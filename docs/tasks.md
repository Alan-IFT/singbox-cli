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
| T-18 | status-egress-via-clash-api | **DELIVERED** — **the batch goal's stated cause was a phantom, and refuting it was the largest saving.** Stage 1 established that `_egress_ip()` has no proxy argument in **any** commit of `bin/sc` back to `41ffd08` — it is one bare `urlopen("https://api.ipify.org", timeout=8)`, so in pure TUN the request is captured by the TUN device like any other and the probe reports the *proxied* address. There was no local-inbound assumption to fix; implementing the goal as written would have added a proxy path or a second address query for a defect that does not exist (the T-16 precedent, applied successfully). AC-S1 then **froze `_egress_ip()` byte-identical** so no downstream stage could "fix" the phantom, and stages 4/5/6 each verified the freeze independently by AST-extract + sha256 against a HEAD clone. The slug's own "via clash api" was declined too (Q-4): sing-box's Clash API reports no egress address, and consuming one would create the **second opinion** `docs/dev-map.md` pins `_egress_ip()` to prevent. What shipped is the goal's *second* clause at the seam it actually lives on: **`clash_api()` made total** — `except (OSError, ValueError, http.client.HTTPException)` plus one `isinstance(body, dict)` gate after the empty-body `{}`. **`bin/sc` +12/−6, no net import** (`urllib.error` deleted, `http.client` added), **no call site edited** — all five were already correct against the new contract, so one edit closes `sc status`, `sc ls`, `sc use`, `sc mode` and `sc doctor` together. **R-20 claimed and closed, and it was wider than filed: six escaping classes, not four.** Stage 4 found the fifth (`ConnectionResetError` — `do_open` wraps only `h.request()`'s `OSError` into `URLError` and bare-re-raises `h.getresponse()`'s) and stage 6 the sixth (`BadStatusLine`, neither an `OSError` nor a `ValueError`) — two of six leaves unknown to the pipeline until the last stage ran, which is the strongest possible argument for the family tuple over the leaf enumeration rule 85 made stage 2 justify. **Rule 85's burden of proof was met and then tested**: stage 2 named `except Exception` as the *smaller* rejected alternative and said what the extra line buys (a defect inside `clash_api()` would otherwise be reported as `[PROBLEM] Clash API responding` — `sc doctor` lying about the host to cover a bug in `sc`); stage 3 tested that against the **installed** stdlib and `README.md:268` and found the design **correct in code but wrong in published surface**, the same shape as T-17's finding (→ C-8). The gate also found three things neither upstream document caught: a **third vacuity trap** (`main()` reassigns `CLASH_PORT` as it does `LANG`, so a fixture without `clash_api_port` gets a port free *by construction* and the whole matrix silently degrades to "nothing listening" on candidate **and** control), two unenumerated call-site changes (`sc use` now regenerates+restarts, `sc mode` prints success), and a control that HEAD does not exhibit (`json.loads("null")` is `None`, making `null` an *agreement* state while `5`/`"x"`/`[1,2]` traceback). **1 rollback** (stage 5 → 4, documentation only: the changelog stated the `sc doctor` exit move as 2 → 1 for all five classes, but the non-object class previously printed a *lying* `[正常]` row and moves 0 → 1; the reviewer offered a waiver and the PM declined it, because rule 85's 「少就是多」 is explicitly about published surface). **T-05's DEF-2 closed on evidence, not argument** (C-3): at BC-1 the candidate yields exit 1 with the port row present, the HEAD control exit 2 with it lost. QA rebuilt its rig from scratch: **262 observations, 260 pass, 0 fail, 2 BLOCKED reported as blocked and never substituted** — AC-B1/AC-B2's live root run needs an interactive sudo credential the agent does not have (→ R-31). Non-vacuity proven across 204 fixture runs: runs talking to a port other than their own stand-in = 0, runs opening no Clash URL = 0, runs touching the live port = 0. The behavioural goal itself **was** observed — the candidate printed egress `38.47.117.142`, matching three independent echo endpoints, with route mode read back as `Rule`. `verify_all PASS 17 / WARN 0 / FAIL 0 / SKIP 1` — batch baseline preserved, never lowered, re-run by the PM at three checkpoints. Live service provably untouched (`MainPID=2566751` + `ActiveEnterTimestamp`, never `is-active`); `/usr/local/bin/sc` never invoked; only live traffic in the whole pipeline was two read-only `GET /configs`. Product diff 3 files, **+15/−7**. | 2026-08-14 | `docs/features/_archived/status-egress-via-clash-api/` (mode: full) |

## Notes

### Open rows surfaced by T-08 — owner to number

*(Items 1 and 2 resolved and rotated to `docs/tasks-archive.md` at T-17 delivery — closed by T-11 and by `verify_all` B.2 respectively; the rest renumbered.)*

1. **Two test-infrastructure defects inherited by T-07** with the harness: `gate_checks.sh` writes
   `faults.json` while `server.py` reads `control.json` (re-run as shipped it yields a false FAIL),
   and AC-3's non-vacuity is carried by the server **throttle**, not the fixture size, with no guard.
2. **`docs/dev-map.md` seam row** for `CURL_OPTS_QUIET`/`CURL_OPTS_PROGRESS` — belongs to T-07, which
   owns the next edit to these flags. Deliberately not added by T-08: dev-map is not in AC-19's
   carve-out, so editing it would have breached the criterion the gate made binding.
3. **`.harness/scripts/baseline.json` still reads `test_count: 0`** across all five delivered tasks —
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
**R-18 confirmed a sixth time** — the index was hand-rotated here again. **R-20 is closed** (above).
**R-29's family statement should name three readers, not two**: `load_nodes()` (called unguarded by
`cmd_status`) carries the same classes plus an absent-file case — found by T-18's stage 1 (Q-5) and
deliberately left out of scope. **R-22(a) was honoured** — AC-B1/AC-B2 were written to observe the
behaviour, and R-22(b) is moot now that R-20 is fixed.

| id | row | owner |
|---|---|---|
| R-31 | **Operator obligation, not a code row.** AC-B1/AC-B2 — one run of `sudo python3 <repo>/bin/sc status` on this pure-TUN host, compared against an independent echo endpoint in the same minute — is the criterion R-22 exists to force, and it is the one promise T-18 did **not** close by a run. It blocked on `sudo -n true` → "a password is required" with no interactive terminal; running non-root would have taken the import-time re-exec into the **installed** `/usr/local/bin/sc`, so QA correctly did not attempt it. The behavioural goal itself was observed by another route (egress `38.47.117.142`, matching three echo endpoints, service witness unchanged), so what is owed is the shipped invocation form end to end as root. Recipe and witnesses in `07_DELIVERY.md`. | owner |
| R-32 | **`_doctor_clash()`'s PROBLEM message now names a cause it does not have.** `"no answer within the 3s timeout"` / 「3 秒超时内无响应」 (`bin/sc` key `:291`) now renders for BC-2 … BC-5 and BC-7 — states in which an answer *did* arrive well within the timeout. A pre-existing imprecision (HEAD already used it for a 4xx and for a refused connection) that T-18 widened to four more states. Deliberately not fixed: `sc doctor`'s wording was frozen by T-18's out-of-scope item 5 and BC-14. Code reviewer's CR-2 / RES-1. | T-20 |
| R-33 | **`sc status > file` prints the `ip` output above the first heading.** `cmd_status`'s `print()` is block-buffered when stdout is a pipe while its `subprocess.run(["ip", …])` children write fd 1 immediately, so the sections come out reordered — in exactly the redirected bug-report case. Pre-existing and identical at HEAD (control run), so no regression, and no AC covered it. `_doctor_print()` already flushes per row for this same reason, so the fix shape exists in-tree. QA-D1, MAJOR. | next task touching `cmd_status` |
| R-34 | **"exactly one value line per heading" is falsifiable, and the promise is what needs narrowing.** A Clash API answering `{"mode":"rule\nINJECTED"}` yields two lines under `=== Route mode ===`, candidate and control alike. BC-12 declines a *size* cap, not an output-shape guarantee, so this is not covered by an existing ruling. The R-22 shape once more: a promise materially wider than the behaviour. QA-D2, MINOR. | next task writing ACs over `sc status` |
| R-35 | **A number for R-23/R-3's family: `timeout=N` bounds each socket operation, not the call.** A peer dripping one body byte every 2 s keeps a `timeout=3` `urlopen` alive **30.1 s** and then returns success — measured, candidate and control alike, so not a T-18 defect. Any "it gives up after N seconds" claim about `clash_api()` or `_egress_ip()` is false as written. Attach to R-3's row when that failure class is next opened. | unassigned |

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

- **ID** `T-NN` (sequential); **Slug** lowercase-kebab ≤40 chars; **Stage** one of `req`, `design`,
  `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`; **Doc folder** under
  `docs/features/<slug>/`, or `docs/features/_archived/<slug>/` once delivered.
- Starting a task: scan this board first — same module → read the prior `02_SOLUTION_DESIGN.md`;
  same feature → build on the prior design rather than redesigning; conflicting decisions → flag.
