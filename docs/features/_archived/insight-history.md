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

## Rotated 2026-08-01 (during `config-write-permission-hardening` / T-13 archive)

The index stood at its 30-line cap before T-13 harvested anything, and `archive-task.sh`'s rotation
is still broken (it harvests but does not rotate — the same defect T-05 recorded). The PM rotated
these three by hand **before** running the script, so the harvest lands at exactly 30 lines and F.4
never turns WARN. Chosen by rule 70's "what no longer earns its line", not oldest-first: one is
factually superseded, one was superseded by a later refinement of the same trap, and one is a
fixture detail with no live consumer.

- 2026-08-01 · `check-i18n-parity.sh` (now `verify_all` B.2) renders both languages *through* `install.sh`'s own `LANG_CHOICE` dispatch, so breaking that dispatch makes it render the **en** table twice, agree on every comparison, print `OK: 41 keys, both languages` and exit 0 while the zh path is entirely unreachable — a committed gate that passes by rendering the same table twice · evidence: install-version-query-abort
  - **Why rotated:** **superseded by a fix.** Commit `49506f8` added a `--- 3b. self-check` step to
    `check-i18n-parity.sh` (`:98-107`) that `die2`s when the two renders come back byte-identical, so
    the false-green path this line warns about is closed in the committed gate. T-13's gate reviewer
    established that R-7's *other* blind spot is still live and it replaces this line in the index —
    keeping both would have spent two of thirty lines on one gate.

- 2026-07-31 · `http.client.HTTPResponse.read(n)` blocks until it has all `n` bytes, so a 64 KiB chunk loop emits exactly one progress redraw for any body under 64 KiB — progress fixtures must exceed the chunk size or they assert nothing · evidence: config-degrade-missing-rulesets
  - **Why rotated:** **superseded by a later, more accurate reading of the same trap**, which is
    already in the index: *"a progress-redraw fixture's non-vacuity is carried by the server's
    **throttle**, not the body size — an 8 MiB body with `sleep=0` yields `states=1` exactly like a
    1 KiB body"* (`install-binary-download-progress`). That entry says explicitly that it refines this
    one, and acting on this line alone (make the body bigger) produces a fixture that still asserts
    nothing. Keeping the superseded version alongside its correction is worse than dropping it.

- 2026-07-31 · The smallest real MetaCubeX rule-set (`geosite-private.srs`) is 696 bytes, and all four configured mirror bases return byte-identical content · evidence: config-degrade-missing-rulesets
  - **Why rotated:** a **fixture measurement with no live consumer**. It was load-bearing while T-02
    was choosing `SRS_MIN_BYTES`; that constant is now committed in `bin/sc` and `docs/dev-map.md`
    carries the usability model, so nothing an agent does today turns on remembering the 696-byte
    figure. Re-measurable in one `curl` if it ever matters again.
