# Rejected decisions — deliberately not adopted (and why)

> Deliberately-declined requests / approaches + why, so a re-proposal finds the prior
> decision instead of re-litigating it. **Read** at a non-trivial decide-point before
> proposing a new approach / feature; **append** when something is deliberately declined
> (a real rejection — or a `deferred` "not now", marked as such). One record per concept;
> a re-occurrence adds its origin to that record, not a second record. Sibling memory:
> `.harness/insight-index.md` (truths), `.harness/decision-rubric.md` (autonomy principles),
> `CONTEXT.md` (glossary). Soft self-discipline: if this grows past ~one screen, compact
> merged/obsolete records — no gate enforces size.

<!-- No declines recorded yet. When your project deliberately turns something down, add a
     record below: a short kebab-case handle as an `## heading`, then the decision
     (declined / deferred), a substantive why (scope / constraint / strategic choice — not
     "we don't want it"), and the origin (which request / task raised it). Example shape: -->

## srs-size-floor-512-bytes
- **Decision:** declined (floor set to 16 bytes instead).
- **Why:** the floor's only job is excluding empty/stub bodies — the `SRS` magic rejects HTML error
  pages and a Content-Length equality check catches truncation. `geosite-private.srs` compiles from a
  handful of suffixes and may legitimately fall under 512 bytes, so a 512-byte floor would
  permanently reject a correctly downloaded file and degrade the config forever — the exact bug T-02
  exists to remove. Binding constraint kept in the code comment: the floor must stay strictly below
  the smallest real rule-set; raising it requires measuring all four first (T-02 AC-27).
- **Origin:** T-02 `config-degrade-missing-rulesets`, task brief ("~512 bytes"), resolved in
  `docs/features/config-degrade-missing-rulesets/02_SOLUTION_DESIGN.md` §7 Q1.

## config-check-retry-without-rulesets
- **Decision:** declined.
- **Why:** retrying `sing-box check` with all rule-sets dropped after a failure would mask unrelated
  config errors (a malformed node) as "rule-set trouble" and silently ship a config with no routing
  rules for a reason the user never sees. Magic + size + Content-Length cover the observed failure
  mode; a byte-valid but semantically corrupt `.srs` from an official mirror is not an observed case.
  A check failure keeps surfacing exactly as it does today.
- **Origin:** T-02 `config-degrade-missing-rulesets` §8 Q5.

## mirror-fallback-cause-on-its-own-line-or-on-stderr
- **Decision:** declined (the cause of a base that failed before a later base succeeded is appended to
  the *same* completion line, as `OK (n bytes); fell back after: <base> -> <reason>`).
- **Why:** a second line per rule-set breaks the non-TTY contract that `sc update-rules` emits exactly
  one completion line per rule-set (T-02 B-19/AC-15), which the systemd timer and
  `/var/log/sing-box/install.log` consume; routing it to stderr breaks the insight-index rule that
  `update-rules`' per-file causes go to **stdout** while stderr carries only the aggregate count (T-01
  depends on it). Reusing the existing `failed: {e}` key for the note was also declined: it would make a
  *successful* line match the `failed:` / `失败：` grep that today means "this file was not updated".
  **The same ban binds every translation of the new key, not just the English one** (A-2): the first zh
  rendering, `"；已回退，前序镜像失败：{causes}"`, re-created the exact collision this record forbids, because
  `"failed: {e}"` renders as `"失败：{e}"` (`bin/sc:126`). Corrected to `"；已回退，前序镜像未成功：{causes}"`
  — `未成功` is true for every cause kind (transport error, non-2xx, truncation, rejected body), whereas
  `报错` (also considered, declined) would be false for the causes where the mirror answered fine and *we*
  rejected the body.
- **Origin:** T-02 `config-degrade-missing-rulesets`, QA defect D-1 (`06_TEST_REPORT.md` §6), resolved as
  Amendment A-1 in `docs/features/config-degrade-missing-rulesets/02_SOLUTION_DESIGN.md` §5.3/§6.2;
  re-occurrence as the zh collision above — code review delta pass MINOR — resolved as Amendment A-2
  in the same document §5.4 + §9 R10.

## ruleset-unit-tests-in-t02
- **Decision:** deferred (to T-07, which owns the committed harness).
- **Why:** the repo has no test directory; adding one here would widen T-02's diff past its stated
  boundary (`bin/sc` + CHANGELOG + both READMEs) and pre-empt T-07's harness design. `verify_all` B.2
  therefore stays SKIP for now. Not discarded: T-02's QA harness is pasted into its `06_TEST_REPORT.md`
  and handed to T-07 rather than thrown away, so the gate stops being permanently empty.
- **Origin:** T-02 `config-degrade-missing-rulesets` §8 Q8, against
  `.harness/rules/50-singbox-cli.md` ("the first real task that adds a test command must replace the
  matching SKIP"). **Re-occurrence:** T-10 `ruleset-update-no-needless-restart` §10 D-8 — same
  answer for the same reason (diff boundary is `bin/sc` + `CHANGELOG.md`), explicitly flagged there
  as the weakest of that task's decisions, since the change is about restart behaviour and a
  permanently reproducible guard has real value. T-07 still owns the committed harness.
  **Re-occurrence:** T-08 `install-binary-download-progress` §9 D-A8 — its AC-9 needs a `t()`
  key-parity extractor for `install.sh`, which is exactly the check `.harness/rules/50-singbox-cli.md`
  wants wired into `verify_all` B.2/B.3; AC-19 caps that diff at `install.sh` + `CHANGELOG.md`, so the
  extractor runs at QA time and is pasted into `06_TEST_REPORT.md` for T-07 to commit. This is the
  third row to hit the same wall — the next one should probably widen its own diff instead.

## t-fmt-default-fallback
- **Decision:** declined (`t()` in `install.sh` keeps `local fmt` with no default).
- **Why:** the proposal was to make a key missing from one language table print the key name instead of
  aborting the installer under `set -u` (`.harness/insight-index.md:10`). It trades a bug that cannot
  ship unnoticed for one that easily can: today a zh-only omission kills the run loudly the first time
  anyone answers `2`, whereas the fallback would print `step2_fetching` mid-install and complete. It
  also edits a function serving ~45 keys for a hazard the task did not raise. The structural fix is a
  committed key-parity gate (see `ruleset-unit-tests-in-t02`); the per-task mitigations are fewer keys,
  paired insertion at the same relative position in both `case` blocks, and a both-languages run.
- **Origin:** T-08 `install-binary-download-progress` §9 D-A7, answering the brief's "design so this
  class of bug is structurally hard".

## ruleset-progress-visible-during-install
- **Decision:** deferred (T-08 leaves step 6's `sc update-rules` redirected to `$LOG_SINK`, so the
  per-rule-set progress T-02 built is still invisible while an install is running).
- **Why:** un-redirecting it destroys T-01's design, in which the *cause* of a rule-set failure is
  captured into `/var/log/sing-box/install.log` while the screen shows only a summary; and a `tee`
  is forbidden by `.harness/insight-index.md:12` — under `pipefail` a logging fault would flip a
  healthy phase. It is also outside T-08's stated boundary (the installer's own transfers, not the
  rule-set download path). The gap is real, not imaginary: T-02 shipped TTY-gated per-rule-set
  progress that no installing user has ever seen, because at install time `sc`'s stdout is a file
  (T-02 evidence E-8). **Unblock path:** a row that decides how step 6 can show progress on the
  terminal *and* keep the cause in the log without a `pipefail`-exposed pipeline — e.g. showing
  progress on a stream that is not the one being captured.
- **Origin:** T-08 `install-binary-download-progress` §9 D-6 / §4 item 3.

## installer-package-manager-download-output
- **Decision:** declined for T-08 (step 1's apt/dnf/yum/pacman/zypper/apk installs stay quiet).
- **Why:** those bytes are not the installer's own transfer. Making them visible means removing the
  quiet flags from six package managers with six output volumes and six error surfaces, changing
  `pkg_install`'s `|| return 1` failure reporting, for a step whose payload is a handful of usually
  cached packages. That is scope the owner's request ("每个下载部分" — the downloads the installer
  itself performs) does not carry, and it is separable into its own row if ever wanted.
- **Origin:** T-08 `install-binary-download-progress` §9 D-7.

## installer-version-query-silent-abort
- **Decision:** deferred (T-08 leaves `install.sh`'s GitHub API version query exactly as it is, apart
  from substituting the shared quiet-flag array).
- **Why:** this is a **live defect, not a style point**, and it was found while correcting a wrong
  sentence in T-08's own requirement (D-5's third reason). `SB_VER=$(curl -fsSL … | grep '"tag_name"'
  | head -1 | sed …)` (`install.sh:352-354`) is a plain assignment from a command substitution, so its
  status is the pipeline's status; under `set -euo pipefail` (`install.sh:9`) an HTTP 403 (GitHub's
  unauthenticated rate limit — routine from shared/CGNAT/CI addresses), a 404, or any transport
  failure makes curl exit 22/6 with empty stdout, `grep` exit 1, and `set -e` terminate the installer
  **at the assignment**. The bilingual `t download_failed "GitHub API (sing-box version)"` /
  `t check_network` at `:356-360` is therefore unreachable on exactly the failures it was written for;
  it catches only a pipeline that exits 0 and yields an empty or non-semver string. **T-01 blast
  radius:** T-01 made `install_report()` state the outcome and derive the exit status
  (`install.sh:494-497`); this path reaches neither, and unlike step 2's *designed* failure exit it
  substitutes no statement of its own — so the installer can terminate having said nothing about what
  happened, showing only curl's raw English one-liner (kept by `-S`) and exiting 1, the same status as
  the diagnosed path. Not fixed in T-08 because fixing it changes step-2 failure behaviour, which
  T-08's AC-6/AC-14 pin as unchanged, and `.harness/rules/85-design-discipline.md`'s counter-rule
  forbids widening a task past the request it was given: T-08 makes downloads visible, it does not
  redesign failure reporting. **Unblock path:** its own row — an API/transport failure of the version
  query produces the same class of outcome as a tarball failure (a bilingual statement naming what
  failed and what to check, plus a derived exit status). That row decides whether the fix keeps the
  direct `exit 1` or routes through `install_report()`, and whether any other bare `VAR=$(pipeline)`
  under `set -e` in this script carries the same hole. Cheap to fix (an explicit `if ! SB_VER=$(…)`),
  but it needs its own acceptance criteria, so it is not smuggled in.
- **Origin:** T-08 `install-binary-download-progress` — found by the Solution Architect as
  `docs/features/install-binary-download-progress/02_SOLUTION_DESIGN.md` §11 R-D, verified and
  re-homed by the Requirement Analyst as that task's `01_REQUIREMENT_ANALYSIS.md` §4 item 11 / E-15 /
  §9 D-5.

## mtime-or-size-as-a-ruleset-change-signal
- **Decision:** declined (a rule-set counts as changed only when its installed **content** differs —
  full byte equality or a digest of the full content).
- **Why:** every write-based signal (mtime, "the request returned 200", "a file was replaced") is true on
  **every successful run**, whether or not the bytes differ from the installed ones, so it would keep
  reproducing the connection drop this task exists to remove — the argument holds regardless of how often
  upstream content actually changes, and no frequency claim is needed or made. Size alone is a weaker
  equality and would miss an equal-size content change. `Content-Length` is already consumed as a truncation
  check and says nothing about whether the body differs from the installed one. **Accuracy note
  (gate-corrected, do not restore the old wording):** `.harness/insight-index.md:15` says the four mirrors
  serve content byte-identical **to each other** at one instant; it does **not** establish week-over-week
  stability of the upstream rule-sets, so "a successful re-download of unchanged data is the *common* case"
  must not be quoted as a conclusion from it.
- **Origin:** T-10 `ruleset-update-no-needless-restart` §4 B-1 / §10 D-3.

## trust-singbox-fswatch-ruleset-reload
- **Decision:** deferred (T-10 restarts sing-box on a real content change instead of relying on
  sing-box reloading the `.srs` file by itself).
- **Why:** the installed binary really does carry a local rule-set file watcher — `/usr/local/bin/sing-box`
  contains the pclntab entry `route/rule/rule_set_local.go`, the log literals `watch rule-set file` and
  `reload rule-set `, and links `github.com/sagernet/fswatch` over `fsnotify` — so on that host a replaced
  rule-set is probably picked up in place at no cost to established connections. It still cannot be relied
  on, and T-10's B-4/B-5 allow an "applied without restarting" claim only with evidence. Three load-bearing
  reasons, in order: (1) **our own config closes the log channel** — `generate_config()` emits
  `"log": {"level": "warn"}` (`bin/sc:746`), so an Info-level success line is never written on this project's
  hosts, whatever the binary can print; (2) **B-12 forbids a systemd-only oracle** — reading a journal has no
  OpenRC counterpart and `sc` contains no log-reading code at all; (3) **whether the watcher survives our
  atomic rename-over-replace** (`bin/sc` `tmp.replace(target)`, inode vs. dirent) could not be determined, so
  even a perfect oracle would not tell us the right thing happened for *our* write pattern. **Accuracy note
  (gate-corrected, do not restore the old wording):** it is **not** true that the binary logs nothing on a
  successful reload — `reloaded rule-set` is absent, but `updated rule-set ` and `rule-set updated` are each
  present alongside `route/rule/rule_set_remote.go`; what is true is only that a success literal **cannot be
  attributed to the local-file path from strings alone**. Also **not** load-bearing: that `install.sh`
  installs the **latest** release rather than a pinned version — fleet capability drift is real context, but
  `sing-box version` and Clash `/version` are both probeable per host, so it cannot carry the decision.
  Restarting only when the installed bytes really changed removes the weekly no-op connection drop regardless
  of which way the unknowns fall. **Unblock path:** pin a minimum sing-box version in `install.sh`, then run
  one observed rename-replace experiment on a disposable host (never a live one); if the reload is confirmed,
  the remaining restarts can be dropped. Also declined here: SIGHUP / `ExecReload`
  (`systemd/sing-box.service:10`) — it recreates the whole box instance, so it drops connections like a
  restart, and the OpenRC service written by `install.sh` defines no `reload()` at all; and the Clash API —
  `/providers/rules` exists as a route but the binary carries none of the Clash rule-provider payload fields
  (`ruleCount`, `vehicleType`), confirming T-02's E-7 that the API switches proxy and mode only.
- **Origin:** T-10 `ruleset-update-no-needless-restart` §10 D-1, closed with evidence in
  `docs/features/ruleset-update-no-needless-restart/02_SOLUTION_DESIGN.md` §2.

## doctor-exit-status-always-zero
- **Decision:** declined (`sc doctor` exits `0` = all OK, `1` = at least one PROBLEM, `2` = no PROBLEM
  but at least one UNKNOWN).
- **Why:** "a diagnostic should never surprise a shell" avoids a small, bounded surprise — a `set -e`
  script deliberately running `sc doctor` — at the cost of the command's entire automated use (health
  check, pre-flight step, triage one-liner). The project already derives status from findings:
  `sc update-rules` exits non-zero when rule-sets failed (`bin/sc:1255-1256`) and T-01 made
  `install.sh` derive its status from recorded phase state. The **two-value** 0/non-zero variant was
  also declined: it must fold UNKNOWN into one of the two values and both foldings lie — folding into
  `0` calls a host healthy when no init system was detected (BC-8) or no Clash port is recorded
  (BC-11); folding into `1` calls it broken on evidence that does not exist. FR-8 already forces three
  outcome classes on the report; the status just does not throw the third one away. Accepted
  side-effect: argparse's own usage error also exits `2`, distinguishable because a usage error prints
  no report.
- **Origin:** T-05 `sc-doctor` — the owner assigned the choice to stage 2; stage 1 §8 R-7 stated both
  candidates without imposing one. Decided in `docs/features/sc-doctor/02_SOLUTION_DESIGN.md` §3.1.

## shared-singbox-check-wrapper
- **Decision:** declined (`sc doctor`'s S3 invokes `sing-box check` directly; `generate_config()`'s
  invocation at `bin/sc:921-926` is left exactly as it is).
- **Why:** three reasons, in order. (1) The judgment "is this config valid" is formed by the external
  binary, not by `bin/sc` — what a wrapper would share is a four-line invocation, i.e. a pass-through
  that fails the deletion test: delete it and no complexity reappears at either call site. (2) The two
  call sites genuinely differ — `generate_config()` checks a file it has just written, as part of an
  apply flow, and routes the message into a stderr warning; `doctor` checks a file it must never write
  and must classify the outcome and truncate the message per BC-7. (3) `generate_config()`'s
  invocation is one of the three pre-existing `capture_output=` sites (3.7+ on a 3.6+ floor) that are
  filed as their own pool row; a shared wrapper would either drag that fix into T-05's diff or force
  T-05 to add a fourth occurrence, and both are forbidden by its scope. The consistent principle: T-05
  consolidates shared **data** (`TUN_IFACE`, `_egress_ip()`'s endpoint, `_saved_clash_port()`'s
  settings key) and does not wrap shared **procedure**.
- **Origin:** T-05 `sc-doctor`, `docs/features/sc-doctor/02_SOLUTION_DESIGN.md` §3.5, against rule 85's
  "duplicated judgment" test.
