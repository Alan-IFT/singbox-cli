# Delivery Summary

- **Task:** `install-binary-download-progress` (pool T-08) — show real download progress for the
  sing-box binary tarball in `install.sh`, degrading to a quiet single-line notice off a TTY.
- **Mode:** `full` (7 stages)
- **Baseline commit:** `90ad762` (`fix(sc): restart sing-box only when a rule-set actually changed`)
- **Delivered:** 2026-08-01 — **uncommitted**; the owner handles commit and push.

## Stages traversed

| # | Stage | Agent | Outcome |
|---|---|---|---|
| 1 | Requirement | requirement-analyst | `READY` — 12 behaviours, 20 AC, 18 BC, 10 recorded decisions, 0 open questions |
| 2 | Design | solution-architect | Design complete; reported requirement defect **R-D** (non-blocking) |
| 1' | Requirement (correction) | requirement-analyst | R-D verified + retracted; D-11/D-12/D-13 added; live bug re-homed |
| 3 | Gate | gate-reviewer | **`APPROVED FOR DEVELOPMENT`** — 0 FAIL / 6 WARN / 4 INFO, conditions C-1…C-8 binding |
| 4 | Development | developer (single mode) | `READY FOR REVIEW` — C-1…C-8 discharged, `verify_all` 16/0/0/2 |
| 5 | Code review | code-reviewer | **`APPROVED`** — 0 CRITICAL / 0 MAJOR / 2 MINOR / 5 NIT |
| 6 | QA | qa-tester | **`PASS`** — 39 scripted assertions + 5 ad-hoc probes, 0 product defects |
| 7 | Delivery | PM | this document |

Exact wall-clock times were not captured per stage; all seven stages ran on 2026-08-01.

## Rollbacks

**1 rollback** (stage 2 → stage 1, targeted correction).

The architect found that one of the three justification legs for **D-5** (the GitHub API version
query stays meter-free) was factually wrong. Per hard rule 2 the analyst — not the architect — owns
its own document, so it was routed back with a fenced scope. The analyst verified the claim against
the real source rather than accepting the report, confirmed it, and sharpened it twice.

The design was **not** re-dispatched: every correction ratified a reading the design had already
adopted, so a revision pass would have produced a byte-identical document. The gate reviewer was
explicitly asked to audit that routing call and **upheld it** after checking all seven corrected
items independently.

## Final `verify_all` result

**PASS 16 / WARN 0 / FAIL 0 / SKIP 2** — re-run by QA against the working tree, with a pristine
`HEAD` **clone** producing an identical result. **Delta: 0.**

QA recorded a methodology warning worth keeping: a `git worktree` is **not** a valid pristine
baseline in this repo — `.git` is a file there, A.1/A.2 turn SKIP, and the summary falsely reads
`14/4`. A clone is required.

## Baseline changes

No test-count delta. `.harness/scripts/baseline.json` remains at `test_count: 0` — the project still
has no committed test suite (`verify_all` B.2/B.3 are SKIP), unchanged across all five delivered
tasks. QA deliberately did not edit it inside a task whose AC-19 pins the shipping diff; see
Outstanding risks.

## Files changed

**Shipping diff (product paths) — 2 files, +27 / −3:**

```
 CHANGELOG.md |  2 ++
 install.sh   | 28 +++++++++++++++++++++++++---
 2 files changed, 27 insertions(+), 3 deletions(-)
```

`install.sh` gained a download flag policy block at `:116-132` — `CURL_OPTS_QUIET=(-f -s -S -L)`
(literally today's `-fsSL`) and `CURL_OPTS_PROGRESS`, which is the same array off a terminal and
`(-f -S -L --progress-bar)` on one, selected by the file's **only** `[ -t 2 ]` at `:130`. The three
curl call sites now consume it: `:345` artifact loop (quiet), `:373` version query (quiet), `:384`
tarball (progress). One new `t()` key `fetching_item` at `:149` (zh) and `:193` (en). Exactly three
lines were replaced — the three pre-change `curl` lines.

**Also modified (pipeline memory, carved out of AC-19 by D-12, not product):**

```
 .harness/rejected-decisions.md | 70 ++++++++++
 CONTEXT.md                     | 13 +++++
```

Plus the untracked stage-document folder `docs/features/install-binary-download-progress/`.

## What the owner asked for, and what shipped

The requirement was 「每个下载部分」 — *every* download shows progress. Every download in
`install.sh` was assessed and the silence of each remaining one is **justified in writing**, not
skipped:

- **Tarball** (`:384`, tens of MB, the largest transfer) — curl's own `--progress-bar`. This is the
  answer to "I can't tell when it will finish".
- **Five remote artifacts** (`:345`, the first thing a `curl | bash` install does) — one name line
  each, no byte meter. Their real uncertainty is *which one is stalled*, which a name line answers;
  a meter on a 7-line unit file shows one instantaneous state.
- **GitHub API version query** (`:373`) — deliberately meter-free. Its body goes into a command
  substitution, so its cost is connection setup rather than transfer, and the notice line acts as a
  boundary marker: a stall *before* it is the API query, a stall *after* it is the tarball.

Off a TTY, all of it degrades to one quiet line naming the resolved version and architecture.

## Outstanding risks

Nothing blocking. Five items are carried, none of them a defect in what shipped:

1. **F-11 — the committed bilingual key-parity gate is now four tasks deep.** `install.sh`'s `t()`
   declares `local fmt` with no default, so a key present in only one language branch aborts the
   whole installer under `set -u`, and the zh branch is reachable only by answering `2`. Parity is
   proven **today** (41 keys, both tables, verified independently at stages 4, 5 and 6), but the
   proof is not committed, so the hazard is exactly as shippable for the next task. The code reviewer
   calls this "the highest-leverage open debt touching this file". AC-19 forbade fixing it here.
2. **The version-query silent abort** (`install.sh:373-381`). Under `set -euo pipefail`,
   `SB_VER=$(curl … | grep … | sed …)` aborts *at the assignment* on HTTP 403/404 or transport
   failure, so the bilingual `download_failed` / `check_network` handling below it never runs **and
   `install_report()` never runs** — the installer can terminate having stated no outcome, which is
   the exact property T-01 exists to guarantee. GitHub's unauthenticated rate limit makes this
   routine. Found at stage 2, verified at stage 1', filed in `.harness/rejected-decisions.md`,
   deliberately not fixed here (it changes failure behaviour that AC-6/AC-14 pin as unchanged).
   **Recommend the owner number this as a pool row.**
3. **Two test-infrastructure defects routed to T-07**, which inherits the harness: `gate_checks.sh`
   writes `faults.json` while `server.py` reads `control.json` (re-run as shipped it gives a false
   FAIL), and AC-3's non-vacuity is carried by the server **throttle**, not the 8 MiB fixture size,
   with no guard protecting it.
4. **Step 6's rule-set progress is still invisible during an install** (`install.sh:456` redirects
   `sc update-rules` to `$LOG_SINK`). This is the one place the owner's original symptom can recur
   unchanged. The reason is structural, not preference: un-redirecting breaks T-01's log-capture
   design and a `tee` is barred by insight L12. Filed with an unblock path.
5. **`docs/dev-map.md` has no row for the new `CURL_OPTS_*` seam.** Deliberate: dev-map is not in
   AC-19's carve-out, so editing it would have been a literal breach of the criterion the gate made
   binding. The one-line row belongs to **T-07**, which owns the next edit to these flags.

## Safety — live system untouched

Verified three times independently (developer, QA, and PM at delivery) with
`systemctl show -p MainPID -p ActiveEnterTimestamp` — never `is-active`, per insight L22:

| | MainPID | ActiveEnterTimestamp |
|---|---|---|
| before | `2500438` | `Fri 2026-07-31 17:04:23 CST` |
| after | `2500438` | `Fri 2026-07-31 17:04:23 CST` |
| at delivery | `2500438` | `Fri 2026-07-31 17:04:23 CST` |

`install.sh` was never executed end to end. Only comment-anchored fragments ran, as uid 1000, never
root, on a `PATH` rebuilt without `/usr/local/bin`, with `systemctl` / `sudo` / all six package
managers stubbed to abort loudly — **none fired**. `/usr/local/bin/{sc,sing-box}` retain their
pre-task mtimes. Insight L13's incident class did not recur.

## Verification highlights

- **The curl 7.29 option floor was settled against the real artifact, twice.** The developer fetched
  the official curl 7.29.0 release tarball, version-dated it from `include/curl/curlver.h:33`/`:67`,
  and found `--progress-bar` at `src/tool_getparam.c:260`. The code reviewer re-verified off the
  same tree independently. This was the package's highest-consequence claim: an unknown option makes
  curl exit 2 and would kill step 2 on every RHEL/CentOS 7 host, invisibly on a modern box.
- **The design's central claim was falsified on demand.** BC-3 (stdout is a TTY, stderr redirected)
  → zero `0x0D`; the negative control that forces the progress array past the gate fires at 26.
  `script -qec` cannot express BC-3 at all and was correctly refused in favour of a real `openpty`
  driver.
- **Six vacuous greens were caught rather than shipped** — three by the developer on its own harness
  (one had already produced a *false PASS*), one latent defect found by QA, and two in QA's own new
  work, discarded before reporting.

## Next steps for the user

1. Review the two-file product diff and commit; nothing was committed or pushed.
2. Number risk item 2 (the version-query silent abort) as a pool row — it is a real T-01 blast-radius
   defect that this task deliberately did not absorb.
3. Decide whether to promote risk item 1 (committed key-parity gate) into T-07 or its own row; it has
   now been deferred four tasks running.

## Insight

- 2026-08-01 · The `curl-7_29_0` git tag is not a valid version-dated source for option-floor claims — `curlver.h` at that tag still reads `7.28.2-DEV`; only the released `curl-7.29.0.tar.gz` (now under `curl.se/download/archeology/`, the plain `download/` path 404s) dates itself correctly · evidence: install-binary-download-progress
- 2026-08-01 · A `git worktree` is not a valid pristine baseline for `verify_all.sh` in this repo — `.git` is a *file* in a worktree, so A.1/A.2 turn SKIP and the summary falsely reads `14/4` instead of `16/2`; use a clone · evidence: install-binary-download-progress
- 2026-08-01 · A progress-redraw fixture's non-vacuity is carried by the server's **throttle**, not the body size — an 8 MiB body with `sleep=0` yields `states=1` exactly like a 1 KiB body, which refines the earlier chunk-size reading of this same trap · evidence: install-binary-download-progress
- 2026-08-01 · Under `set -euo pipefail` a bare `VAR=$(cmd | grep …)` assignment aborts the script *at the assignment* when the pipeline fails, so `install.sh:373`'s version query bypasses its own `download_failed`/`check_network` handler **and** `install_report()` — the installer can exit having stated no outcome at all · evidence: install-binary-download-progress
