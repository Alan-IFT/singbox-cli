# 05 — Code Review · T-13 `config-write-permission-hardening`

> Authored by the stage-5 code-reviewer agent (read-only tool set: Read / Glob / Grep only; no shell,
> so no command was run and nothing was written, chmod'd or moved anywhere). Every claim below was
> re-derived from the shipped files, not from `04_DEVELOPMENT.md`. Verdict at §10.
> Persisted verbatim by the PM Orchestrator, which altered neither content nor verdict.

Mode: **full**. Deferred-human mode (`defer, do not ask`): every judgment call is ruled here.
Condition **C-12** lands on this stage and is discharged at §4.

---

## 1. Files reviewed

| Path | Read | Result |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `1-120`, `300-410`, `975-1130`, `1180-1250`, `1419-1480`, `1671-1760`, `1858-1864`, plus 6 whole-file greps | in scope, correct |
| `/home/alan/Programs/singbox-cli/install.sh` | `130-260`, `254-375`, `570-616`, plus 3 whole-file greps | in scope, correct |
| `/home/alan/Programs/singbox-cli/README.md` / `README.zh-CN.md` | `:190`, `:217-218`, heading maps, line counts | mirrored |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | `1-45` | one zh `### 修复` bullet |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | `30-129` | C-2 discharged (6 edits) |
| `/home/alan/Programs/singbox-cli/docs/architecture.md` | `110-127` | exactly one row |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | `78-82` | glossary matches shipped code |
| `/home/alan/Programs/singbox-cli/docs/tasks.md` | grep `T-13` | one PM row; **no developer edit** |

**Tests:** none committed (D-8, upheld by gate §2 S-2). The stage-4 harness was a throwaway and
`04_DEVELOPMENT.md:122` records it as discarded — see NOTE-8.

### 1.1 How I substituted for a `git diff` I could not run

I have no shell, so I reconciled the diff by **line arithmetic** against the line numbers the three
upstream documents recorded for HEAD. Every anchor lands exactly:

| HEAD anchor (cited upstream) | Shift owed by the additions above it | Predicted | Actual | ✓ |
|---|---|---|---|---|
| auto-elevate block `bin/sc:83-84` | +5 (`import tempfile`, `CRED_MODE` + 3 comment lines) | 88-89 | **88-89** | ✓ |
| `_init_files()`'s `/var/lib/sing-box` `bin/sc:309` | +58 (+5, +52 helper, +1 key) | 367 | **367** | ✓ |
| config write `bin/sc:1016` | +63 (+58, +2 `_init_files`, +3 `save_nodes`) | 1079-1081 | **1079-1081** | ✓ |
| `install_report()` derivation `install.sh:243-246` | +14 (7 keys × 2 tables) | 257-260 | **257-260** | ✓ |
| `install_report()` closing `}` `install.sh:288` | +14 | 302 | **302** | ✓ |
| `/etc/sing-box` literals `install.sh:411/421/455` | +75 (+14 keys, +61 sweep block) | 486/496/530 | **486/496/530** | ✓ |
| `install_report \|\| exit 1` `install.sh:532` | +82 (+75, +7 call-site block) | 614 | **614** | ✓ |

Every anchor is displaced by **exactly** the size of the intended insertions and by nothing else.
That is positive evidence that `bin/sc` and `install.sh` contain the three/four planned insertions
and **no other edit** — in particular that `install_report()`'s body, the auto-elevate block and the
doctor block are untouched. It also matches `04_DEVELOPMENT.md`'s claimed `bin/sc +74/−6`.

---

## 2. The security property, verified from the code (not from the summary)

The seven questions the dispatch put to this stage, answered from what is written.

**(1) Is there any instant at which credential bytes exist at a mode wider than 0600?**
**No.** `bin/sc:339-352`, in the order as written:

```python
fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=path.name + ".tmp." + str(os.getpid()) + ".")
try:
    os.fchmod(fd, CRED_MODE)          # 343 — object exists, is EMPTY, becomes exactly 0600
    fh = os.fdopen(fd, "w")           # 344
    fd = -1                           # 345
    try:
        fh.write(text)                # 347 — FIRST byte, behind a 0600 inode
        fh.flush(); os.fsync(...)     # 348-349
    finally:
        fh.close()                    # 351
    os.replace(tmp, str(path))        # 352
```

`os.fchmod` (343) strictly precedes the first `write` (347); no byte can precede it, because the
only object in existence between 339 and 347 is the one `mkstemp` created empty. The umask can only
*clear* bits from `mkstemp`'s `0o600` argument, so `[t0,t1)` is a window on an **empty** file at
`≤0600`. The target path is never opened for writing at all; it is reached only by `rename(2)`,
which publishes an inode that was already exactly `0600`. **The design's umask-independence argument
survives the code as written.**

**(2) `os.fchmod` at every helper site, mode from a named constant?** Yes — one helper, one
`os.fchmod(fd, CRED_MODE)` (`bin/sc:343`), `CRED_MODE = 0o600` defined once (`bin/sc:27`). No `0o600`
literal appears in any write path. (The shell side necessarily restates it as `CRED_MODE=600`,
`install.sh:316` — cross-language duplication ruled by D-11 and re-homed to T-20.)

**(3) `dir=` passed to `mkstemp`?** Yes — `dir=str(path.parent)`, `bin/sc:340`. `TMPDIR` is never
consulted; `EXDEV` is structurally impossible and credential bytes cannot land outside the
configuration directory.

**(4) Does any `os.chmod` remain in `bin/sc`?** **No.** A whole-file grep for `chmod` returns
exactly three hits: the `os.fchmod` at `:343` and two doc comments. There is one surviving *method*
call, `script.chmod(0o755)` at `bin/sc:1829`, on the OpenRC periodic **shell script** — a
non-credential, deliberately world-executable artifact (stage 1 E-7) and a *widening* chmod, so it
carries no window. The developer's claim is precise and correct. NOTE-1.

**(5) `os.fdopen` vs `os.write(…encode())`?** `os.fdopen(fd, "w")` (`bin/sc:344`). No `.encode(`
anywhere in the helper. Gate Q2 / P-2 / R-3 satisfied: the write stays locale-encoded and therefore
byte-symmetric with `load_nodes()`'s `Path.read_text()` (`bin/sc:379`). No latent write-time failure
is converted into a read-time one.

**(6) The `fd = -1` ownership transfer.** Present verbatim at `bin/sc:345`, immediately after
`os.fdopen` returns. Traced exhaustively:

| Failure point | fd state | tmp state | Outcome |
|---|---|---|---|
| `mkstemp` raises | never created | never created | nothing to clean; `OSError` propagates |
| `os.fchmod` (343) raises | `fd ≥ 0` | exists | `finally` closes fd **and** unlinks tmp |
| `os.fdopen` (344) raises | `fd ≥ 0` (assignment never ran) | exists | same — no leak |
| `fh.write/flush/fsync` raises | `fd == -1` | exists | inner `finally` closes `fh` (the sole owner), outer unlinks tmp — **no double-close** |
| `fh.close()` (351) raises | `fd == -1`, fh closed | exists | outer `finally` unlinks tmp |
| `os.replace` (352) raises | `fd == -1` | exists | outer `finally` unlinks tmp |
| success | `fd == -1` | `tmp = None` (353) | `finally` is a no-op; nothing survives |

No path double-closes, no path leaks a descriptor, and no path leaves a temporary. AC-10 holds by
construction, not by timing.

**(7) AC-8 failure path.** `bin/sc:1082-1085` catches `OSError`, writes **one** line —
`"⚠️  " + t("Could not write {path}: {err}", path=CFG_PATH, err=_plain(e.strerror or str(e)))` — to
stderr and returns `False`. `_plain()` (`bin/sc` `# doctor` block) is the project's single "foreign
text made output-safe" definition, correctly applied to `e.strerror`. No traceback can escape,
because the target is never opened, so `mkstemp`/`fchmod` raise *before* any content exists.
`reload_or_restart()` (`:1103`) forwards `False`; `cmd_reload()` (`:1859-1862`) ends
`sys.exit(t("Reload failed"))` ⇒ status 1. Pre-existing content byte-identical: guaranteed by the
fact that the only operation that ever touches the target is `os.replace`, which is all-or-nothing.
The temp is unlinked on **every** branch (table above). AC-8 / AC-6 / BC-9 hold as written.

---

## 3. Findings

### BLOCKER
None.

### MAJOR
None.

### MINOR

- **[MAINT] `docs/dev-map.md:115` — stale line citation written in this very diff.** The safety
  warning reads ``**Never drive `_init_files()`**: `bin/sc:309` hard-codes `/var/lib/sing-box` ``.
  After this task's own +58 lines that statement lives at **`bin/sc:367`**; line 309 is now inside
  the `# State files` header region and a reader following the citation finds nothing. This is the
  one citation in the new dev-map text that will actively mislead, and it is the *safety* one.
  Notably the developer got this right two rows earlier — `bin/sc:26` deliberately says
  "`SRS_MIN_BYTES` **below**" instead of the design's `(bin/sc:61)`, which is the better habit.
  **Owner: developer.** One-token fix (`309` → `367`, or drop the number as at `:26`); does not
  warrant a rollback — see §10.

### NOTE (no action required; recorded so a later reader does not re-discover them)

- **NOTE-1 — `bin/sc:1829` `script.chmod(0o755)`.** Survives, correctly: non-credential, widening,
  out of the design's three-site scope (stage 1 E-7).
- **NOTE-2 — mode re-read is a string compare.** `install.sh:357` tests
  `[ "$newmode" = "$CRED_MODE" ]`. GNU coreutils and BusyBox both render `%a` without a leading zero
  (`600`), so this is correct on every supported host (the script is Linux-only by construction,
  design §5.2). A hypothetical `stat` printing `0600` would emit a spurious `perm_problem` after a
  *successful* chmod — wrong in the **loud** direction, never leaving a wide file unreported. Ruled:
  leave as designed; do not churn pinned code for a host that cannot reach this script.
- **NOTE-3 — sweep TOCTOU.** Between `[ -L ]` (`install.sh:334`) and `chmod` (`:350`) an attacker who
  can create files in `/etc/sing-box` could swap in a symlink. That requires the directory to be
  attacker-writable, which is NG-5 and is already the open row the gate re-homed (§1.2 / C-11). Not
  a regression: at HEAD the same attacker got `write_text` to write credentials *through* a planted
  link.
- **NOTE-4 — `UnicodeEncodeError` is not an `OSError`.** A non-ASCII node tag under the C locale
  would escape both `except OSError` handlers as a traceback. Pre-existing (§15 O-2, out of scope),
  and **improved** by this change: at HEAD `write_text` had already truncated the live target when it
  raised; now the previous document is byte-identical.
- **NOTE-5 — temp name visible in a world-readable directory.** `config.json.tmp.<pid>.<rand>` is a
  name, not a credential; the inode is `0600` root-owned. Gate §1.2 ruled it; confirmed unchanged.
- **NOTE-6 — behaviour 11's residual.** The sweep runs on every run that reaches `install_report()`,
  but pre-flight and download `exit 1`s (`install.sh:35/47/57/66/348/364/394/401` at HEAD numbering)
  precede it and already bypass `install_report()` too. Design §5.3 stated this scope explicitly and
  the gate accepted it; it is the R-3 class, deliberately not absorbed. Confirmed as designed.
- **NOTE-7 — `config.json`'s inode is no longer stable** across regenerations (gate Q5). Nothing in
  `bin/sc` holds a descriptor across one and nothing enumerates `CFG_DIR` (only `RULES_DIR.iterdir()`
  at `:893`), so it is harmless. Stage 6 states it.
- **NOTE-8 — C-3 is at risk.** `04_DEVELOPMENT.md:122` says both throwaway harnesses were
  "discarded after use", and I could not find them in the scratchpad. C-3 requires the harness pasted
  **verbatim** into `06_TEST_REPORT.md` so the next task inherits a test rather than a paragraph —
  the price the gate charged for the fourth deferral of D-8. Stage 6 must rebuild it, not narrate it.
  **Owner: stage 6 / PM.**

---

## 4. C-12 — the D-2 control-flow change, ruled

The gate assigned this to me specifically. Three separate questions; all three verified.

**(a) `save_nodes()` now `sys.exit`s, and is called from inside `generate_config()`.**
Confirmed: `bin/sc:382-387` exits; `generate_config()` calls it at `bin/sc:991` (stale-active-tag
repair); `cmd_update_rules()` calls `generate_config()` at `:1734`, and its "Exactly one truthful
run-level outcome, always, before the exit" block is `:1743-1755`. An `OSError` writing `nodes.json`
on that path therefore terminates the process before those lines print.

**Ruling: ship as designed. Not a defect, and not a regression.**
1. At HEAD the identical `OSError` propagated as an uncaught traceback out of the same call, skipping
   the identical lines and exiting non-zero. The invariant was already violated on this path; what
   changed is *traceback → one translated line naming the path and the OS cause*, which is exactly
   NFR-3. Strictly better on every axis the requirement measures.
2. The trigger is a conjunction: a stale `active` tag **and** a `nodes.json` write failure, i.e. the
   filesystem is already refusing writes in the credential directory. "State the run-level outcome"
   is not more truthful than "say which path could not be written" on a host in that state.
3. The alternative — making `save_nodes()` return a status — would change its contract for the four
   other call sites (`:372`, `:1195`, `:1218`, `:1232`) where a hard exit *is* the right outcome, to
   serve one caller. That trade is worse, and it is the seam D-1/D-2 exist to avoid.

The general statement ("a helper that `sys.exit`s inside a function whose caller owes a run-level
outcome") is worth a board row, which is already C-11's, assigned to the PM. **No rollback.**

**(b) Is `_init_files()`'s output byte-identical?** **Yes**, verified rather than assumed.
HEAD wrote `json.dumps({"active": None, "nodes": []}, indent=2)`; the new path
(`bin/sc:372` → `:384`) writes `json.dumps(d, indent=2, ensure_ascii=False)` of the same literal.
`ensure_ascii` governs **only** the `\uXXXX` escaping of non-ASCII characters; the literal
`{"active": None, "nodes": []}` contains none, so both calls yield the same bytes
(`{\n  "active": null,\n  "nodes": []\n}`), with no trailing newline in either case
(`Path.write_text` and `fh.write` both add nothing). Byte-identical. ✅

**(c) Is any other `save_nodes()` caller broken by the new `sys.exit`?** No. All five callers are
`bin/sc:372` (`_init_files`), `:991` (`generate_config`, ruled above), `:1195` (`cmd_use`), `:1218`
(`cmd_add`), `:1232` (`cmd_rm`). In the last three, the statements that follow the call
(`clash_api` / `reload_or_restart` / the success `print`) are precisely the statements that must
**not** run if the node store was not persisted — printing "Added: X" after a failed write would be
the banner/reality disagreement T-01 exists to prevent. The hard exit is the correct outcome there,
and it replaces a traceback that already skipped them. ✅

---

## 5. The installer sweep — abort-safety audit

Every item the dispatch named, checked against `install.sh` as shipped.

| Check | Evidence | Result |
|---|---|---|
| **Gate F-1**: all seven `perm_*` keys in **both** tables | zh `:186-192`, en `:237-243`; identical key spellings, identical relative position (after `step6_nolog`) | ✅ |
| **Gate F-1**: every call site names an existing key | call sites `:326, 334, 335, 336, 344, 347, 351, 358, 360` name only `perm_header/skip/absent/unknown/ok/problem/fixed` — all seven exist | ✅ no `set -u` kill path |
| Specifier parity per key | 1/2/1/3/4/1/1 in zh, same in en; call sites pass matching arg counts (`perm_problem` 4, `perm_fixed` 3, `perm_ok` 2) | ✅ |
| Every fallible command in an exemption context | `stat` at `:338` and `:356` inside `if !`; `chmod` at `:350` inside `if !`; the octal test at `:346` inside `[ ]`; no bare command in the body | ✅ |
| Call site `\|\| true` | `:610` | ✅ |
| **Gate P-6**: no `local x=$(…)` | `local f path mode newmode` alone on `:325`; whole-file grep for `local [a-z_]+=\$\(` returns **nothing** | ✅ |
| **Gate P-7**: no column-0 line inside the function | `:325-362` all indented; the only column-0 tokens are `sweep_credential_modes() {` (`:324`) and `}` (`:363`), so `sed -n '/^sweep_credential_modes() {/,/^}/p'` is exact (AC-18) | ✅ |
| `[ -L ]` **first**, before `-e` and `-f` | `:334` then `:335` then `:336` | ✅ |
| **C-10** comment corrected and accurate | `:329-333`: "`chmod` **FOLLOWS** a symlink (Linux has no lchmod) while GNU `stat` does **NOT** dereference unless given `-L`" — factually right, and it makes the guard read as *more* necessary, which was the point of F-2 | ✅ |
| Ordering makes the security claim true | with `[ -L ]` first, a planted link takes `perm_skip` + `continue`; neither `stat` nor `chmod` is ever reached for it, so the installer cannot be aimed at an arbitrary system path | ✅ |
| Octal `case` guard **precedes** any `$(( ))` | `case` `:342-345`, arithmetic `:346` | ✅ |
| `install_report()` banner last, derivation untouched | `:610` sweep → `:614 install_report \|\| exit 1` → `:615 exit 0`; body `:257-302` reads only `PHASE_CONFIG`/`PHASE_SERVICE`/`PHASE_RULESETS`/`INIT_SYS`/`LOG_SINK`, exactly as at HEAD (line arithmetic §1.1) | ✅ DECISION-5 / AC-20 |
| Sweep touches no `PHASE_*` | `:324-363` contains no `PHASE` token | ✅ |
| **Gate P-8**: other `/etc/sing-box` literals not consolidated | `:486`, `:496`, `:530` still literal; `CRED_DIR` referenced only at `:326` and `:328` | ✅ D-7 |
| Narrowing only | the only mutating command is `chmod 600` (`:350`), guarded by `& 8#077 != 0`; a `0400` or `0000` file takes the `perm_ok` branch and is never touched | ✅ DECISION-3 / AC-15 |
| Directory absent | `[ -L ]` false, `[ -e ]` false ⇒ `perm_absent` per file, loop continues | ✅ BC-13 |

**Logic walk of the mode arithmetic** (the part most likely to be wrong and hardest to see):
`600 & 077 = 0` → `perm_ok`, no chmod (AC-27 idempotency). `644 & 077 = 044 ≠ 0` → chmod → re-read
`600` → `perm_fixed` naming both modes. `400`, `000`, `700` → `perm_ok`, not widened. `2600` (setgid)
→ `perm_ok` and the raw `2600` is printed verbatim, so a special bit stays visible (R-12, deliberate).
Non-octal or unreadable → `perm_unknown` **before** any `$(( ))`, so the arithmetic syntax error that
would abort under `set -e` is unreachable. A `chmod` that "succeeds" but does not change the mode
(read-only or foreign filesystem) falls to the second `perm_problem` arm, because the code re-reads
instead of asserting its intent. All correct.

---

## 6. Requirement coverage check

Legend: ✅ implemented and verified by reading; ⏳ implemented, verification owed to stage 6 by an
explicit gate condition (never "not found").

| AC | Implementation | Status |
|---|---|---|
| AC-1 | `bin/sc:343` + call sites `:384`, `:1081` | ✅ |
| AC-2 | `os.fchmod` after a masked `mkstemp`; exactness independent of umask | ✅ |
| AC-3 | fresh `O_EXCL` name + `os.replace` (`:339`, `:352`) — target's prior mode never consulted | ✅ |
| AC-4 | §2(1) timeline: at the `replace` instant only the temp holds new bytes, at `0600` | ✅ (spy measurement is C-8, stage 6) |
| AC-5 | the target is never opened for writing; only `rename` touches it | ✅ |
| AC-6 | `mkstemp`/`fchmod` raise before content exists; handler `:1082-1085` | ✅ |
| AC-7 | write→check ordering preserved: `:1080` write, `:1087` `sing-box check` (NG-9) | ✅ |
| AC-8 | one stderr line, `_plain(e.strerror)`, `return False` → `:1103` → `:1862` non-zero | ✅ |
| AC-9 | per-process `mkstemp` names + atomic `rename` | ✅ |
| AC-10 | `tmp = None` (`:353`) + `finally: unlink` on every other branch | ✅ |
| AC-11 | `O_NOFOLLOW` fresh name; `rename` replaces the link itself, never writes through it | ✅ |
| AC-12 | `dir=str(path.parent)` (`:340`); no `TMPDIR`; `_init_files()` off the tested path | ✅ |
| AC-13 | `install.sh:610` between step 7 (`:603`) and `install_report` (`:614`) | ✅ |
| AC-14 | top-level, unconditional, outside the step-7 `if` | ✅ |
| AC-15 | `perm_fixed` (3 specifiers) / `perm_ok` with no `chmod` issued | ✅ |
| AC-16 | `perm_absent` (`:335`); the sweep sets no status variable | ✅ |
| AC-17 | `if ! chmod` → `perm_problem` → `continue`; `\|\| true` at `:610` | ✅ |
| AC-18 | `CRED_DIR`/`CRED_FILES`/`CRED_MODE` referenced only inside the function; column-0 anchors intact | ✅ |
| AC-19 | `CRED_FILES=(config.json nodes.json)` is the only reachable name set | ✅ |
| AC-20 | sweep touches no `PHASE_*`; `install_report()` body unmoved (§1.1) | ✅ |
| AC-21 | 7 paired keys, equal specifiers | ⏳ first half measured at stage 4; C-5/C-7 transcripts are stage 6's |
| AC-22 | `bin/sc:104` `"Could not write {path}: {err}"` → `"无法写入 {path}：{err}"`; same `{path}`/`{err}`; contains neither `failed:` nor `失败：` | ✅ |
| AC-23 | no `verify_all` step added or changed | ⏳ C-4 clone comparison after archiving |
| AC-24 | `sc doctor` untouched — `DOCTOR_SECTIONS` (`:1570`) unchanged, `_doctor_config` (`:1419-1464`) has no mode probe, no `st_mode`/`import stat` anywhere in `bin/sc` | ✅ (byte-diff is stage 6's) |
| AC-25 | `README.md:190/:218` + `README.zh-CN.md:190/:218`; both files **235 lines**, all 20 headings at identical line numbers; `CHANGELOG.md:15` zh bullet | ✅ |
| AC-26 | `tempfile` imported at `:12` between `sys` and `urllib.error`; only `mkstemp(dir=,prefix=)`, `fchmod`, `fdopen`, `fsync`, `replace`, `unlink`, `close`, `getpid` — all ≤3.3; no walrus, no f-string `=`, no `unlink(missing_ok=)`; `capture_output=` still exactly 3 pre-existing sites (`:1088`, `:1133`, `:1787`), none added or removed; `bin/sc:367`'s `/var/lib/sing-box` untouched | ✅ (P-12 clean) |
| AC-27 | `perm_ok` issues no `chmod`; the sweep writes nothing else | ✅ |

**No acceptance criterion is unimplemented.** No ❌ row.

---

## 7. Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| §4.1 `CRED_MODE` in `# Paths` after `RULES_DIR` | `bin/sc:24-27` | ✅ (comment improved: "SRS_MIN_BYTES **below**" instead of a line number — the right habit; contrast §3 MINOR) |
| §4.2 `_write_private()` body | `bin/sc:312-361` — statement-for-statement identical, including `fd = -1`, no directory `fsync`, pid in `prefix` | ✅ verbatim |
| §4.3 three call sites rewired | `:372` (`_init_files` → `save_nodes`), `:382-387` (`save_nodes`), `:1080-1085` (`generate_config`) | ✅ |
| §4.4 exactly one new zh key, after `"Error: {e}"` | `bin/sc:104` | ✅ |
| §5.1 `CRED_DIR`/`CRED_FILES`/`CRED_MODE` after `install_report()` | `install.sh:304-316` | ✅ |
| §5.2 `sweep_credential_modes()` | `install.sh:324-363` | ✅ verbatim + C-10 comment correction (mandated) |
| §5.3 call site | `install.sh:605-614` | ✅ |
| §5.4 seven keys × two tables | `install.sh:186-192`, `:237-243` | ✅ |
| D-6 `settings.json` writers untouched | `bin/sc:374-375`, `:395`, `install.sh:496` heredoc | ✅ |
| D-7 other `/etc/sing-box` literals not consolidated | `install.sh:486/496/530` | ✅ |
| D-10 README pair, same two edits, same line numbers | `:190` / `:218` in both, both 235 lines | ✅ |
| Gate §8 item 11 — `docs/architecture.md`, **one** row, Chinese only | `docs/architecture.md:120` only; `:119` `nodes.json` row untouched; nothing else in that file | ✅ |
| C-2 — dev-map owed the V-1 recipe + F-6's three rows | `dev-map.md:30` (`CRED_MODE`), `:34` (`# State files`), `:37` (`# Config generation` names the mechanism), `:56` (`_write_private` utility row incl. the "0400 at umask 0o277" regression guard), `:57` (`_plain` non-doctor callers), `:58` (`sweep_credential_modes` row), `:95-118` (the runnable V-1 shim + "never drive `_init_files()`"), `:119-122` (the `sed`-extraction idiom) | ✅ exceeded (6 edits vs 2 budgeted) |
| Item 10 — `docs/tasks.md` is the PM's | grep: one row (`:11`), no developer additions, no C-1/C-11 rows added by stage 4 | ✅ |
| Files outside the pinned eleven | none: only the eight files `04` lists, all inside the list | ✅ |

**Design drift: none.** The three textual additions `04_DEVELOPMENT.md §4` declares — the C-10 comment
correction (`install.sh:329-333`), the `_init_files()` delegation comment (`bin/sc:369-371`) and the
ordering comment (`bin/sc:1079`) — are behaviour-neutral and each explains a *why* the design's prose
carried but its code block did not. That is the permitted kind of improvement, not drift; I rule it
in-scope rather than bouncing it to the solution-architect.

---

## 8. The six dimensions

1. **Logic correctness** — §2 and §5. Every exception path traced; no double-close, no descriptor
   leak, no surviving temporary, no branch that leaves the target partially written. The shell
   arithmetic is guarded before use and correct for every octal shape including special bits.
2. **Requirement fidelity** — §6. All 27 ACs implemented; four carry verification obligations
   already assigned to stage 6 by C-4…C-9.
3. **Design fidelity** — §7. Verbatim where the design pinned code; no silent substitution of the
   three elements the requirement's NFR-1 depends on.
4. **Performance** — non-material, as NFR-5 predicted: one extra inode creation, one `fsync` and one
   `rename` per credential write; a handful of `stat`s per install. No loop over nodes was added, no
   I/O in a hot path, no allocation proportional to anything new. The `fsync` on every `sc add/rm/use`
   costs a few ms and buys ENOSPC-before-publish; correct trade.
5. **Security** — the point of the task; §2. The window is closed structurally (ordering), the
   umask dependence is closed by `fchmod`, the prior-mode dependence is closed by `O_EXCL` + `rename`,
   and the symlink redirection is closed twice (`O_NOFOLLOW` on the temp, `rename` replacing the link
   itself; and in the installer by the `[ -L ]` guard placed first). The installer's new powers are
   bounded to *narrowing* two enumerated names inside one directory. No new input is parsed, no
   secret is logged, nothing is deserialised.
6. **Maintainability** — the helper's docstring states which element carries which guarantee, which
   is the R-2 regression guard written where the next editor will read it, and the same guard is
   repeated in `dev-map.md:56` with the measured `0400` figure. Naming is consistent
   (`_write_private`, `CRED_*`). No dead code, no premature abstraction — D-3 and D-6 decline the two
   available over-builds. One stale citation (§3 MINOR).

---

## 9. Safety

- I ran **no** command; my tool set is Read/Glob/Grep. Nothing was written, chmod'd, moved or backed
  up anywhere, under `/etc` or elsewhere. `install.sh` was never executed; `/usr/local/bin/sc` was
  never invoked.
- **The auto-elevate block is unmodified in the product code.** `bin/sc:88-89` reads
  `if os.geteuid() != 0:` / `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` — the
  HEAD text, displaced by exactly the +5 lines the intended additions above it account for (§1.1).
  Neutralisation lives only in the harness recipe (`dev-map.md:99-109`), which shims `os` in
  `sys.modules` and restores it in a `finally`, never touching the source. Correct per C-14 §2.
- **Commit/push:** the reflog's tip is `11e545b docs: record v2rayN as the project's reference point,
  file T-21`, preceded by `1b1b0e0 feat(sc): add sc doctor` — both T-05/board deliveries. **No commit
  in the log carries any T-13 content**, and no new ref was written after them. The developer neither
  committed nor pushed. ✅
- The code itself honours the constraints it must: `_write_private` writes only inside
  `path.parent`; the sweep can only ever narrow, only ever the two names in `CRED_FILES`, only ever
  under `CRED_DIR`, and never through a symlink.
- Owner through-lines: **failures are loud** — the one previously-silent-ish path (a traceback) is
  now a translated line naming path and cause, and nothing anywhere is silently repaired: even the
  installer's repair prints old mode and new mode. **A generated artifact leaves room for the user** —
  NG-3 is honoured and, better, *stated to the user*: `README.md:218`, `README.zh-CN.md:218` and
  `CHANGELOG.md:15` all say `sing-box check` now needs `sudo`, which is correct behaviour explained
  rather than a surprise.

---

## 10. Verdict

**PASS.**

I verified the security property from the code rather than from the summary, and it holds: `fchmod`
precedes the first byte (`bin/sc:343` before `:347`), the mode comes from one named constant, `dir=`
is present, no `os.chmod` survives on any credential path, `os.fdopen` was used rather than
`os.write(…encode())`, the `fd = -1` ownership transfer is verbatim with no path that double-closes
or leaks, and every failure branch unlinks the temporary while leaving the previous document
untouched. The installer sweep cannot abort the run under `set -e`, `set -u` or `pipefail`: all seven
`perm_*` keys exist in both language tables and every call site names one of them, no `local x=$(…)`
appears, no column-0 line breaks the `sed` contract, the `[ -L ]` guard is first and its corrected
comment is accurate, and the octal `case` precedes the arithmetic. `install_report()`'s banner and
exit derivation are provably unmoved. Design fidelity is exact; scope is exact — eight files, all
inside the gate's pinned eleven, `docs/tasks.md` untouched by the developer, and both files the gate
said were *owed* content (`docs/dev-map.md`, `docs/architecture.md`) got it, the second with exactly
one Chinese row and nothing else.

**C-12 is discharged** (§4): the `sys.exit` inside `generate_config()`'s call graph ships as
designed — it is a strict improvement on HEAD's traceback on the same path, its trigger is a
conjunction of a stale tag and a failing filesystem, and the alternative would corrupt
`save_nodes()`'s contract for four correct callers to serve one. `_init_files()`'s output is
byte-identical, verified rather than assumed. No other caller is broken.

**No rollback.** No BLOCKER, no MAJOR. One **MINOR** — `docs/dev-map.md:115`'s `bin/sc:309`, which is
now `bin/sc:367` — is owned by the **developer** and may be corrected in place at the PM's discretion
without re-review; it changes no behaviour and blocks nothing. **NOTE-8** is owned by **stage 6 / the
PM**: the stage-4 harness was discarded, and C-3 requires a runnable harness pasted verbatim into
`06_TEST_REPORT.md` — that is the price the gate charged for D-8's fourth deferral and it must not
quietly become a paragraph.

Proceed to stage 6 with C-3, C-5, C-6, C-7, C-8, C-9, C-13 and the AC-21/23/24/27 obligations of §6
still open.
