# PM Log — config-degrade-missing-rulesets (T-02)

Mode: **full** (stages 1-7). Dispatched under a stream: `deferred-human mode: defer, do not ask`.

## Pre-flight (2026-07-31)

- `.harness/intervention.md` — checked, **absent**. No pending intervention.
- `.harness/agents/dev-*.md` — none found → **single Developer mode** (`harness-kit:developer`).
- `docs/tasks.md` — related historical work: **T-01 `install-enable-start-split`** (DELIVERED
  2026-07-31), which touched `install.sh` and depends on `sc update-rules` failure-cause output.
  T-02 is explicitly forbidden from touching `install.sh`.
- `.harness/insight-index.md` — read. Two entries surfaced to downstream dispatches:
  - `sc update-rules` prints the actual failure cause on **stdout**; stderr carries only the count.
    `install.sh` captures both into `/var/log/sing-box/install.log` and T-01's failure reporting
    depends on the cause staying visible on stdout.
  - A translation key present in only one language aborts `install.sh`'s `t()` under `set -u`.
    `bin/sc` has a *different* `t()` (`TRANSLATIONS` with English-key fallback) — downstream must
    verify actual behaviour rather than assume.
- `docs/dev-map.md` — read; currently a template with no entries for `bin/sc`. Developer should
  populate it if structure knowledge is added.
- `.harness/rules/85-design-discipline.md` — read. This task is a deliberate **consolidation** of
  three former rows around one abstraction ("is this ruleset usable?"). Rule 85 test 2
  (duplicated judgment) names T-02/T-03 as its own precedent.

## Stage transitions

| # | Stage | Agent | Verdict | Timestamp |
|---|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | **READY** — advance | 2026-07-31 |
| 2 | Solution design | solution-architect | **READY** — advance | 2026-07-31 |
| 3 | Gate review | gate-reviewer | **APPROVED FOR DEVELOPMENT** (9 WARN conditions) — advance | 2026-07-31 |
| 4 | Development | harness-kit:developer | **READY FOR REVIEW** — advance | 2026-07-31 |
| 5 | Code review | code-reviewer | **APPROVED** (0 CRITICAL / 0 MAJOR / 6 MINOR / 8 NIT) — advance | 2026-07-31 |
| 6 | QA test | harness-kit:qa-tester | **ROLLBACK: developer** — D-1 MAJOR | 2026-07-31 |
| 6a | Design amendment | solution-architect | **READY** (Amendment A-1) — advance | 2026-07-31 |
| 6b | Development (fix) | harness-kit:developer | **READY FOR REVIEW** — advance | 2026-07-31 |
| 6c | Code review (delta) | code-reviewer | **APPROVED** (0 CRIT / 0 MAJ / 1 MINOR / 2 NIT) | 2026-07-31 |
| 6d | Design amendment A-2 | solution-architect | **READY** (A-2) — advance | 2026-07-31 |
| 6e | Development (A-2) | harness-kit:developer | **READY FOR REVIEW** — advance | 2026-07-31 |
| 6f | QA re-test | harness-kit:qa-tester | **PASS** — 846/846, 0 failed | 2026-07-31 |
| 7 | Delivery | PM | **DELIVERED** | 2026-07-31 |

### Stage 1 → 2 decision

`01_REQUIREMENT_ANALYSIS.md` returned **READY**: 26 behaviors, 32 boundary conditions, 27 ACs,
9 open questions each with a labelled recommended resolution. **Advance.** Intervention file
re-checked after the stage — absent.

Four analyst findings routed into the architect's dispatch as must-address items:

1. `dns.rules` (`bin/sc:497,498,501`) *also* references rule-set tags — the brief only named
   `route.rules`. A dangling DNS reference is equally invalid.
2. `cmd_update_rules` (`bin/sc:822-825`) restarts but never **regenerates** the config, so the
   promised "补齐后执行 `sc update-rules` … 自动恢复" is currently false.
3. The `~512` byte floor may exceed the real size of `geosite-private.srs` → would permanently
   reject a good file. Analyst recommends 16 bytes + a Content-Length equality check.
4. 4 mirrors × 4 files × `timeout=30` ≈ 8 min worst case without changing any timeout constant —
   obeys the letter of the no-timeout-change rule while violating its intent. Analyst adds
   "a base that fails once is skipped for the rest of the run".

None of the 9 open questions is a red line or an irreversible/uncovered call under
`.harness/rules/25-decision-policy.md`; all are technical judgments owned by the architect and
gate reviewer. **No human escalation raised.** Q1 in particular stays inside the brief's own
latitude — the brief wrote "~512 bytes" with a tilde, i.e. "a sane floor", not a fixed constant.

**Q9 follow-up owned by PM (not folded into T-02):** pre-existing Python-floor violations —
`capture_output=` (3.7+) at `bin/sc:553,857` contradict the documented 3.6+ floor. Recorded in
`docs/tasks.md` Notes as a new pool row rather than absorbed here; T-02 fixes only the one site
inside the loop it already rewrites (`unlink(missing_ok=)` at `:819`).
**Corrected at stage 3:** the gate reviewer found a **third** site, `bin/sc:595` (`is_running()`,
OpenRC branch). The follow-up row must name three sites — `:553`, `:595`, `:857`.

### Stage 2 → 3 decision

`02_SOLUTION_DESIGN.md` returned **READY** and did not roll back stage 1. **Advance.** Intervention
file re-checked — absent. The design resolved all four PM-routed findings: one `usable` set feeding
both `dns.rules` and `route.rules` through a single `_filter_rules`; `cmd_update_rules` regenerating
the config on a gain so the recovery promise becomes true; floor 16 bytes + Content-Length equality
(analyst recommendation adopted, 512 declined); per-run dead-base marking to hold the time budget
flat with no timeout constant touched. Architect recorded three declines in
`.harness/rejected-decisions.md` and flagged a second pre-existing defect (`bin/sc:642`,
`t('ls.idx')` renders the key because `TRANSLATIONS` has no `en` table) as a further pool row.

### Stage 3 → 4 decision

`03_GATE_REVIEW.md` verdict: **APPROVED FOR DEVELOPMENT**, no rollback. **Advance to stage 4.**
Intervention file re-checked — absent. The stage gate is satisfied (explicit PASS-equivalent verdict).

*Persistence note:* the gate-reviewer agent ran without write tools, so the PM persisted its
returned document verbatim to `03_GATE_REVIEW.md`. This is mechanical persistence, not authoring —
no PM edits to the content. Recorded here because it deviates from the normal stage mechanics.

Nine WARN conditions were attached to the approval and carried into the developer dispatch:
F-1 accumulate the SRS magic across chunks · F-2 `{names}` renders as `tag (status phrase)` ·
F-3 harness must neutralise `systemctl`/`rc-service` · F-4 defensive `Content-Length` parse ·
F-5 unparseable temp suffix counts as stale · F-6 no `Accept-Encoding` header · F-7 bases 2-4
unvalidated against reality · F-8 double restart on `install.sh` re-run is expected · F-9 AC-25
is evaluated against the *product* diff only.

### Stage 4 → 5 decision

Developer returned **READY FOR REVIEW**. **Stage gate satisfied**: `verify_all` reports
`PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, exit 0, delta 0 against baseline — no FAIL, so stage 5
may proceed. Intervention file re-checked — absent. Nothing committed; tree left dirty per owner.

Product diff: `bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md` (matches design §2).
Also updated `docs/dev-map.md` (was an unfilled template; now describes `bin/sc`'s section map).

Three gate-review residual risks were **closed by the developer**, not deferred — network turned
out to be available on this box:
- F-7: all four mirror bases fetch identically → the base URLs are real, not just well-formed.
- AC-27: the smallest real rule-set is `geosite-private.srs` at **696 bytes**, so the 16-byte floor
  stands and the 512-byte floor the brief proposed would *not* have rejected it after all. The
  measurement was the binding condition; it has now been taken.
- R2/AC-7: real `sing-box` 1.13.15 `check` accepts all 16 usable/unusable subsets, including the
  all-dropped case.

Carried into stage 5 for independent judgment (PM does not rule on these):
- Two self-declared **DESIGN DRIFT** items — a 3-line `_temp_path()` helper, and building
  `route.rule_set` from `report` rather than re-deriving from `RULESET_FILES`.
- `http.client.HTTPResponse.read(n)` blocks until it has `n` bytes, so a body under 64 KiB yields
  exactly one redraw. Routed to QA as a fixture constraint for AC-16, not as a code defect.
- Line numbers in the upstream docs have shifted (`capture_output=` now at `:822`, `:864`, `:1159`).

### Stage 5 → 6 decision

Code review verdict **APPROVED**: 0 CRITICAL, 0 MAJOR, 6 MINOR, 8 NIT — both axes clear at MINOR.
**Advance to stage 6.** No rollback: nothing MAJOR or above, and the reviewer accepted both
self-declared design drifts with reasons. Intervention file re-checked — absent.

*Persistence note:* the code-reviewer agent also ran without Write/Bash tools, so the PM persisted
its returned document verbatim to `05_CODE_REVIEW.md`. Mechanical persistence, not authoring.
**Consequence carried to QA:** the reviewer could not run `git diff`, `py_compile` or `verify_all`,
so AC-25's scope check was content-inspection only. QA must re-assert it with a real byte diff and
re-run `verify_all` independently rather than inheriting the developer's run.

Three reviewer findings the author could not see, routed to QA as verification targets rather than
to the developer as defects (none is MAJOR, so none forces a rollback):
- `bin/sc:578-581` — dropping `rule_set` from a rule that keeps another matcher *broadens* the
  AND-rule. Dead against today's config and mandated verbatim by B-5; wants a warning comment.
- `bin/sc:1075` — `--mirror` survives the `sudo` re-exec (argv is preserved, env is not), so the
  requirement's "the override is only effective for a caller who is already root" is false for the
  flag; `urlopen` also accepts `file://`. Reviewer assessed privilege impact as negligible (the
  same caller can already run `sc add`/`sc off` as root) and recommends a pool row, not a change
  here. **PM concurs with routing it as a follow-up row** — enlarging scope now would exceed B-14
  and BC-24 as written, and the gate already approved that boundary.
- `_filter_rules` does not recurse into `type: "logical"` sub-rules; no such rule exists and
  `docs/dev-map.md` already carries the guard rail.

Follow-up row updates accumulated so far (PM-owned, not folded into T-02):
- Q9 row must name **five** sites, not two: `capture_output=` at `bin/sc:822`, `:864`, `:1159`
  **plus** `text=True` (also 3.7+) at `:822` and `:1159`.
- `bin/sc:642`-class defect: `TRANSLATIONS` has no `en` table, so a namespaced key renders as the
  literal key in English (architect's finding).
- `--mirror` scheme allow-list (`http`/`https`) hardening (reviewer's finding).
- `docs/dev-map.md:34,37` inaccuracies — routed to the developer inside stage 6, since dev-map is
  this task's own artifact rather than a separate row.

### Stage 6 → rollback 1 (the routing call)

QA verdict: **`ROLLBACK: developer`** — D-1 (MAJOR), `bin/sc:1093-1097`. `causes` is appended
inside `except`, but the success path does `print(OK); break` and discards the list, so the
enumeration is printed only in the total-failure `for…else` branch. When base 1 serves an HTML
error page and base 2 succeeds, stdout shows four clean `OK` lines and stderr is empty — a mirror
path typo ships **invisibly** whenever any later base works, which is the common case on the target
network. AC-10 and AC-11 both require the failed base to appear in the output. Deterministic:
9 failures out of 563 assertions, one root cause, zero flakes across 3 consecutive full runs.

**I am routing to solution-architect first, not straight to the developer.** QA's own provenance
note is the reason: `02_SOLUTION_DESIGN.md` §6.2's pseudocode *already* discards the causes on
`break`, and the gate review did not check that pseudocode against AC-10/AC-11. So the developer
implemented the approved design faithfully — this is a **design gap**, not an implementation slip,
and under the routing rules only the design's author may close it (`Reviewer/QA finds design gap →
solution-architect`). Sending the developer to deviate from an approved design would manufacture
exactly the drift stage 5 exists to catch. The amendment is deliberately scoped to §6.2 alone;
QA's suggested fix shape (append the causes to the same completion line) is handed to the architect
as QA input, **not** as a PM design instruction — I do not adjudicate the fix.

Rollback count at stage 4/6: **1**. The three-consecutive-rollback stop is not near.
Intervention file re-checked after stage 6 — absent.

QA results that stand regardless of D-1 (all executed, with pasted tool output):
- **The reported failure is gone, proven side-by-side.** Same empty rules dir: `main`'s
  `generate_config()` returns `False` with `FATAL initialize router: parse rule-set[0]: open
  …/geoip-cn.srs: no such file or directory`; the worktree returns `True` under real `sing-box`
  1.13.15, keeping nodes, TUN, DNS and `final: "proxy"`.
- AC-3 all-usable config **byte-identical** to `main`'s output (developer's claim verified).
- 16/16 subset masks closed under `referenced ⊆ defined` *and* `referenced == usable`; real
  `sing-box check` accepts all 16 including the empty case (closes design risk R2).
- AC-22 proven a true **regeneration**, not a patch, by injecting a sentinel key.
- A real 30 s socket-timeout run cost 30.1 s total, not 4×30 — the time-budget bound holds in
  execution, not just on paper.
- AC-25 asserted with a **real byte diff**: `install.sh`, `uninstall.sh` and all three `systemd/*`
  are SHA-256-identical to `main`; the three timeout constants are still 3 / 8 / 30. This closes
  the gap left by stage 5, which had no Bash tool.
- `verify_all`: `PASS: 16 / FAIL: 0`, exit 0.
- F-3 satisfied with **both** techniques (flags *and* PATH stubs writing a marker asserted absent
  every run) — no real service touched. F-5's stale-temp PID is `pid_max`, asserted dead first.
  AC-16's fixture is 200 000 bytes, showing `65536→131072→196608→200000` at 32/65/98/100%.

Four items QA marked **unverified** with reasons rather than silently passing them: BC-25 and D-2's
escalation (need a real root/sudoers host), AC-26 against a real 3.6 interpreter (this box has
3.12.3 only), and BC-32. These are carried into delivery as residual risk.

Additional QA findings routed as follow-up pool rows, not as rollback causes: D-2 (`--mirror`
crosses the sudo boundary — same finding the code reviewer raised, now independently confirmed,
and honestly marked *reasoned, not executed*, since QA ran at euid 1000), D-4 (a local disk fault
is reported as a mirror failure and leaks the temp path), D-5 (stray blank line before the restart
notice). D-3 (other-matcher branch broadens a rule) was executed and confirmed dead against today's
config.

### Rollback 1 → back down the pipeline

Architect returned **READY** with **Amendment A-1** to `02_SOLUTION_DESIGN.md` §6.2, and explicitly
declined to blame the requirement (AC-10/AC-11 are correct as written; the pseudocode was wrong).
The loop now keeps two lists: `causes` (unchanged, total-failure line) and `tried` (bases actually
contacted and rejected *for this file*), with `tried` rendered onto the **same** completion line.
`tried` is empty when base 1 works, so the happy path stays byte-identical. Architect tightened
QA's suggested shape (excluding dead-skips, so a cause appears once per base per run) and recorded
three rejected alternatives in `.harness/rejected-decisions.md`. Doc condensed 500 → 498 lines, so
F.6 stays PASS.

**Not re-running stage 3 (gate).** The routing table sends a design gap to the architect and back
down; it does not prescribe a re-gate, and the stage-4 gate condition ("stage 3 produced an explicit
PASS verdict") is already satisfied for this task. The amendment is one scoped section, and both
stage 5 and stage 6 will re-examine it — re-gating would add a full stage for a checkpoint whose
purpose is already served. Recording the call because it is a deviation from a cold-start run.

Dispatching the developer to implement A-1 only, then a delta-focused stage 5, then a stage 6 re-run
of the 14 ACs the architect named (AC-10, AC-11, AC-12, AC-18, AC-21, AC-23 must now carry the note;
AC-13, AC-15, AC-16, AC-17 must not move; AC-14 for the new key; AC-3 as the happy-path guard).
The architect also caught that QA's re-run list omitted **AC-18** — its truncated body is among
D-1's swallowed causes.

### Delta review → amendment A-2 (the sequencing call)

Developer returned READY FOR REVIEW (`verify_all` 16/0/0/2, delta 0) and the delta code review
returned **APPROVED** — D-1 closed structurally: there is exactly one rejection path out of the
inner loop (`except Exception` at `bin/sc:1113`) appending one `entry` to both lists, so
"contacted and rejected ⇒ named in the output" holds by construction rather than by case
enumeration. The dead-skip exclusion is real, and the happy path is byte-identical because `note`
is `""` and concatenated. Two of the six original MINORs were fixed this pass (dev-map, AND-semantics
comment). Intervention file re-checked — absent.

**One new MINOR, and I am routing it back rather than deferring it.** `bin/sc:140`'s zh string
`"；已回退，前序镜像失败：{causes}"` contains `失败：` — the exact substring
`.harness/rejected-decisions.md:44-45` says a *successful* line must never match, since that grep
means "this file was not updated". The protection the design bought in English is defeated in
Chinese. The reviewer rated it MINOR, non-blocking, and explicitly said not to roll back the code
for it.

My reasons for fixing it now rather than filing a row:
1. It defeats a protection **the design itself declared load-bearing** one document earlier — that
   is the "patch-then-patch seam" rule 85 exists to prevent, and the owner's standing directive is
   优先用好的设计，避免不断的修修补补.
2. The affected reader is precisely this task's user — the zh-speaking operator reading
   `install.log` on the mainland-China network that produced the original bug report.
3. **Sequencing:** QA has to re-run either way. Fixing before that re-run costs one small architect
   amendment plus a one-token code change and lets QA validate the final state **once**; deferring
   it means QA runs now and again later on a string it already tested. This is a lifecycle call,
   which is mine.
4. I am **not** choosing the wording. The reviewer offered two candidates; the architect owns
   `02` §5.4's string and decides.

Rollback count: **2** (both design-origin, both distinct causes — D-1 cause-discarding, then the
zh grep collision). Neither repeats the other, and the three-consecutive-rollback stop is not
triggered. If a third design-origin defect appears in this same output path, I stop and escalate
rather than dispatch again.

### A-2 implemented — and a live-system incident to surface

Architect chose `未成功` over the reviewer's `报错`, reasoning that `tried` carries four cause kinds
including bodies *we* rejected after a perfectly good HTTP 200, so `报错` would be false for those;
`未成功` is neutral and true for all four. Architect also ran a wider audit (recorded as design R10)
across all 12 new zh strings against the tokens other renderings own, and found the dead-skip string
`已跳过（…已失败）` carries `失败` **without** the colon — safe today only because dead-skips never
enter `tried`, which is now written down as an invariant rather than left as luck.

Developer applied the one-token change; `verify_all` 16/0/0/2, delta 0; the zh fallback-success line
no longer contains `失败：`, and `失败：` again means only "this file was not updated".

**No third code-review pass for A-2.** It is a one-token change to a single string literal, specified
by the architect and originally proposed by the reviewer itself; the delta review's sole MINOR was
exactly this defect. A further review pass would be process for its own sake. QA verifies the shipped
string instead (AC-14 plus the zh pass of AC-10/AC-11/AC-18). Recording the call since the stage-7
gate requires stage 5 to have PASSed — it did, and its one open finding is now closed.

**LIVE-SYSTEM INCIDENT — self-disclosed by the developer, surfaced to the owner at delivery.**
On a first sandbox attempt the developer did not neutralise the auto-elevate block at `bin/sc:77-78`.
It re-execs the **installed** `/usr/local/bin/sc` (not the worktree copy) and sudo drops the
environment, so `SB_RULES_BASE` never reached the elevated process: **one real `sc update-rules` ran
on this machine against the built-in mirrors and restarted `sing-box`.** Assessed: idempotent
maintenance only; the developer re-checked the service (`active`/`enabled`), all four rule-sets
present and fresh, no repository file affected, and `bin/__pycache__/` debris removed. All reported
results come from the corrected sandbox.

My assessment as task owner: **not a hard stop.** Nothing destructive or irreversible occurred, no
commit or push happened, the effect was a routine maintenance action on the owner's own machine, and
the developer disclosed it unprompted rather than burying it. But it **is** a real gap in this
task's test discipline, and the owner should know a stage agent touched the live service. Two
consequences:
1. Gate condition F-3 required neutralising `systemctl`/`rc-service` in the **QA** harness — QA
   complied with both techniques. Nothing imposed the same discipline on a *developer's* throwaway
   verification script. That asymmetry is the actual defect.
2. This is strong insight-index material: the auto-elevate re-exec targets the installed binary and
   sudo's `env_reset` silently discards `SB_RULES_BASE`, so an un-neutralised import does not merely
   fail — it exercises the *installed* tool against the *real* service. It is also live evidence for
   the already-deferred `--mirror`/sudo hardening row.

### Stage 6 → 7 decision

QA re-test verdict **PASS**: 846/846 assertions, 0 failed, 3 identical runs, zero flakes (up from
554/563). **Delivery gate satisfied** — stage 5 APPROVED and stage 6 PASS. Intervention file
re-checked — absent.

D-1 is closed on all seven rejection modes; the original reproducer, re-run **unmodified**, went
27/2-fail → 29/0. The dead-skip exclusion is verified in execution (files 3-4 asserted *string-equal*
to the plain `OK (n bytes)` form), as is A-2's invariant in both directions: zh fallback-success runs
assert zero occurrences of `失败：` *and* `已失败`, while the zh total-failure run asserts four
`失败：` — so the diagnostic grep keeps its meaning. QA re-ran `verify_all` itself: 16/0/0/2, delta 0.
F-3 honoured with both layers, and QA independently confirmed `NRestarts=0` with `ActiveEnterTimestamp`
still showing only the developer's earlier single restart — no service touched during its pass.

### Delivery actions taken and NOT taken

Written: `07_DELIVERY.md`; `docs/tasks.md` moved T-02 to Completed with a Notes section carrying the
consolidation record (rule 85) and the six follow-up rows, each re-homed rather than dropped.

**`.harness/scripts/archive-task.sh` was NOT run — the PM session has no Bash tool.** Flagged as
step 2 of the delivery's "Next steps". The `## Insight` section is written in the exact harvest
format so the script picks up all four lines when the owner runs it; I did **not** hand-write
`.harness/insight-index.md`, per the contract in `.harness/rules/05-insight-index.md`.

Entropy watch: this project's `.harness/scripts/` has no `entropy-cadence` pair, so the cadence
resolves to **NOT-DUE** under its documented fail-open rule. No scan dispatched, no section emitted.

PM_LOG size: ~350 lines, under the 500-line cap — no compaction needed (T-01 breached this).

