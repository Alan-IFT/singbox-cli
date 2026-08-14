# 06 — Rationale · T-20 `doctor-extended-checks`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## The rig, and why it was rebuilt rather than inherited

Every oracle below is derived from `01`'s acceptance criteria and from `bin/sc` itself. No
assertion, no fixture body and no line number is inherited from `04_DEVELOPMENT.md` (RES-10:
twelve of its citations are stale by +2/+3/+6). `04` was read for the *shipped behaviour claims*
and for P-2/P-3's measured bodies, which V-7's stub bodies must copy rather than invent; the
`docs/dev-map.md` `sys.modules` neutralisation recipe was copied verbatim because the rules forbid
re-inventing it.

Suite: `test/t20/` (gitignored, like the existing `test/step7/`), 14 files, **317 assertions**,
driven by `bash test/t20/run.sh`.

| file | what it owns |
|---|---|
| `qa_harness.py` | the neutralised load, the 8 repointed constants + the inside-the-root assertion, the argv-dispatching `subprocess` stub, the stub Clash server with a request log, the snapshot |
| `t_rulesets.py` | AC-B1, BC-1, BC-2, BC-3, GC-9, the 59/60/61-day threshold boundary |
| `t_drift_ipv6.py` | AC-B2, AC-B3, BC-4…BC-9, GC-7(b), RES-1 |
| `t_clash.py` | AC-B4, AC-B5, AC-B12, BC-10…BC-15, GC-4 (+ the vacuity demonstration) |
| `t_perm.py` | AC-B6, AC-B7, AC-B13, BC-18…BC-21, BC-26/GC-7(a), the mode boundaries |
| `t_healthy.py` | AC-B8/GC-1, AC-S3/FR-12, AC-S8, BC-25, GC-10 |
| `t_zh.py` | AC-B9, BC-24, AC-S5 |
| `t_readonly.py` | AC-B10, AC-B11, AC-S1/GC-5 |
| `t_static.py` | AC-S1…AC-S7, AC-S9, GC-2, GC-3, the frozen set |
| `t_v11.py`, `t_extra.py`, `t_stability.py` | V-11 reproduced, extra adversaries, 10× repeats |

### Safety rails actually held

`assert os.geteuid() != 0` at load; the sudo re-exec never taken; all eight path constants
asserted to resolve inside the `mkdtemp()` root; `main()` never driven; `/usr/local/bin/sc` never
invoked; the `subprocess` stub asserts `argv[0] != "sudo"` and never execs `systemctl`; the only
live-host actions were four read-only `GET`s on `127.0.0.1:29090` (below). Nothing under
`/etc/sing-box` or `/var/lib/sing-box` was written; no credential byte from the live host appears
in any document.

## Fixture traps that bit me, and what they cost

1. **`Fixture.rulesets()` did not clear the directory first**, so BC-1's "absent" case still found
   the file the constructor had written and read `[OK] usable` — a *vacuously passing* fixture in
   the exact direction R-22 warns about. Caught because the assertion demanded the PROBLEM class,
   not merely "no traceback". Fixed by emptying `rules/` at the top of the writer.
2. **The harness randomised `sc.CLASH_PORT` per fixture**, and `generate_config()` embeds the
   module-level port in `experimental.clash_api.external_controller`. V-11's first run therefore
   showed all four pairs differing at identical byte length — a difference with nothing to do with
   the change under test. This is the same class as `04`'s recorded `RULES_DIR` trap; both sides
   now share one root **and** one pinned port. The diff that identified it:
   `-"external_controller": "127.0.0.1:40291"` / `+"external_controller": "127.0.0.1:33609"`.
3. **`umask 002`** leaves `mkdir()` at 0775 and `write_text()` at 0664, both offending
   `_doctor_permissions()`' own predicates. Every fixture normalises to 0755/0600 (and
   `settings.json` to 0644, which is what `save_settings()` really leaves) or the permission
   matrix measures the harness.
4. **`contextlib.redirect_stdout` is not thread-safe** — my first concurrency test swapped the
   global `sys.stdout` in five threads and interleaved the captures. Rewritten as five child
   *processes* against one fixture root.
5. **`AC-B10`'s snapshot compared a root the harness itself had rewritten** between the two
   snapshots (`set_port()` rewrote `settings.json`). The first failure was mine, not the code's.

## GC-1 — the full captures

Candidate, wholly healthy fixture (21 rows, exit 0):

```
[OK] sing-box binary: /tmp/t20qa-f2tcili9/sing-box-stub
[OK] sing-box version: sing-box version 1.13.15 (stub)
[OK] rule-sets: 4/4 usable
[OK] geoip-cn.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-cn.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago
[OK] geosite-private.srs: usable, 203 bytes, 0 seconds ago
[OK] configuration: /tmp/t20qa-f2tcili9/etc-sing-box/config.json
[OK] config drift: matches what sc last generated
[OK] sing-box check: no error reported
[OK] IPv6 (AAAA): AAAA queries are answered empty (setting: off); config.json carries this decision
[OK] service: running (via systemd)
[OK] boot autostart: enabled
[OK] TUN interface: sb-tun
[OK] TUN addresses: 172.19.0.1/30, fdfe:dcba:9876::1/126
[OK] Clash API: 127.0.0.1:39219
[OK] Clash API responding: yes
[OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement); auto-select is on n1
[OK] DNS lookup: api.ipify.org resolved in 0 ms, through the running sing-box
[OK] egress IP: 203.0.113.7
[OK] file permissions: no credential file grants access to group or other, and the directory is not group- or other-writable
```

HEAD (`5bd0eaa`, a **clone**, never a worktree) on the **same fixture root**, same stub, same
`_egress_ip` replacement (16 rows):

```
[OK] sing-box binary: … [OK] sing-box version: …
[OK] rule-sets: 4/4 usable
[OK] geoip-cn.srs: usable, 203 bytes          ← the four .srs rows, without the age
[OK] configuration: … [OK] sing-box check: no error reported
[OK] service: running (via systemd)   [OK] boot autostart: enabled
[OK] TUN interface: sb-tun   [OK] TUN addresses: …
[OK] Clash API: 127.0.0.1:39219   [OK] Clash API responding: yes   [OK] egress IP: 203.0.113.7
```

16 → 21 = **+5**. The added label set computed by difference is exactly
`{config drift, IPv6 (AAAA), node delays, DNS lookup, file permissions}`; every HEAD row's value
is present verbatim in the candidate except the four `.srs` rows, which gained exactly
`, 0 seconds ago` (FR-1's declared change). GC-1(b) is asserted with a token-level path test
(absolute, or containing `/` with a non-numeric component, so `2/2` is a ratio and not a path)
plus a literal test against all eight repointed constants, and a command test over
`` ` ``/`sc update-rules`/`sc reload`/`sc ls`/`sc use`/`chmod`/`run:`.

## GC-4 — the stub server's request log, and the vacuity demonstration

With `sc.SYSTEMD = True` **and** the `subprocess` stub (which returns an object carrying both
`.returncode` and `.stdout` bytes, so `_doctor_run()` still works), the stub server's log for the
AC-B4 / V-12 rig reads:

```
['/configs', '/proxies', '/dns/query?name=api.ipify.org&type=A']
```

The same fixture with the delay-carrying `/proxies` body but **without** `sc.SYSTEMD = True`:

```
row:      [PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed yet or every node is failing; see `sc ls`
stub log: ['/configs', '/dns/query?name=api.ipify.org&type=A']
```

That is F-3/GC-4 reproduced first-hand: without the flag the *control* is indistinguishable from
the *candidate* and no `/proxies` request is ever issued — the whole node-delay matrix would have
been vacuous on both sides. V-8's mirror holds unchanged: with a port nothing listens on (a
witness stub running on a different port), the witness log is `[]`; with no `clash_api_port`
recorded, it is `[]`.

## GC-5 — the four deletion runs, verbatim

```
del _age_text      -> [UNKNOWN] rule-sets: this check could not run: name '_age_text' is not defined
del _drift_state   -> [UNKNOWN] configuration: this check could not run: name '_drift_state' is not defined
del stored_delays  -> [UNKNOWN] Clash API: this check could not run: name 'stored_delays' is not defined
del ipv6_decision  -> [UNKNOWN] IPv6 (AAAA): this check could not run: name 'ipv6_decision' is not defined
```

Each run additionally asserts (a) every *other* section still prints — the 8 remaining
`DOCTOR_SECTIONS` labels, checked by name; (b) the dependent rows are **gone**, not silently `[OK]`
(`config drift` + `sing-box check`; `node delays` + `DNS lookup`; the four `.srs` rows); (c) no
traceback and a normal exit (2). No test asserts an import failure and none asserts merely a
non-zero exit — `cmd_doctor`'s per-section `except Exception` (F-5) makes both unsound.

## GC-9 — the age phrase on a usable, non-stale row

```
[OK] geosite-google.srs: usable, 203 bytes, 0 seconds ago
```

Status, byte count, age, in that order, on a healthy row, with no next step — FR-1's "beside the
status and byte count already there". The clock-skew row (mtime = now + 1 h) reads the same
`0 seconds ago` and is `[OK]`; the no-complete-read rows read
`unreadable, size unavailable, last update unknown` and `missing, size unavailable, last update
unknown` — word form, no digit, never stale.

## The live-host probes (read-only, RES-2)

Four `GET`s on `127.0.0.1:29090`, the persisted port. No write, no service action, no credential
byte.

TTL of `api.ipify.org` across three queries 4–5 s apart: **195 → 190 → 186**, `"Server":"internal"`.
A decrementing TTL is a cache read, not a re-resolution.

Timing, same run: `api.ipify.org` → **4 ms**; `qa-t20-25884.example.com` (never queried) →
**176 ms** with an SOA `Authority` and no `Answer`.

Self-warming, the half CR-3 does not state: one fresh name, queried twice 3 s apart —

```
query 1: 175 ms | authority-TTL=[1800]
query 2:   4 ms | authority-TTL=[1796]
```

So `GET /dns/query` **populates the cache itself**. Every `sc doctor` run warms the exact entry the
next run's DNS row reads, independently of the egress probe; consecutive runs inside the TTL are
guaranteed cache hits, and a negative answer is held for 1800 s on this resolver against the 228 s
positive TTL `04` measured. The row's words stay literally true ("resolved in 4 ms, through the
running sing-box" — the running sing-box did answer), which is why this is a residual and not a
wording defect; but the fact the row exists to establish, *resolution through the tunnel works*, is
not what a 4 ms cache read establishes.

## V-11 reproduced (K-5)

`generate_config()` at HEAD and at the candidate, both sides in **one** `mkdtemp()` root with one
pinned `CLASH_PORT`, four decision states, sha256 of `config.json`:

| state | HEAD | candidate |
|---|---|---|
| `ipv6: off` | `d7347308a3e53cd9…` (6236 B) | `d7347308a3e53cd9…` (6236 B) |
| `ipv6: auto`, no global v6 | `d7347308a3e53cd9…` | `d7347308a3e53cd9…` |
| `ipv6: on` | `fe45a288753f9633…` (6222 B) | `fe45a288753f9633…` |
| `ipv6: auto`, global v6 | `fe45a288753f9633…` | `fe45a288753f9633…` |

Plus the control the comparison needs to be non-vacuous: the suppressing and non-suppressing
documents **do** differ from each other (6236 B vs 6222 B).

## Static reads — anchors re-derived from `bin/sc` (RES-10)

```
_aaaa_rule 1670 · _doctor_rulesets 2489 · _doctor_config 2533 · _doctor_ipv6 2600
_doctor_clash 2712 · _doctor_permissions 2811 · _plain 2402 · cmd_doctor 2922
RULESET_STALE_DAYS 102 · EGRESS_HOST 454 · DOCTOR_EXIT 2398 · DOCTOR_SECTIONS 2896
sanctioned mode reads: [('_doctor_permissions', 'stat', 2831), ('_doctor_permissions', 'lstat', 2853)]
RULESET_STALE_DAYS: defined at [102], read at [2511]
```

These agree with `05_CODE_REVIEW.md`'s corrected coordinates and **not** with `04`'s.

D-4's trap is real and I hit it: a substring grep for `st_size` / `getmtime` returns 4 hits in
`bin/sc`, all prose (3 at HEAD, 1 added by this diff in `_doctor_rulesets`' docstring). The AST
sweep returns **0** attribute/name nodes for either. Likewise `Path.replace` vs `str.replace`: the
naive write-attribute sweep flags `_plain`'s `text.replace("\r", "")`; discriminating on argument
count (2 = `str.replace`) removes the false positive without weakening the sweep.

Frozen set verified by AST equality against HEAD: `_drift_state`, `stored_delays`, `clash_api`,
`is_running`, `_age_text`, `ruleset_state`, `ruleset_states`, `_write_private`, `_status_view`,
`_config_digest`, `_saved_clash_port`, `_doctor_print`, `DOCTOR_EXIT`, `DOCTOR_MARK`,
`DOCTOR_MSG_LINES`, `CRED_MODE`. `ipv6_decision()`'s **code** is identical with the docstring
stripped; only the docstring moved (CR-4), and it now reads "Three callers".

## `verify_all`, verbatim

```
[A.1] PASS  [A.2] PASS  [B.1] Syntax (bin/sc, install.sh, uninstall.sh) PASS
[B.2] install.sh bilingual key parity PASS   [B.3] Lint SKIP
[E.1]…[E.5] PASS   [E.6] Adversarial tests section in completed task reports PASS
[F.1]…[F.6] PASS
=== Summary ===  PASS: 17  WARN: 0  FAIL: 0  SKIP: 1
```

## Stability

The healthy fixture and a broken fixture (stale rule-set + drift + a 0644 backup) were each driven
**10 times**; after normalising the temp root, the port and the measured milliseconds, all 10
reports hash identically, with one exit code (0 / 1) and one row count (21 / 21). The full suite
was then run **3 consecutive times**: 317/317 each round, no file flaked.

## Judgment calls taken under standing authority

1. **`baseline.json` not touched.** `02_SOLUTION_DESIGN.md`'s frozen set pins it ("no new
   `verify_all` step; the count deltas stay at zero"), this project's `verify_all` defines no test
   count (B.3 SKIP), and the file has read `test_count: 0` since 2026-07-31. Raising it would
   record a number no shipped check produces. Recorded, not silently skipped.
2. **The suite lives in `test/t20/`**, which `.gitignore` excludes — the same home as the existing
   `test/step7/`. It is therefore outside AC-S7's tracked diff by construction.
3. **AC-B14 filed as an operator obligation**, id 1 in `.harness/operator-obligations.md` (the file
   did not exist; created with that one row). No weaker artifact check was substituted.
4. **The 60-day boundary was tested at 59/60/61 days**, which no upstream document asked for,
   because a `>=` threshold with a same-`mtime`-derived phrase is exactly where an off-by-one
   makes the number and the verdict disagree. They agree.
5. **`sing-box check`'s absence under an unreadable configuration directory** was checked against
   HEAD before being reported: HEAD does the same (the early return predates this task), so it is
   not a regression and AC-B11's clause is read over `DOCTOR_SECTIONS`' nine labels.

## R-37, seventh confirmation

`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (its headings are
`What this is` / `When to read this` / `Caps` / `Process discipline` / `Adversarial check`). Per
this stage's contract I applied the report schema exactly as written, fitted every required unit
into a declared section, and filed the gap as a `## Defects found` row rather than inventing a
section. Five stages of this task have now filed it.
