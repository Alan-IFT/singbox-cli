# 04 — Development · T-17 `telemetry-reject-list`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

Mode: **full**. Upstream contract portions `01`, `02`, `03` all present and read in full.
`03_RATIONALE.md` read for C-3's and C-4's reasoning. `02_RATIONALE.md` opened under **T4.1**
(design drift recorded below) and **T4.2** (I-9's published anchor contradicts C-4).
`.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so the agent
schema is applied as written: tool transcripts, the fixture sources and the measurement
narratives live in `04_RATIONALE.md`.

## Summary

- The telemetry reject list ships as designed: one tuple (`TELEMETRY_NAMES`, **17** names —
  N-7 dropped under C-3), one settings reader (`_telemetry_setting()`), one overlay
  (`_telemetry_overlay()`) that `$before`-anchors a single `predefined` `NXDOMAIN` rule into
  `dns.rules` at index 2, one command (`sc telemetry block|allow|show`), six strings, one help
  row per language, one README section per language.
- C-4 needed real work and got it: the exception anchor published by I-9 was **measured** to
  break `sc telemetry allow`, and both READMEs now publish `$after {"server": "hosts_dns"}`
  instead — an element emitted in both settings states and every rule-set state.
- 30 behavioural observations against a real `sing-box 1.13.15`, each with a HEAD-clone control
  classified before the run: **30 pass, 0 fail, 0 inconclusive** — that count is of the
  **post-split** observation set, and **AC-B6b *as the criterion is written* came back
  INCONCLUSIVE** and is reported as such (its bundled control can only agree; DD-5). What passes
  are its two split halves, V-27b-i `[A]` and V-27b-ii `[D]`. `verify_all` PASSes with the
  17/0/0/1 baseline preserved.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `TRANSLATIONS["zh"]`: Q-13's six pairs, verbatim, after the IPv6 block | L-1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `# Config composition`, after `_dns_overlay()`: `TELEMETRY_NAMES` (17 names, one source comment each), `_telemetry_setting()`, `_telemetry_overlay()` | L-2 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `generate_config()`: `_telemetry_overlay()` is the third element of the existing `_compose([...])` list — one changed statement, no branch, no literal, guard still three keys | L-3 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `# Commands`, after `cmd_ipv6()`: `_telemetry_meaning()` + `cmd_telemetry()` | L-4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `main()`: the `telemetry` subparser and its `handlers` entry; read-only opt-out arm untouched | L-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `HELP_EN` / `HELP_ZH`: one `telemetry <block\|allow\|show>` row + two sub-option lines, between `ipv6` and `default-tun` | L-6 |
| `/home/alan/Programs/singbox-cli/README.md` | new `### Telemetry name rejection` (100 lines) between `### IPv6 name resolution` and `### Service control` | L-7 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | the same at the mirrored position (100 lines) — both files stay **432** lines with every heading and table row on the same line number *(PM amendment at delivery per stage-6 D-1: this read 433; `wc -l` gives 432/432. The mirror property itself holds — 25 headings, 42 fences, 63 table rows on identical line numbers)* | L-8 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one Chinese bullet under `## [Unreleased]` → `### 新增`, first in the list | L-9 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | `# Config composition`, `# Config generation` and `# Commands` rows updated; two new reusable-utility rows; the `CONFIG_BASE` row gains the **published anchors** warning | L-10 |
| `/home/alan/Programs/singbox-cli/docs/features/telemetry-reject-list/04_DEVELOPMENT.md` | this document | L-11 |

Diff totals: `bin/sc` +219/−2, `README.md` +100, `README.zh-CN.md` +100, `CHANGELOG.md` +2,
`docs/dev-map.md` +6/−4. Nothing outside NFR-3's permitted set was touched: `CONTEXT.md`,
`.harness/**`, `install.sh`, `uninstall.sh`, `systemd/` are unmodified, and `docs/tasks.md` /
`docs/batches/**` carry only the PM's own pre-existing edits.

## verify_all result

```
baseline (before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after   (all edits landed): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
delta:                      0 new FAIL, 0 new WARN, baseline preserved
command:                    bash .harness/scripts/verify_all.sh
F.6 doc-size:               PASS, with 04_DEVELOPMENT.md (120 lines) and 04_RATIONALE.md
                            (304) both counted. V-21 predicted a WARN here; it did not
                            occur, because splitting the transcripts into the rationale
                            portion kept every file under the 500-line cap. The prediction
                            still stands for 06_TEST_REPORT.md — if it WARNs, it clears on
                            archive-task and must not be fixed by deleting content

service witness (start):    MainPID=2566751  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
service witness (end):      MainPID=2566751  ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
                            identical — the live sing-box was never restarted, reloaded or
                            stopped, and no PUT/PATCH/DELETE reached the live Clash API
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| DD-1 | I-9 / FR-9 publish `{"rcode": "NXDOMAIN"}` as the per-name **exception** anchor | both READMEs publish `$after {"match": {"server": "hosts_dns"}}` | **C-4, and measured.** `{"rcode": "NXDOMAIN"}` exists only under `block`. With that recipe in `override.json`, `generate_config()` raises `at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}` under `allow` and at HEAD; `reload_or_restart()` does not catch `OverrideError`, so `sc telemetry allow` exits **1** on exactly the host that used the recipe (measured, transcript in `04_RATIONALE.md`). `{"server": "hosts_dns"}` matches exactly one element in all four {block,allow} × {rule-sets, none} states **and** at HEAD, and `$after` on it lands at index 2 — after the hosts rule (BC-11 intact) and ahead of the shipped reject rule at index 3. |
| DD-2 | I-9 / BC-8 publish `$before {"clash_mode": "Global"}` as the **addition** anchor | both READMEs publish the same `$after {"server": "hosts_dns"}` for this recipe too | **C-4's second clause.** C-4 requires both READMEs to "show the single-directive form for a user who wants both", and one array takes exactly one directive (`_directive_of`, `sc:1209` — measured: `at dns.rules: $after cannot be combined with other keys in the same object`). A single directive can carry only one anchor, so the combined form exists only if both recipes share one. `{"clash_mode": "Global"}` itself is unchanged and still matches exactly one element in all four states (V-4), so FR-9's second clause and AC-3 are unaffected; it simply is no longer the anchor the README tells users to type. |
| DD-3 | I-2 / N-1…N-18: 18 names | 17 names — **N-7 `telemetry-coverage.mozilla.org` dropped** | **C-3.** It does not resolve: `NXDOMAIN` from the system resolver and from 8.8.8.8, 223.5.5.5 and 1.1.1.1 independently, against a `incoming.telemetry.mozilla.org` control that returns `NOERROR`/`ANSWER: 3` on the same resolver. C-3 forbids substituting a corrected spelling, so it is dropped and recorded here (K-10). N-16 and N-18 both resolve and ship. Class 2 keeps one member (N-6); all four FR-2 classes are still covered and 17 ≤ 24. |
| DD-4 | L-2 / L-4 name exactly four new definitions | a fifth, `_telemetry_meaning(setting)`, was added in `# Commands` | Both forms of `cmd_telemetry()` print the meaning sentence, so spelling the `block`/`allow` conditional at each of the two sites would be two definitions of one judgment (rule 85, and the reason D-1(b) rejected inlining `_telemetry_setting()`). It takes the setting as an **argument** and reads nothing, so it adds no second reader of the setting and no second consumer of the list; V-6 confirms `TELEMETRY_NAMES` and `_telemetry_setting()` still have exactly two consumers each. Private, and named in `docs/dev-map.md`. |
| DD-5 | V-28 / AC-B6b is one observation classified `[D]` | run as one observation it is **INCONCLUSIVE**; it was split into V-27b-i `[A]` and V-27b-ii `[D]` and both pass | **C-2**, applied to a case C-2 did not enumerate. AC-B6b bundles "the excepted name resolves" (HEAD resolves it too — agreement) with "every other listed name stays rejected" (HEAD rejects none — defect). Both halves were measured; the bundled result is reported below rather than discarded. This is the same defect class the gate caught as F-4 for V-29. |

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-1 | **discharged, and superseded in part by C-4** | The exception message is recorded verbatim, three times over: candidate under `allow`, and the HEAD clone, both raise `at dns.rules: $before matched 0 elements, but exactly one is required — match: {"rcode": "NXDOMAIN"}`, rendered to the user as `Cannot use …/override.json: <that sentence>`. That measurement is what establishes DD-1. Because C-4 replaces the published anchor with one that **does** exist at HEAD, the shipped recipe's HEAD control no longer raises — it produces AC-B6b's originally stated outcome (the name resolves anyway), which is V-27b-i/ii. Both facts are recorded; neither is reported inconclusive. |
| C-2 | **discharged** | V-28 enumerates **every** behavioural step V-22…V-30, classified per observation: 30 observations, `[D]` 17 and `[A]` 13. V-29's suppressed-AAAA half is `[A]` (and its type-65 half too, in both ipv6 states), V-29's unsuppressed AAAA half and V-30 are `[D]`. One observation came back inconclusive and was reported as such, not as a pass — see DD-5. Final: **30 pass, 0 fail, 0 inconclusive.** |
| C-3 | **discharged** | Per-name first-hand resolution check, recorded verbatim in `04_RATIONALE.md`. N-7 `telemetry-coverage.mozilla.org` → `NXDOMAIN` on four independent resolvers → **dropped** (DD-3). N-16 `ulogs.umeng.com` → `NOERROR`, CNAME chain to `alog-default.umeng.com` → `223.109.148.141` → **ships**. N-18 `data.mistat.xiaomi.com` → `NOERROR`, CNAME chain to `l5.gslb.ksyuncdn.com` → `119.96.37.2` → **ships**. The other 15 were checked too and all resolve. V-9 ran against the final 17-name list. No spelling was corrected. |
| C-4 | **discharged** | Measured that no *published* anchor existed: the old one breaks `sc telemetry allow` (exit 1, transcript in `04_RATIONALE.md`). Established that one **does** exist and published it — `{"server": "hosts_dns"}`, `$after` — verified across candidate × {block, allow} × {rule-sets, none} and at HEAD, 18 combinations, all applying cleanly and all landing ahead of the shipped rule. Both READMEs state that the two recipes cannot be two `override.json` files nor two directives on one array, quote the refusal message, and show the single-directive combined form. V-18 extends to all three recipes × both settings (14 checks); V-27 runs the add recipe under both settings and the exception recipe under `block`, behaviourally. No README says the recipe must be removed before `sc telemetry allow`, because it need not be. |
| C-5 | **discharged** | `04`/`06` scope "no traceback" to `_telemetry_setting()` and only against an **absent / unreadable / non-JSON** file. No guard was added, `load_settings()` is untouched, and `_telemetry_setting()`'s guard tuple is I-3's verbatim. V-13 gained the set-form run: `sc telemetry block` on `{ this is not json` exits 1 with a Python traceback ending `json.decoder.JSONDecodeError: Expecting property name enclosed in double quotes: line 1 column 3 (char 2)`, exactly as `sc ipv6 off` does. **A second hole was found and is reported, not fixed** — see `## Open issues for review` #1. No stage doc, README, help row or changelog line claims `sc telemetry` is traceback-free. |
| C-6 | **discharged** | Both READMEs carry it at mirrored positions, no new translation key: EN *"changing the route mode does not lift the rejection: `sc mode global` and `sc mode direct` change which resolver answers other names, never whether a listed name is rejected"*; ZH *"切换路由模式并不会解除拦截：`sc mode global` 和 `sc mode direct` 改变的是其他域名由哪个解析器回答……"*. V-17 asserts the sentence in both. V-23 measures it: rejected in `global` and in `direct` alike. |
| C-8 | **discharged** | AC-12's "persisted setting" is read as **effective setting** — I-7 compares two `_telemetry_setting()` results, and that is what the implementation does. V-12 gained the third case: a fixture holding `"telemetry": "yes"`, then `sc telemetry block` → `settings.json` **changes** (`{"telemetry": "yes", …}` → `{"telemetry": "block", …}`), exactly **one** stderr line is printed naming the file, the key and both accepted values, `config.json`'s mtime is unchanged, `restart_service()` is not invoked, and the FR-8 line is printed. Exit 0. |
| C-9 | **discharged** | N-14 `cnzz.com`'s source comment now states the apex claim it rests on: *"Clause 2 clears the whole apex on ONE claim — that the site-owner console lives on umeng.com, not here — so a CNZZ apex that ever served a console page would fail clause 2 and belong off this list; that claim, not the payload, is what admits it."* N-11 `demdex.net`'s states the immediacy dependence: *"Clause 2 clears it ONLY because the denial is IMMEDIATE (~4 ms NXDOMAIN, measured) … A dropped or black-holed query here WOULD break page rendering, which is why this list never drops a query."* Both READMEs' list is a four-column table giving **name, vendor, what it carries and class** for all 17 shipped names. |
| C-10 | **discharged at stage 4** (so `06` need not record the limit) | V-26 gained the zero-node state: same fixture, `nodes.json` with an empty node list, all three modes — `NXDOMAIN`, `ANSWER: 0`, no stub receipt, 18.3–19.3 ms, against a HEAD control that resolves the name via a stub in every mode. BC-1's FR-3 clause is therefore **observed**, not merely `check`-ed. AC-B4's count is reported as actually run: **6 per probe name (3 modes × 2 rule-set states), 24 in total** across the four probe names — the AC text's "24 per name" overstates it fourfold. |
| C-7, C-11 | not mine | PM-owned. C-11's decision (the reject rule's slot) was implemented as designed and is re-measurable: V-23's `global`/`direct` rows and their HEAD controls are the evidence the PM's notice needs. |

## Open issues for review

- **`_telemetry_setting()` is not traceback-free against a non-UTF-8 `settings.json`, and neither is `sc telemetry show`.** I-3 mandates `_ipv6_setting()`'s guard tuple verbatim, and `Path.read_text()` raises `UnicodeDecodeError`, which is a `ValueError` and **not** an `OSError` — so it escapes. Measured on one fixture: `sc telemetry block`, `sc telemetry show` and `sc ipv6 show` all exit 1 with the identical `UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 0`. It is **pre-existing** (`_ipv6_setting()` and `_saved_clash_port()` have the same hole), **not a regression**, and D-10/C-5 forbid widening the tuple here — so it is reported, documented in the function's own docstring, and left to R-25's family. It deserves a pool row: one `except (OSError, ValueError)` at `load_settings()` would close it for every reader at once.
- **AC-B6b's classification is unsound as written** (DD-5): it bundles an agreement observation with a defect-reproducing one under a single `[D]`. Stage 6 should adopt the split, and the amendment belongs in `01` beside C-7's Q-5 amendment.
- **AC-B4's verification column overstates its own count fourfold** ("24 combinations compared per name"); it is 6 per probe name and 24 in total. C-10 already says to report it as run; the text should be corrected at delivery.
- **The list still has no freshness owner** (RS-7), and C-3 sharpened the point rather than blunting it: one of the eighteen names stage 2 proposed did not exist, and nothing in this task would have caught that at any later date. A pool row that re-runs the resolution check over `TELEMETRY_NAMES` would have caught it in seconds.
- **No harness is committed** (out-of-scope item; R-9 owns it). Every fixture used here is throwaway; the sources are pasted into `04_RATIONALE.md` so stage 6 can re-run them without rebuilding the rig.

## Dev-map updates

- `# Config composition` row: `TELEMETRY_NAMES`, `_telemetry_setting`, `_telemetry_overlay` added to the section inventory, in file order.
- `# Config generation` row: the compose call is now three overlays, with the note that their order is not load-bearing but is kept so source order matches emitted order.
- `# Commands` row: `cmd_telemetry()` and `_telemetry_meaning()` named as the one surface of `_telemetry_setting()` and `TELEMETRY_NAMES`.
- Two new **Reusable utilities** rows: *"Which telemetry names does this project reject, and is rejection on?"* (`TELEMETRY_NAMES` + `_telemetry_setting()`, including the `UnicodeDecodeError` hole) and *"The telemetry half of the emitted document"* (`_telemetry_overlay()`, including the three-key/`answer`-omitted/uppercase-`rcode` traps and the position argument).
- The `CONFIG_BASE` row gains the **published anchors** warning: `{"server": "hosts_dns"}` (T-17's three recipes, `README*.md:191,209,226`) and `{"clash_mode": "Direct"}` (T-14's Custom-configuration example, `README*.md:384`) are the two anchors both READMEs tell users to write into their own `override.json`, and each must keep matching exactly one element in every state; `{"clash_mode": "Global"}` is named as **not** published — it is `_telemetry_overlay()`'s internal anchor — and `{"rcode": "NXDOMAIN"}` as the worked example of an anchor that exists in only some states.

## Insight to surface

- An `override.json` anchor a README publishes must match exactly one element in **every** state the document can be in, not just the state it was written for — `{"rcode": "NXDOMAIN"}` exists only under `telemetry: block`, so the recipe shipped with it made `sc telemetry allow` exit 1 with `at dns.rules: $before matched 0 elements, but exactly one is required`, because `reload_or_restart()` does not catch `OverrideError` · evidence: bin/sc:1822-1826 + docs/features/telemetry-reject-list/04_RATIONALE.md § C-4
- `sing-box check` fully parses every `.srs` file the document references, so a fixture whose rule-sets are synthetic bytes that satisfy `srs_reject_reason()` fails with `initialize router: parse rule-set[0]: zlib: invalid header` — a `check`-based fixture must copy the host's real `.srs` bytes, and only the all-rule-sets-unusable case is testable without them · evidence: docs/features/telemetry-reject-list/04_RATIONALE.md § V-5
- A `[D]`/`[A]` control class belongs to an **observation**, never to a criterion: AC-B6b's single `[D]` bundles "the excepted name resolves" (which HEAD also does — agreement) with "every other listed name stays rejected" (which HEAD does not — defect), and run as one observation it is inconclusive while both halves pass when split · evidence: docs/features/telemetry-reject-list/04_RATIONALE.md § V-27b
- One array in `override.json` takes exactly one directive (`at dns.rules: $after cannot be combined with other keys in the same object`) and only one `override.json` exists, so two independently-documented recipes are only composable if they are published on the **same** anchor — a constraint that binds the documentation, not the code · evidence: bin/sc:1209

## Verdict

READY FOR REVIEW
