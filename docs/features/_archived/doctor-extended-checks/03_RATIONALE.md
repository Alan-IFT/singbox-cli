> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## 1. Probe P-1, re-run first-hand, with two controls the design did not run

Read-only `Grep` over `/usr/local/bin/sing-box`. No HTTP was issued by me; no service was touched; no credential byte was read.

| pattern | matches | role |
|---|---|---|
| `/providers/rules` | 1 | Reproduces the design's calibration control. |
| `/dns/query` | 0 | Reproduces the negative control: the path is not a single literal. |
| `clashapi.queryDNS` | 1 | Handler present. |
| `clashapi.dnsRouter` | 1 | Router present. |
| `clashapi.configRouter` | 1 | **My control.** Same symbol class; its route `/configs` is proven live on this host by `_doctor_clash()` and `cmd_status()`. |
| `clashapi.proxyRouter` | 1 | **My control.** Same class; `/proxies` is proven live by `stored_delays()`. |
| `clashapi.queryDNSNotReal` | 0 | **My negative control.** A fabricated symbol matches nothing, so presence is not an artefact of the search. |
| `clashapi.scriptRouter` | 1 | **My counter-control**, and the one that limits the ruling. |

The inference holds: `dnsRouter` is a package-level function whose only reference is its `Mount` site, the Go linker drops unreferenced functions, and `configRouter`/`proxyRouter` — retained the same way — serve routes this host answers today. So `GET /dns/query` is **mounted**, and BC-16's three clauses are met (it exists; `clash_api()` bounds each socket operation at 3 s; it asks the running process's own DNS router).

What P-1 does **not** establish, and what the design slightly overstates: `scriptRouter` is present too, and `/script` answers "not supported". A present symbol proves a mounted route, never a *supported* one, and `TCRDRA` proves the response struct is compiled in, not that this route returns it. That is precisely why P-2 exists, why the `Answer` key is provisional, and why GC-6 adds the missing branch to K-20.

## 2. The two forcing reasons, tested at the code rather than accepted

**"Drift must print between `configuration` and `sing-box check`."** True and forcing. `cmd_doctor` (`bin/sc:2631-2645`) iterates `DOCTOR_SECTIONS` and prints each probe's rows as one uninterrupted block; `_doctor_config()` (`:2453-2498`) emits both rows. No new `DOCTOR_SECTIONS` entry can interleave a row between two rows of another section — the table has no mechanism for it. So FR-12's first pair alone rules out "one entry per fact".

**"The node-delay and DNS rows need to know whether the Clash API answered."** True and forcing. `_doctor_clash()` holds that fact as `answer is not None` (`:2580-2586`) and `cmd_doctor` calls `rows = probe()` with **no argument and no return channel** — a separate section could not receive it and would have to re-issue `GET /configs`: a second request, a second 3 s exposure and a second opinion of a fact one function already owns (AC-S2).

I also tested the third possibility the design did not enumerate: folding the AAAA row into `_doctor_config()` to save the ninth `DOCTOR_SECTIONS` entry. It satisfies FR-12, so it is genuinely smaller — and it is still worse, because `cmd_doctor`'s isolation is **per section**: a raise inside the AAAA read would then cost the drift row and the `sing-box check` row as well. The drift row does not carry that risk in the other direction (`_drift_state()` is total, and `_config_digest()` catches `OSError` at `:1854`), which is why the asymmetry is real and not aesthetic. Two new entries and five new rows is the answer the code forces.

## 3. The three flagged decisions

**`_aaaa_rule(suppress)` — load-bearing, but not as I-6 spells it.** Without the extraction the probe calls `ipv6_decision()` for the sentence and `_dns_overlay()` calls it again at `:1635`, so BC-9's stderr line prints twice and `/proc/net/if_inet6` is read twice; a positional `[0]` also silently checks the wrong rule the day a second rule is prepended. Four lines of pure function remove both — the `_drift_state()` precedent exactly. But I-6's own formula re-enters `_dns_overlay()`, so a developer implementing I-6 verbatim ships the double call the extraction was bought to remove, with the extraction as dead weight beside it. That is F-1 and GC-2. Note the design's own V-5 ("at most one IPv6 stderr line per run") is the test that catches it, which is why this is a condition and not a rollback.

**`_age_seconds()` deliberately absent — correct, and it is the smaller design.** The verdict and the render both start from the one `mtime` the single reader produced, so no second opinion is possible; `_age_text()`'s output is a coarse bucketed phrase that could only serve a threshold by being parsed back, which would be worse than either option; and rule 85's counter-rule asks for the future edit a helper prevents — there is no second consumer of "how old, in seconds" today and T-19's K-17 forbids widening `_age_text()`. The only real cost is two `time.time()` reads a few microseconds apart against a 60-day threshold.

**`EGRESS_HOST` — accepted.** `_egress_ip()` holds the literal at `bin/sc:415`; `"https://" + EGRESS_HOST` is byte-identical, the `timeout=8` and the decode are untouched, and `docs/dev-map.md:69`'s "the endpoint literal in one place" stays true because the constant sits immediately above its one composer. One line for one home, and it is what makes the DNS row and the egress row a causal pair rather than two coincidental probes.

## 4. The R-22 trap, checked by construction

Degenerate builds against the two corners:

| degenerate build | corner A (AC-B1…AC-B7, AC-B13) | corner B (AC-B8, AC-B12) |
|---|---|---|
| every new row `[OK]` | fails all seven | passes |
| every new row `[PROBLEM]` | passes | fails AC-B8 (rows not OK, paths named) **and** AC-B12 |
| every dependent row `[UNKNOWN]` | fails AC-B4, AC-B5 | passes AC-B12 |
| age rendered only on stale rows | passes AC-B1 and its control | passes AC-B8 — **the one gap**, closed by GC-9 |

No pair of criteria agrees on a useless build, and every new row has at least one criterion observing it report a *problem* on a deliberately broken fixture: AC-B1 (stale), AC-B2 (drift), AC-B3 (AAAA, both directions), AC-B4 (node delays), AC-B5 (DNS), AC-B6 (file mode), AC-B7 (directory mode). Each also has a control in the opposite direction, and V-9 run 1 doubles as the `settings.json`-exclusion control.

The structural weakness is not in the matrix but in its **discharge**: AC-B8 is the sole adversary for four of the five rows, and it is the one criterion whose satisfaction depends on sections this task does not own. A weakened AC-B8 collapses the table's second column — hence GC-1, which moves the adversarial force onto the three row-level clauses and lets the exit value be reported honestly whatever it is.

One vacuity trap is closed *by the design* and deserves saying: a fixture that forgets the port takes `_saved_clash_port()`'s `None` branch, which BC-10 maps to UNKNOWN — so AC-B4 **fails loudly** rather than passing for the wrong reason. The trap that stays open is the `is_running()` one (F-3): with `SYSTEMD` false, `stored_delays()` returns `({}, None)` and the row reads `0/{total}` — AC-B4's candidate passes for the wrong reason while only its control fails. GC-4 closes both halves, and the stub-log assertion is what makes "the request really went out" observable rather than assumed.

## 5. Invariants re-derived, not diffed

- **No second opinion.** Every new fact traces to its owner's call (§ dimension 3). AC-S1's four deletion tests are the right idea with the wrong mechanism — `cmd_doctor`'s `except Exception` is a graceful catcher, so the deletion is observable as a *specific section degrading and naming the symbol*, not as an import error (F-5, GC-5).
- **One ordering table.** `DOCTOR_SECTIONS` (`:2604`) has exactly one reader, `cmd_doctor`; I-17 inserts two entries and reorders none, and every FR-12 pair is satisfied either by that table or by row order inside one probe.
- **Process-wide read-only.** `main()`'s `if args.cmd in ("doctor", "config")` arm (`:3352`) reaches only `_load_lang()`; the `config` arm is frozen; K-8 enumerates the writers; V-14 adds raisers plus the positive control the insight index demands. The honest residual is that the DNS query makes the *service* work, which is PQ-5 and GC-8.
- **No fresh-measurement claim.** `stored_delays()` reads a stored history (`:2083-2085`), and I-7's text says "history, not a fresh measurement" in both languages. No row states a timeout value; the DNS row prints a **measured** elapsed only, which is the only shape R-35's 30.1 s measurement permits.
- **String hygiene.** The three dying keys are used at exactly the three sites the design names (`:2444`, `:2446`, `:2586`) and nowhere else; the 28 new keys carry matching placeholder sets and none contains `失败`; no new `ls.`-style namespaced key appears, so R-19 does not spread.

## 6. Verified good — things I checked that need no action

`_doctor_rulesets()` already destructures with `*_rest`, so FR-1 costs one call in an existing loop. `_age_text()` clamps skew at `:944`, so BC-2 is satisfied before any new code is written. `_config_digest()` returning `None` gives BC-6 for free. `_saved_clash_port()` returns `None` for a missing or malformed settings file, so BC-10 needs no new guard. `stat` (`:12`) and `time` (`:16`) are imported, so the two new probes add no import. `sorted(CFG_DIR.iterdir())` orders `Path` objects safely. `DOCTOR_MSG_LINES = 5` makes V-9 run 4's "5 lines plus 7 not shown" arithmetic exact. The membership test compares dicts by value, and a JSON round-trip preserves the `query_type` ints, so equality holds; `_filter_rules()` cannot drop the AAAA rule because it carries no `rule_set` key. `sc reload` and `sc update-rules` both exist as shipped commands, so every next step FR-8 promises is performable. The fixture recipe runs non-root with `os.geteuid` shimmed (`docs/dev-map.md:118-126`), so V-10's mode-0000 case is reachable and `CFG_DIR.stat()` still succeeds while `iterdir()` raises — exactly the UNKNOWN I-9 specifies.
