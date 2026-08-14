# Delivery Summary

## Summary

- Task: `status-egress-via-clash-api` (T-18) — fix `sc status`'s egress-IP probe and its bare traceback.
  **The goal's first clause was refuted rather than implemented**; what shipped is one exception
  envelope at `clash_api()`, which discharges R-20 for all five call sites at once.
- Mode: full (7 stages)
- Stages traversed: 1 requirement-analyst → 2 solution-architect → 3 gate-reviewer → 4 developer
  (round 1) → 5 code-reviewer → 4 developer (round 2) → 6 qa-tester → 7 delivery. All 2026-08-14.
- Rollbacks: **1** — stage 5 → 4, for CR-1, a one-clause accuracy defect in the user-facing Chinese
  changelog bullet (it stated the `sc doctor` exit move as 2 → 1 for all five failure classes, but
  for the non-object-body class HEAD printed a *lying* `[正常]` row contributing 0, so that class
  moves 0 → 1). The reviewer offered a waiver; the PM declined it, because rule 85's
  「少就是多」 clause is explicitly about **published surface** and T-17's real defect was found
  exactly there. CR-6 (an elided verb in the new docstring) rode along as an in-place-only repair.
- Final verify_all result: **PASS** — `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, identical to the batch
  baseline measured independently by the PM before stage 1 and re-run at three checkpoints. Never
  lowered.
- Baseline changes: none. The project still has no committed test suite (R-9); `baseline.json` still
  reads `test_count: 0`; B.3 still SKIP. QA's 262-observation rig is uncommitted per R-9's standing
  ruling and its path is recorded in `06_TEST_REPORT.md`.
- Outstanding risks:
  - **AC-B1 / AC-B2 are BLOCKED, not passed and not substituted** — see the operator obligation below.
    This is the one place the promise is not yet closed by a run of the shipped invocation form.
  - Two MINOR findings ship known (CR-2 / RES-1, and QA-D2), plus three pre-existing families
    (QA-D1, QA-D3, QA-D5), each with a HEAD-side control proving it pre-existing.
  - BC-10's own state (every node accepts and never answers) was **not** reproduced — it needs
    node-side network conditions no fixture in this pipeline can create. Reported as unmeasured
    rather than as a pass.
- Files changed: 3 product files, **+15 / −7** (`bin/sc` +12/−6 — exactly K-9's ceiling;
  `docs/dev-map.md` +1/−1; `CHANGELOG.md` +2/−0), plus this task's 13 stage documents.
- Next steps for user: install the new `bin/sc` and run `sc reload` on the live host to receive the
  behaviour change (R-30's standing class — no agent on this project may touch `/usr/local/bin/` or
  the live service), and optionally discharge the AC-B1/AC-B2 operator obligation below.

## What shipped

`clash_api()` became **total**: a JSON object or `None`, never one of the three exception families
its own body raises, never another type.

```python
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            text = r.read().decode()
            answer = json.loads(text) if text else {}
    except (OSError, ValueError, http.client.HTTPException):
        return None
    return answer if isinstance(answer, dict) else None
```

`import urllib.error` became dead and was deleted; `import http.client` took its place, so the module
gained **no net import**. **No call site was edited** — all five were already correct against the new
contract, which is why one edit of a few lines closes `sc status`, `sc ls`, `sc use`, `sc mode` and
`sc doctor` together. A caller-side `try`/`except` at `cmd_status:2230` would have fixed one of six
symptoms and left `sc ls` — the command whose whole point is working on a broken host — still broken.

## The goal's first clause was a phantom, and refuting it was the task's largest saving

The batch goal asserted that the egress probe "cannot work in pure-TUN mode because it assumes a
local inbound that does not exist". Stage 1 refuted it with evidence (Q-1): `_egress_ip()` is one
`urlopen("https://api.ipify.org", timeout=8)` with no proxy argument, no `ProxyHandler` and no
`127.0.0.1`, and `git log -S ipify -- bin/sc` shows that same shape in the **first** commit of
`bin/sc` (`41ffd08`) and every commit since. In pure TUN the request is captured by the TUN device
like any other, so the probe reports the *proxied* address — the fact the section exists to show.
Measured at stage 6: `38.47.117.142`, agreeing with three independent echo endpoints.

AC-S1 then **froze `_egress_ip()` byte-identical** so no downstream stage could "fix" the phantom,
and stages 4, 5 and 6 each verified the freeze independently (AST-extract + sha256 against a HEAD
clone). Implementing the goal as written would have added a proxy path, a second address query or a
Clash endpoint, all for a defect that does not exist. This is the T-16 precedent applied
successfully: measure before designing against it.

The slug's own name was likewise declined (Q-4). Sing-box's Clash API reports no egress address; the
only endpoint that would touch the outside world (`/proxies/:name/delay`) returns a latency integer
and would be an active probe against the live service. Consuming it would also create a **second
opinion** about this host's public address, which `docs/dev-map.md` pins `_egress_ip()` to prevent.

## Decisions surfaced under the owner's standing grant

Per the T-17 precedent, a red-line-adjacent call ships on the standing grant **and is surfaced here**
rather than blocking the batch.

1. **Running product code against the live host (Q-13, ruled permitted by the gate).** AC-B1/AC-B2
   require observing `sc status` on this pure-TUN host, because R-22 exists precisely because T-15
   shipped 35 green criteria while the promise stayed wider than the behaviour. The gate ruled it
   permitted, not blocked, bounded by five preconditions and a before/after mtime+size witness. In
   the event the run was **blocked on a missing sudo credential** (below), and QA reported it blocked
   rather than substituting an artifact check — the correct call under NFR-5 and C-12.
2. **`sc doctor`'s exit status moves (C-1, C-2).** Making `clash_api()` total necessarily changes
   `sc doctor`: the Clash section stops collapsing to one `[UNKNOWN]` row and reports `[PROBLEM]`
   with the port row intact, so the run's exit moves **2 → 1 whenever no other section reports
   `[PROBLEM]`** (and **0 → 1** for the non-object-body class, which previously printed a lying
   `[正常]` row). The gate established this creates **no new user-visible contract**:
   `README.md:277-278` already publishes exit 1 = "an unanswered Clash API port", so the change moves
   the binary *onto* the contract the README already published. Disclosed in the changelog bullet.
3. **BC-14 widened at the gate rather than by a stage-1 round (C-1).** The change was already
   *entailed* by FR-2 and could not be avoided without a caller edit AC-S2 forbids, so a reopened
   stage 1 would have returned the same design.

## Operator obligation — AC-B1 / AC-B2 (the one promise not closed by a run)

All five NFR-3 host preconditions hold and were recorded first (`nodes.json`, `settings.json` with
`"clash_api_port": 29090`, `/var/lib/sing-box`, 29090 LISTEN, one `GET /configs`). The **enabling**
condition failed: `sudo -n true` → `sudo: a password is required`, and the QA agent has no
interactive terminal. Running non-root would have taken the import-time `os.execvp("sudo", …)` branch
into the **installed** `/usr/local/bin/sc` — the exact hazard the insight index warns about — so the
run was correctly not attempted.

**To discharge it**, on a sudo terminal, with a pre/post `find … -printf '%p %s %T@'` witness over
`/etc/sing-box/**` and `/var/lib/sing-box` plus
`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`:

```
sudo python3 /home/alan/Programs/singbox-cli/bin/sc status
```

and compare its egress line to an independent echo endpoint in the same minute.

**What was measured instead, and what it does and does not prove.** QA ran the candidate's
`cmd_status` against the **live** Clash API read-only (route mode read back as `Rule`, so the
observation is not degenerate) and it printed egress `38.47.117.142`, matching `ifconfig.me/ip`,
`icanhazip.com` and `api.myip.com`. Witness delta over both trees and the service: **none**
(`MainPID=2566751` before and after). So the *behavioural goal* — a correct egress IP and no
traceback on this pure-TUN host — is observed. What is not observed is the shipped invocation form
end to end as root through `main()`. QA reported that gap as blocked rather than papering over it.

## Evidence highlights

- **262 declared observations: 260 pass, 0 fail, 2 blocked** (AC-B1, AC-B2), plus 121 stability
  repeat-runs and 3 independent echo queries. Across 204 fixture runs: runs that talked to a port
  other than their own stand-in = **0**; runs that opened no Clash URL = **0**; runs that touched the
  live port = **0**. So all three vacuity traps (K-10, K-11, C-9/F-7) were live and all three were
  survived — the greens are not vacuous.
- **T-05's DEF-2 is closed (C-3), on evidence rather than argument.** With `DOCTOR_SECTIONS`
  restricted to the Clash section so the exit derives from it alone:
  `BC-1 candidate → exit=1, port row present, [OK] Clash API: 127.0.0.1:42713 | [PROBLEM] Clash API
  responding`; `BC-1 control (HEAD clone) → exit=2, port row absent, [UNKNOWN] this check could not
  run: timed out`.
- **R-20 is closed, and it was wider than filed.** R-20 enumerated four escaping classes; this task
  measured **six**. Stage 4 found the fifth (`ConnectionResetError`, from the `do_open` asymmetry),
  stage 6 found the sixth (`BadStatusLine`, which is neither an `OSError` nor a `ValueError`). Two of
  six leaves were unknown to the pipeline until the last stage ran — the strongest possible argument
  for the family tuple K-1 chose over the leaf enumeration it rejected.
- **`sc ls` is genuinely fixed by the same one edit**, traced first-hand at stage 5 through
  `cmd_ls` → `stored_delays()` → `clash_api()`. `stored_delays()` carries no `try`/`except` by
  deliberate design, so at HEAD every one of those classes propagated through `cmd_ls` before a single
  table row printed.
- **A promise already in the tree became true (CR-7).** `CHANGELOG.md:11`'s pre-existing `sc ls`
  bullet promised "API 不通或返回内容异常时表格照常打印、不会抛 Python 报错". That was **false at
  HEAD** for the invalid-JSON, invalid-UTF-8 and short-body states, and this change makes it true.
  Both bullets ship in the same unreleased block, so the release is self-consistent.
- **Rule 85's burden of proof was met and then tested.** Stage 2 named `except Exception` as the
  *smaller* rejected alternative (one word, no import, one line smaller) and stated what the extra
  line buys: a genuine defect inside `clash_api()` stays a traceback instead of being reported as
  `[PROBLEM] Clash API responding` — `sc doctor` lying about the host to cover a bug in `sc`. Stage 3
  tested that answer against the installed stdlib and `README.md:268` rather than accepting it, and
  found the design **correct in code but wrong in published surface** — the same shape of finding as
  T-17's, and the origin of C-8.
- Live service provably untouched throughout: `MainPID=2566751` /
  `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` byte-identical before and after, never
  `is-active`. `/usr/local/bin/sc` never invoked. The only live-port traffic in the entire pipeline
  was two read-only `GET /configs`.

## Insight

- 2026-08-14 · `urllib.request.AbstractHTTPHandler.do_open` wraps only `h.request()`'s `OSError` into `URLError` and bare-re-raises everything `h.getresponse()` raises, so `except (URLError, HTTPError)` misses a peer that resets or closes early — a plain RST gives `ConnectionResetError`, a clean FIN with no response gives `RemoteDisconnected`, and a malformed status line gives `BadStatusLine`, which is neither an `OSError` nor a `ValueError` · evidence: status-egress-via-clash-api
- 2026-08-14 · `urlopen(timeout=N)` bounds each socket operation, never the call's total wall clock: a peer dripping one body byte every 2 s keeps a `timeout=3` request alive **30.1 s** and then returns success, so any "it gives up after N seconds" claim about `clash_api()` or `_egress_ip()` is false as written · evidence: status-egress-via-clash-api
- 2026-08-14 · `main()` reassigns **`CLASH_PORT`** after import exactly as it reassigns `LANG`, so a fixture whose `settings.json` omits `clash_api_port` gets a port that is free *by construction* and the whole Clash-failure matrix silently degrades to "nothing listening" on candidate **and** control — the twin of the `LANG` vacuity trap, and it needs the port recorded in the fixture's own `settings.json` · evidence: status-egress-via-clash-api
- 2026-08-14 · `cmd_status`'s `print()` is block-buffered when stdout is a pipe while its `subprocess.run(["ip", …])` children write fd 1 immediately, so `sc status > file` puts the `ip` output **above** `=== Service status ===` — the reordering hits exactly the redirected bug-report case, and `_doctor_print()` already flushes per row for this reason · evidence: status-egress-via-clash-api

## Verdict

DELIVERED
