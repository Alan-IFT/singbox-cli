# Batch Plan — followups

> Created: 2026-08-15
> Default mode: full
> Stop policy: strong-signal-only

**Provenance.** Every row below is derived from open rows filed by the `default` pool's nine
deliveries (R-15 … R-61 in `docs/tasks.md`, plus the still-open blocks rotated into
`docs/tasks-archive.md`). It is **not** a transcription of that list. Per
`.harness/rules/85-design-discipline.md` — including the **"Less is more"** section the owner added
on 2026-08-14 — the ~40 open rows were grouped by **cause**, and each row below is the one seam whose
repair discharges a family. Seven tasks cover roughly 25 filed rows; the remainder are deliberately
**not** built (see "Rows deliberately not made into tasks").

## Tasks

| ID | Slug | Goal (one sentence) | Mode | Depends on | Status |
|---|---|---|---|---|---|
| T-22 | share-url-userinfo-contract | Give the share-URL parsers one userinfo contract: `urlparse().username` truncates at the first `:`, so tuic silently ships `"password": ""` on every node and trojan/hy2 silently truncate any password containing a colon — while `parse_ss` already does it correctly by hand, making this one judgment with four call sites and three wrong ones. | full | — | done |
| T-23 | state-file-io-contract | Give every JSON state file one read/write contract — explicit `encoding=`, one catch family, and a shape check — so a non-UTF-8 or non-object `settings.json`/`nodes.json` reaches the user as a sentence instead of a traceback, for all readers at once rather than three guard tuples. | full | — | done |
| T-24 | override-error-envelope | Put one exception envelope and one type-mismatch vocabulary over the override/merge pipeline, so a malformed `override.json` (wrong type, too deep, non-object rule element) is a named sentence rather than a traceback or a silent array replacement. | full | — | done |
| T-25 | output-layer-contract | Give the user-facing output layer one contract: no key renders as its own name, one separator convention across `sc status` and `sc doctor`, plural handling for every count key at once, and flush discipline so a redirected `sc status` cannot interleave subprocess output above its own headings. | full | — | done |
| T-26 | doctor-rows-establish-their-fact | Close the three `sc doctor` rows that report a conclusion they did not establish — a DNS probe answered from the cache it just warmed, a node-delay count read as 0 on a host with no init system, and a position-blind AAAA membership test that reads OK while the rule is not in force. | full | — | done (R-48 closed by **narrowing the claim** — weaker guarantee than the old wording implied) |
| T-27 | harness-self-maintenance | Fix the three harness defects that tax every future task: `archive-task.sh`'s rotation counts bullets where `verify_all` F.4 counts lines (so it can never fire and every one of twelve deliveries hand-rotated), rule 70 declares no stage-doc boundary rule, and the committed-diff AC template omits `docs/batches/**`. | full | — | done (**R-18, R-36, R-37 all closed**; R-18 proved by this task's own archive run — `Rotating 4`, index back to 30, **first delivery in seventeen needing no hand rotation**) |
| T-28 | committed-test-suite | Discharge R-9: make `bin/sc` testable and tested — a committed, runnable suite wired into `verify_all` and its `.ps1` mirror, with `baseline.json` finally honest, built on T-07's artifact and its four known defects. | full | T-22, T-23, T-24 | done (**R-9 closed after five deferrals**; `verify_all` gains B.4 + B.5, 17 → 19 PASS) |

## Notes

### How these seven were derived

Each row states the **cause** its family shares, and the filed rows it discharges. Rule 85's two
seam tests were applied to each: *does one task compute what only another consumes?* and *do two
tasks need the same judgment?*

- **T-22 — one judgment, four call sites, three wrong.** `urlparse().username` stops at the first
  `:` in the userinfo. `parse_tuic` (`bin/sc:763-768`) therefore has a **structurally dead**
  `if ":" in userinfo:` branch and writes `"password": ""` into every tuic outbound `sc` has ever
  emitted — a silent authentication failure, not a display defect (**R-42**, the highest-impact row
  the pool produced). Verified 2026-08-15 that the class is **wider than R-42 states**:
  `parse_trojan` (`:696`) and `parse_hy2` (`:744`) both read `unquote(p.username or "")` for schemes
  whose whole userinfo is the password, so any password containing `:` is silently truncated.
  `parse_ss` (`:712-717`) already splits correctly by hand — the correct implementation is *already
  in the file*, which is what makes this one task rather than three fixes. Carries **R-46**
  (`SECRET_KEYS` omits inbound TLS key material) only if the fix touches the credential vocabulary;
  otherwise leave it filed.
- **T-23 — one seam, four readers, three catch tuples.** `load_settings()` lets `UnicodeDecodeError`
  (a `ValueError`, **not** an `OSError`, so the repo's habitual guard misses it) and a valid-JSON
  non-object both reach the user as a traceback, for every reader (**R-29**, which explicitly
  supersedes and widens **R-25**). The family names four readers, not two: `_ipv6_setting()`,
  `_telemetry_setting()`, `_saved_clash_port()` and `load_nodes()` (T-18 Q-5). The write side is the
  same seam from the other end — `_write_private()` and `save_nodes()` dump with
  `ensure_ascii=False` through `os.fdopen(fd, "w")` with **no** `encoding=` (**R-17**), and QA's
  refinement is the useful part: under `LC_ALL=C` the raise fires in `load_nodes()` *before* the
  write path is reached, so a write-only fix does not make a non-ASCII tag work. **R-27** (a
  malformed `settings.json` is rewritten to a single key, dropping `lang`/`mode`) is the same file's
  repair path and belongs with it. T-06's unnumbered measurement is the acceptance oracle: a valid
  document tagged `香港节点` gives `'ascii' codec can't decode byte 0xe9` on a `C`-locale host.
- **T-24 — one error model, three symptoms.** **R-15** says it outright: the coherent fix is *one
  exception envelope over the override pipeline*, not a per-shape guard — a `RecursionError` from a
  500-deep document prints 2 999 lines into a log `install.sh` redirects, and a non-object element in
  `dns.rules` reaches `AttributeError`. **R-16** is the missing half of the same model: the merge has
  no type-mismatch vocabulary, so a bare object silently replaces an array. It has now been declined
  by T-15, T-16, T-17 **and** T-21 (**R-54** re-homed it) — four declines is the signal that it needs
  a task of its own rather than another owner. **R-26** makes `OverrideError` provenance structural
  at its third site *at zero behavioural cost*, which is the cheapest possible member of this family.
  **R-44** is the same depth problem measured from the other side (`json.loads` uses the C scanner,
  so the pure-Python walk is what overflows) — note it argues **against** adding a cap, so it
  constrains the envelope rather than demanding machinery.
- **T-25 — the output layer has no single contract.** `TRANSLATIONS` has no `en` table, so `t()`
  returns the key verbatim and five `ls.*` keys print as `ls.idx ls.active ls.type ls.name
  ls.address` (**R-19**, known since T-02 and never filed against these five; the English header now
  reads `ls.idx … Delay`, visibly mixed). The same layer produces `1 days ago` (**R-40**, whose row
  explicitly says a future task should add plural handling for *every* key at once, not one) and an
  ASCII `, ` in `sc status` where `sc doctor` uses a localised `，` (**R-38**). **R-33** is the same
  surface from the buffering end: `sc status > file` prints `ip` output above the first heading
  because `print()` is block-buffered while its subprocess children write fd 1 immediately — and the
  fix shape is already in-tree, since `_doctor_print()` flushes per row for this exact reason.
  **R-34** ("exactly one value line per heading" is falsifiable) is the promise this task should
  narrow while it is in there.
- **T-26 — a row reports a fact it did not establish.** Three rows, one cause: the verdict is derived
  from a proxy for the fact rather than the fact. **R-48** — the DNS probe is answered from *and
  populates* the install's own `cache_file`, so within the TTL window the row reports a cache hit
  rather than resolution through the tunnel. **R-49** — `is_running()` returns `False` from its final
  line without reaching `subprocess.run` when neither `SYSTEMD` nor `OPENRC` is set, so the node-delay
  row reads `0/{total}` while `/proxies` holds delays. **R-50** — the AAAA membership test is
  position-blind, while **index 0 is what makes the suppression mode-independent** (measured: at
  index 3, types 64/65 are not suppressed in `direct`). R-50's row says explicitly that FR-4 and I-6
  both specify a membership test, so this needs a **requirement ruling**, not just a code edit.
  **R-24** (`sc ipv6` says "Nothing changed" without naming the escape) is the same honesty defect on
  a different command and rides along if it costs one line.
- **T-27 — the harness taxes every task.** **R-18** is confirmed **nine times, once per delivery**:
  `archive-task.sh:89-94` counts bullets (`grep '^\s*-\s'`) against 30 while `verify_all` F.4 counts
  **lines**, and the two differ by the file's header, so on any index with a header the branch can
  never fire. It is a one-line fix that has cost twelve deliveries a manual rotation. **R-37**
  (confirmed **seven times**, five of them inside T-07 alone) is one missing section in rule 70.
  **R-36** is the AC template's missing third carve-out for `docs/batches/**`. Together: three small
  fixes, each of which is currently paid for on every future task. **Caveat that belongs in the
  design:** `archive-task.sh` is plugin-vendored and already carries one local fix that
  `/harness-upgrade` may silently revert — the same is true of `guard-rm.sh`, which has now blocked
  seven commits containing no `rm` by misparsing heredocs as nested pwsh. Decide whether a local fix
  is durable before writing one.
- **T-28 — the row the project has deferred five times.** **R-9** (with **R-4**: `baseline.json`
  still reads `test_count: 0` after twelve deliveries, and every task before T-11 built a throwaway
  harness and discarded it — five of them). T-07 did **not** claim it but made it materially cheaper:
  a committed, runnable, git-tracked test artifact that never imports `bin/sc` now exists to build
  from, and its own four defects (**R-56** userinfo authority accepted as covered, **R-57** two
  `--source` derivation defects, **R-58** the comment asserting no CJK is the file's only CJK,
  **R-59** `rblock` evaluated before E3/E4's own verdicts — which R-59 says needs a *requirement
  ruling*, being a real collision between K-11's letter and BC-10) are pre-diagnosed with named
  one-line fixes. It depends on T-22/T-23/T-24 because those three change the behaviour a suite would
  otherwise pin in its currently-wrong form. **R-9's own scope is unchanged and non-negotiable**: it
  must permanently defuse the import-time auto-elevate, refuse under root, never touch `/etc`, and
  never touch the live service — `verify_all` would otherwise import `bin/sc` on the owner's live
  machine on every run, forever.

### Rows deliberately not made into tasks

Filed, still open, and **correctly not built** — recording why is the point, so no future pass
re-litigates them:

- **Operator obligations (R-30, R-31, R-41, R-47, R-52, R-60).** Human-only by construction; recipes
  live in `.harness/operator-obligations.md`. No agent in this project can discharge them.
- **Capability gaps with no expressible fix (R-23, R-35).** sing-box 1.13.15 has no DNS-query-level
  timeout, no fall-through on failure, and `dns.final` is the no-match default; and `timeout=N`
  bounds each socket operation rather than the call. Both are *numbers to reason with*, not defects.
  Revisit only on a sing-box release that adds the mechanism.
- **Observations that propose nothing (R-53).** The four `RULESET_BASES` entries span three failure
  domains, not four — but 24/24 fetches succeeded, so there is no evidence a change is needed.
- **Accepted boundaries (R-21, R-27's blast radius, R-45, R-46, R-51, R-61).** Each was ruled on by a
  gate or a reviewer with reasons. **R-45** in particular is one rule 85 explicitly declines to fund:
  widening the `BrokenPipeError` guard is machinery for a case nobody has reported, and the measured
  behaviour is exit 120 with no traceback. **R-61** is a lesson for the *next* size cap, not work.
- **Documentation-only rows (R-55, R-28).** R-55's two README sentences and R-28's `TELEMETRY_NAMES`
  freshness check are real but belong to the next task that opens those files; neither justifies a
  pipeline. R-28's need is *proven* (one of eighteen proposed names did not resolve), so if it is
  still open when another task touches the tuple, it must be discharged then.
- **R-22 is a practice, not a row to close.** "An AC set that pins the artifact and never the
  behaviour will pass a gate it should fail" is now carried in every dispatch and was honoured by
  T-18, T-19, T-06 and T-20. It stays filed as the reason, not as work.

### Ordering

T-22 first: it is the only row in this pool that is a **live, silent, user-affecting bug** — every
tuic node `sc` has ever emitted carries an empty password. T-23 and T-24 next, both being error-model
work that T-28 would otherwise pin in its wrong form. T-25 and T-26 are user-facing honesty. T-27 is
tiny and pays for itself on every subsequent task, but is placed after the product rows because it
touches plugin-vendored files whose durability needs a ruling. T-28 last, by dependency.

## Column reference

- **ID** — pool-local identifier (`T-NN`), continuing the `default` pool's numbering to stay unique
  against `docs/tasks.md`.
- **Slug** — kebab-case; becomes `docs/features/<slug>/`.
- **Goal** — one sentence; becomes pm-orchestrator's task-description input.
- **Mode** — `full` (default 7-stage) | `plan` (stages 1-3 only) | `goal` (Dev + QA loop).
- **Depends on** — comma-separated `T-NN` IDs in the same pool, or `—` for none.
- **Status** — `pending` | `in-progress` | `done` | `failed` | `blocked` | `needs-human` | `skipped`.
