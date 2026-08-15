# Delivery Summary

## Summary

- Task: **T-24 `override-error-envelope`** — put one exception envelope and one type-mismatch
  vocabulary over the override/merge pipeline, so a malformed `override.json` (too deep, non-object
  rule element, wrong type at an array key) is a named sentence, a non-zero exit and no write —
  never a traceback and never a silent array replacement.
- Mode: **full** (7 stages). Pool: `followups`, dispatched by `/harness-batch`.
- Stages traversed (2026-08-15): 1 requirement-analyst → 2 solution-architect → 3 gate-reviewer →
  4 developer → 5 code-reviewer → **4′ → 5′ → 4″ → 5″** → 6 qa-tester (attempt 1 lost to an API
  transport fault, attempt 2 complete) → **4‴ → 6′ → 4⁗** → 7 delivery.
- Rollbacks: **3, and not one of them for a code defect.** `bin/sc` has been byte-for-byte as first
  reviewed since round 1.
  1. **Stage 5 → 4 (CR-1/CR-3).** `CHANGELOG.md` published as unconditional a silent-write claim
     that **stage 4's own measurement refutes** at the three guarded keys.
  2. **Stage 5′ → 4 (CR-8).** The correction traded one false universal for another: 「绝不回显你文档
     里的任何一个值」 is refuted by `_anchor_index`'s `match: {anchor}` **inside the region** — the
     echo this task's own `01_RATIONALE.md` re-homed and `02_SOLUTION_DESIGN.md` declines to fix.
  3. **Stage 6 → 4 (QA-1).** QA lifted stage 4's `subprocess.run` stub and measured HEAD with the
     **real** `sing-box`: 「退出码仍然是 0」 is false on every host `install.sh` produces.
  Plus one NIT round (QA-6) for a present-tense claim in `04_DEVELOPMENT.md` that a closed defect
  was still open. **Five instances of one pattern** — a shipped sentence claiming slightly more than
  the code delivers — every one of them in prose, none in code. That is this task's real lesson.
- Final `verify_all` result: **PASS** — `bash .harness/scripts/verify_all.sh` from the repository
  root, **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**, matching the batch baseline exactly. Measured at
  stage 4, stage 4′, 4″, 4‴, 4⁗, stage 6, stage 6′ (against a **freshly made** clone at `2de1339` —
  a stale clone is how that comparison lies) and at this PM checkpoint.
- Baseline changes: **none.** `baseline.json` holds at `test_count: 0`, mtime `2026-07-31` — **T-28**
  owns the committed suite. No test added, lowered, deleted or skipped; `.harness/scripts/` is
  byte-unmodified (checked, not assumed). QA ran its fixtures in the session scratchpad; none
  committed.
- Files changed: **6 product** — `bin/sc` **+79/−55**, `CHANGELOG.md` +2, `README.md` +2,
  `README.zh-CN.md` +2, `CONTEXT.md` +8 (stage 2's glossary term), `docs/dev-map.md` +3/−3 (the PM's
  RES-4/RES-8 repairs). Plus `.harness/operator-obligations.md` +1 and
  `.harness/rejected-decisions.md` +35 (C-9), and this task's stage documents.
- Outstanding risks: none blocking. One criterion **BLOCKED by construction** → operator obligation
  **id 5**, nothing substituted (the **eighth** consecutive time). Two criteria reported
  **NOT-DISCRIMINATING** rather than passed, both re-homed to T-28.

## What shipped

**One region, one vocabulary, one gating condition — and the vocabulary cost zero new keys.**

A single `try` inside `generate_config()` spans `if override is not None:` through a hoisted
`text = json.dumps(...)`. `except OverrideError: raise` comes first — without it the generic arm
would swallow the specific sentence and destroy `e.path` — and `except Exception as e:` raises
`_unusable(OVERRIDE_PATH if override is not None else None, t("no configuration could be produced
from it ({fault})", fault=type(e).__name__)) from None`. The load wrapper carries the same second
arm. `_compose` stays above the region and `_write_private` / `_record_generated` / `sing-box check`
stay below it, so **no path reaches `_write_private()` with an override that failed**: both arms
`raise`, neither returns, and `text` is unbound unless the region completed.

`_merge`'s loop was re-derived around the **target's current type**, so a key whose current value is
an array admits a directive object and **nothing else** — object, scalar, JSON `null` and bare array
all reach the sentence that **already existed**. FR-3 therefore added **zero** translation keys and
**deleted** a branch. One new user-facing string in total, against a cap of two. No new function,
class, module or file.

**Rows discharged. R-15 closed** (both instances, plus a third no row recorded). **R-16 closed** —
open since T-14 and **declined four times** by T-15, T-16, T-17 and T-21 (R-54 re-homed it); this
task is the owner, and the README obligation it carries shipped with the fix. **R-26 closed** at the
zero-behavioural-cost gating it predicted. **R-44 deliberately not closed** — no cap was added on
anyone's say-so; it is honoured as a bound (BC-8, never raise the recursion limit). **R-69
discharged as constraints**: `main()`'s arm still renders `e.path or CFG_PATH` for T-23's 16 state
document call sites, unnarrowed. **R-12 not closed**, and this task **widens its population** —
shapes that used to traceback now end in the sentence-and-exit path that still prints no run-level
outcome line.

## What the pipeline refuted in its own brief

The dispatch handed this task a completed diagnosis and told stage 1 to re-verify rather than
inherit. Four clauses did not survive, and three changed the design:

1. **R-16's counter-weight is false.** The brief asked how much vocabulary is owed given the binary
   already catches it loudly. Answer: the ordering is `_write_private` → `_record_generated()` →
   `sing-box check`, so `rc=1` arrives **after** the working `config.json` was replaced and the
   broken document's digest baselined as "what `sc` last wrote". The loudness protects the running
   service, not the stored configuration. Decisive addition: **both READMEs already publish** the
   opposite promise — the task makes a shipped promise true rather than adding one.
2. **R-44's reachability half is refuted.** Every container an override contributes is deep-copied,
   and the copy overflows long before the pure-Python walk — so the `override.json` route to R-44 is
   **already structurally closed**, and BC-8 is what keeps it closed for free.
3. **A third R-15 instance no row records.** The JSON scanner signals depth exhaustion with
   `RecursionError`, not the `ValueError` `_load_override()` catches — so a deep enough override
   tracebacks **before** `_merge`. This is why the envelope encloses the load.
4. **R-69's "three differing policies" is five.**

## Rule 85 — tested by reconstruction, then corrected *in the smaller design's favour*

The architect named the smaller design (**S**, `≈ +36/−31`), wrote it out in full against real line
numbers, and conceded it satisfies **19 of 21 binding units including every one of AC-1…AC-15** —
claiming the extra code bought two constructible holes, M8 and M9.

**The gate tested that claim and struck half of it.** **M8 is real, but S covers it at zero added
lines** by opening its `try` two statements earlier — so M8 alone does not buy the envelope, and the
architect's section overstated it. **M9 was a conjecture, not a constructed hole** (the design's own
rationale conceded the band might be empty), and the gate could not measure it, so **C-11** sent it
to QA. **QA measured it and the band is EMPTY** — `copy.deepcopy` overflows at depth **498**,
`json.dumps(indent=2)` at **996**, `json.loads` at **9997**; `[996, 498)` has width **0**.

So the larger design's justification rests, in the end, on **FR-2's totality claim plus this
repository's own measured evidence that leaf enumerations at data boundaries ship incomplete** —
never on "two constructible holes". That correction is written into
`.harness/rejected-decisions.md` under **C-9**, so no future reader inherits the refuted phrasing.
The gate also rated the nearer alternative's refutation-by-provenance **rhetoric as written**, while
letting its conclusion stand on better evidence.

## R-61 honoured; the budget verified by a stage that could run `git`

The gate **checked K-16's derivation arithmetically instead of approving it** — removals summing to
exactly −65, the "32 mechanical" figure being the region's own line count — endorsed it with **two
written amendments** (E5's row itemised after ~5 lines of unaudited slack were found; the ±6
tolerance restricted to *added* lines), and the developer landed **0 added lines beyond the split**.
The developer also reported that its own re-indent measured **smaller** than the design's estimate,
because the design double-counted three replaced lines — reported rather than absorbed, which is
exactly what C-8 asks. Stage 5 was read-only at all three rounds and said so; **RES-5** carried the
`git` verification to stage 6, which confirmed the read-derived figures **exactly**.

## The R-22 trap, attacked at four stages

- **The gate** asked of each criterion "what is the smallest wrong build that passes this?" and
  found **five that could not detect what they claimed** — including **AC-2's clause (iv) being
  vacuous** without a pre-existing sentinel `config.json` (the clause carrying the entire R-22 gate),
  **AC-2's own stated entry point being unable to produce its own observables**, and **AC-7 as
  written being passed by a build with the type-check and no gating at all**. All amended in writing.
- **The developer** found AC-2's *control* wrong at the obvious key and ran both positions.
- **QA built six wrong builds and reported which criterion kills each.** W-C — right sentence, right
  exit code, **but writes first** — is killed by **clause (iv) alone, and only in the gate's amended
  sentinel form**. W-F (leaf enumeration) is killed by **M8 only**, which is the measured
  justification for C-10. And **W-D (`fault=str(e)`) is killed by nothing**: it survives all nine
  members. QA reported that as **NOT-DISCRIMINATING (QA-3)** rather than passing the criterion set —
  no criterion controls BC-4 at runtime; it holds by construction only. Re-homed to **T-28**.

## Hard constraints — all three prior hardenings survive

- **T-13 preserved.** `_write_private()` is untouched and remains the only writer of `config.json`;
  `mkstemp` → `fchmod` on the still-empty descriptor → write → `os.replace` is intact. The
  `json.dumps` hoist binds a string that already existed as that call's argument, so **no instant
  exists at which credential bytes sit behind a mode wider than `0600`** — traced by the reviewer
  and measured by QA.
- **T-14 preserved.** `_config_digest()` still hashes the file's **bytes**; the drift record is a
  64-hex digest and never a copy. **B-7 intact**: no call edge from `_apply_directive` back to
  `_merge`. **AC-8 intact**: `_filter_rules`'s body, signature and call-site argument lists are
  byte-identical (the gate's C-6 ruled that enclosing indentation is not "touching the call site",
  binding both designs symmetrically).
- **BC-3 met at the number that matters**: every malformed shape gives **exactly one line**, not a
  smaller pile of lines. The 2 999-line case is one line.
- **No credential, real or fixture, appears in any stage document.** `verify_all` A.1 PASS at every
  run.

## Live host untouched

`systemctl show -p MainPID -p ActiveEnterTimestamp` (never `is-active`) read `MainPID=2566751` /
`ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, `NRestarts=0`, at every stage boundary and at
this delivery checkpoint — identical throughout. `/etc/sing-box` and `/var/lib/sing-box` mtimes
predate the session. `/usr/local/bin/sc` was never invoked; every fixture neutralised the
import-time re-exec and no-op'd `_init_files()`. QA **read** the installed `.srs` rule-sets to build
a checker-valid fixture and wrote nothing there.

## Operator obligations

**AC-15 is BLOCKED by construction and nothing was substituted** — filed as
`.harness/operator-obligations.md` **id 5** with its recipe verbatim: install the new `bin/sc`,
place each malformed shape at `/etc/sing-box/override.json` in turn, run `sc reload`, and confirm
one line in `/var/log/sing-box/install.log`'s capture form, a non-zero status, and an unchanged
`config.json`. It needs root and the installed binary against the live service, which no agent here
may touch. **This is the eighth consecutive un-substituted operator obligation.** It carries the
standing **R-30** obligation with it: this change reaches the running host only when a human
installs the new `bin/sc`.

## Insight

- 2026-08-15 · The composed-document assertion already stops a wrong-typed overlay at `dns.rules` / `route.rules` / `route.rule_set` with one line and exit 1, so an R-22 control placed at those keys shows candidate and HEAD **identical on all four clauses** and certifies nothing — the silent-replacement-reaches-disk class is only reachable at an **unguarded** array key (`dns.servers`, `inbounds`, `outbounds`), where HEAD overwrites `config.json` and baselines its digest **before** the checker runs; and the run exits 0 only while `subprocess.run` is stubbed, because the real `sing-box check` then rejects the just-written document and exits 1, so the harm that survives un-stubbing is the overwrite plus the baselined drift record, never the exit code · evidence: override-error-envelope
- 2026-08-15 · `copy.deepcopy` overflows a nested-object document at depth **498** while `json.dumps(indent=2)` survives to **996** and `json.loads` (the C scanner) to **9997** on CPython 3.12.3 at `sys.getrecursionlimit() == 1000` — a factor of ~20, not the "roughly half" two upstream documents assumed — so the deep copy is what makes every deeper recursion position structurally unreachable through `override.json`, no single depth fixture can exercise two of them, and the three thresholds must each be bisected in a child interpreter rather than probed at a remembered number like 500 · evidence: override-error-envelope

## Next steps for the user

1. **Install the new `bin/sc` on the live host and run `sc reload`** — the change reaches the
   running installation no other way (standing R-30).
2. **Then discharge operator obligation id 5**, the one promise this task could not close by a run.
3. Nothing else is required. **No data migration and no compatibility window**: no on-disk format
   changed, and a downgraded build reads every document this build writes. A user whose
   `override.json` is valid today sees byte-identical output (measured: 24/24 settings and rule-set
   states, and all nine published recipes).

## Verdict

DELIVERED
