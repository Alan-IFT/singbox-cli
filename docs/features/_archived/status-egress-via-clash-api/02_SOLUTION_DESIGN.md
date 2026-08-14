# 02 — Solution Design · T-18 `status-egress-via-clash-api`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. `clash_api()` (`/home/alan/Programs/singbox-cli/bin/sc:1978-1992`) becomes a **total** function —
   a `dict` or `None`, never an exception, never another type — by widening its `except` to the
   three *families* its own body can raise (`OSError`, `ValueError`, `http.client.HTTPException`)
   and gating the decoded body through one `isinstance(body, dict)` test.
2. Nothing else in `bin/sc` changes: no call site, no `_egress_ip()`, no translation key, no HTTP
   method, no timeout, no new concept. `import urllib.error` becomes dead and is deleted, so the
   module's import count does not grow.
3. The seam is `clash_api()` itself — it already is the single place every command asks the local
   Clash API a question, so the judgment "did we get an answer?" is moved *into* the one function
   that owns it rather than being duplicated at five callers.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | Import block (`:3-18`): delete `import urllib.error` (dead after E2 — `:1991` is its only reference), insert `import http.client` in the alphabetical slot after `import hashlib`. Net line count of the block: unchanged. | single |
| E2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `clash_api()` (`:1978-1992`): the `except` clause becomes the three-family tuple of K-1; the decoded body is returned only through the `isinstance` gate of K-3; the three-line lead comment (`:1979-1981`) is folded into a docstring stating the total contract (K-9). Signature, URL, method, headers, `timeout=3` and the one-request property are untouched. | single |
| E3 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | The `# Clash API` row of the "`bin/sc` internal sections" table (`:39`) is replaced with K-7's line. No other row, no new row, no new table. | single |
| E4 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One bullet appended under `## [Unreleased]` → `### 修复`, per K-8. | single |
| E5 | `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/02_SOLUTION_DESIGN.md` | new | This contract. | single |
| E6 | `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/02_RATIONALE.md` | new | Reuse audit, risk analysis, the rejected options and the exception-hierarchy evidence. | single |
| E7 | `/home/alan/Programs/singbox-cli/docs/features/status-egress-via-clash-api/03_GATE_REVIEW.md`, `04_DEVELOPMENT.md`, `05_CODE_REVIEW.md`, `06_TEST_REPORT.md`, `07_DELIVERY.md` | new | Downstream stage documents, written by their own stages. Named here only so the ledger is total over the task's touched files. | single |
| E8 | *(none)* | — | **No other file is touched.** `README.md` / `README.zh-CN.md` are explicitly *not* edited: the only user-visible statement they make about this area (`README.md:268`, `[UNKNOWN]` means "the check could not run at all — never *the thing being checked is broken*") is unchanged by this design and becomes *more* true under it, so NFR-2's README clause does not fire. | — |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I1 | `clash_api(method, path, data=None, port=None)` — `bin/sc` `# Clash API` | signature unchanged; return type narrows to `dict` **or** `None` | **Total.** Exactly one of: a `dict` decoded from a 2xx body (`{}` when the body is empty), or `None`. It raises no exception of the `OSError`, `ValueError` or `http.client.HTTPException` families to any caller, and returns no other type. Still exactly one request, still `timeout=3`, still `http://127.0.0.1:<port or CLASH_PORT><path>`, still writes nothing and prints nothing. |
| I2 | Clash API request envelope (all four in-tree uses) | `GET /configs`, `GET /proxies`, `PUT /proxies/proxy`, `PATCH /configs` on `http://127.0.0.1:<port>` | Identical to HEAD in method, path, body and count. No route is added, removed, renamed or retried; the repository-wide set of `PUT`/`PATCH`/`DELETE` literals is byte-identical to HEAD (AC-S2). |
| I3 | Call flow — the five call sites of `clash_api()` | `stored_delays()` `:2026` (→ `sc ls`, via `:2101`), `cmd_use` `:2148`, `cmd_status` `:2230`, `_doctor_clash()` `:2503`, `cmd_mode` `:2580` | Every site keeps its current bytes. `stored_delays` already `isinstance`-tests the body (`:2029`); `cmd_status` already writes `(r or {})` (`:2232`); `cmd_use` already tests `r is not None` (`:2149`); `_doctor_clash` already tests `answer is not None` (`:2505`); `cmd_mode` already discards the value (`:2580`). All five are correct **against I1 and only against I1** — that is why the fix has exactly one site. |
| I4 | `docs/dev-map.md` → `bin/sc` internal sections → `# Clash API` row | table row | States I1's contract in the words of K-7, so the map and the code cannot form two opinions (AC-S4). |
| I5 | `CHANGELOG.md` → `## [Unreleased]` → `### 修复` | heading + one bullet | One Chinese bullet, one paragraph, per K-8 (AC-S4). |

## Constraints

**K-1** — The implementer catches exactly `(OSError, ValueError, http.client.HTTPException)` in
`clash_api()` and nothing else: no bare `except`, no `except Exception`, and no enumeration of leaf
classes (`TimeoutError`, `JSONDecodeError`, `UnicodeDecodeError`, `IncompleteRead`, `URLError`,
`HTTPError`, `ConnectionResetError`) — each of those is a member of one of the three families, and an
enumeration is the shape that needs re-patching the next time a sibling escapes.

**K-2** — The implementer deletes `import urllib.error` in the same edit that adds
`import http.client`, having first confirmed `bin/sc:1991` is its only reference, so the file gains
no net import and names no module it does not use (NFR-1).

**K-3** — The implementer keeps `{}` as the value of an empty 2xx body and applies the object test
*after* it, so a `204` still yields `{}` (BC-8) while a body decoding to `5` / `"x"` / `[1,2]` /
`null` yields `None` (BC-5); the test is `isinstance(body, dict)` and no other predicate (not
`type(...) is dict`, not a truthiness test — `{}` is falsy and must survive).

**K-4** — The implementer edits none of the five call sites named in I3 and adds no `try`/`except`
anywhere in `bin/sc` outside `clash_api()`'s own body (AC-S2).

**K-5** — The implementer keeps `_egress_ip()` (`bin/sc:391-400`) and its two call sites
(`cmd_status` `:2237`, `_doctor_egress` `:2520`) byte-identical, including the surrounding
`try`/`except Exception` at `:2236-2239` (AC-S1, FR-4).

**K-6** — The implementer adds, removes and reworks no entry of `TRANSLATIONS`: the table is
byte-identical to HEAD after this task, because Q-9 rules the new-string budget is zero and the two
existing keys `"(unavailable)"` and `"(error: {e})"` cover every state FR-3 names (AC-S3).

**K-7** — The implementer replaces `docs/dev-map.md:39` with exactly this row, and changes no other
line of that file:
`| `# Clash API` | `clash_api(method, path, data=None, port=None)` — **total**: a JSON object or `None`, never an exception and never another type. An empty 2xx body is `{}` (so a `204` reads as success); a body that is not a JSON object is `None`. Callers therefore add no `try`/`except` — adding one is the defect, not the fix. `is_running()`, `stored_delays(port=None)`. `port=None` means "the port `main()` resolved"; only `sc doctor` passes one explicitly. |`

**K-8** — The implementer appends exactly one bullet under `## [Unreleased]` → `### 修复` of
`CHANGELOG.md`, one paragraph long, in Chinese, stating: which five failure classes used to reach the
screen as a Python traceback; that they are now treated exactly like "cannot connect"; what each of
`sc status` (route-mode line reads「（不可用）」, remaining lines still printed, exit 0), `sc ls`
(delay column reads `-`), `sc use` (no switch line for a switch that did not happen) and `sc doctor`
(the `Clash API responding` row reports 异常 and the port row survives, instead of the whole section
collapsing to 未知, and the exit status for that state moves 2 → 1) now does; and that behaviour on a
healthy host, the output wording, the 3 s timeout and the number of Clash API calls are unchanged.
It names no file path and no Python identifier.

**K-9** — The implementer replaces `clash_api()`'s three-line lead comment with a docstring of **at
most 8 lines** that states I1's contract, keeps the existing `port=None` explanation, and names *why*
the catch is three families rather than a leaf enumeration or `except Exception`; the total added
line count of E1+E2 in `bin/sc` does not exceed 12.

**K-10** — QA drives every `clash_api()`-dependent fixture with `sc.is_running` forced to return
`True` while `sc.SYSTEMD = sc.OPENRC = False`: with the real `is_running()` under those flags the
function returns `False`, `cmd_status` never reaches the Clash call and `cmd_use` never reaches the
`PUT`, so every BC-1 … BC-8 assertion would pass vacuously on both the candidate and the control.

**K-11** — QA sets the fixture language through the `mkdtemp()` copy of `settings.json` (`"lang"`)
whenever a run goes through `main()`, and through `sc.LANG` only when it calls `cmd_*` directly:
`main()` reassigns `LANG` after import, so a harness that sets only `sc.LANG` renders English on
`main()`-driven paths and every Chinese assertion passes vacuously (NFR-4).

**K-12** — QA obtains the HEAD-side control from a **clone** of the repository at HEAD, never a
`git worktree`, and runs it against the same stand-in server states (AC-B3, NFR-5).

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc:391-400` (`_egress_ip()`) and its two call sites `:2237`, `:2520` | AC-S1 / FR-4 / Q-1 — the batch goal's first clause is a refuted phantom; a "fix" here is the failure mode the freeze exists to prevent. |
| `/home/alan/Programs/singbox-cli/bin/sc` — the five `clash_api()` call sites (`:2026`, `:2148`, `:2230`, `:2503`, `:2580`) and the bodies containing them | AC-S2 / Q-3 — a caller-side guard is the 修修补补 shape this task exists to avoid; all five are already correct against I1. |
| `/home/alan/Programs/singbox-cli/bin/sc` — `TRANSLATIONS` and `t()` | Q-9 / AC-S3 — the required new-string budget is zero. |
| `/home/alan/Programs/singbox-cli/bin/sc` — `stored_delays()` body (`:2004-2048`), `# Config composition`, `# Config generation`, `main()` | Out of scope items 10-11; none of them is on the path this change alters. |
| `/home/alan/Programs/singbox-cli/README.md`, `README.zh-CN.md` | E8 — no user-visible surface they document changes; editing them would break the line-for-line mirror for nothing. |
| `/home/alan/Programs/singbox-cli/install.sh`, `uninstall.sh`, `systemd/**` | NFR-2 permitted diff. |
| `/home/alan/Programs/singbox-cli/.harness/**`, `/home/alan/Programs/singbox-cli/docs/batches/**` | NFR-2 states both are outside the permitted diff (see R2 in `## Residuals travelling` for the one record this displaces). |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | Outside NFR-2's permitted diff, and this design coins no domain term — "total function", "no-answer value" and "Clash API" are all already in use. |
| `/etc/sing-box/**`, `/var/lib/sing-box`, `/usr/local/bin/sc`, the live Clash API port | NFR-3 — verification observes them and writes none of them; the one live invocation is AC-B1/AC-B2's read-only `GET /configs`. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E2 | Working tree clean at HEAD; `clash_api()` still matches `bin/sc:1978-1992`. Apply the body change **before** the import change so the file never sits in a state where `http.client` is referenced but not imported. | `git checkout -- bin/sc`. |
| 2 | E1 | E2 applied; `grep -n 'urllib\.error' bin/sc` returns nothing. | Same. |
| 3 | E3, E4 | E1+E2 applied and `python3 -m py_compile bin/sc` passes. | `git checkout -- docs/dev-map.md CHANGELOG.md`. |
| 4 | *(verification)* | V1 … V10 of `## Verification plan`. | Revert the single commit — see the compatibility row below. |
| — | *(compatibility)* | **No data migration, no feature flag, no persisted-state change, no config regeneration.** `clash_api()` reads a peer's answer and writes nothing; `settings.json`, `nodes.json`, `config.json`, the emitted document and its digest are all unaffected, so an upgraded host needs no `sc reload` and cannot acquire a "config changed behind our back" warning. A host running the old `sc` against the same sing-box is unaffected in both directions. | Reverting the one commit restores HEAD behaviour exactly; nothing on disk has to be undone. |

## Out of scope

- Any change to `_egress_ip()`, to the egress endpoint, to its 8 s timeout, or to how either caller renders its value (AC-S1, Q-1, Q-7).
- Bounding, shortening, threading or cancelling the egress probe's wall-clock wait (BC-10, Q-11) — QA measures it, this design does not cover it.
- A response-size cap, a recursion-depth guard, or any other defence against a hostile process on this host's loopback interface (BC-12). Consequence stated plainly: a body of pathological *nesting* can still raise `RecursionError` (a `RuntimeError`, in none of K-1's three families) and a body of pathological *size* can still raise `MemoryError` — both are BC-12's already-lost threat model, and widening K-1 to cover them would be paying machinery for it.
- `load_settings()` / `load_nodes()` / `_load_lang()` and the state-file I/O seam (R-29, Q-5, BC-13) — different seam, different input class, named owner elsewhere. `cmd_status` still tracebacks on an absent or corrupt `nodes.json`, exactly as at HEAD.
- `sc doctor`'s wording, row order, section set and the `_plain()` scrubbing asymmetry (out-of-scope item 5, Q-7). The row *values* for BC-1 … BC-5 do change; see R1 in `## Residuals travelling`.
- A findings-derived exit status for `sc status` (Q-10); any Clash API endpoint as an egress source, and any new endpoint call including `/proxies/:name/delay` (Q-4).
- A committed test harness or a new `verify_all` step (R-9); the pre-existing `capture_output=` 3.6 violations; R-12, R-15, R-16, R-19, R-21.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V1 | AST-extract `_egress_ip` from the HEAD clone and from the candidate `bin/sc`; sha256 both. Read the diff for `:2237` and `:2520`. | Digests equal; neither call site appears in the diff. | AC-S1 |
| V2 | Read the whole diff; count occurrences of `"PUT"`, `"PATCH"`, `"DELETE"` and of `except` in `bin/sc` at HEAD and at the candidate. | Diff touches only the import block and `clash_api()`'s body; method-literal counts identical; `except` count in `bin/sc` unchanged (one clause rewritten, none added). | AC-S2 |
| V3 | Direct-call totality: import the candidate per NFR-3's recipe, point `sc.CLASH_PORT` at a stand-in port, call `sc.clash_api("GET", "/configs")` once per state BC-1 … BC-8 and record `type(...)` and the value. | BC-1…BC-7 → `None`; BC-8 → `{}`. No exception escapes in any state. | FR-1, FR-2 |
| V4 | `sc status` per state BC-1 … BC-8, in `en` and `zh`, on the candidate **and** on the HEAD clone, with `is_running` forced `True` (K-10) and the language set per K-11. Both streams captured whole. | Candidate: route-mode line is `(unavailable)` / `（不可用）` for BC-1…BC-7 and the real mode for BC-8; one value line per heading; no `Traceback`; exit 0. Control: `Traceback` for BC-1…BC-5, agreement for BC-6…BC-8. | AC-B3, NFR-5 |
| V5 | `sc use <tag>` against the stand-in in BC-5 (non-object body) and in BC-8 (`204`, empty body), candidate and control. | BC-5 → no `Switched to:` line (the run falls through to the restart path); BC-8 → `Switched to:` exactly as at HEAD. `cmd_use` is unedited in the diff. | AC-B5, BC-8 |
| V6 | Call `_doctor_clash()` directly against the stand-in in BC-1 … BC-8, candidate and control; record the returned rows verbatim. | Candidate: BC-1…BC-7 → two rows, `[OK] Clash API: 127.0.0.1:<port>` and `[PROBLEM] Clash API responding`; BC-8 → `[OK]` / `[OK]`. Control: BC-1…BC-5 raise. The delta is reported as an observation, not hidden. | BC-14, R1 |
| V7 | On this host, once, under NFR-3's five preconditions with the mtime+size witness taken before and after: `sudo python3 /home/alan/Programs/singbox-cli/bin/sc status`. Separately, one independent HTTPS query to a *different* public address-echo endpoint in the same minute. Wall clock of the run recorded. | Exactly one line under each heading; the egress line parses as an IP address and equals the independent query's answer; no `Traceback` on either stream; exit 0; witness proves nothing under `/etc/sing-box/**` or `/var/lib/sing-box` was written. | AC-B1, AC-B2 |
| V8 | `sc status` with the public-address endpoint made unresolvable **for the child process only**, in `en` and `zh`. | One localized `(error: {e})` / `（错误：{e}）` line under the egress heading; the four preceding sections already printed; no `Traceback`; exit 0. | AC-B4, BC-9 |
| V9 | Extract `TRANSLATIONS` from HEAD and candidate and compare; report the count of added/changed keys. | Zero added, zero changed — stated explicitly rather than inferred. | AC-S3, Q-9 |
| V10 | `python3 -m py_compile bin/sc`; a 3.6-floor read of the diff; `git diff --name-only` against NFR-2's permitted set; `grep -n 'urllib\.error' bin/sc`; read `docs/dev-map.md:39` and the new `CHANGELOG.md` bullet; `bash .harness/scripts/verify_all.sh`. | Compile passes; no syntax newer than 3.6 and no non-stdlib import; the changed-file set is exactly E1-E7's; `urllib.error` has no remaining reference; both documents carry K-7's and K-8's content; verify_all ends with no FAIL against the 17/0/0/1 baseline. | AC-S4, AC-S5 |

**Stand-in server — required emissions, not an implementation.** One process bound to `127.0.0.1`
on a fixture port that is not the live Clash port, able to produce, one state per run: (a) accept and
never write a byte until the client gives up — this alone yields BC-1, and a stalled sing-box is not
needed; (b) a 2xx with a non-JSON body; (c) a 2xx whose body is not valid UTF-8; (d) a 2xx whose
`Content-Length` exceeds the bytes actually written before close (BC-4); (e) a 2xx whose body is each
of `5`, `"x"`, `[1,2]`, `null` (BC-5); (f) refuse or close on accept, and a not-listening variant
(BC-6); (g) 404 and 500 (BC-7); (h) `204` with no body and a 200 with a zero-length body (BC-8). (c)
and (d) rule out a bare `http.server` handler, so it must write the status line and headers itself.
It must also answer `PUT /proxies/proxy` for V5 — that mutating call goes to the stand-in and never
to the live Clash API (NFR-3).

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| R1 | **Requirement imprecision, found here:** BC-14 calls the non-object case "the one behaviour change T-18 causes outside `sc status` and `sc ls`", but making `clash_api()` total necessarily changes `sc doctor` for BC-1 … BC-4 as well — today those raise inside `_doctor_clash()`, are caught by `cmd_doctor`'s per-section isolation (`bin/sc:2555-2562`), collapse the whole section into one `[UNKNOWN] this check could not run` row (losing the port row) and yield exit status 2; under this design they produce the port row plus `[PROBLEM] Clash API responding` and exit status 1. It cannot be avoided without a caller edit, which AC-S2 forbids, and it moves `sc doctor` *toward* the contract `README.md:268` already publishes (`[UNKNOWN]` never means "the thing being checked is broken"). BC-14 should be widened from BC-5 to BC-1 … BC-5. | `03_GATE_REVIEW.md` (rule on the widening), `06_TEST_REPORT.md` (V6 reports it as an observed change) |
| R2 | The two declined exception shapes (`except Exception`; a leaf-class enumeration) merit a `.harness/rejected-decisions.md` record under rule 25, but `.harness/**` is outside NFR-2's permitted diff, so neither this stage nor the Developer may write it. The reasoning is in `02_RATIONALE.md`. | PM (post-delivery, outside the task diff) |
| R3 | BC-10's observed wall clock (every node accepts and never answers) and V7's wall clock are **measurements**, not criteria; if either is materially longer than 8 s the number is filed as an open pool row rather than fixed here (Q-11). | `06_TEST_REPORT.md`, then PM |
| R4 | AC-S2 says "the six call sites"; there are **five** literal call sites of `clash_api()` in `bin/sc` (`:2026`, `:2148`, `:2230`, `:2503`, `:2580`), which is also the count Q-3 names. `sc ls` reaches the function indirectly through `stored_delays()` (`:2101`), which is presumably the sixth. The criterion is unaffected — "no new handler at any call site" holds over both readings — but the count should be corrected. | `03_GATE_REVIEW.md` |
| R5 | "`import urllib.error` has no remaining reference" is a whole-file property, not a diff property: it must be re-checked by grep against the final file, not inferred from the hunk. | `05_CODE_REVIEW.md` |
| R6 | Q-5's finding that `load_nodes()` belongs in R-29's family (three readers, not two) is already the analyst's; nothing here changes it, and `cmd_status` still tracebacks on a corrupt `nodes.json` (BC-13). | PM (`docs/tasks.md` row for R-29) |

## Partition assignment

**Single-developer mode.** `.harness/agents/dev-*.md` does not exist (`.harness/rules/50-singbox-cli.md`
§ Partitioning states the project deliberately uses one developer), so no partition table is written
and every change ledger row carries the partition `single`.

## Verdict

READY
