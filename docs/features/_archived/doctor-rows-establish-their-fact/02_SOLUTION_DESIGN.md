# 02 — Solution Design · T-26 `doctor-rows-establish-their-fact`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. Three independent edits inside `bin/sc`, sharing no new construct: one **expression** (the AAAA
   row tests the position the emitter defines), one **condition** (`stored_delays()`'s liveness
   guard stops overriding a liveness judgement the caller already holds), and **five sentences**
   (three DNS-row branches, one node-delay branch, one `sc ipv6` no-op line reusing an existing key).
2. Unchanged: `_aaaa_rule()`'s content, `ipv6_decision()`, `is_running()`, `clash_api()`, the emitted
   `config.json` (byte-identical), `stored_delays()`'s return shape, `sc ls`, `cmd_status`,
   `DOCTOR_SECTIONS`, the row grammar, the three outcome classes and the exit mapping.
3. The seams are the ones that already exist: `_dns_overlay()` becomes the **one home of the emitted
   position** by taking the decision as an argument (so the doctor may read it without a second
   `ipv6_decision()` call), and `stored_delays()`'s existing `port` argument — which by construction
   only `sc doctor` passes — becomes the point at which the caller's stronger liveness judgement wins.

## BC-10 probe and ruling

Stage 2 holds **no execution tool** on this run (`Read` / `Grep` / `Glob` / `Write` / `Edit` only), so
the probe is the strongest read-only first-hand form available: `Grep` over the **installed artifact
this host's service actually runs**, `/usr/local/bin/sing-box` — the same technique, on the same file,
as T-20's BC-16 probe P-1, including its calibration and negative controls. No service was touched, no
path under `/etc/sing-box` or `/var/lib/sing-box` was read or written, and **no request of any kind was
issued to the live Clash API**.

| literal searched | count | reading |
|---|---|---|
| `clashapi.queryDNS` | 1 | control, reproduces T-20 P-1: the `/dns/query` handler is linked into this binary |
| `clashapi.dnsRouter` | 1 | same; the DNS route group is mounted |
| `/dns/query` | **0** | T-20's negative control, reproduced: the route is *mounted*, never a single literal — this 0 must not be read as "absent" |
| `/proxies`, `/configs`, `/delay` | ≥1 each | calibration: route literals do survive in this binary, so a 0 elsewhere carries information |
| `clashapi.cacheRouter` | 1 | a cache route group exists … |
| `clashapi.flushFakeip`, `/fakeip/flush` | 1, 1 | … and its handler is a **flush**: a mutating write, of the fake-IP pool (which this project never enables), not of the DNS answer cache |
| `disable_cache` | 4 | present — but alongside `independent_cache` / `cache_capacity` / `disable_expire`, i.e. the **configuration** vocabulary (DNS server / rule options), reachable only by writing the document and reloading the service |
| `no_cache`, `bypass_cache`, `skip_cache`, `cache_bypass`, `fresh=`, `refresh=` | 0 | no read-only cache-bypass request vocabulary |
| `no-cache` | 5 | the HTTP `Cache-Control` header value (chi's `NoCache` middleware) — it governs HTTP caching of the API response, not the resolver's cache |

**Ruling: no bounded, cache-free lookup exists through the Clash route that is read-only and costs no
new constant.** The only cache-free mechanism the artifact carries (`disable_cache`) is a
configuration option, so reaching it means writing `/etc/sing-box/config.json` and reloading the
service — barred by FR-12(b), out-of-scope 6 and 10. The only cache-affecting route is a **mutating**
flush of a pool this project does not use — barred by the read-only invariant and out-of-scope 6.

A second, independent leg makes the ruling robust against the resolution limit of a literal search:
**even if a cache-control parameter existed, the row could not state the stronger fact.** The
DNS-JSON body this endpoint returns (measured first-hand in T-20: `Status` / `TC` / `RD` / `RA` /
`AD` / `CD` / `Question` / `Answer` / `Server`) carries no cache-hit indicator, so a row asserting
"resolved upstream on this query" would be inferring that the parameter was honoured — swapping one
proxy for another, which is the very defect FR-1 forbids. Distinguishing a hit would need a second
request comparing TTLs, forbidden by NFR-2 and AC-11.

**Therefore FR-9's replacement clause does not fire: FR-8 ships the narrowed claim, the DNS probe is
unchanged, and no code chases a fresh measurement.**

## BC-11 ruling on R-24

**R-24 rides along.** The sentence `cmd_telemetry` ships at `bin/sc:3271-3272` — *"Nothing changed —
the sing-box service was not touched; run `sc reload` to apply this setting to a configuration
generated before it"* — is **true for the IPv6 case word for word**: `cmd_ipv6` reaches that line only
after `save_settings()` has persisted `settings["ipv6"]`, and the state it names (a `config.json`
generated before this setting existed, or before the decision it now records) is exactly the state
`sc reload` repairs. No new key, no new `zh` entry, no new branch, no second fact, no placeholder. The
change is a **key swap at one print site** (`bin/sc:3209`), and it lets the now-orphaned key at
`bin/sc:192` be deleted. Cost cap held.

## Change ledger

| id | path | new/edit | what changes | partition |
|---|---|---|---|---|
| E1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | **AAAA row.** `_dns_overlay()` takes `suppress`; `generate_config()`'s compose list passes `ipv6_decision()[1]`; `_doctor_ipv6()` tests the head of `dns.rules` against that same overlay's `$prepend` payload; its PROBLEM sentence names both BC-3 causes. Docstring contracts at all three sites updated. | single-dev |
| E2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | **Node-delay row.** `stored_delays()`'s guard becomes `if port is None and not is_running():`; docstring states the new interface term. `_doctor_clash()` gains no call and no check; its PROBLEM sentence states what was **read**. | single-dev |
| E3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | **DNS row.** Three branch sentences replaced (one shared cache clause across the two PROBLEM branches); the probe, the endpoint, the name, the type, the timing and the classes are untouched. `_doctor_clash()`'s docstring gains the cache sentence. | single-dev |
| E4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | **R-24.** `cmd_ipv6`'s no-op `print()` swaps to the existing `cmd_telemetry` key; the orphaned key at `:192` is deleted. | single-dev |
| E5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `TRANSLATIONS["zh"]`: five entries re-worded in place (`:310-311`, `:335-336`, `:337-338`, `:339-340`, `:341-342`), one entry deleted (`:192`). No entry added. | single-dev |
| E6 | `/home/alan/Programs/singbox-cli/README.md` | edit | Lines 263 (section-table row 4), 266 (row 7), 272 (changes-nothing paragraph), 279 (exit `1` causes) — see I-9. | single-dev |
| E7 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | The same four lines, same numbers (the file is a line-for-line mirror). | single-dev |
| E8 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One entry under `## [Unreleased]` → `### 修复`, in Chinese, naming the three rows, the `sc ipv6` line and the exit-status consequence. | single-dev |
| E9 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | Four "Reusable utilities" rows: `stored_delays()` (guard wording), `_dns_overlay()` (signature + the one home of the position), `_aaaa_rule()` (position test, not membership), `ipv6_decision()` (caller list: `generate_config()` replaces `_dns_overlay()`). | single-dev |
| E10 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | One glossary term, **emitted position**, per the standing glossary rule (see I-10). | single-dev |
| E11 | — | — | **Schema gap, not a file:** `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37, sixteenth confirmation), so the exact user-facing strings are carried as `## Interfaces` rows rather than in a gated byte-form section. T-27 owns the fix; this task changes nothing under `.harness/**`. | — |

Not in the diff, by AC-17: this task's own stage documents, `docs/tasks.md`, `.harness/**`,
`docs/batches/**`.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `_dns_overlay(suppress)` (`bin/sc:1757`) | `def _dns_overlay(suppress):` → `{"dns": {"rules": {"$prepend": [_aaaa_rule(suppress)]}}}` | THE one home of both the authored rule's **content** (via `_aaaa_rule`) and its **emitted position** (the `$prepend` payload). Pure: no I/O, no print, never calls `ipv6_decision()`, never raises. Two readers, one definition. |
| I-2 | `generate_config()` compose list (`bin/sc:2092-2093`) | `_compose([_runtime_overlay(nodes, active, report), _dns_overlay(ipv6_decision()[1]), _telemetry_overlay()])` | Emitted bytes are **byte-identical** to HEAD; overlay order unchanged; `ipv6_decision()` is still called exactly once per generate, so BC-9's stderr line still appears at most once. |
| I-3 | `_doctor_ipv6()` position test (`bin/sc:2717`) | `prepend = _dns_overlay(suppress)["dns"]["rules"]["$prepend"]` then `if isinstance(rules, list) and rules[:len(prepend)] == prepend:` | `[OK]` iff the document's `dns.rules` **begins** with exactly what this build prepends. Raises on no input BC-1 admits (the slice is guarded by `isinstance`); a directive rename in I-1 raises `KeyError` → the section's own `[UNKNOWN]` row, never a silent PROBLEM on every healthy host. |
| I-4 | `stored_delays(port=None)` guard (`bin/sc:2231`) | `if port is None and not is_running():` | `port is None` means "the port `main()` resolved" **and** "judge liveness yourself"; a caller naming a port has already established that the API answers on it and its judgement is not overridden by a weaker one. `sc ls` (`bin/sc:2308`) passes no port and is observably unchanged on every host. Return shape, request count (≤1 `GET`), method set and `isinstance` house style unchanged. |
| I-5 | AAAA PROBLEM sentence (key at `bin/sc:310`, site `:2720`) | en: `{decision}; config.json does not carry this decision as the first dns.rules entry — run `sc reload` to regenerate it, and check {override} if it prepends a rule of its own`<br>zh: `{decision}；config.json 的 dns.rules 第一条不是该决策对应的规则 —— 运行 `sc reload` 重新生成；若 {override} 自己往前插了规则，请检查它` | Two placeholders on both halves; `override=str(OVERRIDE_PATH)` at the site, the convention `bin/sc:2634` already uses. Names both BC-3 causes on one line (T-20 BC-13 shape). The `[OK]` key (`:309`) is **unchanged** (AC-4). |
| I-6 | node-delay PROBLEM sentence (key `:335`, site `:2854`) | en: `a stored delay was read for 0/{total} nodes — either no probe has completed yet, every node is failing, or the list could not be read; see `sc ls``<br>zh: `只读到 0/{total} 个节点的已记录延迟 —— 可能探测尚未完成、可能所有节点都不通，也可能这份列表没读出来；请查看 `sc ls`` | States the **read**, not the world, so it stays true in the one state that survives E2 (a `/proxies` request issued whose body is absent or unusable). Renders `0/2`, keeps the class PROBLEM and keeps `sc ls` (AC-6). The `{n}/{total}` OK key (`:333`) is unchanged. |
| I-7 | DNS OK sentence (key `:337`, site `:2869`) | en: `the running sing-box answered for {name} in {ms} ms, possibly from its own DNS cache`<br>zh: `正在运行的 sing-box 在 {ms} 毫秒内给出了 {name} 的应答，可能来自它自己的 DNS 缓存` | States the probe's fact (the install answered, and how long that took) and names the install's own cache as an admissible source; asserts nothing about where the name was resolved on this query. |
| I-8 | DNS PROBLEM sentences (keys `:339` and `:341`, sites `:2873` and `:2865`) | en: `{name} returned no records after {ms} ms — try another node with `sc use <n>`; an answer already cached by the running sing-box survives a node change` / `no answer for {name} after {ms} ms — ` + the **same** trailing clause<br>zh: `{name} 在 {ms} 毫秒后返回了空结果 —— 可用 `sc use <编号>` 换一个节点试试；正在运行的 sing-box 已缓存的应答不会因为换节点而失效` / `{ms} 毫秒内没有收到 {name} 的解析结果 —— ` + the **same** trailing clause | One clause, spelled identically in both branches and in both languages. It is a standing property of the install, so it is true on the branch where nothing answered; it withdraws the assertion that the next step is effective against a cached answer without claiming this particular answer was cached. Classes unchanged. |
| I-9 | Published sentences | `README.md` / `README.zh-CN.md` `:263` — "…carries that decision **as the first `dns.rules` entry**"; `:266` — the lookup is "**answered** by the running sing-box … which may answer from its own DNS cache"; `:272` — the existing cache sentence gains "…and may equally **answer** a later query from that cache"; `:279` — the exit-`1` cause reads "an AAAA decision the document does not carry **first**" | Every published sentence is true of the shipped build (FR-13, AC-15). The exit-`2` row (`:280`) needs **no** change: this design takes FR-6's *establish* branch, so no row becomes UNKNOWN where it was PROBLEM and **BC-9 does not fire**. |
| I-10 | `CONTEXT.md` glossary term | **emitted position**: the index at which an `sc`-authored overlay places its own rule in an array the base template defines — for the AAAA rule, the head of `dns.rules`. It has one home (the overlay expression) and two readers (the generator and `sc doctor`). _Avoid_: index, offset, slot, ordering | A term the design sharpens, so it is recorded rather than left to prose. |

## Constraints

**K-1** — The implementer introduces **no new top-level `def` or `class`** in `bin/sc`, and no module,
decorator, registry or shared validator serving more than one of the three rows (FR-3, AC-16).

**K-2** — The implementer adds **zero** `TRANSLATIONS` keys and deletes exactly one (`bin/sc:192`);
every re-worded key keeps the same placeholder set on both halves and stays in its existing thematic
group (NFR-4, AC-12).

**K-3** — The implementer writes no `is_running`, `systemctl`, `rc-service`, `SYSTEMD` or `OPENRC`
anywhere in the diff, and adds no second liveness source (AC-8).

**K-4** — The implementer does not delete or move `stored_delays()`'s guard out of the function; only
its condition is narrowed (FR-7, BC-7, AC-7).

**K-5** — The implementer changes nothing about what `/dns/query` is asked: one `GET`, one name
(`EGRESS_HOST`), `type=A`, one query per run, no new constant, no retry, no second endpoint (FR-9).

**K-6** — The implementer keeps `sc doctor` process-wide read-only: no path written, created, removed
or renamed; the `doctor` arm still reaches neither `_init_files()` nor `_resolve_clash_port()`
(FR-12(b), AC-11).

**K-7** — The implementer keeps the emitted `config.json` byte-identical for both decisions: `E1`
changes how the overlay receives the decision, never what it emits (out-of-scope 4).

**K-8** — The implementer adds no `try`/`except` around `clash_api()`, `_dns_overlay()` or
`stored_delays()`; `clash_api()` is total and a second envelope is the defect, not the fix.

**K-9** — The implementer writes no `失败：` literal into any changed or added `zh` string, and
verifies both languages render every changed row (BC-13).

**K-10** — The implementer never imports `bin/sc` without the mandated neutralisation recipe
(`docs/dev-map.md` "Patterns to avoid", with R-77's `encoding="utf-8"`), never runs against the live
service, and never installs over `/usr/local/bin/sc` (R-78; out-of-scope 10).

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `_aaaa_rule()` body (`:1743-1754`) | Out-of-scope 4: the rule's content is not this task's. Only its *position*'s home moves. |
| `bin/sc` `ipv6_decision()` (`:1704-1740`) | Out-of-scope 4; T-16's AC-6 and FR-11 depend on both sides of `cmd_ipv6`'s comparison coming from it and never from disk. |
| `bin/sc` `is_running()` (`:2202-2208`) | AC-8: no new liveness source and no change to the existing one. |
| `bin/sc` `clash_api()` (`:2179-2199`) | T-18's totality contract; K-8. |
| `bin/sc` `CONFIG_BASE`, `_compose`, `_merge`, `_apply_directive`, `DIRECTIVES` | K-7: the emitted document must not move a byte, and the merge has exactly one implementation. |
| `bin/sc` `DOCTOR_SECTIONS`, `DOCTOR_MARK`, `DOCTOR_EXIT`, `_doctor_print()`, `cmd_doctor()` | FR-12(c)(d): order, grammar, classes, markers, per-row flush and exit mapping unchanged. |
| `bin/sc` `cmd_ls()` (`:2308`), `cmd_status()` | FR-7, out-of-scope 7. |
| `bin/sc` `stored_delays()` return shape and body below the guard | Out-of-scope 7. |
| `install.sh`, `uninstall.sh`, `systemd/**` | Not this task's surface. |
| `/etc/sing-box/**`, `/var/lib/sing-box/**`, `/usr/local/bin/sc`, the live service | Out-of-scope 10; the read-only invariant. |
| `.harness/**`, `docs/tasks.md`, `docs/batches/**` | AC-17 / R-36 carve-out. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E1 | `_dns_overlay` has exactly one caller (`bin/sc:2092`) — re-grep before editing; the signature change and the call-site change land in the **same** edit or `sc reload` breaks. | `git checkout -- bin/sc`; no persisted state involved. |
| 2 | E2 | E1 landed and `sc reload` still emits a byte-identical document (V-1). | Restore the one-line guard condition. |
| 3 | E3, E4, E5 | Sentence-only; independent of E1/E2 and of each other. | Restore the keys and the two call sites. |
| 4 | E6, E7 | E1-E5 landed; every published sentence is read against a **captured candidate run**, not against the design (AC-15). | Revert the four lines per file. |
| 5 | E8, E9, E10 | Code and READMEs final, so the changelog and the map describe what shipped. | Revert per file. |
| 6 | — | `.harness/scripts/verify_all` PASS **from the repository root** (R-73: run elsewhere it self-reports a false red). | The whole task is one commit; `git revert` restores HEAD behaviour. No data migration, no flag, no settings key, no on-disk format change, and no user action required on upgrade. |

**Backwards compatibility, stated rather than assumed.** (a) `config.json` is untouched by this task
and regenerates byte-identically, so no host needs `sc reload` to keep working. (b) A host whose
`dns.rules` carries the authored rule at a non-zero index — today only reachable through a user
`override.json` that `$prepend`s, since every `sc`-generated document puts it first — moves from
`[OK]` to `[PROBLEM]` and from exit `0` to exit `1`. That is the intended correction (FR-4, BC-4), it
is published in both READMEs (I-9), and the row names both repair routes. (c) An init-less host with
an answering Clash API moves from `[PROBLEM] 0/N` to `[OK] n/N` (or an honest `0/N` read), and its
exit moves `1` → **`2`**, not `1` → `0` — measured on an otherwise wholly healthy init-less fixture
(HEAD `EXIT = 1`, candidate `EXIT = 2`). The move is **unmasking, not reclassification**: with
neither systemd nor OpenRC, `_doctor_service()` already returns two `[UNKNOWN]` rows unconditionally
(`bin/sc:2739-2742`), and since `worst = max(...)` over `OK < UNKNOWN < PROBLEM` (`bin/sc:2476,3027`)
maps through `DOCTOR_EXIT = {OK: 0, UNKNOWN: 2, PROBLEM: 1}` (`bin/sc:2480`), the node-delay
`[PROBLEM]` was **masking** those pre-existing UNKNOWNs in the exit status; removing it lets them
surface. Such a host therefore cannot exit `0`, before this task or after. **No host gains an UNKNOWN
it did not have** — that sub-clause holds — so BC-9's row-class case does not arise, and I-9 and the
exit-`2` table row (`README*.md:279-280`, which already lists "no init system detected" as an
exit-`2` cause) are unchanged.

## Out of scope

1. Everything `01_REQUIREMENT_ANALYSIS.md` `## Out of scope` lists — carried forward verbatim, not restated.
2. Any cache bypass, flush, warm-up, TTL inspection, cache-hit detector or second DNS request, in code or in a fixture (BC-10 ruled; FR-9 binds).
3. Distinguishing "no `/proxies` answer" from "an answer with no history" in `stored_delays()`'s **return value** — that needs the return-shape change out-of-scope 7 forbids; I-6 makes the sentence true across both instead.
4. Any judgement about whether a user's own prepended rule preempts the decision (needs sing-box semantics this project must not re-implement, BC-4).
5. Any repair action, new row, new flag, machine-readable output or widening of the report.
6. R-51, R-21, R-35, R-56…R-59, R-70…R-79, and the harness rows T-27 owns.

## Verification plan

Every step runs against a fixture loaded by the mandated recipe (`docs/dev-map.md`, with
`encoding="utf-8"`), all eight path constants asserted inside a `mkdtemp()` root, `sc.SYSTEMD =
sc.OPENRC = False` unless the step says otherwise, and the Clash port recorded in the **fixture's own**
`settings.json`. Never the live host, never the installed `sc`.

| step id | what is run / measured | expected observable | AC |
|---|---|---|---|
| V-1 | `generate_config()` on one fixture, for `ipv6: on` and `ipv6: off`, candidate vs. HEAD | The two `config.json` byte streams are **identical** to HEAD's, and `dns.rules[0]` is `_aaaa_rule(suppress)` in both. | K-7, AC-4 |
| V-2 | `sc doctor` on a fixture whose `dns.rules` carries the authored rule at index 3 behind three decoy rules | `[PROBLEM] IPv6 (AAAA)` whose value text names both BC-3 causes and both repair routes. | AC-1, AC-2 |
| V-3 | `sc doctor` on a fixture whose `dns.rules` lacks the rule entirely, and on one with `dns` a string / `rules` absent / the document not an object / the file unreadable | V-2's sentence on the first; on the rest, exactly HEAD's classes and sentences, and no exception anywhere. | AC-2, BC-1, BC-2 |
| V-4 | Read `_dns_overlay()` and `_doctor_ipv6()`; then attempt the divergence — rename the directive in I-1 only, and re-run | Before: one expression defines the position and the probe reads it. After the tampering: `[UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'`, **never** a silent `[PROBLEM]` on a healthy document. Revert the tampering. | AC-3 |
| V-5 | `sc doctor` with `SYSTEMD = OPENRC = False`, a stub API answering `/configs` and `/proxies` with a delay for each of two configured tags | `[OK] node delays: 2/2 …`; the stub log contains `/proxies`. HEAD on the same fixture prints `[PROBLEM] … 0/2 …` and logs no `/proxies`. | AC-5 |
| V-6 | Same fixture with `sc.SYSTEMD = True` **and** `subprocess.run` stubbed (both, or candidate and control agree vacuously), `/proxies` answering with entries carrying no `history` | `[PROBLEM] node delays: … 0/2 … see \`sc ls\`` — class and numerals unchanged from HEAD. | AC-6 |
| V-7 | `sc.SYSTEMD = True`, `subprocess.run` stubbed to report **stopped**, stub API **not answering** (the only coherent BC-7 fixture: an init system reporting stopped and an API that answers describes a live process, where reading `/proxies` is correct); run `sc doctor` **and** `sc ls` | Stub request log contains no `/proxies` from either command; the node-delay row is `[UNKNOWN]`; `sc ls`'s delay column is all `-` and its table is byte-identical to HEAD's. Deleting the guard fails this step through `sc ls`. | AC-7, FR-7, BC-7 |
| V-8 | `git diff` grepped for `is_running`, `systemctl`, `rc-service`, `SYSTEMD`, `OPENRC`; top-level `def`/`class` counted before and after | Zero matches; identical counts. | AC-8, AC-16 |
| V-9 | `sc doctor` on three DNS fixtures: `/dns/query` answered with a non-empty `Answer` (body copied from T-20's P-2a), answered with an object carrying none (body copied from T-20's P-3), and not answered at all | Row 1 `[OK]` naming the install's own cache and asserting nothing about where the name was resolved; rows 2 and 3 `[PROBLEM]`, classes unchanged from HEAD, both carrying the identical trailing clause. | AC-9, AC-10, BC-12 |
| V-10 | Across those three runs: the stub request log, plus a before/after snapshot of the whole fixture root (existence, size, mtime, sha256, mode), plus a positive control that writes one byte and proves the snapshot detects it | Exactly one `GET /dns/query` per run, no other DNS request, no mutating request; snapshots identical; the control fails loudly. | AC-11, FR-12(b), NFR-2 |
| V-11 | `sc ipv6 auto` on a fixture already deciding `auto` (reload stubbed), in `en` and in `zh`; then read `cmd_ipv6`'s two comparison sources and the diff's `TRANSLATIONS` delta | The no-op line names `sc reload` in both languages; zero keys added, one deleted, zero branches added; neither side of the comparison is read from `config.json`. | AC-12, AC-13 |
| V-12 | A wholly healthy fixture, candidate vs. HEAD, row by row | Same row count, same labels, same order, same exit status; no `[PROBLEM]`, no `[UNKNOWN]`. | AC-14, NFR-1 |
| V-13 | Enumerate each published sentence (`README*.md:263,266,272,279,280`, `docs/dev-map.md`'s four rows) against a captured candidate run, one by one | Each sentence true of the run; the exit-`2` row needs no change because no row became UNKNOWN. | AC-15, FR-13 |
| V-14 | `sc lang zh` over V-2, V-5, V-6, V-9, V-11; grep every changed zh string for `失败：` | Every changed sentence renders in Chinese; zero matches. | BC-13, K-9 |
| V-15 | `git status` + `git diff --numstat` at delivery; `.harness/scripts/verify_all` from the repository root | Only the files E1-E10 name; `verify_all` PASS. | AC-17 |

## Smaller alternative rejected

Rule 85 puts the burden of proof on the larger design. Per row, the smaller design and what the extra
code buys — stated so stage 3 can **test** the answer rather than accept it.

**Row 1 (AAAA).** Smaller: leave `_dns_overlay()` alone and write `rules[:1] == [_aaaa_rule(suppress)]`
in the probe — `+1/−1`, no signature change, no call-site edit. It satisfies FR-4 and AC-1/AC-2
exactly. It fails **AC-3**: the position would then be spelled twice — `$prepend` in the emitter,
`[:1]` in the probe — with nothing coupling them. What the extra ~6 lines buy, concretely and not
speculatively: (a) the day the emitter's payload grows a second rule (the growth `_aaaa_rule()` itself
was created to survive — see its docstring, "a positional index … would silently check the wrong rule
the day a second one is prepended"), the probe follows at **zero** edits, where `[:1]` silently
compares one element against two and reports PROBLEM on every healthy host; (b) if the directive is
ever renamed, the probe **raises** and the row reads `[UNKNOWN]`, where `[:1]` would ship a false
`[PROBLEM]` on 100 % of installs — T-20's own rollback shape, and precisely what "changing one without
the other is not possible silently" means. Accepted cost: the `[UNKNOWN]` message is a bare
`'$prepend'` KeyError text. Loud and cryptic beats silent and wrong.

**Row 2 (node delays).** Smaller: delete `stored_delays()`'s guard outright — `+0/−2`, and AC-5 passes.
Rejected by AC-7 and FR-7 rather than by argument: `sc ls` on a stopped host would then pay a request
and, behind a DROP rule, a 3 s wait. The retained-but-narrowed guard costs **one changed line** and
keeps that guarantee for every caller that does not name a port. Also rejected, as **larger**: a
`running=True` parameter (`+3` lines and a new knob a future caller can pass wrongly) and any
re-implementation of the `/proxies` read inside `_doctor_clash()` (a second opinion about the fact
`stored_delays()` owns — the defect this project has spent five tasks removing).

**Row 3 (DNS).** Smaller: change the `[OK]` sentence only, and leave both PROBLEM branches alone —
saves ~8 lines. Rejected by OQ-9/BC-12/AC-10, which are contract: the same call serves all three
branches from the same cache, a negative answer is held far longer than a positive one, and covering
all three costs the same one clause. Also rejected, as **larger** and now as **unsupported**: any
cache-bypass, second name, per-run varying name or second request — BC-10's probe establishes no
mechanism to build on, and FR-9 forbids building one anyway. **This row is the one rule 85 predicted:
the check does not change at all; only what the sentence claims does.**

**R-24.** Smaller: drop it (BC-11's escape). Not taken because the cheaper option is *keeping* it: one
changed print line plus one **deleted** translation entry, net zero, and it removes a dead key.

## Projected size

| unit | added | removed | note |
|---|---|---|---|
| E1 AAAA | ~18 | ~12 | of which ~9 added / ~7 removed are docstring contract text at three sites |
| E2 node delays | ~9 | ~6 | one executable line changed; the rest is docstring + one sentence |
| E3 DNS | ~15 | ~13 | sentences only; no executable change |
| E4 + E5 keys | ~8 | ~9 | five entries re-worded in place, one deleted |
| **`bin/sc` total** | **≈ 50** | **≈ 40** | net ≈ **+10** lines |

Measured against NFR-3: smaller than T-25 (`+80/−41`), T-24 (`+79/−55`) and T-23 (`+76/−51`) on
additions and on total churn (≈ 90 against 121 / 134 / 127). It **exceeds the `+40/−20` bar**, so the
burden of proof is discharged explicitly: **no new function, class or module appears** (K-1, AC-16);
**~15 of the ~50 added lines are executable** — the rest is the contract docstring text this
repository requires beside every construct plus five translated sentences whose re-wording is the
task's whole deliverable; and every removal is a *replaced* line, so nothing is deleted behaviour.
The `−20` half of the bar is unreachable for any task whose product is re-worded sentences: each
re-worded line costs one removal by construction. Total churn, not `+40/−20`, is the honest ruler
here, and by it this is the smallest of the last four deliveries.

## Risks

| id | risk | mitigation |
|---|---|---|
| R-1 | The QA fixture for AC-7 is built with a stub API that **does** answer `/configs` while the init system reports stopped. Under this design doctor then correctly reads `/proxies`, and the step reads as a failure. | V-7 pins the coherent fixture (API not answering) and states why: an answering API on a "stopped" host describes a live process, and reporting its real delays is the fix, not a regression. Travelling as RS-1. |
| R-2 | `sc.SYSTEMD` left `False` while `subprocess.run` is stubbed (or the reverse) makes the whole node-delay matrix agree on candidate and control — the indexed T-20 trap. | V-6 requires **both**; V-5 requires neither and asserts the opposite direction, so the pair is self-checking. |
| R-3 | The fixture's `settings.json` omits `clash_api_port`, so `main()` resolves a port free by construction and every Clash row degrades to "nothing listening" on candidate and control. | Every Clash-section step records the port in the fixture's own `settings.json`; V-5's HEAD half must show `/configs` in the stub log or the fixture is void. |
| R-4 | A hand-written loader re-execs the installed `/usr/local/bin/sc` against the live service (R-78, a near-miss in this pool). | K-10: the mandated recipe from the start, `assert os.geteuid() != 0` first, all eight constants asserted inside the temp root. |
| R-5 | The signature change in E1 lands without its call site, breaking `sc reload` on every command that regenerates. | Migration order 1 makes them one edit; V-1 (byte-identical config for both decisions) is the first step run. |
| R-6 | The AAAA PROBLEM row now fires on hosts whose `override.json` legitimately `$prepend`s to `dns.rules` — a true statement that may read as an accusation. | BC-4 is explicit that the row judges only `sc`'s own emission; I-5 names the override as a *cause to check*, asserts nothing about whether the user's rule preempts the decision, and the READMEs publish the position as the promise (`README.md:126`). |
| R-7 | The re-worded DNS clause reads as "your answer was cached" on the branch where nothing answered. | I-8's clause is a standing property of the install, conditional in both halves ("an answer **already cached** … survives a node change"), so it claims nothing about this answer's provenance and is true in every branch. |
| R-8 | A `zh` re-wording collides with the `失败：` grep that `sc update-rules` consumers rely on (R-75). | K-9 + V-14 grep every changed zh string; none of the five uses a failure noun. |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | AC-7's fixture must have the stub API **not answering**; an answering API with an init system reporting "stopped" describes a live process, and reading `/proxies` there is correct behaviour, not a defect. | `03_GATE_REVIEW.md`, `06_TEST_REPORT.md` |
| RS-2 | BC-10 was discharged without an execution tool: the probe is a read-only literal search over the installed binary, with T-20's calibration and negative controls. Its resolution limit is stated in `02_RATIONALE.md`. If QA later observes a cache-control parameter on `/dns/query`, that does **not** reopen this task — FR-9's replacement clause was stage-2-gated and did not fire, and the narrowed claim is true in both worlds. | `03_GATE_REVIEW.md`, `06_TEST_REPORT.md` |
| RS-3 | `stored_delays()` still cannot tell "no `/proxies` answer" from "an answer with no history"; I-6's sentence is true across both, but the *distinction* remains unavailable while the return shape is frozen. Candidate pool row if a future task wants the row to say which. | `07_DELIVERY.md` (pool) |
| RS-4 | R-37, sixteenth confirmation: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`, so this contract carries its exact user-facing strings as `## Interfaces` rows and no gated byte-form section exists to hold them. T-27 owns the fix. | `07_DELIVERY.md`, T-27 |
| RS-5 | Insight candidate: sing-box's Clash API exposes cache control only as a **mutating** fake-IP flush (`clashapi.cacheRouter` / `flushFakeip`) and as **configuration** options (`disable_cache`, `independent_cache`, `cache_capacity`), never as a read-only request parameter — so no `sc` probe can ever ask this install for an uncached resolution. | `07_DELIVERY.md` `## Insight` |
| RS-6 | `docs/dev-map.md`'s `stored_delays()` row now has a two-clause guard contract; any future caller that names a port inherits "you have already judged liveness". | `05_CODE_REVIEW.md` |
| RS-7 | Two declines belong in `.harness/rejected-decisions.md` — `position-test-by-a-bare-head-slice` and `doctor-cache-free-dns-lookup` (see `## Smaller alternative rejected` and `## BC-10 probe and ruling`). `.harness/**` is outside this task's permitted diff (AC-17), so the PM files them at delivery, as it did for T-18 and T-19. | `07_DELIVERY.md` (PM files) |

## Verdict

READY
