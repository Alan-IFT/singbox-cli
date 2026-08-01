# Batch Plan — default

> Created: 2026-07-31
> Default mode: full
> Stop policy: strong-signal-only

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-01 | install-enable-start-split | Make `install.sh` report its true outcome — register autostart unconditionally, surface real errors to `/var/log/sing-box/install.log`, and derive an honest closing banner plus exit code from collected phase status. | full | — | done |
| T-02 | config-degrade-missing-rulesets | Introduce one ruleset-resource abstraction in `bin/sc` — availability-and-validity detection plus validated multi-mirror atomic fetch with per-file byte/percent download progress — and have config generation degrade from it, dropping absent rule-sets per-file with a clear user warning. | full | — | done |
| T-03 | ruleset-mirror-fallback | ~~Multi-mirror download with validation~~ — **merged into T-02**; the mirror/validation/atomic-write logic and the availability check are one abstraction, not two. | full | — | skipped |
| T-04 | install-error-surfacing | ~~Error surfacing + honest banner~~ — **merged into T-01**; setting a status flag and acting on it are one design, not two tasks. | full | T-01 | skipped |
| T-05 | sc-doctor | Add a `sc doctor` command that prints binary+version, config syntax check, per-`.srs` presence and size, service active/enabled state, `sb-tun` interface and address, Clash API reachability, and current egress IP in one screen. | full | T-02 | done |
| T-12 | dns-block-aaaa-query-type | ~~AAAA suppression~~ — **merged into T-16**; it is one `query_type` entry in the same DNS block T-16 restructures, and the live hand-patch it rescues is the same change. | full | — | skipped |
| T-06 | sc-config-show | Add `sc config --show` (with an optional `--redact` that masks node credentials) so `/etc/sing-box/config.json` can be inspected without root `grep`. | full | — | pending |
| T-09 | fix-rules-update-execstart | Fix `systemd/sing-box-rules-update.service`, whose `ExecStart` invokes the non-existent `/usr/local/bin/proxy` so the weekly ruleset auto-update has never run at all (203/EXEC), pointing it at the installed `sc` binary. | full | — | done |
| T-10 | ruleset-update-no-needless-restart | Stop `sc update-rules` from restarting sing-box when no rule-set actually changed, so the now-live weekly timer no longer drops every connection each Monday; prefer hot-apply over restart per the project's own convention. | full | — | done |
| T-08 | install-binary-download-progress | Show real download progress for the sing-box binary tarball in `install.sh` step 2 by replacing `curl -fsSL` with a progress-emitting invocation, degrading to a quiet single-line notice when stderr is not a TTY. | full | — | done |
| T-11 | install-version-query-abort | Fix `install.sh`'s sing-box version query, where `VAR=$(pipeline)` aborts at the assignment under `set -e` and so bypasses both its own error handler and `install_report()` — letting the installer exit having stated no outcome, the exact property T-01 exists to guarantee. | full | — | done |
| T-13 | config-write-permission-hardening | Close the credential-exposure window when writing `config.json` — create the file 0600 from the start instead of `write_text` then `chmod`, apply the same to any backup it writes, and have `install.sh` verify permissions across `/etc/sing-box/` at the end. | full | — | done |
| T-14 | config-composition-layer | Turn config generation from one hardcoded dict into a composition — base template as data, ordered overlays, then a user override file — with explicit array `$prepend`/`$append`/`$replace` semantics and drift detection, under the hard constraint that with no override present the emitted config is **byte-identical** to today's. | full | — | done |
| T-15 | proxy-urltest-group | Make the `proxy` tag always point at a `urltest` group rather than a concrete node, so a single flaky node has a failover path, and surface per-node latency from the Clash API in `sc ls`. | full | T-14 | pending |
| T-16 | dns-resilience | Stop a single flaky node from killing all name resolution: add a non-proxied fallback resolver, converge the 10s DNS timeout, and suppress AAAA when the host has no global IPv6 (`sc ipv6 on/off/auto`) — expressed as overlays on T-14's layer, not as edits to a hardcoded dict. | full | T-14 | pending |
| T-17 | telemetry-reject-list | Ship the common-telemetry DNS reject list as an opt-out overlay on T-14's layer — after T-14 and T-16 this should be close to data plus a toggle, not new machinery. | full | T-14, T-16 | pending |
| T-18 | status-egress-via-clash-api | Fix `sc status`'s egress-IP probe, which cannot work in pure-TUN mode because it assumes a local inbound that does not exist, and report a bare traceback when it fails. | full | T-15 | pending |
| T-19 | ruleset-staleness-visibility | Make stale rule-sets loud: report each file's age in `sc status`, and make the systemd timer actually fail when updates fail instead of only printing. | full | — | pending |
| T-20 | doctor-extended-checks | Extend `sc doctor` with the checks that need features landing after it — rule-set age, per-node latency, DNS timing, config drift, file permissions, and IPv6 consistency — each reported as a conclusion with a next step. | full | T-05, T-13, T-14, T-15, T-16 | pending |
| T-21 | ruleset-source-strategy-from-v2rayn | Decide the rule-set source strategy against v2rayN's, which this project is a headless equivalent of: whether to add GitHub *Releases* assets (CDN-backed, unlike raw.githubusercontent), whether to mirror the rules into a repo this project controls, and whether source *sets* should be user-selectable rather than just mirror order. | explore | T-14 | pending |
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
    progress bar would write carriage-return spam into the journal. Gate on `sys.stdout.isatty()` in Python; in Bash gate on **`[ -t 2 ]`, not `[ -t 1 ]`** —
    T-08 established that curl writes its meter to stderr and does not self-gate on it. Fall back to
    a single completion line. The two implementations cannot share
    code (Bash/curl vs Python/urllib) but must share the visual language.
  - Note the existing ruleset code already writes to `.tmp` then `.replace()` — T-02's atomic-write
    requirement is partly satisfied already; keep it rather than reinventing it.
- **RESTRUCTURED 2026-08-01 on the owner's directive 「优先用好的设计，避免不断的修修补补」, stated a
  second time.** The criticism was correct: the pool had been filed as the field report's symptom
  list. Re-derived from the code instead.
  **The finding:** `bin/sc:1001` holds ONE hardcoded ~70-line config dict, and **T-14, T-15, T-16 and
  T-17 all edit it** — T-16 and T-17 both editing `dns.rules`, an array whose *order carries meaning*.
  Four tasks taking turns patching one monolith is precisely the pattern rule 85 forbids, and the
  field report itself asked for the fix (#4: 「长期考虑把模板从 Python 字符串里抽出来」).
  **The design:** T-14 is no longer "add an override file". It becomes the composition layer —
  base template as data, ordered overlays, user override on top, with explicit array semantics
  because rule position is load-bearing. Its gate is that **with no override present the emitted
  config is byte-identical to today's**, which makes a pure structural change verifiable and keeps
  behaviour out of it.
  **The consequence:** T-15, T-16, T-17 and T-21 stop being edits to a hardcoded dict and become
  content on a structure — T-17 in particular should collapse to data plus a toggle. They now depend
  on T-14 for real consumption, not for sequencing convenience. This is why T-14 is worth doing
  first even though it ships no user-visible behaviour: it is the one change that makes the other
  four small, and it is the same change the owner identified as gating everything else.
  Counter-rule check per rule 85 (a refactor needs a nameable future edit it prevents): five are
  nameable — T-15, T-16, T-17, T-21, and every user customization that today survives only until the
  next `sc reload`.
- **v2rayN研究 2026-08-01 (owner: 「singbox-cli 初衷是实现一个类似于非桌面版的 V2rayN；完全可以抄 V2rayN 的一些逻辑」).**
  Read 2dust/v2rayN's actual update path before filing anything. Findings, evidence-backed:
  - **Their download logic is WEAKER than what T-02 already shipped.** `DownloadFileAsync` has no
    retry, no fallback, and no checksum; it copies the temp file over the target with
    `overwrite=true` regardless of content. Only `TryDownloadString()` has a two-strategy fallback.
    We already have ordered multi-base fallback, SRS-magic + size validation, atomic replace, and
    per-run dead-base marking. Do not regress toward theirs.
  - **They download THROUGH the local proxy** (`socks5://127.0.0.1:port` via `GetWebProxy`), which is
    direct counter-evidence to the field report's "考虑规则下载走 direct 而非 proxy" suggestion.
    Neither is obviously right; T-21 should decide with measurement, not assumption.
  - **What IS worth copying** — three things, none of which we have:
    1. `.dat` files come from **GitHub Releases** (`/releases/latest/download/{0}.dat`), not raw
       paths. Release assets are served from a different CDN than `raw.githubusercontent.com`.
    2. Their `.srs` come from **`2dust/sing-box-rules`, a repo they control** — a mirror they own
       rather than a third party's raw path.
    3. Sources are **selectable sets** (Loyalsoldier / russia-v2ray-rules / Iran-v2ray-rules), i.e. a
       rule-source *profile*, not merely mirror ordering. That composes with T-14's override.
  - **Project framing recorded:** singbox-cli is intended as a headless v2rayN. T-15 (urltest group +
    per-node latency) and T-14 (user-owned config) are already v2rayN-shaped; treat v2rayN's feature
    set as a roadmap reference rather than copying its implementation, which is thinner than ours.
- **Ingest 2026-08-01 — second field report (two production hosts, Ubuntu 24.04, pure TUN).**
  Ten numbered items. Triaged against work already delivered in this batch **before** filing, so the
  pool records what is genuinely outstanding rather than re-litigating shipped work:
  - **#2 (install.sh `set -e` / step 7) — ALREADY DELIVERED as T-01** (commit 493eb6a). The report's
    ask ("区分完全成功 / 部分成功 / 失败三种状态") is exactly what `PHASE_RULESETS`/`PHASE_CONFIG`/
    `PHASE_SERVICE` + `install_report()` now produce. No row.
  - **#3's mirror half — ALREADY DELIVERED as T-02** (commit ab4e4a4). `RULESET_BASES` already lists
    cdn.jsdelivr → testingcf.jsdelivr → ghfast → raw.githubusercontent, i.e. jsDelivr ahead of GitHub
    exactly as recommended, with per-source fallback and SRS validation. **The remainder is real and
    is T-19**: staleness reporting and making the timer fail loudly rather than printing.
  - **#6's root cause as stated is WRONG for current code, but the observation is real.** The report
    says the tool never sets permissions when regenerating; in fact `bin/sc` has called
    `os.chmod(CFG_PATH, 0o600)` immediately after writing since commit 41ffd08, there is exactly one
    write path, and the live file here is `-rw-------`. What survives scrutiny is a narrower defect:
    `write_text` creates the file at umask (0644) and only *then* chmods, leaving a window in which a
    credentials file is world-readable — plus backups get no chmod at all. T-13 is scoped to that,
    not to the reported cause. The 0644 file the reporter saw most likely predates 41ffd08 on that
    host; T-19's permission sweep in `install.sh` would repair such a host.
  - **#7 (AAAA) absorbed T-12 into T-16.** It is one `query_type` entry inside the DNS block T-16
    restructures; shipping it alone then restructuring around it is the seam
    `.harness/rules/85-design-discipline.md` forbids. The report's measurement is strong evidence:
    10.0s timeout → 0.016s empty answer on both hosts.
  - **#5 + #7 merged as T-16.** Both are "a flaky node must not hang name resolution", both edit the
    same `dns.servers`/`dns.rules` region, and the report itself notes rule *order* carries meaning
    (reject must sit after `clash_mode` and before the routing rules). Three separate rows would each
    have to reason about the others' insertion points.
  - **#8 (`sc doctor`) is in flight as T-05**, which was briefed before this report arrived. The
    report's richer check list is **T-20**, not a T-05 rollback: rule-set age, node latency, config
    drift, permission audit and IPv6 consistency each depend on features that do not exist yet
    (T-19, T-15, T-14, T-13, T-16 respectively). That is a real dependency, not a patch-then-patch.
  - **#1, #4, #9, #10** are new: T-15, T-14, T-18, T-17.
  - Execution order follows the report's own staging, which is sound: security and the blocking
    prerequisite first (T-13, T-14), then stability (T-15, T-16, T-19), then experience (T-17, T-18,
    T-20). The report is right that **T-14 gates everything** — until a user can persist their own
    configuration, every workaround dies at the next `sc reload`, and their only recourse is editing
    the shipped script, which forfeits the upgrade path.
  - Two through-lines the report asks to be carried into every row, both adopted: **failures must be
    loud**, and **a generated artifact must leave room for the user**.
- **T-12 filed 2026-08-01 — a live hand-patch is about to be silently destroyed.** At 10:06 a
  separate terminal (`pts/4`, `PWD=/home/alan/Programs/NFBY_CMS`) ran
  `sed -i 's/"query_type": \[64, 65\]/"query_type": [28, 64, 65]/' /usr/local/bin/sc`, adding AAAA
  to the DNS predefined-NOERROR list on the INSTALLED binary only. The repo's `bin/sc` still reads
  `[64, 65]`. `install.sh` is idempotent and rewrites `/usr/local/bin/sc`, so the next install or
  upgrade discards the change with no warning. A `/usr/local/bin/sc.bak-2026-08-01-1006` backup was
  taken by the same session. The change itself needs a real decision (blocking AAAA suppresses IPv6
  resolution globally — deliberate for some setups, a regression for others), so it gets a pipeline
  rather than a copy-paste.
- **T-01 blocked 2026-07-31 by an infrastructure outage, not by the task.** The safety classifier
  (`claude-sonnet-5[1m]`) went unavailable, so the `Agent` tool could not dispatch stage 5. Stages
  1-4 are complete and mutually consistent (analyst rev. 2, architect rev. 3, gate APPROVED with
  no FAIL/WARN, developer complete); **stage 5 code review and stage 6 QA never ran.** The code is
  on disk, uncommitted, and must NOT be committed until both run — `.harness/rules/80-delivery-policy.md`
  requires DELIVERED plus a green gate. Resume by re-dispatching 5 → 6 → 7; no upstream rework.
  The same outage also gated the `Bash` tool, so `verify_all`, commit, and push are unavailable.
- **T-09 found during T-01, verified independently 2026-07-31.**
  `systemd/sing-box-rules-update.service:7` reads `ExecStart=/usr/local/bin/proxy update-rules`.
  No such binary exists — the CLI installs as `/usr/local/bin/sc` (install.sh step 3, the
  `/etc/sudoers.d/sc` scope, and `bin/sc`'s own auto-elevate target all agree). The unit therefore
  fails 203/EXEC on every trigger, meaning the README-advertised weekly auto-update has **never
  worked on any install**, independent of the network failure that started this batch. Severity
  rises once T-01 lands, because T-01 makes the timer enabled unconditionally. Not merged into any
  existing row: it is a one-line unit fix in `systemd/`, sharing no code region with T-01 (steps
  6-7 of install.sh) or T-02 (bin/sc).
  **Scoped down after checking the OpenRC path: the bug is systemd-only.** `bin/sc:898` writes the
  OpenRC periodic script as `/usr/local/bin/sc update-rules`, which is correct — T-09 must not
  "fix" it. T-09 is exactly the one `ExecStart` line.
- **Open question for the owner (NOT a row — no requirement was given, and adding one would widen
  scope).** On OpenRC, the periodic script is only ever written by `sc update-interval
  daily|weekly|monthly` (`bin/sc:887-899`); `install.sh` never invokes it. So an Alpine/OpenRC
  install gets **no automatic ruleset update by default**, while a systemd install gets the weekly
  timer (once T-09 makes it actually run). This is a behaviour gap between the two init systems,
  not a defect against any stated requirement. Ask before filing.
- **T-10 filed 2026-07-31 on the owner's standing grant 「你来决策就行」.**
  T-09 fixed a dead timer, which activates a latent defect: `bin/sc:1141-1143` restarts sing-box
  even when **nothing changed** (`if not applied and is_running()`). With `OnCalendar=weekly` +
  `RandomizedDelaySec=1h`, every systemd host now drops all connections once a week, Monday
  00:00-01:00 local, for a refresh that usually changes nothing. Verified directly 2026-07-31.
  Fix shape: restart only when a rule-set actually changed on disk — and prefer the project's own
  hot-apply-over-restart convention (`.harness/rules/50-singbox-cli.md`), since sing-box reloads
  rule-sets without a service restart. Say the word and I file it.
  Two smaller follow-ups found alongside, same status: `uninstall.sh:113-130` never runs
  `systemctl reset-failed`, so it can leave a unit in `systemctl --failed`; and `bin/sc` still has
  3 `capture_output=True` sites (Python 3.7+) against a README-documented 3.6+ floor.
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
