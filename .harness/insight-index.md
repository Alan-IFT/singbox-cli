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
