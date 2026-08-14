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

## Rotated 2026-08-01 (during `config-composition-layer` / T-14 archive)

`archive-task.sh` harvested T-14's 4 insights but again did **not** rotate — its threshold counts
**bullets** (25 after the harvest, under the 30 it compares against) while `verify_all` F.4 counts
**lines** (34 against a 30 cap), so the two can never agree and the rotation is dead code for any
index with a header. The PM rotated these four by hand. Chosen by rule 70's "what no longer earns
its line": three come from areas that are closed and quiet, and one is a one-time process
observation of the kind rule 70's own adversarial check assigns to a stage doc rather than the
always-loaded index.

- 2026-07-31 · `systemd-analyze verify` only catches an unresolvable absolute `ExecStart`; a bare PATH lookup, CRLF line endings and `/usr/bin/env` indirection all exit 0, so it proves a wrong-path defect is gone but is not general unit lint · evidence: fix-rules-update-execstart
  - **Why rotated:** the **defect it scoped is shipped and the area is quiet**. T-09 is delivered, the
    unit's `ExecStart` is correct, and no open row touches `systemd/`. What survives of it is a
    caveat on `.harness/rules/50-singbox-cli.md:138`'s standing lint suggestion — a caveat that costs
    a line of the always-loaded index every task, to be spent by whichever future task next edits a
    unit file. That task can re-derive it from this file.

- 2026-07-31 · A systemd timer's stamp advances when the timer elapses and *enqueues* the job, not when the service succeeds, so a unit failing `203/EXEC` still advanced its stamp weekly and `Persistent=true` produces no catch-up burst once the command is fixed · evidence: fix-rules-update-execstart
  - **Why rotated:** **the question it answered is settled and closed.** It existed to rule on whether
    fixing T-09's `ExecStart` would trigger a `Persistent=true` catch-up burst; it would not.
    `BATCH_PLAN.md:186-189` records the companion finding (`Persistent=true` is already present and
    already installed) and closes P3-2 with "Nothing to change". QA additionally found the unit has
    **never run** on this host, so the stamp claim has no live consumer here at all.

- 2026-08-01 · The `curl-7_29_0` git tag is not a valid version-dated source for option-floor claims — `curlver.h` at that tag still reads `7.28.2-DEV`; only the released `curl-7.29.0.tar.gz` (now under `curl.se/download/archeology/`, the plain `download/` path 404s) dates itself correctly · evidence: install-binary-download-progress
  - **Why rotated:** a **settled one-off version question**. The 7.29 option floor it guarded was
    established by two independent readers during T-08 and the conclusion is written into
    `docs/tasks.md:21`; the download-flag policy block is shipped. Nothing an agent does today turns
    on re-checking a 2013 curl tag, and if the floor is ever reopened this entry is one grep away.

- 2026-07-31 · An acceptance criterion of the form "no occurrence of `<literal>` anywhere in the repository" is self-violating, because the requirement document stating it contains the literal · evidence: fix-rules-update-execstart
  - **Why rotated:** **not project-specific hard-won fact.** Rule 70's adversarial check ("one-time
    observation about a task → write it in a stage doc that gets archived") and rule 05's ("would
    someone reasonable derive this in under 10 minutes?") both place this outside the index. It is a
    writing caution about ACs, generic to any repository, from a task that is closed. Substituted in
    for the progress-redraw throttle entry — see the note below.

**Deviation from the proposed set:** the fourth proposed removal — the progress-redraw fixture
throttle entry (`install-binary-download-progress`) — was **kept**. It is still load-bearing:
`docs/tasks.md:47-49` files it as an open row ("AC-3's non-vacuity is carried by the server
**throttle**, not the fixture size, with no guard") against a harness **T-07 inherits**, and the
T-13 rotation above deleted its predecessor precisely on the grounds that this entry supersedes it —
dropping it now would leave the corrected reading nowhere in the index while the uncorrected one is
already gone. The self-violating-AC entry was rotated in its place.

## Rotated 2026-08-13 (during `proxy-urltest-group` / T-15 archive)

`archive-task.sh` harvested 4 new insights and again did **not** auto-rotate — R-18's diagnosis
confirmed a third time: the script's threshold counts **bullets** (21 + 4 = 25, under its 30) while
`verify_all` F.4 counts **lines** (34 against a 30 cap), so on any index carrying a header the branch
can never fire. The PM rotated these four by hand.

Selection follows rule 70's "what no longer earns its line", not oldest-first. Each was chosen
because a committed artefact, a filed open row, or a sharper sibling entry now carries the knowledge:

- 2026-07-31 · Under `set -euo pipefail`, redirecting a command to an unwritable path fails *before* the command runs, so a bare `>>"$LOG"` guard would record a healthy step as failed; and a `tee` pipeline would let a logging fault flip a healthy phase under `pipefail` · evidence: install-enable-start-split
- 2026-07-31 · The systemd manager's default service `PATH` on this project's hosts includes `/usr/local/bin`, which is the only reason `bin/sc`'s bare `SB_BIN = "sing-box"` lookup resolves when the CLI runs from a unit rather than a login shell · evidence: fix-rules-update-execstart
- 2026-07-31 · `.harness/scripts/archive-task.sh` harvests only the FIRST physical line of each `## Insight` bullet, silently truncating any wrapped entry and dropping its `· evidence:` tag — write index bullets as one physical line · evidence: fix-rules-update-execstart
- 2026-08-01 · sing-box does watch local rule-set files (`sagernet/fswatch`, literals `watch rule-set file` / `reload rule-set `), but `generate_config()` emits `"log": {"level": "warn"}`, so any Info-level success line is never written on this project's hosts — the watcher cannot be trusted because there is no channel to observe it working · evidence: ruleset-update-no-needless-restart

Why each stopped earning its line:

1. **The `>>"$LOG"` / `tee` entry** is the blunt form of a family whose sharp form is still in the
   index — `VAR=$(cmd | grep …)` aborting *at the assignment* under `pipefail` — and the wider class
   is filed as R-3 with five named sites. Keeping both spends two lines on one lesson.
2. **The systemd `PATH` entry** is a host fact that `systemctl show-environment` answers in under a
   minute, which is exactly the "derivable in <10 minutes" bar `05-insight-index.md` rejects. It was
   worth recording when `sing-box-rules-update.service` was being fixed; it is not worth a permanent
   line now that the unit ships correct.
3. **The `archive-task.sh` first-physical-line entry** is now **stale in its literal claim**: the
   script carries a local awk fix (`archive-task.sh:51-71`) that joins continuation lines, so a
   wrapped bullet is harvested whole. The residual risk — that `/harness-upgrade` silently reverts
   that fix — is filed as **R-18** along with the rotation defect, which is the better home because
   R-18 names both defects and the file they live in. The authoring convention it taught (one
   physical line per insight) survives in the PM's own delivery-doc contract.
4. **The fswatch / `log.level=warn` entry** recorded *why* T-10 declined rule-set hot-apply. That
   decline is now a delivered decision recorded in T-10's `docs/tasks.md` row ("recorded as a
   **deferred decline**, not a rejection"), and no live code path depends on the observation. The
   sibling entry that *is* still load-bearing — `/providers/rules` being a compatibility stub — stays
   in the index, and was cited by T-15's own brief.

**Deliberately kept** (re-examined this rotation and left in place): the progress-redraw **throttle**
entry. The 2026-08-01 rotation note above already declined to drop it on the ground that
`docs/tasks.md` files it as an open row against a harness T-07 inherits, and that reasoning is
unchanged — rotating it now would delete the corrected reading while its uncorrected predecessor is
already gone.

## Rotated 2026-08-14 (during `dns-resilience` / T-16 delivery)

Rotated by hand: `archive-task.sh` harvested but did not rotate (R-18 — it counts bullets while
`verify_all` F.4 counts lines, so on any index carrying a header the branch cannot fire).
The index stood at 37 lines against a 30-line cap after the harvest.

- YYYY-MM-DD · <one-sentence fact> · evidence: <task-slug or commit-sha>
- 2026-07-31 · `bin/sc`'s import-time auto-elevate re-execs the **installed** `/usr/local/bin/sc`, not the file under test, and sudo's `env_reset` silently drops `SB_RULES_BASE` — so an un-neutralised test import does not fail, it runs the *installed* tool against the *live* service · evidence: config-degrade-missing-rulesets
- 2026-07-31 · `失败：` in `bin/sc` output is a load-bearing diagnostic grep meaning "this file was not updated"; any new zh string must avoid it, and `已跳过（…已失败）` is safe only because dead-skips never reach a success line · evidence: config-degrade-missing-rulesets
- 2026-08-01 · `systemctl is-active` prints `active` on both sides of a restart, so a before/after `is-active` reading cannot detect a service bounce at all — the witness that does is `systemctl show -p MainPID -p ActiveEnterTimestamp`, and the `is-active` check written after T-02's live-restart incident would have passed during that very incident · evidence: ruleset-update-no-needless-restart
- 2026-08-01 · sing-box's Clash API cannot apply a local `.srs`: the installed binary contains the `/providers/rules` route string but neither `ruleCount` nor `vehicleType`, so the route is a compatibility stub and no rule-set hot-apply path exists through it · evidence: ruleset-update-no-needless-restart
- 2026-08-01 · A `git worktree` is not a valid pristine baseline for `verify_all.sh` in this repo — `.git` is a *file* in a worktree, so A.1/A.2 turn SKIP and the summary falsely reads `14/4` instead of `16/2`; use a clone · evidence: install-binary-download-progress
- 2026-08-01 · A progress-redraw fixture's non-vacuity is carried by the server's **throttle**, not the body size — an 8 MiB body with `sleep=0` yields `states=1` exactly like a 1 KiB body, which refines the earlier chunk-size reading of this same trap · evidence: install-binary-download-progress

## Rotated 2026-08-14 (during `telemetry-reject-list` / T-17 archive)

`archive-task.sh` harvested 8 new insights and, as on every prior harvest, did **not** auto-rotate the
overflow — the index stood at **38** lines against its 30 cap. This is **R-18 confirmed a fifth
time**: the script's rotation threshold counts *bullets* while `verify_all` F.4 counts *lines*, so it
never fires. The PM rotated these eight by hand.

Chosen because a committed artefact or a shipped fix now carries the knowledge, **not** because they
are old — every entry retained is one a future task would still be surprised by. Rotated here:
the four whose defect was fixed in code and whose fix is now the guard (`set -euo pipefail`
assignment abort → T-11; `mkstemp` umask and the symlink write-through → T-13; the CSI residue →
`sc doctor`), the two `posixpath` traps that `bin/sc`'s own call sites now encode, and the two
`urltest`/Clash-API specifics that belong to T-15's shipped design rather than to the next task.

- 2026-08-01 · Under `set -euo pipefail` a bare `VAR=$(cmd | grep …)` assignment aborts the script *at the assignment* when the pipeline fails, so `install.sh:373`'s version query bypasses its own `download_failed`/`check_network` handler **and** `install_report()` — the installer can exit having stated no outcome at all · evidence: install-binary-download-progress
- 2026-08-01 · sing-box colours its `check` output unconditionally, even with `stdout=PIPE`, so stripping the lone `0x1B` byte leaves the literal residue `[31mFATAL[0m` on screen — only removing the COMPLETE CSI sequence yields a pasteable line, and a fake-checker fixture cannot reveal this · evidence: sc-doctor
- 2026-08-01 · `tempfile.mkstemp`'s `0o600` is `open(2)`'s **mode argument**, not a chmod, so umask still masks it — at umask `0o277` it yields `0400`, and only an `os.fchmod` on the descriptor **before the first byte** makes the mode exactly 0600 regardless of umask · evidence: config-write-permission-hardening
- 2026-08-01 · At HEAD a planted symlink at `config.json` made `Path.write_text` write 12214 credential bytes **through** the link and the trailing `os.chmod` then narrowed the *destination*, so write-then-chmod was a redirection bug as well as a window — measured, not reasoned · evidence: config-write-permission-hardening
- 2026-08-01 · `os.stat` follows symlinks, so a **dangling** symlink raises `FileNotFoundError` and is indistinguishable from an absent file — any "absent" arm written with `os.stat` silently swallows a user-owned file that is present; `os.path.islink` is the discriminator and, being `lstat`-based, also returns False for a broken *parent* component · evidence: config-composition-layer
- 2026-08-01 · `os.path.realpath` is not raise-free on any Python this project targets: `posixpath._joinrealpath` calls `os.readlink` **unguarded** at 3.8.2 and **still** at 3.12.3 — the 3.10 rewrite guarded the `lstat`, not the `readlink` · evidence: config-composition-layer
- 2026-08-13 · sing-box's `interrupt_exist_connections` governs **external (inbound-originated)** connections only — the binary carries `interrupt.ContextWithIsExternalConnection`/`IsExternalConnectionFromContext` beside `(*Group).Interrupt`, so setting it false *spares* external connections while sing-box's own internal ones (the DoH transport carrying `remote_dns`) are torn down on every re-selection regardless · evidence: proxy-urltest-group
- 2026-08-13 · sing-box's `GET /proxies` returns entries that are not `sc` outbounds at all — its implicit `GLOBAL` selector among them — so a delay map keyed by the API's own tags is not node-keyed, and a node named after one of them silently inherits that entry's history · evidence: proxy-urltest-group
