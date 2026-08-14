> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

## Files reviewed
- `/home/alan/Programs/singbox-cli/bin/sc`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`
- `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/01_REQUIREMENT_ANALYSIS.md`
- `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/02_SOLUTION_DESIGN.md`
- `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/03_GATE_REVIEW.md`
- `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/04_DEVELOPMENT.md`
- `/home/alan/Programs/singbox-cli/README.md` (E8's premise, read-only)
- `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md`, `.harness/rules/70-doc-size.md`
- `/usr/lib/python3.12/urllib/request.py`, `/usr/lib/python3.12/http/client.py` (stdlib witnesses, read-only)

No test file exists in this repository (`.harness/rules/50-singbox-cli.md` § Build/test: no suite, B.3
still SKIP), so dimension "tests are code too" is discharged against QA's fixture plan at stage 6
rather than against committed tests.

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MINOR | Standards-conformance | `CHANGELOG.md:21` | The `sc doctor` clause states the *before*-state over all five classes — "不再整节塌成一行「未知」…这一节由「未知」变成「异常」…退出码由 2 变成 1" — but for the non-object-body class HEAD printed `[OK] Clash API responding: 是` (`bin/sc:2512` at HEAD+6), so that class's move is 「正常」→「异常」 and 0 → 1, not 未知 → 异常 and 2 → 1. The same bullet discloses that class's before-state correctly two sentences earlier ("过去甚至不报错，而是被当成正常回答继续使用"), so the paragraph is reconcilable rather than false; the doctor sentence over-generalises. C-2's conditional-exit requirement is honoured. One-clause repair in `05_RATIONALE.md` § Finding 5. |
| CR-2 | MINOR | Spec/design-fidelity | `bin/sc:2514-2515` (key `:291`) | The frozen `_doctor_clash()` PROBLEM message `"no answer within the 3s timeout"` / 「3 秒超时内无响应」 now renders for BC-2, BC-3, BC-4, BC-5 and BC-7 — states in which an answer *did* arrive well within the timeout. The widening makes a pre-existing imprecision (HEAD already used it for a 4xx and for a refused connection) cover four more states. `sc doctor`'s wording is frozen by out-of-scope item 5 and BC-14, so **no edit is asked for here**; it travels as RES-1. |
| CR-3 | INFO | Spec/design-fidelity | `04_DEVELOPMENT.md` § Open issues; `/usr/lib/python3.12/urllib/request.py:1342-1351` | **Confirmed** against the installed stdlib: `do_open` wraps only `h.request(...)`'s `OSError` into `URLError` and bare-re-raises `h.getresponse()`'s. BC-6's "unchanged from HEAD" is false. Refinement: there are **two** reset variants with different mechanisms — (a) reset during status line/headers raises `RemoteDisconnected` (`http/client.py:1571`, a `ConnectionResetError` **and** a `BadStatusLine`) out of `getresponse()`, which is what the citation explains; (b) reset during body read raises `ConnectionResetError` from `r.read()` inside `clash_api()`'s own `try`, where `do_open` is not on the stack at all — which is what `04`'s prose describes. Both escape HEAD's tuple, both are covered by the candidate. QA declares **both** defect states. |
| CR-4 | INFO | Spec/design-fidelity | `/usr/lib/python3.12/http/client.py:1533`; `bin/sc:1996` | `class IncompleteRead(HTTPException)` is `HTTPException` only — not also a `ValueError`. BC-4 is therefore caught by the third family alone, so `http.client.HTTPException` is load-bearing and not redundant with `ValueError`. Recorded because it is the simplification a future reader is most likely to attempt. |
| CR-5 | INFO | Standards-conformance | `bin/sc:1993` | `timeout=3` is a per-socket-operation timeout, not a total wall-clock bound: a peer that drips bytes slower than the read loop keeps `r.read()` alive indefinitely. Unchanged from HEAD and inside BC-12's declined threat model, so no code consequence — but QA's BC-1 measurement should record the observed wall clock rather than assume 3 s (this is R3's family). |
| CR-6 | INFO | Standards-conformance | `bin/sc:1979-1980` | The docstring's first sentence elides its verb — "Returns a JSON object or None, never one of the three exception families its own body raises" reads on first pass as "never *returns* an exception family". "never *raises* one of the three families…" is one word and stays inside K-9's 8 lines. Note E1+E2 sit at exactly K-9's 12-added-line ceiling, so any repair must be in place, never an added line. |
| CR-7 | INFO | Spec/design-fidelity | `CHANGELOG.md:11` | The already-written `sc ls` bullet in the same `[Unreleased]` block promises "API 不通或返回内容异常时表格照常打印、不会抛 Python 报错". That promise was **false at HEAD** for the invalid-JSON / invalid-UTF-8 / short-body states and becomes true only through this change — independent evidence for Q-2/Q-3 and R-20, and a claim `07_DELIVERY.md` may record as retired. Both bullets ship in the same unreleased block, so the release is self-consistent; no edit needed. |

## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| FR-1 — `clash_api()` yields a JSON object or `None`, nothing else, never raises | `bin/sc:1992-1998`; every path walked (`05_RATIONALE.md` § Finding 2) | ✅ |
| FR-2 — all eight failure classes become the one no-answer value; no caller adds handling | `:1996` three-family tuple + `:1998` isinstance gate; `bin/sc` still carries 45 `try:` / 46 `except` line-starts, one clause rewritten, none added | ✅ |
| FR-3 — `sc status` one value line per fact, no traceback from the two remote seams, exit 0 | `:2234-2245`; Clash seam now total, egress seam already wrapped at `:2242-2245`; no `sys.exit` in `cmd_status` | ✅ (code); observation is AC-B1/B2's |
| FR-4 — egress fact stays the one existing query, unchanged | `_egress_ip()` `:391-400` at HEAD's own line numbers, `https://api.ipify.org`, `timeout=8`, no proxy argument; call sites `:2243`, `:2526` | ✅ |
| FR-5 — bilingual parity; no new zh string carries `失败：`; no `ls.*` namespacing | zero strings added or changed; the file's only `失败：` is pre-existing at `:204` | ✅ (vacuous, as Q-9 ruled) |
| BC-1 / BC-6 / BC-7 (silent port, refused/reset, 4xx-5xx) | `TimeoutError`, `ConnectionResetError`, `RemoteDisconnected`, `URLError`, `HTTPError` all ⊂ `OSError`; `RemoteDisconnected` also ⊂ `HTTPException` | ✅ (see CR-3 on the control class) |
| BC-2 / BC-3 (bad JSON, bad UTF-8) | `JSONDecodeError`, `UnicodeDecodeError` ⊂ `ValueError` | ✅ |
| BC-4 (short body) | `IncompleteRead` ⊂ `http.client.HTTPException` only — see CR-4 | ✅ |
| BC-5 (valid JSON, not an object) | `:1998` `isinstance(answer, dict)`; `null` → `None` → `None` | ✅ |
| BC-8 (empty 2xx body → `{}`) | `:1995` `json.loads(text) if text else {}` evaluated **before** the gate; `{}` is a `dict`, so it survives; `cmd_use` `:2155` `r is not None` still reports the switch | ✅ |
| BC-9 / BC-10 (egress unreachable / all nodes hang) | `:2242-2245` unchanged `except Exception` → `(error: {e})`; no bound added, none claimed | ✅ |
| BC-13 (corrupt `nodes.json`) | `cmd_status:2233` `load_nodes()` still unguarded — unchanged from HEAD, as required | ✅ (correctly *not* fixed) |
| BC-14 as widened by C-1 (`sc doctor` on BC-1…BC-5) | `_doctor_clash():2509-2515` returns the port row plus `[PROBLEM] Clash API responding` instead of the section collapsing; `README.md:265,268,277-278` remain true and become more true (E8's premise verified) | ✅ (see CR-2 on the message text) |
| AC-B1, AC-B2 — live-host run, one line per fact, no traceback, exit 0 | code preconditions met; the run itself is V7's | ⏳ stage 6 (RES-3) |
| AC-B3 — BC-1…BC-8 fixture in both languages, with per-state control | code path verified for all eight; control classes must follow C-5 and CR-3 | ⏳ stage 6 |
| AC-B4 — egress endpoint unresolvable | `:2242-2245` unedited | ⏳ stage 6 (V8) |
| AC-B5 — `sc use` on BC-5 vs BC-8 | `cmd_use:2151-2159` unedited: BC-5 → `None` → `reload_or_restart()` path; BC-8 → `{}` → `Switched to:` | ✅ (code); observation is V5's |
| AC-S1 — `_egress_ip()` byte-identical, two call sites unchanged | `:391-400` at 0-shift, content matching the design's first-hand HEAD read; call sites at HEAD+6 with handlers intact | ✅ by line-shift argument; digest re-check is V1's (RES-3) |
| AC-S2 (as corrected by C-4) — no new route, no `PUT`/`PATCH`/`DELETE`, no handler at any of the five call sites | exactly five call sites (`:2032`, `:2154`, `:2236`, `:2509`, `:2586`), one `"PUT"`, one `"PATCH"`, **no** `"DELETE"` literal in the file; `sc ls`'s indirect reach `:2107` untouched | ✅ |
| AC-S3 — zero added/changed `TRANSLATIONS` entries | keys at `:143-146`, `:160`, `:263`, `:291` all at HEAD line numbers with HEAD content | ✅ zero, stated explicitly |
| AC-S4 — dev-map row states the contract; CHANGELOG gains a Chinese entry | `docs/dev-map.md:39`; `CHANGELOG.md:21` | ✅ (see CR-1) |
| AC-S5 — `py_compile`, 3.6 floor, stdlib only, permitted diff, `verify_all` no FAIL | 3.6 floor and stdlib verified by inspection (f-string only, no walrus, no 3.7+ construct; `http.client` is stdlib since 3.0); permitted-diff set verified against NFR-2 | ⏳ compile / `verify_all` re-run is stage 6's (RES-3) |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| K-1 — exactly `(OSError, ValueError, http.client.HTTPException)`; no bare `except`, no `except Exception`, no leaf enumeration, no fourth family | `bin/sc:1996` — the tuple verbatim; the file's six `except Exception` clauses (`:649`, `:2167`, `:2244`, `:2527`, `:2563`, `:2774`) are all pre-existing and outside `clash_api()`; no bare `except` anywhere | ✅ |
| K-2 — `urllib.error` deleted, `http.client` added, no net import | whole-file grep: **zero** occurrences of `urllib.error` (R5 discharged as a whole-file property, not a hunk property); `import http.client` at `:7`, alphabetically between `hashlib` `:6` and `json` `:8`; 15 `import` statements + one `from`, unchanged | ✅ |
| K-3 — `json.loads(text) if text else {}` first, `isinstance` gate after, never truthiness | `:1995` then `:1998`; the predicate is `isinstance(answer, dict)`, not `type(...) is dict`, not a truthiness test | ✅ |
| K-4 — no `try`/`except` added outside `clash_api()`; none of the five call sites edited | 91 `try:`/`except` line-starts total, matching HEAD's 45+46; all five call sites at HEAD+6 with the content I3 describes | ✅ |
| K-5 — `_egress_ip()` and its two call sites byte-identical | see AC-S1 | ✅ |
| K-6 — `TRANSLATIONS` byte-identical | see AC-S3 | ✅ |
| K-7 + C-8 — dev-map row states the three families **and** the residue, never an unqualified "never an exception" | `docs/dev-map.md:39`: "**total over the three exception families its own body raises**  (`OSError`, `ValueError`, `http.client.HTTPException`)" + "a pathological body … can still raise `RecursionError` / `MemoryError`" + the `{}`/`204` case + "callers therefore add no `try`/`except`" | ✅ |
| K-8 + C-2 + C-6 — one Chinese bullet naming five commands incl. `sc mode`, `sc use`'s restart behaviour, the conditional exit move, no file path, no identifier | `CHANGELOG.md:21`; every quoted zh fragment matches the actual translation (`:146`, `:160`) byte for byte | ✅ with CR-1 |
| K-9 + C-8 — docstring ≤8 lines stating the contract, keeping `port=None`, naming *why* families; E1+E2 ≤12 added lines | `bin/sc:1979-1986` = exactly 8 lines, all three elements present; net function growth +6 and one import swapped is consistent with the reported 12 added / 6 deleted, i.e. exactly at the ceiling | ✅ |
| I1 — signature, URL, method, headers, `timeout=3`, one-request property untouched | `:1978`, `:1987-1993` | ✅ |
| I2 — request envelope identical to HEAD | `GET /configs` ×2, `GET /proxies`, `PUT /proxies/proxy`, `PATCH /configs`; no `DELETE` | ✅ |
| I3 — all five call sites already correct against I1 | `:2035` isinstance, `:2155` `is not None`, `:2238` `(r or {})`, `:2511` `is not None`, `:2586` discarded | ✅ |
| E8 — `README.md` / `README.zh-CN.md` correctly *not* edited | `README.md:268` (`[UNKNOWN]` never means "the thing is broken") and `:277-278` (exit-code table) stay true and become more true; no user-visible surface they document changes | ✅ |
| Design drift — the refuted phantom (egress probe / local inbound) | no proxy argument, no `ProxyHandler`, no second address query, no Clash endpoint added anywhere in the diff region | ✅ none |
| K-10 / K-11 / K-12 (vacuity traps, language, HEAD clone) + C-9 | QA-owned; nothing in this diff affects them | n/a stage 6 |
| `04_DEVELOPMENT.md` § Design drift: "None" | independently confirmed | ✅ |

## Axis status
- **Standards-conformance: 3 findings, worst = MINOR** (CR-1 changelog before-state precision; CR-5 timeout-bound wording, INFO; CR-6 docstring verb elision, INFO). Repo conventions hold: Python 3.6 floor, stdlib only, alphabetical imports, bilingual parity (zero new strings), no invented rule applied — `.harness/rules/70-doc-size.md` carries no `## Stage-doc boundary rule` section, so this document applies its declared schema as written and does not block on the absence.
- **Spec/design-fidelity: 4 findings, worst = MINOR** (CR-2 a frozen `sc doctor` message that now names a cause it does not have, out of scope to fix here; CR-3, CR-4, CR-7 all INFO/confirmations). Every constraint K-1…K-9, every interface I1…I3, every gate condition owned by stage 4 (C-2, C-4, C-6, C-8) is discharged, and no design drift exists in either direction.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | `_doctor_clash()`'s PROBLEM message "no answer within the 3s timeout" / 「3 秒超时内无响应」 (`bin/sc:2514-2515`, key `:291`) now renders for BC-2, BC-3, BC-4, BC-5 and BC-7, where an answer did arrive within the timeout. Frozen by out-of-scope item 5, so it is a follow-up row for `sc doctor`'s owner (T-20), not an edit here. | `07_DELIVERY.md`, then PM (`docs/tasks.md` row against T-20) |
| RES-2 | BC-6's reset states are **defect** states, not agreement states, and split into two variants with different mechanisms (CR-3). A fixture that declares either an agreement state makes the run inconclusive under NFR-5. | `06_TEST_REPORT.md` (V4/V6 control table, with C-5) |
| RES-3 | This stage could not execute `git diff`, `python3 -m py_compile bin/sc` or `bash .harness/scripts/verify_all.sh` (no shell in this reviewer's grant). AC-S1's digest, AC-S2's diff read and AC-S5's compile + `verify_all` were verified by content and line-shift argument only (method and limits in `05_RATIONALE.md` § Method); V1, V2, V9 and V10 must execute them for real against a HEAD clone. | `06_TEST_REPORT.md` |
| RES-4 | `timeout=3` bounds each socket operation, not the call's total wall clock (CR-5), so BC-1's "3 s" is a measurement, not a guarantee — the same family as R3. | `06_TEST_REPORT.md`, then PM |
| RES-5 | `CHANGELOG.md:11`'s pre-existing `sc ls` promise was false at HEAD and is made true by this task (CR-7); `07_DELIVERY.md` may record it, alongside C-3's T-05 DEF-2 closure. | `07_DELIVERY.md` |

## Verdict
APPROVED WITH MINOR (0 MAJOR, 2 MINOR, 5 INFO) — CR-1 is a one-clause changelog repair the developer may take or the PM may waive; CR-2 is out of scope here and travels as RES-1. No rollback: no code defect, no design drift, no requirement gap.
