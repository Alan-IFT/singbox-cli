> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Method, and its one limit

This reviewer's grant carries no shell. `git diff`, `python3 -m py_compile`, and
`bash .harness/scripts/verify_all.sh` could not be re-executed here, and no HEAD blob could be
extracted. Everything below was established by reading the working-tree files. Where a HEAD
comparison was required (AC-S1, AC-S2, K-5, K-6), it was replaced by a **line-shift argument**, which
is weaker than a digest but is not confidence:

- Every upstream citation of a HEAD line number that lies **before** `clash_api()` still resolves to
  the same content at the same line in the candidate: `TRANSLATIONS` keys at `:143-144` (gate § dim 3),
  `_egress_ip()` at `:391-400` (design K-5). Shift = **0**.
- Every upstream citation **after** `clash_api()` resolves to the same content at HEAD-line + 6:
  `stored_delays()`'s `clash_api` call `:2026 → :2032`, its `isinstance` gate `:2029 → :2035`,
  `cmd_use` `:2148 → :2154`, `cmd_status` `:2230 → :2236`, `_egress_ip()` call sites `:2237 → :2243`
  and `:2520 → :2526`, `_doctor_clash` `:2503 → :2509`, `cmd_mode` `:2580 → :2586`,
  `stored_delays()`'s reach from `cmd_ls` `:2101 → :2107`.
- A uniform 0-shift before and a uniform +6-shift after, with content matching the upstream first-hand
  reads at every one of those points, admits exactly one edit region: `clash_api()`, growing by 6 net
  lines (15 → 21). `bin/sc` carries **91** `try:`/`except` line starts, matching the developer's
  reported 45 + 46 exactly.

So AC-S1/AC-S2/K-5/K-6 are verified to the precision of the upstream first-hand citations, not to a
byte-for-byte digest. Stage 6 re-runs V1/V2/V9/V10 with a real clone and closes the residue (RES-3).

## Finding 2 — the return statement's scoping, exhaustively

The design places the `return` outside the `try`. Every path was walked:

1. `urlopen` raises (refusal, no route, timeout, `HTTPError`) → `except` → `return None`. `answer`
   never bound, never read.
2. `r.read()` raises (`IncompleteRead`, `ConnectionResetError`) → the `with` runs
   `HTTPResponse.close()` on the way out, the exception continues to the `except` → `return None`.
3. `.decode()` raises `UnicodeDecodeError` (⊂ `ValueError`) → same.
4. `json.loads` raises `JSONDecodeError` (⊂ `ValueError`) → same.
5. Normal completion: `answer` is bound, then the `with` exits. If `HTTPResponse.close()` itself
   raised an `OSError`, it would be caught and a good answer silently degraded to `None` — this is a
   conservative failure, not a defect, and `io.BufferedIOBase.close()` on a read-only response has no
   realistic raising path.
6. An exception outside the three families (`RecursionError`, `MemoryError`, `KeyboardInterrupt`)
   propagates out of the function entirely — it never reaches the `return`.

There is therefore **no path on which `answer` is unbound when the `return` executes**: the only way
to reach that line is to fall off the end of the `with`, which requires the assignment to have
completed. `isinstance(x, dict)` with a builtin type as the second argument cannot raise, so running
it outside the `try` adds no escape. `KeyboardInterrupt` remaining uncaught is the correct outcome —
the 3 s wait stays interruptible, matching the reasoning already written at `bin/sc:2564`.

## Finding 3 — PA-1's silent-regression warning

The warning is real and permanent: `json.loads("")` raises `ValueError`, which the widened tuple now
catches, so deleting `if text else {}` would turn BC-8 from a loud traceback into a silent `{}` → wait,
into a silent `None` — `sc use` and `sc mode` would stop reporting success on a `204` with no error
anywhere. The code as written is correct (`bin/sc:1995`). The protection for the next reader is
partial: the docstring states the *contract* ("An empty 2xx body is {}") and `docs/dev-map.md:39`
states it twice over ("An empty 2xx body is `{}` (so a `204` reads as success)"), so a reader who
deletes the branch violates a written contract in two published places. Neither surface states the
*mechanism* — that the ValueError which used to make that mistake loud is now caught. Adding that
sentence is not possible inside K-9's ceiling (E1+E2 sit at exactly 12 added lines), and the contract
statement is the more durable of the two. Judged adequate; no finding raised. `04_DEVELOPMENT.md`
already carries the mechanism for the next maintainer, and the residual belongs to QA's assertion
(V3 asserts `{}` by value *and* type), which is where PA-1 put it.

## Finding 4 — C-8, judged by rule 85 applied to documentation

`docs/dev-map.md:39` and the docstring (`bin/sc:1979-1986`) each state, independently:

- the three families by name, with the reason they are families and not leaves;
- the residue clause naming `RecursionError` / `MemoryError` and why no cap is bought;
- `{}` for an empty 2xx body, `None` for a non-object body;
- "callers add no `try`/`except`" (dev-map only — correctly, since it is the map that a future
  caller-author reads).

Neither claims an unqualified "never an exception". The qualified form is longer than the absolute
form by roughly one clause each. What a future reader must hold is: *three families, one residue, two
body cases*. That is proportionate — the residue clause is the difference between a map a reader can
trust and one that is false in exactly the case BC-12 declined to defend, which is the T-17 precedent
the gate invoked. The dev-map row is long, but shorter than its `# Config composition` and
`# Config generation` neighbours (`:37`, `:38`), so the table's own proportion is unchanged.

## Finding 5 — the changelog bullet, quote by quote

Verified against the code rather than against the design:

| bullet claim | code | verdict |
|---|---|---|
| five failure classes named | port held and silent (timeout), non-JSON body, non-UTF-8 body, short body, non-object body | ✅ five, and it discloses that the fifth "过去甚至不报错，而是被当成正常回答继续使用" |
| `sc status` → 「（不可用）」, other lines still printed, exit 0 | `bin/sc:2238` renders key `"(unavailable)"` → `"（不可用）"` (`:143`); `cmd_status` has no `sys.exit` | ✅ |
| `sc ls` → `-` | `bin/sc:2035` isinstance gate → `{}`, `:2110` renders `-` | ✅ |
| `sc use` → regenerates config, restarts, prints 「（服务已重启）」 | `:2155` `r is not None` fails → `:2158` `reload_or_restart()` = `generate_config()` + `restart_service()` (`:1969-1973`) → `:2159` prints key whose zh is `"已切换到：{tag}（服务已重启）"` (`:146`) | ✅ quoted text matches the actual translation byte for byte |
| `sc mode` → prints 「路由模式 → <模式>」, running process unchanged until reload | `:2586` value discarded, `:2587` prints key whose zh is `"路由模式 → {mode}"` (`:160`) | ✅ |
| exit status 2 → 1 **只在没有其他检查项报「异常」的前提下** | `DOCTOR_EXIT` (`:2263`) + `worst = max(...)` (`:2574`) | ✅ C-2 honoured literally |
| names no file path, no Python identifier | reads `sc status` / `sc ls` / `sc use <节点>` / `sc mode <模式>` / `sc doctor` and the JSON values `5` / `"x"` / `[1,2]` | ✅ command names are not identifiers; no `bin/sc`, no `clash_api` |
| 「所有输出文字…没有任何改动」 | `TRANSLATIONS` unchanged (0-shift at `:143-146`, `:160`, `:263`, `:291`) | ✅ the *set* of strings is unchanged; which string a given state renders does change, and the bullet is precisely the description of that |
| no new zh string carries `失败：` | the only `失败：` in `bin/sc` is pre-existing at `:204` (`"failed: {e}"`); zero strings added | ✅ FR-5 vacuously satisfied |

The one imprecision is CR-1: the `sc doctor` clause's *before*-state. For the non-object class HEAD
returned the value and `_doctor_clash()` printed `[OK] Clash API responding: 是` — a lying row, exit
contribution 0 — so for that class the section did not collapse to 未知 and the exit move is 0 → 1,
not 2 → 1. K-8 itself asserted all five reached the screen as a traceback, which is what the bullet
inherited; the developer improved on it elsewhere in the same paragraph ("过去甚至不报错") and only the
doctor sentence over-generalises. Suggested repair, one clause, no new bullet:

> …不再整节塌成一行「未知」（正文不是对象的那一类过去这一行反而显示「正常」），也就是这一节由「未知」
> 或「正常」变成「异常」，因此在没有任何其他检查项报「异常」的前提下，这次运行的退出码相应地由 2 或 0
> 变成 1。

## Finding 6 — the refuted phantom

`_egress_ip()` (`bin/sc:391-400`) is one `urllib.request.urlopen("https://api.ipify.org", timeout=8)`
with no `proxies=`, no `ProxyHandler`, no opener installed, no `127.0.0.1` — identical to Q-1's
first-hand description of HEAD and at HEAD's own line numbers. Its two call sites (`:2243` inside
`cmd_status`'s `try/except Exception`, `:2526` inside `_doctor_egress`) carry their surrounding
handlers unchanged. A repository-wide read of the diff region shows no second address query, no proxy
argument, no Clash endpoint added: the only Clash routes in the file remain `GET /proxies` (`:2032`),
`PUT /proxies/proxy` (`:2154`), `GET /configs` (`:2236`, `:2509`) and `PATCH /configs` (`:2586`), and
there is **no `"DELETE"` literal anywhere**. The phantom was not re-introduced.

## Finding 7 — the sixth escape class, verified against the installed stdlib

`/usr/lib/python3.12/urllib/request.py:1342-1351` reads exactly as `04_DEVELOPMENT.md` reports:

```python
        try:
            try:
                h.request(...)
            except OSError as err: # timeout error
                raise URLError(err)
            r = h.getresponse()
        except:
            h.close()
            raise
```

Only `h.request(...)`'s `OSError` becomes a `URLError`; `h.getresponse()`'s exceptions pass through
the bare `except:` and are re-raised **unwrapped**. Confirmed. Two distinct variants follow, and they
have different mechanisms:

- **(a) reset before/while the status line and headers are read.** `h.getresponse()` raises
  `RemoteDisconnected` — `class RemoteDisconnected(ConnectionResetError, BadStatusLine)`
  (`/usr/lib/python3.12/http/client.py:1571`) — or a plain `ConnectionResetError`. Neither is a
  `URLError` or an `HTTPError`, so it escapes HEAD's tuple. This is the variant the citation explains.
- **(b) reset while the *body* is being read.** The `ConnectionResetError` is raised by `r.read()`
  inside `clash_api()`'s own `try` block, with `do_open` no longer on the stack at all. It escapes
  HEAD's tuple for the simpler reason that HEAD's tuple never covered `ConnectionResetError`. This is
  the variant `04`'s prose describes; the citation is not its explanation.

Both are **defect** states on HEAD and both are covered by the candidate (`ConnectionResetError` ⊂
`OSError`; (a) is additionally an `HTTPException` through `BadStatusLine`). The developer's conclusion
is confirmed and QA's control class for BC-6 must be split accordingly — a "reset" fixture that is
declared an agreement state would make the run inconclusive under NFR-5.

## Finding 8 — the third family is load-bearing

`class IncompleteRead(HTTPException)` (`/usr/lib/python3.12/http/client.py:1533`) — `HTTPException`
**only**, not also a `ValueError`. So BC-4 (a body shorter than its declared `Content-Length`) is
caught by nothing but `http.client.HTTPException`, and dropping the third family "because
`ValueError` already covers bad bodies" would silently reopen BC-4. Recording this because it is the
kind of simplification a future reader makes; the docstring's family list is what prevents it.

## Finding 9 — does this actually fix `sc ls` (Q-3 / R-20)?

Traced first-hand: `cmd_ls` (`:2097`) → `stored_delays()` (`:2107`) → `clash_api("GET", "/proxies")`
(`:2032`). `stored_delays()` carries **no** `try`/`except` by deliberate design (`:2025-2028`), so at
HEAD a `JSONDecodeError` / `UnicodeDecodeError` / `IncompleteRead` / hung-port `TimeoutError` from
`clash_api()` propagated straight through `cmd_ls` before a single table row printed. Under the
candidate it returns `None`, the `isinstance` gate at `:2035` yields `({}, None)` and every cell
renders `-`. Q-3's claim holds: `sc ls` is genuinely fixed by the same one edit, not merely
`sc status`. The one `sc ls` traceback this does **not** close is `load_nodes()` at `:2098`, which is
BC-13 / R-29 and disclosed as out of scope.

A supporting observation neither upstream stage made (CR-7): `CHANGELOG.md:11`, the *already-written*
`sc ls` bullet in the same `[Unreleased]` block, promises "API 不通或返回内容异常时表格照常打印、不会抛
Python 报错". That promise was **false at HEAD** for the invalid-JSON, invalid-UTF-8 and short-body
states and becomes true only with this change. Since both bullets ship in the same unreleased block,
the release is self-consistent — and it is independent evidence that the seam Q-2 identified is the
right one.

## Findings the 6 dimensions produced with nothing to report

- **Performance.** One request, one `timeout=3`, no loop, no allocation beyond the body, nothing on a
  hot path. Unchanged from HEAD. The only note is CR-5's per-operation-vs-total distinction.
- **Security.** No new input trusted, no new endpoint, no `PUT`/`PATCH`/`DELETE` added, no secret in
  any string, no deserialization beyond `json.loads` of a loopback peer's answer whose threat model
  BC-12 states and declines by argument. Widening the catch to `OSError` does not swallow
  `KeyboardInterrupt` or `SystemExit`, both `BaseException` — so the 3 s wait and the 8 s egress wait
  remain interruptible, preserving the property `bin/sc:2564` already relies on.
- **Maintainability.** The one naming decision (`answer`, because `body` is already the request
  payload at `:1988`) matches `_doctor_clash()`'s existing `answer` at `:2509`; it is a naming choice,
  not drift, and the developer disclosed it. No dead code, no abstraction added, no comment restating
  the code.
