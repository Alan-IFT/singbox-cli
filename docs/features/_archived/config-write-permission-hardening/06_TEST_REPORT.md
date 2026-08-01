# 06 — Test Report · T-13 `config-write-permission-hardening`

Mode: **full**. Deferred-human mode: every judgment call is ruled here. `01`…`05` were read as
binding and **not edited**. Conditions **C-3, C-5, C-6, C-7, C-8, C-9, C-13** and the final half of
**C-4** land on this stage and are discharged at §5. Verdict at §11.

**This stage rebuilt the harness rather than re-running stage 4's** (project precedent T-05/T-10/T-11;
stage 4 discarded its harnesses anyway — `05_CODE_REVIEW.md` NOTE-8). Both harnesses below were
written from `01_REQUIREMENT_ANALYSIS.md`'s acceptance criteria, not from `04_DEVELOPMENT.md`'s test
code, so a green cannot be green by construction. Every major assertion is shown failing on demand
against a pristine `HEAD` **clone** (§4).

---

## 1. Safety — witnesses, at three checkpoints

`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` — **never `is-active`** (C-14 §6):

| Checkpoint | Reading |
|---|---|
| **Start** (before any command of this stage) | `MainPID=2887037` · `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |
| **Middle** (after the Python harness, before the sweep harness's stability runs) | `MainPID=2887037` · `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |
| **End** (after `verify_all` and the post-archive simulation) | `MainPID=2887037` · `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST` |

Identical at all three, and identical to the baseline the dispatch handed over. The service was
neither restarted nor reloaded.

`/etc/sing-box/{config.json,nodes.json,settings.json}` and `/var/lib/sing-box` were witnessed
read-only (`os.lstat`: ino, mode, size, mtime, ctime) before and after **every** harness run and
compared programmatically — unchanged in all 21 runs (`ac12_safety_no_writes_outside`, which is
deliberately the **last** test so it witnesses the whole run):

```
/etc/sing-box            (11272671, 16877, 4096, 1785549971.64, 1785549971.64)
/etc/sing-box/config.json(11666092, 33152, 5882, 1785550000.57, 1785550000.57)   # 33152 = 0100600
/etc/sing-box/nodes.json (11272772, 33152,  633, 1785387632.88, 1785387632.88)
/etc/sing-box/settings.json(11272677, 33188, 86, 1785387641.34, 1785387641.34)   # 33188 = 0100644
/var/lib/sing-box        (15336152, 16877, 4096, 1785387564.30, 1785387564.30)
```

Nothing under `/etc` was written, chmod'd, moved or backed up. `install.sh` was **never executed** —
its functions were extracted with the project's `sed` idiom (`check-i18n-parity.sh:48`) and sourced.
The installed `/usr/local/bin/sc` was **never** invoked. `_init_files()` was **never driven**. The
auto-elevate re-exec was neutralised in every harness by the `sys.modules` `os`-shim
(`geteuid()` → 0, real `os` restored in a `finally`, asserted restored) — `bin/sc`'s source was never
edited, and no blanket "no `os.execvp`" guard was used. Nothing was committed or pushed.

---

## 2. Test plan — every acceptance criterion has a test

Two harnesses, both pasted verbatim and runnable at §10:
**P** = `t13_qa.py` (Python, 27 named assertions) · **S** = `t13_sweep.sh` (Bash, 79 named assertions).

| AC | Test case(s) | Harness |
|---|---|---|
| AC-1 | `ac1_empty_dir_0600` | P |
| AC-2 / BC-1 / BC-2 | `ac2_umask_0000`, `ac2_umask_0022`, `ac2_umask_0077`, **`ac2_umask_0277`** | P |
| AC-3 / BC-3 / BC-4 | `ac3_preexisting_modes` (0644, 0664, 0666, 0400, 0000 × both files) | P |
| AC-4 | `ac4_never_wide_empty_dir`, `ac4_never_wide_preexisting_0644` (C-8's two shapes) | P |
| AC-5 | `ac4_never_wide_preexisting_0644` (byte-count at the suspension point) | P |
| AC-6 / BC-9 | `ac6_ac8_write_failure` | P |
| AC-7 / NG-9 | `ac7_check_ordering` | P |
| AC-8 | `ac6_ac8_write_failure` (one line, no traceback, `Reload failed` + status asserted separately) | P |
| AC-9 / BC-11 | `ac9_concurrency` (12 forked double-runs) | P |
| AC-10 | `ac10_no_temp_survives` | P |
| AC-11 / BC-7 | `ac11_symlink_target` (+ destination content **and** mode control) | P |
| AC-12 | `ac12_safety_no_writes_outside` | P |
| AC-13 | `AC-13 placement`, `AC-13 banner is the LAST output` | S |
| AC-14 | `AC-14 call site is top-level/unconditional` + `AC-20 sweep touches no PHASE_*` | S |
| AC-15 / BC-15 | `AC-15 0644 …`, `AC-15 0600 mtime unchanged`, `AC-15 0400 NOT widened` | S |
| AC-16 | `AC-16 absent reported`, `AC-16 absent file NOT created` | S |
| AC-17 / BC-14 | `AC-17 problem line …`, `AC-17 execution continues past section` | S |
| AC-18 | `AC-18 sed extraction`, `AC-18 fragment parses (t/sweep/report)` | S |
| AC-19 | `AC-19 settings.json / rules/ not reported`, both modes unchanged | S |
| AC-20 | `AC-20 install_report byte-identical HEAD vs new` (168 lines, 12 combinations) | S |
| AC-21 | `check-i18n-parity.sh install.sh` → `OK: 48 keys` (first half); `C-7 en/zh transcripts differ` (second half) | S |
| AC-22 | `ac22_new_key_bilingual` | P |
| AC-23 | §6 — `verify_all` on the working tree vs a pristine **clone**, plus a post-archive simulation | — |
| AC-24 | `ac24_doctor_identical` (HEAD vs new, en and zh, one shared fixture) | P |
| AC-25 | §7 static check (both READMEs 235 lines, headings at identical line numbers) | — |
| AC-26 | §7 static API audit + a full harness run on **Python 3.8.2** | — |
| AC-27 / BC-15 | `AC-27 second run issues no chmod`, `AC-27 second run changes nothing` | S |
| behaviour 8 / NG-4 | `behaviour8_settings_untouched` | P |
| BC-13 | `BC-13 missing CRED_DIR` | S |

---

## 3. Boundary tests added

- umask `0o000`, `0o022`, `0o077`, `0o277` — through the helper **and** through the real call site.
- Pre-existing target at `0644`, `0664`, `0666`, `0400`, `0000` — for `config.json` **and** `nodes.json`.
- Target is a symlink (both `bin/sc` and the installer sweep), with the link destination's content,
  mode **and** inode asserted unchanged.
- Target is a **directory** named `config.json` (installer sweep → `perm_skip`).
- Configuration directory unwritable (`OSError` on the config-write path).
- Configuration directory entirely absent (installer sweep → two `perm_absent` lines).
- `stat` forced to fail; `stat` returning non-octal text (`not-a-mode 9x`); `stat` disagreeing with
  the chmod it just performed (the second `perm_problem` arm).
- `chmod` forced to fail.
- Concurrency: 12 rounds × 2 forked processes generating distinguishable documents into one fixture.
- A 12-node document (≈12.2 KB) so the write is large enough for the spy to observe real content.

---

## Adversarial tests

One independent reproducer per acceptance criterion carrying the security guarantee, each with a
stated failure hypothesis written **before** the run. Verdict rests on whether the implementation
survived these, not on whether stage 4's tests pass. Every reproducer below is new and mine.

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome |
|---|---|---|---|
| AC-2 | the `fchmod` is redundant, so a hostile umask leaves `0400` and the "exactly 0600" claim is a coincidence of the common umask | `python3 t13_qa.py ac2_umask_0277` (NEW) | **Survived.** `config.json` EXACTLY `0600`; the bare-`mkstemp` control in the same run gives `0400`, so the `fchmod` is demonstrably load-bearing. |
| AC-3 | `mkstemp`'s mode argument is ignored for the existing target, so a legacy `0644` file stays `0644` | `python3 t13_qa.py ac3_preexisting_modes` (NEW) | **Survived.** `644/664/666/400/000 → 0600` with the new content, for both credential documents. Tried to break it by pre-creating at `0000`; root-less `os.replace` still published a `0600` inode. |
| AC-4 (shape 1) | the mode is only narrowed *after* the bytes land, so a snapshot at the publish instant catches a wide file holding credentials | `python3 t13_qa.py ac4_never_wide_empty_dir` (NEW spy on `os.replace`/`os.chmod`) | **Survived.** Only object holding new bytes is `config.json.tmp.<pid>.<rand>` at `0o600`, 12206 bytes. |
| AC-4 (shape 2) + AC-5 | with a `0644` file already at the target, the write truncates it in place, so the user's document is destroyed before the new one is durable | `python3 t13_qa.py ac4_never_wide_preexisting_0644` (NEW) | **Survived.** At the suspension point the pre-existing target is still 34 bytes at `0644` — byte-identical; afterwards `0600` with the new document. |
| AC-4/AC-5 **non-vacuity** | if the spy cannot fail, it proves nothing | same spy against a pristine **clone** of `HEAD` (`ac4_head_must_fail_*`) | **HEAD FAILED, as required.** Shape 1: `config.json` observed at **`0o666` holding 12206 bytes** at the publish instant. Shape 2: target holds 12206 bytes (pre-run: 34) at `0o644`. **Stage 4's claim independently reproduced** — same mode `0o666`, byte count differs only because my fixture carries 12 nodes rather than theirs. |
| AC-6 / AC-8 | an `OSError` escapes as a traceback, or several lines, or the previous document is already destroyed | `python3 t13_qa.py ac6_ac8_write_failure` (NEW; directory chmod'd `0500`, four **usable** `.srs` stubs so `_warn_degraded` is silent — C-9) | **Survived.** Exactly one stderr line naming the path and `Permission denied`; no `Traceback`; previous document byte-identical; directory state unchanged; `cmd_reload` → `SystemExit('Reload failed')` ⇒ status 1, asserted **separately**. |
| AC-7 | the atomic rewrite "fixed" E-12 by rolling the file back on a failing `sing-box check` | `python3 t13_qa.py ac7_check_ordering` (NEW, stub exits 1) | **Survived.** Config still written *before* the check, `0600`, parseable; the pre-existing `Config check failed` message still printed. |
| AC-9 | two racing generations interleave and publish a spliced document, or leave a temp | `python3 t13_qa.py ac9_concurrency` (NEW, 12 rounds × 2 `fork()`ed children with distinguishable node tags) | **Survived.** Every round: parses, contains node-a\* **xor** node-b\*, `0600`, no `*.tmp.*` left. |
| AC-11 | a pre-planted symlink redirects credential bytes to an arbitrary path | `python3 t13_qa.py ac11_symlink_target` (NEW) | **Survived.** `config.json` is a regular `0600` file with the new document; destination content, mode `0644` and inode unchanged; no `uuid` reached it. |
| AC-11 **non-vacuity** | — | `ac11_head_writes_through_link` against the HEAD clone | **HEAD FAILED, as required:** 12214 bytes of credentials written **through** the link into the decoy, and HEAD's trailing `os.chmod` then narrowed the *destination* to `600`. |
| AC-15/AC-17 (F-1) | a `t perm_*` call naming a key absent from **both** tables aborts the installer under `set -u` before `install_report()` ever runs | `bash t13_sweep.sh keys` (NEW) — extracted, unmodified `t()` + `sweep_credential_modes()` sourced under `bash -u`, 10 situations × 2 languages | **Survived.** All **seven** `perm_*` keys reached in **both** `LANG_CHOICE` values; `AFTER-SWEEP-REACHED` and `CHILD-STATUS=0` on all 20 runs. The abort path is real — a control probe with a bogus key gives `fmt: unbound variable`, status 127 — which is exactly why reaching all seven matters. |
| AC-17 | `set -euo pipefail` kills the run when `chmod` fails | `t13_sweep.sh` with `chmod() { return 1; }` (NEW) | **Survived.** `perm_problem` names file, mode and a runnable `chmod 600 <path>`; `AFTER-SWEEP-REACHED` still printed. |
| AC-19 | the sweep's loop can reach `settings.json` or `rules/*.srs` | `t13_sweep.sh` (NEW) | **Survived.** Neither appears in any output line; both still `644` afterwards. |
| AC-20 | the sweep perturbs the banner or the exit derivation | `AC-20 install_report byte-identical HEAD vs new` (NEW) — `install_report()` extracted from **both** revisions and driven over 2 languages × 2 `PHASE_CONFIG` × 3 `PHASE_SERVICE` | **Survived.** 168 lines byte-identical; statuses `2 × 0`, `10 × 1`, identical. |
| AC-24 | the doctor picked up a permission row, or `_plain`'s new callers moved it | `python3 t13_qa.py ac24_doctor_identical` (NEW — HEAD and new build driven against **one shared fixture** so a differing `mkdtemp` path cannot masquerade as a behaviour difference) | **Survived.** Byte-identical HEAD vs new in **both** languages (exit 2 both); 16 marked rows; no `permission` / `权限` / `0600` row; en and zh differ from each other. |
| AC-27 | the sweep is not idempotent and re-chmods on a second run | `AC-27 second run issues no chmod` (NEW, `chmod` shadowed by a **tattling** stub) | **Survived.** No `CHMOD-WAS-CALLED`; mode/mtime/size triple identical across the second run. |
| C-6 | `os.replace` preserving the source's mode is only a specification argument | `python3 t13_qa.py c6_replace_preserves_source_mode` (NEW, **with** falsifier) | **Survived.** `src 0600 → tgt 0644` ends `0600`; **falsifier** `src 0644 → tgt 0600` ends `0644`. What survives is the source's mode, not the target's. Fixture filesystem: `ext2/ext3` by `stat -f -c %T`, **`ext4`** by `df --output=fstype` (`/dev/nvme0n1p2`, the same filesystem as the repo) — **not** tmpfs. |

**What I tried to break and could not.** (a) Leaking the spy: the spy patches `sc.os`, not the
harness's `os`, and restores in `__exit__`; a deliberate check asserts `sys.modules["os"]` is the real
module after every load. (b) Making the spy vacuous: `_assert_never_wide` refuses to pass unless it
observed at least one **non-empty** file. (c) Fooling the C-5 key sweep: keys are matched on each
key's **own rendered marker text** per language, not on the key name, so a `t` that silently printed
the wrong format string would not count as "reached". (d) Making AC-8 count the wrong lines: the
fixture carries four *usable* `.srs` stubs so `_warn_degraded` is silent, and the `Reload failed`
line is asserted on a separate invocation. (e) Blaming the `mkstemp` name for the exposure: the
temp's **name** is visible in a world-readable directory but its inode is `0600` — gate §1.2's
ruling, re-confirmed by the spy's own records.

---

## 4. Non-vacuity — every green shown falsifiable

The pristine-HEAD comparison used `git clone --no-hardlinks` (`.git` is a **directory** in the clone,
verified with `stat -c '%F'`), never a `git worktree` — so A.1/A.2 stay PASS and the summary is real.
Clone HEAD = `11e545b`.

| Assertion | Against the new build | Against pristine `HEAD` |
|---|---|---|
| never wider than `0600` at the publish instant (empty dir) | PASS | **FAIL** — `config.json` at `0o666`, 12206 bytes |
| pre-existing target byte-identical at the publish instant | PASS | **FAIL** — target already holds 12206 bytes at `0o644` |
| symlinked target: destination untouched | PASS | **FAIL** — 12214 credential bytes written through the link |
| `install_report()` output and status | identical | identical (that is the criterion) |
| `sc doctor` output, en and zh | identical | identical (that is the criterion) |

---

## 5. Binding conditions discharged

**C-3 — harness pasted verbatim and runnable, with the umask-`0o277` guard as a named, separately
runnable assertion.** §10 carries both harnesses byte-for-byte as run. The guard is
`ac2_umask_0277` and runs alone:

```
$ SC_HEAD_SRC=.../head-clone/bin/sc python3 t13_qa.py ac2_umask_0277
PASS  ac2_umask_0277   0.03s  config.json EXACTLY 0600 at umask 0o277; bare mkstemp control = 0400
                              => os.fchmod is load-bearing
=== 1 passed, 0 failed (of 1) ===
```

`python3 t13_qa.py --list` enumerates all 27; `bash t13_sweep.sh keys` runs the C-5 matrix alone.

**C-5 (blocking) — all seven `perm_*` keys, both languages, `bash -u`, run continuing every time.**
Discharged. The **extracted, unmodified** `t()` and `sweep_credential_modes()` (via
`sed -n '/^sweep_credential_modes() {/,/^}/p'`, 40 lines, `bash -n` clean) were sourced into a
`bash -uo pipefail` child. Ten situations × two `LANG_CHOICE` values = 20 runs; `AFTER-SWEEP-REACHED`
and `CHILD-STATUS=0` on every one. Keys reached, **en and zh alike**:
`perm_header perm_ok perm_absent perm_fixed perm_problem perm_unknown perm_skip` — **all seven, none
unreachable, and none reached by calling `t` directly.** F-1's abort path is confirmed live by a
separate control (`t definitely_not_a_key` ⇒ `line 110: fmt: unbound variable`, status 127), which is
precisely why reaching all seven through the sweep is the only guard that exists.

**C-6 (blocking) — `os.replace` mode preservation, measured, with its falsification control, on a
named filesystem.** Discharged: see the C-6 row of the adversarial table. Filesystem named twice
(`stat -f -c %T` → `ext2/ext3`; `df --output=fstype` → `ext4`) so the measurement is not a tmpfs one.
V-2(b) is also measured (`c6_mkstemp_is_umask_masked`): `mkstemp` at umask `0o277` → `0400`, at
`0o000` → `0600`, confirming the design's "upper bound, not equality" reading.

**C-7 — which artefact discharged AC-21's second half.** The **two-transcript diff** did
(`C-7 en/zh transcripts differ`, 78 differing lines over the whole `perm_*` matrix), **not**
`check-i18n-parity.sh` §3b. §3b compares whole transcripts of all 48 keys and so proves the
`LANG_CHOICE` dispatch works; it cannot prove that any *new* key differs. `check-i18n-parity.sh
install.sh` → `OK: 48 keys, both languages`, exit 0, discharges AC-21's **first** half only.

**C-8 — AC-4 in both fixture shapes, plus non-vacuity.** Discharged: shape 1 (empty directory) and
shape 2 (pre-existing `0644` target, assertion excluding that target, paired with AC-5 and AC-3),
each re-run against the pristine `HEAD` clone and each **required to fail there** — both did.

**C-9 — AC-8 on the config-write path, four usable `.srs` stubs, `Reload failed` asserted
separately.** Discharged. `ac6_ac8_write_failure` fails the **config** write (not `nodes.json`), the
fixture's four `.srs` stubs are `b"SRS"` + 29 bytes (≥ `SRS_MIN_BYTES`) so `_warn_degraded` emits
nothing, the stderr line count is measured on `generate_config()`'s own output (exactly 1), and
`cmd_reload`'s pre-existing `Reload failed` line plus its non-zero status are asserted in a separate
invocation.

**C-13 — F-5 stated, not fixed.** **STATED:** `main()` calls `_init_files()` at **`bin/sc:2041`** and
assigns `LANG` at **`bin/sc:2042`**. After D-2 routed `_init_files()`'s nodes branch through
`save_nodes()`, a write failure during first-run initialisation renders
`t("Could not write {path}: {err}")` while `LANG` is still the module default `"en"` — i.e. **English
only on that one call site**. The zh entry exists and is reached from the other four call sites
(measured: `ac22_new_key_bilingual`, `note_save_nodes_exits`). This is strictly better than HEAD's
English traceback. **`_load_lang()` was NOT reordered before `_init_files()`** and no product code was
touched. Verified statically — this harness never drives `_init_files()`.

**C-14 — the six safety constraints.** §1. All honoured; the harnesses enforce them mechanically
rather than by convention.

**C-4 (final half) — AC-23's delta against a pristine clone, after archiving.** §6.

---

## 6. `verify_all` result and AC-23

| Run | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| Pristine **clone** of `HEAD` (`11e545b`, `.git` is a directory) | **17** | **0** | **0** | **1** |
| Working tree, this stage (before writing this report) | **16** | **1** | **0** | **1** |
| Working tree, **post-archive simulation** (task docs moved under `docs/features/_archived/`) | **17** | **0** | **0** | **1** |

**Every moved count attributed.** Exactly one step moves between the clone and the working tree:
`[F.6] Active task docs <=500 lines each` PASS → WARN. Cause: `02_SOLUTION_DESIGN.md` is **788
lines** against F.6's 500-line cap (and, once written, this report — C-3 requires the harness pasted
verbatim, which is the gate's own price for D-8's fourth deferral). The clone contains none of this
task's documents, so F.6 is PASS there. This is **exactly** gate finding F-3's prediction and T-05's
precedent, and the post-archive simulation confirms it clears on archive: F.6 excludes
`*/_archived/*`, so the count returns to `17 / 0 / 0 / 1`. Every other step — A.1, A.2, B.1, B.2,
B.3, E.1, E.2, E.3, E.4, E.4b, E.5, E.6, F.1, F.2, F.3, F.4, F.5 — is **identical** in all three runs.
F.4 (`insight-index.md ≤30 lines`) reads **PASS**, not WARN; the gate flagged it as a *may* and the
measurement refutes it. `[B.3] Lint` is the pre-existing hard-coded `SKIP` (`verify_all.sh:77`);
D-8/S-2 deliberately does not move it, and no `verify_all` step was added, removed or edited by any
stage of this task.

**AC-23 verdict:** satisfied on the gate's ruling ("no step may regress, and no count may move for a
reason the task cannot name") **and** on the literal zero-delta reading once the task documents are
archived. `bash .harness/scripts/verify_all.sh` ends with **FAIL: 0**.

---

## 7. Static audits

**AC-25 (documentation).** `README.md` and `README.zh-CN.md` are both **235 lines** and every
heading sits at an identical line number in both (`diff` of the heading line-number lists is empty).
`README.md:190` / `README.zh-CN.md:190` gain `(mode 600)` for `config.json`; `:218` in each gains the
security bullet naming the mechanism *and* the user-visible consequence (`sing-box check` now needs
root). `CHANGELOG.md` gains one Chinese `### 修复` bullet under `[Unreleased]`.
`docs/architecture.md:120` gains exactly one Chinese row in the 安全考量 table, leaving `:119`'s
`nodes.json` row untouched.

**AC-26 (Python floor).** **No Python 3.6 interpreter exists on this host and none is obtainable** —
`/usr/bin/python3.12` is the only system interpreter, and `uv python list --all-versions` offers
nothing older than **3.8.2**. I therefore state this plainly rather than asserting 3.6 compatibility:

- *Empirical, labelled as such:* the **entire** 27-assertion harness was re-run under **CPython
  3.8.2** (downloaded via `uv`) and passed 27/27, so the code is measured on 3.8.2 **and** 3.12.3, not
  on 3.12 alone. The 3.6–3.7 gap is **not** measured.
- *Static audit of the diff:* the only names this task introduces are `tempfile.mkstemp(dir=,
  prefix=)` (2.3+), `os.fchmod` (2.6+, POSIX), `os.fdopen`, `os.fsync`, `os.close`, `os.unlink`,
  `os.getpid`, `os.replace` (**3.3+**), and `json.dumps(..., ensure_ascii=False)`. No f-string, no
  walrus, no `unlink(missing_ok=)`, no positional-only syntax, no dataclass, no third-party import.
  The floor-relevant risk is `os.replace`, at 3.3. `capture_output=` appears exactly **3** times in
  both `HEAD` and the working tree — the pre-existing violations were neither touched nor added to
  (P-12 clean). `bin/sc:367`'s `/var/lib/sing-box` literal is untouched (O-1).

**Stage-5's MINOR is fixed.** `docs/dev-map.md:115-116` now reads "one of its `mkdir` calls hard-codes
`/var/lib/sing-box` as a `Path` literal — the only directory in the function not built from a
repointable constant", with no line number. Verified: the literal is at `bin/sc:367`, and the
drift-proof semantic anchor is the better form.

---

## 8. Behaviour changes — stated, not discovered

1. **`config.json`'s inode is no longer stable across regenerations** (gate Q5 / NOTE-7). **Measured:**
   HEAD `[12323576, 12323576, 12323576]`; new build `[12323576, 12323577, 12323576]` — a different
   inode on every consecutive regeneration (the filesystem legitimately recycles the just-freed
   number, so the assertion is "consecutive values differ", not "all distinct"). Harmless here:
   nothing in `bin/sc` holds a descriptor across a regeneration and nothing enumerates `CFG_DIR`
   (only `RULES_DIR.iterdir()`), which I re-checked. An external watcher keyed on the inode would see it.
2. **`save_nodes()` now `sys.exit`s where it raised** (R-8 / F-4). **Measured:** on the same fixture,
   HEAD raises `OSError: [Errno 13] Permission denied: …/nodes.json`; the new build raises
   `SystemExit('Could not write …/nodes.json: Permission denied')`. A traceback became one translated
   line — NFR-3's intent. Ruled by stage 5 (C-12) and not re-litigated here.
3. **NEW, not predicted by any upstream document: the write path now requires write permission on the
   *directory* where HEAD needed it only on the *file*.** Measured (`note_dir_write_required`): with
   the target pre-existing and writable but the directory at `0500`, HEAD **succeeds** (it reopens the
   existing inode with `O_TRUNC`) while the new build **fails loudly** and preserves the previous
   document. Assessment: **not reachable in production** — `sc` always runs as root
   (`bin/sc:88-89` auto-elevate) and root bypasses directory DAC; and on a genuinely read-only
   *filesystem* both builds fail with `EROFS` (reasoned, not measured — mounting one needs root).
   Recorded as a NOTE, not a defect. Worth one line on the board for T-14/T-20.

---

## 9. Defects found

**BLOCKER: none. CRITICAL: none. MAJOR: none.**

- **[MINOR — requirement wording] AC-4 as literally written is unsatisfiable, and contradicts NG-4.**
  AC-4 says "*every* regular file in the fixture configuration directory has mode `0600` or narrower,
  and no file there carries any group or other bit". `settings.json` lives in that directory, is
  deliberately left at the ambient-umask mode by NG-4 / DECISION-2 / D-6, and is **`0644` on this very
  host** (stage 1 E-8, re-witnessed at §1). So no correct implementation can satisfy AC-4 literally.
  **Reproducer:** run `ac4_never_wide_empty_dir` with `NON_CREDENTIAL = ()` — it fails on
  `('os.replace', 'settings.json', '0o664', 59)`, which is my fixture's own non-credential file.
  Gate C-8 anticipated this class and scoped out the *pre-existing target* but not `settings.json`.
  **Reading applied** (and the one the design's §13 already argues): in-scope **behaviour 3** —
  "every filesystem object that holds any byte of the **new content**" — which `settings.json` does
  not. The harness excludes it by name with that reason recorded at the exclusion, and pairs it with
  `behaviour8_settings_untouched`, which asserts `generate_config()` leaves `settings.json`'s mode,
  content and inode untouched and that `_write_private(SETTINGS_PATH` appears nowhere.
  **Owner: requirement-analyst (documentation only). No product change. Does not block delivery.**
- **[MINOR — pre-existing, stated per C-13] F-5, the English-only start-up render.** §5 C-13. Ruled by
  the gate as ship-as-is; confirmed present, not fixed. **Owner: PM board row (C-11).**
- **[NOTE] Directory-write requirement.** §8 item 3. **Owner: PM board row.**
- **[NOTE] A hand-made backup exists on this host** (`04_DEVELOPMENT.md` §9 item 1) — outside
  `CRED_FILES`, so invisible to the sweep. Correct per NG-11; re-confirmed, not acted on.

Nothing found requires a rollback to any agent.

---

## 10. Stability

- `t13_qa.py`: **10 consecutive full runs**, `27 passed, 0 failed` every time. Plus one run on
  CPython 3.8.2: `27 passed, 0 failed`. **No flakes.**
- `t13_sweep.sh`: **10 consecutive full runs**, `79 passed, 0 failed` every time. **No flakes.**
- `verify_all`: run 3 times (clone, working tree, post-archive simulation) — deterministic.
- Total: 21 harness runs, 0 failures, 0 flakes. The live-service and `/etc` witnesses were identical
  on every one.

---

## 11. Verdict

**PASS.**

The security property holds end to end, and the green is earned rather than assumed: the same spy
that reports "nothing wider than `0600` at the publish instant" for the new build reports
`config.json` at **`0o666` holding 12206 bytes of credentials** for a pristine `HEAD` clone, and the
same symlink fixture that leaves the decoy untouched for the new build has HEAD writing 12214
credential bytes straight through the link. AC-1…AC-12 are measured, not reasoned. The installer
sweep reaches all seven `perm_*` keys in both languages under `bash -u` with the run continuing every
single time — closing F-1's abort path for these keys, against a control proving that path is
genuinely live — and its two transcripts differ, which is what discharges AC-21's second half (C-7).
C-6's specification claim is now a measurement **with** its falsifier, on a named `ext4` fixture.
`install_report()`'s 168 lines and every exit status are byte-identical to HEAD across all twelve
phase combinations, and `sc doctor` is byte-identical in both languages with no permission row.

`bash .harness/scripts/verify_all.sh` ends **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — **no FAIL** — with
the single WARN fully attributed to F.6's 500-line cap on active task documents
(`02_SOLUTION_DESIGN.md` at 788 lines, plus this report, whose harness C-3 requires pasted verbatim),
present before this stage began and confirmed to clear on archive by an explicit post-archive
simulation that returns `17 / 0 / 0 / 1` — the clone's exact figure.

Three findings, all MINOR or NOTE, none blocking and none owned by the developer's code: AC-4's
literal wording contradicts NG-4 and needs the behaviour-3 reading (requirement-analyst, documentation
only); F-5 stands as ruled and is stated rather than fixed, with `_load_lang()` **not** reordered; and
one behaviour change no upstream document predicted — the new path needs *directory* write permission
where HEAD needed only *file* write permission — which is unreachable for a tool that always runs as
root.

The live service was witnessed identical at the start, middle and end (`MainPID=2887037`,
`ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`); `/etc/sing-box` and `/var/lib/sing-box` are
byte-for-byte unchanged; `install.sh` was never executed and the installed `/usr/local/bin/sc` was
never invoked. **Nothing was committed and nothing was pushed.**

---

## 12. The harnesses, verbatim (C-3)

Both files are reproduced exactly as run. They are self-contained: the only inputs are
`SC_REPO` / `SC_SRC` / `SC_HEAD_SRC` (Python) and `SC_REPO` / `SC_HEAD_REPO` (Bash), each defaulting
sensibly. Reproduce with:

```bash
git clone --no-hardlinks /home/alan/Programs/singbox-cli /tmp/qa/head-clone   # a CLONE, never a worktree
cd /tmp/qa
SC_HEAD_SRC=/tmp/qa/head-clone/bin/sc  python3 t13_qa.py          # 27 assertions
SC_HEAD_SRC=/tmp/qa/head-clone/bin/sc  python3 t13_qa.py ac2_umask_0277   # the C-3 guard, alone
SC_HEAD_REPO=/tmp/qa/head-clone        bash    t13_sweep.sh       # 79 assertions
SC_HEAD_REPO=/tmp/qa/head-clone        bash    t13_sweep.sh keys  # the C-5 matrix, alone
```

### 12.1 `t13_qa.py` — `bin/sc`, 27 named assertions

```python
#!/usr/bin/env python3
# T-13 config-write-permission-hardening — STAGE 6 (QA) INDEPENDENT HARNESS
#
# Written from 01_REQUIREMENT_ANALYSIS.md's acceptance criteria. It deliberately does NOT
# reuse stage 4's harness (which was discarded anyway): a green must not be green by
# construction.
#
# SAFETY (C-14, non-negotiable — this harness enforces them, it does not merely respect them):
#   * refuses to run as root (assert at import of the module under test);
#   * neutralises bin/sc's import-time auto-elevate by shimming `os` in sys.modules so
#     geteuid() reads 0 -- the source of bin/sc is NEVER edited -- and restores the real
#     `os` in a finally;
#   * never drives _init_files() (it hard-codes /var/lib/sing-box as a Path literal);
#   * never touches /etc, never runs install.sh, never invokes /usr/local/bin/sc,
#     never restarts or reloads the service;
#   * witnesses /etc/sing-box/* and /var/lib/sing-box read-only before and after.
#
# USAGE
#   python3 t13_qa.py                # run everything
#   python3 t13_qa.py ac2_umask_0277 # run ONE named assertion (C-3's separately-runnable
#                                    # umask-0o277 guard is exactly this name)
#   python3 t13_qa.py --list
#
# The build under test is chosen with SC_SRC (default: the repo working tree).
# The pristine-HEAD comparison uses SC_HEAD_SRC (a git CLONE, never a worktree).

import io
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import traceback
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from types import ModuleType

REPO = os.environ.get("SC_REPO", "/home/alan/Programs/singbox-cli")
SC_SRC = os.environ.get("SC_SRC", os.path.join(REPO, "bin", "sc"))
SC_HEAD_SRC = os.environ.get("SC_HEAD_SRC", "")
SCRATCH = os.environ.get(
    "SC_SCRATCH",
    "/tmp/claude-1000/-home-alan-Programs-singbox-cli/"
    "68c488a7-ff0d-4f82-acf8-1e6350c3ff46/scratchpad/qa/run")

LIVE_WITNESS = ["/etc/sing-box", "/etc/sing-box/config.json", "/etc/sing-box/nodes.json",
                "/etc/sing-box/settings.json", "/var/lib/sing-box"]

_results = []


# --------------------------------------------------------------------------- infrastructure

def load_sc(src):
    """Load bin/sc as a module WITHOUT mutating its source and WITHOUT re-execing sudo."""
    if os.geteuid() == 0:
        raise SystemExit("REFUSING: this harness must never run as root.")
    real_os = os
    shim = ModuleType("os")
    shim.__dict__.update(real_os.__dict__)
    shim.geteuid = lambda: 0            # bin/sc's `if os.geteuid() != 0:` branch is not taken
    mod = ModuleType("sc_under_test")
    mod.__file__ = src
    sys.modules["os"] = shim
    try:
        with open(src) as fh:
            code = compile(fh.read(), src, "exec")
        exec(code, mod.__dict__)
    finally:
        sys.modules["os"] = real_os     # restored even if bin/sc raises
    assert sys.modules["os"] is real_os, "the os shim leaked into the harness"
    assert mod.os is shim, "bin/sc did not pick up the shim"
    assert mod.os is not real_os
    return mod


def stub_sing_box(root, rc=0, msg=""):
    p = os.path.join(root, "sing-box-stub")
    with open(p, "w") as fh:
        fh.write("#!/bin/sh\n")
        if msg:
            fh.write("echo %s 1>&2\n" % json.dumps(msg))
        fh.write("exit %d\n" % rc)
    os.chmod(p, 0o755)
    return p


NODE_TEMPLATE = {
    "type": "vless", "server": "203.0.113.7", "server_port": 443,
    "uuid": "11111111-2222-3333-4444-555555555555", "flow": "xtls-rprx-vision",
    "tls": {"enabled": True, "server_name": "example.invalid",
            "utls": {"enabled": True, "fingerprint": "chrome"},
            "reality": {"enabled": True,
                        "public_key": "PUBKEYPUBKEYPUBKEYPUBKEYPUBKEYPUBKEYPUBKEY",
                        "short_id": "abcd1234"}},
}


def make_nodes(n=12, salt="a"):
    nodes = []
    for i in range(n):
        d = json.loads(json.dumps(NODE_TEMPLATE))
        d["tag"] = "node-%s%02d" % (salt, i)
        d["uuid"] = "%s%s" % (salt * 8, "-2222-3333-4444-555555555555")
        nodes.append(d)
    return {"active": nodes[0]["tag"], "nodes": nodes}


def new_fixture(name, srs="usable", nodes=None, settings=True):
    """A redirected configuration directory. Never /etc. Returns its path."""
    os.makedirs(SCRATCH, exist_ok=True)
    root = tempfile.mkdtemp(prefix="fx-%s-" % name, dir=SCRATCH)
    cfg = os.path.join(root, "sing-box")
    os.makedirs(os.path.join(cfg, "rules"))
    if srs == "usable":
        # four USABLE .srs stubs => _warn_degraded is silent (C-9)
        for fname in ("geoip-cn.srs", "geosite-cn.srs",
                      "geosite-google.srs", "geosite-private.srs"):
            with open(os.path.join(cfg, "rules", fname), "wb") as fh:
                fh.write(b"SRS" + b"\x00" * 29)
    with open(os.path.join(cfg, "nodes.json"), "w") as fh:
        json.dump(nodes if nodes is not None else make_nodes(), fh, indent=2)
    os.chmod(os.path.join(cfg, "nodes.json"), 0o600)
    if settings:
        with open(os.path.join(cfg, "settings.json"), "w") as fh:
            json.dump({"default_tun": True, "mode": "rule", "lang": "en"}, fh, indent=2)
    return root, cfg


def point_at(sc, cfg, sb_bin=None, lang="en"):
    sc.CFG_DIR = Path(cfg)
    sc.CFG_PATH = Path(cfg) / "config.json"
    sc.NODES_PATH = Path(cfg) / "nodes.json"
    sc.SETTINGS_PATH = Path(cfg) / "settings.json"
    sc.RULES_DIR = Path(cfg) / "rules"
    sc.SYSTEMD = False
    sc.OPENRC = False
    sc.CLASH_PORT = 29090
    sc.LANG = lang
    if sb_bin:
        sc.SB_BIN = sb_bin
    return sc


def imode(p):
    return stat.S_IMODE(os.lstat(p).st_mode)


def dir_state(d):
    out = {}
    for name in sorted(os.listdir(d)):
        p = os.path.join(d, name)
        st = os.lstat(p)
        out[name] = (stat.S_IFMT(st.st_mode), stat.S_IMODE(st.st_mode), st.st_size)
    return out


def witness_live():
    w = {}
    for p in LIVE_WITNESS:
        try:
            st = os.lstat(p)
            w[p] = (st.st_ino, st.st_mode, st.st_size, st.st_mtime, st.st_ctime)
        except OSError as e:
            w[p] = ("ERR", e.errno)
    return w


class Fail(AssertionError):
    pass


def check(cond, msg):
    if not cond:
        raise Fail(msg)


# ---------------------------------------------------------------- the publish-instant spy

class PublishSpy:
    """Suspends the write at the last instant before the new content is published.

    Hooks BOTH os.replace and os.chmod on the module under test, because the two builds
    publish differently and the comparison must be symmetric:
      * the NEW build publishes with os.replace(tmp, target) -- the spy fires with the
        target still holding the OLD document;
      * HEAD publishes with Path.write_text(target) and then os.chmod(target, 0o600) --
        the spy fires with the target already holding the NEW bytes at its creation mode.
    In each case the spy observes the build's own last instant before the target both
    holds the new content AND carries its final mode. It records every regular file in
    the configuration directory, then delegates to the real call.
    """

    def __init__(self, sc, cfgdir):
        self.sc = sc
        self.cfgdir = cfgdir
        self.obs = []
        self._real_replace = None
        self._real_chmod = None

    def _snap(self, why, arg):
        recs = []
        for name in sorted(os.listdir(self.cfgdir)):
            p = os.path.join(self.cfgdir, name)
            st = os.lstat(p)
            if stat.S_ISREG(st.st_mode):
                recs.append((name, stat.S_IMODE(st.st_mode), st.st_size))
        self.obs.append({"why": why, "arg": str(arg), "files": recs})

    def __enter__(self):
        self._real_replace = self.sc.os.replace
        self._real_chmod = self.sc.os.chmod

        def spy_replace(src, dst, *a, **kw):
            if os.path.dirname(os.path.abspath(str(dst))) == os.path.abspath(self.cfgdir):
                self._snap("os.replace", dst)
            return self._real_replace(src, dst, *a, **kw)

        def spy_chmod(path, mode, *a, **kw):
            if os.path.dirname(os.path.abspath(str(path))) == os.path.abspath(self.cfgdir):
                self._snap("os.chmod", path)
            return self._real_chmod(path, mode, *a, **kw)

        self.sc.os.replace = spy_replace
        self.sc.os.chmod = spy_chmod
        return self

    def __exit__(self, *exc):
        # ALWAYS restore: a leaked spy corrupts every later assertion (gate P-11).
        self.sc.os.replace = self._real_replace
        self.sc.os.chmod = self._real_chmod
        return False


# =========================================================================== ACCEPTANCE TESTS

def ac1_empty_dir_0600():
    """AC-1 config.json and nodes.json reach 0600 from an empty directory."""
    root, cfg = new_fixture("ac1")
    os.unlink(os.path.join(cfg, "nodes.json"))
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    sc.save_nodes(make_nodes(2))
    check(imode(os.path.join(cfg, "nodes.json")) == 0o600,
          "nodes.json is %o" % imode(os.path.join(cfg, "nodes.json")))
    err = io.StringIO()
    with redirect_stderr(err):
        ok = sc.generate_config()
    check(ok is True, "generate_config returned %r; stderr=%r" % (ok, err.getvalue()))
    check(imode(os.path.join(cfg, "config.json")) == 0o600,
          "config.json is %o" % imode(os.path.join(cfg, "config.json")))
    json.loads(open(os.path.join(cfg, "config.json")).read())
    return "nodes.json 0600, config.json 0600, both parse"


def _umask_case(mask):
    root, cfg = new_fixture("um%o" % mask)
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    old = os.umask(mask)
    try:
        # helper directly
        sc._write_private(Path(cfg) / "direct.json", '{"k": 1}')
        m_direct = imode(os.path.join(cfg, "direct.json"))
        # and through the real call site
        err = io.StringIO()
        with redirect_stderr(err):
            ok = sc.generate_config()
        m_cfg = imode(os.path.join(cfg, "config.json"))
        # the CONTROL that makes the fchmod demonstrably load-bearing:
        fd, tmp = tempfile.mkstemp(dir=cfg)
        os.close(fd)
        m_bare = imode(tmp)
        os.unlink(tmp)
    finally:
        os.umask(old)
    check(ok is True, "generate_config failed at umask %o: %s" % (mask, err.getvalue()))
    check(m_direct == 0o600, "umask %o: _write_private gave %o" % (mask, m_direct))
    check(m_cfg == 0o600, "umask %o: config.json is %o" % (mask, m_cfg))
    return m_bare


def ac2_umask_0000():
    """AC-2 / BC-1 umask 0o000."""
    b = _umask_case(0o000)
    return "config.json 0600; bare mkstemp control = %o" % b


def ac2_umask_0022():
    """AC-2 umask 0o022."""
    b = _umask_case(0o022)
    return "config.json 0600; bare mkstemp control = %o" % b


def ac2_umask_0077():
    """AC-2 umask 0o077."""
    b = _umask_case(0o077)
    return "config.json 0600; bare mkstemp control = %o" % b


def ac2_umask_0277():
    """AC-2 / BC-2 umask 0o277 -- THE named separately-runnable guard (gate C-3/Q1/P-1).

    Exactly 0600, NOT 0400. A bare mkstemp under this umask yields 0400, so this is the
    single assertion that proves os.fchmod is load-bearing rather than redundant.
    """
    bare = _umask_case(0o277)
    check(bare == 0o400,
          "control failed: bare mkstemp at umask 0o277 gave %o, expected 0400" % bare)
    return ("config.json EXACTLY 0600 at umask 0o277; bare mkstemp control = 0400 "
            "=> os.fchmod is load-bearing")


def ac3_preexisting_modes():
    """AC-3 / BC-3 / BC-4 pre-existing target at 0644/0664/0666/0400/0000."""
    out = []
    for mode in (0o644, 0o664, 0o666, 0o400, 0o000):
        root, cfg = new_fixture("ac3-%o" % mode)
        sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
        target = os.path.join(cfg, "config.json")
        with open(target, "w") as fh:
            fh.write("OLD-DOCUMENT")
        os.chmod(target, mode)
        err = io.StringIO()
        with redirect_stderr(err):
            ok = sc.generate_config()
        check(ok is True, "generate_config failed from %o: %s" % (mode, err.getvalue()))
        got = imode(target)
        body = open(target).read()
        check(got == 0o600, "from %o ended at %o" % (mode, got))
        check(body != "OLD-DOCUMENT" and '"outbounds"' in body,
              "from %o: content was not replaced" % mode)
        # nodes.json too
        os.chmod(os.path.join(cfg, "nodes.json"), mode)
        sc.save_nodes(make_nodes(2))
        check(imode(os.path.join(cfg, "nodes.json")) == 0o600,
              "nodes.json from %o ended at %o" % (mode, imode(os.path.join(cfg, "nodes.json"))))
        out.append("%o->0600" % mode)
    return "config.json and nodes.json: " + ", ".join(out)


def _spy_run(src, shape):
    """Run one generation under the publish spy. shape in {'empty','preexisting-0644'}."""
    root, cfg = new_fixture("spy")
    sc = point_at(load_sc(src), cfg, stub_sing_box(root))
    pre = None
    if shape == "preexisting-0644":
        target = os.path.join(cfg, "config.json")
        pre = '{"pre": "existing user document"}\n'
        with open(target, "w") as fh:
            fh.write(pre)
        os.chmod(target, 0o644)
    old = os.umask(0o000)
    try:
        with PublishSpy(sc, cfg) as spy:
            err = io.StringIO()
            with redirect_stderr(err):
                ok = sc.generate_config()
    finally:
        os.umask(old)
    return sc, cfg, spy, ok, err.getvalue(), pre


# settings.json is NOT a credential document: NG-4 / DECISION-2 deliberately leave it at
# the ambient-umask mode, and on the live host it really is 0644 (stage 1 E-8). AC-4's
# literal wording ("every regular file in the fixture configuration directory") therefore
# contradicts NG-4 and is unsatisfiable on any host that has a settings.json. The reading
# applied here is in-scope behaviour 3 -- "every filesystem object that holds any byte of
# the NEW CONTENT" -- which settings.json does not. Reported as a documentation defect.
NON_CREDENTIAL = ("settings.json",)


def _assert_never_wide(spy, exclude=()):
    check(spy.obs, "the spy never fired -- vacuous")
    saw_content = False
    wide = []
    for o in spy.obs:
        for name, mode, size in o["files"]:
            if name in exclude or name in NON_CREDENTIAL:
                continue
            if size > 0:
                saw_content = True
            if mode & 0o077:
                wide.append((o["why"], name, oct(mode), size))
    check(saw_content,
          "spy observed no non-empty file -- vacuous (it must have seen real content)")
    check(not wide, "files wider than 0600 at the publish instant: %r" % (wide,))


def ac4_never_wide_empty_dir():
    """AC-4 shape 1 (C-8): empty directory, umask 0o000, nothing ever group/other-readable."""
    before_settings = None
    sc, cfg, spy, ok, err, _ = _spy_run(SC_SRC, "empty")
    check(ok is True, "generate_config failed: %s" % err)
    _assert_never_wide(spy)
    return "spy fired %d time(s); observed %r; nothing wider than 0600 (settings.json excluded per NG-4)" % (
        len(spy.obs), [(o["why"], o["files"]) for o in spy.obs])


def behaviour8_settings_untouched():
    """In-scope behaviour 8 / NG-4 / D-6: settings.json is written unchanged."""
    root, cfg = new_fixture("b8")
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    sp = os.path.join(cfg, "settings.json")
    os.chmod(sp, 0o644)
    before = (imode(sp), open(sp).read(), os.stat(sp).st_ino)
    err = io.StringIO()
    with redirect_stderr(err):
        ok = sc.generate_config()
    check(ok is True, err.getvalue())
    check((imode(sp), open(sp).read(), os.stat(sp).st_ino) == before,
          "generate_config touched settings.json")
    # and its own writer is still the plain, non-private one
    old = os.umask(0o000)
    try:
        sc.save_settings({"default_tun": True, "mode": "rule", "lang": "en"})
    finally:
        os.umask(old)
    check(imode(sp) == 0o644, "save_settings changed the mode to %o" % imode(sp))
    src = open(SC_SRC).read()
    check("_write_private(SETTINGS_PATH" not in src,
          "settings.json was routed through _write_private (D-6 forbids it)")
    return ("generate_config leaves settings.json untouched (0644, same inode); "
            "save_settings still uses the plain writer and does not pin a mode")


def ac4_never_wide_preexisting_0644():
    """AC-4 shape 2 + AC-5 + AC-3 (C-8): pre-existing 0644 target."""
    sc, cfg, spy, ok, err, pre = _spy_run(SC_SRC, "preexisting-0644")
    check(ok is True, "generate_config failed: %s" % err)
    # AC-4 (shape 2): every file OTHER THAN the user's pre-existing target is <=0600
    _assert_never_wide(spy, exclude=("config.json",))
    # AC-5: the pre-existing target is byte-identical at the suspension point
    seen = [(n, m, s) for o in spy.obs for (n, m, s) in o["files"] if n == "config.json"]
    check(seen, "the spy never saw config.json at all")
    for _n, m, s in seen:
        check(s == len(pre),
              "AC-5 violated: config.json is %d bytes at the suspension point, "
              "pre-run content is %d bytes" % (s, len(pre)))
        check(m == 0o644, "pre-existing target's mode changed under it: %o" % m)
    # AC-3: exactly 0600 with the new content afterwards
    target = os.path.join(cfg, "config.json")
    check(imode(target) == 0o600, "after: %o" % imode(target))
    check(open(target).read() != pre, "after: content not replaced")
    return ("other files at publish instant all <=0600; pre-existing target byte-identical "
            "(%d bytes, mode 0644) at the instant; 0600 with new content after" % len(pre))


def ac4_head_must_fail_empty_dir():
    """NON-VACUITY (C-8): the same spy against a pristine HEAD clone MUST fail."""
    check(SC_HEAD_SRC and os.path.exists(SC_HEAD_SRC),
          "SC_HEAD_SRC not set to a pristine HEAD clone of bin/sc")
    sc, cfg, spy, ok, err, _ = _spy_run(SC_HEAD_SRC, "empty")
    check(ok is True, "HEAD's generate_config failed: %s" % err)
    try:
        _assert_never_wide(spy)
    except Fail as e:
        return "HEAD FAILED as required: %s" % e
    raise Fail("HEAD PASSED the never-wide assertion -- the test is vacuous, investigate")


def ac4_head_must_fail_preexisting_0644():
    """NON-VACUITY (C-8) shape 2: HEAD must violate AC-5 (target truncated in place)."""
    check(SC_HEAD_SRC and os.path.exists(SC_HEAD_SRC), "SC_HEAD_SRC not set")
    sc, cfg, spy, ok, err, pre = _spy_run(SC_HEAD_SRC, "preexisting-0644")
    check(ok is True, "HEAD's generate_config failed: %s" % err)
    seen = [(n, m, s) for o in spy.obs for (n, m, s) in o["files"] if n == "config.json"]
    check(seen, "spy never saw config.json under HEAD")
    bad = [(m, s) for _n, m, s in seen if s != len(pre)]
    check(bad,
          "HEAD kept the pre-existing target byte-identical -- non-vacuity broken: %r" % (seen,))
    return ("HEAD FAILED AC-5 as required: at its publish instant config.json holds "
            "%d bytes (pre-run: %d) at mode %s" % (bad[0][1], len(pre), oct(bad[0][0])))


def ac6_ac8_write_failure():
    """AC-6 / AC-8 / BC-9 (C-9): OSError on the CONFIG-WRITE path."""
    root, cfg = new_fixture("ac6")
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    target = os.path.join(cfg, "config.json")
    pre = '{"previous": "document"}\n'
    with open(target, "w") as fh:
        fh.write(pre)
    os.chmod(target, 0o600)
    before = dir_state(cfg)
    os.chmod(cfg, 0o500)                     # unwritable directory, no root needed
    try:
        err = io.StringIO()
        with redirect_stderr(err):
            ok = sc.generate_config()
    finally:
        os.chmod(cfg, 0o700)
    text = err.getvalue()
    lines = [ln for ln in text.splitlines() if ln.strip()]
    check(ok is False, "generate_config returned %r" % ok)
    check(len(lines) == 1, "expected exactly one stderr line, got %d: %r" % (len(lines), lines))
    check("Traceback" not in text, "a traceback reached the user")
    check(target in lines[0], "the line does not name the path: %r" % lines[0])
    check("Permission denied" in lines[0], "the line does not name the OS cause: %r" % lines[0])
    check(open(target).read() == pre, "the previous document was modified")
    check(dir_state(cfg) == before, "directory changed: %r -> %r" % (before, dir_state(cfg)))
    # AC-8's other two clauses, asserted SEPARATELY (C-9)
    os.chmod(cfg, 0o500)
    try:
        err2 = io.StringIO()
        code = "NO-EXIT"
        with redirect_stderr(err2):
            try:
                sc.cmd_reload(None)
            except SystemExit as e:
                code = e.code
    finally:
        os.chmod(cfg, 0o700)
    check(code == sc.t("Reload failed"),
          "cmd_reload did not exit with the pre-existing 'Reload failed' line: %r" % (code,))
    check(code not in (0, None), "cmd_reload's exit status would be zero")
    return ("one stderr line %r; no traceback; previous document byte-identical; "
            "no leftover; cmd_reload -> SystemExit(%r) => status 1" % (lines[0], code))


def ac7_check_ordering():
    """AC-7 / NG-9 / E-12: a failing `sing-box check` does NOT roll the file back."""
    root, cfg = new_fixture("ac7")
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root, rc=1, msg="stub: bad config"))
    err = io.StringIO()
    with redirect_stderr(err):
        ok = sc.generate_config()
    target = os.path.join(cfg, "config.json")
    check(ok is False, "generate_config returned %r" % ok)
    check(os.path.exists(target), "the config was not written before the check")
    check(imode(target) == 0o600, "mode is %o" % imode(target))
    json.loads(open(target).read())
    check("Config check failed" in err.getvalue() or "配置检查失败" in err.getvalue(),
          "the pre-existing check-failure message is gone: %r" % err.getvalue())
    return "config written (0600, parseable) BEFORE the check; check failure reported"


def ac9_concurrency():
    """AC-9 / BC-11: two concurrent generations against one fixture."""
    root, cfg = new_fixture("ac9")
    sb = stub_sing_box(root)
    docs = {}
    for salt in ("a", "b"):
        s = point_at(load_sc(SC_SRC), cfg, sb)
        s.load_nodes = (lambda d: (lambda: json.loads(json.dumps(d))))(make_nodes(8, salt))
        docs[salt] = s
    rounds = 12
    for _i in range(rounds):
        target = os.path.join(cfg, "config.json")
        if os.path.exists(target):
            os.unlink(target)
        pids = []
        for salt in ("a", "b"):
            pid = os.fork()
            if pid == 0:
                rc = 0
                try:
                    with redirect_stderr(io.StringIO()), redirect_stdout(io.StringIO()):
                        docs[salt].generate_config()
                except BaseException:
                    rc = 1
                os._exit(rc)
            pids.append(pid)
        for pid in pids:
            os.waitpid(pid, 0)
        body = open(target).read()
        doc = json.loads(body)                       # parseable, not truncated
        tags = set(o.get("tag", "") for o in doc["outbounds"])
        check(("node-a00" in tags) != ("node-b00" in tags),
              "config.json is a mixture of both documents: %r" % sorted(tags))
        check(imode(target) == 0o600, "mode is %o" % imode(target))
        leftovers = [n for n in os.listdir(cfg) if ".tmp." in n]
        check(not leftovers, "temporaries survived: %r" % leftovers)
    return "%d concurrent double-runs: always one whole document, 0600, no leftovers" % rounds


def ac10_no_temp_survives():
    """AC-10: the directory gains exactly config.json."""
    root, cfg = new_fixture("ac10")
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    before = set(os.listdir(cfg))
    err = io.StringIO()
    with redirect_stderr(err):
        ok = sc.generate_config()
    check(ok is True, err.getvalue())
    after = set(os.listdir(cfg))
    check(after - before == {"config.json"}, "unexpected additions: %r" % (after - before,))
    check(before - after == set(), "files disappeared: %r" % (before - after,))
    return "added exactly {'config.json'}; nothing removed; no temporary survived"


def ac11_symlink_target():
    """AC-11 / BC-7 / DECISION-6 + C-10's falsification control."""
    root, cfg = new_fixture("ac11")
    sc = point_at(load_sc(SC_SRC), cfg, stub_sing_box(root))
    dest = os.path.join(cfg, "decoy.txt")
    dest_body = "DECOY CONTENT — must not receive a single credential byte\n"
    with open(dest, "w") as fh:
        fh.write(dest_body)
    os.chmod(dest, 0o644)
    dest_ino = os.stat(dest).st_ino
    os.symlink(dest, os.path.join(cfg, "config.json"))
    err = io.StringIO()
    with redirect_stderr(err):
        ok = sc.generate_config()
    target = os.path.join(cfg, "config.json")
    check(ok is True, err.getvalue())
    check(not os.path.islink(target), "config.json is still a symlink")
    check(stat.S_ISREG(os.lstat(target).st_mode), "config.json is not a regular file")
    check(imode(target) == 0o600, "config.json is %o" % imode(target))
    body = open(target).read()
    json.loads(body)
    check('"outbounds"' in body, "config.json does not hold the new document")
    # FALSIFICATION CONTROL (C-10): the link destination is untouched, in content AND mode
    check(open(dest).read() == dest_body, "the link destination's CONTENT changed")
    check(imode(dest) == 0o644, "the link destination's MODE changed to %o" % imode(dest))
    check(os.stat(dest).st_ino == dest_ino, "the link destination's inode changed")
    check("uuid" not in open(dest).read(), "credential bytes reached the link destination")
    return ("config.json is a regular 0600 file with the new document; destination content, "
            "mode 0644 and inode all unchanged")


def ac11_head_writes_through_link():
    """NON-VACUITY for AC-11: HEAD writes credentials THROUGH the link."""
    check(SC_HEAD_SRC and os.path.exists(SC_HEAD_SRC), "SC_HEAD_SRC not set")
    root, cfg = new_fixture("ac11h")
    sc = point_at(load_sc(SC_HEAD_SRC), cfg, stub_sing_box(root))
    dest = os.path.join(cfg, "decoy.txt")
    with open(dest, "w") as fh:
        fh.write("DECOY\n")
    os.chmod(dest, 0o644)
    os.symlink(dest, os.path.join(cfg, "config.json"))
    err = io.StringIO()
    with redirect_stderr(err):
        sc.generate_config()
    body = open(dest).read()
    if "uuid" in body:
        return ("HEAD FAILED as required: %d bytes of credentials were written THROUGH the "
                "link into %s (mode now %o)" % (len(body), dest, imode(dest)))
    raise Fail("HEAD did not write through the link -- non-vacuity broken")


def ac12_safety_no_writes_outside():
    """AC-12: nothing outside the fixture root is created or modified."""
    global _LIVE_BEFORE
    now = witness_live()
    check(now == _LIVE_BEFORE,
          "LIVE PATHS CHANGED:\n  before=%r\n  after =%r" % (_LIVE_BEFORE, now))
    strays = []
    for d in ("/tmp", tempfile.gettempdir()):
        try:
            strays += [os.path.join(d, n) for n in os.listdir(d)
                       if n.startswith("config.json.tmp.") or n.startswith("nodes.json.tmp.")]
        except OSError:
            pass
    check(not strays, "credential temporaries outside the fixture: %r" % strays)
    return "/etc/sing-box/*, /var/lib/sing-box unchanged (ino/mode/size/mtime/ctime); no stray temps"


def ac22_new_key_bilingual():
    """AC-22: the one new bin/sc key, both languages, same placeholders, no `failed:`."""
    sc = load_sc(SC_SRC)
    key = "Could not write {path}: {err}"
    zh = sc.TRANSLATIONS["zh"].get(key)
    check(zh is not None, "no zh entry for the new key")
    sc.LANG = "en"
    en_r = sc.t(key, path="/p", err="E")
    sc.LANG = "zh"
    zh_r = sc.t(key, path="/p", err="E")
    check(en_r != zh_r, "en and zh render identically: %r" % en_r)
    check("{path}" in zh and "{err}" in zh, "placeholder set differs: %r" % zh)
    check("failed:" not in key and "failed:" not in zh, "'failed:' polluted the grep")
    check("失败：" not in zh, "'失败：' polluted the grep")
    check("/p" in en_r and "E" in en_r and "/p" in zh_r and "E" in zh_r, "placeholders not filled")
    return "en=%r  zh=%r" % (en_r, zh_r)


def c6_replace_preserves_source_mode():
    """C-6: os.replace preserves the SOURCE's mode, WITH its falsification control."""
    os.makedirs(SCRATCH, exist_ok=True)
    d = tempfile.mkdtemp(prefix="c6-", dir=SCRATCH)
    fstype = subprocess.run(["stat", "-f", "-c", "%T", d],
                            stdout=subprocess.PIPE).stdout.decode().strip()
    fstype_df = subprocess.run(["df", "--output=fstype", d],
                               stdout=subprocess.PIPE).stdout.decode().splitlines()[-1].strip()
    out = []
    for src_mode, tgt_mode in ((0o600, 0o644), (0o644, 0o600)):
        src = os.path.join(d, "src-%o" % src_mode)
        tgt = os.path.join(d, "tgt-%o-%o" % (src_mode, tgt_mode))
        with open(src, "w") as fh:
            fh.write("S")
        os.chmod(src, src_mode)
        with open(tgt, "w") as fh:
            fh.write("T")
        os.chmod(tgt, tgt_mode)
        os.replace(src, tgt)
        got = imode(tgt)
        out.append((oct(src_mode), oct(tgt_mode), oct(got)))
        check(got == src_mode,
              "src %o onto target %o gave %o -- os.replace does NOT carry the source mode"
              % (src_mode, tgt_mode, got))
    check(out[1][2] == "0o644",
          "falsification control did not fire: %r" % (out,))
    return ("fs=%s (stat -f -c %%T) / %s (df --output=fstype); "
            "src0600->tgt0644 ends 0600; FALSIFIER src0644->tgt0600 ends 0644 "
            "=> what survives is the SOURCE's mode" % (fstype, fstype_df))


def c6_mkstemp_is_umask_masked():
    """C-6 (b) / V-2(b): mkstemp's 0o600 is an upper bound, not an equality."""
    os.makedirs(SCRATCH, exist_ok=True)
    d = tempfile.mkdtemp(prefix="c6b-", dir=SCRATCH)
    res = {}
    old = os.umask(0o277)
    try:
        fd, p = tempfile.mkstemp(dir=d)
        os.close(fd)
        res["0o277"] = imode(p)
    finally:
        os.umask(old)
    old = os.umask(0o000)
    try:
        fd, p = tempfile.mkstemp(dir=d)
        os.close(fd)
        res["0o000"] = imode(p)
    finally:
        os.umask(old)
    check(res["0o277"] == 0o400, "mkstemp at umask 0o277 gave %o" % res["0o277"])
    check(res["0o000"] == 0o600, "mkstemp at umask 0o000 gave %o" % res["0o000"])
    return "mkstemp: umask 0o277 -> 0400, umask 0o000 -> 0600"


def ac24_doctor_identical():
    """AC-24: `sc doctor` output byte-identical (HEAD vs new) in BOTH languages."""
    check(SC_HEAD_SRC and os.path.exists(SC_HEAD_SRC), "SC_HEAD_SRC not set")
    outs = {}
    # ONE fixture, reused by both builds and both languages, so a differing mkdtemp path
    # cannot masquerade as a behaviour difference. cmd_doctor is read-only.
    root, cfg = new_fixture("doc")
    with open(os.path.join(cfg, "config.json"), "w") as fh:
        fh.write('{"log": {}}')
    os.chmod(os.path.join(cfg, "config.json"), 0o600)
    sb = stub_sing_box(root)
    for label, src in (("HEAD", SC_HEAD_SRC), ("NEW", SC_SRC)):
        for lang in ("en", "zh"):
            sc = point_at(load_sc(src), cfg, sb, lang=lang)
            # the ONLY dependency stubbed, identically for both builds: the network probe
            sc._egress_ip = lambda: "198.51.100.9"
            buf, ebuf = io.StringIO(), io.StringIO()
            code = None
            with redirect_stdout(buf), redirect_stderr(ebuf):
                try:
                    sc.cmd_doctor(None)
                except SystemExit as e:
                    code = e.code
            outs[(label, lang)] = (buf.getvalue(), code)
    for lang in ("en", "zh"):
        a, ca = outs[("HEAD", lang)]
        b, cb = outs[("NEW", lang)]
        check(a == b, "doctor output differs in %s:\n--- HEAD ---\n%s\n--- NEW ---\n%s"
              % (lang, a, b))
        check(ca == cb, "doctor exit status differs in %s: %r vs %r" % (lang, ca, cb))
    en_body = outs[("NEW", "en")][0]
    zh_body = outs[("NEW", "zh")][0]
    check(en_body != zh_body, "en and zh doctor output are identical -- dispatch is broken")
    for word in ("permission", "mode 600", "0600", "权限"):
        check(word not in en_body and word not in zh_body,
              "a permission row appeared in doctor output (NG-2/AC-24): %r" % word)
    labels = [ln for ln in en_body.splitlines() if ln.startswith("[")]
    return ("byte-identical HEAD vs NEW in en and zh (exit %r); %d marked rows; no permission "
            "row; en and zh differ from each other" % (outs[("NEW", "en")][1], len(labels)))


def note_inode_not_stable():
    """STATED BEHAVIOUR CHANGE (gate Q5 / NOTE-7): config.json's inode now changes."""
    root, cfg = new_fixture("note-ino")
    sb = stub_sing_box(root)
    inos = {}
    for label, src in (("HEAD", SC_HEAD_SRC), ("NEW", SC_SRC)):
        if not src:
            continue
        target = os.path.join(cfg, "config.json")
        if os.path.exists(target):
            os.unlink(target)
        sc = point_at(load_sc(src), cfg, sb)
        seq = []
        for _ in range(3):
            with redirect_stderr(io.StringIO()):
                sc.generate_config()
            seq.append(os.stat(target).st_ino)
        inos[label] = seq
    # NB: the filesystem legitimately RECYCLES the just-freed inode number, so the test is
    # "consecutive regenerations differ", never "all three values are distinct".
    check(len(set(inos["HEAD"])) == 1, "HEAD's inode was not stable: %r" % inos["HEAD"])
    seq = inos["NEW"]
    check(all(a != b for a, b in zip(seq, seq[1:])),
          "NEW's inode did not change between consecutive regenerations: %r" % seq)
    src = open(SC_SRC).read()
    check("CFG_DIR.iterdir" not in src and "listdir(str(CFG_DIR" not in src,
          "something now enumerates CFG_DIR -- the inode change may not be harmless")
    return ("HEAD ino %r (stable) vs NEW ino %r (new inode each regeneration). Harmless here: "
            "nothing holds a descriptor across a regeneration and nothing enumerates CFG_DIR."
            % (inos["HEAD"], inos["NEW"]))


def note_save_nodes_exits():
    """STATED BEHAVIOUR CHANGE (R-8 / F-4): save_nodes() now sys.exit()s instead of raising."""
    root, cfg = new_fixture("note-exit")
    outs = {}
    for label, src in (("HEAD", SC_HEAD_SRC), ("NEW", SC_SRC)):
        sc = point_at(load_sc(src), cfg, stub_sing_box(root))
        # the target must NOT exist, or HEAD's write_text simply reopens the existing
        # writable file and never fails -- see note_dir_write_required below.
        if os.path.exists(os.path.join(cfg, "nodes.json")):
            os.unlink(os.path.join(cfg, "nodes.json"))
        os.chmod(cfg, 0o500)
        try:
            err = io.StringIO()
            with redirect_stderr(err):
                try:
                    sc.save_nodes({"active": None, "nodes": []})
                    outs[label] = ("returned normally", "")
                except SystemExit as e:
                    outs[label] = ("SystemExit", e.code)
                except OSError as e:
                    outs[label] = ("OSError", str(e))
        finally:
            os.chmod(cfg, 0o700)
    check(outs["HEAD"][0] == "OSError", "HEAD did not raise OSError: %r" % (outs["HEAD"],))
    check(outs["NEW"][0] == "SystemExit", "NEW did not sys.exit: %r" % (outs["NEW"],))
    check("Traceback" not in str(outs["NEW"][1]), "a traceback survived")
    return "HEAD: %r  ->  NEW: SystemExit(%r) — traceback replaced by one translated line" % (
        outs["HEAD"], outs["NEW"][1])


def note_dir_write_required():
    """FOUND BY QA, not predicted by any upstream document: the new path needs DIRECTORY
    write permission where HEAD needed only FILE write permission.

    HEAD reopened the existing target (O_WRONLY|O_TRUNC) and so succeeded on a directory
    it could not create in. The new path creates a fresh object with mkstemp and therefore
    needs +w on the directory. Not reachable in production -- sc always runs as root
    (auto-elevate, bin/sc:88-89) and root bypasses directory DAC -- and a genuinely
    read-only *filesystem* makes both builds fail with EROFS. Recorded as a NOTE.
    """
    outs = {}
    for label, src in (("HEAD", SC_HEAD_SRC), ("NEW", SC_SRC)):
        root, cfg = new_fixture("note-dirw")
        target = os.path.join(cfg, "config.json")
        with open(target, "w") as fh:
            fh.write("PREVIOUS")
        os.chmod(target, 0o600)                 # file IS writable
        sc = point_at(load_sc(src), cfg, stub_sing_box(root))
        os.chmod(cfg, 0o500)                    # directory is NOT writable
        try:
            err = io.StringIO()
            with redirect_stderr(err):
                ok = sc.generate_config()
        finally:
            os.chmod(cfg, 0o700)
        outs[label] = (ok, imode(target), open(target).read()[:20])
    check(outs["HEAD"][0] is True, "HEAD unexpectedly failed too: %r" % (outs["HEAD"],))
    check(outs["NEW"][0] is False, "NEW unexpectedly succeeded: %r" % (outs["NEW"],))
    check(outs["NEW"][2] == "PREVIOUS", "NEW did not preserve the previous document")
    return ("HEAD succeeds (ok=True, wrote through the existing fd), NEW fails loudly and "
            "preserves the previous document. Divergence is confined to 'directory not "
            "writable but file writable', unreachable for root; EROFS fails both.")


def f5_english_only_at_startup():
    """C-13: STATE gate finding F-5. _init_files() runs BEFORE LANG is assigned.

    Read statically -- this harness must NEVER drive _init_files() (it hard-codes
    /var/lib/sing-box as a Path literal). NOT fixed: _load_lang() is not reordered.
    """
    lines = open(SC_SRC).read().splitlines()
    init_at = lang_at = None
    for i, ln in enumerate(lines, 1):
        if init_at is None and ln.strip() == "_init_files()":
            init_at = i
        if init_at and lang_at is None and ln.strip().startswith("LANG ="):
            lang_at = i
    check(init_at and lang_at, "could not locate the two statements")
    check(init_at < lang_at, "ordering changed: _init_files at %d, LANG at %d" % (init_at, lang_at))
    src = "\n".join(lines)
    check("save_nodes({\"active\": None, \"nodes\": []})" in src,
          "_init_files no longer delegates to save_nodes")
    return ("CONFIRMED, NOT FIXED: bin/sc:%d `_init_files()` precedes bin/sc:%d `LANG = ...`, "
            "so a nodes.json write failure during first-run initialisation renders the new key "
            "in English only. LANG's module default is 'en'; the zh entry exists and is reached "
            "from the other four save_nodes() call sites (ac22 + note_save_nodes_exits)."
            % (init_at, lang_at))


def head_no_chmod_left():
    """Static: no os.chmod survives on any credential path in bin/sc (stage-5 claim, re-checked)."""
    src = open(SC_SRC).read()
    hits = [(i + 1, ln.strip()) for i, ln in enumerate(src.splitlines()) if "chmod" in ln]
    code_hits = [h for h in hits if not h[1].startswith("#") and not h[1].startswith("*")]
    return "chmod occurrences in bin/sc: %r" % (code_hits,)


# =========================================================================== runner

TESTS = [
    ac1_empty_dir_0600,
    ac2_umask_0000, ac2_umask_0022, ac2_umask_0077, ac2_umask_0277,
    ac3_preexisting_modes,
    ac4_never_wide_empty_dir, ac4_never_wide_preexisting_0644, behaviour8_settings_untouched,
    ac4_head_must_fail_empty_dir, ac4_head_must_fail_preexisting_0644,
    ac6_ac8_write_failure, ac7_check_ordering, ac9_concurrency, ac10_no_temp_survives,
    ac11_symlink_target, ac11_head_writes_through_link,
    ac22_new_key_bilingual,
    c6_replace_preserves_source_mode, c6_mkstemp_is_umask_masked,
    ac24_doctor_identical,
    note_inode_not_stable, note_save_nodes_exits, note_dir_write_required,
    f5_english_only_at_startup,
    head_no_chmod_left,
    ac12_safety_no_writes_outside,          # LAST: it witnesses the whole run
]

_LIVE_BEFORE = None


def main(argv):
    global _LIVE_BEFORE
    if "--list" in argv:
        for t in TESTS:
            print(t.__name__, "-", (t.__doc__ or "").splitlines()[0])
        return 0
    if os.geteuid() == 0:
        print("REFUSING to run as root")
        return 2
    wanted = [a for a in argv if not a.startswith("-")]
    _LIVE_BEFORE = witness_live()
    print("live witness (read-only) before: %s" % json.dumps(
        {k: str(v) for k, v in _LIVE_BEFORE.items()}, indent=None))
    todo = [t for t in TESTS if not wanted or t.__name__ in wanted]
    check(todo, "no test matched %r" % wanted)
    npass = nfail = 0
    for t in todo:
        t0 = time.time()
        try:
            detail = t()
            npass += 1
            print("PASS  %-38s %5.2fs  %s" % (t.__name__, time.time() - t0, detail))
        except BaseException as e:
            nfail += 1
            print("FAIL  %-38s %5.2fs  %s: %s" % (t.__name__, time.time() - t0,
                                                  type(e).__name__, e))
            traceback.print_exc()
    print("\n=== %d passed, %d failed (of %d) ===" % (npass, nfail, len(todo)))
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

### 12.2 `t13_sweep.sh` — the installer sweep, 79 named assertions (`install.sh` never executed)

```bash
#!/usr/bin/env bash
# T-13 — STAGE 6 (QA) INSTALLER-SWEEP HARNESS.  install.sh is NEVER executed.
#
# It EXTRACTS the two functions with the project's proven sed idiom
# (.harness/scripts/check-i18n-parity.sh:48) and sources them, unmodified, into a
# `bash -u` child.  Nothing under /etc is ever read, written, chmod'd or moved:
# CRED_DIR is repointed at a temp fixture, which is exactly what AC-18 exists for.
#
# Discharges: C-5 (all seven perm_* keys x both LANG_CHOICE, under set -u, run
# continuing every time), C-7 (AC-21 second half by the two-transcript diff),
# AC-13/14/15/16/17/18/19/20/27, BC-13/BC-14/BC-15.
#
#   bash t13_sweep.sh            # everything
#   bash t13_sweep.sh keys       # only the C-5 seven-key x two-language matrix
set -uo pipefail

REPO="${SC_REPO:-/home/alan/Programs/singbox-cli}"
HEAD_REPO="${SC_HEAD_REPO:-}"
SCR="$(mktemp -d "${TMPDIR:-/tmp}/t13-sweep-XXXXXX")"
trap 'rm -rf "$SCR"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %-44s %s\n' "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %-44s %s\n' "$1" "$2"; }
want() { # want <name> <needle> <haystack>
    case "$3" in *"$2"*) ok "$1" "found: $2" ;; *) bad "$1" "MISSING: $2" ;; esac
}
wantnot() {
    case "$3" in *"$2"*) bad "$1" "PRESENT but must not be: $2" ;; *) ok "$1" "absent: $2" ;; esac
}

# ---- extraction (AC-18): column-0 anchors, the check-i18n-parity.sh:48 idiom -------------
extract() { # extract <file> <fnname> <out>
    sed -n "/^$2() {/,/^}/p" "$1" > "$3"
    test -s "$3"
}
extract "$REPO/install.sh" t                     "$SCR/t.sh"      || { echo "t() extraction failed"; exit 1; }
extract "$REPO/install.sh" sweep_credential_modes "$SCR/sweep.sh" || { echo "sweep extraction failed"; exit 1; }
extract "$REPO/install.sh" install_report        "$SCR/report.sh" || { echo "install_report extraction failed"; exit 1; }
ok "AC-18 sed extraction" "t()=$(wc -l < "$SCR/t.sh") lines, sweep=$(wc -l < "$SCR/sweep.sh") lines, install_report=$(wc -l < "$SCR/report.sh") lines"
# the extracted fragments must be syntactically complete on their own
for f in t sweep report; do
    if bash -n "$SCR/$f.sh"; then ok "AC-18 fragment parses ($f)" "bash -n clean"
    else bad "AC-18 fragment parses ($f)" "bash -n rejected the fragment"; fi
done

# ---- fixture builder ---------------------------------------------------------------------
mkfixture() { # mkfixture <name>  -> echoes the dir
    local d="$SCR/$1"
    mkdir -p "$d/rules"
    printf 'CONFIG' > "$d/config.json";  chmod 644 "$d/config.json"
    printf 'NODES'  > "$d/nodes.json";   chmod 600 "$d/nodes.json"
    printf 'SET'    > "$d/settings.json";chmod 644 "$d/settings.json"
    printf 'SRS'    > "$d/rules/geoip-cn.srs"; chmod 644 "$d/rules/geoip-cn.srs"
    echo "$d"
}

# ---- the runner: sources the UNMODIFIED extracts into a `bash -u` child -------------------
run_sweep() { # run_sweep <lang> <creddir> [extra-shell-code-injected-before-the-call]
    local lang="$1" dir="$2" extra="${3:-}"
    bash -uo pipefail -c '
        set -u
        LANG_CHOICE="'"$lang"'"
        CRED_DIR="'"$dir"'"
        CRED_FILES=(config.json nodes.json)
        CRED_MODE=600
        . "'"$SCR"'/t.sh"
        . "'"$SCR"'/sweep.sh"
        '"$extra"'
        sweep_credential_modes || true
        echo "AFTER-SWEEP-REACHED"
    ' 2>&1
    echo "CHILD-STATUS=$?"
}

case "${1:-all}" in keys|all) :;; esac

# ==========================================================================================
# C-5 — all seven perm_* keys, in BOTH LANG_CHOICE values, under set -u, run continuing
# ==========================================================================================
KEYS="perm_header perm_ok perm_absent perm_fixed perm_problem perm_unknown perm_skip"

# One fixture per key-producing situation; each situation is run in en and zh.
situation() { # situation <name> <lang> ; echoes transcript
    local n="$1" lang="$2" d
    case "$n" in
      ok)       d=$(mkfixture "s-ok-$lang");       chmod 600 "$d/config.json"; run_sweep "$lang" "$d" ;;
      fixed)    d=$(mkfixture "s-fixed-$lang");    run_sweep "$lang" "$d" ;;
      absent)   d=$(mkfixture "s-absent-$lang");   rm -f "$d/config.json" "$d/nodes.json"
                                                   run_sweep "$lang" "$d" ;;
      skiplink) d=$(mkfixture "s-link-$lang");     rm -f "$d/config.json"
                                                   printf 'VICTIM' > "$d/victim"; chmod 644 "$d/victim"
                                                   ln -s "$d/victim" "$d/config.json"
                                                   run_sweep "$lang" "$d" ;;
      skipdir)  d=$(mkfixture "s-dir-$lang");      rm -f "$d/config.json"; mkdir "$d/config.json"
                                                   run_sweep "$lang" "$d" ;;
      unknown)  d=$(mkfixture "s-unk-$lang");      run_sweep "$lang" "$d" 'stat() { return 1; }' ;;
      unknown2) d=$(mkfixture "s-unk2-$lang");     run_sweep "$lang" "$d" 'stat() { echo "not-a-mode 9x"; }' ;;
      problem)  d=$(mkfixture "s-prob-$lang");     run_sweep "$lang" "$d" 'chmod() { return 1; }' ;;
      problem2) d=$(mkfixture "s-prob2-$lang");    run_sweep "$lang" "$d" 'stat() { echo 644; }' ;;
      nodir)    d="$SCR/no-such-dir-$lang";        run_sweep "$lang" "$d" ;;
    esac
}

declare -A SEEN_EN SEEN_ZH
FULL_EN=""; FULL_ZH=""
for sit in ok fixed absent skiplink skipdir unknown unknown2 problem problem2 nodir; do
    for lang in en zh; do
        out="$(situation "$sit" "$lang")"
        # the run must ALWAYS continue past the section (F-1 / AC-17)
        want "C-5 continues past section [$sit/$lang]" "AFTER-SWEEP-REACHED" "$out"
        want "C-5 child exits 0 [$sit/$lang]"          "CHILD-STATUS=0"      "$out"
        if [ "$lang" = en ]; then FULL_EN="$FULL_EN$out"; else FULL_ZH="$FULL_ZH$out"; fi
    done
done

# which keys did the matrix actually reach?  Matched on each key's OWN rendered marker text.
reached() { # reached <transcript> <lang>
    local tx="$1" l="$2" k hit=""
    for k in $KEYS; do
        case "$l:$k" in
          en:perm_header)  pat="Checking credential file permissions in" ;;
          en:perm_ok)      pat="left unchanged" ;;
          en:perm_absent)  pat="not present" ;;
          en:perm_fixed)   pat="narrowed to" ;;
          en:perm_problem) pat="could not be narrowed" ;;
          en:perm_unknown) pat="its mode could not be read" ;;
          en:perm_skip)    pat="not a regular file" ;;
          zh:perm_header)  pat="检查凭据文件权限" ;;
          zh:perm_ok)      pat="未改动" ;;
          zh:perm_absent)  pat="不存在" ;;
          zh:perm_fixed)   pat="已收紧为" ;;
          zh:perm_problem) pat="无法收紧" ;;
          zh:perm_unknown) pat="读不到权限" ;;
          zh:perm_skip)    pat="不是普通文件" ;;
        esac
        case "$tx" in *"$pat"*) hit="$hit $k" ;; *) echo "UNREACHED:$k"; return 1 ;; esac
    done
    echo "all7:$hit"
}
r_en="$(reached "$FULL_EN" en)" && ok "C-5 all seven perm_* keys reached (en)" "$r_en" \
    || bad "C-5 all seven perm_* keys reached (en)" "$r_en"
r_zh="$(reached "$FULL_ZH" zh)" && ok "C-5 all seven perm_* keys reached (zh)" "$r_zh" \
    || bad "C-5 all seven perm_* keys reached (zh)" "$r_zh"

# C-7 / AC-21 second half — the two transcripts must DIFFER
printf '%s' "$FULL_EN" > "$SCR/tx-en.txt"
printf '%s' "$FULL_ZH" > "$SCR/tx-zh.txt"
if diff -q "$SCR/tx-en.txt" "$SCR/tx-zh.txt" >/dev/null; then
    bad "C-7 en/zh transcripts differ" "IDENTICAL — the LANG_CHOICE dispatch is broken"
else
    ok "C-7 en/zh transcripts differ" "$(diff "$SCR/tx-en.txt" "$SCR/tx-zh.txt" | grep -c '^[<>]') differing lines"
fi

if [ "${1:-all}" = keys ]; then
    printf '\n=== %d passed, %d failed ===\n' "$PASS" "$FAIL"; exit $((FAIL>0))
fi

# ==========================================================================================
# AC-15 / AC-16 / AC-19 / BC-15 — the behaviour matrix, with mode and mtime measured
# ==========================================================================================
d=$(mkfixture "m-main")
chmod 600 "$d/nodes.json"
touch -d '2001-02-03 04:05:06' "$d/nodes.json"
mt_before=$(stat -c '%Y' "$d/nodes.json")
out="$(run_sweep en "$d")"
want "AC-15 0644 reported repaired, both modes" "config.json: mode was 644 — narrowed to 600" "$out"
[ "$(stat -c '%a' "$d/config.json")" = 600 ] \
    && ok "AC-15 0644 -> 0600 on disk" "mode now 600" \
    || bad "AC-15 0644 -> 0600 on disk" "mode is $(stat -c '%a' "$d/config.json")"
want "AC-15 0600 reported OK"            "nodes.json: mode 600 — left unchanged" "$out"
[ "$(stat -c '%Y' "$d/nodes.json")" = "$mt_before" ] \
    && ok "AC-15 0600 mtime unchanged" "mtime $mt_before preserved (no chmod issued)" \
    || bad "AC-15 0600 mtime unchanged" "mtime moved"
wantnot "AC-19 settings.json not reported" "settings.json" "$out"
wantnot "AC-19 rules/ not reported"        "rules"         "$out"
[ "$(stat -c '%a' "$d/settings.json")" = 644 ] \
    && ok "AC-19 settings.json mode unchanged" "still 644" \
    || bad "AC-19 settings.json mode unchanged" "now $(stat -c '%a' "$d/settings.json")"
[ "$(stat -c '%a' "$d/rules/geoip-cn.srs")" = 644 ] \
    && ok "AC-19 rules/*.srs mode unchanged" "still 644" \
    || bad "AC-19 rules/*.srs mode unchanged" "now $(stat -c '%a' "$d/rules/geoip-cn.srs")"

d=$(mkfixture "m-0400"); chmod 400 "$d/config.json"
out="$(run_sweep en "$d")"
want "AC-15 0400 reported OK" "config.json: mode 400 — left unchanged" "$out"
[ "$(stat -c '%a' "$d/config.json")" = 400 ] \
    && ok "AC-15 0400 NOT widened" "still 400 (DECISION-3: narrowing only)" \
    || bad "AC-15 0400 NOT widened" "widened to $(stat -c '%a' "$d/config.json")"

d=$(mkfixture "m-abs"); rm -f "$d/config.json"
out="$(run_sweep en "$d")"
want "AC-16 absent reported"      "config.json: not present" "$out"
[ ! -e "$d/config.json" ] && ok "AC-16 absent file NOT created" "still absent" \
                          || bad "AC-16 absent file NOT created" "the sweep created it"

# BC-13 — directory absent entirely
out="$(run_sweep en "$SCR/no-such-dir-x")"
n=$(printf '%s' "$out" | grep -c 'not present')
[ "$n" = 2 ] && ok "BC-13 missing CRED_DIR" "two 'not present' lines, run continues" \
             || bad "BC-13 missing CRED_DIR" "got $n 'not present' lines"

# ==========================================================================================
# AC-11-analogue for the installer / C-10 falsification control — the symlink case
# ==========================================================================================
d=$(mkfixture "m-link"); rm -f "$d/config.json"
printf 'VICTIM-CONTENT' > "$d/victim"; chmod 644 "$d/victim"
ln -s "$d/victim" "$d/config.json"
out="$(run_sweep en "$d")"
want "symlink reported as not-a-regular-file" "config.json: not a regular file" "$out"
[ "$(stat -c '%a' "$d/victim")" = 644 ] \
    && ok "C-10 link destination MODE unchanged" "victim still 644 — chmod never reached it" \
    || bad "C-10 link destination MODE unchanged" "victim is now $(stat -c '%a' "$d/victim")"
[ "$(cat "$d/victim")" = "VICTIM-CONTENT" ] \
    && ok "C-10 link destination CONTENT unchanged" "byte-identical" \
    || bad "C-10 link destination CONTENT unchanged" "content changed"
[ -L "$d/config.json" ] && ok "symlink left in place, untouched" "still a symlink" \
                        || bad "symlink left in place, untouched" "the sweep replaced it"

# ==========================================================================================
# AC-17 / BC-14 / R-5 — chmod forced to fail: problem line AND execution continues
# ==========================================================================================
d=$(mkfixture "m-chmodfail")
out="$(run_sweep en "$d" 'chmod() { return 1; }')"
want "AC-17 problem line names file+mode+fix" "config.json: mode 644 could not be narrowed — run: chmod 600" "$out"
want "AC-17 execution continues past section" "AFTER-SWEEP-REACHED" "$out"
want "AC-17 child status 0"                   "CHILD-STATUS=0"      "$out"

# ==========================================================================================
# AC-27 — idempotency: a SECOND sweep over the result is a no-op (BC-15)
# ==========================================================================================
d=$(mkfixture "m-idem")
out1="$(run_sweep en "$d")"
st1="$(stat -c '%a:%Y:%s' "$d/config.json" "$d/nodes.json" "$d/settings.json" | tr '\n' ' ')"
out2="$(run_sweep en "$d" 'chmod() { echo "CHMOD-WAS-CALLED:$*"; return 0; }')"
st2="$(stat -c '%a:%Y:%s' "$d/config.json" "$d/nodes.json" "$d/settings.json" | tr '\n' ' ')"
wantnot "AC-27 second run issues no chmod" "CHMOD-WAS-CALLED" "$out2"
[ "$st1" = "$st2" ] && ok "AC-27 second run changes nothing" "$st2" \
                    || bad "AC-27 second run changes nothing" "$st1 -> $st2"
want "AC-27 second run reports OK"  "config.json: mode 600 — left unchanged" "$out2"

# ==========================================================================================
# AC-20 — install_report(): byte-identical output AND status, HEAD vs new revision
# ==========================================================================================
if [ -n "$HEAD_REPO" ] && [ -f "$HEAD_REPO/install.sh" ]; then
    extract "$HEAD_REPO/install.sh" install_report "$SCR/report-head.sh"
    extract "$HEAD_REPO/install.sh" t              "$SCR/t-head.sh"
    drive_report() { # drive_report <tfrag> <reportfrag>
        local tf="$1" rf="$2" lang pc ps
        for lang in en zh; do for pc in ok failed; do for ps in started dead enabled; do
            bash -uo pipefail -c '
                LANG_CHOICE="'"$lang"'"; PHASE_CONFIG="'"$pc"'"; PHASE_SERVICE="'"$ps"'"
                PHASE_RULESETS="ok"; INIT_SYS="systemd"
                INSTALL_LOG="/var/log/singbox-cli-install.log"; LOG_SINK="$INSTALL_LOG"
                SB_VER="1.0.0"; TARGET_USER="nobody"; INSTALL_SRC="local"
                . "'"$tf"'"; . "'"$rf"'"
                install_report; echo "STATUS=$?"
            ' 2>&1
        done; done; done
    }
    drive_report "$SCR/t-head.sh" "$SCR/report-head.sh" > "$SCR/rep-head.txt" 2>&1
    drive_report "$SCR/t.sh"      "$SCR/report.sh"      > "$SCR/rep-new.txt"  2>&1
    if diff -q "$SCR/rep-head.txt" "$SCR/rep-new.txt" >/dev/null; then
        ok "AC-20 install_report byte-identical HEAD vs new" \
           "$(wc -l < "$SCR/rep-new.txt") lines over 2 langs x 2 PHASE_CONFIG x 3 PHASE_SERVICE"
    else
        bad "AC-20 install_report byte-identical HEAD vs new" \
            "$(diff "$SCR/rep-head.txt" "$SCR/rep-new.txt" | head -20)"
    fi
    grep -c 'STATUS=' "$SCR/rep-new.txt" >/dev/null && \
        ok "AC-20 exit statuses captured" "$(grep -o 'STATUS=[0-9]*' "$SCR/rep-new.txt" | sort | uniq -c | tr '\n' ' ')"
else
    bad "AC-20 install_report HEAD comparison" "SC_HEAD_REPO not set to a pristine clone"
fi

# ==========================================================================================
# AC-13 / AC-14 / AC-20 — placement, read from the script (install.sh is NEVER executed)
# ==========================================================================================
ln_step7=$(grep -n '^t step7$' "$REPO/install.sh" | tail -1 | cut -d: -f1)
ln_sweep=$(grep -n '^sweep_credential_modes || true' "$REPO/install.sh" | cut -d: -f1)
ln_rep=$(grep -n '^install_report || exit 1' "$REPO/install.sh" | cut -d: -f1)
ln_exit=$(grep -n '^exit 0' "$REPO/install.sh" | tail -1 | cut -d: -f1)
tail_after=$(awk -v a="$ln_rep" 'NR>a && $0 !~ /^[[:space:]]*(#.*)?$/ && $0 !~ /^exit 0$/' "$REPO/install.sh" | wc -l)
[ -n "$ln_sweep" ] && [ "$ln_step7" -lt "$ln_sweep" ] && [ "$ln_sweep" -lt "$ln_rep" ] \
    && ok "AC-13 placement" "step7 line $ln_step7 < sweep $ln_sweep < install_report $ln_rep < exit 0 $ln_exit" \
    || bad "AC-13 placement" "step7=$ln_step7 sweep=$ln_sweep report=$ln_rep"
[ "$tail_after" = 0 ] && ok "AC-13 banner is the LAST output" "nothing but 'exit 0' follows install_report" \
                      || bad "AC-13 banner is the LAST output" "$tail_after statements follow install_report"
# AC-14: the call site must be at column 0 (top level), i.e. outside the step-7 `if`
awk -v n="$ln_sweep" 'NR==n' "$REPO/install.sh" | grep -q '^sweep_credential_modes' \
    && ok "AC-14 call site is top-level/unconditional" "column-0 call, outside step 7's if" \
    || bad "AC-14 call site is top-level/unconditional" "the call is indented"
# AC-20: the sweep must not read or write any PHASE_* variable
if grep -q 'PHASE' "$SCR/sweep.sh"; then bad "AC-20 sweep touches no PHASE_*" "PHASE found in the function"
else ok "AC-20 sweep touches no PHASE_*" "no PHASE token in the extracted function"; fi
# P-6 / P-7 regression guards, re-checked independently of stage 5
if grep -qE 'local +[A-Za-z_]+=\$\(' "$SCR/sweep.sh"; then bad "P-6 no local x=\$(...)" "found"
else ok "P-6 no local x=\$(...)" "none"; fi
if grep -nE '^[^[:space:]}]' "$SCR/sweep.sh" | grep -v '^1:' >/dev/null; then
    bad "P-7 no column-0 line inside the function" "$(grep -nE '^[^[:space:]}]' "$SCR/sweep.sh" | grep -v '^1:')"
else ok "P-7 no column-0 line inside the function" "only the header and the closing brace"; fi

# ==========================================================================================
# F-1's real teeth: a `t` call naming a key absent from BOTH tables kills the shell
# ==========================================================================================
probe="$(bash -uo pipefail -c '
    LANG_CHOICE="en"; . "'"$SCR"'/t.sh"
    t definitely_not_a_key "x" || true
    echo "SURVIVED"
' 2>&1; echo "ST=$?")"
case "$probe" in
  *SURVIVED*) ok  "F-1 documented (informational)" "an unknown key did NOT kill the shell here: $probe" ;;
  *)          ok  "F-1 confirmed live" "an unknown key aborts the shell under set -u ($probe) — which is why C-5's all-seven sweep is the only guard" ;;
esac

printf '\n=== %d passed, %d failed ===\n' "$PASS" "$FAIL"
exit $((FAIL>0))
```
