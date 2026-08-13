# Task Board — singbox-cli

> Maintained by **PM Orchestrator**. Each task appears here when started and is updated through its lifecycle.
>
> New tasks should check this board for related historical work before planning; rows rotated out under rule 70 live in `docs/tasks-archive.md`, and every task's stage docs under `docs/features/_archived/<slug>/`.

## Active tasks

| ID | Slug | Stage | Started | Doc folder |
|---|---|---|---|---|
| _(none)_ | | | | |

## Completed tasks

| ID | Slug | Outcome | Completed | Doc folder |
|---|---|---|---|---|
| T-15 | proxy-urltest-group | **DELIVERED** — `proxy` keeps its selector and gains a probing member: a `urltest` outbound tagged `auto`, emitted whenever ≥1 node exists, so a degrading node can be demoted without a human command and DNS (`remote_dns` detours through `proxy`) follows it. **The field report's premise was false and was verified false before anything was designed** — `bin/sc:1356-1363` was already a selector over every node plus `direct`; the defect that survives is that a selector *picks and stays*, never probing. Three new functions carry every new judgment, one definition each: `_auto_group_emitted()`, `_valid_selection()` (the single selection judge, absorbing all three of `sc`'s former arbitrary `node_tags[0]` auto-picks), and `stored_delays()` (the single Clash-API delay reader, parameterless for `sc ls` so `sc doctor` can call it unchanged later). Composed entirely through T-14's layer — the existing `$replace` on an array `CONFIG_BASE` already defines, **no new merge directive** (R-16 explicitly ruled not-ours and left open), and `generate_config()` gains no outbound literal. **1 rollback, and it is the whole story of the task.** Stages 2–5 passed the diff with all 35 ACs green; QA then ran the real binary against real traffic and measured that the shipped promise was wider than the behaviour: a *slower* member is demoted at 183 s and a *refusing* member at 190 s (≈ the emitted `interval: 3m`, with every request failing throughout), but **a member that accepts and never answers was never demoted in 440 s** — 2.4 intervals, 100 % traffic loss, three independent runs against a positive control that moved. That is precisely the failure `01 §1.2` leads with ("handshakes that hang rather than refuse"). Routed to the developer as **DEF-2**; fixed as a prose qualification in both READMEs and the CHANGELOG (no emitted parameter can close it — `urltest` has no per-probe timeout). **DEF-4 is the reason it got that far: not one of the 35 ACs observed the goal — all verify the artifact.** The gate earned its stage too: **F-1** caught that the design's K-6 carve-out (a host whose node is already tagged `auto` gets no group, silently) prints a `Switched to: auto` **byte-identical** to the real failover case, so the surface a user consults to check confirms the wrong belief — closed by C-1/C-2 as a mirrored README blockquote. **C-6 was resolved by finding a better fact rather than picking a side**: `interrupt_exist_connections` governs *external, inbound-originated* connections only, so the internally-dialled DoH transport is torn down on re-selection regardless and the gate's F-3 inversion cannot occur. **C-7 settled a hypothesis stage 2 could not**: the real `sing-box check` rejects a `urltest` with an empty member list (`FATAL initialize outbound[1]: missing tags`, exit 1), making the emit condition load-bearing rather than tidy. **AC-15 ended as an observation, not an inference** — QA **ran V-19** on a second unprivileged sing-box with the group selected via `proxy.default` (zero `PUT`/`PATCH`/`DELETE`, live service untouched) and recorded the SOCKS5 relay seeing `atyp=3 host=www.gstatic.com`, i.e. the probe FQDN went to the member and no local DNS server resolved it, so BC-12's circularity is impossible. QA **rebuilt** its harness rather than inheriting stage 4's, proved non-vacuity throughout (including reproducing the S-8 `LANG` trap *then* avoiding it), and closed RES-2 by AST-extracting all **11 frozen anchors** byte-identical with a mutant proof — noting a grep-based freeze check on this file is unsound because `timeout=3` is a prefix of `timeout=30`. Zero-node output is byte-identical to HEAD by construction; `sc use <name>/<index>` identical for 30 spec × language pairs; two consecutive `sc reload`s on a pre-T-15 host succeed with no hand-editing and no drift warning. **3 defects ship open and filed** (R-20/R-21/R-22), each unfixable inside this task's frozen set. `verify_all PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1` after archive — **better than the batch baseline** (16/1): F.6 cleared exactly as predicted before code was written, and F.5 (this row plus R-19…R-22 pushed the board to 308 lines) was cleared by rotating the eight oldest Completed rows into `docs/tasks-archive.md` under rule 70. No FAIL at any point in the run. Live service provably untouched at every checkpoint (`MainPID=2566751` + `ActiveEnterTimestamp`, never `is-active`); `/etc/sing-box/` mtimes unchanged; no mutating call ever reached the live Clash API. Product diff 5 files, **+250/−25**. | 2026-08-13 | `docs/features/_archived/proxy-urltest-group/` (mode: full) |
| T-14 | config-composition-layer | **DELIVERED** — `generate_config()` stops *being* the configuration and starts **composing** it: a module-level `CONFIG_BASE` data literal, one computed `_runtime_overlay()`, and a user-owned `/etc/sing-box/override.json` applied last, all three through a single `_merge()` with five directives (`$replace` / `$prepend` / `$append` / `$before` / `$after`). **Zero content change** — the point was to make T-15/T-16/T-17/T-21 small, not to make them. **The gate was byte-identity and it held under two independent measurements**: the developer's 148 runs and QA's **rebuilt** 164 (82 points × 2 languages, 860 comparisons) against a pristine `f642ca7` **clone**, comparing config bytes, stderr, boolean return and `nodes.json` — re-run green after every subsequent change, **unrelaxed and never re-baselined**. Non-vacuity was proven **before** the literal moved (three mutants, incl. **a pure key reorder changing no value** — R-1's named worst case; QA used six), which is what makes the green runs mean anything. The literal was moved **by script, never re-typed**: `diff` shows exactly four hunks (name + three position-holding placeholders), and stage 5 re-walked all 12 emitted positions down to an incidental double-space surviving. AC-1 holds **by construction** because every run-time value is written to a key that *already exists* in the base, so assignment preserves its position — the gate verified that claim key by key rather than accepting it, and caught that `CLASH_PORT` in the base would have **frozen the emitted port at 29090** on every host that ever probed another. **1 rollback, and it earned its stage**: QA found a **dangling symlink at `override.json` was silently treated as absent** (`rv=True`, empty stderr, `config.json` replaced, `exit=0`, no drift warning) — *the exact failure this task exists to remove, reproduced inside the fix for it*, on the version-controlled-symlink workflow D-14 had blessed. **No AC forbade it** (it sat in the seam between BC-7 "empty ≡ absent" and BC-9 "non-regular after symlink resolution") and `02` §5.4 had *specified* it, so it was routed to the **requirement-analyst**, not the developer. The analyst ruled it **malformed** — declining the internal precedent at `bin/sc:732-734` as merely corroborating and reasoning from BC-7's own discriminator (*can this shape encode a typo?* empty cannot; a symlink naming a moved target can) — then ruled the fix needed **no design change**, saving a stage-2 transition on the merits. `os.path.islink` makes BC-27's final-component-only boundary **a property of the primitive**, not an invariant to maintain. The fix's own non-vacuity was proven too: reverting only its five lines turns 20 of QA's 50 assertions red, reproducing the defect verbatim. **Three MINOR were ruled out rather than fixed** (R-15/R-16 filed; a fix would touch `_filter_rules`, pinned by AC-8). Two false claims were **retracted from the record and from the source** — `os.path.realpath` is **not** raise-free on any Python this project targets (`posixpath._joinrealpath` calls `os.readlink` unguarded at 3.8.2 **and still** at 3.12.3; the 3.10 rewrite guarded the `lstat`, not the `readlink`), verified against real stdlib source on two interpreters. Drift detection ships as a sha256 record at `/etc/sing-box/.config.sha256` via `_write_private()` at 0600 — a digest, **never a copy** of credential bytes. `_write_private()` remains the only writer of `config.json`; `_filter_rules` keeps one definition, two call sites, no new parameter; nothing is written at import or during `sc doctor`. Deep-copy discipline verified at all **eight** overlay entry points, and B-7 ("directives only at merge positions") holds because there is **no edge in the call graph** from `_apply_directive` back to `_merge` — structural, not remembered. `verify_all PASS: 16 / WARN: 1 / FAIL: 0 / SKIP: 1`; the clone reads 17/0/0/1, so the delta is **exactly** the gate-predicted F.6 doc-size WARN, which clears on archive. Live service provably untouched at every checkpoint (`MainPID` + `ActiveEnterTimestamp`, never `is-active`); `/etc/sing-box/` never written — no `override.json`, no `.config.sha256`; `/usr/local/bin/sc` never invoked. **Owed and labelled: Python 3.6 is statically audited, not executed** (no 3.6 interpreter on this host). `baseline.json` still `test_count: 0` — the harnesses are throwaways, R-9 owns a committed suite. Product diff 7 files, **+740/−95**. Uncommitted; owner owns delivery. | 2026-08-01 | `docs/features/_archived/config-composition-layer/` (mode: full) |

## Notes

### Open rows surfaced by T-08 — owner to number

1. **Version-query silent abort** (`install.sh:373-381`). Under `set -euo pipefail`,
   `SB_VER=$(curl … | grep … | sed …)` aborts *at the assignment* on HTTP 403/404 or transport
   failure, so the bilingual `download_failed`/`check_network` handler below it never runs **and
   `install_report()` never runs** — the installer can exit having stated no outcome, the exact
   property T-01 exists to guarantee. GitHub's unauthenticated rate limit makes this routine, not
   theoretical. Found at stage 2, verified against the source at stage 1', filed in
   `.harness/rejected-decisions.md`; deliberately not absorbed because it changes failure behaviour
   that T-08's AC-6/AC-14 pin as unchanged.
2. **Committed bilingual key-parity gate — now deferred four tasks running.** `install.sh`'s `t()`
   declares `local fmt` with no default, so a key present in only one language branch aborts the
   whole installer under `set -u`, and the zh branch is reachable only by answering `2`. Parity was
   proven three times independently during T-08 (41 keys, both tables) but the proof is **not
   committed**, so the hazard is exactly as shippable for the next task. The code reviewer calls this
   the highest-leverage open debt touching this file. `rejected-decisions.md:57-73` already says the
   next task "should probably widen its own diff instead"; T-08 could not, because AC-19 pinned the
   shipping diff.
3. **Two test-infrastructure defects inherited by T-07** with the harness: `gate_checks.sh` writes
   `faults.json` while `server.py` reads `control.json` (re-run as shipped it yields a false FAIL),
   and AC-3's non-vacuity is carried by the server **throttle**, not the fixture size, with no guard.
4. **`docs/dev-map.md` seam row** for `CURL_OPTS_QUIET`/`CURL_OPTS_PROGRESS` — belongs to T-07, which
   owns the next edit to these flags. Deliberately not added by T-08: dev-map is not in AC-19's
   carve-out, so editing it would have breached the criterion the gate made binding.
5. **`.harness/scripts/baseline.json` still reads `test_count: 0`** across all five delivered tasks —
   the project had no committed test suite. **Partly resolved by T-11**, which made B.2 a real check;
   B.3 (lint) is still SKIP and `baseline.json` still reads zero — see R-4. Every task before T-11
   built a throwaway harness and discarded it.

### Open rows surfaced by T-11 (R-1 … R-8) — owner to number

Each was found by a T-11 stage agent, judged out of scope by the requirement or the design, and
deliberately **re-homed rather than dropped**. HEAD anchors are pre-T-11 line numbers.

1. **R-1 — unguarded `mktemp -d` assignments.** `ARTIFACT_DIR="$(mktemp -d -t …)"` (`install.sh:332`)
   and `SB_TMPDIR="$(mktemp -d)"` (`:371`) abort the run by exactly T-11's mechanism, leaving only
   `mktemp`'s raw English line. Re-homed (D-3/O-8) because no handler below them is made unreachable
   and the failure domain is the local temp filesystem, not the network.
2. **R-2 — empty version display.** `t step2_already "$(sing-box version | head -1)"` (`:368`) and
   `t step2_done "$(…)"` (`:392`) discard the substitution's status, so a `sing-box` that exits
   non-zero prints `▶ [2/7] sing-box already installed: ` with an empty version and the run
   continues. A display defect, not an abort.
3. **R-3 — the wider silent-abort class.** Bare `python3` heredoc (`:403-417`), `tar -xz` (`:390`),
   `install -m` (`:391`/`:398`/`:399`/`:428-430`), `chmod` (`:454`/`:462`), `visudo -c` (`:463`) all
   abort `install.sh` with no stated outcome. **T-01's "the installer always states its outcome"
   guarantee is not global, and T-11 does not make it so** (D-7). This row is the one that would.
4. **R-4 — `.harness/scripts/baseline.json` still reads `test_count: 0`.** T-11 made `verify_all`
   B.2 a real check (`check-i18n-parity.sh`, 41 keys × 2 languages), so the file can finally be
   populated instead of recording zero across six delivered tasks.
5. **R-5 — the `fail_download()` helper.** Three sites now share
   `t download_failed … ; t check_network ; exit 1` (`:346-348`, `:385-387`, and T-11's new block).
   The seam is real; T-11 declined it (`02_SOLUTION_DESIGN.md` §3.5, recorded in
   `.harness/rejected-decisions.md` as `installer-early-exit-download-helper`) because it would pull
   two untouched blocks into the diff and weaken the line-by-line audits AC-9 and B-5 rest on.
   Natural owner is R-3, which rewrites this failure class anyway.
6. **R-6 — the PowerShell mirror diverges.** T-11 wired B.2 in `.harness/scripts/verify_all.sh` only;
   `.harness/scripts/verify_all.ps1:79` still reads `Step "B.2" "Tests pass"` with a SKIP body, so
   the two mirrors now disagree about what B.2 is. Out of T-11's permitted diff by AC-12/A-4;
   recorded here so the divergence is not silent.
7. **R-7 — the B.2 gate's blind spots. NARROWED by T-13, not closed.** The first blind spot (the
   `LANG_CHOICE` false green: mutating the dispatch made `check-i18n-parity.sh` render the **en**
   table twice, agree on every comparison, print `OK: 41 keys, both languages` and exit 0) **is
   fixed** — commit `49506f8` added the `--- 3b. self-check` step (`check-i18n-parity.sh:98-107`),
   which `die2`s when the two renders come back byte-identical. T-13's gate reviewer verified this
   and **rejected** the design's claim that the whole row was stale.
   **The second blind spot is live.** The checker enumerates keys **from the two tables**, so a
   `t <key>` *call site* naming a key absent from **both** is invisible to it — while killing the
   installer outright under `set -u` (`t()` declares `local fmt` with no default, and `|| true`
   cannot catch an expansion error), i.e. the R-3 "states no outcome" class. T-13 added seven such
   call sites and discharged them by a bespoke `bash -u` matrix reaching all seven keys in both
   languages; **nothing committed catches this for the next task.** Cheapest fix: have the checker
   also extract `t <key>` call sites and assert each names a key that exists. Owner: solution-architect.
8. **R-8 — three T-11 document defects, none reaching product code.** (a) `02_SOLUTION_DESIGN.md`
   §10's E-10 fixture is defective: `yes … | head -200000` is itself an early-exiting reader *inside*
   the measured pipeline, so under `pipefail` both legs return 141 regardless of the extraction tail
   — the probe could never distinguish its own legs. (b) §4's "+11 line shift" is actually +14.
   (c) `04_DEVELOPMENT.md`'s "load-bearing, not precautionary" overstates the evidence; the accurate
   reading is *load-bearing for large or hostile bodies, precautionary for the real endpoint*.
   (d) `.harness/rules/50-singbox-cli.md:45` still opens "until B.2/B.3 are real", now false for B.2
   — C-11 correctly forbade touching it, so it belongs to the next rule-50 edit.

### Open rows surfaced by T-13 (R-9 … R-14) — owner to number

Filed by the PM at delivery to discharge gate conditions **C-1** and **C-11**. Each was found by a
T-13 stage agent, judged out of scope, and **re-homed rather than dropped**.

1. **R-9 — the committed `bin/sc` test harness. This is the price the gate charged for deferring it
   a fourth time (C-1), and it is now filed with scope rather than re-argued.** It covers: a real
   `verify_all.sh` step, the `verify_all.ps1` mirror (R-6), populating `baseline.json` (R-4, still
   `test_count: 0` across seven delivered tasks), and — the part that has repeatedly made this row
   look cheaper than it is — **fail-closed safety criteria of its own**: refuse under root, never
   touch `/etc`, never touch the live service. A committed step means `bin/sc` is imported on the
   owner's live machine on **every** future `verify_all` run, forever, which requires permanently
   defusing the import-time auto-elevate that once re-execed the *installed older* binary under sudo
   and restarted the owner's VPN. T-13 declined on exactly that risk-coupling ground rather than the
   diff-boundary ground `rejected-decisions.md § ruleset-unit-tests-in-t02` has grown tired of.
   **A runnable, non-vacuous harness now exists to build from**: `06_TEST_REPORT.md` §12 carries 106
   assertions verbatim, including the `sys.modules` neutralisation shim (also in `docs/dev-map.md`).
2. **R-10 — hand-made credential backups are invisible to the installer sweep.**
   `/etc/sing-box/config.json.bak-2026-08-01-1001` exists on this host at `0600`. It is correctly
   outside `CRED_FILES` (NG-11 — the sweep must not roam), but a hand-made backup at a *wide* mode
   would never be reported. Natural owner is **T-20**'s permission audit, which is the row that owns
   a full sweep rather than an enumerated one.
3. **R-11 — `/etc/sing-box/`'s own mode is never checked or set deliberately.** `install.sh` creates
   it at the ambient umask, and it is world-readable and traversable on this host. If it were ever
   world-*writable*, a local attacker could rename their own file over T-13's temp name between
   `fchmod` and `replace`. Strictly better than HEAD (where the same attacker plants a symlink and
   gets credentials written *through* it), and NG-5 put the directory out of T-13's scope — but
   nothing owns it. Owner: T-20 or a new row.
4. **R-12 — a helper that `sys.exit`s inside a function whose caller owes a run-level outcome.**
   After T-13, `save_nodes()` exits on failure and is called from inside `generate_config()`, which
   `cmd_update_rules()` calls — and that function's own contract is "exactly one truthful run-level
   outcome, always, before the exit". Ruled ship-as-designed at stages 3 and 5 (HEAD exited via an
   uncaught traceback on the identical path, so it is a strict improvement, and the trigger needs a
   stale active tag **and** a failing filesystem). The **general** statement is the row: T-01/T-10's
   outcome invariant is not enforced by anything structural. **T-14 adds a second unwind past the
   same block**: `generate_config()` now raises `OverrideError` on a malformed
   `/etc/sing-box/override.json`, and `main()` renders it with `sys.exit`, so a `sc update-rules` run
   that regenerates (`gained`) while the user's override is broken also skips
   `cmd_update_rules`' run-level outcome line. Ruled ship-as-designed at T-14's gate (the abort lands
   strictly before `restart_service()`, so nothing happened to the service and the run names the file
   to fix); the six-line exception stash was explicitly *not* required. Two raise sites now, one row.
5. **R-13 — the new `bin/sc` key renders English-only on one of its five call sites.** `main()` calls
   `_init_files()` before assigning `LANG`, so a failure writing `nodes.json` at start-up renders
   `Could not write {path}: {err}` in English. Both languages ship and the other four call sites are
   bilingual, so AC-22 holds; it is strictly better than HEAD's English traceback. **C-13 explicitly
   forbade fixing it here** by reordering `_load_lang()` — that would be an unrequested change to the
   start-up path T-05 deliberately shaped.
6. **R-14 — the new write path needs permission on the *directory* where HEAD needed it only on the
   file.** Found by QA, predicted by no upstream document: with the target writable but its directory
   at `0500`, HEAD succeeds and the new build fails loudly. Unreachable in production (root bypasses
   directory DAC; EROFS fails both), but it is a real behaviour change and belongs on the record
   rather than in a future bug report.

### Open rows surfaced by T-14 (R-15 … R-18)

R-15/R-16 filed by the requirement-analyst at stage 1′, discharging `06`'s two MINOR; scope rulings
and reasons are in `docs/features/config-composition-layer/01_REQUIREMENT_ANALYSIS.md` §12.4.
R-17 filed by the PM at delivery, discharging the gate's and the code reviewer's shared instruction
to re-home R-4 rather than fix it inside a byte-identity gate.

1. **R-15 — an override shape outside BC-8 … BC-14 reaches the user as a Python traceback instead of
   a sentence.** One defect, two measured instances: (a) `06` D-2 — a 3 001-byte override nested 500
   levels deep makes `copy.deepcopy` raise `RecursionError`, printing 2 999 lines / 135 KB to a
   stream `install.sh` redirects into `/var/log/sing-box/install.log` (BC-18), against B-11 and
   NFR-7's one-complete-line-per-fact contract; (b) `05` MINOR-1 — a non-object element in
   `dns.rules` / `route.rules` reaches `AttributeError` in `_filter_rules`. Both are contained: no
   write, no service-affecting action, non-zero exit. The coherent fix is **one exception envelope
   over the override pipeline**, not a per-shape guard — a change to T-14's error model, which is why
   neither instance was patched inside T-14. Do not fix by widening `02` §6's shape assertion or by
   touching `_filter_rules` (pinned by AC-8).
2. **R-16 — the merge has no type-mismatch vocabulary: a bare *object* silently replaces an existing
   array.** `{"inbounds": {"mtu": 1500}}` replaces the TUN inbound array; `02` §5.3 specifies it, and
   it is the unguarded mirror of D-5. Deliberately not fixed in T-14: D-5's rationale turns on the
   wrong result being *valid and silent*, and `06` measured the mirror to be loud — the real
   `sing-box` 1.13.15 returns `rc=1`, `sc reload` fails in the same invocation, the service is never
   restarted. Owner: whichever of T-15 / T-16 / T-17 / T-21 first needs the vocabulary; it carries the
   README obligation with the fix. Related boundary, same mechanism: an object keyed `"0"` does not
   address array element 0 (`06` §8 O-5).
3. **R-17 — the credential write path has no `encoding=`, so a non-ASCII node tag raises under a
   non-UTF-8 locale.** `_write_private()` and `save_nodes()` both write through
   `os.fdopen(fd, "w")` with no `encoding=` while dumping with `ensure_ascii=False`, so on a host
   where `sudo` yields `LC_ALL=C` a node tag containing non-ASCII characters aborts the write. Named
   as R-4 in T-14's `02` §13, confirmed unfixed at stages 4/5, and **deliberately not fixed**: it
   changes `_write_private()`'s behaviour inside a task whose gate is byte-identity, and T-14's
   harnesses run under UTF-8 so AC-1 could never surface it. **QA refined the diagnosis and the
   refinement is the useful part**: under `LC_ALL=C` both the pre- and post-change builds raise
   *identically*, but the raise is a `UnicodeDecodeError` in **`load_nodes()`** (`bin/sc:418`), which
   fires *before* `_write_private()` is ever reached — so a fix that touches only the write side
   would not make a non-ASCII tag work. The drift record is immune by construction (`_config_digest()`
   hashes the file's bytes, not in-memory text). Owner: whichever task next opens the state-file I/O
   seam; T-20 is the natural site.
4. **R-18 — `archive-task.sh`'s rotation is dead code, and the one-line cause is now known.** T-05
   recorded that the script "harvests but never rotates", and every task since has hand-rotated. The
   cause, diagnosed at T-14's archive: the script's rotation threshold counts **bullets**
   (`archive-task.sh:89-94`, `grep '^\s*-\s'` → 25 after harvest, under its 30) while `verify_all`
   **F.4 counts lines** (34 against a 30 cap). The two metrics differ by the file's header, so on any
   index with a header the branch can never fire — it is not a tuning problem. Fix is to make the
   script count the same thing F.4 counts. Note the file also carries a **local** fix for the older
   first-physical-line truncation bug (`:51-71`, an awk joining continuation lines, dated 2026-07-31)
   with a note that `/harness-upgrade` may overwrite it — so both defects live in a plugin-vendored
   script that a framework upgrade can silently revert. Owner: unassigned; it costs every task a
   manual step until fixed.

### Open rows surfaced by T-15 (R-19 … R-22)

Filed by the PM at delivery. R-19 was surfaced by the requirement-analyst and made a non-goal
(D-13/NG-10) so the new column header would not copy the defect; R-20 … R-22 are QA's DEF-1, DEF-3
and DEF-4/DEF-5, each **routed here rather than back into T-15** because none is fixable inside that
task's frozen set — the reasons are recorded in `PM_LOG.md` under the stage 6 → 4 rollback.

1. **R-19 — the five namespaced `ls.*` translation keys print literally in English.**
   `bin/sc:183-187` + the `sc ls` header. `TRANSLATIONS` has no `en` table, so `t()` returns the key
   verbatim and English users see `ls.idx  ls.active  ls.type  ls.name  ls.address` as column
   headings. Known since T-02 ("`TRANSLATIONS` has no `en` table", follow-up note 2) but never filed
   against these specific five. One-line fix per key: replace each with the English word it means.
   T-15 deliberately did **not** fix them (`.harness/rules/85-design-discipline.md`'s counter-rule
   forbids widening scope) and instead made its own new key an English sentence — so the English
   header now reads `ls.idx … Delay`, visibly mixed until this lands. Natural owner: the next task
   that changes `sc ls`'s columns.
2. **R-20 — `clash_api()`'s `except` does not cover what its own body raises, and `sc ls` is now on
   that path.** `bin/sc:1635-1638` catches only `URLError`/`HTTPError`, but QA reproduced **four**
   escaping classes: `TimeoutError` (a port that accepts and never answers — needs no foreign server,
   a stalled sing-box suffices), `JSONDecodeError` (non-JSON 2xx), `UnicodeDecodeError` (invalid
   UTF-8), `IncompleteRead` (short body). Two of BC-9's four states therefore fail AC-24's "no
   traceback on a broken host". **Pre-existing** — HEAD's `sc status` raises the same types, verified
   against a clone — but T-15 newly puts `sc ls`, the command whose whole point is working on a
   broken host, on that path. Not fixable inside T-15: `clash_api()` was frozen by AC-28 (byte-identity
   independently verified) and K-12 forbade a local `try`/`except`. The row is the **class**, not the
   one body shape the code reviewer first spotted. Note the reviewer's reachability analysis
   ("needs a *foreign* HTTP server") understates it. Owner: whichever task next opens the Clash API
   seam; the coherent fix is one exception envelope around `clash_api()`, sibling to R-15's.
3. **R-21 — `RESERVED_TAGS` does not cover sing-box's implicit `GLOBAL` selector.** `bin/sc:56`
   reserves `proxy`/`direct`/`auto`, but the live `GET /proxies` returns a `GLOBAL` entry that is not
   an `sc` outbound at all. A node tagged exactly `GLOBAL` mints cleanly, the real checker accepts the
   document, and `sc ls` prints that entry's stored delay in the node's row (`9999 ms` in QA's
   reproducer). Narrow, no exception, table intact. The general statement is that
   `stored_delays()`'s map is keyed by the API's tags, not by `sc`'s nodes.
4. **R-22 — two upstream requirement defects, both found by running the software rather than reading
   it.** (a) **No acceptance criterion observed the goal.** T-15's AC-1…AC-35 verify the emitted
   document, the selection state machine and the `sc ls` rendering; not one asks whether a degraded
   node stops carrying traffic. That is why DEF-2 — a promise materially wider than the behaviour —
   passed stages 2, 3, 4 and 5 with every AC green. The row is the *pattern*: an AC set that pins the
   artifact and never the behaviour will pass a gate it should fail. (b) **`BC-9`'s stated mechanism
   is factually wrong** — "`clash_api()` returns `None` on every `URLError`/`HTTPError`" is not what
   the code does (see R-20), and AC-24 inherited that reading. Not routed back to the analyst at
   delivery: the gap in (a) had already been closed empirically by QA's own measurements, and (b)'s
   consequence is R-20. Owner: the next task writing ACs against a behaviour with a live counterpart.

### T-02 consolidation (rule 85)

T-02 deliberately absorbed what were originally three rows — config degradation, mirror/validation,
and download progress — because all three need the same judgment ("is this rule-set file usable?").
Split, degradation would have shipped a bare `path.exists()` and an HTML error page would have read
as "present". Recorded in `02_SOLUTION_DESIGN.md` §12 and verified structurally at stages 3 and 5
(deletion test: removing `srs_reject_reason` forces magic/floor logic back into two live call sites).

### Follow-up rows surfaced by T-02 (not yet filed — owner to number them)

Each was found by a stage agent, judged out of scope by the gate or the PM, and deliberately
**re-homed rather than dropped**:

1. **Python-floor violations — five sites, not two.** `capture_output=` (3.7+) at `bin/sc:822`,
   `:864`, `:1159`, plus `text=True` (3.7+) at `:822`, `:1159`. The documented 3.6+ floor is already
   false today. Either lower the code or raise the floor in both READMEs and `CHANGELOG.md`.
   *(Requirement Q9 counted two; the gate reviewer found the third, the code reviewer the rest.)*
2. **`TRANSLATIONS` has no `en` table**, so `t()` returns the key verbatim in English — `bin/sc:642`
   already prints a literal `ls.idx`. Constrains every future key to readable English prose.
3. **`--mirror` sudo/scheme hardening.** `--mirror` survives the auto-elevate re-exec (argv is
   preserved even though the environment is not) and `urlopen` accepts `file://`. Privilege impact
   negligible; the requirement's security NFR is nonetheless stale. A `http`/`https` allow-list is
   a one-line fix.
4. **D-4** — a local disk fault (ENOSPC, `replace()` EPERM) is reported as a *mirror* failure and
   leaks the internal temp path. A-1 widened this to a second surface: it can now appear on a
   success line as well as a failure line, so a fix must test both.
5. **D-5** — stray blank line before the restart notice in `cmd_update_rules`.
6. **`_temp_path` prefix coupling** — `_clear_stale_temps` builds `fname + ".tmp"` independently, so
   the `".tmp"` literal is written twice and coupled only by convention.

### Carried to T-07

Restricted-network end-to-end verification (never reproduced here — no such VM), the four items QA
left honestly unverified (BC-25, the D-2 escalation, AC-26 on a real 3.6 interpreter, BC-32), and
QA's 846-assertion harness, which T-07 should inherit in preference to the developer's.

## Conventions

- **ID** is sequential: `T-001`, `T-002`, ...
- **Slug** is lowercase-kebab, ≤40 chars (e.g. `csv-export-orders`).
- **Stage** is one of: `req`, `design`, `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`.
- **Doc folder** is the relative path under `docs/features/<slug>/`.

## How tasks relate

When starting a new task, the Requirement Analyst scans this board for related work:

- Same module → read prior `02_SOLUTION_DESIGN.md` first.
- Same feature → build on prior design, don't redesign.
- Conflicting decisions → flag for user.
