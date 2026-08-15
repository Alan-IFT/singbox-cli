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

## Rotated 2026-08-14 (during `status-egress-via-clash-api` / T-18 delivery)

**R-18 confirmed a sixth time** — `archive-task.sh` harvested 4 insights, leaving the index at 34
against F.4's 30, and its own rotation branch never fired (it counts bullets, F.4 counts lines).
Chosen by rule 70's "what no longer earns its line", not oldest-first. The first entry below is
**superseded**: T-18 fixed the defect it describes, and the index now carries the deeper mechanism
(`do_open`'s asymmetric wrapping) that explains why the enumeration in it was incomplete — six
escaping classes, not four.

- 2026-08-13 · `clash_api()`'s `except (URLError, HTTPError)` does not cover what its own body raises: a port that accepts and never answers yields `TimeoutError`, a non-JSON 2xx `JSONDecodeError`, invalid UTF-8 `UnicodeDecodeError`, a short body `IncompleteRead` — so every caller, not just the new one, can take a traceback on a host where something other than sing-box holds the Clash port · evidence: proxy-urltest-group
- 2026-08-14 · `geosite-private` matches the reserved TLD `test`, so a probe name like `probe.test` is **not** "matched by no DNS rule" — it is routed to `direct_dns`, silently invalidating any measurement of the no-rule class that uses a `.test` name · evidence: dns-resilience
- 2026-08-14 · `dig … ANY` uses TCP, so an `ANY` probe against a UDP-only fixture inbound returns `connection refused` in ~16 ms and measures the harness rather than the document, while `MX`/`TXT` of the same name behave as the no-rule class · evidence: dns-resilience
- 2026-08-14 · A `predefined` rule with `rcode:"NXDOMAIN"` **and** a non-empty `answer` emits a self-contradictory reply — `status: NXDOMAIN` carrying `ANSWER: 1` — and still passes `sing-box check`; an omitted `rcode` silently means `NOERROR`, and a lowercase `"nxdomain"` is a hard `check` failure, so all three of key-absence, explicitness and case are load-bearing · evidence: telemetry-reject-list

<!-- rotated 2026-08-14 at T-19 `ruleset-staleness-visibility` delivery: the index hit 32/30 on harvest (R-18, seventh confirmation — archive-task.sh counts bullets while verify_all F.4 counts lines, so its rotation branch can never fire on a file with a header). Chosen by rule 70's "what no longer earns its line": both belong to DNS/telemetry work that has shipped (T-16, T-17) and both are narrow harness details rather than standing constraints. -->
- 2026-08-14 · sing-box 1.13.15's `predefined` DNS-rule decoder **rejects** unknown fields while its `reject` decoder **accepts** them — `{"action":"reject","zzz_nope":1}` and even a meaningless `rcode` on a `reject` rule pass `check` and do nothing — so the bogus-key acceptance control that proves a key is real is sound **only** against `predefined`, and `reject` + `rcode` is a validating no-op trap · evidence: telemetry-reject-list
- 2026-08-14 · `dig`'s default EDNS COOKIE defeats sing-box 1.13.15's upstream DNS cache entirely — 5 client queries produce 5 upstream queries with it and 1 with `+nocookie` — so any harness measuring caching or "was upstream contacted twice" is measuring the cookie; separately a `dig` subprocess costs ≈17.5 ms of pure startup here, so a `dig`-driven 100 ms assertion really asserts ≈82 ms of headroom · evidence: telemetry-reject-list

## Hand-rotated 2026-08-14 (during `sc-config-show` / T-06 delivery)

`archive-task.sh` harvested 4 insights and rotated **none** — it counts *bullets* (22) against
30 while F.4 counts *lines* (30), so the index landed at 34/30. This is **R-18, confirmed an
eighth time**; the rotation below is by hand. The four were chosen by rule 70's "what no longer
earns its line" rather than oldest-first (the T-05 precedent): each one's owning task is
delivered and its lesson is now encoded in shipped code or corrected docs, and the last is
superseded in its family by T-06's stderr-buffering entry.

- 2026-08-01 · A differential harness for `generate_config()` must run baseline and candidate at the **same** fixture path, because `RULES_DIR` is emitted verbatim inside `route.rule_set[].path` — two `mkdtemp()` roots yield a 100% config mismatch that reads exactly like a refactor bug · evidence: config-composition-layer
- 2026-08-14 · sing-box 1.13.15 refuses to start when a DNS server's `detour` names a bare `{"type":"direct"}` outbound (`FATAL start dns/udp[remote_dns]: detour to an empty direct outbound makes no sense`) while accepting a `selector` whose only member is `direct` — so a fixture can pass `sing-box check` and still die at run · evidence: dns-resilience
- 2026-08-14 · An `override.json` anchor that a README publishes must match exactly one element in **every** state the document can reach, not just the state it was written for: `{"rcode":"NXDOMAIN"}` existed only while the reject list was on, so the shipped recipe made `sc telemetry allow` exit 1 with `$before matched 0 elements` — and because the setting is persisted *before* regeneration, the host was left recorded `allow` with a `config.json` never regenerated · evidence: telemetry-reject-list
- 2026-08-14 · `sys.exit(<str>)` is interpreter-handled and flushes Python's `sys.stdout` **before** writing the string to `sys.stderr`, so swapping it for an in-run `sys.stderr.write` reorders the merged `2>&1` capture `install.sh` records — the aggregate lands ahead of the still-buffered stdout and splits the last per-file line in two — unless an explicit `sys.stdout.flush()` precedes it; proved live by a mutant build differing from HEAD at byte 836 · evidence: ruleset-staleness-visibility


## Hand-rotated 2026-08-14 (during `doctor-extended-checks` / T-20 delivery)

`archive-task.sh` harvested 4 insights and rotated **none** — it counts *bullets* against 30 while
F.4 counts *lines*, so the index landed at 34/30. This is **R-18, confirmed a ninth time**; the
rotation below is by hand, and the fix remains to make the script count what F.4 counts.

Chosen by rule 70's "what no longer earns its line" rather than oldest-first (the T-05 precedent).
Each one's owning task is delivered and its lesson is now carried by shipped code, a corrected
document, or settled habit. Deliberately **kept** in the index despite being older: the `LANG` and
`CLASH_PORT` reassignment traps and the new `is_running()` twin (three live fixture-vacuity
hazards), `_init_files()`'s hard-coded `/var/lib/sing-box` (a safety floor), the `[D]`/`[A]`
control-class rule (methodology, reused this task), the E.6 heading regex, and the
`clash_mode`-rule-precedence entry, which stays because **R-50 is open against exactly that
mode-independence property**.

- 2026-08-14 · `git diff --stat`'s bar column counts insertions **plus** deletions, so quoting it as an added-line count inflates the number and silently rescopes any "the added lines were scanned" claim built on it — the added count is `--numstat`'s first field, or the `N insertions(+)` trailer · evidence: dns-resilience
- 2026-08-14 · `domain_suffix` in sing-box 1.13.15 is **label-boundary aware**, not the raw character suffix the v2ray era assumed — one dotless entry matches the apex and every subdomain at any depth, case-insensitively, and does **not** match `notexample.com` or `example.com.evil.net`, so the habitual `domain` + `.suffix` pairing is dead weight defending against a false positive this binary cannot produce, while a bare leading-dot `.example.com` is the genuinely wrong form because it silently leaves the apex resolvable · evidence: telemetry-reject-list
- 2026-08-14 · `sing-box check` fully parses every `.srs` the document references, so a fixture with synthetic rule-set bytes that satisfy this project's own `srs_reject_reason()` still dies at `initialize router: parse rule-set[0]: zlib: invalid header` — a `check`-based fixture must copy the host's real `.srs` bytes, or only the all-rule-sets-unusable state is actually testable · evidence: telemetry-reject-list
- 2026-08-14 · `json.loads` parses with the **C scanner**, whose depth budget is not the Python recursion limit, so a ~1000-level-deep document parses cleanly and it is the *pure-Python* walk over the result that raises `RecursionError` — refuting the natural assumption (ruled at gate D-2) that a recursive JSON transform inherits the parser's own depth protection · evidence: sc-config-show

## Rotated 2026-08-14 (hand-rotated during T-21 `ruleset-source-strategy-from-v2rayn`; R-18 confirmed a tenth time — `archive-task.sh` counts bullets (22) while verify_all F.4 counts lines (30), so its rotation never fires at the cap)

Chosen by rule 70's "what no longer earns its line", not oldest-first: both are QA-harness *methodology* rather than the project-specific fact this index is for.

- 2026-08-14 · A `[D]`/`[A]` control class is a property of an **observation**, never of a criterion: an acceptance criterion that bundles "the excepted name resolves" (which HEAD also does) with "every other name stays rejected" (which HEAD does not) can only ever produce an *agreeing* control, making it inconclusive by construction no matter how good the rig — split per observation, both halves pass · evidence: telemetry-reject-list
- 2026-08-14 · A fixture that proves "the command under test created nothing" must also stop its **own loader** from creating the config directory or a stub binary, because those writes land in the same `find` listing and read exactly like the command having initialised — the negative is only meaningful with raisers over `_init_files` / `_resolve_clash_port` plus a positive control proving a raiser *does* fire for a command that initialises · evidence: sc-config-show

## Rotated 2026-08-15 (during `restricted-network-regression-test` / T-07 archive)

**R-18 confirmed a ninth time.** `.harness/insight-index.md` stood at exactly 30 `wc -l` lines
against F.4's 30 cap, and `archive-task.sh:85-95` still counts **bullets** (`grep -E '^[[:space:]]*-'`)
where F.4 counts **lines**, so its rotation branch cannot fire on any index carrying a header —
30 bullets is 38 file lines. T-07's gate re-derived the exact mechanism (`03_RATIONALE.md` §6) and
made pre-harvest rotation a binding delivery condition (GC-8). Three lines rotated by hand to make
room for two harvested insights. Chosen by rule 70's "what no longer earns its line": each is either
task-specific to work that has shipped, already carried by a `docs/tasks.md` row, or a narrower
restatement of a line that stays.

- 2026-08-13 · A sing-box `urltest` group demotes a member that is slow or refuses within about one `interval`, but **never** demotes a member that accepts the connection and then never answers — a probe that hangs never completes, so the cached selection is never revisited even after the stale history is dropped, and there is no per-probe timeout option to change it · evidence: proxy-urltest-group
  - **Why rotated:** T-15 shipped and its selection state machine is now described in `docs/dev-map.md`;
    the residual it left is filed as **R-21/R-49** on the board, which is where a future task meets it.
- 2026-08-14 · A `bin/sc` fixture that repoints all eight path constants into a temp root is still **not** isolated from the live sing-box: `CLASH_PORT` is read from the module global when `main()` is not driven, and 29090 is the port the real instance listens on here, so `cmd_status()`'s `clash_api("GET","/configs")` was answered by the running service from inside a fully redirected root — a fixture must bind a port it has proved free · evidence: ruleset-staleness-visibility
  - **Why rotated:** a narrower restatement of the `main()`-reassigns-`CLASH_PORT` line, which stays and
    carries the same warning in its general form. Two lines for one trap stopped earning the space.
- 2026-08-14 · The Clash API's `GET /dns/query` is answered from, **and populates**, the running install's own DNS cache (`experimental.cache_file`), so each probe warms the entry the next probe reads — measured live: a fresh name costs 175 ms, the same name 3 s later 4 ms with the authority TTL decremented 195 → 190 → 186, and a negative answer is held 1800 s — which means a "DNS timing" reading inside that window reports a cache hit rather than resolution through the tunnel · evidence: doctor-extended-checks
  - **Why rotated:** carried in full by **R-48** on the board, owned by the next task touching
    `_doctor_dns` or the egress pair — the one place it will actually be read.

## Rotated 2026-08-15 (during `share-url-userinfo-contract` / T-22 delivery)

Three lines rotated **before** the harvest so the index stays inside F.4's 30-**line** cap (`archive-task.sh` counts *bullets*, so its own rotation branch cannot fire — **R-18**, confirmed a tenth time; **T-27** owns the one-line fix).

- 2026-08-14 · A sing-box DNS rule placed **after** the two `clash_mode` rules is unreachable in both non-`rule` modes, because each `clash_mode` rule is a catch-all within its own mode — and for a name-scoped rule that is not "merely unblocked" but the name **measurably leaked to an upstream resolver** (`NOERROR`, 1 record, recorded at the stub, in `global` and `direct` alike), which is why a privacy or suppression rule must precede them · evidence: telemetry-reject-list
  - **Why rotated:** T-17 shipped the rule-ordering fix and the general form of the trap (a `clash_mode` rule is a catch-all within its own mode) is now structural in the emitted document. Kept here for the measurement, which is the part that would be expensive to redo.
- 2026-08-14 · `urlparse().username` stops at the first `:` in the userinfo, so the idiom `userinfo = p.username; if ":" in userinfo:` is **structurally dead** — `bin/sc:713` has therefore never stored a tuic link's password and every tuic outbound `sc` has ever emitted carries `"password": ""`, a silent authentication failure that no config-level test can see because the emitted document is well-formed · evidence: sc-config-show
  - **Why rotated:** superseded by **T-22 `share-url-userinfo-contract`**, which fixed the defect this line described in the present tense — `bin/sc` no longer reads `.username` anywhere. The durable half of it now lives in the code itself, in `CONTEXT.md`'s **userinfo reading** glossary term, and in T-22's own index line (a real `sing-box check` accepts an empty tuic password, so no config-level test can catch a lost credential).
- 2026-08-15 · `RULESET_BASES`' base 4 is a byte-**suffix** of base 3 (base 3 is `https://ghfast.top/` followed by base 4 verbatim), so any substring test for "the log names all four bases" counts **4 on a log naming only 3** — measured 4 vs 3 against a synthetic 3-of-4 `install.log` — and a per-entry boundary match (`failed: <base> -> ` / `; <base> -> `) is the only form that counts honestly · evidence: restricted-network-regression-test
  - **Why rotated:** narrow to one artifact's log-parsing assertion, and the artifact (`restricted-network-regression.sh`) already carries the per-entry boundary match the line argues for. It stopped earning a line on a 30-line index.

### Rotated at T-23 `state-file-io-contract` delivery (2026-08-15)

Four lines rotated by hand to make room for T-23's harvest, keeping `.harness/insight-index.md` under `verify_all` F.4's 30-line cap. **R-18 confirmed a twelfth time** — `archive-task.sh` counts *bullets* against 30 while F.4 counts *lines*, so its rotation branch still cannot fire on an index with a header; **T-27** owns the one-line fix. Selection was by value rather than by age (rule 70: cuts remove what no longer earns its line), so three older lines that are still load-bearing — the `LANG` reassignment trap, `_init_files()`'s hard-coded `/var/lib/sing-box`, and `settings.json` being 0644 on every install — were kept.

- 2026-08-01 · `verify_all` E.6 matches the heading regex `^##\s+Adversarial\s+tests`, so a *numbered* heading such as `## 3. Adversarial tests` makes E.6 FAIL rather than SKIP — a self-inflicted red that costs a debug cycle in every task whose QA numbers its sections · evidence: sc-doctor
  - **Why rotated:** now carried in every `/harness*` dispatch this project issues, checked automatically by `verify_all` E.6 itself, and stated in `AI-GUIDE.md`'s declare-done gate. The index line was the least authoritative of the four copies.

- 2026-08-01 · `check-i18n-parity.sh` enumerates keys **from the two tables**, so a `t <key>` *call site* naming a key absent from **both** is invisible to B.2 while killing the installer outright under `set -u` (`local fmt` has no default, and `|| true` cannot catch an expansion error) · evidence: config-write-permission-hardening
  - **Why rotated:** narrow to one script's blind spot on one file. B.2 parses `install.sh` only, and that scope limit is now recorded where it bites — T-23's gate condition C-9 states it for any task adding a translation key.

- 2026-08-14 · sing-box 1.13.15 has **no DNS-query-level timeout at any level** — `"timeout"` is rejected on a DNS server, on the `dns` block and on a DNS rule, with a bogus-key control proving the decoder rejects unknown fields — and its own per-query deadline is a fixed 10.0 s at which the query is **dropped silently**, with no answer, no retry and no second server · evidence: dns-resilience
  - **Why rotated:** superseded as a *decision* input by `docs/batches/followups/BATCH_PLAN.md` §"Rows deliberately not made into tasks", which rules R-23/R-35 out of scope with this fact as the ground, and by R-23's own row in `docs/tasks.md`. Still true; no longer needs to cost a line at every task start.

- 2026-08-14 · `urlopen(timeout=N)` bounds each socket operation, never the call's total wall clock: a peer dripping one body byte every 2 s keeps a `timeout=3` request alive **30.1 s** and then returns success, so any "it gives up after N seconds" claim about `clash_api()` or `_egress_ip()` is false as written · evidence: status-egress-via-clash-api
  - **Why rotated:** same ruling as the line above — R-35's row in `docs/tasks.md` carries the number and the measurement, and the batch plan cites it as a reason not to build a task. It is a fact to reason with, not a trap that fires unannounced.

## Rotated 2026-08-15 (during `override-error-envelope` / T-24 archive)

`archive-task.sh` harvested 2 new insights and again did **not** auto-rotate the overflow (**R-18,
confirmed a thirteenth time** — it counts bullets where `verify_all` F.4 counts lines, so on an index
with a header the branch can never fire; **T-27** owns the one-line fix). The index stood at 31 lines
against its 30 cap; the PM rotated these two by hand.

Both are **rule-set sourcing research**, and both were chosen for the standard reason: a committed
artefact now carries the knowledge. `RULESET_BASES`' failure-domain count lives in **R-53**'s row in
`docs/tasks.md` (filed explicitly as an observation that proposes nothing, since 24/24 fetches
succeeded), and the publishing-layout survey is settled history recorded in T-20's and T-21's
delivery documents. Neither is a trap a future task can walk into unaware — unlike the entries kept,
which are all live hazards for the *next* harness someone writes.

- 2026-08-14 · No publisher of sing-box rule-sets ships `.srs` as a GitHub **Release asset** — MetaCubeX/meta-rules-dat (1 release, 28 assets), 2dust/sing-box-rules (30), SagerNet/sing-geosite (11) and sing-geoip (4) publish only aggregate `.dat`/`.db`/`.mmdb`/`.7z` there and keep every `.srs` on a git **branch** (3790 files on one such branch) — and the `.db` they do ship is refused by sing-box 1.13.15 with `geosite database is deprecated in sing-box 1.8.0 and removed in sing-box 1.12.0`, a bogus-key control proving the field is decoded and *then* rejected · evidence: ruleset-source-strategy-from-v2rayn
- 2026-08-14 · GitHub **Release assets are not a second CDN**: `github.com/…/releases/download/…` 302s to a signed, ~1 h-expiry `release-assets.githubusercontent.com` URL answering on **185.199.108.133** — one of the same four Fastly anycast addresses `raw.githubusercontent.com` resolves to, `via: 1.1 varnish` — so a network blocking raw *by address* blocks releases with it; measured alongside, `cdn.jsdelivr.net` and `testingcf.jsdelivr.net` share one Cloudflare edge, leaving `RULESET_BASES`' four entries spanning **three** failure domains · evidence: ruleset-source-strategy-from-v2rayn

## Rotated 2026-08-15 (during `output-layer-contract` / T-25 archive)

Hand-rotated — `archive-task.sh`'s own rotation is dead code (**R-18**, confirmed a **fourteenth** time; it counts bullets against 30 while `verify_all` F.4 counts lines, so with a 8-line header the branch can never fire). **T-27** owns the one-line fix. All three entries below stopped earning an always-loaded line because the knowledge is now carried by shipped code and a closed row: the `do_open` escaping classes by T-18's envelope at `clash_api()` (R-20 closed), the `parse_ss` SIP002 selection by T-22's `_userinfo()` (R-42 closed), and the `clashapi` symbol probe by T-20's shipped `sc doctor` rows.

- 2026-08-14 · `urllib.request.AbstractHTTPHandler.do_open` wraps only `h.request()`'s `OSError` into `URLError` and bare-re-raises everything `h.getresponse()` raises, so `except (URLError, HTTPError)` misses a peer that resets or closes early — a plain RST gives `ConnectionResetError`, a clean FIN with no response gives `RemoteDisconnected`, and a malformed status line gives `BadStatusLine`, which is neither an `OSError` nor a `ValueError` · evidence: status-egress-via-clash-api
- 2026-08-14 · A `clashapi.*Router` symbol present in the `sing-box` binary proves only that a route is **mounted**, never that its body is supported: `clashapi.scriptRouter` is present while `/script` answers "not supported", so symbol-table grep is a sound existence probe (the Go linker drops unreferenced functions, and a fabricated symbol name matches 0) but must be paired with one live read-only request before any response shape is designed against · evidence: doctor-extended-checks
- 2026-08-15 · `parse_ss`'s SIP002 arm is selected by a `ValueError` from the **colon split inside its `try`**, not by base64 validity — `_b64dec` succeeds on ordinary plaintext method names — so a colonless plaintext userinfo fell through to the `except` arm and raised a *second*, uncaught `ValueError` there, printing `Error: not enough values to unpack` · evidence: share-url-userinfo-contract
- 2026-08-01 · `_init_files()` hard-codes `/var/lib/sing-box` as a `Path` literal — the one directory in it not built from a repointable module-level constant — so a redirected-paths harness driving any non-doctor command still writes to the real `/var/lib` · evidence: sc-doctor
- 2026-08-01 · `main()` reassigns `LANG` from `_load_lang()` after import, so a `bin/sc` harness that sets only `sc.LANG` renders **English** on every `main()`-driven path — Chinese assertions then pass vacuously, because "no newline, no 失败" is also true of English · evidence: config-composition-layer
- 2026-08-14 · A sing-box DNS rule chain **never falls through on failure**: a black-holed, `NXDOMAIN` or `SERVFAIL` answer is final, and `dns.final` is the *no-rule-matched* routing default rather than a failure fallback — so an always-true catch-all rule makes `final` structurally unreachable, and "add a fallback resolver" is not expressible in the document at all · evidence: dns-resilience
