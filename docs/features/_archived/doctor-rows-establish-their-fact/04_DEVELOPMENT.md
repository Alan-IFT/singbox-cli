# 04 — Development · T-26 `doctor-rows-establish-their-fact`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

1. All ten edits E1…E10 landed in the design's migration order; the AAAA row now tests the
   **emitted position** it reads from `_dns_overlay(suppress)`, the node-delay row states a count
   read from `/proxies` on the branch where the caller already established the API answers, and the
   three DNS-row sentences plus `sc ipv6`'s no-op line say only what their probe established.
2. `bash .harness/scripts/verify_all.sh` from the repository root **PASSES**, baseline preserved:
   PASS 17 / WARN 0 / FAIL 0 / SKIP 1.
3. `bin/sc` is `+55/−45` with **no new top-level `def` or `class`** (113 before, 113 after), zero
   `TRANSLATIONS` keys added and exactly one deleted (183 → 182 `zh` entries).

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `_dns_overlay(suppress)` takes the decision; `generate_config()`'s compose list passes `ipv6_decision()[1]`; `_doctor_ipv6()` reads that overlay's `$prepend` payload and compares it against the head of `dns.rules`; the PROBLEM sentence names both BC-3 causes with `{override}`; docstring contracts corrected at `_aaaa_rule()`, `_dns_overlay()`, `_doctor_ipv6()` | E1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `stored_delays()`'s guard is now `if port is None and not is_running():`, one changed line, guard kept inside the function; its docstring states the two-clause `port` interface — the guard paragraph's own claim was corrected from "every **future** caller inherits it" to "every caller **naming no port** inherits it" (`:2222`, the one sentence E2 falsifies, now agreeing with `docs/dev-map.md:65`), and the paragraph that states the named-port half is two lines rather than three because the narrowing is no longer said twice (`:2225-2226`); `_doctor_clash()` gained no call and no check, and its PROBLEM sentence states what was **read** | E2 |
| `/home/alan/Programs/singbox-cli/bin/sc` | the three DNS-row sentences replaced (one shared cache clause across both PROBLEM branches); probe, endpoint, name, type, timing and classes untouched; `_doctor_clash()`'s docstring gained the cache sentence | E3 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `cmd_ipv6`'s no-op `print()` swapped to `cmd_telemetry`'s existing key; the orphaned key at `:192` deleted in the same edit | E4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `TRANSLATIONS["zh"]`: five entries re-worded in place, one deleted, none added; every re-worded key carries the same placeholder set on both halves | E5 |
| `/home/alan/Programs/singbox-cli/README.md` | lines 263 / 266 / 272 / 279 per I-9; line 280 (exit `2`) unchanged, because no row became UNKNOWN where it was PROBLEM | E6 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | the same four lines, same numbers — the mirror still aligns line-for-line | E7 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one entry under `## [Unreleased]` → `### 修复`, in Chinese, naming the three rows, the `sc ipv6` line, the byte-identical `config.json` and the two **measured** exit-status transitions: an init-less host with an answering Clash API goes `1` → **`2`** (its 「服务」/「开机自启」 rows are already `[未知]`, and once no `[异常]` remains the exit reports 未知), a host whose rule is not first goes `0` → `1` | E8 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | four "Reusable utilities" rows: `stored_delays()` (two-clause guard), `_dns_overlay(suppress)` (signature + the one home of the emitted position), `_aaaa_rule()` (position test, not membership), `ipv6_decision()` (caller list) | E9 |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | one glossary term, **emitted position**, placed with the other composition terms, with its `_Avoid_` line | E10 |

Not touched, as required: this task's own stage documents aside, `docs/tasks.md`, `.harness/**` and
`docs/batches/**`. `docs/batches/followups/BATCH_{LOG,PLAN}.md` show as modified in `git status`;
those edits pre-date this stage (file mtime 20:33, before stage 4 opened) and are not mine.

## verify_all result

```
command: bash .harness/scripts/verify_all.sh          # run from /home/alan/Programs/singbox-cli
baseline (before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after (all edits landed):   PASS 17 / WARN 0 / FAIL 0 / SKIP 1
delta: 0 new failures, 0 new warnings, baseline preserved
result: PASSED
skip: B.3 Lint (SKIP at baseline too — no linter wired on this project)
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | `## Frozen set` row `ipv6_decision()` (`bin/sc:1704-1740`) | Its docstring's caller list was corrected from "`_dns_overlay()`, `cmd_ipv6()` and `sc doctor`'s AAAA row" to "`cmd_ipv6()`, `sc doctor`'s AAAA row and `generate_config()` (which hands it to `_dns_overlay()`)". The function's body, signature and return value are byte-unchanged. | E1 makes the old sentence false of the shipped build — after the signature change `_dns_overlay()` no longer calls `ipv6_decision()` — and E9 corrects that same caller list in `docs/dev-map.md`, so leaving the code sentence would put the map and the code in disagreement. This is BC-D's reading of a frozen row (returned value + signature frozen, not a sentence the edit falsifies) applied to the one other site E1 falsifies; `02_RATIONALE.md:103` already names `generate_config()` as the new reader. Cost: 4 changed docstring lines, no behaviour. |

No other deviation: I-1…I-10 shipped as written, including I-5's second clause in both languages
and I-8's clause spelled identically four times.

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| BC-C | **Discharged.** Fixture note: `telemetry: block` is written into the fixture's **own** `settings.json` (it is also the absent-key default, so this composition is the ordinary host, not an exotic one). The composed `dns.rules` is `[0]` = `{"action":"predefined","query_type":[64,65],"rcode":"NOERROR"}` — i.e. `_aaaa_rule(suppress)`, asserted equal, not assumed — `[1]` = `{"ip_accept_any":true,"server":"hosts_dns"}`, `[2]` = the `sc`-authored telemetry reject rule (`predefined` / `NXDOMAIN` / `domain_suffix`), so a **second `sc`-authored `dns.rules` writer is present** and the AAAA rule still holds index 0. The row renders `[OK] IPv6 (AAAA): … config.json carries this decision`. V-1's byte-identity check was run for this composition too: `sha256 = a87ee4f9…dbca7d5`, identical to HEAD's for the same fixture. A `telemetry: allow` contrast composition (`sha256 = 8e4f569f…f29c90d21`, telemetry rule absent) was also run candidate-vs-HEAD and is byte-identical. | `04_RATIONALE.md` §V-1 / §BC-C transcripts |
| BC-D | **Discharged.** `bin/sc:1743-1752` — the clause claiming `sc doctor` asks a *membership test* and *indexes no position* is replaced by one stating it is a **POSITION test against `_dns_overlay()`'s own payload**; the body at the `return` (`:1753-1754`) is byte-unchanged, as is the returned dict and the signature. Per PQ-1 the same edit removed `_doctor_ipv6()`'s prohibition sentence ("`_dns_overlay()` is deliberately NOT called from anywhere in this block …"), whose only reason was HEAD's overlay calling `ipv6_decision()` itself. `grep -n "membership" bin/sc` now returns nothing. | `git diff bin/sc` hunks at `:1747` and `:2698` |
| BC-E | **Discharged.** The gate command, quoted exactly: `bash .harness/scripts/verify_all.sh`, executed from `/home/alan/Programs/singbox-cli`. No extensionless path was used and no other working directory. Baseline before any edit and result after all edits are both **PASS 17 / WARN 0 / FAIL 0 / SKIP 1**. | `## verify_all result` above |
| BC-F | **Discharged.** I-5's second clause ships in both halves and is neither shortened nor merged. Rendered `en`: `… config.json does not carry this decision as the first dns.rules entry — run \`sc reload\` to regenerate it, and check <OVERRIDE_PATH>/override.json if it prepends a rule of its own`. Rendered `zh`: `… config.json 的 dns.rules 第一条不是该决策对应的规则 —— 运行 \`sc reload\` 重新生成；若 <OVERRIDE_PATH>/override.json 自己往前插了规则，请检查它`. Placeholder set `{decision, override}` on both halves; `override=str(OVERRIDE_PATH)` at the site, the `bin/sc:2634` convention. | `04_RATIONALE.md` §V-2 transcripts (both languages) |
| BC-G (reviewer's, measured here) | `git diff --numstat bin/sc` → **`55  45`**, inside the `+55/−45` bar — **at the ceiling on both halves, zero margin**, and stated as such rather than as comfortable clearance. The removed half moved 44 → 45 because CR-1's correction lands on a **pre-existing** line (`:2222`); the added half did **not** move, because the same edit gave one line back — the named-port paragraph is now two lines, not three. Net docstring length is one line **shorter** than round 1. Top-level `def`/`class` count 113 → 113 (AC-16). The design's `≈ +50/−40` projection was exceeded by the first draft (`+79/−45`) and brought back under the bar by shortening added docstring prose only — no contract text, no interface string and no removal was dropped to get there. | `## Summary` |
| BC-H (reviewer's, self-checked here) | The shared cache clause is byte-identical across I-8's two English keys and across their two `zh` values (compared programmatically, not by eye), and all five re-worded keys carry identical placeholder sets on both halves. | `04_RATIONALE.md` §parity |
| BC-J (developer half) | `docs/dev-map.md:136`'s recipe defect (R-77) was **not** fixed here; every fixture in this stage adds `encoding="utf-8"` at use time instead. E9's edits are the four declared "Reusable utilities" rows and nothing else in that file. | `git diff docs/dev-map.md` (4 changed lines) |

## Open issues for review

- **`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`** (R-37, seventeenth
  confirmation), so this contract has no gated section that can hold a verification transcript. The
  smoke record — V-1, V-2/V-3, V-4, V-5/V-6/V-7, V-9/V-10, V-11, V-12, the `zh` renderings and the
  parity check — is therefore in `04_RATIONALE.md`, referenced from `## Condition disposition` above.
  T-27 owns the fix.
- **AC-8's mechanical grep matches four lines by construction, none of them a call site.** `git diff
  bin/sc | grep -E "is_running|systemctl|rc-service|SYSTEMD|OPENRC"` returns the two halves of the one
  changed guard (`- if not is_running():` / `+ if port is None and not is_running():`, I-4 verbatim)
  **and** the two halves of the one corrected docstring line at `:2222`, which names `is_running()`
  in prose exactly as HEAD's line did — the token count in the diff rose, the number of `is_running()`
  **call sites** did not. There is no second liveness judgement and no new liveness source anywhere in
  the diff; the named-port paragraph deliberately says "the guard" rather than naming the function a
  second time, so the grep stays readable.
- **NFR-2 ("the added cost is zero requests") deserves the reviewer's eye on one branch.** On an
  init-less host the candidate now issues the `GET /proxies` that HEAD short-circuited away — that is
  the defect being fixed, not a new probe: no new endpoint, no new constant, still ≤ 1 `GET` per
  `stored_delays()` call, and only on the branch where `/configs` has already answered. Every other
  host issues exactly what it issued before, and `sc ls` issues nothing new on any host.
- **A fixture near-miss, recorded rather than hidden.** One intermediate fixture ran `sc ls` through
  `main()`, which takes the initialising arm and therefore reached `_init_files()` — the function the
  dev-map says never to drive. Nothing was written: `/var/lib/sing-box` already exists and both
  `mkdir` calls pass `exist_ok=True` (`bin/sc:541-543`), so its mtime is unchanged (Jul 30) and it
  gained no entry; `NODES_PATH` / `SETTINGS_PATH` were redirected into the temp root. The case was
  rebuilt to call `cmd_ls()` **directly**, which removes that one case's reach — but it does **not**
  remove the reach from the fixture set: `main()`'s read-only arm is `if args.cmd in ("doctor",
  "config")` (`bin/sc:3755-3760`), so the final fixture's `ipv6` case takes the **initialising** arm
  exactly as `ls` did, and `_init_files()` — including the un-repointable
  `Path("/var/lib/sing-box").mkdir(parents=True, exist_ok=True)` at `:543` — is still driven. The
  host effect is the same nil quantity for the same reasons: both `mkdir` calls pass
  `exist_ok=True` on directories that already exist, `/var/lib/sing-box`'s mtime is unchanged (Jul
  30) and it gained no entry, and all eight path constants are repointed into the temp root and
  asserted to resolve inside it. No live-service action, no write under `/etc/sing-box`, no install over
  `/usr/local/bin/sc`, and no request of any kind to the live Clash API at any point.
- **The `1` → `2` transition is a consequence of this task, not a regression, and nothing else states
  it.** On an init-less host `_doctor_service()` returns two `[UNKNOWN]` rows unconditionally
  (`bin/sc:2740-2742`); with `DOCTOR_EXIT = {OK:0, UNKNOWN:2, PROBLEM:1}` over the ordering
  `OK < UNKNOWN < PROBLEM` and `worst = max(...)` (`:2476,2480`), such a host cannot exit `0` on this
  build **or on HEAD** — the node-delay `[异常]` was merely masking a pre-existing `[未知]`. No row
  became UNKNOWN, so I-9 and BC-9 still stand and `README*.md:279/280` still need nothing (`:280`
  already lists "no init system detected" as an exit-`2` cause). `02_SOLUTION_DESIGN.md`'s
  backwards-compatibility clause (c) states the superseded `1` → `0`; it is upstream and not mine to
  edit.
- **The clause's lead, 「退出码的影响只有一个方向」, is left exactly as written.** It reads as "the
  exit code is affected only downstream of the row classes — no exit mapping changed", which is true
  of this build; read as "only one numeric direction" it was already loose before this task (`1` →
  `0` and `0` → `1` are two). Repairing the false transition was in scope; re-phrasing a
  pre-existing looseness in a published entry was not.
- `sc doctor`'s egress row performs its ordinary read-only public-IP query during a fixture run;
  that is HEAD behaviour, unchanged by this task, and it touches no path.
- RS-3 stands unchanged: `stored_delays()` still cannot distinguish "no `/proxies` answer" from "an
  answer with no history"; I-6's sentence is true across both, and the distinction stays unavailable
  while the return shape is frozen.

## Dev-map updates

- `stored_delays(port=None)` row now states the two-clause guard: `port is None and not is_running()`,
  `port=None` meaning "the port `main()` resolved" **and** "judge liveness yourself", a named port
  meaning the caller has already judged liveness — with `sc ls` named as unchanged on every host.
- `_dns_overlay()` row renamed to `_dns_overlay(suppress)` and re-titled "The IPv6 half of the emitted
  document, and the **emitted position**": one home, two readers (`generate_config()`,
  `_doctor_ipv6()`), and the renamed-directive failure mode (`[UNKNOWN]`, never a silent `[PROBLEM]`).
- `_aaaa_rule(suppress)` row: the question `sc doctor` asks is now **position, not membership**.
- `ipv6_decision()` row: the caller list reads `generate_config()` where it read `_dns_overlay()`.

## Insight to surface

- A `bin/sc` fixture cannot call `main()` twice in one process: `main()`'s `io.TextIOWrapper` re-wrap of `sys.stdout` (`bin/sc:3717`) leaves the previous run's wrapper over the same `BufferedWriter`, and when the second call replaces it the collected wrapper closes that buffer — so every later `print()` raises `ValueError: I/O operation on closed file`, and with stderr discarded the fixture prints *nothing* and looks like a probe that produced no rows rather than a harness that broke; one case per process is the only reliable shape · evidence: bin/sc:3717 + `04_RATIONALE.md` §fixture
- Removing a `sc doctor` `[PROBLEM]` row can **raise** the exit code rather than lower it: `DOCTOR_EXIT` maps `UNKNOWN → 2` while the internal severity ordering is `OK < UNKNOWN < PROBLEM` with `worst = max(...)`, so on any host whose `_doctor_service()` rows are `[UNKNOWN]` (no systemd and no OpenRC — two rows, unconditionally) a `[PROBLEM]` was masking them and its removal moves the run `1` → `2`, never `1` → `0`; the exit code is a class *label*, not a severity scale, so no fix's exit-status effect may be reasoned about from the row it fixes alone · evidence: bin/sc:2476,2480,2740-2742
- `telemetry: block` is the absent-key **default**, so the second `sc`-authored `dns.rules` writer F-3 warned about is present on an ordinary host, and `_telemetry_overlay()`'s `$before {"clash_mode":"Global"}` anchor puts its rule at index **2** (behind the `hosts_dns` rule), leaving the AAAA rule's index 0 intact — measured on the composed document, not inferred · evidence: bin/sc:1850,1880-1884 + `04_RATIONALE.md` §BC-C

## Verdict

READY FOR REVIEW
