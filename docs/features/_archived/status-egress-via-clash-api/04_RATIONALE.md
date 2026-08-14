# 04 — Development rationale · T-18 `status-egress-via-clash-api`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## The developer-level totality check (V3's shape), and its control

Not QA's V3 — QA rebuilds its own rig. This is the developer-level check the stage contract requires:
one raw-socket stand-in bound to `127.0.0.1` on an **ephemeral** port (never the live Clash port), the
module imported by `docs/dev-map.md`'s recipe (`geteuid` shim, restored in a `finally`), all eight path
constants repointed into a `mkdtemp()` root **and asserted to resolve there**, `SYSTEMD = OPENRC = False`,
`SB_BIN` repointed to a non-existent stub, `_init_files()` never driven, and `sc.CLASH_PORT` assigned
directly per state so `main()`/`_resolve_clash_port()` never runs (F-7/C-9's trap does not apply to a
direct-call harness, but the port each run talked to is printed anyway). Only `GET /configs` is issued;
no `PUT`/`PATCH`/`DELETE` anywhere; nothing under `/etc` or `/var/lib` is opened.

Script: `<scratchpad>/v3_totality.py` (not committed — R-9 keeps a committed harness out of this task).

### Candidate (working tree)

```
BC-1  hang, never answers                  port=46703  -> None                   type=NoneType   OK
BC-2  2xx non-JSON body                    port=40915  -> None                   type=NoneType   OK
BC-3  2xx invalid UTF-8                    port=41997  -> None                   type=NoneType   OK
BC-4  2xx short body (Content-Length)      port=44741  -> None                   type=NoneType   OK
BC-5  2xx body 5                           port=37023  -> None                   type=NoneType   OK
BC-5  2xx body "x"                         port=35795  -> None                   type=NoneType   OK
BC-5  2xx body [1,2]                       port=37755  -> None                   type=NoneType   OK
BC-5  2xx body null                        port=34253  -> None                   type=NoneType   OK
BC-6  connection reset on accept           port=43205  -> None                   type=NoneType   OK
BC-7  404                                  port=41305  -> None                   type=NoneType   OK
BC-7  500                                  port=40515  -> None                   type=NoneType   OK
BC-8  204, no body                         port=35337  -> {}                     type=dict       OK
BC-8  200, zero-length body                port=45595  -> {}                     type=dict       OK
control 2xx JSON object                    port=33067  -> {'mode': 'rule'}       type=dict       OK
BC-6  nothing listening                    port=42119  -> None                   type=NoneType   OK

15/15 states total; failures: none
```

BC-8 is asserted by **value and type** (`got == {}` *and* `type(got) is dict`), which is PA-1's
requirement: the widened catch makes a BC-8 regression silent, so `== {}` alone would also accept `None`
never being reached, and truthiness would reject the correct answer.

### HEAD control (clone, not a worktree — K-12)

Same script, same states, against `git clone --no-hardlinks` of the repository at `ed01efc`:

```
BC-1  hang, never answers      FAIL  RAISED TimeoutError: timed out
BC-2  2xx non-JSON body        FAIL  RAISED JSONDecodeError: Expecting value: line 1 column 1 (char 0)
BC-3  2xx invalid UTF-8        FAIL  RAISED UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff ...
BC-4  2xx short body           FAIL  RAISED IncompleteRead: IncompleteRead(15 bytes read, 385 more expected)
BC-5  2xx body 5               FAIL  -> 5                  type=int
BC-5  2xx body "x"             FAIL  -> 'x'                type=str
BC-5  2xx body [1,2]           FAIL  -> [1, 2]             type=list
BC-5  2xx body null            OK    -> None               type=NoneType
BC-6  connection reset         FAIL  RAISED ConnectionResetError: [Errno 104] Connection reset by peer
BC-7  404 / 500                OK    -> None
BC-8  204 / 200 zero-length    OK    -> {}                 type=dict
BC-6  nothing listening        OK    -> None
```

The control reproduces the defect rather than agreeing, so the candidate's green is not vacuous. It also
confirms C-5's per-value control classes first-hand: `null` **agrees** at HEAD (it decodes to `None`),
while `5` / `"x"` / `[1,2]` are the defect states and return the wrong type rather than raising.

## Why `ConnectionResetError` escaped at HEAD, and what it means for BC-6

BC-6 is written as "unchanged from HEAD". That holds for *nothing listening* and for *refused*, and is
false for *reset while the response is being read*:

```python
# /usr/lib/python3.12/urllib/request.py:1342-1348, AbstractHTTPHandler.do_open
try:
    try:
        h.request(req.get_method(), req.selector, req.data, headers, ...)
    except OSError as err: # timeout error
        raise URLError(err)
    r = h.getresponse()
except:
    h.close()
    raise
```

Only `h.request(...)`'s `OSError` becomes a `URLError`. Anything `h.getresponse()` raises is re-raised
bare after `h.close()`. So the wrapping that makes `except (URLError, HTTPError)` *look* like a socket-error
envelope covers the send half of the exchange only — which is exactly why a family-level catch is the right
shape and a leaf enumeration derived from reading the source is not. Under K-1's tuple the case is covered
without a new name: `ConnectionResetError` is an `OSError`.

Consequence for QA, filed as an open issue in the contract portion: the reset variant of BC-6 must be
declared a **defect** state (control raises), not an agreement state, or NFR-5 will report an inconclusive
run for a state the candidate genuinely fixes.

## Two small choices the design did not name

- **`answer`, not `body`, for the decoded value.** `body` is already bound in the same function to the
  *request* payload (`bin/sc:1988`). Reusing it would be harmless at run time (the request is already
  sent) and actively misleading to read. `_doctor_clash()` already calls the same thing `answer`.
- **The `isinstance` gate sits after the `try`, not inside it.** K-3 fixes the order relative to the
  empty-body branch, not the block it lives in. Outside the `try` the gate is visibly not a source of
  caught exceptions, and the `return` in the `except` arm keeps the two exits adjacent. `json.loads`
  stays inside the `with`, exactly as at HEAD, so the read and the decode keep their existing scope.

## What was checked and found unchanged

| property | method | result |
|---|---|---|
| `_egress_ip()` byte-identity (K-5, AC-S1) | AST `get_source_segment` + sha256, candidate vs `git show HEAD:bin/sc` | `78ec7c96a5ce9005` both sides — EQUAL; its call sites (`:2237` → `:2243`, `:2520` → `:2526`) appear in no hunk |
| `TRANSLATIONS` byte-identity (K-6) | AST extraction of the assignment + sha256 | `2824d051c9006b21` both sides — EQUAL; zero keys added or changed |
| `PUT` / `PATCH` / `DELETE` literals (AC-S2) | count in whole file, both sides | 1 / 1 / 0 both sides |
| `try` / `except` line counts (K-4) | regex over whole file, both sides | 45 / 46 both sides |
| `urllib.error` (K-2, R5) | `grep -c 'urllib\.error' bin/sc` on the **final** file, not the hunk | `0` |
| 3.6 floor (NFR-1) | AST walk for `NamedExpr` / `match` / `async def`; diff read; stdlib-only imports | none present; `http.client` is stdlib |
| import count | count of `import` lines | 15 → 15 |
