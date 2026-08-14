# 01 — Requirement Analysis · T-18 `status-egress-via-clash-api`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

`sc status` states every fact it promises — active node, route mode, Clash API address, public egress
address — as one line each in the user's language, and never as a Python traceback, whatever the local
Clash API answers or fails to answer; the egress address it prints is the address this host's traffic
actually leaves from, established by observing the command on a pure-TUN host rather than assumed.
The batch goal's stated cause is refuted rather than implemented: no code in `bin/sc` points the egress
probe at a local inbound (Q-1), so this task deletes that phantom instead of building against it, and
what remains is one exception envelope at the one seam both symptoms come from (Q-2, Q-3).

## In-scope behaviors

**FR-1** — `clash_api()` yields exactly two kinds of result: a JSON **object** decoded from the local
Clash API's answer, or the single no-answer value `None`. It raises no exception to any caller and
returns nothing else — not a number, a string, a list or `null` decoded from a 2xx body. An answer with
an empty body keeps yielding the empty object, so a `204` to a `PUT`/`PATCH` still reads as success.

**FR-2** — Every failure to obtain that object is one no-answer result: no route to the port, a refused
connection, an HTTP error status, no answer within the existing timeout, a body that is not valid UTF-8,
a body that is not valid JSON, a body that ends early, and a body that decodes to something other than a
JSON object. The judgment lives in `clash_api()` alone; no caller adds exception handling of its own.

**FR-3** — On a running host `sc status` prints each of its section headings followed by exactly one
value line: the active node, the route mode, the Clash API address, and the public egress address — or,
for a fact it could not obtain, one line stating that it is unavailable or naming the error, in the
user's language. No Python traceback reaches the user from the Clash API call or from the egress probe,
and the command keeps exiting 0.

**FR-4** — The egress address keeps coming from the one existing egress query that `sc status` and
`sc doctor` share, unchanged: same endpoint, same 8 s socket timeout, same byte-faithful value. This
task adds no second query, no proxy argument, no Clash API endpoint and no other second opinion about
what this host's public address is.

**FR-5** — Every user-facing string this task adds or changes is an English sentence used as the
translation key with a `zh` entry carrying the same placeholder set; no new `zh` string contains
`失败：`; no new key is namespaced in the `ls.*` shape. Q-9 rules that the required string budget is
**zero** — the two keys `sc status` already uses cover every state FR-3 names.

## Out of scope

1. R-29's state-file I/O seam — `load_settings()` and `load_nodes()` letting `UnicodeDecodeError`, a
   non-object JSON body or a missing file reach the user as a traceback. Different seam, different
   input class, named owner (Q-5).
2. R-12 — helpers that `sys.exit` inside a function owing a run-level outcome. This task adds no
   `sys.exit` and removes none (Q-6).
3. Any Clash API endpoint as a source of the egress address, and any new endpoint call of any kind,
   including an active latency probe (`/proxies/:name/delay`) (Q-4).
4. Changing `_egress_ip()` in any way — endpoint, timeout, decode, byte-faithfulness, call sites.
5. `sc doctor`'s rows, wording, ordering, section set or exit status; and the `_plain()` scrubbing
   difference between `sc doctor`'s rendering and `sc status`'s (Q-7).
6. `sc status`'s exit status: it keeps exiting 0 on every path, and reports no findings-derived status.
7. Anything `sc status` prints when the service is stopped: the command keeps printing the service
   section and the TUN section only.
8. Bounding, shortening or splitting the egress probe's wall-clock wait; no new timeout, no thread, no
   bounded name resolution, no cancellation (Q-11).
9. A response-size cap on `clash_api()`, or any other defence against a hostile process already running
   on this host's loopback interface (BC-12).
10. R-19 (the five `ls.*` keys), R-16 (the merge's type-mismatch vocabulary), R-21 (`RESERVED_TAGS`
    versus `GLOBAL`), R-15 (the override pipeline's envelope), R-9 (a committed test harness and a new
    `verify_all` step) — each has a named owner elsewhere.
11. `install.sh`, `uninstall.sh`, `systemd/`, the shape of `settings.json` or `nodes.json`, and the
    `# Config composition` / `# Config generation` regions of `bin/sc`.

## Boundary conditions

**BC-1** — Something holds the Clash API port and never answers → the route-mode line reads
`(unavailable)` in the user's language, `sc status` completes, exit 0, no traceback.

**BC-2** — A 2xx answer whose body is not valid JSON → BC-1's outcome.

**BC-3** — A 2xx answer whose body is not valid UTF-8 → BC-1's outcome.

**BC-4** — A 2xx answer whose body ends before its declared length → BC-1's outcome.

**BC-5** — A 2xx answer that decodes to valid JSON that is **not** an object (`5`, `"x"`, `[1,2]`,
`null`) → the no-answer result. `sc status` prints BC-1's line, and `sc use` does not report a switch
that did not happen.

**BC-6** — Nothing listening on the Clash API port, or the connection is refused or reset → BC-1's
outcome, unchanged from HEAD.

**BC-7** — An HTTP 4xx or 5xx status from the Clash API port → the no-answer result, unchanged from HEAD.

**BC-8** — A 2xx answer with an empty body → the empty object, unchanged from HEAD. This is what a
`204` to `PUT /proxies/proxy` and to `PATCH /configs` produces, so `sc use` and `sc mode` keep
reporting success exactly as today.

**BC-9** — The public-address endpoint is unreachable, unresolvable, refuses, or does not answer within
the existing 8 s socket timeout → one line under the egress heading naming the error, in the user's
language; the four sections printed before it are already on screen; exit 0; no traceback.

**BC-10** — Every node accepts the connection and never answers (the state a `urltest` group provably
never demotes) → the egress section eventually prints BC-9's line. The wait is sing-box's own per-query
DNS deadline plus the system resolver's, neither of which the existing 8 s socket timeout bounds; this
task neither bounds it, shortens it nor claims a bound. QA reports the observed wall clock as a
measurement (Q-11).

**BC-11** — The service is stopped → unchanged: `sc status` prints the service section and the TUN
section and stops there, issuing no Clash API request and no egress probe.

**BC-12** — A process on this host's loopback interface answers on the Clash API port with an
arbitrarily large body → not defended. `clash_api()` gains no size cap: the peer is a loopback address
on the host itself, so an attacker in that position already runs code as this user, and a cap is
machinery bought for a threat model that is already lost.

**BC-13** — `nodes.json` or `settings.json` is absent, unreadable, not valid UTF-8, or valid JSON that
is not an object → unchanged from HEAD in every respect, traceback included. T-18 makes no claim over
that class; R-29 and Q-5 own it, and no acceptance criterion here may be read as covering it.

**BC-14** — `sc doctor` meets BC-5 (a non-object body) → its `Clash API responding` row reports the
problem state rather than `yes`, which is the same conclusion `sc status` draws from the same answer.
Its existing wording is unchanged by this task, and this is the one behaviour change T-18 causes
outside `sc status` and `sc ls`.

**BC-15** — `sc status`'s stdout is not a terminal → one complete line per fact, no carriage return, no
intermediate state (the non-TTY output contract).

**BC-16** — Two `sc` invocations at once → unchanged: `sc status` writes nothing beyond `main()`'s
existing start-up path, and no lock exists or is added.

## Acceptance criteria

Class **[B]** = behavioural: it observes what a user sees when the software runs. Class **[S]** =
structural: it pins the artifact. AC-B1 and AC-B2 are the R-22 criteria — they can be satisfied only by
running `sc status` on this host and reading its output.

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | On this host (pure TUN, service running), one run of the **candidate** `bin/sc`'s `status` prints under the egress heading exactly one line that parses as an IP address, and that address equals the one an independent HTTPS query to a *different* public address-echo endpoint reports from this host in the same minute | [B] | `sudo python3 <repo>/bin/sc status`, under NFR-3's preconditions and mtime witnesses; the independent query run separately and compared |
| AC-B2 | That same run prints exactly one value line under each of its section headings, emits no `Traceback` on stdout or stderr, and exits 0 | [B] | The same run, captured whole; both streams searched for `Traceback` |
| AC-B3 | With a stand-in server on a fixture Clash port producing each of BC-1 … BC-8, `sc status` prints the unavailable line, emits no traceback and exits 0 in **both** languages. A HEAD-clone control on the identical fixture must exhibit the defect for BC-1 … BC-5 (a traceback) and agree for BC-6 … BC-8 | [B] | Fixture per NFR-3; per-state control runs recorded verbatim in `06_TEST_REPORT.md` |
| AC-B4 | With the public-address endpoint made unreachable for the run, `sc status` prints one localized line under the egress heading, in both languages, with no traceback, and the four preceding sections are already printed | [B] | Fixture per NFR-3, endpoint made unresolvable for the child process only |
| AC-B5 | Against a stand-in returning a non-object JSON body (BC-5), `sc use <tag>` does not print a switch line as if the switch had happened; against a `204` with an empty body (BC-8) it still does | [B] | Same fixture; `cmd_use` is not edited — the criterion is satisfied by FR-1 alone |
| AC-S1 | `_egress_ip()` is byte-identical to HEAD — same endpoint literal, same `timeout=8`, no proxy argument, no second query — and its two call sites are unchanged | [S] | AST extraction + sha256, not `grep`; diff read |
| AC-S2 | The diff adds no Clash API path, no `PUT`/`PATCH`/`DELETE` anywhere, and no `try`/`except` at any caller of `clash_api()`; the whole behaviour change is inside `clash_api()` | [S] | Diff read; repository-wide search for the four HTTP methods and for new handlers at the six call sites |
| AC-S3 | Every user-facing string added or changed has a `zh` entry with an identical placeholder set, no new `zh` string contains `失败：`, and no new key is namespaced | [S] | Extract `TRANSLATIONS`, compare placeholder sets; if the count is zero (Q-9), state that |
| AC-S4 | `docs/dev-map.md`'s `# Clash API` row states FR-1's contract ("a JSON object or `None`, never an exception"), and `CHANGELOG.md` gains a Chinese entry | [S] | Read both files |
| AC-S5 | `python3 -m py_compile bin/sc` passes, the diff uses no syntax newer than Python 3.6 and no non-stdlib import, the permitted diff of NFR-2 is respected, and `bash .harness/scripts/verify_all.sh` ends with no FAIL against the 17/0/0/1 baseline | [S] | Compile; diff read; run it |

## Non-functional requirements

- **NFR-1 — Python 3.6 syntax floor, standard library only** (`.harness/rules/50-singbox-cli.md`). No
  new import is expected; one added to name an exception class must be stdlib and must be justified in
  `02_SOLUTION_DESIGN.md` against the smaller alternative.
- **NFR-2 — Permitted diff:** `bin/sc`, `docs/dev-map.md`, `CHANGELOG.md`, plus this task's stage
  documents. `README.md` / `README.zh-CN.md` only if the user-visible surface changes, and they stay
  line-for-line mirrors. `.harness/**` and `docs/batches/**` are outside it.
- **NFR-3 — Verification never touches the live system.** Every fixture neutralises the import-time
  auto-elevate by `docs/dev-map.md`'s recipe, repoints all eight path constants into a `mkdtemp()` root
  and asserts each resolves there, never drives `_init_files()`, sets `SYSTEMD = OPENRC = False`, never
  invokes `/usr/local/bin/sc`, never writes under `/etc` or `/var/lib`, and issues no `PUT`/`PATCH`/
  `DELETE` to the live Clash API. The service witness is
  `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`, never `is-active`.
  **AC-B1/AC-B2 are the one permitted live-host invocation** and are bounded by five preconditions,
  each checked before the run and reported: `nodes.json`, `settings.json` and `/var/lib/sing-box` all
  already exist; `settings.json` already records `clash_api_port`; the invocation is
  `sudo python3 <repo>/bin/sc status` so `geteuid()` is 0 and the re-exec branch is never taken; the
  only Clash call it makes is one `GET /configs`; and an mtime + size witness over `/etc/sing-box/**`
  and `/var/lib/sing-box` taken before and after proves the run wrote nothing.
- **NFR-4 — Bilingual parity is a correctness requirement**, not a nicety: `TRANSLATIONS` has no `en`
  table, so a key is its own English text and a missing `zh` entry prints English mid-sentence.
- **NFR-5 — A behavioural criterion without a control is not evidence.** AC-B3 declares its
  defect-reproducing states (BC-1 … BC-5) and its agreement states (BC-6 … BC-8); a green run whose
  control does neither is reported as inconclusive, never as a pass. No behavioural criterion may be
  replaced by an artifact check — where an observation must shrink, it shrinks to a smaller *observed*
  behaviour. This is R-22 applied.
- **NFR-6 — One complete line per fact** on every output, stdout for results and stderr for warnings,
  per the project's stream split and the non-TTY output contract.
- **NFR-7 — QA's `06_TEST_REPORT.md` must carry the heading `## Adversarial tests`, unnumbered**:
  `verify_all` E.6 matches `^##\s+Adversarial\s+tests`, so `## 3. Adversarial tests` turns a SKIP into
  a FAIL.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does the batch goal's first clause — "the egress probe cannot work in pure-TUN mode because it assumes a local inbound that does not exist" — describe a defect at HEAD? | **No. It is a phantom, and T-18 deletes it rather than implements it.** `_egress_ip()` is one `urllib.request.urlopen("https://api.ipify.org", timeout=8)` with no proxy argument, no `ProxyHandler`, and no `127.0.0.1` anywhere in it or in either of its two call sites; nothing in `bin/sc` points the probe at a local inbound. In pure TUN the request is captured by the TUN device like every other outbound connection, so the probe reports the *proxied* egress address — which is the fact the section exists to show. The one route by which a local inbound could still be assumed is `urllib`'s environment-derived proxy handling (`http_proxy` / `https_proxy` / `ALL_PROXY`), which is a property of the host's environment and not of this code; it needs no code change either way, because BC-9 already requires one clear line for *any* failure of the probe whatever its cause. AC-S1 freezes `_egress_ip()` byte-identical so no downstream stage "fixes" the phantom. |
| Q-2 | Then what is the defect T-18 fixes? | **The goal's second clause, at the seam it actually lives on.** `cmd_status` calls `clash_api("GET", "/configs")` unguarded two lines above the egress block, and `clash_api()`'s `except (URLError, HTTPError)` does not cover what its own body raises — T-15's QA reproduced four escaping classes (`TimeoutError`, `JSONDecodeError`, `UnicodeDecodeError`, `IncompleteRead`), and reading the callers adds a fifth that no one had filed: a 2xx body decoding to non-object JSON returns that value, which `sc status` then calls `.get()` on. The egress block is *already* wrapped in `except Exception`, so the traceback the goal reports never came from it. |
| Q-3 | Does one fix at `clash_api()` discharge both `sc ls` and `sc status`, or does `sc status` need a second `try`/`except` beside the first? | **One fix at `clash_api()`, and no second handler anywhere.** R-20 says the coherent fix is one exception envelope around `clash_api()`, and it is right: all six call sites take the same class of failure from the same function, and five of them (`stored_delays`, `cmd_status`, `cmd_use`, `_doctor_clash`, `cmd_mode`) already handle the no-answer value. Making `clash_api()` total — object or `None`, never an exception, never another type — closes `sc ls`, `sc status`, `sc use`, `sc mode` and `sc doctor` in one change of a few lines, makes its own docstring and `docs/dev-map.md`'s row true, and adds no concept a future reader must hold. A local handler at `cmd_status` would fix one of six symptoms, leave `sc ls` broken on the host whose whole point is being broken, and be exactly the 修修补补 rule 85 forbids. **T-18 claims R-20 and closes it**; AC-S2 forbids the alternative shape. |
| Q-4 | Can sing-box's Clash API report an egress address, and should the egress fact move there? | **No, on three independent grounds, only the first of which is a measurement.** (a) No endpoint of this binary's Clash API is known to report one: T-02's E-7 and T-10's strings analysis both record the API as switching proxy and mode only, `/providers/rules` being a compatibility stub, and `GET /proxies` serving a *stored* url-test history. This ground is not first-hand-measured here, and the ruling deliberately does not rest on it alone. (b) Even if such an endpoint existed, consuming it would create a **second opinion** about this host's public address — `docs/dev-map.md` pins `_egress_ip()` as the single query precisely so `sc status` and `sc doctor` can never disagree, and rule 85 forbids a second judgment of the same fact. (c) The only Clash endpoint that would touch the outside world, `/proxies/:name/delay`, makes the *running* sing-box originate a request and returns a latency integer, not an address — an active probe against the live service, which this project's Clash use never performs. The slug's name is the task's identifier, not a design instruction. |
| Q-5 | R-29 (`load_settings()` letting `UnicodeDecodeError` and a non-object body through) is reachable from `sc status`. Is it in scope? | **No, and the promise is narrowed to match rather than left vague.** FR-3's no-traceback guarantee is scoped to the two *remote dependencies* `sc status` consults; BC-13 states plainly that a corrupt local state file behaves exactly as at HEAD and that nothing here covers it. The reasons: R-29 is a different seam (state-file I/O, whose named owner is the next task opening it), a different input class (a file this host owns, not a peer's answer), and its fix belongs with `load_nodes()` and `_load_lang()` as one family — taking one member here would either be a third guard tuple (the thing R-29 exists to prevent) or a second unrelated design inside a task whose whole value is being one small coherent change. **New for the PM to file:** `load_nodes()` — `json.loads(NODES_PATH.read_text())`, called unguarded by `cmd_status` — carries R-29's two failure classes and a third (an absent file, which the start-up path normally prevents); R-29's family statement should be widened to name it, so the next owner fixes three readers and not two. |
| Q-6 | Does this requirement touch R-12 (a helper that `sys.exit`s inside a function owing a run-level outcome)? | **No.** `clash_api()` contains no `sys.exit` and gains none; `cmd_status` contains none; FR-1 replaces a raised exception with a returned value, which moves the run *toward* R-12's invariant rather than into its territory. R-12 stays open and unclaimed. |
| Q-7 | `sc status` and `sc doctor` already share `_egress_ip()`. Does anything remain to unify? | **No, and this task must not invent one.** T-05 extracted the query, `docs/dev-map.md` pins it, and rule 85's "no second opinion" test is already satisfied there. The one remaining difference is *rendering* — `sc doctor` scrubs foreign text through `_plain()` and `sc status` prints it verbatim — which `docs/dev-map.md` records as a deliberate division (the query is byte-faithful, scrubbing belongs at the caller). It is not a second opinion about the address, no defect has been observed from it, and changing an untouched line to satisfy a symmetry nobody reported is scope this task does not carry. Out of scope item 5; a candidate row, not a requirement. |
| Q-8 | Is the "no traceback" promise a promise about the whole command? | **No — it is scoped to the Clash API call and the egress probe, and nothing else, in exactly those words.** T-15's DEF-2 is the precedent: a promise materially wider than the behaviour passes every gate and fails the user. FR-3 names its two paths, BC-13 names what stays broken, and no acceptance criterion asserts a general property of `sc status`. |
| Q-9 | What is the exact bilingual text of every new user-facing string? | **There is none: the required budget is zero.** Every state FR-3 and BC-1 … BC-9 name is already covered by two existing bilingual keys — `"(unavailable)"` → `"（不可用）"` for a Clash API fact that could not be obtained, and `"(error: {e})"` → `"（错误：{e}）"` for a failed egress probe. Reusing them is the smaller design and keeps the change to one function. If stage 2 nonetheless proposes a string, it must state what the existing pair cannot express, and it inherits FR-5 and AC-S3 unchanged. |
| Q-10 | Does `sc status` gain a findings-derived exit status, the way `sc doctor` has one? | **No.** `sc doctor` is the command that classifies (`doctor-exit-status-always-zero` in `.harness/rejected-decisions.md` decided that deliberately, and T-20 owns its extensions); `sc status` is a screenful of facts and keeps exiting 0. Adding a second command that grades the host is a second opinion and unrequested scope. |
| Q-11 | BC-10 says the egress probe's wait is not bounded by its own 8 s timeout. Should T-18 bound it? | **No. T-18 states the limit and measures it; it does not cover it.** The 8 s argument is a socket timeout and does not bound name resolution, and T-16 measured that sing-box has no DNS-query-level timeout at any level and drops a proxied query silently at its own fixed 10.0 s deadline — so on the host class this batch is about, the wait is the resolver's and sing-box's, not `sc`'s. Bounding it needs a design (a bounded resolve, a worker, a cancellation path) that no measurement yet justifies, inside a task whose value is being small. QA reports the observed wall clock of AC-B1's run and of BC-10's fixture as measurements; if it is materially longer than 8 s, the PM files it as an open row with the number attached, which is how the next owner gets a fact instead of a suspicion. |
| Q-12 | Does the document schema hold everything, and what governs the split? | **Yes.** `.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section in this project, so per the analyst contract the declared schema is applied as written and the task proceeds. Evidence with path-and-line citations, the related-task survey and the candidate answers each ruling beat are in `01_RATIONALE.md`; no unit needed a section this schema does not declare. |
| Q-13 | Do the safety rules permit running `sc status` on this live host, as R-22 requires? | **Yes, under NFR-3's five preconditions, and it is mandatory — AC-B1/AC-B2 may not be replaced by an artifact check.** The run invokes the *candidate* file as `sudo python3 <repo>/bin/sc status`, so `geteuid()` is 0 and the import-time re-exec of `/usr/local/bin/sc` never happens; `cmd_status` performs no write, no service action and exactly one `GET /configs`; `_init_files()` creates only what is missing and nothing is missing on this host, and `_resolve_clash_port()` writes only when no port is recorded and one is. The mtime + size witness is what turns those four statements into evidence rather than confidence. This is red-line-adjacent by construction — it is the one place the pipeline runs product code against the live host — and it ships on the owner's standing grant with the witnesses recorded. |

## Verdict

READY
