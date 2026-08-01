# 04 — Development Record · T-13 `config-write-permission-hardening`

Mode: **full**. Deferred-human mode (`defer, do not ask`): every implementation-level judgment call
is resolved here and recorded at §5. `01`/`02`/`03` were read as binding and **not edited**.
Conditions C-2, C-4, C-10 and C-14 land on this stage and are discharged at §7.

---

## 1. Summary

`bin/sc` gained one function, `_write_private(path, text)`, which is now the only way a credential
document reaches disk: `mkstemp(dir=path.parent)` → `os.fchmod(fd, CRED_MODE)` **while the object is
still empty** → write/flush/fsync → `os.replace()`. The write-then-`chmod` pair is gone from all
three of its occurrences; **no `os.chmod` remains anywhere in `bin/sc`**. `install.sh` gained
`sweep_credential_modes()`, called as `sweep_credential_modes || true` between step 7 and
`install_report()`, which states each credential document's mode and narrows — never widens —
anything wider than 600, without being able to abort the run or change its exit status. Documentation
(2 READMEs, CHANGELOG, dev-map, architecture) follows the code.

---

## 2. `verify_all` — measured, not assumed (C-4)

| Run | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| **Pre-edit baseline** (before the first edit, working tree as handed over) | **16** | **1** | **0** | **1** |
| **After all changes** | **16** | **1** | **0** | **1** |
| **Delta** | 0 | 0 | 0 | 0 |

**Every count attributed.** The dispatch's stated `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` is T-05's
post-archive figure and is **not** what a run today produces — gate finding F-3 predicted this
exactly. The single WARN is `[F.6] Active task docs <=500 lines each`, caused by
`02_SOLUTION_DESIGN.md` being **789 lines**; it was already WARN before my first edit and is
unrelated to any change I made. F.4 (`insight-index.md ≤30 lines`) reads **PASS**, not WARN — the
gate flagged it as a *may*, and the measurement says no. `[B.3] Lint` is the pre-existing hard-coded
`SKIP` (`verify_all.sh:77`); D-8/S-2 deliberately does not move it. B.2 now renders **48** keys
(41 + 7 new), up from 41, and passes.

Working tree at task start carried three uncommitted changes, all upstream, none mine and none
touched by me: `.harness/rejected-decisions.md` (+48, stage 2), `CONTEXT.md` (+9, stage 2),
`docs/tasks.md` (2 +-, PM). Their diffs are byte-identical before and after my work.

## 2.1 Live-service witness (C-14 constraint 6)

`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` — **never `is-active`**:

| Checkpoint | Reading |
|---|---|
| **Before any edit** | `MainPID=2887037` · `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |
| **After all work** | `MainPID=2887037` · `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |

Identical, and identical to the baseline the dispatch handed over. The service was neither restarted
nor reloaded. `/etc/sing-box` and `/var/lib/sing-box` were witnessed by `os.stat` (ino/mode/mtime/size)
before and after the whole harness run and compared programmatically: **unchanged**. Independent
confirmation after the fact: `config.json` ino=11666092 mode=600 mtime=1785550000, `nodes.json`
ino=11272772 mode=600, `settings.json` mode=644 — all mtimes predate this session.

---

## 3. Files changed

Seven files, all inside the gate's §8 pinned diff. `docs/tasks.md` (item 10) was **not** touched —
findings for the board are at §9.

| Path | Change |
|---|---|
| `bin/sc` | `import tempfile` (between `sys` and `urllib.error`, Q4); `CRED_MODE = 0o600` in `# Paths` after `RULES_DIR`; new `_write_private()` above `_init_files()`; 3 call sites rewired; 1 zh translation key. **+74 / −6** |
| `install.sh` | `CRED_DIR` / `CRED_FILES` / `CRED_MODE` + `sweep_credential_modes()` after `install_report()`'s closing `}`; call site before `install_report \|\| exit 1`; 7 keys × 2 tables inserted pairwise after `step6_nolog`. **+82 / −0** |
| `README.md` | `:190` gains ` (mode 600)`; one security bullet after `:217`. **+2 / −1** |
| `README.zh-CN.md` | the same two edits at the same line numbers; mirrors verified line-for-line (both 235 lines, heading line numbers identical). **+2 / −1** |
| `CHANGELOG.md` | one `### 修复` bullet under `[Unreleased]`, Chinese. **+2** |
| `docs/dev-map.md` | 6 edits — see §7 C-2. **+34 / −4** |
| `docs/architecture.md` | **one** row in the 安全考量 table, Chinese, nothing else in that file. **+1** |

Unchanged and deliberately so: `uninstall.sh`, `systemd/*`, `docs/faq.md`, `.harness/scripts/*`,
`.harness/rules/*`, `.claude/*`, `AI-GUIDE.md`, `CLAUDE.md`, `baseline.json`, `sc doctor`,
`settings.json`'s three writers (D-6), `bin/sc:309`'s `/var/lib/sing-box` (O-1), the three
`capture_output=` sites (AC-26), `install.sh`'s other `/etc/sing-box` literals (D-7/P-8).

---

## 4. Design drift

**None.** `_write_private()` and `sweep_credential_modes()` are the design's §4.2/§5.2 bodies
verbatim, including the `fd = -1` ownership transfer (R-4/P-4), `os.fdopen` rather than
`os.write(…encode())` (R-3/P-2/Q2), the mandatory `dir=` (R-1/P-3), the `case` octal guard before any
`$((8#…))` (R-5), `local` on its own line (P-6), no column-0 line inside the shell function (P-7),
and no directory `fsync` (§4.2 note 4). Three additions, all textual and all mandated by a binding
condition rather than chosen by me:

1. **C-10** — the `[ -L ]` comment is corrected rather than copied (see §7).
2. Two short comments the design's prose implies but its code block does not carry: one at
   `_init_files()`'s `save_nodes()` delegation (why the output is byte-identical) and one above
   `generate_config()`'s `try:` recording that the write→`sing-box check` ordering is unchanged
   (NG-9). Neither changes behaviour.

---

## 5. Implementation decisions taken under standing authority

- **D-a. `save_nodes()`'s `except` catches `OSError` only, and lets `SystemExit` through.** The
  design's body is reproduced exactly; I record it because the shape matters: `_write_private` raises
  nothing else, and a bare `except` would swallow a `KeyboardInterrupt` during an `fsync`.
- **D-b. `_plain(e.strerror or str(e))` is kept verbatim at both call sites** even though
  `_plain` lives in the `# doctor` block, far below `# State files`. Python resolves module globals at
  call time, so the forward reference is fine, and it is exercised on both call sites by the harness.
  The dev-map row for `_plain` now says it has non-doctor callers so a future reader does not
  "tidy" it back into the doctor block.
- **D-c. The CHANGELOG entry is one bullet, in Chinese, under the existing `### 修复`.** It states
  the mechanism change, the atomicity by-product, the installer sweep, the upgrade path, and the
  one user-visible consequence (`sing-box check` as a non-root user now fails — NG-3). Matching the
  existing entries' density was deliberate; this file is the project's user-facing record.
- **D-d. The README security bullet names the consequence, not only the guarantee.** NFR-3's
  through-line is that the user is told what to do; "your `sing-box check` now needs `sudo`" is the
  only behaviour a user could be surprised by.
- **D-e. I did not add a `docs/tasks.md` row** for the two observations at §9 (Q7 forbids it).

---

## 6. What I verified myself, and how

Two throwaway harnesses, both under the scratchpad, both discarded after use. Neither ever wrote,
chmod'd or moved anything under `/etc`; neither executed `install.sh`; neither touched
`/usr/local/bin/sc`. The Python one loads `bin/sc` through the §14 V-1 `sys.modules` `os`-shim
(`geteuid` → 0, restored in a `finally`), asserts `os.geteuid() != 0` first, repoints all five path
constants into a `mkdtemp()` root, sets `SYSTEMD = OPENRC = False` and `SB_BIN` to a stub, and
**never drives `_init_files()`**.

**43 checks, 0 failures.** Grouped by what they discharge:

| Group | Result |
|---|---|
| `_write_private` at umask `0o000` / `0o022` / `0o077` / `0o277` | mode **exactly `0600`** in all four (AC-2, BC-1, BC-2) |
| **Control for P-1/R-2**: bare `mkstemp` at umask `0o277` | **`0400`** — so the `fchmod` is demonstrably load-bearing, not redundant |
| Pre-existing target at `0644` / `0664` / `0666` / `0400` / `0000` | ends `0600` with the new content in every case (AC-3, BC-3, BC-4) |
| Symlinked target | replaced by a **regular** `0600` file; the link **destination's content and mode are unchanged** (AC-11, BC-7, C-10's falsification control) |
| `generate_config()` end to end | `0600`, parseable, and the directory gains exactly `config.json` — no temporary survives (AC-1, AC-10) |
| **"Never wide" spy** on `os.replace` under umask `0o000`, both fixture shapes (C-8) | empty-dir shape: nothing group/other-readable at the publish instant. Pre-existing-`0644` shape: every file *other than the user's own target* ≤ `0600`, the target byte-identical at that instant, and `0600` with new content after (AC-4, AC-5, AC-3) |
| **Non-vacuity of the above** (C-8) | the identical spy against a pristine `HEAD` copy of `bin/sc` observes `config.json` at **`0o666`, 5148 bytes** at the publish instant; the new build observes only a `0600` temp. The green is earned |
| Unwritable fixture directory | `generate_config()` → `False`; **exactly one** stderr line naming the path and `Permission denied`; **no `Traceback`**; previous document byte-identical; no leftover temp (AC-6, AC-8, BC-9) |
| The new key in zh | renders differently from en, carries the same `{path}`/`{err}` set, and contains **neither `failed:` nor `失败：`** (AC-22) |
| `save_nodes()` | fresh `nodes.json` is `0600`; its output is **byte-identical** to HEAD's `_init_files()` literal (C-12's second half); an `OSError` becomes `SystemExit("Could not write …")`, not a traceback |
| `sing-box check` ordering | a failing stub check still leaves `config.json` written and `0600`, and still reports the pre-existing `Config check failed` message (AC-7, NG-9, E-12) |
| Two concurrent `generate_config()` runs (forked) | result parses, is `0600`, no `*.tmp.*` remains (AC-9, BC-11) |
| Safety witnesses | `/etc/sing-box` + `/var/lib/sing-box` ino/mode/mtime/size identical before and after; no stray temp anywhere under the fixture root (AC-12) |

**The installer sweep**, extracted with `sed -n '/^t() {/,/^}/p'` and
`sed -n '/^sweep_credential_modes() {/,/^}/p'` (40 lines extracted cleanly, so the column-0 anchors
AC-18 rests on hold) and sourced into a `bash -uo pipefail -c` child against temp fixtures:

- **All seven `perm_*` keys reached in both `LANG_CHOICE` values**, and `AFTER-SWEEP-REACHED` printed
  every single time — the sweep never terminated the child. That is F-1's `set -u` abort path closed
  for these seven keys, and the two full transcripts **differ**, which is AC-21's second half.
- `0644` → narrowed to `600` and the line names both modes; `0600` → OK, no `chmod` issued; `0400`
  → OK and **not widened**; missing → absent; symlink → skipped and its destination's mode and
  content unchanged; a *directory* named `config.json` → skipped; `settings.json` and `rules/*.srs`
  appear in **no** output line and their modes are unchanged (AC-15, AC-16, AC-19, BC-15).
- `chmod() { return 1; }` → `perm_problem` naming the file, its mode and a runnable `chmod` command;
  execution continues past the section (AC-17, R-5).
- `stat() { return 1; }` and `stat() { echo "not-a-mode 9x"; }` → `perm_unknown`, no `chmod` issued,
  no arithmetic syntax error, run continues. The `case` guard does its job.
- `stat() { echo 644; }` with a real `chmod` → the **second** `perm_problem` arm (re-read disagrees
  with the intent) fires as designed.
- `CRED_DIR` pointing at a non-existent directory → two `perm_absent` lines, run continues (BC-13).
- **AC-20 measured directly**: `install_report()` extracted from `HEAD` and from the new revision and
  driven across 2 languages × `PHASE_CONFIG` ∈ {ok, bad} × `PHASE_SERVICE` ∈ {started, dead} —
  **byte-identical output and status, 118 lines each**.
- `.harness/scripts/check-i18n-parity.sh install.sh` → `OK: 48 keys, both languages`, exit 0 (AC-21
  first half).

### What I could **not** verify, stated rather than asserted

- **AC-23's clone comparison.** The gate's ruling is that the delta is computed **after archiving**,
  against a pristine clone. I measured the delta against my own pre-edit run of the same working
  tree (zero) and attributed the one WARN; the clone comparison is stage 6's and the PM's, after
  archiving moves the task docs and F.6 returns to PASS.
- **Python 3.6.** No 3.6 interpreter exists on this host (§1.1 says so and rules it not load-bearing).
  Every name used is 3.6-or-older with the relied-on semantics, and the guarantee rests on
  `os.fchmod`, a syscall wrapper, not on `tempfile`'s shape — but I measured on **3.12 only**.
- **`os.replace` preserving the source mode with a falsification control, plus the fixture's
  filesystem type** (C-6). My tests show the end state is `0600` in every shape, which would fail
  loudly if the claim were false, but I did not run V-2's explicit falsifier (temp at `0644` ⇒
  target `0644`) nor record `stat -f -c %T`. That is C-6, assigned to stage 6.
- **`sc doctor`'s byte-identical output in both languages** (AC-24). I changed nothing in the doctor
  block and `_plain` is untouched, but I did not render the seven sections and diff them. Stage 6.
- **`install.sh` idempotency on a real second run** (AC-27). Structurally the sweep is a no-op on an
  already-`0600` file (proved: `perm_ok` issues no `chmod`), but the installer was never executed —
  correctly, per constraint 5. Stage 6 reasons about it the same way or in a container.
- **The `EXDEV`/cross-filesystem path** (R-1). `dir=` is present and `TMPDIR` is never consulted;
  I did not construct a two-filesystem fixture to make `os.replace` raise `EXDEV`.

---

## 7. Binding conditions discharged by this stage

**C-4 — pre-edit baseline.** §2. Measured before the first edit; every moved count attributed;
F-3's prediction confirmed (F.6 already WARN at 789 lines) and its F.4 half refuted (PASS).

**C-10 — the symlink comment.** Corrected, and the guard stays exactly where it is, first. The
shipped comment now reads: `chmod` **FOLLOWS** a symlink (Linux has no `lchmod`) while GNU `stat`
does **NOT** dereference unless given `-L` — so without the guard the sweep would read the *link's*
own mode (777), decide it needs narrowing, and `chmod` the link's **destination**, i.e. an arbitrary
path a planted link chose for it. Stated that way the guard reads as *more* necessary, not
redundant. The falsification control (link destination's mode and content unchanged) is measured.

**C-2 — `docs/dev-map.md`.** Six edits, not two:
1. `# Paths` row gains `CRED_MODE` (F-6).
2. `# Config generation` row now **names the mechanism** — `_write_private()`, 0600 from before the
   first byte, atomic replace, "**not** a post-write `chmod`" — instead of "writes 0600" (F-6).
3. `# State files` row gains `_write_private` and records that `_init_files()`'s nodes branch is now
   just a `save_nodes()` call.
4. New "Reusable utilities" row for `_write_private`, spelling out which element carries which
   guarantee and that `mkstemp` alone yields **0400** at umask `0o277` — the R-2 regression guard,
   written where the next editor will read it.
5. New "Reusable utilities" row for `sweep_credential_modes()` incl. the `sed` extraction contract
   and the corrected symlink reasoning; and the `_plain` row now records its non-doctor callers.
6. **The §14 V-1 neutralisation recipe**, pasted as runnable code under "Patterns to avoid", with the
   `assert geteuid() != 0`, the `finally`-restore, the repointing list, and the standing
   **"never drive `_init_files()`"** warning — plus a companion bullet for the
   "verify `install.sh` without running it" `sed`-extraction idiom. This is D-8's price: the next
   task inherits a design, not a blank page.

**C-14 — the six safety constraints, restated so stage 6 inherits them intact:**
1. **Never write, chmod, move or back up anything under `/etc`.** Every verification uses a temp-dir
   fixture root. `/etc/sing-box/` is the live configuration of the owner's running VPN.
2. **Neutralise `bin/sc`'s import-time auto-elevate in every harness and every throwaway script** —
   via the `sys.modules` `os`-shim (now in `docs/dev-map.md`), **never** by editing `bin/sc`'s
   source, and **never** with a blanket "no `os.execvp`" guard (`cmd_uninstall` legitimately calls
   `os.execvp("bash", …)`).
3. **A redirected-paths harness is not automatically safe** — `_init_files()` hard-codes
   `/var/lib/sing-box` (`bin/sc:309`), which is not repointable. Never drive it.
4. **Never test against the installed `/usr/local/bin/sc`** — it is an older build that diverges.
5. **Never execute `install.sh`.** Extract the function with `sed` and source it.
6. **Never restart or reload the live service**; witness with
   `systemctl show -p MainPID -p ActiveEnterTimestamp`, **never `is-active`**.

Plus: **do not commit and do not push** — the owner handles delivery. I did neither.

Conditions not mine: C-1, C-11 (PM); C-3, C-5, C-6, C-7, C-8, C-9, C-13 (stage 6); C-12 (stage 5).

---

## 8. Acceptance criteria — who verifies what

**Implemented and measured by me:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10,
AC-11, AC-12, AC-15, AC-16, AC-17, AC-18, AC-19, AC-20, AC-22, AC-25, AC-26 (by audit — every
introduced name is ≤3.3, no third-party import, no touched `capture_output=`).

**Implemented, and stage 6 must verify rather than me:**
- **AC-13 / AC-14** — the sweep's *placement* relative to step 7 and the banner. I verified the
  function's behaviour and that `install_report()` is byte-identical, and read the call site, but
  ordering within a real run can only be seen by running `install.sh`, which constraint 5 forbids.
  Stage 6 discharges it the way T-08 and T-11 did — by reading the script and driving the extracted
  pieces, not by running it.
- **AC-21** — first half done (`check-i18n-parity.sh` → `OK: 48 keys`); second half done by V-4's
  two differing transcripts. C-7 asks stage 6 to **say which discharged it**: the transcript diff
  did, not `check-i18n-parity.sh` §3b.
- **AC-23** — the clone-and-archive comparison (§6 caveat).
- **AC-24** — `sc doctor` byte-identical in both languages.
- **AC-27** — installer idempotency.

**Behavioural change stage 6 should state rather than discover** (Q5): `config.json`'s **inode is no
longer stable** across regenerations. Nothing in `bin/sc` holds a descriptor across one and nothing
enumerates `CFG_DIR`, so it is harmless here — but an external watcher keyed on the inode would see
it.

---

## 9. Open issues for review / for the PM's board

1. **A hand-made backup exists on this very host**: `/etc/sing-box/config.json.bak-2026-08-01-1001`,
   mode `0600`, made by a human at a shell (E-6 established the tool never makes one). It is **not**
   in `CRED_FILES`, so the installer sweep will neither report nor touch it — correct per NG-11, but
   it means a hand-made credential backup at a wide mode would be invisible to the sweep. Worth a
   board row for T-20's audit; I may not add one (Q7).
2. **F-5 stands as ruled**: a write failure inside `_init_files()` → `save_nodes()` renders the new
   key in **English only**, because `main()` calls `_init_files()` (`bin/sc:1973`) before assigning
   `LANG` (`:1974`). I did **not** reorder `_load_lang()` — C-13 forbids it. Strictly better than
   HEAD's English traceback; the zh translation ships and is reached from the other four call sites
   (measured).
3. **F-4 stands as ruled**: `save_nodes()` now `sys.exit`s where it raised, so an `OSError` on the
   `generate_config()` → `save_nodes()` path (`bin/sc:991`) exits before `cmd_update_rules`' "exactly
   one truthful run-level outcome" lines. Not a regression (a traceback skipped them too), but it now
   *looks* designed. C-12 asks stage 5 to review it explicitly.
4. **F-8 confirmed present, cosmetic**: `_write_private`'s inner `finally: fh.close()` can raise a
   second `OSError` masking the first. Both are caught by the same handler and both name a plausible
   cause. Left as designed.
5. **O-4 unchanged**: `docs/tasks.md` R-7 is *half* stale — its `LANG_CHOICE` blind spot is closed,
   its "key missing from **both** tables" blind spot is live and now covers seven new call sites.
   PM's edit, not mine.

---

## 10. Dev-map updates

`docs/dev-map.md` — see §7 C-2 for the six edits: `# Paths` (+`CRED_MODE`), `# State files`
(+`_write_private`), `# Config generation` (mechanism named), two new "Reusable utilities" rows
(`_write_private`, `sweep_credential_modes`), the `_plain` row's non-doctor callers, and the V-1
neutralisation recipe plus the `install.sh` `sed`-extraction idiom under "Patterns to avoid".

---

## 11. Insight to surface

- `mkstemp` creates at `0o600` as `open(2)`'s **mode argument**, so umask still masks it — measured `0400` at umask `0o277`, which is why the `fchmod` on the empty descriptor is what makes the mode exact and not a redundant line · evidence: `bin/sc` `_write_private()`, T-13 stage-4 harness
- A shell function shadowing an external in a sweep harness must match on the **path argument's position**, not on `$2` — `stat -c '%a' "$path"` puts the path in `$3`, so a `$2`-keyed stub silently does nothing and the fault-injection case passes for the wrong reason · evidence: T-13 stage-4 sweep harness, first run reached 6 of 7 `perm_*` keys

---

## 12. Verdict

**READY FOR REVIEW.**

Implementation matches the approved design with no drift. `verify_all` shows **PASS 16 / WARN 1 /
FAIL 0 / SKIP 1** — zero delta against my own pre-edit measurement, with the single WARN attributed
to `02_SOLUTION_DESIGN.md`'s length and present before my first edit. The live service was witnessed
identical before and after (`MainPID=2887037`, `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`)
and `/etc/sing-box` was never written to. The regression the gate predicted I would ship (P-1: the
`fchmod` "simplified" away) is guarded by a measurement that shows bare `mkstemp` yielding `0400` at
umask `0o277`, and the fix's green is non-vacuous — the same spy against `HEAD` observes
`config.json` at `0o666` holding 5148 bytes of credentials at the publish instant. Nothing was
committed or pushed.

---

## 13. Post-review fix — stage-5 MINOR (dev-map citation drift)

Stage 5 PASSed with one MINOR finding owned by me: the safety warning under "Patterns to avoid"
cited `bin/sc:309` for `_init_files()`'s hard-coded `/var/lib/sing-box`.

**Verified, not taken on faith.** `grep -n '/var/lib/sing-box' bin/sc` puts the literal at
**`bin/sc:367`**; `_init_files()` itself begins at `bin/sc:364`. The reviewer's arithmetic is
right — `:309` was correct when I drafted the sentence and this task's own +58 lines to `bin/sc`
moved it out from under the citation. A reader following `:309` lands in unrelated code, and it
was the *safety* citation that had rotted.

**Form chosen: drift-proof, no line number.** The warning now reads "one of its `mkdir` calls
hard-codes `/var/lib/sing-box` as a `Path` literal — the only directory in the function not built
from a repointable constant". A number here earns nothing: the sentence already names the function,
so the reader greps `_init_files` and is done. The *semantic* anchor is strictly better than a
numeric one, because "the only `mkdir` not built from a repointable constant" is precisely the
property that makes the warning true, and it survives any future edit to `bin/sc` that a number
would not. This matches the habit already used two rows earlier in the same file (symbol +
"**below**", never an offset).

**Sibling scan — one other citation, and it is sound.** Extracting every `file:line` token from
this task's own added dev-map lines (`git diff -U0 docs/dev-map.md | grep '^+'`) yields exactly two:
the `bin/sc:309` above, and `.harness/scripts/check-i18n-parity.sh:48` in the new "don't run
`install.sh` to verify it" bullet. I checked the second rather than assuming: line 48 is
`sed -n '/^t() {/,/^}/p' "$FILE" > "$FRAG"`, which is the exact idiom the bullet cites as
precedent, and `git status --porcelain` confirms this task never touched that file, so it could not
have drifted. Left as written — it points into a stable harness script and names a specific line
worth reading. No other citations were added.

**Scope held.** `docs/dev-map.md` and this file only; `bin/sc`, `install.sh` and `docs/tasks.md`
untouched. Nothing in a markdown-only fix went anywhere near `/etc`, `install.sh`, the installed
`/usr/local/bin/sc`, or the live service, and nothing in the task pushed toward them.

**`verify_all` after the fix: PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — identical to the post-edit
measurement in §12, with the same single WARN attributable to `02_SOLUTION_DESIGN.md` (788 lines,
read-only to me). This document stays inside F.6's 500-line limit. Not committed, not pushed.
