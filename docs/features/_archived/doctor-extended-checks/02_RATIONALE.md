# 02 — Rationale · T-20 `doctor-extended-checks`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## 1. Reuse audit

Every row of the contract was derived by reading the current tree first-hand; line numbers are from
`bin/sc` at `1e454b6`.

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "How old is this rule-set?" | `ruleset_states()` 6-tuple's `mtime` + `_age_text(mtime)` | `bin/sc:845-859`, `:933-948` | **Reuse as-is.** `_doctor_rulesets()` (`:2434`) already destructures the widened tuple and discards `mtime`; the row is one `_age_text()` call in a loop that already runs. This is the edit T-19's K-17 and `rejected-decisions.md § ruleset-timestamp-outside-the-single-reader` predicted by name. |
| "Is it stale?" | (none — T-19's Q-4 deliberately shipped no verdict) | — | **One new constant, no new function.** `RULESET_STALE_DAYS` is read once, over the age T-19's reader already produces. |
| "Has `config.json` drifted?" | `_drift_state()` → `True`/`False`/`None` | `bin/sc:1879-1905` | **Reuse as-is.** T-06 extracted it as the reusable seam for exactly this consumer; `_warn_drift()` (`:1908`) stays `generate_config()`'s renderer and is not called here. |
| "Does this host suppress AAAA?" | `ipv6_decision()` → `(setting, suppress, sentence)` | `bin/sc:1580-1615` | **Reuse as-is, called once**, including its four already-translated evidence sentences — the row writes no fifth. |
| "What does the document say about AAAA?" | `_dns_overlay()` authors the rule | `bin/sc:1618-1639` | **Reuse by extraction.** `_aaaa_rule(suppress)` gives the rule one home; the probe does a membership test against `dns.rules`. No re-spelling, no second decision. |
| "What delay does each node have?" | `stored_delays(port=None)` → `(delays, current)` | `bin/sc:2077-2121` | **Reuse as-is.** Its docstring already promises the `port=` parameter exists so `sc doctor` can call it unchanged; its `is_running()` guard and its one `GET` are inherited, not re-implemented. |
| "Did the Clash API answer?" | `_doctor_clash()`'s existing `clash_api("GET", "/configs", port=port)` | `bin/sc:2568-2587` | **Reuse the result**, by putting the two dependent rows in the same section. A second request would be a second opinion (AC-S2) and a second 3 s wait. |
| Bounded DNS lookup through the install | `clash_api()` + sing-box's `/dns/query` route | `bin/sc:2045-2065`; binary probe P-1 | **Reuse `clash_api()`.** No new transport, no new envelope, no new timeout; T-18's totality is inherited. |
| "Is this mode too wide?" | `CRED_MODE` (`0o600`) + `install.sh`'s `mode & 8#077` predicate | `bin/sc:41`; `install.sh:324-363` | **Reuse the constant and the predicate; do not reuse the sweep.** The installer's function *chmods*, so it must not roam (T-13 NG-11); a reporter only reports, so it enumerates. Six characters of Python, no shell-out. |
| Foreign text made output-safe | `_plain()` | `bin/sc:2338-2380` | **Reuse** for every `{e}` and every path rendered from the filesystem. |
| Multi-line quotation + elision | `DOCTOR_MSG_LINES` + `"... {n} more line(s) not shown"` | `bin/sc:2335`, `:2493-2497` | **Reuse for the permission list** — BC-21 asks for the same rule and the same constant. |
| Row grammar, classes, exit mapping, per-row flush, per-section isolation | `_doctor_print()`, `DOCTOR_*`, `cmd_doctor()` | `bin/sc:2330-2646` | **Reuse untouched.** Every new fact is data inside that machinery. |
| Egress name | endpoint literal inside `_egress_ip()` | `bin/sc:407-416` | **Extract one constant** so the DNS row and the egress row resolve the same name (Q-13). |

Nothing here is a new module. The two new functions are probes in the existing `# doctor` block, the
shape every one of the seven existing sections already has.

## 2. Risk analysis

| # | risk | mitigation |
|---|---|---|
| R-a | **The `/dns/query` response shape is inferred from a binary string table, not from a live body.** If sing-box's fork names the records something other than `Answer`, the DNS row reports "no records" on a healthy host — and a fixture stub written from this design would *agree with the bug*. | K-20 + P-2: stage 4 issues one read-only `GET` against the live API **before** writing the row, pastes the body into `04_DEVELOPMENT.md`, and a contradiction is routed back to stage 2. V-7's stub bodies are copied from that observation, not from this document. |
| R-b | **A degenerate build that reports PROBLEM everywhere** passes AC-B1…AC-B7 (T-06's F-1 failure). | V-12 is written as the adversary: exit 0, exactly +5 rows, no path and no next step anywhere. V-8 is the third corner (UNKNOWN where a prerequisite failed). No single build satisfies all three. |
| R-c | **A fixture makes the whole Clash matrix vacuous.** `CLASH_PORT` and `LANG` are reassigned in `main()`; `is_running()` is `False` with no init system, so `stored_delays()` issues no request and every node-delay assertion passes for the wrong reason. | K-19 states all four fixture obligations, including the `subprocess.run` stub that makes `is_running()` true **without** execing `systemctl` (T-19's K-19, the live-service incident). V-6's control (entries carrying a delay ⇒ OK) is only reachable if the request really went out. |
| R-d | **`sc doctor` writes something.** Six new probes, one shared root, and `_init_files()` hard-codes `/var/lib/sing-box`. | K-8 enumerates the forbidden callees; V-14 snapshots the fixture root before and after **and** installs raisers over the four writers plus a positive control proving a raiser fires. |
| R-e | **Extracting `_aaaa_rule()` changes the emitted `config.json`.** T-15/T-16/T-17 differentials pin those bytes and a user's host would regenerate a different document. | K-5 + V-11: a byte comparison of `config.json` under both decisions, run in order 1 **before** any row is written, so a divergence is caught while the diff is three hunks. |
| R-f | **The report gets louder than it is useful.** Five new rows × three states, on hosts where the world-readable `/etc/sing-box` is normal, could produce a screen people learn to ignore. | Q-5's narrowing (`mode & 0o022` for the directory, never `0o077`) keeps the directory row silent on 100% of today's installs; the 60-day threshold is unreachable on any preset cadence; NFR-3/BC-20 keep the healthy screen at one row per check with no paths. `_drift_state()`'s own docstring (`bin/sc:1890-1892`) is the precedent this follows. |
| R-g | **Twenty-eight new strings is the largest string batch in the batch**, and R-19 is the standing counter-example of what a careless key does. | K-14 + V-15: no namespaced keys, both languages per key, same placeholder set, no `失败`. Six existing keys are reused rather than re-worded (`cannot read {path}: {e}`, `... {n} more line(s) not shown`, `(none)`, `not probed — no port recorded`, `this check could not run: {e}`, plus `ipv6_decision()`'s four sentences). |
| R-h | **An honest row that is nonetheless surprising**: BC-22 turns a working-but-drifted host's exit from 0 to 1. | Stated in the contract's migration paragraph and in the README's exit-status table (E-11/E-12), not discovered by a user. Q-11 already ruled that drift is PROBLEM because it is the only class carrying an action. |

## 3. Why the design is this size

Counted honestly: **2 new probe functions, 2 new `DOCTOR_SECTIONS` entries, 1 extracted 4-line
function, 2 constants, 5 new rows, 28 strings, ~150 changed lines in `bin/sc`** — and, for the reader
who must hold it in their head, exactly one new concept per check, each named after a fact the project
already had a word for.

The three things that could have made it bigger were all declined and are recorded in the contract's
`## Smaller alternative rejected`: a section per fact (would have forced a second Clash request and
broken FR-12), an `_age_seconds()` helper (no second consumer today), and a per-path PROBLEM row
(report size scaling with the directory). The one thing that could have made it smaller — dropping
FR-6 — was decided by running the probe rather than by preference, and the probe said the mechanism
exists on a seam that is already there.

## 4. Evidence cited

- **P-1** (this stage, first-hand, read-only): `/providers/rules` 1 · `/dns/query` 0 · `clashapi.queryDNS` 1 · `clashapi.dnsRouter` 1 · `invalid query type` 1 · `TCRDRA` 1, in `/usr/local/bin/sing-box`. The first is T-10's calibration control; the second is the negative control that prevents the naive reading; the last is the packed key blob of the Google-DoH-shaped response.
- `_dns_overlay()` emits `{"action": "predefined", "rcode": "NOERROR", "query_type": [28,64,65] | [64,65]}` at `dns.rules[0]` — `bin/sc:1636-1639`.
- `clash_api()` builds `f"http://127.0.0.1:{port or CLASH_PORT}" + path`, so a query string needs no new plumbing — `bin/sc:2054`.
- `_doctor_clash()` already holds "did the API answer" as `answer is not None` — `bin/sc:2580-2586`.
- `load_nodes()` is `json.loads(NODES_PATH.read_text())` with no guard — `bin/sc:492-493` — hence I-7's guard tuple, which must include `ValueError` for the non-UTF-8 case (insight index, 2026-08-14).
- `stat` is already imported (`bin/sc:12`), so the permission probe needs no new import; `time` is imported (`:16`) for `time.monotonic()`.
- `install.sh`'s sweep excludes `settings.json` and tests `mode & 8#077` — the predicate and the exclusion this task reuses.
- The insight index's `urlopen(timeout=N)` entry (30.1 s measured) is why K-15 forbids any wall-clock claim, and why the DNS row prints a measured elapsed rather than a promise.

## 5. Proposed `CONTEXT.md` entries (not written to that file here — Q-15 / T-19 precedent)

**stale rule-set** — a usable rule-set whose bytes were last written longer ago than
`RULESET_STALE_DAYS` (60 days), i.e. one whose automatic refresh has demonstrably not run. Distinct
from *unusable*: it still loads and still routes. _Avoid_: old, outdated, expired, out-of-date.

**credential directory** — `/etc/sing-box/`, the directory holding every credential document, the
drift record and the user override. A file's exposure is a property of where it sits as much as of its
own mode. _Avoid_: config dir, sing-box directory, `/etc/sing-box` (in prose).

**wide mode** — a mode granting any permission to group or other on a regular file in the credential
directory (`mode & 0o077`), or write to group or other on the directory itself (`mode & 0o022`).
_Avoid_: insecure permissions, bad permissions, world-readable (true of the directory on every host,
and deliberately not a finding).
