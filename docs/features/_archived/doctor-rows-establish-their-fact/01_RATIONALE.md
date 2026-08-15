# 01 — Rationale · T-26 `doctor-rows-establish-their-fact`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. Per-row re-verification — what stage 1 established itself, and how

Stage 1 held **no execution tool** on this dispatch (Read / Grep / Glob / Write only), so every
re-establishment below is by reading. Where a claim needs a runtime observation it is marked
inherited and routed to a later stage (contract OQ-8, BC-10, AC-1/AC-5/AC-9/AC-10). Nothing is
inherited silently, and no requirement above rests on an inherited figure.

### R-49 — re-established in full, by reading

| step | evidence |
|---|---|
| the guard returns without a subprocess | `bin/sc:2202-2208` — `if SYSTEMD: … elif OPENRC: … return False`; `SYSTEMD` is `bool(shutil.which("systemctl"))` at `:75` |
| the short-circuit | `bin/sc:2231-2232` — `if not is_running(): return {}, None`, inside the reader, before the request |
| the unread count | `bin/sc:2845-2857` — `delays, current = stored_delays(port=port)`, `n = len(tags & set(delays))`, `n == 0` → the `0/{total}` PROBLEM row |
| the branch is reached only after the API answered | `bin/sc:2821-2831` — `/configs` returned non-`None` and the row above already printed `[OK] Clash API responding` |
| `sc ls` shows the same emptiness (R-49's "narrow" clause) | `bin/sc:2308-2311` — same `stored_delays()` call, `-` in every delay cell |
| the failure direction | the row is **PROBLEM**, so R-49 fails **loud**. R-48 and R-50 fail **silent** (a false `[OK]`). That asymmetry is why FR-6 is capped at the smallest honest change and why AC-5 accepts either resolution. |

The framing that made FR-6 short: `_doctor_clash()` asks "is the process alive?" **twice** — once by
the `/configs` answer it already holds, once through `is_running()` inside the reader — and the
weaker answer overrides the stronger. That is rule 85's *duplicated judgment* test, so the fix
removes a second opinion rather than adding a check. `docs/dev-map.md:163-165` ("don't give
`sc doctor` a second opinion … it consumes `is_running()` … and it must stay that way") is not
violated by either admissible design: `_doctor_service()` already renders "no init system" as
UNKNOWN (`bin/sc:2736-2739`), so an UNKNOWN node-delay row in the same state consumes the same
constants the doctor already consumes.

### R-50 — mechanism and stakes re-established by reading; one runtime figure inherited

- Position-blind test: `bin/sc:2717` — `if isinstance(rules, list) and _aaaa_rule(suppress) in rules`.
- Why position is load-bearing: `CONFIG_BASE`'s `dns.rules` (`bin/sc:1310-1323`) opens with
  `{"server": "remote_dns", "clash_mode": "Global"}` and `{"server": "direct_dns", "clash_mode":
  "Direct"}`. Each matches **every** query in its mode, so a rule after them never fires in
  `global`/`direct`. The base's own comment at `:1314-1317` records that the rule "USED to sit here"
  and "disappeared in exactly the two modes people switch to when something is broken";
  `_dns_overlay()`'s docstring (`:1763-1767`) states index 0 is "the whole point"; and
  `_telemetry_overlay()` (`:1855-1862`) re-derives the identical conclusion for its own rule, with
  its own measurement.
- The published promise: `README.md:126` — "The rule that carries this is evaluated **first**, ahead
  of both routing-mode rules, so it applies in `rule`, `global` and `direct` alike"; `README.md:263`
  and the zh mirror at `README.zh-CN.md:263` publish the row as "whether the `config.json` on disk
  carries that decision". A membership test does not establish either sentence.
- Inherited: T-20's stage-6 run showing types 64/65 unsuppressed in `direct` at index 3
  (`docs/features/_archived/doctor-extended-checks/06_TEST_REPORT.md:50`, DEF-3 at `:125`). Not
  load-bearing — FR-4 rests on the chain and the published promise, both read here.

### R-48 — the mechanism read; the numbers inherited

- One read-only GET of the running install's own resolver: `bin/sc:2861-2875`, name from the single
  `EGRESS_HOST` constant (`:461`), which `_egress_ip()` also resolves (`:477`).
- The cache exists and is the install's own: `CONFIG_BASE["experimental"]["cache_file"]` is
  `{"enabled": True, "path": "/var/lib/sing-box/cache.db", "store_fakeip": False}` (`bin/sc:1355`),
  and `dns.independent_cache` is `True` (`:1325`).
- **No name in this project goes unwarmed.** The DNS row (section 7) and the egress row (section 8)
  resolve the same name in one run by design (T-20 Q-13), and `sc status` resolves it again through
  `_egress_ip()`. So "a name no run warms" does not exist among the constants this project ships,
  and inventing one means a second endpoint constant — refused by FR-9.
- Inherited and **not** re-measured: 175 ms / 4 ms, the 195→190→186 TTL decrement, the 1800 s
  negative hold (`docs/tasks.md` R-48). FR-8 needs only that the cache exists and serves this
  endpoint, which is read above.
- What stage 2 must probe first-hand (BC-10): whether `GET /dns/query` accepts any parameter that
  bypasses or ignores the cache, on the *installed* binary, read-only. The cheap route is the
  binary's own strings plus one read-only request; a mutating call is forbidden by the dispatch and
  by FR-9.

### R-24 — cost re-established exactly

`bin/sc:3208-3209` prints `Nothing changed — the sing-box service was not touched`.
`bin/sc:3270-3272` (`cmd_telemetry`) prints, for the identical state, `Nothing changed — the sing-box
service was not touched; run `sc reload` to apply this setting to a configuration generated before
it` — whose zh half is already in the table at `bin/sc:209-212`, with a comment at `:196-197`
recording that it names `sc reload` "because the one state where 'nothing changed' misleads is a
config generated before this setting existed". So the fix is a key swap at one print site: **one
changed line, zero new keys**. `cmd_ipv6`'s two comparison sources (`:3200` and `:3204`) both come
from `ipv6_decision()`, i.e. from the host — T-16's AC-6 is untouched, exactly as the dispatch
requires.

## 2. Candidate answers, and the argument that selected among them

### OQ-1 (membership vs position) — three candidates

1. **Narrow the sentence** ("`config.json` contains this rule"). *Smallest*: one key + one zh entry,
   no check change. **Rejected**: the class carries the verdict, so `[OK]` still appears on a host
   where suppression is not in force in `global`/`direct` — the R-22 trap intact — and the narrowed
   sentence answers a question no user has ("is this dict a member of that list?"). Narrowing is
   admissible only where the existing class stays honest (contract FR-2); here it does not.
2. **Evaluate the chain** — decide whether any preceding rule preempts the AAAA rule. **Rejected as
   larger and as a second opinion**: it re-implements sing-box's matching semantics inside `sc`, for
   documents `sc` did not author. Out of scope item 5.
3. **Test the position `sc` emits** (adopted). The probe keeps asking one question about `sc`'s own
   emission, gains no knowledge of sing-box semantics, and costs one expression. Its accepted cost is
   a wider PROBLEM branch (a document from a pre-T-16 build, or one a user override reordered) —
   which T-20 already accepted for this row in RS-3 and F-14 as "the inverse of the R-22 defect", and
   which BC-3 makes honest by requiring a next step valid for both causes.

The maintenance trap candidate 3 carries — a future `sc` overlay `$prepend`ing to `dns.rules` would
make a healthy host read PROBLEM — is why FR-5 exists. It is answered as *one home for the position*
(the arrangement `_aaaa_rule()` already gives the rule), **not** as a new function; `_aaaa_rule()`'s
own docstring warning at `bin/sc:1748-1751` is about indexing into the **overlay payload**, which
this does not do — it indexes the emitted document.

### OQ-3 (narrow vs establish) — why the answer differs per row

The test that decides it: *would the row's existing outcome class still be wrong on a host where the
underlying thing is broken?* R-48 → no (`[OK]` truthfully means "the install answered"), so narrow.
R-49 → the claim is a count, and a count is not narrowable; the honest options are read it or say
UNKNOWN. R-50 → yes, so the check changes. This is the whole of contract FR-2, and it is what keeps
the task from becoming three strengthened checks.

### OQ-4 (one construct or three) — the over-build this task is most likely to buy

The tempting abstraction is an "established fact" wrapper — a probe-result type carrying provenance,
or a decorator that downgrades a class when its input was not read. Priced: three unrelated probes,
one new concept every future reader must hold, against three sentences and one expression. Rule 85's
counter-rule ("not every stated symptom needs its own code" cuts both ways — nor does every stated
*cause* need its own construct). AC-16 is the gate on it, with the T-25 precedent of a whole output
contract shipped with **no new function at all**.

### OQ-5 (R-24) — what would have made it "leave filed"

If the reusable sentence had not existed, the price would have been one new English key plus one zh
entry plus the print-site edit — three lines and a new key for a row whose owner is "next task
touching `cmd_ipv6`". The dispatch's one-line test would have failed and the honest answer would have
been "leave filed". It survives only because T-17 already paid for the sentence. The one residual
judgement, handed to stage 2 as BC-11: "a configuration generated before it" reads correctly for the
telemetry case (before the setting existed) and for the IPv6 case (before this setting was made); if
stage 2 disagrees, the row drops rather than buying a key.

## 3. Related tasks — links, not re-descriptions

- **T-20 `doctor-extended-checks`** — the task being edited: `docs/tasks.md` completed row +
  `docs/features/_archived/doctor-extended-checks/` (FR-4, FR-5, FR-6, FR-13, BC-11, BC-16, Q-13,
  RS-3, CR-2/RES-1, DEF-1/DEF-2/DEF-3). Its own rollback shape — the clean-host permission row fixed
  by **narrowing the sentence, never the check** (`bin/sc:2957-2965`, insight-index 2026-08-14) — is
  the precedent contract FR-2 generalises.
- **T-16 `dns-resilience`** — `docs/features/_archived/dns-resilience/`: FR-4 (`sc ipv6`), I-6
  (`_dns_overlay()`), AC-6 (no second opinion in `cmd_ipv6`), R-24's origin at stage 5 RES-2.
- **T-17 `telemetry-reject-list`** — `docs/features/_archived/telemetry-reject-list/`: the sentence
  R-24 reuses, and an independent measurement of the same rule-position hazard.
- **T-05 `sc-doctor`** — `docs/features/_archived/sc-doctor/`: the read-only invariant and the
  `doctor` arm above argument dispatch; `.harness/rejected-decisions.md` §`doctor-exit-status-always-zero`
  for the 0/1/2 mapping BC-9 depends on.
- **T-15 / T-18** — `stored_delays()`'s contract and `clash_api()`'s single envelope, both of which
  FR-6 must consume unchanged.
- **T-25 `output-layer-contract`** — the size bar (NFR-3) and the practice of reporting a criterion
  **NOT-DISCRIMINATING rather than passed**, which AC-4/AC-6/AC-7/AC-13/AC-14/AC-15 adopt in advance.
- **R-74** (`docs/tasks.md`, T-24 block) — five prose claims wrong in one task, all in the same
  direction. FR-13 exists because this task changes two rows' claims and both READMEs describe them.

## 4. Traps the fixtures must avoid (for stage 2's V-table and stage 6)

All from `.harness/insight-index.md` and `docs/dev-map.md:121-158`; each has cost a prior task a round.

1. The loader recipe's `open("bin/sc").read()` needs `encoding="utf-8"` (R-77).
2. An un-neutralised import re-execs the **installed** `/usr/local/bin/sc`; its signature is an
   argparse usage error at exit 2, not a loud warning (R-78 — T-25 voided a run on this).
3. `sc.SYSTEMD = True` **and** a `subprocess.run` stub are both required for the AC-6 control;
   without the stub, candidate and control agree and the criterion measures nothing.
4. The fixture's own `settings.json` must record `clash_api_port`, or `_saved_clash_port()`
   (`bin/sc:417-426`) returns `None` and all four Clash rows go UNKNOWN before any of this is
   reached; `main()` re-assigns `CLASH_PORT` after import, so setting the module constant is not
   enough.
5. `main()` re-assigns `LANG` after import, so a zh assertion driven through `main()` renders English
   and passes vacuously.
6. A probe that raises loses its **whole section** (four rows), not one row — so a candidate that
   tracebacks inside `_doctor_clash()` can look like a passing table with three rows missing.
7. Never drive `_init_files()`: it hard-codes `/var/lib/sing-box`.

## 5. Glossary terms proposed for `CONTEXT.md` (not written there — the T-19/T-20 precedent)

- **Unestablished verdict** — a reported outcome whose class was derived from a proxy for its
  subject rather than from the subject: a count no request produced, a membership standing in for a
  position, a cached answer standing in for a resolution. _Avoid_: "false positive", "stale row".
- **Narrowing the claim** — repairing an unestablished verdict by making the sentence exactly as wide
  as what the probe established, leaving the check untouched. Admissible only when the row's outcome
  class stays honest afterwards. _Avoid_: "weakening the check", "downgrading the row".
