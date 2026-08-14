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
| T-20 | doctor-extended-checks | **DELIVERED** — `sc doctor` now reports **nine** facts instead of seven, and this was the batch's convergence task: every one of the six new facts already existed somewhere, so the design question was *which existing call does each row stand on*, not how to compute it. All six stand on their feature owner's call — rule-set age on T-19's single-reader `mtime` + `_age_text()` (K-17 honoured, consumed inside `_doctor_rulesets()`'s existing loop), drift on T-06's extracted `_drift_state()`, AAAA state on T-16's `ipv6_decision()`, node delays on T-15's `stored_delays()`, permissions on T-13's `CRED_MODE` + its own `mode & 0o077` predicate, DNS through the already-total `clash_api()`. **The goal sentence's "DNS timing" clause was refuted at stage 1** (the fifth consecutive pool task where that held, and again the largest saving): `CONFIG_BASE`'s whole `dns` block carries no timeout key, so a row reporting a configured DNS timeout would report a value that does not exist. Re-scoped to one **measured** fact behind **BC-16** — ship nothing unless a first-hand probe finds a boundable mechanism reaching the running install's resolver — with `socket.getaddrinfo` pre-ruled inadmissible (BC-17, it takes no timeout argument). The architect's probe **P-1** read the `sing-box` binary's symbol table (`clashapi.queryDNS` + `clashapi.dnsRouter` present, literal `/dns/query` matching 0 as a negative control, `/providers/rules` = 1 as calibration); the gate **re-ran it with two controls the design did not** (`configRouter`/`proxyRouter` present and live, a fabricated symbol 0) plus a **counter-control** — `scriptRouter` is present while `/script` answers "not supported" — which bounded the ruling to *mounted*, never *supported*, and is why **GC-6** forced a live P-2 before the row was written. **Rule 85 held literally**: 2 new `DOCTOR_SECTIONS` entries, 5 new rows, 3 seams, **+5 rows exactly** on a healthy host (16 → 21 vs a HEAD clone on the same fixture root), all `[OK]`, none naming a path or next step, exit 0; `_age_seconds()` deliberately **not** added; the undeclared-growth chain closed at **+288** then **+294 net with no slack** across the rework. **1 rollback** (stage 5 → 4, CR-1 MAJOR): the clean-host permission row asserted "no file grants access to group or other" while `settings.json` is excluded **by name whatever its mode** and `save_settings()` writes it `write_text()` — 0644 on **every default install**, so the row was false on the commonest host state there is. Fixed by narrowing the **sentence, never the check** (both predicates verified byte-unchanged at round 2) — the R-22 defect class caught in the text of the row that reports on it. **R-10 closed** (the full sweep catches a hand-made `config.json.bak-<date>` at 0644 with no filename pattern; safe because a reporter may enumerate where a *chmod*ing sweep may not), **R-11 half-closed** (directory row narrowed to `mode & 0o022`, the rename-window attack, never the world-readable mode every host has; `install.sh`'s half stays open), **R-32 closed**, **R-43 closed by ruling**. QA rebuilt the suite from `01` and from `bin/sc` itself — **317 assertions, 14 files, 3 consecutive clean runs**, no line number inherited (RES-10) — and reproduced three residuals independently. **AC-B14 BLOCKED and filed**, never substituted (R-31/R-41/R-47, honoured a fourth time) → `.harness/operator-obligations.md` id 1. `verify_all PASS 17 / WARN 0 / FAIL 0 / SKIP 1` at four PM checkpoints. Product diff 5 files, **+366/−66**. | 2026-08-14 | `docs/features/_archived/doctor-extended-checks/` (mode: full) |

## Notes

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
2. **R-10 — CLOSED by T-20** (2026-08-14). `sc doctor`'s permission row sweeps every regular file
   directly inside the configuration directory (one exclusion, `settings.json`; no filename
   pattern), so a hand-made backup at a wide mode is now named with its mode and a `chmod`.
   The asymmetry that made it safe: NG-11 forbids the *installer* sweep from roaming because it
   `chmod`s; a reporter only reports. Nothing left open here.
3. **R-11 — HALF-CLOSED by T-20** (2026-08-14). The *checking* half shipped: the row is PROBLEM on
   `mode & 0o022` — the rename-between-`fchmod`-and-`replace` window R-11 names — and deliberately
   never on the world-readable, traversable mode every host has, which would fire on 100 % of
   installs. **Still open: nothing sets the directory's mode deliberately.** `install.sh` still
   creates it at the ambient umask, and T-20's out-of-scope 2 kept the installer untouched.
   Owner: whichever task next opens `install.sh`.
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

Filed by the PM at delivery; R-19 was made a non-goal (D-13/NG-10), R-20 … R-22 are QA's DEF-1/3/4/5,
each routed here rather than back into T-15 because none was fixable inside that task's frozen set.

1. **R-19 — the five namespaced `ls.*` translation keys print literally in English.**
   `bin/sc:183-187` + the `sc ls` header. `TRANSLATIONS` has no `en` table, so `t()` returns the key
   verbatim and English users see `ls.idx  ls.active  ls.type  ls.name  ls.address` as column
   headings. Known since T-02 ("`TRANSLATIONS` has no `en` table", follow-up note 2) but never filed
   against these specific five. One-line fix per key: replace each with the English word it means.
   T-15 deliberately did **not** fix them (`.harness/rules/85-design-discipline.md`'s counter-rule
   forbids widening scope) and instead made its own new key an English sentence — so the English
   header now reads `ls.idx … Delay`, visibly mixed until this lands. Natural owner: the next task
   that changes `sc ls`'s columns.
2. **R-20 — CLOSED by T-18** (2026-08-14), exactly as this row prescribed: one exception envelope at `clash_api()`, no caller-side guard. Row text rotated to `docs/tasks-archive.md`. It was **wider than filed** — six escaping classes, not four.
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

### Open rows surfaced by T-16 (R-23 … R-27)

Filed by the PM at delivery; detail in `docs/features/_archived/dns-resilience/07_DELIVERY.md`. (R-18 confirmed a fourth time; index hand-rotated.)

| id | row | owner |
|---|---|---|
| R-23 | **A name whose only resolver is reached through a node stays unresolvable while that node accepts and never answers.** Not a defect — a measured capability gap: sing-box 1.13.15 has no DNS-query-level timeout at any level, no fall-through on failure, and `dns.final` is the no-match default, so no configuration this project emits can cover it. Re-pointing `final` to the domestic resolver was rejected on the merits (Q-17). Revisit only if a sing-box release adds a per-query bound or a real fallback transport; the probe deliberately established only that `timeout` is absent, not that no other key exists. | unassigned |
| R-24 | **`sc ipv6 <value>` says "Nothing changed" at the one moment the user is most likely to be sitting in a stale-document stall, and names no escape.** Both sides of the comparison come from the current host, never from the document on disk — which is correct (AC-6 forbids the second opinion). The escape exists (`sc reload`, or a value that flips the decision) but is never prompted. Note `sc ipv6 off` repairs it only in one direction. BC-13 now states the general rule; making the *line* name the repair needs its own design round. | next task touching `cmd_ipv6` |
| R-25 | **`_load_lang()` (`bin/sc:312-314`) lets a non-UTF-8 `settings.json` reach the user as a traceback**, before any command runs, `sc doctor` included. Pre-existing and adjudicated out of T-16's scope (T-16 puts no new user on the path). The class is repo-wide and partly *prescribed*: `_ipv6_setting()` and `_saved_clash_port()` carry the same catch tuple, so a fix must take the family together. The repo's own fix shape is `bin/sc:1712`'s `(OSError, ValueError)`. | next task opening the settings I/O seam |
| R-26 | **`OverrideError` provenance is structural at two of its three sites.** The third (`generate_config()`'s three-key array guard) is correct today only by an argument in its own comment, not by call structure — the property the docstring and `docs/dev-map.md` both claim. Gating the guard on `override is not None` would make it structural at zero behavioural cost. | solution-architect / next override-pipeline task |
| R-27 | **A malformed `settings.json` is rewritten to a single key, dropping `lang`/`mode`.** Confined to a file already unparseable, where every reader in `sc` treats those keys as absent anyway, so what is discarded was not in effect. Deliberately left out of user-facing text to avoid over-weighting a corrupted-file edge case. | unassigned |

### Open rows surfaced by T-17 (R-28 … R-30)

Filed by the PM at delivery; detail in `docs/features/_archived/telemetry-reject-list/07_DELIVERY.md`.
(R-18 confirmed a fifth time; index hand-rotated.) **R-16 remains open and unclaimed**, declined by
T-15, T-16 *and* T-17 — the last on the ground that its vocabulary would not serve the user-extension case.

| id | row | owner |
|---|---|---|
| R-28 | **`TELEMETRY_NAMES` has no freshness owner.** A shipped name list ages: endpoints retire, vendors move collection, new dominant SDKs appear. T-17 deliberately adds no update path (a rule-set would be deleted by `_filter_rules()` on the degraded host that needs it), so the list is only ever revised by editing `bin/sc`. **The need is proven, not hypothetical**: one of the eighteen names stage 2 proposed did not resolve at all, and only C-3's first-hand check caught it. A task that re-runs a resolution check over the tuple would catch the next one in seconds. | unassigned |
| R-29 | **`load_settings()` lets two whole failure classes reach the user as a traceback, for every reader.** `Path.read_text()` raises `UnicodeDecodeError` — a `ValueError`, **not** an `OSError` — so the repo's habitual guard tuple misses it; and a `settings.json` that is valid JSON but **not an object** (`null`, `42`, `"telemetry"`) raises `TypeError: argument of type 'NoneType' is not iterable`. Both are pre-existing and both were proven so with HEAD-side controls (`sc ipv6 show` fails identically). This **supersedes and widens R-25**: the fix is one `except (OSError, ValueError, TypeError)` plus an is-a-dict check at `load_settings()`, closing it for `_ipv6_setting()`, `_telemetry_setting()` and `_saved_clash_port()` at once, rather than three guard tuples. | next task opening the settings I/O seam |
| R-30 | **Operator obligation, not a code row.** T-17's behaviour change reaches the owner's live host only when a human installs the new `bin/sc` and runs `sc reload` there — no agent on this project may touch `/usr/local/bin/` or the live service. Until then the running host keeps the pre-T-17 document. Stage 6 could not file this itself (`.harness/**` is outside the task's permitted diff) and routed it here. | owner |

### Open rows surfaced by T-18 (R-31 … R-35)

Filed by the PM at delivery; detail in `docs/features/_archived/status-egress-via-clash-api/07_DELIVERY.md`.
**R-18 confirmed a sixth time** (index hand-rotated again). **R-20 is closed** (above). **R-29's family
statement should name three readers, not two**: `load_nodes()` (called unguarded by `cmd_status`) carries
the same classes plus an absent-file case — T-18 stage 1's Q-5, left out of scope. **R-22(a) was honoured**
(AC-B1/AC-B2 observe the behaviour); R-22(b) is moot now that R-20 is fixed.

| id | row | owner |
|---|---|---|
| R-31 | **Operator obligation, not a code row.** AC-B1/AC-B2 — one run of `sudo python3 <repo>/bin/sc status` on this pure-TUN host, compared against an independent echo endpoint in the same minute — is the criterion R-22 exists to force, and it is the one promise T-18 did **not** close by a run. It blocked on `sudo -n true` → "a password is required" with no interactive terminal; running non-root would have taken the import-time re-exec into the **installed** `/usr/local/bin/sc`, so QA correctly did not attempt it. The behavioural goal itself was observed by another route (egress `38.47.117.142`, matching three echo endpoints, service witness unchanged), so what is owed is the shipped invocation form end to end as root. Recipe and witnesses in `07_DELIVERY.md`. | owner |
| R-32 | **`_doctor_clash()`'s PROBLEM message now names a cause it does not have.** `"no answer within the 3s timeout"` / 「3 秒超时内无响应」 (`bin/sc` key `:291`) now renders for BC-2 … BC-5 and BC-7 — states in which an answer *did* arrive well within the timeout. A pre-existing imprecision (HEAD already used it for a 4xx and for a refused connection) that T-18 widened to four more states. Deliberately not fixed: `sc doctor`'s wording was frozen by T-18's out-of-scope item 5 and BC-14. Code reviewer's CR-2 / RES-1. | T-20 |
| R-33 | **`sc status > file` prints the `ip` output above the first heading.** `cmd_status`'s `print()` is block-buffered when stdout is a pipe while its `subprocess.run(["ip", …])` children write fd 1 immediately, so the sections come out reordered — in exactly the redirected bug-report case. Pre-existing and identical at HEAD (control run), so no regression, and no AC covered it. `_doctor_print()` already flushes per row for this same reason, so the fix shape exists in-tree. QA-D1, MAJOR. | next task touching `cmd_status` |
| R-34 | **"exactly one value line per heading" is falsifiable, and the promise is what needs narrowing.** A Clash API answering `{"mode":"rule\nINJECTED"}` yields two lines under `=== Route mode ===`, candidate and control alike. BC-12 declines a *size* cap, not an output-shape guarantee, so this is not covered by an existing ruling. The R-22 shape once more: a promise materially wider than the behaviour. QA-D2, MINOR. | next task writing ACs over `sc status` |
| R-35 | **A number for R-23/R-3's family: `timeout=N` bounds each socket operation, not the call.** A peer dripping one body byte every 2 s keeps a `timeout=3` `urlopen` alive **30.1 s** and then returns success — measured, candidate and control alike, so not a T-18 defect. Any "it gives up after N seconds" claim about `clash_api()` or `_egress_ip()` is false as written. Attach to R-3's row when that failure class is next opened. | unassigned |

### Open rows surfaced by T-19 (R-36 … R-41)

Filed by the PM at delivery; detail in `docs/features/_archived/ruleset-staleness-visibility/07_DELIVERY.md`.
**R-18 confirmed a seventh time** (index hand-rotated again). **R-12 narrowed, not closed** (Q-2): its two
unwind paths already exit non-zero with the cause on stderr before any service-affecting action, so the row
is now about the missing outcome *line* only. **R-4/R-9 unchanged** (`test_count: 0`, nine tasks running).
**R-22 honoured; R-31's discipline held** — AC-B9 BLOCKED, never substituted (→ R-41).

| id | row | owner |
|---|---|---|
| R-36 | **AC-S3's ledger carve-out omits `docs/batches/**`.** QA-D2: `BATCH_PLAN.md` (M) and `BATCH_LOG.md` (??) are in neither of AC-S3's two lists, and the criterion says a path in neither list *is* a failure — yet both are the batch loop's, both predate stage 4, and neither was written by any T-19 stage. The candidate itself is clean; the criterion's text is what needs the third carve-out. Any future task reusing this AC template inherits the false failure. | next task writing an AC over the committed diff |
| R-37 | **`.harness/rules/70-doc-size.md` defines no `## Stage-doc boundary rule` on this project**, so units the PM's dispatch requires in a contract portion (rule 85's `## Smaller alternative rejected`, the FR/BC/AC coverage table, C-6's per-edit-id size table, C-2/C-3/C-4/C-5/C-8's evidence) fit no declared stage-doc shape. Recorded as a gap at stages 2 (E-20), 3, 5 (RES-10) and 6 (QA-D1) — **five stages in one task**, each carrying it as a named section rather than inventing one. Cheapest fix is one section in rule 70. | unassigned |
| R-38 | **The zh rule-set row's separator is an ASCII `, ` where `sc doctor`'s is a localised `，`.** `sc status` prints `可用, 30 天前` because I-3 fixes the separator inside the format string `"%-20s %s, %s"`, while `sc doctor` reads `可用，5572 字节` because its separator lives inside the key `"{reason}, {size} bytes"` (`bin/sc:278`). Implemented exactly as designed, so this is a design item rather than drift (CR-5/RES-4); fixing it costs one key plus one zh entry, against a budget that landed at the +80 ceiling. | next task touching `cmd_status`'s rule-set section or T-20 |
| R-39 | **`_status_view()`'s docstring (`bin/sc:856-857`) repeats a false attribution**: it says `generate_config()` destructures the 3-tuple. It does not — it only passes `report` through; `_runtime_overlay()` (`:1815`), `usable_tags()` (`:905`) and `_warn_degraded()` (`:976`) are the three real sites. Found as F-14, answered as A-1, and **corrected in `docs/dev-map.md` at round 4′** because that line was already being edited; the docstring was left because the line was not otherwise edited and `bin/sc` was at the +80 ceiling (RES-5). | next task editing `_status_view()` |
| R-40 | **`_age_text()` renders `1 days ago`** — the ladder emits the largest unit only and pluralises like the existing `{n} ruleset(s)` keys, so a 36-hour-old file reads `1 days ago`. Deliberate per Q-11 (one deterministic vocabulary) and now observable in shipped output rather than hypothetical (RS-5/RES-6). A future task should add plural handling for every key at once rather than for this one. | unassigned |
| R-41 | **Operator obligation, not a code row.** AC-B9/P-6 — the shipped invocation form, run as root against the live unit — is the one promise T-19 did not close by a run, and it is the *only* observation of the goal's stated mechanism ("systemd records the run as failed"). The whole of the evidence is the unit-file read confirmed at the gate: `Type=oneshot`, one un-prefixed `ExecStart`, no `SuccessExitStatus=`, no `Restart=`. K-18 forbids it to every agent here, and QA reported it **BLOCKED rather than substituting the unit-file read** (the R-31 precedent, honoured). Recipe: trigger the unit once, then `systemctl show -p Result -p ExecMainStatus sing-box-rules-update.service`. Carries the standing **R-30** obligation with it — the change reaches the live host only when a human installs the new `bin/sc` and runs `sc reload`. | owner |

Unnumbered, all pre-existing or accepted: `HELP_EN` says `active node` where `README.md:245` says
`current node` (otherwise the two enumerations agree word for word — C-1 discharged); `cmd_update_rules()`
prints `Rule-sets restored:` while `CONTEXT.md` fixes **gained** as the term and lists "restored" under
`_Avoid_` (F-8 — FR-9 freezes that line, T-19 edited only its guard); two proposed `CONTEXT.md` glossary
entries, **rule-set age** and **run outcome**, defined in `01_RATIONALE.md`; and **RS-3/Q-9 accepted** —
`install.sh` step 6 branches on the exit status alone, so it now reports its ruleset-*download* warning
for a regeneration or restart cause.

### Open rows surfaced by T-06 (R-42 … R-47)

Filed by the PM at delivery; detail in `docs/features/_archived/sc-config-show/07_DELIVERY.md`.
**R-18 confirmed an eighth time** — `archive-task.sh` counts *bullets* (22) against 30 while F.4
counts *lines* (30), so it rotated nothing at the cap and the index was hand-rotated again.
**R-37 confirmed a second time** (rule 70 still defines no `## Stage-doc boundary rule`; stages 1
and 5 each recorded it). **R-4/R-9 unchanged** (`test_count: 0`, ten tasks running).

| id | row | owner |
|---|---|---|
| R-42 | **`parse_tuic()` has never stored a tuic link's password — a silent authentication failure, not a display defect.** `urlparse().username` stops at the first `:` in the userinfo, so `bin/sc:713`'s `if ":" in userinfo:` is structurally dead and `:724` writes `"password": ""` into **every** tuic outbound `sc` has ever emitted. Found by the developer while building a six-scheme fixture, confirmed independently at stage 5 and again by QA (the value never reaches disk). Correctly **not** fixed inside T-06 — the change is outside every C-row, touches `# Share-URL parsers`, and would alter what `generate_config()` emits, which out-of-scope 3 forbids. The highest-impact row this task produced. | next task touching the share-URL parsers |
| R-43 | **BC-13's third clause and K-14 cannot both hold.** A drift record that exists, is non-empty and is **not a digest** makes `sc config` print `This has drifted…`, while BC-13 says a record that is "empty, unreadable, or **not a digest**" is treated as BC-12 (no provenance line — absent means *unknown*, never *drifted*). Not a code defect and not fixable inside T-06: V-12 shows `_warn_drift()` at **HEAD** warns in exactly that state, so making `_drift_state()` return `None` here would change `_warn_drift()`'s observable behaviour and break K-14, which the gate made binding. Either BC-13 drops its third clause or K-14 is re-scoped. QA-1, MINOR. | requirement-analyst / architect, next task touching the drift quartet |
| R-44 | **Gate answer D-2's premise is false on CPython, and a number for it.** D-2 ruled no recursion guard was needed because "`json.loads` raises `RecursionError` before `_redact()` is reached". `json.loads` uses the **C scanner**, whose depth budget is not the Python recursion limit, so a ~1000-level-deep document parses fine and the pure-Python walk is what overflows — 27 lines of traceback out of `bin/sc:2719`, exit 1, stdout empty, **no credential byte in the traceback**. Depth 990 renders fine (1 988 974 B). Reachable only by a hand-edited or `override.json`-supplied document; nothing `sc` composes comes near. **No cap should be added on QA's say-so** — BC-10 and D-2 both argue against one. QA-2, MINOR. | architect, next task touching `_redact()` |
| R-45 | **The `BrokenPipeError` guard covers the stdout write only.** K-6 scoped it to the single write plus its flush, so the two-or-three stderr writes above it are unguarded and `sc config 2>&1 \| head -1` can still surface a Python-level error. BC-14 was worded for stdout alone (`sc config \| head -5`, fully handled), so the code is faithful and the gap is upstream. QA found it **milder than predicted**: five runs of five exit **120** (CPython's "failed to flush a standard stream at shutdown") with **no** traceback — nothing can be printed when the only stream left is the broken one. Widening the guard is machinery rule 85 does not fund for a case nobody has reported. CR-2/RES-6/QA-4. | architect, if the case is ever reported |
| R-46 | **`SECRET_KEYS` omits inbound TLS private-key material** (`key`, `certificate`, `key_path`) — the most likely *real* instance of the FR-9 limit both READMEs publish, and the same class as the READMEs' own `auth_token` example. `sc` never emits an inbound TLS key, so nothing shipped leaks, and QA confirmed the limit behaves exactly as documented (an inbound user's `auth_str` and an inbound's `tls.key` print verbatim while the sibling user's `password` is masked). Recorded so the boundary of Q-5's "floor, not the guarantee" is a **reviewed** decision rather than an unexamined one. CR-4, NIT. | requirement-analyst, at pool intake if revisited |
| R-47 | **Operator obligation, not a code row.** AC-B9 — the shipped invocation `sc config` run as root on the live host, printing the live configuration with every credential masked and the service untouched — is the one promise T-06 did not close by a run. No agent in this pipeline holds an interactive sudo credential (R-31), and running non-root would take the import-time re-exec into the **installed** `/usr/local/bin/sc`, so QA reported it **BLOCKED and did not substitute an artifact check** (the R-31/R-41 precedent, honoured a third time). The behavioural goal itself *was* observed by another route — AC-B1/AC-B2 against a six-scheme fixture, 10 == 10 positions. Carries the standing **R-30** obligation: the change reaches the live host only when a human installs the new `bin/sc`. | owner |

Unnumbered, all pre-existing or accepted: `sc config >&-` (stdout closed outright, not a
short-reading pipe) gives `AttributeError: 'NoneType' object has no attribute 'write'` and exit 1,
where `sc status >&-` exits 0 silently — `print()` returns quietly when `sys.stdout is None` while
`sys.stdout.write` does not; outside BC-14's wording and K-6's guard by design, no leak, no write
(QA-3). A `config.json` containing `NaN`/`Infinity` (a `json.loads` extension) is re-emitted
verbatim, so a *strict* parse fails while `jq` accepts it — masking unaffected, document faithful
to disk (QA-5). A credential whose value is the empty string still renders the mask, so an **unset**
credential is indistinguishable from a set one — FR-5 as written, a decision not an accident
(RES-5). The provenance line may describe a newer inode than the document printed if `sc reload`
lands mid-read; the document is still whole per BC-11 (RES-1). `json.loads` keeps the last of
duplicate keys, so a hand-edited file with a repeated key is shown without the earlier one (RES-2).
Neither the read nor the `ensure_ascii=False` write names an encoding, so a `C`/`POSIX`-locale host
at the 3.6 floor is affected in both directions — **measured**, not reasoned: a valid document
tagged `香港节点` gives `cannot read …: 'ascii' codec can't decode byte 0xe9`, exit 1, one sentence,
no traceback; a pre-existing repo-wide class (`load_nodes()`, `load_settings()`, `_load_lang()`,
`cmd_ls`), so no code was bought (RS-6/GC-7/RES-3).

### Open rows surfaced by T-20 (R-48 … R-52)

Filed by the PM at delivery. R-48 … R-50 are QA's DEF-1 … DEF-3, each reproduced independently at
stage 6 and each pre-recorded as a code-review residual; R-51 and R-52 are boundaries the pipeline
accepted deliberately. **R-32 and R-43 are closed by T-20** (the Clash row no longer asserts an
unobserved cause; BC-13's third clause gave way to T-06's K-14, so a present non-digest drift
record reads *drifted*). **R-10 closed, R-11 half-closed** — see the T-13 block above.

| id | statement | owner |
|---|---|---|
| R-48 | **The DNS row's probe warms the cache the next probe reads.** `GET /dns/query` is answered from *and populates* the install's own `experimental.cache_file`, so a fresh name costs 175 ms while the same name 3 s later costs **4 ms** with the authority TTL decremented (195 → 190 → 186; a negative answer is held 1800 s). Inside that window the row reports a cache hit rather than resolution through the tunnel — the fact it exists to establish is not established. The wording stays literally true, so this is a capability limit, not a lie. Fixing it needs a name no run warms, or a cache-bypass the Clash route does not offer. QA DEF-2, sharpening the reviewer's CR-3/RES-2. | next task touching `_doctor_dns` or the egress pair |
| R-49 | **A live Clash API on a host with no init system makes the node-delay row state a count it never read.** `is_running()` returns `False` from its **final line** without reaching `subprocess.run` when `SYSTEMD` and `OPENRC` are both false, so `stored_delays()` returns `({}, None)` and the row reads `0/{total}` though `/proxies` holds delays. This is BC-11's clause ("not running ⇒ UNKNOWN, no request") unhonoured in the one state BC-11 did not anticipate. Not fixable inside T-20: the guard lives in the frozen `stored_delays()`. No false `[OK]`, and the next step (`sc ls`) shows the same emptiness. QA DEF-1, widening RS-2/RES-4. | next task touching `stored_delays()` or `is_running()` |
| R-50 | **The AAAA membership test is position-blind.** `_aaaa_rule(suppress) in rules` passes wherever the rule sits, while **index 0** is what makes the suppression mode-independent (measured at HEAD: at index 3, types 64/65 are *not* suppressed in `direct` mode). A document from a pre-T-16 build, or one a user override reordered, reads `[OK] … config.json carries this decision` while the decision is not in force in `global`/`direct`. Not developer drift — FR-4 and I-6 both specify a membership test, so this needs a design decision. QA DEF-3 = CR-2/RES-1. | requirement-analyst / architect, next task touching the AAAA row |
| R-51 | **A group- or other-writable *sub-directory* is never judged.** BC-19 forbids descending, so a host on which anyone can plant a `.srs` into `/etc/sing-box/rules` still reads `[OK] file permissions`. Reproduced at stage 6. Accepted boundary — descending would cost the row its one-line healthy-host shape (NFR-3) — but unowned. Related and in the safe direction (CR-11): the check is now slightly *wider* than its sentence, so a stray non-credential file at 0644 is still reported. | unassigned |
| R-52 | **Operator obligation, not a code row.** AC-B14 — `sc doctor` run as root on the live host, printing the extended report and leaving the service witness unchanged — is the one promise T-20 did not close by a run: installing the candidate over `/usr/local/bin/sc` is forbidden, and no agent here holds an interactive root credential. QA reported it **BLOCKED and substituted nothing** (R-31/R-41/R-47, honoured a fourth time), and created `.harness/operator-obligations.md`, where it is **id 1**. Carries the standing **R-30** obligation with it. | owner |

### Rotated-but-open blocks — read them in `docs/tasks-archive.md`

Four blocks live in `docs/tasks-archive.md` § "Still-open rows rotated for space (NOT closed)".
**None is closed**; each was moved only to keep this board under its 300-line F.5 cap, and
completed rows were always rotated first.

- **T-02 follow-ups** and **"Carried to T-07"** — moved at T-19 delivery. A task touching the
  ruleset download path, the Python-floor sites, or T-07 must read them there.
- **T-08's remaining rows** — moved at T-06 delivery: T-07's inherited test-infrastructure
  defects, the `CURL_OPTS_*` dev-map seam row, and `baseline.json`'s `test_count: 0`
  (also tracked live as R-4/R-9).
- **T-11's R-1 … R-8** — moved at T-06 delivery. The `install.sh` `set -e` assignment-abort
  family, including the unguarded `mktemp -d` assignments. **T-07 is the task that must read them.**


## Conventions

- **ID** `T-NN` (sequential); **Slug** lowercase-kebab ≤40 chars; **Stage** one of `req`, `design`,
  `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`; **Doc folder** under
  `docs/features/<slug>/`, or `docs/features/_archived/<slug>/` once delivered.
- Starting a task: scan this board first — same module → read the prior `02_SOLUTION_DESIGN.md`;
  same feature → build on the prior design rather than redesigning; conflicting decisions → flag.
