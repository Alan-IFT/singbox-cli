# 02 — Rationale · T-18 `status-egress-via-clash-api`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| One place that asks the local Clash API a question | `clash_api(method, path, data=None, port=None)` | `/home/alan/Programs/singbox-cli/bin/sc:1978-1992` | **Reuse as the seam** — it already is the single door; the change happens inside it and nowhere else. |
| "Is the decoded body the shape I can use?" | `isinstance` shape tests with no `try`/`except` | `bin/sc:2029-2047` (`stored_delays()`) | **Reuse the idiom verbatim.** `stored_delays()`'s docstring (`:2019-2022`) already states the project position — a malformed body must not reach a traceback, and a bare except would hide a real defect just as well as it hides a malformed body. The new object gate is the same test one level up, which is what lets `stored_delays()` keep its own tests unchanged. |
| A "no answer" value every caller already understands | `None`, tested at four of five call sites | `bin/sc:2149`, `:2232`, `:2505`, and by omission `:2580` | **Reuse as-is.** No new sentinel, no exception class, no result object — the callers were written against this contract already; the function simply starts honouring it. |
| A user-facing way to say "this Clash fact is unavailable" | `t("(unavailable)")` → `（不可用）` | `bin/sc:2232` + `TRANSLATIONS` | **Reuse as-is.** Q-9's zero-string budget holds: no state this task creates needs a sentence the two existing keys cannot say. |
| A user-facing way to say "the egress probe failed" | `t("(error: {e})")` → `（错误：{e}）` | `bin/sc:2239`, `:2522` | **Reuse as-is**, and the surrounding `except Exception` at `:2236-2239` is left byte-identical (AC-S1's neighbourhood). |
| A name for the `IncompleteRead` family | `http.client.HTTPException` | stdlib `/usr/lib/python3.12/http/client.py:1511,1533` | **New import, justified** — the family is reachable through no name `bin/sc` already binds (`urllib.request` imports it, but `bin/sc` never binds `http`). It is stdlib (NFR-1) and it costs **zero net imports**, because `import urllib.error` becomes dead in the same edit. |
| Anything resembling a retry, a cap, a second endpoint, a helper, a new module | (none found, and none justified) | — | **Not added.** `docs/dev-map.md`'s "Patterns to avoid" and rule 85's counter-rule both point the same way. |

## Grounding the exception set — verified, not recalled

Read from the installed stdlib rather than from memory:

- `class URLError(OSError)` and `class HTTPError(URLError, …)` — `/usr/lib/python3.12/urllib/error.py:19,35`. Both are therefore **already covered by `OSError`**, which is why the two names in today's tuple disappear rather than move.
- `class HTTPException(Exception)`, `class IncompleteRead(HTTPException)`, and its siblings `BadStatusLine`, `LineTooLong`, `InvalidURL`, `RemoteDisconnected(ConnectionResetError, BadStatusLine)` — `/usr/lib/python3.12/http/client.py:1511,1533,1519,1559,1566,1571`. `HTTPException` is a plain `Exception` subclass: **no `OSError`, no `ValueError`**, so BC-4 escapes any tuple that does not name it.
- `class JSONDecodeError(ValueError)` — `/usr/lib/python3.12/json/decoder.py:20`.
- `UnicodeDecodeError` → `UnicodeError` → `ValueError` (language reference; the same trap is recorded project-wide in `.harness/insight-index.md:20`, and `bin/sc:358` already pairs `OSError` with `json.JSONDecodeError` for the same reason).
- `TimeoutError` is a built-in **`OSError`** subclass (PEP 3151); `socket.timeout` is a subclass of `OSError` on the 3.6 floor and an alias of `TimeoutError` from 3.10. Either way `OSError` covers BC-1 on every supported interpreter.

So the body of `clash_api()` — `urlopen`, `read`, `decode`, `json.loads` — can raise members of exactly three families, and naming the three families rather than the leaves is what makes the fix hold when a *sibling* shows up (a `ConnectionResetError` mid-read, an `InvalidURL` from a `None` port, a `BadStatusLine` from a non-HTTP server). None of those three has an in-tree caller relying on it escaping.

## Options compared, and what the smaller one was

| option | size | why not chosen |
|---|---|---|
| **A — `except (OSError, ValueError, http.client.HTTPException)` + one `isinstance` gate** (chosen) | +1 import (net 0), 1 rewritten `except`, 1 rewritten assignment, 1 new `return`, ≤8 docstring lines | — |
| **B — `except Exception` + the same gate** (the smaller alternative) | 1 word, **no import at all**; one line smaller than A | Rejected. It converts a genuine defect *inside* `clash_api()` — an `AttributeError` after a refactor, a `TypeError` from a future header change, a `NameError` — into the sentence "the Clash API is not answering", and `sc doctor` would then print `[PROBLEM] Clash API responding` about a bug in `sc`. That is the exact failure the project already wrote down twice: `stored_delays()`'s docstring (`bin/sc:2019-2022`) refuses a bare except on the grounds that it hides a real defect, and `README.md:268` publishes that `[UNKNOWN]`/`[PROBLEM]` must describe the thing being checked. `cmd_doctor:2555-2562` *does* use `except Exception`, and the distinction is principled: a **driver** isolating unknown probe code cannot enumerate anything, while a function judging **its own** four-statement body can. One line buys the difference between an honest diagnostic and a lying one, on a command whose entire purpose is diagnosis. |
| **C — enumerate the leaf classes** (`TimeoutError`, `JSONDecodeError`, `UnicodeDecodeError`, `IncompleteRead`, plus today's two) | 6 names + 1 import; larger than A | Rejected. It is provably incomplete the day it ships — `ConnectionResetError` mid-read and `BadStatusLine` from a non-HTTP peer both escape it — so it is code shaped like T-15's symptom list rather than like the problem, and it guarantees a second patch. Rule 85's `## The directive` names this shape directly. |
| **D — a local `try`/`except` at `cmd_status`** | ~4 lines, one caller | Rejected by Q-3 and forbidden by AC-S2, and rightly: it fixes one of five symptoms and leaves `sc ls` broken on the host whose defining property is being broken. |
| **E — a `_clash_get()` helper / a `ClashUnavailable` exception / a module-level tuple constant** | +1 concept each | Rejected. A tuple constant used once is a name a future reader must resolve to read four lines; a helper wrapping the one seam is a second door; an exception class re-raises the problem the task exists to delete. None of them removes a future edit, which is rule 85's test for a justified structure. |

**Also considered and adopted, as a deletion:** after A, `urllib.error` has exactly one reference in
the file (`bin/sc:1991`) and that reference goes away, so the import goes with it. This is why the
chosen design's net import count is **zero** — the "new dependency" that NFR-1 asked to be justified
turns out to be an exchange, not an addition.

**Deletion test on the design as a whole:** delete the `isinstance` gate and `sc status` calls
`.get()` on an `int`; delete the widened tuple and four failure classes reach the screen at five call
sites. Both halves earn their lines, and neither is needed anywhere else — which is the argument for
their sitting in `clash_api()` and not in a new module.

## Risks

| # | risk | mitigation |
|---|---|---|
| 1 | **`except` widened past what the body can raise, hiding a defect in `sc` itself.** The three families are broad; `OSError` in particular covers a lot. | Scope, not breadth, is the control: the `try` block stays exactly four statements long (`urlopen`, `read`, `decode`, `json.loads`), and `json.dumps(data)` + `Request()` construction stay **outside** it, as at HEAD. K-9 makes the docstring say why the three families and not `Exception`, so the next reader cannot widen it further by accident. V2 asserts no new `except` appears anywhere. |
| 2 | **BC-8 regresses**: someone "simplifies" the empty-body case away and `sc use` / `sc mode` stop reporting success on a `204`. This is the one thing that must not break, and `{}` is falsy — a truthiness test would break it silently. | K-3 pins the order (`{}` first, object test after) and forbids a truthiness test; V3 asserts `{}` by value **and** type for BC-8; V5 asserts the user-visible `Switched to:` line for `204` on candidate and control. |
| 3 | **A vacuous green run.** With `SYSTEMD = OPENRC = False` the real `is_running()` returns `False`, so `cmd_status` never calls the Clash API and `cmd_use` never issues the `PUT` — every BC assertion would pass on the *control* too, and NFR-5 would be satisfied on paper by a fixture that measured nothing. Its twin is the `LANG` reassignment in `main()`, which renders English while Chinese assertions pass. | K-10 and K-11 make both explicit, and AC-B3's control requirement is the backstop: a control that does not traceback for BC-1 … BC-5 proves the fixture never reached the code, and NFR-5 requires reporting that as inconclusive rather than as a pass. |
| 4 | **`sc doctor`'s unsanctioned delta** (BC-1 … BC-4 moving `[UNKNOWN]`/exit 2 → `[PROBLEM]`/exit 1) is discovered late and read as a scope breach. | Surfaced now as R1 with the exact mechanism and line numbers, measured by V6 on candidate *and* control, and disclosed to users in K-8's changelog clause. It is forced by AC-S2 + FR-1 and it moves the command toward its published contract; the gate rules on widening BC-14, and nothing in the design changes either way. |
| 5 | **The deleted `import urllib.error` breaks something a grep missed** (a string-built reference, a future hunk landing in parallel). | `urllib.error` is a two-line surface in this file (`:15`, `:1991`); the module is a single flat file with no dynamic import and no `getattr` on module names. V10 re-greps the *final* file rather than the diff, and R5 hands that check to code review as well. |
| 6 | **The one live-host run (V7) writes something.** It is the pipeline's only invocation of product code against the live machine. | NFR-3's five preconditions checked and reported before the run; `sudo python3 <repo>/bin/sc` so the import-time re-exec of `/usr/local/bin/sc` never fires; `cmd_status` issues exactly one `GET /configs` and no write; the mtime + size witness over `/etc/sing-box/**` and `/var/lib/sing-box` taken before and after is what makes "it wrote nothing" evidence instead of confidence. |

## Notes on scope kept where the requirement put it

Rule 85's `## Recording the call` asks for consolidation/split decisions. There are none to record:
Q-3 already consolidated R-20 into this task at the right granularity — one seam, one function, one
edit — and this design agrees with it rather than re-deriving a different shape. The only movement is
outward: R1 hands a requirement correction to the gate, R2 hands a `.harness/` record to the PM
because NFR-2 forbids this task's diff from carrying it, and R3 hands two wall-clock measurements to
QA. Nothing requested was dropped.
