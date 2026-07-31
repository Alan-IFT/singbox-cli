# Insight Index — singbox-cli

> Cross-task truths the project has learned the hard way. ≤30 lines.
> Read at the start of design/implementation tasks; write only after evidence-backed surprises.
> See `.harness/rules/05-insight-index.md` for the contract.

<!-- Append new insights below, one per line. Format:
- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
-->
- 2026-07-31 · `install.sh`'s `t()` declares `local fmt` with no default, so a key present in only one language branch aborts the whole installer under `set -u` rather than printing a blank line — and the zh branch is only reachable by answering `2` at the language prompt, so an English-only test run cannot detect it · evidence: install-enable-start-split
- 2026-07-31 · `sc update-rules` prints the actual failure cause (`urlopen error timed out`) on **stdout** while stderr carries only the aggregate count, so capturing stderr alone logs "N ruleset(s) failed to update" and loses the diagnosis entirely · evidence: install-enable-start-split
- 2026-07-31 · Under `set -euo pipefail`, redirecting a command to an unwritable path fails *before* the command runs, so a bare `>>"$LOG"` guard would record a healthy step as failed; and a `tee` pipeline would let a logging fault flip a healthy phase under `pipefail` · evidence: install-enable-start-split
- 2026-07-31 · `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc`, not the file under test, and sudo's `env_reset` silently drops `SB_RULES_BASE` — so an un-neutralised test import does not fail, it runs the *installed* tool against the *live* service · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `http.client.HTTPResponse.read(n)` blocks until it has all `n` bytes, so a 64 KiB chunk loop emits exactly one progress redraw for any body under 64 KiB — progress fixtures must exceed the chunk size or they assert nothing · evidence: config-degrade-missing-rulesets
- 2026-07-31 · The smallest real MetaCubeX rule-set (`geosite-private.srs`) is 696 bytes, and all four configured mirror bases return byte-identical content · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `失败：` in `bin/sc` output is a load-bearing diagnostic grep meaning "this file was not updated"; any new zh string must avoid it, and `已跳过（…已失败）` is safe only because dead-skips never reach a success line · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `systemd-analyze verify` only catches an unresolvable absolute `ExecStart`; a bare PATH lookup, CRLF line endings and `/usr/bin/env` indirection all exit 0, so it proves a wrong-path defect is gone but is not general unit lint · evidence: fix-rules-update-execstart
- 2026-07-31 · A systemd timer's stamp advances when the timer elapses and *enqueues* the job, not when the service succeeds, so a unit failing `203/EXEC` still advanced its stamp weekly and `Persistent=true` produces no catch-up burst once the command is fixed · evidence: fix-rules-update-execstart
- 2026-07-31 · An acceptance criterion of the form "no occurrence of `<literal>` anywhere in the repository" is self-violating, because the requirement document stating it contains the literal · evidence: fix-rules-update-execstart
- 2026-07-31 · The systemd manager's default service `PATH` on this project's hosts includes `/usr/local/bin`, which is the only reason `bin/sc`'s bare `SB_BIN = "sing-box"` lookup resolves when the CLI runs from a unit rather than a login shell · evidence: fix-rules-update-execstart
- 2026-07-31 · `.harness/scripts/archive-task.sh` harvests only the FIRST physical line of each `## Insight` bullet, silently truncating any wrapped entry and dropping its `· evidence:` tag — write index bullets as one physical line · evidence: fix-rules-update-execstart
