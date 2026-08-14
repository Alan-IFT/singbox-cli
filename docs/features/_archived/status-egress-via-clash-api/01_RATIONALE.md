# 01 — Rationale · T-18 `status-egress-via-clash-api`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. Evidence at HEAD (backward-looking citations — path and line are proof, not instructions)

Read first-hand at HEAD (`1e454b6`), against the four PM pointers.

- **E-1 — the egress probe has no proxy in it.** `bin/sc:391-400`: `_egress_ip()` is a docstring plus
  `with urllib.request.urlopen("https://api.ipify.org", timeout=8) as resp: return resp.read().decode()`.
  No `ProxyHandler`, no `build_opener`, no `127.0.0.1`, no port. Its two call sites are `bin/sc:2237`
  (`cmd_status`, inside `try: … except Exception as e: print(t("(error: {e})", e=e))`) and `bin/sc:2520`
  (`_doctor_egress()`, inside its own `try`/`except Exception`). The docstring at `:392-397` already
  states the design the PM pointer describes ("THE one endpoint sc queries … so `sc status` and
  `sc doctor` can never report different egress addresses"). **PM pointer 1 confirmed; the batch goal's
  first clause is refuted.**
- **E-2 — the traceback is real and lives at `bin/sc:2230`.** `r = clash_api("GET", "/configs")` is the
  only unguarded remote call in `cmd_status`, two lines above the egress block. **PM pointer 2 confirmed.**
- **E-3 — `clash_api()`'s catch tuple versus its body.** `bin/sc:1978-1992`: the body does
  `urlopen(req, timeout=3)` → `r.read()` → `.decode()` → `json.loads(text) if text else {}`, and catches
  `(urllib.error.URLError, urllib.error.HTTPError)`. `HTTPError` is a subclass of `URLError`, so the
  tuple is one class. A read timeout raises `socket.timeout`/`TimeoutError`, which is an `OSError` but
  not a `URLError`; `.decode()` raises `UnicodeDecodeError` and `json.loads` raises `JSONDecodeError`,
  both `ValueError`; a short body raises `http.client.IncompleteRead`, an `HTTPException`. None is
  caught. These four are not inferred here — T-15's QA **reproduced** them
  (`docs/features/_archived/proxy-urltest-group/06_TEST_REPORT.md`, DEF-1; enumerated in
  `.harness/insight-index.md:15` and in `docs/tasks.md` R-20).
- **E-4 — a fifth escaping class nobody had filed: a non-object 2xx body.** `clash_api()` returns
  whatever `json.loads` produced. `cmd_status` (`bin/sc:2232`) then evaluates
  `(r or {}).get("mode", …)`: for `r = [1, 2]` or `r = 5` the `or` keeps the truthy non-dict and `.get`
  raises `AttributeError`. The same body reaches `cmd_use` (`bin/sc:2148-2151`), whose success test is
  `if r is not None:` — so a Clash port answering `5` makes `sc use` print `Switched to: <tag>` for a
  switch that did not happen. `stored_delays()` (`bin/sc:2029-2033`) is immune because every shape check
  there is an `isinstance` test. This is why FR-1 is stated as *object or `None`* rather than as *does
  not raise*: the exception envelope alone would leave the silent-wrong-result half of the same defect.
- **E-5 — the other five call sites already handle the no-answer value.** `bin/sc:2026` (`isinstance`
  guard), `:2148` (`is not None`), `:2230` (`(r or {})`), `:2503` (`is not None`, with a comment
  explaining why an empty `{}` must not read as failure), `:2580` (return ignored). Nothing needs a new
  handler, which is what makes the one-line envelope sufficient.
- **E-6 — the empty-body path is load-bearing.** `json.loads(text) if text else {}` (`bin/sc:1990`) is
  what turns sing-box's `204` on `PUT /proxies/proxy` and `PATCH /configs` into a success for
  `cmd_use` and `cmd_mode`. BC-8 exists so a "return a dict or None" fix cannot quietly delete it.
- **E-7 — `sc doctor` is a caller too, and one of its rows changes.** `_doctor_clash()`
  (`bin/sc:2503-2509`) reports `yes` for any non-`None` answer, so today a non-object body reads as a
  healthy API; after FR-1 it reports the problem row. BC-14 states that consequence out loud rather
  than letting stage 5 discover it.
- **E-8 — the Clash API's known surface.** `.harness/rejected-decisions.md`
  § `trust-singbox-fswatch-ruleset-reload` records, from a strings analysis of the installed binary,
  that "`/providers/rules` exists as a route but the binary carries none of the Clash rule-provider
  payload fields … confirming T-02's E-7 that the API switches proxy and mode only", and
  `.harness/insight-index.md` records `GET /proxies` as a *stored* url-test history. Not a first-hand
  measurement in this task — which is exactly why Q-4 is decided on grounds (b) and (c), each of which
  holds whatever a fresh probe would find.
- **E-9 — the live-run safety chain.** `bin/sc:116-117` re-execs `/usr/local/bin/sc` under `sudo` only
  when `os.geteuid() != 0`; `_init_files()` (`bin/sc:462-473`) creates directories with
  `exist_ok=True` and seeds the two state files only `if not …exists()`; `_resolve_clash_port()`
  (`bin/sc:364-388`) returns the saved port before any write when one is recorded. Together these are
  why AC-B1's live invocation can be read-only — and why NFR-3 demands the mtime witness instead of
  trusting the reading.
- **E-10 — the strings already exist.** `bin/sc:143-144` carry `"(unavailable)"` → `"（不可用）"` and
  `"(error: {e})"` → `"（错误：{e}）"`, both already used by `cmd_status` at `:2232` and `:2239`. Hence
  Q-9's zero-string budget.
- **E-11 — a documented user-reachable instance.** `README.md:396` already warns that removing
  `experimental.clash_api.external_controller` from the config yields a file `sing-box check` accepts
  while "`sc use` and `sc status` stop working". After FR-1 that host gets one `(unavailable)` line
  instead of a traceback, on a path the project already tells users they can reach.

## 2. Related tasks (linked, not re-described)

- **T-05 `sc-doctor`** — extracted `_egress_ip()` and `_saved_clash_port()`; the "no second opinion"
  constraint Q-4 and Q-7 rest on is its. `docs/features/_archived/sc-doctor/02_SOLUTION_DESIGN.md` §3.5
  and `.harness/rejected-decisions.md` § `shared-atomic-write-helper-with-ruleset-downloader` /
  § `doctor-exit-status-always-zero` (the last of which Q-10 applies).
- **T-15 `proxy-urltest-group`** — measured R-20's four exception classes and filed R-20/R-22:
  `docs/features/_archived/proxy-urltest-group/05_CODE_REVIEW.md` and `06_TEST_REPORT.md`;
  `docs/tasks.md` § "Open rows surfaced by T-15".
- **T-16 `dns-resilience`** — the precedent this task's first hour was spent on
  (`docs/features/_archived/dns-resilience/01_REQUIREMENT_ANALYSIS.md`, Q-2/Q-14): two of three goal
  clauses were not expressible against the real binary, and the requirement said so instead of
  building. Q-1 here is the same move at a smaller scale. Its Q-2 measurement is also what makes
  BC-10 and Q-11 statable at all.
- **T-17 `telemetry-reject-list`** — the model for declining an adjacent row three times with a fresh
  reason each time, and for the `[D]`/`[A]` control discipline NFR-5 restates.
- **T-14 `config-composition-layer`** — R-15's "one exception envelope over the pipeline" is the
  sibling shape of FR-1; the two are deliberately separate seams (override documents versus a peer's
  HTTP answer).
- **T-20 `doctor-extended-checks`** — owns every future `sc doctor` row, which is why out-of-scope
  item 5 exists.

## 3. Candidates each ruling beat

- **Q-1 (the phantom).** Candidate A: implement the goal literally — give `_egress_ip()` a proxy handler
  pointing at a local inbound. Rejected: there is no local inbound in this project's emitted document
  (pure TUN), so the change would break a probe that works, and it contradicts the endpoint's byte-faithful
  single-query design. Candidate B: keep the clause but reinterpret it as "the probe cannot *distinguish*
  proxied from direct". Rejected as a different feature (a second, non-proxied query) — that is precisely
  the second opinion `docs/dev-map.md` forbids, and nobody asked for it. Candidate C, chosen: state the
  refutation, freeze the function, and spend the task on the defect that is real.
- **Q-3 (where the fix goes).** Candidate A: `try`/`except` around `bin/sc:2230` in `cmd_status`. Smaller
  by one line at the call site, larger everywhere else — five other call sites keep the exposure, `sc ls`
  (the command whose point is a broken host) stays broken, and the next caller inherits the trap. Candidate
  B: a shape-checking wrapper `clash_get()` beside `clash_api()`. Rejected by the deletion test: delete it
  and no complexity reappears, and it makes two functions that both mean "ask the Clash API". Candidate C,
  chosen: make `clash_api()` total. It is the smallest diff that closes six call sites, and it makes an
  already-published contract (its docstring, `docs/dev-map.md`'s row) true rather than adding a new one.
- **Q-5 (R-29).** Candidate A: fix `load_settings()` and `load_nodes()` here too — "one line each" and
  `sc status` reaches both. Rejected: it is a second design at a second seam bought with the argument that
  the fix is short, which is how a small task becomes an unfocused one; R-29's own statement is that the
  family must be fixed **together** (three readers, one guard), and doing two of three here would leave the
  third and burn the row. The honest alternative was chosen instead: narrow the promise (Q-8) and state the
  gap (BC-13), plus hand the PM the new `load_nodes()` observation so R-29 grows rather than fragments.
- **Q-9 (strings).** Candidate: a dedicated message such as "the Clash API did not answer — is sing-box
  running?". Rejected under 「以少就是多」: it adds two translation entries, a bilingual-parity obligation
  and a diagnosis `sc doctor` already owns as a classified row, to say what `(不可用)` on a line whose
  heading is `=== 路由模式 ===` already says in context.
- **Q-11 (the wait).** Candidate: bound the egress probe with a resolve-then-connect split or a worker
  thread. Rejected as designing against an unmeasured number — T-16's precedent — inside a task whose
  value is its size. Reversed shape adopted: QA produces the number, the PM files the row, the next owner
  starts from a fact.
- **AC set size.** T-15 shipped 35 criteria, all green, none observing the goal (R-22). Ten were written
  here, five of them behavioural, and the two that run on this host are declared unreplaceable (NFR-5).
  The temptation resisted was a criterion per boundary condition: BC-1 … BC-8 are one fixture and one
  loop, so they are one criterion (AC-B3) with eight declared states and eight controls, not eight rows
  that would each pass while the command still failed the user.

## 4. What this task deliberately leaves smaller than the batch plan implied

The row's title says "via clash api" and its goal sentence names two defects. One of the two does not
exist (Q-1); the mechanism in the title is declined on three grounds (Q-4); and the one real defect is
already filed as R-20 with the fix shape named. The honest T-18 is therefore **one function made total,
plus the criteria that prove it on this host** — a smaller task than the row promised, and a strictly
more truthful one. If a later stage finds itself designing something large here, that is the signal that
it has re-adopted the phantom.
