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
| T-07 | restricted-network-regression-test | **DELIVERED — the project's first committed, runnable test artifact, and all four clauses of the goal sentence were refuted at stage 1** (the sixth consecutive pool row where that held, and again the largest saving). **The headline refutation inverts the very criterion T-07 exists to discharge**: T-01's AC-9 ("prints the failure banner, exits non-zero") is **false against current code** — with all four rule-sets missing, `generate_config()` deletes the empty `route.rule_set` (`bin/sc:2060-2061`) and filters **both** rule arrays (`:2062-2063`), so `sing-box check` passes, `PHASE_CONFIG=ok`, the service is already up, and `install_report()` takes its **success** arm: `✅ Install complete`, **exit 0**. A test written to AC-9 would have **failed on correct code**. Re-derived first-hand as six conditions E1…E6, and the gate re-walked all five links independently before approving. Also refuted: blocking `github.com`/`raw.githubusercontent.com` cannot reproduce the scenario (four shipped sources, **three** failure domains — two jsDelivr edges share one Cloudflare edge — so the blackout is **derived** from `RULESET_BASES` at run time, never hardcoded); "the full one-liner install" is impossible under its own premise (the one-liner fetches `install.sh` from the blocked host and `RAW_BASE` has no override), so the artifact drives the local-checkout branch with the coverage limit stated; and container is out, **VM only** (E1/E5 need systemd as PID 1 plus `/dev/net/tun`). **What shipped is one file** — `.harness/scripts/restricted-network-regression.sh`, 0755, beside `check-i18n-parity.sh`, the existing precedent for a git-tracked, unignored, Linux-only, no-`.ps1` project check — so `.gitignore` was untouched and dev-map's "no test directory" sentence stays true. **Zero product diff**: `install.sh`, `bin/sc`, `uninstall.sh` and `systemd/*` verified byte-identical to HEAD 6/6 against a `git clone` (never a worktree — GC-11) with a one-byte negative control. **The task was a vacuous-green hunt and found four more, each at a different stage, none by the stage that introduced it**: gate **F-1** (E1's `pair=` was a restatement, and E1's assertion is satisfied *identically by a healthy unrestricted install* → GC-1 swapped in the step-6 warning, which separates a *degraded* success from a healthy one); developer **D-3** (base 4 of `RULESET_BASES` is a byte-**suffix** of base 3, so the obvious substring test counts **4 on a log naming 3** — measured 4 vs 3, fixed with a per-entry boundary match, reproduced independently at QA); reviewer **CR-1**, the one rollback (BC-9's second clause implemented for E6 and forgotten for E3/E4, so on a no-egress VM both printed `PASS` with a `pair=` byte-identical to their own `obs=`); QA **D6-1** (`uncoverable()` accepts a **userinfo** authority, reporting "covered" for a base whose sunk name `u@cdn.example` is not the name any fetcher resolves). QA also **reproduced F-6 before trusting anything** — `--self-check` exits 0 on a three-base source, so exit 0 is not a guard, the printed list is — then compared the four printed URLs to `bin/sc:113-118` with an **independent** parser (`ast.literal_eval`, sharing no code with the artifact's `sed`+`grep`): byte-identical, with one-byte-edit and dropped-line negative controls. **A downstream stage refuted a reviewer's named fix and the reviewer withdrew it in writing**: CR-5's `[ "$p5" = "$prev5" ]` is a **tautology at both loop exits** (the loop body's tail is `prev5="$p5"`), measured on the very crash-loop state it was meant to catch; stage 4 shipped the working equivalent (an `agree` flag set at the break) and **kept a dead service reporting FAIL rather than BLOCKED** — a product failure must not be laundered into a harness excuse. **Rule 85 was tested twice and the *cap* was what failed**: the gate wrote F-11 saying the 250-line cap had no margin and K-10's "≤235 target" was not credible, then approved K-10 unchanged; stage 5 spent the burden of proof region by region and judged the 330-line result **earned** — recoverable surplus ~15-20 lines against a binding floor of **267** (239 code at zero comments/blanks + the 28-line operator guide GC-9 forbids trimming) — so no refactor was demanded and nothing was dropped to make a number. What the design *did* avoid is the thing rule 85 aimed at: no framework, no fixture library, no mock server, no fault-injection matrix, no runner, **no second file and no new directory** (this project had already thrown away five harnesses). **The BLOCKED discipline held a fifth time, and at its largest: eight criteria, not one.** AC-6…AC-13 and AC-20's VM half are `BLOCKED` with reasons and a named recipe — `.harness/operator-obligations.md` **row 2** (R-1…R-6 plus the three RES-4 readings) — and **no artifact inspection was substituted for any of them** (R-31/R-41/R-47/R-52 precedent); the three unit-level rows are explicitly labelled *partly discharged at unit level, condition still BLOCKED*. **1 rollback** (5 → 4, CR-1). QA: **63 host observations, 12 PASS / 0 FAIL / 9 BLOCKED**, 10/10 byte-identical stability signatures, every fixture built from the AC table rather than stage 4's transcripts. Nothing on this host was mutated: `install.sh` never ran, `/usr/local/bin/sc` never invoked, `bin/sc` never imported, `/etc/hosts`/`nsswitch.conf`/`resolv.conf` unchanged, live-service witness (`MainPID=2566751` + `ActiveEnterTimestamp`) identical at all 12 sample points, `is-active` never invoked. `baseline.json` held at `test_count: 0` (R-4/R-9 keep it — no assertion can run here). `verify_all PASS 17 / WARN 0 / FAIL 0 / SKIP 1` at five PM checkpoints. Diff 5 files, **+355/−0**. | 2026-08-15 | `docs/features/_archived/restricted-network-regression-test/` (mode: full) |

## Notes

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

Five blocks live in `docs/tasks-archive.md` § "Still-open rows rotated for space (NOT closed)".
**None is closed**; each was moved only to keep this board under its 300-line F.5 cap, and
completed rows were always rotated first.

- **T-02 follow-ups** and **"Carried to T-07"** — moved at T-19 delivery. **Now largely discharged
  or ruled on by T-07**: the "846-assertion harness" and T-08's two inherited defects were found to
  reference files that **were never committed and no longer exist** (`.gitignore:19` ignores `test/`
  wholesale), so T-07 converted them into binding requirements instead of carrying them as
  unfixable TODOs; of T-02's four unverified items only **BC-32** is closed (by E3, and closed
  *by construction of the test* — closed in fact only when a `[VM]` run reports `E3 PASS`).
  BC-25, the D-2 escalation and AC-26 on a real 3.6 interpreter stay open there.
- **T-08's remaining rows** — moved at T-06 delivery. **The `CURL_OPTS_*` dev-map seam row is
  CLOSED by T-07** (`docs/dev-map.md`, one `## Reusable utilities` row naming the flag policy block
  and the three facts that make it a seam). `baseline.json`'s `test_count: 0` stays open (R-4/R-9).
- **T-11's R-1 … R-8** — moved at T-06 delivery. The `install.sh` `set -e` assignment-abort
  family, including the unguarded `mktemp -d` assignments. **Read by T-07 and deliberately not
  covered** — the restricted-network scenario reaches none of those call sites, so covering them
  would need faults the scenario does not inject. All eight stay open and unclaimed.
- **T-13's R-9 … R-14** — moved at T-07 delivery. **R-9 (the committed `bin/sc` test harness) is the
  live one and T-07 deliberately did not claim it**, leaving it the `verify_all` wiring, the `.ps1`
  mirror, `baseline.json`/R-4 and defusing the import-time auto-elevate — but T-07 makes it
  **cheaper**, since a committed, runnable, git-tracked test artifact that never imports `bin/sc`
  now exists to build from. R-10 closed, R-11 half-closed (T-20 block above).


### Open rows surfaced by T-21 (R-53 … R-55) — explore mode, so none is a code claim

| id | statement | owner |
|---|---|---|
| R-53 | **`RULESET_BASES`' four entries span three failure domains, not four.** Measured 2026-08-14: `cdn.jsdelivr.net` and `testingcf.jsdelivr.net` both answered from `104.17.207.5`/`104.17.208.5` — one Cloudflare edge — leaving Cloudflare (bases 1+2), `ghfast.top` (3) and Fastly (4). A *fifth* base does not help (GitHub Releases share base 4's Fastly IP); a one-entry data change to base 2 would. **No evidence it is needed** — 24/24 fetches succeeded — so this is an observation, not a proposal. | unassigned |
| R-54 | **R-16 re-homed: T-21 formally declines ownership.** R-16 (the merge has no type-mismatch vocabulary — a bare object silently replaces an array) named T-15/T-16/T-17/T-21 as candidate owners. T-15…T-17 have all shipped without needing it, and T-21 is an `explore` task that ships **no code**, so it cannot claim it. R-16 stays **open and unclaimed**; the next task that needs the vocabulary owns it, and it still carries the README obligation with the fix. | next task needing the array/object merge vocabulary |
| R-55 | **Two sentences the README owes users, both established by measurement.** (1) Rule-set downloads follow the *host's* routing — tunnelled on a running host (`rule=final` -> `proxy`, observed) and direct at install time (`install.sh:567` precedes `systemctl start` at `:593`) — so there is nothing to configure, and a `direct` default would re-create this batch's founding failure. (2) An alternate rule source is expressible **today** as a `type: remote` entry in `override.json` (verified against sing-box 1.13.15), with the caveat that such rule-sets live in `cache_file` and therefore sit outside `sc`'s validity, age and `doctor` reporting. | next task touching the README rule-set section |

### Open rows surfaced by T-07 (R-56 … R-61)

Filed by the PM at delivery. R-56 … R-58 are QA's D6-1 … D6-4, each reproduced at stage 6 with a
named one-line fix; R-59 is the code reviewer's CR-13; R-60 and R-61 are boundaries the pipeline
accepted deliberately. **R-18 confirmed a ninth time** and the index hand-rotated again (three lines
to `insight-history.md` before the harvest, per GC-8 — `archive-task.sh` counts **bullets** where
F.4 counts **lines**, so its rotation branch cannot fire on any index with a header). **R-37
confirmed a seventh time**, recorded at stages 1, 2, 3, 5 and 6 of this task alone.
**R-4/R-9 unchanged** (`test_count: 0`, twelve tasks running) — see the T-13 pointer above.

| id | statement | owner |
|---|---|---|
| R-56 | **`uncoverable()` reports "covered" for an authority `/etc/hosts` cannot map.** The predicate (`restricted-network-regression.sh:92`) rejects an empty host, `localhost`, an IP literal and a port-bearing authority but **accepts a userinfo one**: a base `https://u@cdn.example/geo` yields `SELF-CHECK OK: 1 shipped base(s), all covered`, exit 0, while the name it would sink is `u@cdn.example` and `urllib.parse` gives `hostname = cdn.example`. I-7 designates this predicate the single home of FR-3 coverage and BC-2, so the one guard the design has reports coverage for a base it cannot cover. Unreachable with the four bases at HEAD, and on a VM the I-9 resolver proof fails closed to `UNMET` — hence MINOR, not MAJOR. Fix is one `\|*@*` alternative in the `case`. QA D6-1. | next task touching the artifact, or R-9 |
| R-57 | **Two `--source`-only derivation defects, both harmless at HEAD.** (a) The `sed` range `/^RULESET_BASES = (/,/^)/` never closes on a source whose closing `)` is **indented**, so sed runs to EOF and the derivation adopts unrelated URLs (observed: two bases, one of them `https://sneaky.example/geo`, `SELF-CHECK OK`). (b) `grep -oE 'https?://[^"]+'` overruns a **single-quoted** entry, yielding `https://single.example/geo',` — the host survives (`host_of` cuts at the first `/`) so the blackout would still be right, but E3's per-entry `failed: <base> -> ` match could never fire for that base. `bin/sc:118` is a bare `)` with double-quoted entries, so neither is reachable through the default source. QA D6-2/D6-3. | unassigned |
| R-58 | **The comment asserting the file has no CJK is the file's only CJK.** `restricted-network-regression.sh:31` reads *"…no string of this file can collide with `bin/sc`'s load-bearing `失败：` grep"* — and is the single line below the guide block matching `[\x{4E00}-\x{9FFF}]`. Harmless in fact (a comment never enters any stream `bin/sc` greps), but it makes **I-15's** "it is the only Chinese in the file" and `05_CODE_REVIEW.md`'s design-fidelity row *"everything below `:30` English"* both false as written. Fix is to reword the comment, not the code. Deliberately not fixed at delivery: it would have required a fourth stage-4 round plus re-review for a NIT, and the counter-rule in rule 85 forbids widening scope for it. QA D6-4. | next task touching the artifact |
| R-59 | **`rblock` is evaluated before E3's and E4's own verdicts, so a product failure reads as a harness excuse.** On a no-egress VM (`nok=0`), E3 and E4 report `BLOCKED` even where their own blackout-arm observation is already falsified — including the `E3 FAIL` that **BC-10 mandates in so many words** for the "log not writable" form, and a genuine E4 failure (`mode=644`, unparsable document, `sing-box check` non-zero). Never a false green (`finish` exits non-zero on any non-PASS), so MINOR. **E5 already carries the correct shape** (`[ "$st" = PASS ] && [ "$agree" -eq 0 ]`); mirroring it at E3/E4 is one line each. This is the exact inverse of the CR-1 defect the task rolled back for, and it is a real collision between K-11's unconditional letter and BC-10 — so it needs a requirement ruling, not just a code edit. Reviewer CR-13; carried to the operator as obligation row 2 reading (b). | requirement-analyst / next task touching the artifact |
| R-60 | **Operator obligation, not a code row — and the largest instance of it this project has filed.** Eight criteria (AC-6 … AC-13) plus AC-20's VM half need root on a **disposable systemd VM** with `/dev/net/tun`, because the scenario runs `install.sh` and writes `/etc/hosts`, `/etc/sing-box`, `/var/log/sing-box` and systemd units. No container or VM runtime is usable in this pool (`docker` needs sudo; `podman`/`systemd-nspawn`/`qemu-system-x86_64`/`vagrant` absent; LXD uninitialised — installing the snap was ruled out of scope; `bwrap --unshare-net` EPERMs on loopback setup), no agent holds an interactive sudo credential, and the artifact **refuses on this host by design** at K-3 gate 2. QA reported all eight **BLOCKED and substituted nothing** (R-31/R-41/R-47/R-52, honoured a fifth time) and wrote the full recipe into `.harness/operator-obligations.md` as **id 2** (R-1…R-6), including the three readings the first transcript must be checked against. Until it is run, T-01's AC-9 and T-02's `install.log` capture remain unverified **by a run** — but are now verifiable by one command. | owner |
| R-61 | **A line cap set as a round number, approved after being declared not credible.** The NFR capped the artifact at 250 lines; the gate wrote **F-11** saying the cap had no margin and K-10's "target ≤235" was not credible — **and then approved K-10 unchanged**. It shipped at 330 against a measured binding floor of **267** (239 code at zero comments and zero blanks + the 28-line operator guide GC-9 forbids trimming), so the cap was unreachable by construction and every downstream stage had to spend a round adjudicating it. Rule 85's burden of proof still worked (the overrun was tested region by region and judged earned, recoverable surplus ~15-20 lines, no refactor demanded, nothing dropped to make a number) — the defect is the cap's **provenance**. Any future artifact of this class should be capped **from its own element list**, not from a round number, and a gate that finds a cap incredible should amend it rather than approve it. Reviewer RES-5. Related, unnumbered: **CR-7** — E4's five clauses cannot distinguish a correctly degraded config from one that defines nothing, which is FR-7/V-15 as written and so an upstream gap, constrained in practice by E1/E5 and E4's `pair=`; **CR-14/CR-15** NITs; and QA's fourth owed reading — E3's `nfail -eq 4` is an exact equality over the **whole** append-only `install.log`, so any second `failed:` line from an unrelated `sc` run makes E3 `FAIL` (fail-closed, but expect it on a re-used host). | architect, next task writing a size cap |

## Conventions

- **ID** `T-NN` (sequential); **Slug** lowercase-kebab ≤40 chars; **Stage** one of `req`, `design`,
  `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`; **Doc folder** under
  `docs/features/<slug>/`, or `docs/features/_archived/<slug>/` once delivered.
- Starting a task: scan this board first — same module → read the prior `02_SOLUTION_DESIGN.md`;
  same feature → build on the prior design rather than redesigning; conflicting decisions → flag.
