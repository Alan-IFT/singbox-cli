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
