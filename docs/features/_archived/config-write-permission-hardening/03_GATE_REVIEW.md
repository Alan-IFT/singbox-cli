# 03 — Gate Review · T-13 `config-write-permission-hardening`

> Authored by the stage-3 gate-reviewer agent (read-only tool set) and persisted verbatim by the
> PM Orchestrator. The PM did not alter its content or its verdict.

Mode: **full**. Deferred-human mode (`defer, do not ask`): every referral below is **ruled**, not returned. This stage is read-only: it edited no upstream document and ran no command. Where a claim can only be settled by execution it is assigned as a numbered obligation to stage 4 or stage 6 with the exact check. Verdict at §9.

Upstream verdicts confirmed: `01_REQUIREMENT_ANALYSIS.md` **READY**, `02_SOLUTION_DESIGN.md` **READY**.

---

## 1. Independent verification of the load-bearing claims

Nothing below is taken from an upstream document. Each row was re-derived from the file named.

| # | Claim under test | Verdict | Evidence read this session |
|---|---|---|---|
| V-a | `mkstemp` passes `0o600` as `open(2)`'s mode argument and issues no `chmod`, so umask still masks it | **CONFIRMED** | `/usr/lib/python3.12/tempfile.py:395` `fd = _os.open(file, flags, 0o600)`; `_mkstemp_inner` is `:382-409` and contains no `chmod`/`fchmod`. Stage 2's citation is exact. |
| V-b | `mkstemp`'s flags carry `O_CREAT\|O_EXCL` and `O_NOFOLLOW` | **CONFIRMED** | `tempfile.py:191-197`: `_text_openflags = O_RDWR\|O_CREAT\|O_EXCL`, `+= O_NOFOLLOW` under `hasattr`; `_bin_openflags = _text_openflags`. |
| V-c | The documented contract forbids anything wider | **CONFIRMED** | `tempfile.py:481` "The file is readable and writable only by the creating user ID." |
| V-d | `PermissionError` is re-raised on POSIX | **CONFIRMED** | `tempfile.py:398-405`; the `continue` arm is `_os.name == 'nt'` only. |
| V-e | One write path per credential document at HEAD, each `write_text` + trailing `chmod` | **CONFIRMED** | `bin/sc:311-312`, `:323-324`, `:1016-1017`. |
| V-f | `save_nodes()` is called from **inside** `generate_config()` | **CONFIRMED** | `bin/sc:925-928`. Load-bearing for F-4. |
| V-g | `_init_files()` runs **before** `LANG` is assigned | **CONFIRMED** | `bin/sc:1973-1974` inside `main()`, which declares `global LANG, CLASH_PORT` at `:1940`. Load-bearing for F-5. |
| V-h | `install_report()`'s closing `}` is `install.sh:288`; call site `:532-533`; `/etc/sing-box` literals at `:411, :421, :455` | **CONFIRMED** | as cited. |
| V-i | `t()` has 41 keys, `step6_nolog` last in both blocks, `local fmt` with no default | **CONFIRMED** | `install.sh:139-238`; zh `:145-185`, en `:189-229`. 41 + 7 = 48, matching the design's expected B.2 output. |
| V-j | `check-i18n-parity.sh` §3b self-check exists and `die2`s on byte-identical renders | **CONFIRMED** | `.harness/scripts/check-i18n-parity.sh:98-107`. Wired as B.2 at `verify_all.sh:70-73`. |
| V-k | `verify_all.sh:77` is a hard-coded `step "B.3" "Lint" "SKIP"` | **CONFIRMED** | as cited. `baseline.json:4` still `"test_count": 0`. |
| V-l | The service runs as root, so a `0600` config stays readable | **CONFIRMED** | `systemd/sing-box.service` has no `User=`; the OpenRC unit written at `install.sh:448-467` uses `supervise-daemon` with no user. |
| V-m | `README.md:190/:191/:217` and the zh mirror carry the same content at the same line numbers | **CONFIRMED** | both files read; D-10's anchors are exact. |
| V-n | Nothing enumerates `/etc/sing-box/`, so a transient temp there is invisible to the tool | **CONFIRMED** | the only directory scan in `bin/sc` is `RULES_DIR.iterdir()` at `:830` (`_clear_stale_temps`). No interaction with a temp in `CFG_DIR`. |

### 1.1 Dispatch claim 1 — the umask-independence proof and the Python 3.6 floor

**Ruling: the mechanism does not depend on a CPython version detail. PASS.**

Stage 2's citation is to 3.12, and I could not read a 3.6 `tempfile.py` on this host (none is installed). That gap does **not** matter, and the reason is structural rather than empirical: the design's correctness needs only two properties of `mkstemp`, and both are **documented contract**, not implementation —

1. the created object's mode is **≤ 0600** (`tempfile.py:481`, wording unchanged since Python 2), and
2. the name is fresh and exclusively created (`O_CREAT|O_EXCL`, documented in `mkstemp`'s own docs).

Exactness comes from `os.fchmod`, a syscall wrapper, not a library policy. So even if 3.6's `_mkstemp_inner` differed in shape, the guarantee holds: `fchmod` re-establishes `0600` unconditionally on a still-empty descriptor. This is precisely why §3.1's "each fact is defeated by a *different* element" is the right construction and not decoration — it is what makes the mechanism robust to the version variance the dispatch asked about.

The one claim that *is* version-shaped — V-d — is **not load-bearing**: even a hypothetical retrying implementation exhausts `TMP_MAX` and raises `FileExistsError`, still an `OSError`, still caught by the §4.3 handler. AC-6 survives either way.

**API floor audit (AC-26).** Every name the design introduces exists in 3.6 with the relied-on semantics: `tempfile.mkstemp(dir=, prefix=)` (2.3+), `os.fchmod` (POSIX), `os.fdopen`, `os.fsync`, `os.replace` (**3.3+**), `os.unlink`, `os.close`, `os.getpid`. No `stat`-module constant appears in product code (`S_IMODE` is used only in the stage-6 harness, §14 V-3). No third-party import. **PASS.** Pre-existing `capture_output=` violations (`bin/sc:1019` and two others) are out of scope and must not be touched.

### 1.2 Dispatch claim 2 — the window analysis

**Ruling: no hole found. PASS.** I tried to break the `t0…t3` timeline four ways:

- *The `O_CREAT|O_EXCL` instant.* The object is nameable at `t0` at `0600 & ~umask ⊆ 0600` and holds zero bytes. A mask can only clear bits. No content, no exposure.
- *The temp file's own directory entry.* `/etc/sing-box/` is traversable and world-readable (stage 1 E-8), so the temp **name** is visible to any local user. The name is not a credential and the inode is `0600` root-owned. Not an exposure.
- *The target path.* `rename(2)` is one step; the inode it publishes was `0600` before it held a byte. There is no interval.
- *Same-directory placement.* `dir=str(path.parent)` is deliberate and doubly load-bearing — cross-filesystem `rename` raises `EXDEV` (R-1) and a default `TMPDIR` would move credential bytes out of the configuration directory, breaking AC-12.

**Residual, ruled out of scope and *not* a regression:** if `/etc/sing-box/` were ever world-writable (`install.sh:411` creates it at the ambient umask — stage 1 E-10), a local attacker could rename their own file over the temp name between `t2` and `t3` and have it published as `config.json`. This is strictly **better** than HEAD, where the same attacker plants a symlink at `config.json` and `write_text` writes the credentials *through* it. The directory's own mode is NG-5. Re-home as an open row (C-11); do not build it here.

### 1.3 Dispatch claim 3 — deferring "`os.replace` preserves the source's mode" to stage 6

**Ruling: deferral is acceptable, and V-2 is upgraded from "should" to blocking.** `rename(2)` is *defined* as moving a directory entry; the inode, which carries `st_mode`, is untouched — POSIX's "the new pathname refers to the same file" leaves no room for a conforming implementation to differ. The design does not rest on it too heavily: if the claim were false the failure is loud and immediate (a `0644` `config.json` at the end of every run, caught by AC-1/AC-3 on the first test). Conditions in C-6.

### 1.4 Dispatch claim 4 — is `docs/tasks.md` R-7 stale?

**Ruling: HALF TRUE, and the design overstates it. This is F-1.** R-7 (`docs/tasks.md:86-92`) records **two** blind spots. The first — the `LANG_CHOICE` false green — is genuinely closed by `check-i18n-parity.sh:98-107`. The second is not: *"It also cannot see a key missing from **both** tables, though that aborts the installer under `set -u`."* The checker enumerates keys **from the tables** (`:70`), so a `t <key>` *call site* naming a key that exists in neither table is invisible to it. T-13 adds seven such call sites. The row must not be struck; it must be narrowed.

**AC-21's second half is nevertheless satisfied without new tooling — but by V-4, not by §3b as the design states.** §3b compares two *whole* transcripts, so it proves the dispatch works; it does not prove any *new* key differs. §14 V-4's "run the whole matrix in both `LANG_CHOICE` values and diff the two transcripts" *does*, because the sweep's transcript contains only `perm_*` keys. Binding as C-7.

### 1.5 Dispatch claim 5 — Python 3.6 floor

Covered in §1.1. **PASS**, with the style note that `import tempfile` belongs between `import sys` (`bin/sc:11`) and `import urllib.error` (`:12`) to keep the block alphabetical.

---

## 2. The three referrals, ruled

### S-1 — documentation scope: **UPHELD, and widened by one file**

The dispatch's "SCOPE BOUNDARY: `bin/sc` and `install.sh` only" is a summary of the *behaviour-changing* surfaces. AC-25 is a criterion of an **APPROVED** requirement document, and a criterion outranks a summary. D-9 is upheld.

I overturn the design on one exclusion. `docs/architecture.md:115-122` is a 安全考量 table whose only credential row is `nodes.json`（含密码/UUID）| mode 600。After T-13, `config.json` is equally credential-bearing and equally `0600`; a reader consulting that table would conclude the opposite. The design excludes the file because "its `:119` line stays true" — true but now **misleading**, and this is exactly the T-08 pattern the PM cited: a narrow diff left an owed `docs/dev-map.md` row that became an open board row. Since D-9 already widened for the same judgment (README's security bullet), the exclusion is arbitrary. **One table row, Chinese only** (no English mirror of that file exists — `docs/` holds `architecture.md`, `faq.md`, `workflow.md`, `dev-map.md`, `tasks.md`). Final pinned diff at §8.

### S-2 — DECISION-8 / D-8, the fourth deferral: **AC-23's literal reading OVERTURNED; the deferral UPHELD on a new ground**

Two separable questions; the design conflates them.

**(a) What AC-23 means.** It sits under **"Non-regression"** (`01_…md` §5). Read literally as "zero delta", it would forbid turning a permanently-`SKIP` step into a real `PASS` — which is what `.harness/rules/50-singbox-cli.md:38-40` explicitly *mandates* ("a permanently SKIPping check proves nothing"). A criterion cannot be read so as to forbid what the project's own ruleset requires. **AC-23 means: no step may regress (PASS→WARN/FAIL/SKIP), and no count may move for a reason the task cannot name.** D-8's stated overturn condition is therefore **met**.

**(b) Whether the harness ships here anyway. It does not — and on a ground none of the four prior deferrals used.** A *committed* test step is not a one-off harness: it means `bin/sc` gets **imported on the owner's live machine on every future `verify_all` run, forever**. The only way to import `bin/sc` is to defuse an import-time `os.execvp("sudo", ["sudo", "/usr/local/bin/sc", …])` (`bin/sc:83-84`) that has already, once, re-executed the *installed older* binary under sudo and restarted the owner's live VPN (`.harness/insight-index.md:11`). Making that permanent is a design with its own safety criteria — fail-closed under root, never touching `/etc`, never touching the live service — and **no APPROVED requirement in T-13 states them**. This is a risk-coupling argument, not the diff-boundary argument that `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` has rightly grown tired of. Shipping unstated safety criteria inside a security fix is the worse trade.

The deferral is **not free**. C-1…C-3 make this the last cheap one: the recipe is committed, the row is filed with scope, and the regression guard R-2 needs is written and pasted, not described.

### The three AC scope readings

| Reading | Ruling |
|---|---|
| **AC-4 / AC-6** "no file wider than `0600`" measured only where the pre-existing file was `0600`-or-absent | **UPHELD, with a non-vacuity condition.** In-scope behaviour 3 is scoped to "every filesystem object that holds **any byte of the new content**"; a pre-planted `0644` `config.json` holds none of it at the suspension point, and AC-3 pins its end state. But the reading must not hollow out the criterion: **AC-4 must run in both fixture shapes** — empty directory, and pre-existing `0644` target — and in the second shape the assertion is "every file *other than the pre-existing target* is ≤`0600`", paired with AC-5 (target byte-identical) and AC-3 (target `0600` after). HEAD still fails that, because at HEAD the target itself holds the new bytes at `0644`. C-8. |
| **AC-8** "exactly one line" measured on `generate_config()`'s own output | **UPHELD.** AC-8's own text already separates the clauses: *one line* is about the new failure message; *no `Traceback`* and *`sc reload` exits non-zero* are about the whole command. `cmd_reload`'s `sys.exit(t("Reload failed"))` (`bin/sc:1794`) is untouched existing behaviour and is what carries the status. Condition: the fixture must carry four **usable** `.srs` stubs so `_warn_degraded` (`bin/sc:784-800`) is silent, or the count measures the wrong thing. C-9. |
| (implicit) AC-8 asserted against the wrong failure path | **Flagged.** After D-2, an `OSError` inside `save_nodes` reached from `generate_config` (`bin/sc:928`) produces a `sys.exit` message, not the `⚠️ ` + `return False` path. Stage 6 must assert AC-8 against the **config-write** failure. C-9. |

---

## 3. The eight-dimension audit

| # | Dimension | Verdict | Reason |
|---|---|---|---|
| 1 | Requirement completeness | **PASS** | Every in-scope behaviour is expressed as an end-state at an instant, and BC-1…BC-16 name the umask, prior-mode, symlink, directory, ENOSPC, SIGKILL and concurrency cases individually; the one untestable-sounding phrase ("no instant") is discharged structurally by §3.3's timeline, not by timing. |
| 2 | Design completeness | **PASS** | All 27 ACs map to a named element, and I re-derived the mapping for the ten carrying the security guarantee (AC-1…AC-11) rather than accepting §13's assertions; the two needing a stated reading are ruled above. |
| 3 | Reuse correctness | **PASS** | Every reused symbol exists where §7 says: `_plain` `bin/sc:1236`, `sys.exit(t(…))` precedent `:1075`, `⚠️ ` + `stderr.write` `:800`/`:1022`, `tmp.replace(target)` `:1632`, `SRS_MIN_BYTES` `:61`, `sed -n '/^t() {/,/^}/p'` `check-i18n-parity.sh:48`, `if ! SB_VER=$(…)` `install.sh:384`; and the declined reuse (D-3) is correct — `_clear_stale_temps` (`:821-856`) would put a sweeper in the configuration directory, which BC-10/NG-11 forbid. |
| 4 | Risk coverage | **WARN** | R-1…R-13 are the real risks and R-2 names the exact silent regression, but three are missing or under-analysed: the `set -u` abort the sweep can still cause (F-1), `sys.exit` bypassing T-10's run-level-outcome invariant (F-4), and the English-only render of the new key on the `_init_files` path (F-5). |
| 5 | Migration safety | **PASS** | No schema, no persisted-field change, no flag; content bytes identical for identical inputs; rollback is `git revert` with no on-disk state to undo, and V-l proves a narrowed file stays readable by the (root) service. The only irreversible on-disk effect is *narrowing*, which DECISION-3 confines to one direction. |
| 6 | Boundary handling | **PASS** | Null/empty (BC-6), max (BC-12), concurrency (BC-11 → `mkstemp` uniqueness + atomic `rename`), error paths (BC-8/BC-9 → `OSError` before the target is ever opened), SIGKILL (BC-10 → `0600` pid-tagged litter) are each carried by a named element rather than a promise. |
| 7 | Test feasibility | **PASS (with C-4)** | Every AC is checkable unprivileged against a temp-dir fixture; the two that looked unverifiable ("at every instant", "exactly one line") are made verifiable by the V-3 spy and the AC-8 scoping. The one measurement impossible on this host — a real 3.6 interpreter — is not load-bearing (§1.1) and must be reported as unverified rather than asserted. |
| 8 | Out-of-scope clarity | **PASS** | NG-1…NG-11 plus §11 name the neighbouring rows (T-14/15/16/19/20), and the three tempting over-builds (settings.json through the helper, a shared atomic helper, a `sc doctor` permission row) are each pre-declined with a checkable reason. |

---

## 4. Findings

**F-1 — WARN — the sweep can still abort the installer, and B.2 cannot see it.** *Owner: design (§5.3), not blocking.* `sweep_credential_modes || true` does make `set -e` and `pipefail` harmless for **every** command inside the function (bash suspends `set -e` for the whole duration of a function invoked in a `||` list). It does **not** cover a `set -u` expansion error: `t()` declares `local fmt` with no default (`install.sh:142`), so a call naming a key absent from *both* tables makes `printf "$fmt\n"` (`:234`) dereference an unset variable, and bash terminates the shell outright — `||` cannot catch an expansion error. That kills the run **before `install_report()`**, which is precisely the R-3 "the installer states no outcome" class this file has a history of. B.2 is blind to it (§1.4). The design's "true by construction rather than by an audit of every line" is accurate for `set -e` and overstated for `set -u`. Mitigation exists and is made binding as C-5 — no design change required.

**F-2 — WARN — one word of the symlink justification is wrong; the guard is right.** *Owner: design (§5.2 comment), not blocking.* The comment says "chmod **and stat** both FOLLOW links". GNU `stat` does **not** dereference by default (`-L` is what dereferences), so on a symlinked `config.json` it would report the link's own `777`. `chmod` *does* follow (Linux has no `lchmod`). The consequence is that the guard is *more* necessary than the comment implies: without `[ -L ]` the sweep would read `777`, issue `chmod 600` against the **link's destination** — an arbitrary path — and then print `perm_problem`, having silently modified a system file. The security claim is **upheld**; the supporting sentence must be corrected so a later reader does not judge the guard redundant. C-10.

**F-3 — WARN — `verify_all`'s current state is not the dispatch's stated baseline, and AC-23 must be measured accordingly.** *Owner: gate (new).* `verify_all.sh:229-237` (F.6) WARNs on any active task doc over 500 lines. `02_SOLUTION_DESIGN.md` is **789 lines**, so F.6 is **already WARN in the working tree before a line of code is written**, while a pristine `HEAD` clone (which contains none of this task's docs) shows F.6 PASS. F.4 (`:213-219`, insight-index ≤30 lines) reads 31 lines in the working tree and may also WARN. The dispatch's "baseline PASS 17 / WARN 0 / FAIL 0 / SKIP 1" is T-05's **post-archive** measurement, not a prediction of a run today — T-05 hit and cleared exactly this (`docs/tasks.md:17`). AC-23 is satisfiable, but only if the delta is computed as T-05 computed it: after archiving, against a clone. C-4.

**F-4 — WARN — R-8 is real but under-analysed: `sys.exit` inside `generate_config`'s call graph bypasses T-10's run-level-outcome invariant.** *Owner: design (§9 R-8), not blocking.* `save_nodes()` is called from `generate_config()` at `bin/sc:928`, which `cmd_update_rules` calls at `:1666`. That function's contract, in its own comment at `:1675-1676`, is "Exactly one truthful run-level outcome, always, before the exit". After D-2, an `OSError` writing `nodes.json` there exits the process before `:1677-1684` prints. At HEAD the same `OSError` raises a traceback and also skips those lines, so this is **not a regression** — but a clean `sys.exit("Could not write …")` *looks* like a designed outcome while violating an invariant a traceback obviously violates. Trigger requires a stale active tag *and* a write failure. Ship as designed; review it explicitly (C-12) and re-home the general statement.

**F-5 — WARN — the new key renders English-only on one of its five call sites.** *Owner: design (§4.3 D-2), not blocking.* `main()` calls `_init_files()` at `bin/sc:1973` and assigns `LANG` at `:1974`. After D-2 routes `_init_files`' nodes branch through `save_nodes()`, a failure there renders `t("Could not write {path}: {err}")` while `LANG` is still the module default `"en"` (`:221`). The zh translation exists and is reached from the other four call sites, so **AC-22 is satisfiable and rule 50's bilingual requirement is not breached** — the string ships in both languages. It is strictly better than HEAD (an English traceback). Do **not** "fix" it by reordering `_load_lang()` before `_init_files()`: that is an unrequested change to the start-up path T-05 deliberately shaped (`bin/sc:1961-1969`). State it in `06_TEST_REPORT.md`; re-home as an open row. C-13.

**F-6 — NOTE — `docs/dev-map.md`'s row budget is under-counted.** §2 budgets `+3` lines / 2 rows. Three more are owed by the file's own header: `# Paths` (`dev-map.md:30`) enumerates the constants and gains `CRED_MODE`; `# Config generation` (`:37`) says `generate_config()` "writes 0600" and must now name the mechanism; and D-8 promises the V-1 neutralisation recipe lands there. The file is already in the permitted diff, so this costs no scope. C-2.

**F-7 — NOTE — `CONTEXT.md`'s new glossary entry asserts code that does not exist yet.** `CONTEXT.md:78-86` states "Every credential document is installed by `_write_private()`" in the present tense; it becomes true at stage 4, and if the helper is renamed the glossary must move in the same diff. Both stage-2 memory edits are **within contract**: `rejected-decisions.md:1-10` mandates append-on-decline and one-record-per-concept with re-occurrences appended to the existing record — `:74-88` is exactly that, and `:235-266` are two genuinely new concepts. Confirmed, not a scope breach.

**F-8 — NOTE — `_write_private`'s inner `finally: fh.close()` can mask the original exception.** If `fh.write` raises, `close()` re-flushes and may raise a second `OSError` that replaces the first. Both are `OSError`, both caught by the same handler, and the message would name a plausible cause — cosmetic, recorded so stage 5 does not "discover" it as a defect.

---

## 5. Questions stage 4 will ask, pre-answered

**Q1. "`mkstemp` already creates at `0600` — is the `fchmod` redundant?"** No, and this is the single most likely regression (R-2). `0o600` is `open(2)`'s mode argument (`tempfile.py:395`), so umask masks it: under umask `0o277` you get `0400`, not `0600`, and BC-2/AC-2 demand *exactly* `0600`. Under the common umask `0o022` you cannot see the difference — which is why C-5's umask-`0o277` assertion is mandatory and must stay in the pasted harness.

**Q2. "Can I use `os.write(fd, text.encode('utf-8'))` and skip the wrapper?"** No. `load_nodes()` reads back with `Path.read_text()` (`bin/sc:319`), which is locale-encoded; `os.fdopen(fd, "w")` is byte-identical to `Path.write_text` (both are `io.open` with `encoding=None`). Writing UTF-8 while reading locale converts a latent write-time failure into a read-time one on a non-ASCII node tag. Encoding is out of scope (§15 O-2).

**Q3. "Should `save_settings()` go through the helper for consistency?"** No — D-6. It would change `settings.json`'s observable mode (today `0666 & ~umask`), which NG-4 forbids, and dilute the "credential document" judgment this task exists to state once.

**Q4. "Where does `import tempfile` go?"** Between `import sys` (`bin/sc:11`) and `import urllib.error` (`:12`) — the block is alphabetical.

**Q5. "Does replacing the inode break anything holding `config.json` open?"** No. `sing-box run -c` reads the file at start-up and the service is restarted separately; nothing in `bin/sc` holds a descriptor across a regeneration, and nothing enumerates `CFG_DIR` (V-n). The behavioural change — `config.json`'s inode is no longer stable across regenerations — is real and harmless here; state it in the test report rather than discovering it later.

**Q6. "`verify_all` shows a WARN I did not cause — did I break something?"** Probably not: see F-3. Measure the pre-change baseline **before** your first edit and diff against that.

**Q7. "Can I add a `docs/tasks.md` row for what I found?"** No. That file is in the permitted diff for the **PM only** (§8 item 10).

---

## 6. Failure modes stage 4 is most likely to produce — where stages 5 and 6 must look

| # | Predicted failure | How it is caught |
|---|---|---|
| P-1 | `os.fchmod` dropped as "redundant" | Only visible at a non-default umask: C-5's umask-`0o277` assertion. A suite run at `0o022` passes while BC-2 is broken. |
| P-2 | `os.write(fd, …encode())` substituted for `os.fdopen` | Stage 5 greps the helper for `.encode(`; stage 6 round-trips a non-ASCII node tag. |
| P-3 | `dir=` dropped, or `NamedTemporaryFile` used | `EXDEV` on a host with a separate `/tmp`; AC-12's "no file outside the fixture root". |
| P-4 | `fd = -1` ownership transfer removed | Double-close / `EBADF`; stage 5 must see the line verbatim (R-4). |
| P-5 | A `t perm_*` key typo'd at the call site, or added to one table only | One-table: B.2. **Both-table / typo: nothing committed catches it** — C-5's `bash -u` sweep in both languages is the only guard (F-1). |
| P-6 | `local mode=$(stat …)` written on one line | Status becomes `local`'s; with `set -e` suspended the sweep silently sees an empty mode. Stage 5 greps for `local .*=\$(`. |
| P-7 | A column-0 line (heredoc terminator) inside `sweep_credential_modes()` | Breaks the `sed` extraction AC-18 rests on; C-5 fails loudly if so. |
| P-8 | `install.sh`'s other `/etc/sing-box` literals consolidated into `CRED_DIR` | D-7 forbids it; `:411`'s `mkdir -p` is a different judgment and widens the diff. |
| P-9 | A permission row added to `sc doctor` because it "obviously belongs" | NG-2 / AC-24 — `sc doctor` output must stay byte-identical in both languages. |
| P-10 | A harness imports `bin/sc` without the §14 V-1 shim | Re-execs the **installed older** `/usr/local/bin/sc` under sudo and restarts the owner's live VPN (`.harness/insight-index.md:11`). C-14's witnesses are the backstop. |
| P-11 | The V-3 spy patches the real `os` module rather than `sc.os`, or leaves it patched | Corrupts every later assertion in the process; require restoration in a `finally`. |
| P-12 | `capture_output=` or `bin/sc:309`'s `/var/lib/sing-box` "fixed while I was in there" | AC-26 and §15 O-1 forbid both. |

---

## 7. Binding conditions

- **C-1 (PM).** File the committed `bin/sc` test harness as its own numbered row **now**, scoped to: a `verify_all.sh` step, the `verify_all.ps1` mirror (R-6), `baseline.json` (R-4), and fail-closed safety criteria (refuse under root; never touch `/etc`; never touch the live service). Also **narrow** R-7 rather than striking it (§1.4). This is the price of the fourth deferral.
- **C-2 (stage 4).** `docs/dev-map.md` gets the §14 V-1 neutralisation recipe **and** the three rows named in F-6, not just the two budgeted.
- **C-3 (stage 6).** The harness is pasted verbatim into `06_TEST_REPORT.md` with the umask-`0o277` guard as a **named, separately runnable** assertion, so the next task inherits a test rather than a paragraph.
- **C-4 (stage 4 first action; stage 6 final).** Run `bash .harness/scripts/verify_all.sh` **before the first edit** and record the true counts; confirm the working tree carries no unrelated uncommitted changes. AC-23's delta is computed against that measurement and a pristine **clone** of `HEAD` (never a worktree — `.harness/insight-index.md:24`), taken **after** archiving, with F.6/F.4 movement attributed explicitly (F-3).
- **C-5 (stage 6, blocking).** The §14 V-4 harness must source the **extracted, unmodified** `t()` and `sweep_credential_modes()` under `bash -u` and reach **all seven** `perm_*` keys in **both** `LANG_CHOICE` values. Reaching all seven closes F-1's abort path; diffing the two transcripts discharges AC-21's second half. If a key is unreachable in the matrix, say so — do not fill the gap by calling `t` directly.
- **C-6 (stage 6, blocking).** V-2(a) *and* its falsification control (temp at `0644` ⇒ target `0644`) must both run, and the report must name the **filesystem type** the fixture sat on (`stat -f -c %T`), so a tmpfs measurement is not reported as an ext4 one.
- **C-7 (stage 6).** AC-21's second half is discharged by V-4's two-transcript diff, **not** by `check-i18n-parity.sh` §3b. Say which discharged it.
- **C-8 (stage 6).** AC-4 runs in **both** fixture shapes; in the pre-existing-`0644` shape the assertion excludes the pre-existing target and is paired with AC-5 and AC-3. Re-run against a pristine `HEAD` copy and require failure (non-vacuity).
- **C-9 (stage 6).** AC-8 is measured on the **config-write** failure path with four usable `.srs` stubs in the fixture; `cmd_reload`'s `Reload failed` line and the non-zero status are asserted separately.
- **C-10 (stage 4).** Correct the `[ -L ]` comment: `chmod` follows symlinks, GNU `stat` does not. The guard stays exactly where it is, first. Stage 6's symlink fixture must assert the **link destination's mode is unchanged** — the falsification control for the security claim.
- **C-11 (PM).** Re-home as open rows: the world-writable-`/etc/sing-box` residual (§1.2), F-4's invariant statement, and F-5's English-only start-up render.
- **C-12 (stage 5).** Explicitly review the D-2 control-flow change (`save_nodes` now `sys.exit`s) at `bin/sc:928`'s call site, and confirm `_init_files()`'s output is byte-identical (`json.dumps({"active": None, "nodes": []}, indent=2)` vs the same with `ensure_ascii=False` — identical for a pure-ASCII literal).
- **C-13 (stage 6).** State F-5 in the report rather than fixing it. `_load_lang()` must **not** be reordered before `_init_files()`.
- **C-14 (stages 4 and 6, non-negotiable).** §15's six safety constraints are inherited intact and bind every throwaway script: never write/chmod/move under `/etc`; never execute `install.sh`; never test the installed `/usr/local/bin/sc`; neutralise the auto-elevate re-exec via the §14 V-1 `sys.modules` shim (never by editing `bin/sc`); never restart or reload the live service; witness service state with `systemctl show -p MainPID -p ActiveEnterTimestamp`, **never** `is-active`. Never drive `_init_files()` (`bin/sc:309`'s `/var/lib/sing-box` is not repointable). Do **not** commit or push.

---

## 8. The permitted diff — final, pinned

Any file not listed is out of scope. Eleven entries; item 10 is the PM's, not the developer's.

| # | Path | Why |
|---|---|---|
| 1 | `bin/sc` | §4 |
| 2 | `install.sh` | §5 |
| 3 | `README.md` | AC-25 |
| 4 | `README.zh-CN.md` | AC-25, line-for-line mirror |
| 5 | `CHANGELOG.md` | AC-25 + convention (`### 修复` under `[Unreleased]`, zh) |
| 6 | `docs/dev-map.md` | its own header + C-2 |
| 7 | `CONTEXT.md` | glossary duty — already written by stage 2 |
| 8 | `.harness/rejected-decisions.md` | rule 25 duty — already written by stage 2 |
| 9 | `docs/features/config-write-permission-hardening/*` | stage documents |
| 10 | `docs/tasks.md` | **PM only** — board, open rows C-1/C-11 |
| 11 | `docs/architecture.md` | **added by this gate**: one row in the 安全考量 table (§2 S-1). Nothing else in that file. |

Explicitly out: `uninstall.sh`, `systemd/*`, `.harness/scripts/*`, `.harness/rules/*`, `.claude/*`, `AI-GUIDE.md`, `CLAUDE.md`, `docs/faq.md`, `.harness/scripts/baseline.json`.

---

## 9. Verdict

The mechanism is sound and I re-derived it from source rather than accepting it: the umask-independence proof holds (§1.1), the window analysis has no hole (§1.2), the mode-preservation deferral is proportionate (§1.3), and every symbol the design says it reuses exists where it says. The rule-85 call is correct in both directions — the seam is real (two direct adapters plus one indirect, ~18 lines of ordering-critical code per call site if deleted) and the counter-direction holds (D-3 and D-6 decline the two available over-builds with reasons that check out). The three referrals are ruled: S-1 upheld and widened by one file, S-2's literal AC-23 reading overturned but the deferral upheld on a new, non-repetitive ground, and the three AC scope readings upheld with non-vacuity conditions.

Five WARNs, no FAIL. None requires a design change: F-1, F-2 and F-4 are corrections and verification obligations, F-3 is a measurement correction the dispatch itself carried, F-5 is a pre-existing start-up ordering this task improves rather than worsens. One dispatch claim did not survive: **`docs/tasks.md` R-7 is only half stale** — its second blind spot is live and bears directly on this task's seven new keys, which is why C-5 exists.

No safety red line was reached; §15's constraints are inherited intact and are strong enough to bind stages 4 and 6, with C-14 restating them as a checklist.

Development may proceed subject to C-1…C-14.

**VERDICT: APPROVED FOR DEVELOPMENT** (with conditions C-1…C-14 binding).
