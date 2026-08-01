# PM Log — sc-doctor (T-05)

Mode: **full** (stages 1-7). Decision mode: standing authority granted by owner
(「你来决策就行」) — PM resolves judgment calls and records them; `BLOCKED: NEEDS-HUMAN`
reserved for a genuine safety red line. Interactive asks unavailable (deferred-human mode).

## Pre-flight (PM)

- `.harness/intervention.md` — **absent** at task start. No pending intervention.
- Partition agents `.harness/agents/dev-*.md` — **none**. Single-developer mode; stage 4
  goes to the plugin `harness-kit:developer` (confirmed by rule 50 § Partitioning).
- `docs/tasks.md` read. Related historical rows surfaced to downstream:
  - **T-02** `config-degrade-missing-rulesets` — introduced the ruleset usability model
    (`srs_reject_reason` / `ruleset_status` / `ruleset_report`). Load-bearing reuse target.
  - **T-10** `ruleset-update-no-needless-restart` — added `ruleset_state(path) -> (status, digest)`,
    the ONE on-disk `.srs` reader. Second reuse target.
  - **T-08 / T-11** — `install.sh` only; out of this task's scope boundary, but T-08's TTY
    gating precedent (`[ -t 2 ]`, stderr) informs BR-6.
  - **T-09** — `systemd/` only; out of scope.
- `docs/dev-map.md` read; "Reusable utilities" table is the authoritative reuse inventory
  and is quoted into the stage-1/2 dispatch prompts.
- `.harness/insight-index.md` read (29 entries, cap 30 — harvest budget is ~1 line).
  Entries surfaced to downstream dispatches: lines 13 (auto-elevate re-execs the *installed*
  `sc`; sudo `env_reset` drops env), 16 (`失败：` is a load-bearing grep literal), 22
  (`systemctl is-active` cannot witness a restart; use `MainPID` + `ActiveEnterTimestamp`),
  20 (`SB_BIN` bare-name PATH resolution), 21 (insight bullets must be ONE physical line).

## Live-service witness (PM, task start)

Owner-supplied pre-task reading, to be re-verified at stage 4 and stage 6:
`MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`.

## Stage transitions

| # | Time | Stage | Decision |
|---|---|---|---|
| 0 | 2026-08-01 | pre-flight | Task folder created; no intervention; single-dev mode confirmed. |
| 1 | 2026-08-01 | 1 requirement-analyst | **ADVANCE → stage 2.** `01_REQUIREMENT_ANALYSIS.md`: 31 FR / 26 AC / 18 BC / 7 NFR / 10 resolved ambiguities / 5 risks. Verdict `READY FOR DESIGN`, no BLOCKED marker, zero questions routed to the owner (deferred-human mode honoured). |

### PM rulings on stage-1 scope expansions (standing decision authority)

Stage 1 resolved three ambiguities that widen the blast radius beyond the literal dispatch brief.
I reviewed each against the owner's own words and rule 85, and **upheld all three**:

1. **R-1 — FR-4 read-only is process-wide, not `doctor`-local.** `main()` calls `_init_files()` and
   `_resolve_clash_port()` before dispatch; on a wrecked host `sc doctor` would today *create the very
   directory whose emptiness is the diagnosis* and persist an invented Clash port. The owner wrote
   "Read-only. This is absolute." A guarantee scoped to `doctor`'s own function body would be
   dishonest. **Upheld.** Constraint attached for stage 2: the fix must touch the shared start-up path
   as narrowly as possible and must state what protects the other subcommands (RISK-2); this is inside
   the `bin/sc`-only boundary.
2. **R-2 residue / FR-18 — single definitions for the TUN interface name and egress endpoint.** This
   is a small refactor of `cmd_status`'s internals. Rule 85 §"Duplicated judgment" authorises it and
   the future edit it prevents is nameable (the next task needing either literal). FR-19 + AC-16 pin
   `sc status` output byte-identical in both languages, which bounds the risk. **Upheld.**
3. **R-10 / FR-30 — `CHANGELOG.md` and `docs/dev-map.md` join the permitted diff.** My brief named
   `bin/sc` + the two READMEs. Both additions are documentation-only with no behavioural surface;
   every prior delivered task shipped a CHANGELOG bullet, and dev-map self-documents as
   "update whenever the module inventory changes" (FR-12/FR-18 change it). **Upheld**, and AC-26 now
   pins the exact five-file diff, which is a tighter gate than my prose boundary was.

Not upheld / left closed: absorbing T-06 (`sc config --show`) or replacing `sc status` — stage 1
declined both under rule 85's tests (R-8) and I agree; the pool row stays.

| 2 | 2026-08-01 | 2 solution-architect | **ADVANCE → stage 3.** `02_SOLUTION_DESIGN.md` (18 sections, D-1..D-9 each with rejected alternative). No rollback requested against stage 1; no BLOCKED marker. Also appended two records to `.harness/rejected-decisions.md` (permitted — harness metadata, not product). |

### PM notes carried into the gate

- **D-8 / RISK-1 is deliberately unsettled.** The architect has no shell this session and refused to
  assert sing-box internals from memory — correct behaviour, not a defect. It recorded a prediction,
  a structural note (AC-5's fresh-host half never reaches the checker), and a pre-agreed contingency.
  I am routing the empirical settlement to stage 4/6, which have Bash. The gate must confirm the
  contingency does not pre-emptively weaken FR-4.
- **AC-13 interpretation flagged, not silently taken.** The design satisfies the deletion test through
  `ruleset_report() == _status_view(ruleset_states())` (`bin/sc:605`) rather than through a direct
  `ruleset_report()` call, because `ruleset_report()` cannot carry a size and calling both would mean
  two reads per file (an FR-12 violation). The architect asked the gate to rule. **Gate owns this.**
- **D-2 widens `ruleset_state()` to `(status, digest, size)`** — this touches T-10's restart-decision
  machinery. The gate must satisfy itself that `sc update-rules`'s "exactly one apply per run" and
  `changed_usable_tags`'s tag-pairing survive, since regressing T-10 is a serious defect.

| 3 | 2026-08-01 | 3 gate-reviewer | **ADVANCE → stage 4** with conditions. Verdict `APPROVED FOR DEVELOPMENT WITH CONDITIONS: C-1..C-8`. 14 findings (3 MAJOR / 4 MINOR / 7 INFO); **no rollback** — the gate states explicitly that none of the eight requires a design change of substance and that neither `01_` nor `02_` must be reopened. All three MAJORs are instruction/test-method defects executable inside stage 4/6. |

### PM: transcription of `03_GATE_REVIEW.md`

The `gate-reviewer` agent is provisioned **read-only** (Read/Glob/Grep), so it returned the document
as text and could not write it. I wrote it to disk **verbatim** and marked the transcription at the
head of the file. I authored none of its content — this is a mechanical routing action, not a PM
professional opinion.

### PM ruling on C-8 first half (F-5 — `02_` is 858 lines vs rule 70's 500-line cap)

The gate explicitly routed this to me as "a documentation-hygiene routing decision for the PM, not a
design defect". **Decision: declare the `verify_all` F.6 WARN as a predicted AC-25 delta; do NOT
compact `02_` mid-flight.** Reasons:

1. Rule 70 closes with "Cuts are made by removing what doesn't earn its line, not by mechanical
   truncation." The gate audited `02_` section by section and found no redundant section — it found
   the opposite (three MAJORs from under-specification, not over-specification).
2. `02_`'s section anchors are load-bearing *right now*: C-1..C-8, the developer's E-1..E-18 edit
   list and QA's T-1..T-10 all cite them. Renumbering mid-pipeline would break the conditions the
   gate just made binding — a real correctness risk traded for a soft WARN.
3. The WARN **self-resolves at delivery**: `verify_all.sh:229-237` (F.6) skips `*/_archived/*`, and
   step 10 runs `archive-task`, which moves the stage docs there.

Consequence I accept and pin: `verify_all` will read **WARN 1** (F.6) instead of the WARN 0 baseline
while this task is in flight. **FAIL must still be 0** — that is the owner's gate and it is unchanged.
Mitigation attached to stages 4 and 6: keep `04_` and `06_` under 500 lines via rule 70's
"reference, don't paste", so F.6 names exactly one file and the delta stays fully predicted.

| 4 | 2026-08-01 | 4 developer | **ADVANCE → stage 5.** Verdict `READY FOR REVIEW`. `verify_all` **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — zero delta against the developer's own pre-work capture; the single WARN is F.6 naming only `02_` (857 lines), exactly the delta I predicted. **Stage gate satisfied: no FAIL.** 131 executed checks across 7 sandboxed harnesses, 0 failures. Product diff = exactly the five permitted files (`bin/sc` +484/−43, `README.md` +31, `README.zh-CN.md` +31, `CHANGELOG.md` +2, `docs/dev-map.md` ±24); `install.sh` / `uninstall.sh` / `systemd/` byte-identical to HEAD by `git diff --quiet`. |

### Live-service witness (stage 4) — the safety gate

Developer's readings, verbatim, at **start and end**, re-read after every harness that touched systemd:
`MainPID=2500438` · `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`.
**Identical to the owner's pre-task values.** The live sing-box was not restarted. `systemctl is-active`
was correctly not used as the witness (`insight-index.md:22`). Every harness loads `bin/sc` through a
shared loader that *asserts* the sudo re-exec was removed before executing the module and forces
`SYSTEMD = OPENRC = False` — the T-02 gap (guard bound the QA harness but not a scratch file) is closed
in both places.

### C-7 / RISK-1 — settled empirically, no longer a prediction

`sing-box check -c` (v1.13.15) neither creates nor modifies the `experimental.cache_file` database.
Measured on a temp-dir **copy** with the cache path redirected into that temp dir — the live root-only
config was never handed to the checker — in both arms (absent → still absent; pre-existing → identical
size / `st_mtime_ns` / sha256), with the live `/var/lib/sing-box/cache.db` fingerprint as an unchanged
control. Stated scope limits: one sing-box version, a shape-equivalent copy rather than the installed
config. **C-7's "inconclusive is not a pass" escape hatch did not need to fire, and RISK-1 does not
return to the gate.**

### PM ruling — three design drifts reported by stage 4 (NO rollback to stage 2)

The developer found three defects in `02_` and correctly **did not edit the upstream document**; it
resolved each minimally in code and labelled them `DESIGN DRIFT`. I am **not** rolling back to the
solution-architect. Rationale, and where each goes instead:

1. **`02_` §6/§10 gap — S4's `not enabled ({state})` supplies a `{state}` source for systemd only.**
   Real gap: OpenRC's `rc-update show default` has no state word to quote. The developer added one key
   pair (`not in the default runlevel` / `不在 default 运行级别`). The two alternatives it rejected are
   both defects (an untranslated English phrase breaks BC-18; a meaningless token breaks FR-23/AC-19).
   A stage-2 round trip to add one bilingual key pair would cost a full re-gate to change nothing —
   disproportionate. **Routed to stage 5 to audit**, not to stage 2 to re-author.
2. **`02_` §5.1 omits `_first_line()`** — S1 and S4 both need "first non-empty line of a tool's
   output". Adding one helper is the rule-85-correct move (the alternative is duplicating the loop,
   which is precisely the duplicated-judgment failure rule 85 forbids). **Routed to stage 5** with the
   explicit question of whether it earns its line under rule 85's counter-rule.
3. **`02_` header anchor drift** — states `bin/sc` is 1537 lines at HEAD `22502f9`; it is 1536, so
   every `file:line` anchor in `02_` may be off by one. Harmless here because every anchor is also
   named by function, but it is a documentation defect. **Recorded here; not re-opening `02_`.**

Standing instruction to stage 5: if any of drifts 1-2 is the *wrong* resolution rather than a
proportionate one, say so and name the owning agent — I will then roll back to the architect. This is
the same disposition the gate applied when it audited-and-upheld a developer call in T-08.

| 5 | 2026-08-01 | 5 code-reviewer | **ADVANCE**, with two items routed back to stage 4 first. Verdict `APPROVED WITH FOLLOW-UPS` — **zero BLOCKER, zero MAJOR**; aggregate severity MINOR on both axes. 24 of 26 ACs verified by inspection; AC-25 and AC-26's byte-identity clause explicitly declared unverifiable without a shell (the reviewer is read-only) and handed to QA. `05_CODE_REVIEW.md` transcribed to disk verbatim by me, same as `03_`. |

### PM ruling — the three drifts are settled, NO rollback to stage 2

The code reviewer ruled on all three drifts I routed to it (§6):
(a) the OpenRC `not in the default runlevel` key pair — **proportionate, keep**; the two alternatives
both break a binding AC (BC-18 / FR-23+AC-19). (b) `_first_line()` — **proportionate, keep**; two real
call sites today, passes rule 85's deletion test, no modes, no parameters. (c) the 1537-vs-1536 line
count — **not a drift at all**; a `wc -l` vs displayed-line-count artefact, and every `02_` anchor is
also named by function, so all eighteen resolved correctly. **The architect is not re-dispatched.**
The reviewer's counter-finding is that the arithmetic which genuinely did not close was the
*developer's own diffstat*, not the design's anchors.

| 5b | 2026-08-01 | 4b developer (bounded fix-up) | **ADVANCE → stage 6.** Verdict `READY FOR REVIEW`. |

### PM ruling — M-2 is fixed, not shipped as a wart (overriding "optional")

The reviewer filed M-2 (a non-zero checker with empty output prints
`[PROBLEM] sing-box check: the checker reported an error:` with **nothing beneath it**) as
MINOR/optional. **I ruled it be fixed.** Reason: this project's standing discipline since T-01 is that
a tool always states its outcome, and a *diagnostic* that prints a header promising detail and then
delivers none is that exact failure mode — on the broken host the command exists for. The row now
reads `the checker reported an error, no message (exit {code})`, carrying the only fact that path has.

**Ordering decision:** I ran the fix-up **before** QA rather than after, so QA validates final code and
does not have to re-run against a moving target. Cost: one extra developer round trip. The alternative
(ship the wart, file a follow-up row) was rejected — it is a two-line fix in the command's own block.

**M-3 (record arithmetic) resolved with the real numbers.** The authoritative diffstat is
`5 files changed, 539 insertions(+), 43 deletions(-)`; `--numstat` gives `457 37 bin/sc`. The slip was
reading `git diff --stat`'s graph column (insertions **+** deletions) as insertions. It now closes:
`1536 − 37 + 457 = 1956`, and the file measures 1956. Per-file: `bin/sc` 457/37, `README.md` 31/0,
`README.zh-CN.md` 31/0, `CHANGELOG.md` 2/0, `docs/dev-map.md` 18/6.
**M-1 answered honestly:** `t_status.py:66` stubs `is_running` to `True`, so the egress region *was* in
the AC-16 capture; the record had omitted three stubs, and the one region deliberately never compared
is the volatile `systemctl status` block. QA re-states this independently.

Live-service witness at fix-up start and end: `MainPID=2500438` ·
`ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` — unchanged for the third and fourth checkpoints.
`verify_all` PASS 16 / WARN 1 / FAIL 0 / SKIP 1; `git diff --quiet -- install.sh uninstall.sh systemd/`
exit 0.

| 6 | 2026-08-01 | dispatched | Stage 6 (QA) and a **bounded M-2 delta re-review** dispatched **concurrently** — both read the same now-final code, and QA does not depend on the delta review's outcome unless it finds a defect. QA was told to **rebuild** its harness rather than inherit the developer's (T-10/T-11 precedent: an author-written harness shares the author's blind spots) and to prove non-vacuity by making key assertions fail on demand. |
| 5c | 2026-08-01 | 5 code-reviewer (delta) | `DELTA APPROVED — prior verdict stands`. Aggregate NIT. Appended verbatim to `05_CODE_REVIEW.md` §11. Its shift analysis (a uniform +2/+10 offset with no intermediate values) is independent structural evidence that the fix-up introduced no third edit site. |
| 6 | 2026-08-01 | 6 qa-tester | `PASS WITH DEFECTS: DEF-1, DEF-2` (both MINOR). 688 assertions / 0 failures; all 26 ACs PASS; T-1/RISK-1 **measured**, so C-7's "inconclusive" trigger did not fire. |

### PM ruling — DEF-1 fixed, DEF-2 shipped open

**DEF-1 fixed.** `_plain()` stripped the ESC *byte* only, and QA measured that sing-box 1.13.15
colourises **even into a pipe**, so every real broken host rendered `[31mFATAL[0m[0000] initialize
router: …` — on the single row the owner's entire requirement leans on, in an artefact whose stated
priority (NFR-3) is being pasted into a bug report. The design's own §6.2 sample showed this line clean,
so the expectation was empirically wrong; the developer's fixtures used a *fake* checker, which is
exactly why it survived to stage 6. Ruled fixed despite QA filing it MINOR.

**DEF-2 shipped open.** A *hung* Clash port yields one `[UNKNOWN]` row instead of the port row plus a
PROBLEM row. This was predicted by the gate as **F-12 before code was written** and ruled "acceptable,
not a bug to chase"; the report stays complete (FR-9 holds) and refused ports behave as designed.
Re-opening a pre-ruled acceptance at stage 6, for a case with a working fallback, would be the
band-aid accumulation rule 85 exists to prevent. Filed as a follow-up row instead.

| 4c | 2026-08-01 | 4 developer (bounded fix-up) | DEF-1 fixed — whole-CSI stripping confined to `_plain()`, hand-scanned (no `re` import), reproduced and re-measured on the **real** binary. Interrupted by a platform API 403 **after** writing its record; the work itself was complete and self-consistent, which I confirmed from the files rather than from its (lost) report. |
| 6b | 2026-08-01 | 6 qa-tester (targeted re-verify) | **`PASS WITH DEFECTS: DEF-2`** — 721 PASS / 0 FAIL, four consecutive identical runs. DEF-1 gone, measured on the real binary in a run whose *raw* bytes were verifiably coloured. Byte-identity oracle taken from `02_` §3.6 (the design doc) rather than the developer's code, so it cannot agree by construction. QA found a **third** harness failure the developer had missed and fixed its own pins. T-12 measured as not affecting any doctor probe. |
| 7 | 2026-08-01 | PM delivery | `07_DELIVERY.md` written, `docs/tasks.md` updated, `archive-task.sh` run (3 insights harvested, stage docs moved). **Final `verify_all`: PASS 17 / WARN 0 / FAIL 0 / SKIP 1 — zero delta vs a pristine clone.** |

### PM note — the archive step needed a second ruling

`archive-task.sh` cleared F.6 as predicted but pushed `insight-index.md` to **32/30**, turning F.4
WARN: it harvests without auto-rotating, which rule 70 §Caps says is its job. I hand-rotated two
entries into `docs/features/_archived/insight-history.md`, selected by rule 70's "what no longer earns
its line" (one is now enforced by committed gate B.2; the other is now a `docs/dev-map.md` convention)
rather than mechanically oldest-first. Filed as a follow-up: this is the **second** archive-script
defect on record and will recur for every task that harvests at the cap.

### Live-service witness — final disposition

The witness moved mid-task from `MainPID=2500438` / `Fri 2026-07-31 17:04:23 CST` to
`MainPID=2887037` / `Sat 2026-08-01 10:06:40 CST`. **No pipeline stage caused it**: `NRestarts=0`, and
the sudo journal attributes it to the owner working by hand from `pts/4`
(`PWD=/home/alan/Programs/NFBY_CMS`) at 10:06. Every stage read the witness with
`systemctl show -p MainPID -p ActiveEnterTimestamp` — never `is-active` — and every reading was
identical before and after **within** each stage, which is the property that actually proves
non-interference. Stage 6b re-baselined onto the new values and closed identical.
