# Insight History — singbox-cli

> Entries rotated out of `.harness/insight-index.md` when it exceeded its 30-line cap.
> Nothing here is deleted knowledge — it is knowledge that stopped earning a line in the
> always-loaded index, usually because a committed gate or `docs/dev-map.md` now carries it.
> See `.harness/rules/05-insight-index.md` and `.harness/rules/70-doc-size.md`.

## Rotated 2026-08-01 (during `sc-doctor` / T-05 archive)

`archive-task.sh` harvested 3 new insights but did **not** auto-rotate the overflow, so the index
stood at 32 lines against its 30 cap and `verify_all` F.4 turned WARN. The PM rotated these two by
hand. Both were chosen because a committed artefact now carries the knowledge — not merely because
they were the oldest lines (rule 70: "Cuts are made by removing what doesn't earn its line").

- 2026-07-31 · `install.sh`'s `t()` declares `local fmt` with no default, so a key present in only one language branch aborts the whole installer under `set -u` rather than printing a blank line — and the zh branch is only reachable by answering `2` at the language prompt, so an English-only test run cannot detect it · evidence: install-enable-start-split
  - **Why rotated:** T-11 committed `check-i18n-parity.sh` as `verify_all` **B.2**, which renders every
    `t()` key in both languages and fails the run on a key-set or `printf`-specifier mismatch. The
    hazard is now caught by a gate on every run instead of by an agent remembering this line.
    (Its known blind spot is itself an index entry — the `LANG_CHOICE` dispatch one — which stays.)

- 2026-07-31 · `sc update-rules` prints the actual failure cause (`urlopen error timed out`) on **stdout** while stderr carries only the aggregate count, so capturing stderr alone logs "N ruleset(s) failed to update" and loses the diagnosis entirely · evidence: install-enable-start-split
  - **Why rotated:** now a standing convention in `docs/dev-map.md` § "Patterns to follow" — *"stdout
    carries results and per-file causes; stderr carries aggregates and warnings"* — which the developer
    agent reads before writing code. The index line duplicated a rule that already lives closer to the
    work.
