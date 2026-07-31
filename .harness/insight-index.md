# Insight Index — singbox-cli

> Cross-task truths the project has learned the hard way. ≤30 lines.
> Read at the start of design/implementation tasks; write only after evidence-backed surprises.
> See `.harness/rules/05-insight-index.md` for the contract.

<!-- Append new insights below, one per line. Format:
- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
-->
- 2026-07-31 · `install.sh`'s `t()` declares `local fmt` with no default, so a key present in only one
- 2026-07-31 · `sc update-rules` prints the actual failure cause (`urlopen error timed out`) on **stdout**
- 2026-07-31 · `systemd/sing-box-rules-update.service` has always pointed at `/usr/local/bin/proxy`, a
- 2026-07-31 · Under `set -euo pipefail`, redirecting a command to an unwritable path fails *before* the
- 2026-07-31 · `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc`, not the file under test, and sudo's `env_reset` silently drops `SB_RULES_BASE` — so an un-neutralised test import does not fail, it runs the *installed* tool against the *live* service · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `http.client.HTTPResponse.read(n)` blocks until it has all `n` bytes, so a 64 KiB chunk loop emits exactly one progress redraw for any body under 64 KiB — progress fixtures must exceed the chunk size or they assert nothing · evidence: config-degrade-missing-rulesets
- 2026-07-31 · The smallest real MetaCubeX rule-set (`geosite-private.srs`) is 696 bytes, and all four configured mirror bases return byte-identical content · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `失败：` in `bin/sc` output is a load-bearing diagnostic grep meaning "this file was not updated"; any new zh string must avoid it, and `已跳过（…已失败）` is safe only because dead-skips never reach a success line · evidence: config-degrade-missing-rulesets
