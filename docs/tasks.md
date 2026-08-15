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
| T-25 | output-layer-contract | **DELIVERED — one contract, two homes, both already in the file; `bin/sc` +80/−41 of which the machinery share is one import and one guarded statement, and the batch's highest over-build risk did not materialise.** The **string layer**: a key *is* its own English rendering (the five `ls.*` keys became `#`/`On`/`Type`/`Name`/`Address`), carries its own field punctuation inside the translated string, and renders **one invariant form per count phrase** for every value — 14 members, byte counts in, `{n}/{total}` fractions out. The **stream layer**: one `io.TextIOWrapper(sys.stdout.buffer, encoding=sys.stdout.encoding, errors="backslashreplace", newline="\n", line_buffering=True)` at the top of `main()`, guarded on the stream having a binary buffer, buying write-order fidelity **and** unencodable-character survival together. FR-8 is not a third home — four `cmd_status` sites re-use the existing `_plain()`. **Nothing new was created**: no `en` table, no catalogue, no formatter, no plural engine, no second key per phrase, no print wrapper, no new file, no new function (top-level `def`/`class` count **113**, unchanged). **R-19, R-33, R-34, R-38 and R-40 CLOSED** — R-19 known since T-02 and deferred by every task since — and **T-23's BLOCKED-BY-T-25 clause discharged**. **Four dispatch claims refuted by first-hand re-verification**, three load-bearing: R-19's stated cause is wrong (in English *every* `t()` lookup is a designed miss and the key **is** the rendering, so no `en` table and no change to `t()` were needed); R-33 inverted **two** headings, not one, and `cmd_update_interval` had the identical shape; the T-23 hand-off was far wider than `cmd_add`'s one `→` (`sc ls` prints `●`/`→` on ordinary rows, so English `sc ls` was broken outright under a non-UTF-8 stdout); and the defect was **published** in `README.md:94` and `docs/dev-map.md:90-92`, which no row mentioned. **Rule 85 was tested, not accepted, and the smaller design won on its own merits**: the gate **re-priced the rejected flush route itself** and found no smaller construct exists on the 3.6 floor (`reconfigure()` is 3.7-only, `sys.stdout.errors` is read-only, `PYTHONIOENCODING` needs a re-exec), so once the re-wrap exists `line_buffering=True` costs **zero** additional lines — and it corrected the rejected route's site count **in that route's favour** (4 → 3) without changing the ruling. **One rollback, and no code defect at any stage**: the MAJOR was a *record* defect — C-6 discharged as "structurally unreachable" when it was conditional on `PYTHONIOENCODING` being unset **and** on `cmd_config`'s own locale-decode defect staying unfixed; the developer **confirmed the reviewer by measurement rather than deferring** (exit **0** with 269 ASCII bytes `json.loads` rejects, against HEAD's exit 1) and found it wider still. **R-22 honoured at three stages with two criteria reported NOT-DISCRIMINATING rather than passed** (AC-12's comparison clause named a `sc doctor` routing-mode rendering that does not exist — QA measured `grep -ci` = 0 on both builds; AC-13 was satisfiable by an empty screen), and QA reproduced the trap live: **HEAD's heading row satisfies `.isascii()`**. QA: **16/16 criteria, nothing BLOCKED** — the first delivery in this pool's recent history to append **no** operator obligation — 14 adversarial cases all survived, the sharpest being a **latin-1 stdout that can encode part of the data** (candidate prints `café-é` *and* an escaped `日本-jp` at exit 0 where HEAD aborts after row 1) and a **240 KB child** (candidate headings at lines 1/4003/8005 against HEAD's 8001/8003/8005 — the per-site `flush=True` route would not have survived it). **A safety near-miss was caught, voided and re-taken**: a hand-written loader re-exec'd the installed `/usr/local/bin/sc` under password-less `sudo`; caught before any write, run declared **void**, all five cases re-taken on the mandated recipe reproducing byte-for-byte, and the reviewer ruled it write-free on evidence *independent* of the harness's own witness (→ **R-78**). C-1 held as a real floor: **142 runs, 142 `[C-1] VERDICT OK`, 0 void**, and QA found a **second** hard-coded write path nobody had named (`cmd_update_interval`'s `/etc/systemd/system/…timer.d`). T-13 and T-06 intact: `_write_private()` still the sole writer of `config.json`, `sc config` still renders `_redact(doc, False)`, no credential path on the diff. `verify_all PASS 17 / WARN 0 / FAIL 0 / SKIP 1` at every checkpoint (QA re-ran it four times); `baseline.json` held at `test_count: 0`. Live host untouched: witnessed with `systemctl show -p MainPID -p ActiveEnterTimestamp`, `is-active` never called. | 2026-08-15 | `docs/features/_archived/output-layer-contract/` (mode: full) |

## Notes

### Open rows surfaced by T-14 (R-15 … R-18)

R-15/R-16 filed by the requirement-analyst at stage 1′; R-17 by the PM at delivery. **Three of the
four are closed** — R-15/R-16 by T-24, R-17 by T-23 — leaving only R-18, which T-27 owns.

1. **R-15 / R-16 — CLOSED 2026-08-15 by T-24**; **R-17 — CLOSED 2026-08-15 by T-23**, and its one
   stated limit (it closed the disk layer only; printing a non-ASCII tag under a non-UTF-8 locale
   still failed) is **CLOSED 2026-08-15 by T-25**. Row text and closure detail rotated to
   `docs/tasks-archive.md`.
2. **R-18 — `archive-task.sh`'s rotation is dead code; one-line cause known, owner assigned.**
   `archive-task.sh:89-94` counts **bullets** (`grep '^\s*-\s'`) against 30 while `verify_all` **F.4
   counts lines**, so the two differ by the file's header and the branch can never fire on any index
   with one. Confirmed **twelve times**, once per delivery, each paying a manual rotation. The file
   also carries a **local** fix (`:51-71`) that `/harness-upgrade` may silently revert — so durability
   of a local fix to a plugin-vendored script needs a ruling, not just the edit. **Owner: T-27.**

### Open rows surfaced by T-15 (R-19 … R-22)

Filed by the PM at delivery; R-19 was made a non-goal (D-13/NG-10), R-20 … R-22 are QA's DEF-1/3/4/5,
each routed here rather than back into T-15 because none was fixable inside that task's frozen set.

1. **R-19 — CLOSED 2026-08-15 by T-25**, after being known since T-02 and deferred by every task
   since. English `sc ls` now reads `#  On  Type  Name  Address  Delay`. **The row's stated cause
   was wrong**, and T-25's analyst refuted it first-hand: `t()` returning the key on a miss is not
   the defect — in English *every* lookup is a designed miss and the key **is** the rendering, so
   the defect is a key that is not its own English rendering. No `en` table and no change to `t()`
   were needed or made. Row text rotated to `docs/tasks-archive.md`.
2. **R-20 — CLOSED by T-18** (2026-08-14): one exception envelope at `clash_api()`, no caller-side guard; **wider than filed** — six escaping classes, not four. Row text rotated to `docs/tasks-archive.md`.
3. **R-21 — `RESERVED_TAGS` does not cover sing-box's implicit `GLOBAL` selector.** `bin/sc:56`
   reserves `proxy`/`direct`/`auto`, but the live `GET /proxies` returns a `GLOBAL` entry that is not
   an `sc` outbound at all. A node tagged exactly `GLOBAL` mints cleanly, the real checker accepts the
   document, and `sc ls` prints that entry's stored delay in the node's row (`9999 ms` in QA's
   reproducer). Narrow, no exception, table intact. The general statement is that
   `stored_delays()`'s map is keyed by the API's tags, not by `sc`'s nodes.
4. **R-22 — a practice, not work to close: an AC set that pins the artifact and never the behaviour
   will pass a gate it should fail.** Carried in every dispatch since; honoured by T-18, T-19, T-06,
   T-20, T-22, T-23, T-24 (four stages, six wrong builds killed) and **T-25**, which reported **two
   criteria NOT-DISCRIMINATING rather than passed** and reproduced the trap live: HEAD's `ls.idx …`
   heading row satisfies `.isascii()`, so a naive "is it English?" check passes on the broken build.
   Full row rotated to `docs/tasks-archive.md`.

### Open rows surfaced by T-16 (R-23 … R-27)

Filed by the PM at delivery; detail in `docs/features/_archived/dns-resilience/07_DELIVERY.md`. (R-18 confirmed a fourth time; index hand-rotated.)

| id | row | owner |
|---|---|---|
| R-23 | **A name whose only resolver is reached through a node stays unresolvable while that node accepts and never answers.** Not a defect — a measured capability gap: sing-box 1.13.15 has no DNS-query-level timeout at any level, no fall-through on failure, and `dns.final` is the no-match default, so no configuration this project emits can cover it. Re-pointing `final` to the domestic resolver was rejected on the merits (Q-17). Revisit only if a sing-box release adds a per-query bound or a real fallback transport; the probe deliberately established only that `timeout` is absent, not that no other key exists. | unassigned |
| R-24 | **`sc ipv6 <value>` says "Nothing changed" at the one moment the user is most likely to be sitting in a stale-document stall, and names no escape.** Both sides of the comparison come from the current host, never from the document on disk — which is correct (AC-6 forbids the second opinion). The escape exists (`sc reload`, or a value that flips the decision) but is never prompted. Note `sc ipv6 off` repairs it only in one direction. BC-13 now states the general rule; making the *line* name the repair needs its own design round. | next task touching `cmd_ipv6` |
| R-25 | **CLOSED 2026-08-15 by T-23** (with R-29, which superseded and widened it). Full row rotated to `docs/tasks-archive.md`. | **closed** — T-23 |
| R-26 | **CLOSED 2026-08-15 by T-24** at the zero-behavioural-cost gating it predicted: `generate_config()`'s three-key array guard now sets `OVERRIDE_PATH if override is not None else None`, so provenance is structural at all three sites and the docstring's and `docs/dev-map.md`'s claim is true rather than argued. **One refinement the row did not anticipate**: gating the assertion *alone* converts a mislabelled sentence into a traceback, so the gate and the envelope had to land together. | **closed** — T-24 |
| R-27 | **CLOSED 2026-08-15 by T-23.** Full row rotated to `docs/tasks-archive.md`. | **closed** — T-23 |

### Open rows surfaced by T-17 (R-28 … R-30)

Filed by the PM at delivery; detail in `docs/features/_archived/telemetry-reject-list/07_DELIVERY.md`.
(R-18 confirmed a fifth time.) R-16 was declined here a third time; **T-24 closed it**.

| id | row | owner |
|---|---|---|
| R-28 | **`TELEMETRY_NAMES` has no freshness owner.** A shipped name list ages: endpoints retire, vendors move collection, new dominant SDKs appear. T-17 deliberately adds no update path (a rule-set would be deleted by `_filter_rules()` on the degraded host that needs it), so the list is only ever revised by editing `bin/sc`. **The need is proven, not hypothetical**: one of the eighteen names stage 2 proposed did not resolve at all, and only C-3's first-hand check caught it. A task that re-runs a resolution check over the tuple would catch the next one in seconds. | unassigned |
| R-29 | **CLOSED 2026-08-15 by T-23 — and its own prescription was wrong in two ways**, both found by re-verifying rather than inheriting (the catch tuple missed `AttributeError`; the `"telemetry"` example answered wrongly instead of raising). Full row rotated to `docs/tasks-archive.md`. | **closed** — T-23 |
| R-30 | **Operator obligation, not a code row.** T-17's behaviour change reaches the owner's live host only when a human installs the new `bin/sc` and runs `sc reload` there — no agent on this project may touch `/usr/local/bin/` or the live service. Until then the running host keeps the pre-T-17 document. Stage 6 could not file this itself (`.harness/**` is outside the task's permitted diff) and routed it here. | owner |

### Open rows surfaced by T-18 (R-31 … R-35)

Filed by the PM at delivery; detail in `docs/features/_archived/status-egress-via-clash-api/07_DELIVERY.md`.
R-18 confirmed a sixth time; **R-20 closed** (above); stage 1's Q-5 was right, still undercounted, and
is **closed by T-23**; R-22(a) honoured and R-22(b) moot now that R-20 is fixed.

| id | row | owner |
|---|---|---|
| R-31 | **Operator obligation, not a code row.** AC-B1/AC-B2 — one run of `sudo python3 <repo>/bin/sc status` on this pure-TUN host, compared against an independent echo endpoint in the same minute — is the criterion R-22 exists to force, and it is the one promise T-18 did **not** close by a run. It blocked on `sudo -n true` → "a password is required" with no interactive terminal; running non-root would have taken the import-time re-exec into the **installed** `/usr/local/bin/sc`, so QA correctly did not attempt it. The behavioural goal itself was observed by another route (egress `38.47.117.142`, matching three echo endpoints, service witness unchanged), so what is owed is the shipped invocation form end to end as root. Recipe and witnesses in `07_DELIVERY.md`. | owner |
| R-32 | **`_doctor_clash()`'s PROBLEM message now names a cause it does not have.** `"no answer within the 3s timeout"` / 「3 秒超时内无响应」 (`bin/sc` key `:291`) now renders for BC-2 … BC-5 and BC-7 — states in which an answer *did* arrive well within the timeout. A pre-existing imprecision (HEAD already used it for a 4xx and for a refused connection) that T-18 widened to four more states. Deliberately not fixed: `sc doctor`'s wording was frozen by T-18's out-of-scope item 5 and BC-14. Code reviewer's CR-2 / RES-1. | T-20 |
| R-33 | **CLOSED 2026-08-15 by T-25**, and it was **wider than filed**: `cmd_status` runs *two* children (`systemctl`/`rc-service`, then `ip`), so two headings inverted rather than one, and `cmd_update_interval` had the identical shape. Both are inside the guarantee, plus `argparse`'s own stdout output, because the one stream statement sits before `parse_args()`. QA measured a **240 KB child**: candidate headings at lines 1/4003/8005 against HEAD's 8001/8003/8005 — the per-site `flush=True` route this row proposed would not have survived it. Full row rotated to `docs/tasks-archive.md`. | **closed** — T-25 |
| R-34 | **CLOSED 2026-08-15 by T-25 by narrowing the promise, as this row asked.** The falsifiable claim is replaced by the true one — `sc` adds no line of its own — and the criterion that measured it was reported **NOT-DISCRIMINATING** first (nothing asserted the section had printed at all; `is_running()` returns `False` off its final line when neither init system is set), then re-asserted with the section proved printed on candidate **and** HEAD. Full row rotated to `docs/tasks-archive.md`. | **closed** — T-25 |
| R-35 | **A number for R-23/R-3's family: `timeout=N` bounds each socket operation, not the call.** A peer dripping one body byte every 2 s keeps a `timeout=3` `urlopen` alive **30.1 s** and then returns success — measured, candidate and control alike, so not a T-18 defect. Any "it gives up after N seconds" claim about `clash_api()` or `_egress_ip()` is false as written. Attach to R-3's row when that failure class is next opened. | unassigned |

### Open rows surfaced by T-19 (R-36 … R-41)

Filed by the PM at delivery; detail in `docs/features/_archived/ruleset-staleness-visibility/07_DELIVERY.md`.
R-18 confirmed a seventh time. **R-12 narrowed, not closed** (Q-2): its two unwind paths already exit
non-zero with the cause on stderr before any service-affecting action, so the row is now about the missing
outcome *line* only — and **T-24 widened its population** (→ R-70…R-74 block). R-22 honoured; R-31's
discipline held — AC-B9 BLOCKED, never substituted (→ R-41).

| id | row | owner |
|---|---|---|
| R-36 | **AC-S3's ledger carve-out omits `docs/batches/**`.** QA-D2: `BATCH_PLAN.md` (M) and `BATCH_LOG.md` (??) are in neither of AC-S3's two lists, and the criterion says a path in neither list *is* a failure — yet both are the batch loop's, both predate stage 4, and neither was written by any T-19 stage. The candidate itself is clean; the criterion's text is what needs the third carve-out. Any future task reusing this AC template inherits the false failure. | next task writing an AC over the committed diff |
| R-37 | **`.harness/rules/70-doc-size.md` defines no `## Stage-doc boundary rule` on this project**, so units the PM's dispatch requires in a contract portion (rule 85's `## Smaller alternative rejected`, the FR/BC/AC coverage table, C-6's per-edit-id size table, C-2/C-3/C-4/C-5/C-8's evidence) fit no declared stage-doc shape. Recorded as a gap at stages 2 (E-20), 3, 5 (RES-10) and 6 (QA-D1) — **five stages in one task**, each carrying it as a named section rather than inventing one. Cheapest fix is one section in rule 70. | unassigned |
| R-38 | **CLOSED 2026-08-15 by T-25.** One separator convention: punctuation that joins the fields of one rendered line lives **inside** the translated string (`sc doctor`'s convention), and `sc status` adopted it. Cost was one new table entry; the English rendering is byte-identical to HEAD, so the change is exactly the Chinese `, `→`，`. Full row rotated to `docs/tasks-archive.md`. | **closed** — T-25 |
| R-39 | **`_status_view()`'s docstring (`bin/sc:856-857`) repeats a false attribution**: it says `generate_config()` destructures the 3-tuple. It does not — it only passes `report` through; `_runtime_overlay()` (`:1815`), `usable_tags()` (`:905`) and `_warn_degraded()` (`:976`) are the three real sites. Found as F-14, answered as A-1, and **corrected in `docs/dev-map.md` at round 4′** because that line was already being edited; the docstring was left because the line was not otherwise edited and `bin/sc` was at the +80 ceiling (RES-5). | next task editing `_status_view()` |
| R-40 | **CLOSED 2026-08-15 by T-25 for every count key at once**, exactly as this row demanded rather than for the one symptom: a population of **14** phrases, one invariant rendered form each (the `(s)` idiom already in-tree), byte counts **included** and `{n}/{total}` fractions correctly **excluded** — no plural-selection mechanism, no second key per phrase, no per-language rules. Full row rotated to `docs/tasks-archive.md`. | **closed** — T-25 |
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
| R-42 | **CLOSED 2026-08-15 by T-22 `share-url-userinfo-contract`.** The row was right about the defect and **understated its class**: the same missing judgment truncated trojan / hysteria2 passwords at a raw colon and double-decoded shadowsocks passwords recovered from base64, so the fix is one construct (`_userinfo`) consumed by five call sites rather than a tuic patch. Discharged with the tuic empty-password case measured red at HEAD on all five fixtures and green on the candidate through the **emitted document**. Two facts worth carrying: a real `sing-box check` **accepts** an empty tuic password (so no config-level test could ever have caught this), and already-stored nodes are **not** repaired by the fix — `sc rm` + `sc add` is required, filed as operator obligation **id 3**. | **closed** — T-22 |
| R-43 | **BC-13's third clause and K-14 cannot both hold.** A drift record that exists, is non-empty and is **not a digest** makes `sc config` print `This has drifted…`, while BC-13 says a record that is "empty, unreadable, or **not a digest**" is treated as BC-12 (no provenance line — absent means *unknown*, never *drifted*). Not a code defect and not fixable inside T-06: V-12 shows `_warn_drift()` at **HEAD** warns in exactly that state, so making `_drift_state()` return `None` here would change `_warn_drift()`'s observable behaviour and break K-14, which the gate made binding. Either BC-13 drops its third clause or K-14 is re-scoped. QA-1, MINOR. | requirement-analyst / architect, next task touching the drift quartet |
| R-44 | **Gate answer D-2's premise is false on CPython, and a number for it.** D-2 ruled no recursion guard was needed because "`json.loads` raises `RecursionError` before `_redact()` is reached". `json.loads` uses the **C scanner**, whose depth budget is not the Python recursion limit, so a ~1000-level-deep document parses fine and the pure-Python walk is what overflows — 27 lines of traceback out of `bin/sc:2719`, exit 1, stdout empty, **no credential byte in the traceback**. Depth 990 renders fine (1 988 974 B). Reachable only by a hand-edited or `override.json`-supplied document; nothing `sc` composes comes near. **No cap should be added on QA's say-so** — BC-10 and D-2 both argue against one. QA-2, MINOR. | architect, next task touching `_redact()` |
| R-45 | **The `BrokenPipeError` guard covers the stdout write only.** K-6 scoped it to the single write plus its flush, so the two-or-three stderr writes above it are unguarded and `sc config 2>&1 \| head -1` can still surface a Python-level error. BC-14 was worded for stdout alone (`sc config \| head -5`, fully handled), so the code is faithful and the gap is upstream. QA found it **milder than predicted**: five runs of five exit **120** (CPython's "failed to flush a standard stream at shutdown") with **no** traceback — nothing can be printed when the only stream left is the broken one. Widening the guard is machinery rule 85 does not fund for a case nobody has reported. CR-2/RES-6/QA-4. **Price updated 2026-08-15 by T-25 (RES-4): the row stays declined, but an un-guarded command at pipe-buffer scale now emits two extra `Exception ignored in: <_io.TextIOWrapper …>` stderr lines**, because two wrappers sit over one `BufferedWriter`. Reachable in no shipped consumer (`install.sh:567,590` and `restricted-network-regression.sh:283` all redirect; the timer unit has no pipeline), exit status and traceback unchanged, and `sc config`'s `os._exit(1)` unaffected (measured at 1 MB). Recorded so whoever next prices R-45 does not re-measure it. | architect, if the case is ever reported |
| R-46 | **`SECRET_KEYS` omits inbound TLS private-key material** (`key`, `certificate`, `key_path`) — the most likely *real* instance of the FR-9 limit both READMEs publish, and the same class as the READMEs' own `auth_token` example. `sc` never emits an inbound TLS key, so nothing shipped leaks, and QA confirmed the limit behaves exactly as documented (an inbound user's `auth_str` and an inbound's `tls.key` print verbatim while the sibling user's `password` is masked). Recorded so the boundary of Q-5's "floor, not the guarantee" is a **reviewed** decision rather than an unexamined one. CR-4, NIT. | requirement-analyst, at pool intake if revisited |
| R-47 | **Operator obligation, not a code row.** AC-B9 — the shipped invocation `sc config` run as root on the live host, printing the live configuration with every credential masked and the service untouched — is the one promise T-06 did not close by a run. No agent in this pipeline holds an interactive sudo credential (R-31), and running non-root would take the import-time re-exec into the **installed** `/usr/local/bin/sc`, so QA reported it **BLOCKED and did not substitute an artifact check** (the R-31/R-41 precedent, honoured a third time). The behavioural goal itself *was* observed by another route — AC-B1/AC-B2 against a six-scheme fixture, 10 == 10 positions. Carries the standing **R-30** obligation: the change reaches the live host only when a human installs the new `bin/sc`. | owner |

Unnumbered, all pre-existing or accepted: `sc config >&-` gives `AttributeError` + exit 1 where
`sc status >&-` exits 0 silently (`print()` returns quietly on a `None` stream; **T-25 confirmed
this is unchanged** — its stream statement is guarded on the stream having a binary buffer, QA-3);
`NaN`/`Infinity` is re-emitted verbatim, so a strict parse fails while `jq` accepts it (QA-5); an
empty-string credential still renders the mask, so unset and set are indistinguishable (RES-5); the
provenance line may describe a newer inode than the document printed (RES-1); duplicate keys keep
the last (RES-2). The unnamed-encoding item (RS-6/GC-7/RES-3) is **CLOSED for the state documents by
T-23**; `cmd_config`'s own reader keeps its locale decode — deliberate at T-23, now **R-76**.

### Open rows surfaced by T-20 (R-48 … R-52)

Filed by the PM at delivery. R-48 … R-50 are QA's DEF-1 … DEF-3, each reproduced independently at
stage 6; R-51 and R-52 are boundaries the pipeline accepted deliberately. **R-32 and R-43 closed by
T-20**; **R-10 closed, R-11 half-closed** — see the T-13 block above.

| id | statement | owner |
|---|---|---|
| R-48 | **The DNS row's probe warms the cache the next probe reads.** `GET /dns/query` is answered from *and populates* the install's own `experimental.cache_file`, so a fresh name costs 175 ms while the same name 3 s later costs **4 ms** with the authority TTL decremented (195 → 190 → 186; a negative answer is held 1800 s). Inside that window the row reports a cache hit rather than resolution through the tunnel — the fact it exists to establish is not established. The wording stays literally true, so this is a capability limit, not a lie. Fixing it needs a name no run warms, or a cache-bypass the Clash route does not offer. QA DEF-2, sharpening the reviewer's CR-3/RES-2. | next task touching `_doctor_dns` or the egress pair |
| R-49 | **A live Clash API on a host with no init system makes the node-delay row state a count it never read.** `is_running()` returns `False` from its **final line** without reaching `subprocess.run` when `SYSTEMD` and `OPENRC` are both false, so `stored_delays()` returns `({}, None)` and the row reads `0/{total}` though `/proxies` holds delays. This is BC-11's clause ("not running ⇒ UNKNOWN, no request") unhonoured in the one state BC-11 did not anticipate. Not fixable inside T-20: the guard lives in the frozen `stored_delays()`. No false `[OK]`, and the next step (`sc ls`) shows the same emptiness. QA DEF-1, widening RS-2/RES-4. | next task touching `stored_delays()` or `is_running()` |
| R-50 | **The AAAA membership test is position-blind.** `_aaaa_rule(suppress) in rules` passes wherever the rule sits, while **index 0** is what makes the suppression mode-independent (measured at HEAD: at index 3, types 64/65 are *not* suppressed in `direct` mode). A document from a pre-T-16 build, or one a user override reordered, reads `[OK] … config.json carries this decision` while the decision is not in force in `global`/`direct`. Not developer drift — FR-4 and I-6 both specify a membership test, so this needs a design decision. QA DEF-3 = CR-2/RES-1. | requirement-analyst / architect, next task touching the AAAA row |
| R-51 | **A group- or other-writable *sub-directory* is never judged.** BC-19 forbids descending, so a host on which anyone can plant a `.srs` into `/etc/sing-box/rules` still reads `[OK] file permissions`. Reproduced at stage 6. Accepted boundary — descending would cost the row its one-line healthy-host shape (NFR-3) — but unowned. Related and in the safe direction (CR-11): the check is now slightly *wider* than its sentence, so a stray non-credential file at 0644 is still reported. | unassigned |
| R-52 | **Operator obligation, not a code row.** AC-B14 — `sc doctor` run as root on the live host, printing the extended report and leaving the service witness unchanged — is the one promise T-20 did not close by a run: installing the candidate over `/usr/local/bin/sc` is forbidden, and no agent here holds an interactive root credential. QA reported it **BLOCKED and substituted nothing** (R-31/R-41/R-47, honoured a fourth time), and created `.harness/operator-obligations.md`, where it is **id 1**. Carries the standing **R-30** obligation with it. | owner |

### Rotated-but-open blocks — read them in `docs/tasks-archive.md`

Five blocks live in `docs/tasks-archive.md` § "Still-open rows rotated for space (NOT closed)".
**None is closed** — each moved only to keep this board under F.5's 300-line cap, completed rows first.

- **T-02 follow-ups** + **"Carried to T-07"** (moved at T-19 delivery) — largely discharged by T-07,
  which found the "846-assertion harness" and T-08's two inherited defects referenced files that
  **were never committed and no longer exist** (`.gitignore:19` ignores `test/`) and converted them
  into binding requirements. Of T-02's four unverified items only **BC-32** is closed, and only by
  construction; BC-25, the D-2 escalation and AC-26 on a real 3.6 interpreter stay open.
- **T-08's remaining rows** (moved at T-06 delivery) — the `CURL_OPTS_*` dev-map seam row is **CLOSED
  by T-07**; `baseline.json`'s `test_count: 0` stays open (R-4/R-9).
- **T-11's R-1 … R-8** (moved at T-06 delivery) — the `install.sh` `set -e` assignment-abort family.
  **Read by T-07 and deliberately not covered**: the restricted-network scenario reaches none of
  those call sites. All eight open and unclaimed.
- **T-13's R-9 … R-14** (moved at T-07 delivery) — **R-9, the committed `bin/sc` test harness, is the
  live one**; T-07 deliberately did not claim it but made it cheaper (a committed, runnable,
  git-tracked artifact that never imports `bin/sc` now exists to build from). **T-28 owns it.**
  R-10 closed, R-11 half-closed (T-20 block above).


### Open rows surfaced by T-21 (R-53 … R-55) — explore mode, so none is a code claim

| id | statement | owner |
|---|---|---|
| R-53 | **`RULESET_BASES`' four entries span three failure domains, not four.** Measured 2026-08-14: `cdn.jsdelivr.net` and `testingcf.jsdelivr.net` both answered from `104.17.207.5`/`104.17.208.5` — one Cloudflare edge — leaving Cloudflare (bases 1+2), `ghfast.top` (3) and Fastly (4). A *fifth* base does not help (GitHub Releases share base 4's Fastly IP); a one-entry data change to base 2 would. **No evidence it is needed** — 24/24 fetches succeeded — so this is an observation, not a proposal. | unassigned |
| R-54 | **CLOSED 2026-08-15 by T-24**, which took ownership after R-16's fifth decline and shipped the README obligation with the fix. The re-homing worked exactly as written: the next task that *needed* the vocabulary owned it. Full row rotated to `docs/tasks-archive.md`. | **closed** — T-24 |
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

### Open rows surfaced by T-22 (R-62 … R-63)

Filed by the PM at delivery; detail in `docs/features/_archived/share-url-userinfo-contract/`.
**R-42 is CLOSED above** by this task. **R-18 confirmed a tenth time** — `archive-task.sh` counts
*bullets* against 30 while F.4 counts *lines* (**T-27** owns the one-line fix); **R-37 an eleventh**,
recorded independently at stages 1, 3, 5 and 6. **R-4/R-9 unchanged** (`test_count: 0`; **T-28** owns
it and depends on this task's fix). **R-46 stays filed** — Q-5's re-open predicate is checkable and
did not fire.

| id | row | owner |
|---|---|---|
| R-62 | **CLOSED 2026-08-15 by T-23** on the population it named. All three writers it anchored now encode UTF-8 explicitly, and both write-failure renderers survive a non-encodable argument via `getattr(e, "strerror", None) or str(e)` — a bare `e.strerror` would have raised `AttributeError` **inside the error handler**, since `UnicodeEncodeError` carries none. Verified end to end: under a *proved* non-UTF-8 process the `p%C3%A9q` password lands on disk decoding to exactly `péq`. **R-62's own recipe was the correct one and the criteria that inherited it were not** — `PYTHONUTF8=0` is required, and dropping it (as T-23's round-1 criteria did) yields a fully UTF-8 process on Python 3.7+ in which HEAD passes unchanged. | **closed** — T-23 |
| R-63 | **A shipped docstring's truth rests on a coincidence no comment records.** `bin/sc:634` states `_userinfo` is the only site applying the userinfo rules to material taken from URI text. `:726`'s `body.rsplit("@", 1)` *does* apply the last-`@` rule to URI text, and the sentence survives only because CL-6 left that variable's sole consumer as `_b64dec` at `:729` — i.e. its product is a base64 candidate, never a field. A future change that gives `:726`'s value a second consumer would silently falsify a claim shipped in the file, and nothing in the file says so. Reviewer CR-4 (NIT), raised to a row because it is a **trap for the next editor** rather than a defect today. Fix is one clause in a comment, worth doing by whichever task next opens `parse_ss`. | next task touching `parse_ss` |

### Open rows surfaced by T-23 (R-64 … R-69)

Filed by the PM at delivery; detail in `docs/features/_archived/state-file-io-contract/`.
**R-17, R-25, R-27, R-29, R-62 CLOSED above.** R-18 confirmed a twelfth time (four lines hand-rotated;
**T-27** owns it) and R-37 a twelfth; R-16 was still open here after a fifth decline — **T-24 closed it**.

| id | row | owner |
|---|---|---|
| R-64 | **Two more commands act on the system *before* reading `settings.json`, and no boundary statement names them.** BC-13 and RT-5 name only `sc on` / `sc off`. `cmd_default_tun()` runs `systemctl enable/disable` before its `load_settings()` (`bin/sc:3232-3241`), and `cmd_update_interval()` writes `override.conf`, runs `daemon-reload` and restarts the timer (`:3388-3400`; OpenRC writes the periodic script at `:3431-3439`) before its own. Both therefore leave a standing system change and *then* abort per FR-6. The ordering is pre-existing and T-23 forbade reordering it by name, so **the statement is what must widen, not the code**. Reviewer CR-4 → RES-3. | next task touching `cmd_default_tun` / `cmd_update_interval`, or writing BC-13's successor |
| R-65 | **On an unusable `settings.json`, a regenerating run silently discards the user's stored choices and re-baselines the drift record.** Measured, not reasoned: `sc reload` exits **0** and writes a `config.json` that *adds* an NXDOMAIN block for 17 telemetry domains the user's stored `telemetry: allow` had turned off, flips `external_controller` from the recorded `127.0.0.1:29099` to a freshly probed `:29091` (BC-15), and records that digest as the new drift baseline. The only output is the one `⚠️` line, which names **neither** consequence. Fully authorised by T-23's FR-4/Q-2/BC-15 and safe under K-8 (no read-modify-write routes through the degrade — verified), but **stated by no boundary condition**, which is the R-22 shape again: a promise wider than the behaviour. Reviewer CR-5 → RES-4, QA DEF-2. | requirement-analyst, next task touching the degrade or the drift quartet |
| R-66 | **`save_settings()` is now the only authored document whose write failure is not rendered.** No `except`, so an `EROFS`/`ENOSPC`/read-only-`/etc/sing-box` write is a raw `PermissionError` traceback, and `Path.write_text` truncates, so "the previous document is intact" does not hold for it. **Reachable and measured** (seed-time on a fresh install), and **identical at HEAD**, so not a regression. T-23 declined it deliberately with a ground worth carrying: no value reaching it can fail a UTF-8 encode (every key but `update_interval` is a validated ASCII enum/boolean, and `update_interval`'s only non-ASCII path dies earlier at `bin/sc:3365`), and a guard would break `_resolve_clash_port()`'s deliberate swallow. RT-4 / QA DEF-3 / gate C-11. | unassigned |
| R-67 | **A criteria gap of exactly the shape the gate caught once and missed once.** T-23's FR-6 named eight commands that must abort on an unusable `settings.json`; seven were verified by run, and the eighth — `sc update-interval` — is **unreachable under the mandated fixture**, because `cmd_update_interval` is `if SYSTEMD: … elif OPENRC: …` and `SYSTEMD = OPENRC = False` takes neither arm, so it exits **0** having read nothing. Identical in shape to the `sc status` / `is_running()` trap the gate *did* catch (C-1). QA substituted nothing: reaching the systemd arm needs a live `daemon-reload` + `restart`. **Not a product defect** — the two `load_settings()` calls are unguarded and inside `main()`'s try, the same mechanism proven for the other seven. The lesson is the row: **a criterion over a command gated on `SYSTEMD`/`OPENRC` must name the exclusion the way C-1 does.** QA DEF-1. | requirement-analyst, T-28 and any task writing ACs over an init-system-gated command |
| R-68 | **Operator obligation, not a code row.** AC-21 — install the new `bin/sc`, `sudo sc add` a share URL carrying a non-ASCII password, `sc reload`, and confirm the real `sing-box check` accepts the regenerated document — is the one promise T-23 did not close by a run: it needs root and the **installed** `/usr/local/bin/sc` against the live service, and an un-neutralised import re-execs into it. QA reported it **BLOCKED and substituted nothing** (R-31/R-41/R-47/R-52/R-60 and obligation 3, honoured a **seventh** time) and filed it as **id 4** in `.harness/operator-obligations.md` with the recipe. Carries the standing **R-30** obligation: the change reaches the running host only when a human installs the new `bin/sc`. | owner |
| R-69 | **T-24 inherits a second consumer of `OverrideError`, and one line it must move rather than rewrite.** T-23 routes state-document failures through the *existing* envelope so `main()`'s arm serves 16 call sites with no new key and no second arm — the gate ruled this legitimate reuse rather than a mortgage, on the condition that `_unusable()` is the **single** construction site. So if T-24 renames or re-parents the class, `_unusable()` is the one line to move, and `main()`'s arm **must keep honouring `e.path`** and must not be narrowed back to the override. Related: `_load_override()` and `_read_state()` are deliberately **two** implementations of "is this JSON document usable?" — the override's stat-first, size-cap and whitespace-as-absent policies were **not** copied, and collapsing them is only safe if all three survive. RT-1 / RT-2. | **T-24** `override-error-envelope` |

### Open rows surfaced by T-24 (R-70 … R-74)

Filed by the PM at delivery; detail in `docs/features/_archived/override-error-envelope/`.
**R-15, R-16 and R-26 CLOSED** by this task (R-16 after four declines, README obligation shipped
with the fix); **R-44 deliberately not closed** (stage 6 measured the band empty, so no cap on
anyone's say-so); **R-69 discharged as constraints**; **R-12 not closed and now WIDER**. R-18 / R-37
confirmed a thirteenth time; **R-61 honoured** (the gate amended K-16 rather than approving a cap it
disbelieved); **R-22 honoured at four stages**, QA killing six wrong builds.

| id | row | owner |
|---|---|---|
| R-70 | **`sc reload` tracebacks on a host with no `sing-box`.** `bin/sc:2135`'s `subprocess.run([SB_BIN, "check", …])` carries no `shutil.which` guard where `cmd_doctor` does at `:2603`, so a missing binary raises `FileNotFoundError` from **outside** the new envelope — it sits below the region by design (Q-8 rejected widening the region to cover the checker). Confirmed by construction at three stages: every success-path fixture had to stub `subprocess.run`. Measured shape: `exit=1`, traceback, and on the malformed-override path the overwrite and the baselined digest still happen while the attribution to the checker does not. Gate F-14 / stage-4 boundary note / QA §RES-7. | next task touching `reload_or_restart()` or the checker call |
| R-71 | **No criterion in this project controls the no-echo property at runtime.** QA built `fault=str(e)` in place of `type(e).__name__` and it **survives all nine malformed members and every AC-2 clause**, rendering `('int' object has no attribute 'get')` — a value out of the user's document — onto the stream `install.sh` captures. BC-4 holds in the shipped file **by construction only**; six purpose-built carriers produced no actual echo, so the hazard is real but unrealised. A runtime carrier assertion is the missing control. QA-3, NOT-DISCRIMINATING rather than passed. Related: **QA-4** — C-5's "found as a `t()` key" is satisfied by a *partial* bare-literal build; the strengthened form is "no emission site is a bare literal". | **T-28** `committed-test-suite` |
| R-72 | **An existing error message echoes user-supplied JSON into the captured log.** `_anchor_index()` (`bin/sc:1400-1404`, zh key `:370-371`) renders `—— match：{anchor}` with `anchor = json.dumps(match, …)` — arbitrary user JSON, on stderr, into `/var/log/sing-box/install.log`. Pre-existing and **deliberately** left alone: BC-4 scopes its ban to sentences a task introduces or newly reaches, and T-24's envelope does not newly reach it. It is reachable from the READMEs' **own published** `$before`/`$after` recipe, whose zero-or-several failure both READMEs advertise. Twice a rollback cause here, because two drafts published a no-echo guarantee this sentence refutes. Analyst re-homed finding 1 / CR-8. | next task touching `_anchor_index` or the override error strings |
| R-73 | **The drift record is baselined onto a document the checker then rejects.** `_record_generated()` runs **before** `sing-box check`, so on any override that produces a checker-invalid document the record already reads as "what `sc` last wrote" while the service still runs the previous configuration. Measured at spawn time by QA (round 3) on `dns.servers` / `inbounds` / `outbounds`: the digest equals the sha256 of the just-written broken document before the checker is even spawned. Not a T-24 defect — T-24 stops the malformed shapes it owns *before* the write — but it is the general statement behind that clause, and it is what makes an unguarded-key failure destroy the working configuration rather than merely fail. Analyst re-homed finding 3. | next task touching `_record_generated()` / the reload ordering |
| R-74 | **A prose claim about a *measured* outcome went wrong five times in one task, always in the same direction.** CR-1, CR-3, CR-8, QA-1 and QA-6 were each a shipped sentence claiming slightly more than the code delivers — an unconditional silent-write claim, a universal fault-clause promise, a universal no-echo promise, an exit code measured under a stub, and a present-tense claim that a closed defect was open. **Every one was in prose; not one was in code.** The specific traps, worth carrying: a universal quantifier over a region must be enumerated against every sentence the region can produce *before* it is written; and a figure measured under a stub is a claim about the stub, not about the build. Not work — a practice, in the shape of R-22. | every stage that writes a user-facing or record sentence |

Unnumbered, accepted or already-owned: the `CHANGELOG.md` write-failure clause has an elided subject
though two internal markers scope it correctly (CR-8/RES-8, NIT); on the `[]` fixture HEAD produces
**two** silent accidents rather than the one C-2 predicted, since `"x" not in []` is `True` for both
accessors (QA DEF-4); and `docs/dev-map.md:52`'s three citations were **already stale at HEAD**.

### Open rows surfaced by T-25 (R-75 … R-79)

Filed by the PM at delivery; detail in `docs/features/_archived/output-layer-contract/`.
**R-19, R-33, R-34, R-38 and R-40 are CLOSED** by this task — R-19 after being known since T-02 and
deferred by every task since, and R-33/R-40 were each **wider than filed**. **T-23's BLOCKED-BY-T-25
clause is discharged** (and was far wider than `cmd_add`'s one `→`: `sc ls` prints `●`/`→` on ordinary
rows, so English `sc ls` was broken outright under a non-UTF-8 stdout). **R-45 stays declined**, but
its price rose: an un-guarded command at pipe-buffer scale now emits two extra `Exception ignored in:
<_io.TextIOWrapper …>` stderr lines, because two wrappers sit over one `BufferedWriter` — reachable
in no shipped consumer, exit status and traceback unchanged. R-18 confirmed a **fourteenth** time
(index hand-rotated again; **T-27** owns the one-line fix) and R-37 a **fourteenth**, recorded
independently at stages 1, 2, 3, 5 and 6. **R-22 honoured**, with two criteria reported
NOT-DISCRIMINATING rather than passed and the trap reproduced live (HEAD's `ls.idx …` heading row
satisfies `.isascii()`). `.harness/operator-obligations.md` row 4 step R-5 **marked closed in place**
(QA-4): `sc add` under a proved non-UTF-8 stdout now exits **0**. **Nothing was BLOCKED** — for the
first time in this pool's recent history no new operator obligation was appended.

| id | row | owner |
|---|---|---|
| R-75 | **The `失败：` diagnostic grep already matches two lines that do not mean "this rule-set file was not updated", and one of them collides in both languages.** `bin/sc:145` (`Error: applying timer failed: {err}` → `错误：应用 timer 失败：{err}`) carries **both** load-bearing literals — `failed: ` in English *and* `失败：` in Chinese — while `:136` (`Config check failed:` → `配置检查失败：`) carries only the Chinese one and is reachable into `install.log` through `sc update-rules` → config regeneration. Both pre-existing; T-25 touched neither and its own census was clean (104 forms/language, 0 hits), so this is the **family** statement rather than the one site the analyst first found. Reviewer CR-6 / RES-5 + analyst Q-17. | next task touching either sentence, or T-28 when it pins the grep |
| R-76 | **`cmd_config`'s `CFG_PATH.read_text()` is T-23's locale-decode defect in a third reader — and repairing it falsifies two published README sentences unless they are read at the same time.** `bin/sc:3113` has no `encoding=`, so under a non-UTF-8 locale `sc config` ends at the read with exit 1. That defect is currently the *only* thing keeping `sc config`'s escape path unreachable without an env var: with T-23's explicit UTF-8 decode applied, a CJK-tagged document decodes and then escapes on the way out at **exit 0**, measured. Both READMEs' `:297` sentences are already written for that post-repair world (T-25's CR-10 disposition, taken deliberately), so **the repair's duty is to verify them, not to change them**. Reviewer CR-1/CR-10 / RES-6. | next task touching `cmd_config`, or whoever completes T-23's reader family |
| R-77 | **The mandated fixture-loader recipe cannot load `bin/sc` under the one environment every locale criterion needs.** `docs/dev-map.md:136`'s bare `open("bin/sc").read()` decodes with the **locale** codec while CPython reads a script as UTF-8 (PEP 263), so `LC_ALL=C PYTHONUTF8=0` gives `UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 29`. T-25's QA added `encoding="utf-8"` in its own harness; the recipe should carry it, or the next locale test reads the failure as a harness bug. One keyword. QA-1. | next task touching the dev-map loader recipe, or T-28 |
| R-78 | **The loader row states its rule but not its failure signature, and the signature is what a fresh context actually sees.** `docs/dev-map.md:121-158` says "use this one, do not re-invent it"; a context that skips it does **not** get a loud "you imported the installed build" — it gets an argparse usage error about its own argv at exit 2, which reads like a bug in the harness. T-25 lost a round-4′ run to exactly this (re-exec into `/usr/local/bin/sc` under password-less `sudo`; caught before any write, run declared void, all five cases re-taken and reproducing byte-for-byte). One clause naming the signature. Reviewer RES-7. | next task touching the dev-map loader recipe |
| R-79 | **A cost clause states a loss that was never available to lose.** `docs/dev-map.md:78` records that `errors="backslashreplace"` displaces the POSIX locale's `surrogateescape`, so undecodable-byte data renders `\udcXX` instead of round-tripping. True against a *future* reader — but on **both** named instances HEAD aborts before reaching the line (`sc update-rules` at `↓`, `sc doctor` at `—`, measured under `LC_ALL=C PYTHONUTF8=0`), so the byte fidelity was never observable on the shipped build. The row should say the loss is prospective, or a reader will hunt a regression that never shipped. QA-5. | next task touching that dev-map row |

Unnumbered, folded here rather than numbered: **QA-2** — `04_DEVELOPMENT.md`'s K-6 resolution records
"16 static labels (9 ∪ 7)" where an independent enumeration finds **15** (9 sections ∪ **6** probe
labels), 18 with `DOCTOR_MARK`; all 18 are in the `zh` table, so AC-4's verdict is unaffected and only
the number is wrong. **QA-3** — a 28th `bin/sc` hunk (an `_age_text` docstring line) is named by no
`L-` row and no drift block; correct, non-executable, measured to change nothing.

## Conventions

- **ID** `T-NN` (sequential); **Slug** lowercase-kebab ≤40 chars; **Stage** one of `req`, `design`,
  `gate`, `dev`, `review`, `test`, `delivery`, `blocked`, `done`; **Doc folder** under
  `docs/features/<slug>/`, or `docs/features/_archived/<slug>/` once delivered.
- Starting a task: scan this board first — same module → read the prior `02_SOLUTION_DESIGN.md`;
  same feature → build on the prior design rather than redesigning; conflicting decisions → flag.
