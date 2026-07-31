# Batch Plan — default

> Created: 2026-07-31
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | install-enable-start-split | Split `enable` from `start` in `install.sh` step 7 (both systemd and OpenRC branches) so autostart registration is unconditional and no optional-step failure can abort the installer under `set -e`. | full | — | pending |
| T-02 | config-degrade-missing-rulesets | Make `bin/sc` config generation degrade gracefully when `.srs` files are missing — drop the absent `route.rule_set` entries and the `route.rules` entries referencing them, per-file rather than all-or-nothing, and tell the user the mode degraded. | full | — | pending |
| T-03 | ruleset-mirror-fallback | Give `.srs` downloads an ordered multi-mirror base list with per-source fallback, `SRS`-magic + minimum-size content validation, atomic temp-file replacement, and `SB_RULES_BASE` / `--mirror` overrides. | full | — | pending |
| T-04 | install-error-surfacing | Stop swallowing installer errors: tee stderr to `/var/log/sing-box/install.log`, and branch the closing banner on install success/failure with a remediation command list and a non-zero exit, with matching zh/en `t()` strings. | full | T-01 | pending |
| T-05 | sc-doctor | Add a `sc doctor` command that prints binary+version, config syntax check, per-`.srs` presence and size, service active/enabled state, `sb-tun` interface and address, Clash API reachability, and current egress IP in one screen. | full | — | pending |
| T-06 | sc-config-show | Add `sc config --show` (with an optional `--redact` that masks node credentials) so `/etc/sing-box/config.json` can be inspected without root `grep`. | full | — | pending |
| T-07 | restricted-network-regression-test | Add a repeatable restricted-network regression test that blocks `github.com` / `raw.githubusercontent.com` in a container or VM, runs the full one-liner install, and asserts the five expected end-state conditions from the failure report. | full | T-01, T-02, T-03 | pending |

## Notes (optional)

- Decomposed T-01..T-07 (7 rows) ← "singbox-cli 安装故障复盘与修复清单 — P0-1/P0-2/P1-1/P2-1/P3-1/P3-3 + 回归测试" (2026-07-31)
- **P3-2 (timer `Persistent=true`) produced no row — the requirement is already satisfied.** The
  report marked it 待确认; verified 2026-07-31 that `systemd/sing-box-rules-update.timer` already
  contains `Persistent=true`, and `install.sh:320` installs that exact file to
  `/etc/systemd/system/`. Nothing to change.
- T-04 depends on T-01 because it consumes the `INSTALL_OK` state variable that T-01 introduces.
- T-07 depends on T-01/T-02/T-03 because it asserts their combined end state; it is the report's
  section 四 acceptance scenario made executable.
- T-02, T-03, T-05, T-06 are independent of each other and of T-01 — a failure in one must not
  block the others.
- Root cause context: a single optional resource (4 `.srs` files) failing to download cascaded into
  a dead service, no autostart, and a success banner that lied. T-01 and T-02 are the two
  independent breaks in that chain; either alone would have prevented the bricked install.
- Explicitly out of scope per the report's section 三: timeout values (`timeout=3` line 583,
  `timeout=8` line 742, `timeout=30` line 812) are correct and must NOT be enlarged — the failure
  was true unreachability, not slowness; sing-box binary install logic; sudoers scoping.

## Column reference

- **ID** — pool-local identifier (`T-NN`). Does NOT collide with repo-wide `docs/tasks.md` IDs.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`. Must be unique within the pool.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same pool, or `—` for none.
- **Status** — `pending` | `in-progress` | `done` | `failed` | `blocked` | `needs-human` | `skipped`.
  The skill writes; the user reads.
