# 02 — Solution Design · T-30 `validate-before-baseline`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. **What changes:** the last thirteen executable lines of `generate_config()`
   (`bin/sc:2147-2161`) are re-ordered into *candidate → verdict → install → record*, the whole
   re-ordered tail becomes **one** guarded region so that no filesystem call in it can unwind
   without a rendered outcome (BC-11), and the checker's output stops being decoded by the
   process locale.
2. **What does not:** `_write_private()`, the drift quartet, `_warn_drift()`'s position, T-24's
   `try` region, `restart_service()` / `reload_or_restart()`, every caller of `generate_config()`,
   the emitted document's bytes, and every `sc doctor` row. No new function, no new module, no new
   parameter on any existing function.
3. **Where the seam is:** the existing credential writer, pointed at one extra name. The composed
   document reaches a fresh `O_EXCL` file inside `config.json`'s own directory *through
   `_write_private()`*, the checker is pointed at that file, and `config.json` is written by the
   same writer afterwards — so the transient object inherits T-13's five guarantees instead of
   restating any of them.

## Change ledger

| id | path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `generate_config()`'s tail (`:2147-2161`) replaced per `## Interfaces` I-1…I-11; two new `TRANSLATIONS["zh"]` entries (I-12, I-13); the entry `"Config check failed:\n{stderr}"` (`:136`) deleted with its only reader; `_doctor_run()`'s docstring (`:2539-2544`) widened to name its second caller | single developer |
| E-2 | `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | edit | one new assertion function (I-14) plus its entry in `TESTS` (`:537-547`), carrying **four** arms and the candidate-directory clause; the module docstring's "spawns no child process" claim stays true and is not edited | single developer |
| E-3 | `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | edit | `test_count` and `passing_count` `17` → `18`, in the same commit as E-2 | single developer |
| E-4 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | five rows and one bullet clause: `# Config generation` (`:41`, the new order, and its failure clause worded over **three** filesystem operations — creating the candidate, writing it, writing `config.json` — not two writes), the drift-quartet row (`:70`, `_record_generated()` now runs after a verdict that is not *rejected*), `_write_private` (`:77`, it now installs the candidate too), `_plain`/`_doctor_run` (`:78`, the runner has a caller outside `# doctor`), the contract-suite row (`:87`, 17 → 18 assertions), and the `## Patterns to follow` bullet at `:105-106`, whose "`capture_output=` at **three** sites" this change falsifies — two remain (`bin/sc:2258`, `:3523`). The bullet is one clause inside an existing bullet, not a sixth row | single developer |
| E-5 | `/home/alan/Programs/singbox-cli/docs/architecture.md` | edit | the relationship diagram at `:57-64` still draws `config.json ──> sing-box check`; it must draw the candidate ahead of `config.json` (Chinese, human-facing) | single developer |
| E-6 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | one Chinese entry: a configuration the checker rejects no longer replaces `config.json` and no longer becomes the drift baseline. Its freeze claim about `sc reload` / `sc add` / `sc update-rules` is scoped to **标准输出与退出码**; it may not say 输出, which the same paragraph contradicts by describing the reworded stderr | single developer |
| E-7 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | one new term, **candidate document**, beside the existing **checker verdict** entry (`:127-131`) | single developer |
| E-8 | `/home/alan/Programs/singbox-cli/docs/features/validate-before-baseline/04_DEVELOPMENT.md` | new | the developer's stage doc | single developer |
| E-9 | — schema-gap row — | — | the ordered call flow, the exact translation keys and the candidate's byte-level construction have no `## Byte-form specification` gate available: `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule` carries no numbered rows, so no row 3 / row 4 can be named and the section is omitted. Those units are carried by `## Interfaces` (call flow, key text) and `## Constraints` (obligations), per that rule's precedence clause | — |

**Not touched, deliberately:** `README.md` / `README.zh-CN.md` (neither quotes the check-failure
message — verified by grep), `install.sh`, `systemd/*`, `uninstall.sh`,
`.harness/scripts/verify_all.sh` (B.4 already reads the floor from E-3).

## Interfaces

**I-1 … I-11 are `generate_config()`'s new call flow**, in order. "was `:N`" cites the current
line the statement comes from; "new" means the statement does not exist today. Everything above
`:2146` — including `_warn_drift()` at `:2138` and the hoisted `text = json.dumps(...)` at `:2139`
— is unchanged and stays inside T-24's `try` region.

| id | surface | shape | invariant |
|---|---|---|---|
| I-1 | step 1 (new) — **two** statements | `name = None`, then `fd, name = tempfile.mkstemp(dir=str(CFG_PATH.parent), prefix=CFG_PATH.name + ".check.")` **as the first statement inside I-2's `try`** | `name = None` cannot raise, and it is the **only** statement of the tail that sits outside I-2's `try`. The candidate's name is fresh and exclusive (`O_CREAT\|O_EXCL\|O_NOFOLLOW`), lies in `config.json`'s **own** directory (BC-1, BC-2, and `os.replace` inside `_write_private` would raise `EXDEV` anywhere else), and cannot collide with a concurrent run's (BC-6). `dir=` is `CFG_PATH.parent`, never `CFG_DIR` or `TMPDIR`. Creating the candidate is a filesystem operation with `_write_private`'s own failure set — EROFS, ENOSPC, an absent or non-directory parent — so it is **inside** the guard and its failure renders I-9's line and returns `False`, never a traceback (BC-11) |
| I-2 | step 2 (new) | one `try:` … `except (OSError, ValueError)` … `finally:` statement, whose `finally` is `if name is not None:` → `try: os.unlink(name)` / `except OSError: pass` | The `try` opens **before** I-1's `mkstemp`, which is its first statement, so **every fallible statement of the tail is inside this one `try`**: creating the candidate, both `_write_private` calls, the checker call and both message writes. Nothing that can raise may ever be placed between `name = None` and the `try:` line: a filesystem call in that gap ends the run in a traceback with **no run-level outcome line**, because nothing above `generate_config()` catches an `OSError` — `main()`'s envelope takes `OverrideError` only, `cmd_reload()` has no `try`, and `cmd_update_rules()`'s recovery arm re-raises anything whose `.path` is not `SETTINGS_PATH`. Every outcome — accepted, rejected, cannot-validate, either `return False`, or an exception no handler catches — still passes through the `finally`. The `finally` therefore carries a precondition the `try` does not: it runs with `name is None` in exactly one state, the one where `mkstemp` raised and **no candidate exists**, and then it must do nothing. `if name is not None:` is the required spelling of that guard on the 3.6 floor — neither the walrus nor `Path.unlink(missing_ok=True)` exists before 3.8 — and never `except NameError`/`UnboundLocalError` or `except (OSError, TypeError)`, which would turn an exception into a control-flow signal and swallow a typo. BC-1 therefore reads: the candidate is removed on every outcome in which it was created, and there is **no** outcome in which it exists and the unlink is skipped. The unlink stays guarded so a failure to remove the candidate can never become the exception that leaves `generate_config()` |
| I-3 | step 3 (new) | `os.close(fd)` — immediately after I-1's `mkstemp`, second statement inside I-2's `try` | The descriptor `mkstemp` returned is closed before anything else runs; it is inside the `try` so even an impossible failure still removes the candidate |
| I-4 | step 4 (new) | `_write_private(Path(name), text)` | THE credential writer installs the composed document at the candidate: mode exactly `0600` set by `os.fchmod` on the still-empty descriptor before the first byte, `encoding="utf-8"`, `fsync`, atomic `os.replace`. No `chmod` after content, no second construction, no parameter added (BC-1, BC-7, Q-8) |
| I-5 | step 5 (new, replaces `:2156-2157`) | `code, out = _doctor_run([SB_BIN, "check", "-c", name])`, inside its own `try:` | **Exactly one** `sing-box check` process per `generate_config()` call (NFR-1), pointed at the candidate and never at `config.json`. `out` is already decoded `utf-8`/`replace` and already `_plain()`-neutralised. No `shutil.which()` pre-flight: the attempt *is* the test, which is what makes AC-4 and AC-5 one arm |
| I-6 | step 6 — cannot-validate (new) | `except OSError as e:` → one `sys.stderr.write("⚠️  " + t(I-12, path=CFG_PATH, err=_plain(str(e))) + "\n")`, then **fall through** to I-8 | A missing binary, an unexecutable binary and a binary that will not exec are one arm: install, record, warn, succeed (FR-4, Q-7). Nothing raises out of the invocation; no second opinion about host health is formed here |
| I-7 | step 7 — rejected (new, replaces `:2158-2160`) | `else:` `if code != 0:` → one `sys.stderr.write("⚠️  " + t(I-13, path=CFG_PATH, checker=out.replace(name, str(CFG_PATH)) or t("the checker reported an error, no message (exit {code})", code=code)) + "\n")`, then `return False` | `config.json` and the drift record are never opened for writing on this path (FR-2). `out.replace(name, str(CFG_PATH))` is what keeps the candidate's path out of a message the user sees (FR-5) — the checker quotes the path it was handed. The `or` arm reuses `sc doctor`'s existing key so an empty rejecting output still states the exit status (BC-10) with **no new key and no second wording** |
| I-8 | step 8 (was `:2149`, target unchanged) | `_write_private(CFG_PATH, text)` | The **only** mechanism by which `config.json` reaches disk stays the only one (BC-7). Reached on accepted and on cannot-validate, never after I-7 |
| I-9 | step 9 (was `:2150-2153`, now covering all three filesystem operations) | `except (OSError, ValueError) as e:` → the existing `"Could not write {path}: {err}"` line with `path=CFG_PATH`, then `return False` | **One** handler for creating the candidate (I-1), writing it (I-4) and writing `config.json` (I-8), rendering `CFG_PATH` for every one of them — because a candidate that cannot be created or written *is* `config.json` that cannot be written, and the transient name may not appear (FR-5). "The filesystem refused this document" has exactly one home in this function, which is why the tail carries no second `except OSError` on the write side. I-6's inner `except OSError` binds first, so a checker `OSError` can never render as a write failure. With I-1 inside the guard, this task adds **zero** members to the population of runs that unwind with no run-level outcome line and removes three (missing binary, unexecutable binary, undecodable output): BC-11 is satisfied as the floor it is worded as, not as a net |
| I-10 | step 10 (was `:2154`) | `_record_generated()`, **after** I-2's `finally` has run | The drift baseline is written only after a document the checker did not reject reached `config.json` (FR-6). Its own contract — "called ONLY after a successful `_write_private()` of `config.json`" — is now true by control flow rather than by adjacency |
| I-11 | step 11 (was `:2161`) | `return True` | `generate_config()`'s boolean keeps its meaning exactly: `True` for accepted and for cannot-validate, `False` for rejected (I-7) and for a failed write (I-9) — Q-10, and T-19's folding stays valid |
| I-12 | new `t()` key — cannot-validate | en (the key): ``{path} was installed without being checked — `sing-box check` could not be run: {err}``<br>zh: ``{path} 已写入，但未经检查 —— 无法运行 `sing-box check`：{err}`` | Placeholders `{path}`, `{err}` in both; no `失败：` (BC-12, R-75). States the outcome first and the reason second |
| I-13 | new `t()` key — rejected | en (the key): ``{path} was left unchanged — `sing-box check` rejected the new configuration:\n{checker}``<br>zh: ``{path} 未被改动 —— `sing-box check` 拒绝了新的配置：\n{checker}`` | Placeholders `{path}`, `{checker}` in both; no `失败：`; names `config.json` and says it was left unchanged (FR-5, AC-8). Replaces `"Config check failed:\n{stderr}"`, whose only reader is deleted |
| I-14 | new B.4 assertion — `check-sc-contracts.py` | `def config_reaches_disk_only_when_the_checker_did_not_reject(sc)`, appended to `TESTS` | **One** function with **four** arms. Three are driven by a stub bound to `sc.subprocess` and restored in a `finally` — rejected, accepted, cannot-run — and start no child process, so the suite's docstring stays true. The fourth binds no stub at all: `sc.CFG_PATH` is repointed under a parent directory that does **not exist**, which fails identically for root and non-root, and the arm asserts `generate_config()` returns `False` **without raising** — the committed control for I-2's guarded region and for its `finally`'s `name is None` state. Arm 4 **passes** on the HEAD clone, because HEAD guards its one write and renders the same line: it is a regression control for this design's own boundary, not a HEAD discriminator, and the rejected arm stays the arm that fails on HEAD. Two clauses are mandatory and neither may be spelled as a containment: the checker's argv directory, `os.path.dirname(cmd[3]) == str(sc.CFG_DIR)` — never `str(sc.CFG_PATH) in cmd[3]`, which is vacuous because `str(CFG_PATH)` is a literal prefix of the candidate's name — and arm 4's no-raise clause. Observables in `## Verification plan` V-1 and V-14 |
| I-15 | `_doctor_run(cmd)` (`bin/sc:2538`) | `(returncode, _plain(stdout+stderr decoded utf-8/replace))` — signature and body **unchanged** | Stays a **general** child-process runner with two responsibilities and no more: capture merged output, hand back neutralised text. It gains a caller and a widened docstring; it must never gain classification, truncation, a timeout, or a per-caller parameter — that would be the declined `shared-singbox-check-wrapper` arriving by the back door |
| I-16 | the candidate document (on disk) | `<CFG_DIR>/config.json.check<6 random chars>`, mode `0600`, lifetime ≤ one `sing-box check` | Exists only between I-1's `mkstemp` returning and I-2's `finally`, and does not exist at all when that call raised; never named in any message; never read by anything but the checker; leaves no entry behind under `/etc/sing-box` after any run (NFR-2, AC-7) |

## Constraints

**K-1** — The developer writes exactly the statements the `## Interfaces` rows I-1…I-11 give, in
that order and in the shapes those rows state — I-1 is **two** statements (the sentinel and the
creation), I-2 is **one** `try` statement with one `except` and one `finally` — and adds no
statement that none of those rows names: in particular no `shutil.which()`, no retry, no second
`sing-box check`, no comparison of the candidate against the installed file, no validation `sc`
performs itself, and no third `try` statement in the tail. **The bound is the enumeration, not a
count:** a statement I-1…I-11 requires is authorised however many that makes, and any statement
they do not require is forbidden however few that leaves.

**K-2** — The developer leaves `_write_private()` byte-identical: no validate hook, no mode
parameter, no `keep=`/`check=` argument, and no second temp-then-replace construction anywhere in
`bin/sc`. Q-8's two declines stand; the candidate is a *caller* of the writer, never a variant
of it.

**K-3** — The developer keeps `_record_generated()` (I-10) textually **after** the `try`/`except`/
`finally` statement, so it is unreachable from every `return False` inside it.

**K-4** — The developer renders every one of the three arms' messages against `CFG_PATH` and never
against the candidate's name, and applies `out.replace(name, str(CFG_PATH))` to the checker's
quoted words before they reach `t()`.

**K-5** — The developer neutralises the checker's words only through `_doctor_run()`'s existing
`_plain()` call and adds no scrubbing of its own; `_plain()` already removes a **complete** CSI
sequence (`bin/sc:2501-2535`, verified first-hand at design time), which is the property a stub
checker cannot exercise (AC-11).

**K-6** — The developer decodes the checker's output with `errors="replace"` (inherited from
`_doctor_run`) and adds no `try`/`except UnicodeDecodeError`: FR-4's "output the run cannot decode"
disjunct has an **empty extension** under this decoder, so an undecodable rejecting output is a
*rejection* (AC-6), not a cannot-validate.

**K-7** — The developer removes the `TRANSLATIONS` entry `"Config check failed:\n{stderr}"`
together with its only reader, and adds exactly the two entries of I-12 and I-13 — no third new
key; the empty-output fact reuses `"the checker reported an error, no message (exit {code})"`
(`bin/sc:313`), which already ships in both languages.

**K-8** — The developer keeps `subprocess` usage at this site on the 3.6 floor: `_doctor_run`'s
`stdout=PIPE` + `stderr=STDOUT` + `.decode()`, never `capture_output=` and never `text=`. This
site leaves the three-site 3.7-only population; the remaining two stay filed and untouched.

**K-9** — The developer keeps `bin/sc`'s **net added executable lines ≤ 25**. That is NFR-3's
figure and the only bound; this design's own **+21** is a prediction published for re-derivation,
not a second ceiling, and nothing may be compressed, no comment deleted and no `try` arm dropped to
reach 21 or any other number. Derivation, counted the same way on both sides — physical lines that
are neither blank, nor a comment, nor a `TRANSLATIONS` data line, with a modified line counted on
both sides: **34 added − 13 removed (`:2148-2154`, `:2156-2161` at HEAD) = +21.** A shape that
leaves `mkstemp` outside the guarded region costs +19 (32 − 13) and violates BC-11; this design is
that shape plus exactly two executable lines — `name = None` and the `finally`'s
`if name is not None:` — with the `mkstemp` call and the unlink block re-indented, which the
counting rule scores as modified, not added.
Separately and outside NFR-3: about +3 physical `TRANSLATIONS` data lines (two entries added, one
deleted) and about +6 comment lines; `check-sc-contracts.py` grows by roughly 55 lines, which
NFR-3 does not bound.

**K-10** — The developer adds exactly **one** assertion *function* to `check-sc-contracts.py` and
raises `baseline.json`'s `test_count` and `passing_count` from 17 to 18 in the same commit; the
four arms of I-14 all live inside that one function, and adding an arm to it is not adding an
assertion. The floor is never lowered, and no existing assertion is edited to accommodate the new
behaviour.

**K-11** — The developer drives the new assertion's arms by binding a stub to `sc.subprocess` and
restoring the real module in a `finally`; it starts no child process, writes no executable fixture,
and never points `SB_BIN` at a real program. No `ast` shape check is added for this task's
invariant — an `ast` check would pin the *spelling* of the ordering (statement order, a temp
variable's name), which T-29/R-97 declined for exactly that reason, whereas the run-observed
assertion pins the *behaviour*.

**K-12** — The developer changes no `restart_service()` call site, adds no `except` around
`generate_config()` at any caller, and leaves `cmd_update_rules()`'s recovery arm, its single
folded boolean and its outcome block untouched (BC-9, BC-11, Q-4).

**K-13** — The developer states in `04_DEVELOPMENT.md` the measured mode of the candidate at the
instant the checker sees it, and the `/etc/sing-box` entry set before and after each verified case;
neither may be asserted from the source.

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc:488-538` (`_write_private`) | T-13 owns it; BC-7 requires its five guarantees intact and unweakened, and Q-8 refuses a parameter on it |
| `bin/sc:2054-2145` (`generate_config()` up to and including the hoisted `json.dumps`) | T-24's one `try` region; what it encloses and which `.path` each raise carries must not move. `_warn_drift()` at `:2138` stays where it is — BC-5 makes the run's own message, not the warning's position, the thing that corrects a drift prediction the run did not fulfil |
| `bin/sc:1954-2051` (`_config_digest` / `_record_generated` / `_drift_state` / `_warn_drift`) | T-14; the record stays a digest, the judgement keeps one definition (BC-4, BC-8). Only `_record_generated()`'s **call site** moves; its body does not |
| `bin/sc:2163-2182` (`restart_service`, `reload_or_restart`) | T-10 / T-19: "exactly one apply per run" is structural |
| `bin/sc:2493-2535` (`_plain`) | K-5 leans on its exact behaviour (it removes a **complete** CSI sequence) and adds no scrubbing beside it. The re-order moves the function's line numbers; its bytes do not change, and the developer hashes both sides to show it |
| `bin/sc:2624-2688` (`_doctor_config`) and all of `# doctor`'s probes | T-05 / T-20 / AC-9: no second opinion, no row change. `_doctor_run`'s **body** is frozen too; only its docstring is edited |
| `bin/sc:3400-3441` (`cmd_update_rules`' apply decision and outcome block) | T-19 / T-29 / R-100: the population of runs with no outcome line may not grow |
| `bin/sc` `CONFIG_BASE` and every overlay | NFR-4 / T-15's differential: the emitted bytes do not change |
| `.harness/scripts/verify_all.sh` / `.ps1` | B.4 already reads the floor from `baseline.json`; no step is added or renumbered |
| `docs/features/validate-before-baseline/01_REQUIREMENT_ANALYSIS.md`, `01_RATIONALE.md` | upstream contract; stage 2 may not edit either |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1 | none — no persistent format changes, no flag, no data migration; `config.json` and `.config.sha256` keep their current content and meaning on every host | `git revert` of `bin/sc` alone restores HEAD behaviour, but leaves E-2's assertion failing: revert 1 and 2 together |
| 2 | E-2 | E-1 is in the tree — the new assertion is a control that **fails on HEAD** (that is what makes it discriminating), so committing it first reddens B.4 | revert E-2 and E-3 together |
| 3 | E-3 | E-2 is in the same commit or already committed; raising the floor before the assertion exists reddens B.4 | restore `17`/`17` |
| 4 | E-4, E-5, E-6, E-7 | E-1 final | documentation only; independently revertible |
| 5 | `verify_all` full run | 1–4 complete | — |

**Backwards compatibility:** total. A host upgrading from any earlier build keeps its `config.json`
and its drift record byte-identical; the first run after the upgrade behaves exactly as before
whenever the checker accepts the document, and differs only in the two outcomes this task exists to
correct. No new file, directory, setting or environment variable is introduced, and no `sc`
subcommand changes its surface.

## Out of scope

1. Any backup, copy or rollback of a previous `config.json`; the drift record stays a digest.
2. A `sing-box check` wrapper shared with `sc doctor`, and any parameterisation of the credential
   writer (both remain declined — see `02_RATIONALE.md` for the Q-8 re-opening test and its result).
3. R-81, R-100, R-99's second site and `install.sh`'s `settings.json` reader/writer.
4. Any validation `sc` performs itself; the composed-document array assertion keeps its extent.
5. `sc doctor`'s rows, `sc config`'s provenance line, and the emitted document's bytes.
6. Retrying, degrading or repairing a document the checker rejected.
7. A stale-candidate sweeper for `/etc/sing-box` (BC-1 forbids one; the SIGKILL residue is disclosed
   as RS-6).
8. Renaming `_doctor_run`, moving it out of the `# doctor` block, or reorganising that block.
9. A committed clause on the rejection message's *text*: FR-5 and AC-8 are established by V-6 and
   V-10, and I-14 gains no fifth arm for them.
10. A timeout, a deadline or a watchdog on `_doctor_run()` — RS-9 files it as a pool row.

## Verification plan

Every step runs under `docs/dev-map.md:129-177`'s loader recipe **plus** `check-sc-contracts.py`'s
exec-denial shim, with all nine path constants repointed into a `mkdtemp` root and
`SYSTEMD = OPENRC = False`. Never `/etc/sing-box`, never `/var/lib/sing-box`, never `sc reload`
against the live host, never a service restart (BC-13).

| step | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | The new B.4 assertion (I-14), arms 1-3: a valid node store, a pre-existing `config.json` and `.config.sha256` carrying sentinel bytes; `sc.subprocess` stubbed so `run()` records `(argv, os.lstat(argv[3]).st_mode & 0o777, CFG_PATH.read_bytes(), call count)` and returns `returncode=1` (rejected), `0` (accepted), then raises `OSError` (cannot-run) | Rejected: `generate_config()` is `False`; `CFG_PATH` and `STATE_PATH` bytes unchanged; no new entry under `CFG_DIR`. Accepted and cannot-run: `True`; `CFG_PATH` == the emitted text; `STATE_PATH` == its sha256; no new entry. Every arm: exactly **one** recorded call, `argv[3] != str(CFG_PATH)`, `os.path.dirname(argv[3]) == str(sc.CFG_DIR)` — the fixture repoints `CFG_DIR` and `CFG_PATH` into one root, so the two spellings name one directory, and a build mkstemping into `TMPDIR` goes red where a `str(CFG_PATH) in argv[3]` containment would stay green — mode `0o600`, and `CFG_PATH` still holding the pre-run bytes at call time | AC-2, AC-3, AC-7, AC-13, NFR-1 |
| V-2 | AC-1 differential: the same fixture inputs run against a HEAD clone and the candidate build, checker stub exiting 0 | `config.json` byte-identical between the two, mode `0600` on both, drift record equal to the sha256 of the installed file, return `True`, one restart at the caller | AC-1, NFR-4 |
| V-3 | AC-2/AC-3/AC-5 with a **real** child: `SB_BIN` = a `0755` file whose content is not an executable (AC-5); `SB_BIN` = an absent path (AC-4); a stub script exiting 1 with a message (AC-2/AC-3, with and without a pre-existing pair) | AC-4/AC-5: no exception, document installed, record written, `True`, one stderr line naming the reason. AC-2: both files byte-identical to pre-run. AC-3: neither file exists afterwards | AC-2, AC-3, AC-4, AC-5 |
| V-4 | AC-6: stub exiting 1 writing invalid UTF-8 (e.g. `\xff\xfe`) on stderr | No exception; rejection reported; on-disk state satisfies AC-2; the rendered line contains U+FFFD rather than raising | AC-6 |
| V-5 | AC-7 second clause: `sorted(os.listdir(CFG_DIR))` captured before and after each of V-2…V-4 | Identical lists; no `config.json.check*` and no `config.json*.tmp.*` survives any case | AC-7, NFR-2 |
| V-6 | AC-8: captured stderr of V-3's rejecting case, under `sc.LANG = "en"` and `"zh"` (one case per process — insight 17) | Contains `str(CFG_PATH)`, states it was left unchanged, contains no `\x1b` and no `\r`, and does **not** contain the candidate's name; the zh rendering contains no `失败：` | AC-8, BC-12 |
| V-7 | BC-10: stub exiting 1 with **empty** output | The line states the exit status through the reused key; no colon-then-nothing | BC-10 |
| V-8 | AC-9 freeze: `_doctor_config()` driven over three on-disk states (no config; config + matching record; config + stale record), compared against the HEAD clone | Row-for-row identical; `_drift_state` has one definition (grep) | AC-9, BC-8 |
| V-9 | AC-10 freeze: `cmd_update_rules()` with stubbed fetches and a rejecting checker; `cmd_reload()`; `cmd_add()` | Exactly one run-level outcome line and exit 1; `sc reload` non-zero; `sc add` prints its check-failed line and exits 0 — all identical to the HEAD clone | AC-10, BC-9, BC-11 |
| V-10 | AC-11: V-3's rejecting fixture with `SB_BIN` = a **real** `sing-box`, no root, no live service | `config.json` byte-identical; the rendered message satisfies V-6's clauses against genuinely coloured output. **BLOCKED** with this recipe if the verifying host has no `sing-box` | AC-11 |
| V-11 | `.harness/scripts/verify_all` in full, after E-3 | PASS; B.4 reports `18 defined, 18 run, 18 passed`; no witness line; A.1 clean | AC-13 |
| V-12 | NFR-3: `git diff -U0 bin/sc` classified line by line into executable / comment / blank / `TRANSLATIONS` data, added and removed counted separately | Net added executable **≤ 25**, K-9's predicted +21 re-derived rather than accepted, and the classification published in `04_DEVELOPMENT.md`. A figure between 21 and 25 is a PASS and is reported as measured; nothing is trimmed to reach 21 | NFR-3 |
| V-13 | AC-12: operator obligation — install the new `bin/sc`, provoke a rejecting override, then `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts sing-box` before and after a restart | **BLOCKED** at every stage that lacks root, the installed `sc` and the live service; filed with this recipe, never substituted | AC-12 |
| V-14 | BC-11 at I-1, both as a run and as a HEAD comparison: `sc.CFG_PATH` repointed under a parent directory that does not exist (root-proof — `FileNotFoundError` for any uid, where a permission-based fixture would pass as root), the node store and settings intact in the fixture root, no stub bound; `generate_config()` called with stderr captured. This is arm 4 of I-14, run once at stage 4 outside the suite as well | No exception leaves `generate_config()`; it returns `False`; exactly **one** stderr line, the existing `"Could not write {path}: {err}"` key rendered against `str(CFG_PATH)`, with no candidate name in it; `STATE_PATH` unchanged, so `_record_generated()` was not reached; no entry created anywhere. The HEAD clone prints the same key for the same host state — the run-level outcome is **preserved**, not introduced. Deleting I-2's `if name is not None:` turns this step red with a `TypeError`; moving I-1's `mkstemp` above the `try:` line turns it red with the `OSError` | BC-11, FR-5 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | Three decision records to file: `candidate-installed-by-os-replace-instead-of-the-one-writer` (declined), the ruling that reusing `_doctor_run()` is **not** the declined `shared-singbox-check-wrapper` with the distinction that carried it, and `second-guarded-region-around-the-candidates-creation` (declined under rule 85 — one guarded region and one write-failure handler, at the price of a `finally` with a precondition; the reasoning is `02_RATIONALE.md` §3, S-5) | `.harness/rejected-decisions.md`, written by the PM at delivery (`.harness/**` is outside the developer's diff by precedent) |
| RS-2 | AC-12 is an operator obligation with the `systemctl show` recipe of V-13; it is never substituted for a run | `06_TEST_REPORT.md`, then `07_DELIVERY.md` |
| RS-3 | AC-11 is **BLOCKED** if the verifying host carries no `sing-box`; it is the only row that establishes AC-8's ESC clause, because a stub checker cannot colour its output (T-05 DEF-1) | `06_TEST_REPORT.md` |
| RS-4 | K-6's reading — FR-4's "cannot decode" disjunct is empty under `errors="replace"`, so AC-6 governs and the third arm costs zero lines — is the one place this design resolves an upstream tension rather than implementing it | `03_GATE_REVIEW.md`, to be tested rather than accepted |
| RS-5 | R-81, R-99's second site and its `install.sh` half, and R-100 stay filed and are untouched by this task; this task's site leaves the three-site `capture_output=` population, so that pool row now names two sites (`bin/sc:2258`, `:3523`). `.harness/rejected-decisions.md`'s "one of the **three** pre-existing sites" needs the same correction — that file is outside the developer's diff by precedent, so it travels with RS-1 | `docs/tasks.md` and `.harness/rejected-decisions.md`, by the PM at delivery |
| RS-6 | Known cost, accepted: a run killed between I-1 and I-2's `finally` (SIGKILL, power loss) leaves one `0600` `config.json.check*` entry under `/etc/sing-box` that nothing removes — BC-1 forbids a sweeper, and `_write_private()` already has this residue class at HEAD for its own `.tmp.` name, so the kind is not new | `07_DELIVERY.md` |
| RS-7 | A concurrent `sc doctor` can list the candidate in `_doctor_permissions()`' per-entry rows for the duration of one `sing-box check`. Same race and same kind as `_write_private()`'s existing `.tmp.` entry at HEAD; not enlarged, not fixed here | `07_DELIVERY.md` |
| RS-8 | Q-5's "**it moves one and removes three**" is false of this design and stage 2 may not edit `01`. The true statement is **three out, zero in**: the three traceback paths of Q-4 (missing binary, unexecutable binary, undecodable output) leave R-100's population, and with I-1 inside I-2's guard nothing enters it — R-12/R-100 strictly shrink. Any shape that leaves `mkstemp` outside the guarded region would be three out, **one** in, which is what BC-11's floor wording forbids | the PM, who decides whether `01_REQUIREMENT_ANALYSIS.md`'s Q-4/Q-5 needs a round; `PM_LOG.md` either way |
| RS-9 | New pool row, not a residual of this design: `_doctor_run()` has no timeout and now has a caller on the **write** path, so a hung `sing-box check` blocks `generate_config()` with a `0600` candidate on disk for the whole hang. I-15 forbids the timeout here, and `sc doctor` already waited unboundedly on the same runner — the exposure **moved rather than grew**. Out of scope for T-30 | `docs/tasks.md`, by the PM at delivery |

## Verdict

READY
