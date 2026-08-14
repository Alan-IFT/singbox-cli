# 01 — Rationale · T-20 `doctor-extended-checks`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. The goal sentence, clause by clause, re-derived from the code

Six clauses. **Five survive unchanged; one is refuted.** Every check below is a first-hand read of
the current tree, not a reading of the upstream documents.

| clause | verdict | the call it stands on (evidence) |
|---|---|---|
| rule-set age | survives | `ruleset_state()` returns `(status, digest, size, mtime)` from **one** open handle, `os.fstat(fh.fileno()).st_mtime` inside the same `with` (`bin/sc:824`); `ruleset_states()` carries it (`:845-859`); `_age_text(mtime)` is the one renderer, with no command-specific argument (`:933-948`) and today exactly one call site, `cmd_status()` (`:2302`). `_doctor_rulesets()` already destructures the widened tuple and ignores `mtime` (`:2434`). |
| per-node latency | survives | `stored_delays(port=None) -> (delays, current)` (`:2077-2121`), with the `is_running()` guard **inside** the function and a `port=` parameter its docstring says exists so `sc doctor` can call it unchanged. |
| config drift | survives | `_drift_state() -> True/False/None` (`:1879-1905`), extracted by T-06 as the one judgement, with `_warn_drift()` (`:1908-1927`) as a renderer over it. `_config_digest()` (`:1834-1856`) hashes the file's bytes. |
| file permissions | survives | `CRED_MODE = 0o600` (`bin/sc:41`) — one definition, one reader (`_write_private()`), a named single-reader constant by design. `install.sh`'s `sweep_credential_modes()` (`:324-363`) fixes the predicate (`mode & 8#077`) and the exclusion (`settings.json`, `:312-315`). |
| IPv6 consistency | survives | `ipv6_decision() -> (setting, suppress, sentence)` (`:1580-1615`), stated to have exactly two callers and to be the one place the decision exists; `_dns_overlay()` (`:1618-1639`) is where it reaches the document. |
| **DNS timing** | **refuted** | See §2. |

## 2. Why "DNS timing" is refuted, and what replaced it

**Measured, first hand, in this tree.** `grep -n timeout bin/sc` returns nine lines: three `urlopen`
socket timeouts (3 s Clash `:2060`, 8 s egress `:415`, 30 s download `:1070`), one `idle_timeout:
30m` inside T-15's `urltest` group (`:1803`), one appearance in the visible-key set (`:2676`), one zh
string (`:299`), and three comments. **`CONFIG_BASE`'s whole `dns` block (`:1174-1206`) carries no
timeout key of any kind**, and `_dns_overlay()` (`:1636-1639`) adds only `query_type`. There is
nothing to report.

That is consistent with T-16's own measurement, which is why no new probe was needed to settle it:
sing-box 1.13.15 rejects `"timeout"` on a DNS server, on the `dns` block and on a DNS rule, proved
with a bogus-key control; the per-query deadline is a fixed 10.0 s at which the query is dropped
silently; and the rule chain never falls through, so `dns.final` is the no-match default rather than
a failure fallback (`.harness/insight-index.md:14-15`; R-23 in `docs/tasks.md`).

**Candidates for what the row could become, and the argument that chose among them.**

| candidate | why not / why |
|---|---|
| Report the configured DNS timeout | Refuted above. It would print a value no document contains. |
| Report the DNS *topology* — that `remote_dns` is reached through `detour: proxy`, so resolution depends on the selected node | A static fact identical on every host. It would print the same sentence forever and never conclude anything, which is the user-facing bloat rule 85 warns about applied to a screen. |
| Drop the row entirely, keep five | Defensible, and it stays available under BC-16. Rejected as the default because **no other row catches R-23's failure**: a node that accepts and never answers keeps its stored delay (the history entry persists, and the hung probe never completes — `.harness/insight-index.md:13`), so the node-delay row reads OK, the Clash row reads OK, and only the egress row fails, leaving the reader without the cause. |
| **Measure one lookup through the running install** (chosen) | It is the only candidate that produces a conclusion, and it isolates the DNS half of the egress row's failure. It is also the one clause with **no owning call**, so it is the one place this task must buy code — which is precisely why BC-16 forces a first-hand probe before it is bought. |

**Why the mechanism is a stage-2 obligation and not settled here.** Settling it requires running a
read-only probe against the live sing-box (does its Clash API expose a DNS query route?), and this
stage held no shell. Rather than guess a mechanism into a binding requirement — the failure mode
this batch has been correcting since T-18 — BC-16 states the drop rule and BC-17 rules out the one
mechanism that looks obvious and cannot work: `socket.getaddrinfo` takes no timeout argument, so a
row built on it cannot honour a bounded wait and would reintroduce exactly the stall it reports.
R-35's number is the companion warning: `urlopen(timeout=3)` kept a call alive **30.1 s**, so
"bounded" must mean a bound the caller sets on each operation, and the report must not claim a total.

## 3. Related historical tasks

Linked, not re-described — read the entries in `docs/tasks.md` and the archived stage documents.

- **T-05 `sc-doctor`** — `docs/features/_archived/sc-doctor/` — the command being extended. Its
  structural results are inherited verbatim: one ordering table with a single reader, causal order,
  three outcome classes, per-section isolation, per-row flush, and process-wide read-only enforced by
  keeping `doctor` off the start-up writers (`bin/sc:3340-3357`). Its out-of-scope item 8 excluded
  remediation suggestions; T-20's goal sentence is what introduces them, which is why Q-8 confines
  them to the row's value text rather than to a new print path.
- **T-19 `ruleset-staleness-visibility`** — `02_SOLUTION_DESIGN.md` **K-17** states the contract
  directly: T-20 consumes `ruleset_states()`'s `mtime` and `_age_text()` exactly as
  `_doctor_rulesets()` already consumes `size` and `_status_text()`. **Q-4** is the other half: no
  threshold in T-19, and any future verdict must be a function of that reader's age with no second
  derivation. `.harness/rejected-decisions.md § ruleset-timestamp-outside-the-single-reader` names
  T-20's row as the *nameable future edit* that justified the tuple widening — this task is the one
  that has to make that prediction true.
- **T-15 `proxy-urltest-group`** — the stored-delay reader and R-21 (the delay map is keyed by the
  API's tags, not by `sc`'s nodes; a node tagged `GLOBAL` collides). FR-5 counts against `nodes.json`
  and states counts rather than a table, so R-21 is neither closed nor widened here.
- **T-14 `config-composition-layer`** / **T-06 `sc-config-show`** — the drift record and
  `_drift_state()`'s extraction as a reusable seam; T-06's V-12 is what makes Q-9's ruling forced.
- **T-13 `config-write-permission-hardening`** — the credential-document definition, the 0600
  contract, the sweep's predicate and its deliberate non-roaming (NG-11), and R-10 / R-11.
- **T-16 `dns-resilience`** — `ipv6_decision()`, `sc ipv6`, R-23 and R-24. FR-4's row partially serves
  R-24: the stale-document stall it describes becomes visible, and the row's next step names the
  escape (`sc reload`) that `cmd_ipv6` never prints.
- **T-18 `status-egress-via-clash-api`** — `clash_api()` is total by one envelope closing six
  escaping classes; any new Clash-dependent row inherits that and must not add a second envelope
  (AC-S2). R-32 is T-18's residual, assigned to this task.

## 4. Candidates behind the remaining binding answers

**Q-3, the threshold value.** Candidates: 7 days (fires on any host on the weekly preset that misses
one run — a warning that cries wolf); 30 days (indistinguishable from a healthy *monthly* host, whose
files are up to 31 days old); **60 days** (two missed monthly runs, roughly eight missed weekly runs
— unreachable while auto-update works on any preset the tool offers); derived from
`settings["update_interval"]` (`bin/sc:3074`, `:3113`) — rejected because the key is absent on a
default install and a custom `OnCalendar` expression (`:3054-3057`) is not convertible to a duration,
so the derivation is machinery that still needs a fallback constant.

**Q-4/Q-5, the permission predicate.** Candidates: (a) check only `CRED_FILES`' two names — exactly
reproduces R-10's blind spot, so the row would ship already known to miss the reported instance;
(b) enumerate backup *patterns* — fragile machinery that a differently-named backup defeats;
(c) **enumerate every regular file in the directory, minus `settings.json`** — one exclusion, no
pattern, and it catches a file nobody predicted. (c) is data, (b) is machinery, and the asymmetry
that makes (c) safe is that reporting is not modifying: NG-11 constrains a sweep that `chmod`s.
For the directory itself, `mode & 0o022` was chosen over `mode & 0o077` because the world-readable
directory is the state of every host including this one (R-11's own text), and a row that is PROBLEM
on 100% of installs is the anti-pattern `_drift_state()`'s docstring already names ("a warning that
fires on 100% of installs at first upgrade teaches people to ignore exactly the warning that has to
stay loud", `bin/sc:1890-1892`).

**Q-11, drift's class.** Candidates: OK-with-a-note (no class carries it — the grammar has three
classes and a note is not one of them); UNKNOWN (semantically false: the fact *was* established);
PROBLEM (chosen). The cost is honest and is written down as BC-22: a working but hand-edited host
now exits 1.

**Q-12, where the permission rows print.** Candidates: beside the configuration section (same
subject — the files in `/etc/sing-box`); last (chosen). The ordering rule is causal, not thematic;
a mode grants nothing to root, so it explains no row below it, and placing it mid-screen would push
the binary → rule-sets → config → service → egress chain down for a fact that is never its cause.

**Q-10 / FR-5's shape.** A widened `stored_delays()` returning each history entry's timestamp was
considered — it would let the row say how old the stored delay is, closing the "no row may claim a
fresh measurement" gap more tightly. Declined: it widens a reader's contract for a fact no
conclusion in this task needs, and out-of-scope 5 keeps it out.

## 5. How the acceptance criteria are built against R-22 (and T-06's sharper version)

R-22(a): an AC set that pins the artifact and never the behaviour passes a gate it should fail.
T-06's F-1: two criteria that are *both* satisfied by a useless build agree with each other.

The defence here is structural rather than exhortative:

1. **Every new check has a broken-fixture criterion** — AC-B1…AC-B7 — each of which requires the row
   to report a *problem* on a host where the thing really is broken. A build that reports OK
   everywhere fails all seven.
2. **AC-B8 is their adversary, not their friend.** It requires every new row to be OK, to name no
   path and to carry no next step on a healthy fixture. A build that reports PROBLEM everywhere
   passes AC-B1…AC-B7 and fails AC-B8. The two halves cannot be satisfied by the same degenerate
   build, which is exactly the property T-06's AC-B1/AC-B2 pair lacked.
3. **AC-B12 is the third corner**: a build that reports PROBLEM whenever it cannot tell would pass
   both halves above and fails here, because a dependent section must be UNKNOWN when its
   prerequisite failed.
4. Each fixture is constructible without root and without touching the live host, by repointing the
   path constants (`CFG_DIR`, `RULES_DIR`, `SETTINGS_PATH`, `STATE_PATH`, `IF_INET6_PATH`) and by
   binding a stub Clash port that is **recorded in the fixture's own `settings.json`** — without
   that, the insight-index trap fires twice over: `CLASH_PORT` and `LANG` are both reassigned in
   `main()` after import (`bin/sc:3353-3357`), so a fixture setting only the module globals renders
   English and talks to the live instance on 29090. `sc doctor` does not resolve a port at all, which
   makes `_saved_clash_port()`'s `None` path (BC-10) the one a careless fixture silently takes.
5. AC-B14 is the one criterion no agent in this pipeline can discharge, and it is pre-declared
   **BLOCKED-and-filed** rather than substituted, following R-31 / R-41 / R-47.

## 6. Proposed `CONTEXT.md` entries (not written to that file here — T-19 precedent)

**stale rule-set**: A usable rule-set whose bytes were last written longer ago than the project's one
staleness threshold, i.e. one whose automatic refresh has demonstrably not run. Distinct from
*unusable*: a stale rule-set still loads and still routes; what is wrong is its content's age.
_Avoid_: old, outdated, expired, out-of-date

**credential directory**: `/etc/sing-box/` — the directory holding every credential document, the
drift record, the user override and `settings.json`. Named as one concept because a file's exposure
is a property of where it sits as much as of its own mode: anything a user leaves here (a hand-made
backup of `config.json`, an override carrying a node password) is exposed by a wide mode even though
no code in this project created it.
_Avoid_: config dir, sing-box directory, `/etc/sing-box` (in prose)

## 7. Standing project truths carried into this analysis

- `verify_all` E.6 matches `^##\s+Adversarial\s+tests`; a numbered QA heading turns a SKIP into a
  FAIL. This task's QA sections must not be numbered.
- `_init_files()` hard-codes `/var/lib/sing-box`, so any harness driving a non-`doctor` command
  writes to the real path. Every fixture here drives `doctor` only.
- `TRANSLATIONS` has no `en` table, so a key *is* the English text; R-19's five `ls.*` keys are the
  standing counter-example and this task adds more strings than any other in the batch.
- `失败：` in `bin/sc` output is a load-bearing diagnostic grep; no new zh string may contain it.
- `/providers/rules` is a compatibility stub, and `GET /proxies` serves stored history with no
  `meanDelay`; T-05 shipped DEF-2 open (a hung Clash port loses the port row), which is why FR-5 and
  FR-6 both hang off the persisted port and both degrade to UNKNOWN rather than to a guess.
