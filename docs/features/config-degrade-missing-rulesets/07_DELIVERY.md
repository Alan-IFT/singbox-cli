# Delivery Summary

- **Task**: `config-degrade-missing-rulesets` (T-02) — a `.srs` rule-set is an optional routing
  optimization and must never be a hard dependency of the sing-box service starting.
- **Mode**: full (stages 1-7)
- **Dispatched under**: a stream, `deferred-human mode: defer, do not ask`. No human question was
  raised at any stage; no point requiring human authorization was auto-decided.

## Stages traversed (all 2026-07-31)

| # | Stage | Agent | Verdict |
|---|---|---|---|
| 1 | Requirement analysis | requirement-analyst | READY — 26 behaviors, 32 boundary conditions, 27 ACs, 9 open questions each with a recommended resolution |
| 2 | Solution design | solution-architect | READY |
| 3 | Gate review | gate-reviewer | **APPROVED FOR DEVELOPMENT**, 9 WARN conditions |
| 4 | Development | developer | READY FOR REVIEW — `verify_all` 16/0/0/2 |
| 5 | Code review | code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 6 MINOR, 8 NIT |
| 6 | QA | qa-tester | **ROLLBACK: developer** — D-1 (MAJOR) |
| 6a | Design amendment A-1 | solution-architect | READY |
| 6b | Development (fix) | developer | READY FOR REVIEW |
| 6c | Code review (delta) | code-reviewer | **APPROVED** — 0 CRITICAL, 0 MAJOR, 1 MINOR, 2 NIT |
| 6d | Design amendment A-2 | solution-architect | READY |
| 6e | Development (A-2) | developer | READY FOR REVIEW |
| 6f | QA re-test | qa-tester | **PASS** — 846/846 assertions, 0 failed |
| 7 | Delivery | PM | this document |

## Rollbacks: 2 (both design-origin, distinct causes)

1. **D-1 (MAJOR), QA → architect → developer.** The download loop appended per-base failure causes
   inside `except`, but the success path did `print(OK); break` and discarded them, so the
   enumeration printed only on total failure. A base serving an HTML error page while a later base
   succeeded produced four clean `OK` lines and an empty stderr — **a broken mirror shipped
   invisibly**, which is the common case on the target network and exactly what gate finding F-7
   warned about. QA routed it to the developer; I routed it to the **architect** instead, because
   §6.2's pseudocode already discarded the causes on `break` — the developer had implemented the
   approved design faithfully, so it was a design gap, and only its author may close it.
   Closed by **Amendment A-1**: two lists, `causes` (unchanged, total-failure line) and `tried`
   (bases actually contacted and rejected *for this file*, dead-skips excluded), rendered by the
   same `print` onto the same completion line.
2. **zh grep collision (MINOR), delta review → architect → developer.** A-1's zh string contained
   `失败：` — the exact diagnostic grep meaning "this rule-set was NOT updated" — so a *successful*
   line matched it in Chinese, defeating a protection the design had declared load-bearing one
   document earlier. Closed by **Amendment A-2** (`前序镜像未成功：`). The reviewer rated it
   non-blocking; I routed it back anyway because QA had to re-run regardless, so fixing it first
   cost one token and let QA validate the final state once.

The three-consecutive-rollback stop was never approached.

## Final verify_all result: **PASS**

`PASS: 16 / WARN: 0 / FAIL: 0 / SKIP: 2`, exit 0 — re-run independently by QA at the final state,
not inherited from the developer. Delta against baseline: **0**.

## Baseline changes

None. `baseline.json` still records `test_count: 0`; `[B.2] Tests` and `[B.3] Lint` remain the two
pre-existing SKIPs. This task deliberately commits **no** tests — adjudicated at requirement Q8 and
gate V-9, recorded in `.harness/rejected-decisions.md`, and handed to **T-07**, which owns the
committed harness. QA's throwaway harness (11 files, 846 assertions, including a cross-revision
runner that loads `main:bin/sc` as a second module for byte-identity comparison) is recommended for
T-07 to inherit in preference to the developer's.

## What was proven, not asserted

- **The reported failure is gone, demonstrated side by side.** With the same empty rules directory,
  `main`'s `generate_config()` returns `False` with
  `FATAL initialize router: parse rule-set[0]: open …/geoip-cn.srs: no such file or directory`,
  while the worktree returns `True` under real `sing-box` 1.13.15 — keeping nodes, TUN, DNS and
  `final: "proxy"`, so the service starts and traffic proxies with only routing granularity lost.
- All **16** usable/unusable subsets are closed under `referenced ⊆ defined` *and*
  `referenced == usable`, and real `sing-box check` accepts all 16 including the all-dropped case
  (this closed design risk R2 rather than deferring it).
- The all-usable config and the happy-path stdout are **byte-identical** to `main`.
- A real 30 s socket-timeout run cost 30.1 s total, not 4×30 — the multi-mirror time budget holds in
  execution, with no timeout constant changed (still 30 / 3 / 8).
- Scope asserted with a **real byte diff**: `install.sh`, `uninstall.sh` and all three `systemd/*`
  are SHA-256-identical to `main`.

## Outstanding risks

- **Four items remain honestly unverified** (QA marked them rather than passing them silently):
  BC-25 and the D-2 escalation need a real root/sudoers host (QA ran at euid 1000); AC-26 needs a
  real Python 3.6 interpreter (this box has 3.12.3 only); BC-32.
- **No network-restricted VM exists**, so the mainland-China reproduction itself was never re-run
  end to end. T-07 owns that. Mitigation: network *was* available here, so all four mirror bases
  were fetched from for real and return byte-identical content (closing gate F-7), and the smallest
  real rule-set was measured at **696 bytes**, which validates the 16-byte floor against its binding
  constraint.
- **`--mirror` crosses the sudo boundary** (found independently by the code reviewer and QA): argv
  survives the auto-elevate re-exec even though the environment does not, and `urlopen` accepts
  `file://`. Privilege impact assessed as negligible — the same caller can already run `sc add` /
  `sc off` as root — but the requirement's security NFR is stale, and a scheme allow-list is worth
  a row. Deliberately not fixed here: it exceeds B-14/BC-24 as the gate approved them.
- **Known non-defects, recorded so they are not re-litigated**: `install.sh` re-runs now restart the
  service twice (F-8, expected); a gzip-encoding mirror would be rejected as "not a rule-set file"
  from every base (F-6 signature, left diagnosable on purpose); a local disk fault is reported as a
  mirror failure and now leaks the temp path onto a *success* line too (D-4's widened surface).

## ⚠️ Live-system incident (owner should read this)

The developer disclosed, unprompted, that a first sandbox attempt failed to neutralise the
auto-elevate block at `bin/sc:77-78`. It re-execs the **installed** `/usr/local/bin/sc` under sudo,
and sudo's `env_reset` discards `SB_RULES_BASE` — so **one real `sc update-rules` ran on this
machine against the built-in mirrors and restarted `sing-box`**. Assessed as idempotent maintenance:
service re-checked `active`/`enabled`, all four rule-sets present and fresh, no repository file
affected, `__pycache__` debris removed, and all reported results come from the corrected sandbox.
QA independently confirmed at the final state that `systemctl show sing-box` reports `NRestarts=0`
with `ActiveEnterTimestamp` still that single restart, unchanged across its whole pass.

Root cause of the process gap: gate condition F-3 required neutralising `systemctl`/`rc-service` in
the **QA** harness, and QA complied with both techniques — but nothing imposed the same discipline
on a *developer's* throwaway verification script. That asymmetry is the real defect, and the insight
below exists so it does not recur.

## Files changed (working tree left dirty and uncommitted, per owner instruction)

Product diff — exactly the four files design §2 permits:

- `bin/sc` — the one rule-set model (`SRS_MAGIC`, `SRS_MIN_BYTES`, `srs_reject_reason` plus its
  path / socket / screen adapters), per-file config degradation through a single `_filter_rules`
  applied to **both** `dns.rules` and `route.rules`, the ordered multi-mirror validated chunked
  downloader with `--mirror` / `SB_RULES_BASE`, TTY-gated progress, and the `cmd_update_rules`
  recovery path. 12 new zh translation entries; both help blocks; both READMEs' matching sections.
- `CHANGELOG.md`, `README.md`, `README.zh-CN.md`

Repository bookkeeping (outside AC-25's product diff, per gate F-9):

- `docs/dev-map.md` — filled in from its unused template: `bin/sc`'s section map, the rule-set
  utilities, and the harness gotchas that cost this task two sandbox accidents.
- `docs/features/config-degrade-missing-rulesets/` — stage docs 01-07 + `PM_LOG.md`
- `docs/tasks.md`, `.harness/rejected-decisions.md`

*(No `git diff --stat` line counts: the PM session has no Bash tool. File list is taken from the
stage reports, each of which verified the product diff independently — QA with a real byte diff.)*

## Next steps for user

1. **Review and commit.** Nothing was committed or pushed, as instructed.
2. **Run `.harness/scripts/archive-task.sh --task config-degrade-missing-rulesets`** — the PM
   session has no Bash tool, so this could not be run. It harvests the `## Insight` section below
   into `.harness/insight-index.md` and moves the stage docs to `docs/features/_archived/`. The
   section is formatted for that harvest; I did not hand-write the index, per the contract in
   `.harness/rules/05-insight-index.md`.
3. **File the follow-up pool rows** accumulated here (details and line numbers in `PM_LOG.md`):
   Python-floor violations at **five** sites — `capture_output=` at `bin/sc:822`, `:864`, `:1159`
   plus `text=True` at `:822`, `:1159` (the requirement doc's count of two was wrong; the gate found
   the third and the reviewer the rest); the `TRANSLATIONS`-has-no-`en`-table defect that makes a
   namespaced key print literally (`bin/sc:642`-class); the `--mirror` sudo/scheme hardening; D-4
   (local disk fault reported as a mirror failure, now on two output surfaces); D-5 (stray blank
   line); and the `_temp_path` prefix coupling.
4. **T-07** inherits the restricted-network verification, the four unverified items, and QA's
   846-assertion harness.

### Entropy watch

Not run, and correctly so: this project's `.harness/scripts/` contains no `entropy-cadence` pair,
so the cadence check resolves to **NOT-DUE** under its documented fail-open rule. No scan was
dispatched and no findings section is emitted. The delivery verdict is unaffected either way.

## Insight

- 2026-07-31 · `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc`, not the file under test, and sudo's `env_reset` silently drops `SB_RULES_BASE` — so an un-neutralised test import does not fail, it runs the *installed* tool against the *live* service · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `http.client.HTTPResponse.read(n)` blocks until it has all `n` bytes, so a 64 KiB chunk loop emits exactly one progress redraw for any body under 64 KiB — progress fixtures must exceed the chunk size or they assert nothing · evidence: config-degrade-missing-rulesets
- 2026-07-31 · The smallest real MetaCubeX rule-set (`geosite-private.srs`) is 696 bytes, and all four configured mirror bases return byte-identical content · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `失败：` in `bin/sc` output is a load-bearing diagnostic grep meaning "this file was not updated"; any new zh string must avoid it, and `已跳过（…已失败）` is safe only because dead-skips never reach a success line · evidence: config-degrade-missing-rulesets
