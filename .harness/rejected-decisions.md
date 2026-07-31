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
  matching SKIP").
