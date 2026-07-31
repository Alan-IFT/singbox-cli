# Batch Plan — default

> Created: 2026-07-31
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | install-enable-start-split | Make `install.sh` report its true outcome — register autostart unconditionally, surface real errors to `/var/log/sing-box/install.log`, and derive an honest closing banner plus exit code from collected phase status. | full | — | in-progress |
| T-02 | config-degrade-missing-rulesets | Introduce one ruleset-resource abstraction in `bin/sc` — availability-and-validity detection plus validated multi-mirror atomic fetch with per-file byte/percent download progress — and have config generation degrade from it, dropping absent rule-sets per-file with a clear user warning. | full | — | pending |
| T-03 | ruleset-mirror-fallback | ~~Multi-mirror download with validation~~ — **merged into T-02**; the mirror/validation/atomic-write logic and the availability check are one abstraction, not two. | full | — | skipped |
| T-04 | install-error-surfacing | ~~Error surfacing + honest banner~~ — **merged into T-01**; setting a status flag and acting on it are one design, not two tasks. | full | T-01 | skipped |
| T-05 | sc-doctor | Add a `sc doctor` command that prints binary+version, config syntax check, per-`.srs` presence and size, service active/enabled state, `sb-tun` interface and address, Clash API reachability, and current egress IP in one screen. | full | T-02 | pending |
| T-06 | sc-config-show | Add `sc config --show` (with an optional `--redact` that masks node credentials) so `/etc/sing-box/config.json` can be inspected without root `grep`. | full | — | pending |
| T-08 | install-binary-download-progress | Show real download progress for the sing-box binary tarball in `install.sh` step 2 by replacing `curl -fsSL` with a progress-emitting invocation, degrading to a quiet single-line notice when stdout is not a TTY. | full | — | pending |
| T-07 | restricted-network-regression-test | Add a repeatable restricted-network regression test that blocks `github.com` / `raw.githubusercontent.com` in a container or VM, runs the full one-liner install, and asserts the five expected end-state conditions from the failure report. | full | T-01, T-02 | pending |

## Notes (optional)

- Decomposed T-01..T-07 (7 rows) ← "singbox-cli 安装故障复盘与修复清单 — P0-1/P0-2/P1-1/P2-1/P3-1/P3-3 + 回归测试" (2026-07-31)
- **Consolidated 2026-07-31 on the owner's directive 「优先用好的设计，避免不断的修修补补」.** The
  original decomposition mirrored the report's patch list, which contained two patch-then-patch
  seams. Both are now merged; no scope was dropped, only re-homed:
  - **T-04 → T-01.** T-01 computed `INSTALL_OK` and T-04 consumed it. Delivering T-01 alone would
    have shipped an installer that computes its own failure and still prints ✅ 安装完成 — the exact
    defect being fixed. One task: "install.sh reports its true outcome."
  - **T-03 → T-02.** T-02 needed "is this ruleset usable?" and T-03 defined what a valid ruleset
    file is (SRS magic, minimum size). Split, T-02 would have shipped a bare `path.exists()` that
    T-03 then had to revisit — and a mirror returning an HTML error page would read as "present".
    One task: one ruleset-resource abstraction that both config generation and download use.
- **Download progress (2026-07-31, owner: 「看不到每个下载部分的进度条，不知道什么时候能完成」)** —
  split by code region, not by symptom, per `.harness/rules/85-design-discipline.md`:
  - **Ruleset progress → folded into T-02** (not a new row). `bin/sc:804-825` currently does
    `tmp.write_bytes(r.read())` — a single blocking read, so progress requires chunking the fetch
    loop. T-02 already rewrites that exact loop for mirrors + validation + atomic replace. A
    separate progress row would rewrite the same function twice.
  - **Binary progress → T-08** (new row). `install.sh:274` uses `curl -fsSL "$SB_URL"`; the `-s`
    silences curl's own meter. Different file, different language, and a different step from the
    one T-01 is rewriting, so there is no shared seam to preserve.
  - **Shared design constraint for both:** progress output must degrade when stdout is not a TTY.
    This is not cosmetic — `sc update-rules` runs from the weekly systemd timer, so an unguarded
    progress bar would write carriage-return spam into the journal. Gate on `sys.stdout.isatty()`
    / `[ -t 1 ]` and fall back to a single completion line. The two implementations cannot share
    code (Bash/curl vs Python/urllib) but must share the visual language.
  - Note the existing ruleset code already writes to `.tmp` then `.replace()` — T-02's atomic-write
    requirement is partly satisfied already; keep it rather than reinventing it.
- **P3-2 (timer `Persistent=true`) produced no row — the requirement is already satisfied.** The
  report marked it 待确认; verified 2026-07-31 that `systemd/sing-box-rules-update.timer` already
  contains `Persistent=true`, and `install.sh:320` installs that exact file to
  `/etc/systemd/system/`. Nothing to change.
- T-05 now depends on T-02: `sc doctor` should report ruleset health by reading the same
  availability/validity model T-02 introduces, not by re-implementing a second opinion of it.
- T-07 depends on T-01/T-02 because it asserts their combined end state; it is the report's
  section 四 acceptance scenario made executable.
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
