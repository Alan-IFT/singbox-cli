# 04 — Development · T-18 `status-egress-via-clash-api`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

- `clash_api()` is now total over the three exception families its own body raises: it returns a
  `dict` or `None` and no other type, with `{}` still the value of an empty 2xx body.
- The change is confined to the import block and `clash_api()`'s own body — no call site, no
  `_egress_ip()`, no `TRANSLATIONS` entry, no HTTP method, no route, no timeout moved.
- `docs/dev-map.md`'s `# Clash API` row and one Chinese `CHANGELOG.md` bullet publish the new
  contract, both qualified per C-8/C-2 rather than as an absolute.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | Import block: `import urllib.error` deleted (dead — `:1991` was its only other reference), `import http.client` inserted in the alphabetical slot after `import hashlib`. Net imports: unchanged (15 → 15). | E1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `clash_api()` (`:1978-1998`): three-line lead comment → an 8-line docstring; decoded body bound instead of returned inside the `with`; `except (urllib.error.URLError, urllib.error.HTTPError)` → `except (OSError, ValueError, http.client.HTTPException)`; one trailing `return answer if isinstance(answer, dict) else None`. Signature, URL, method, headers, `timeout=3` and the one-request property untouched. | E2 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | Line 39 — the `# Clash API` row — replaced with K-7's text as modified by C-8. No other line of the file changed (`git diff --stat` → `1 +, 1 -`). | E3 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | One Chinese bullet inserted at the head of `## [Unreleased]` → `### 修复` (newest-first, the file's existing order), one paragraph, per K-8 as modified by C-2 and C-6. | E4 |
| `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/04_DEVELOPMENT.md` | This contract portion. | E7 |
| `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/04_RATIONALE.md` | Measurement transcripts (candidate + HEAD control) and the `urllib` evidence behind the open issue below. | E7 |

`git diff --name-only` over the working tree also lists `docs/tasks.md` and
`docs/batches/default/BATCH_PLAN.md`; both were already modified before this stage started (PM-owned,
present in the pre-edit `git status`) and neither was touched here.

## verify_all result

```
baseline (before any edit): PASS 17 · WARN 0 · FAIL 0 · SKIP 1
after (final tree):         PASS 17 · WARN 0 · FAIL 0 · SKIP 1
delta:                      0 new FAIL, 0 new WARN, baseline preserved
command:                    bash .harness/scripts/verify_all.sh
py_compile:                 python3 -m py_compile bin/sc → OK (before and after)
```

## Design drift

None.

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-2 | Honoured. The changelog bullet states the exit-status move as conditional: 「这一节由「未知」或「正常」变成「异常」，因此在没有任何其他检查项报「异常」的前提下，这次运行的退出码相应地由 2 或 0 变成 1」— never an unconditional move. The before-state is stated per class, not over all five: for the non-object-body class HEAD did not collapse the section but printed a `[正常]` row contributing 0 to the exit status, which the same clause now names in parentheses (「正文不是对象的那一类过去这一行反而显示「正常」」). Labels and exit map checked against the code: `"OK"/"PROBLEM"/"UNKNOWN"` → 「正常」/「异常」/「未知」 (`bin/sc:248-250`), `DOCTOR_EXIT = {OK: 0, UNKNOWN: 2, PROBLEM: 1}` (`:2263`). | `CHANGELOG.md`, the new first bullet under `### 修复`; `bin/sc:248-250`, `:2263`, `:2512`, `:2514` |
| C-4 | Honoured. The five literal call sites are unedited and each was read in the final diff: at HEAD `bin/sc:2026, :2148, :2230, :2503, :2580`; in the candidate the same lines shifted +6 to `:2032, :2154, :2236, :2509, :2586` with byte-identical content. `sc ls`'s indirect reach through `stored_delays()` (`:2101` → `:2107`) is likewise untouched. `bin/sc` carries 45 `try:` and 46 `except` lines at HEAD and the same 45/46 in the candidate — one clause rewritten, none added. | `git diff bin/sc` (hunks touch only the import block and `clash_api()`); AST/line comparison against `git show HEAD:bin/sc` |
| C-6 | Honoured. The bullet names `sc mode` (「照常保存设置并打印「路由模式 → <模式>」，但正在运行的进程要到下次重启或重新加载才真正换过去」) and states that `sc use` on those states now regenerates the config and restarts the service instead of tracebacking (「像端口连不上时那样重新生成配置并重启服务，然后打印带「（服务已重启）」的那一行」). Both readings were checked against the unedited code at `bin/sc:2153-2159` and `:2585-2587`. | `CHANGELOG.md` bullet |
| C-8 | Honoured. Neither published surface claims an unqualified "never an exception". The dev-map row reads "**total over the three exception families its own body raises** (`OSError`, `ValueError`, `http.client.HTTPException`)" and carries the residue clause ("a pathological body from a process on this host's own loopback can still raise `RecursionError` / `MemoryError`, and no size or depth cap is bought for a threat model that is already lost"); the docstring carries the same two statements. K-1's tuple is unchanged. The docstring is 8 physical lines (`bin/sc:1979-1986`), and E1+E2 add 12 lines in total (`git diff --numstat bin/sc` → `12 6`), at K-9's ceiling and not over it. | `docs/dev-map.md:39`; `bin/sc:1979-1986` |

## Open issues for review

- **BC-6's "unchanged from HEAD" is false for one of its variants, measured.** A peer that accepts and
  then resets *while the response is being read* escapes HEAD's `except (URLError, HTTPError)` as a raw
  `ConnectionResetError`: `urllib.request.AbstractHTTPHandler.do_open` wraps only `h.request(...)`'s
  `OSError` into `URLError` and re-raises `h.getresponse()`'s exceptions bare
  (`/usr/lib/python3.12/urllib/request.py:1342-1348`). The HEAD-clone control raised it; the candidate
  returns `None`. No code consequence — the candidate already covers it, `ConnectionResetError` being an
  `OSError` — but it is a fifth escaping class beyond the four the insight index records, and QA should
  declare that variant a **defect** state, not an agreement state.
- The decoded body is bound to `answer`, not `body`: `body` is already the *request* payload local in
  the same function (`bin/sc:1988`). The design named no variable, so this is a naming choice, not drift;
  it matches `_doctor_clash()`'s existing `answer`.
- E1+E2 land on exactly 12 added lines, K-9's ceiling, and the docstring on exactly its 8-line maximum
  (`bin/sc:1979-1986`). Any later addition inside `clash_api()` in this task would breach it; a wording
  change there has to reflow inside the existing lines, as the current first sentence does (its 99
  characters are within the file's own habit — 44 other lines of `bin/sc` exceed 98).
- PA-1's silent-regression warning stands as a permanent property of the file: because `ValueError` is
  now caught, a future edit that breaks the `if text else {}` branch degrades `{}` to `None` with no
  traceback. This stage's check asserts BC-8 by value *and* type; a future one must too.

## Dev-map updates

- No line added or removed. `docs/dev-map.md:39` (the `# Clash API` row of the "`bin/sc` internal
  sections" table) was replaced in place with K-7's text as modified by C-8; the file's line count is
  unchanged and no other row, table or section was touched.

## Insight to surface

- `urllib.request.AbstractHTTPHandler.do_open` wraps only `h.request()`'s `OSError` into `URLError` and re-raises `h.getresponse()`'s exceptions bare, so a peer that resets the connection *while the response is being read* escapes an `except (URLError, HTTPError)` as a raw `ConnectionResetError` — the class of failure that looks covered on a reading of the source and is not · evidence: /usr/lib/python3.12/urllib/request.py:1342-1348, reproduced on a HEAD clone

## Verdict

READY FOR REVIEW
