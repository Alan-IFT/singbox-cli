# 02 — Solution Design · T-22 `share-url-userinfo-contract`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. `bin/sc` gains **one** function in `# Share-URL parsers` — `_userinfo(authority)` — which is the
   shipped file's only statement of where a userinfo ends, where its field boundary is, and when
   percent-decoding applies; the five parsers that read a userinfo (`parse_vless`, `parse_trojan`,
   `parse_ss`, `parse_hy2`, `parse_tuic`) each hold **no** reading of their own afterwards.
2. Nothing else moves: host/port readings (`p.hostname` / `p.port`), `parse_ss`'s arm selection and
   its last-`@` tolerance, `parse_vmess`, `generate_config()` and the composition layer, the emitted
   key set, `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND`, every user-facing string, and every already-stored
   node.
3. The seam is the **authority text**: a caller hands `_userinfo` the text in which a userinfo may be
   followed by `@` (`p.netloc` for the four `urlparse`-based schemes, the `ss://` body for
   shadowsocks) and gets back three decoded projections — whole / first field / rest — so a
   per-scheme grammar becomes a choice of *which projection to read*, never a second parse.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| CL-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | Add `_userinfo()` immediately above `parse_vless` (`:629`), inside `# Share-URL parsers`. | single-dev |
| CL-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_vless` `:637`: `"uuid": p.username` → the **first** projection of one `_userinfo(p.netloc)` call. Deletes this file's 1st netloc-userinfo reading. | single-dev |
| CL-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_trojan` `:696`: `urllib.parse.unquote(p.username or "")` → the **whole** projection of one `_userinfo(p.netloc)` call. Deletes the 2nd reading. | single-dev |
| CL-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_hy2` `:744`: same replacement as CL-3. Deletes the 3rd reading. | single-dev |
| CL-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_tuic` `:763-768`: the six-line `p.username` / `":" in userinfo` / `unquote` block is **deleted** and replaced by one `_userinfo(p.netloc)` call yielding `uuid` and `password`; `:774-775` (the two dict keys) are untouched. Deletes the 4th reading and the structurally dead branch. | single-dev |
| CL-6 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_ss` `:717` (the `except` arm only): `userinfo.split(":", 1)` → one `_userinfo(body)` call yielding `method` and `password`. Arm selection (`:711`, `:713-716`), `body.rsplit("@", 1)` (`:712`), `hostpart` handling (`:718-720`) and the whole-body base64 arm (`:721-725`) are unchanged. | single-dev |
| CL-7 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `parse_ss` `:732`: `"password": urllib.parse.unquote(password)` → `"password": password`. Deletes the 5th reading — the one that decoded base64-recovered material (FR-6 / Q-4). | single-dev |
| CL-8 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One bullet appended to `### 修复` under `## [Unreleased]`, in Chinese, carrying the four clauses of K-14. No other section touched. | single-dev |
| CL-9 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | One row in `## Reusable utilities` for `_userinfo`, and the `# Share-URL parsers` cell in the sections table amended to name it. Stage-4 duty (the dispatch assigns map upkeep to the Developer); it is a navigation ledger, deliberately outside NFR-3's product diff, and carries no product bytes. | single-dev |
| CL-10 | `/home/alan/Programs/singbox-cli/docs/features/share-url-userinfo-contract/04_DEVELOPMENT.md` | new | The Developer's own stage document (canonical pipeline filename). | single-dev |
| CL-11 | *(schema gap)* | — | `.harness/rules/70-doc-size.md` still declares no `## Stage-doc boundary rule` (R-37, Q-9), so the gated `## Byte-form specification` section cannot match a row and is **absent by construction**, not by omission. Recorded here because no other section of this schema can hold it. T-27 owns the fix. | single-dev |

The AC-1…AC-4 differential harness is **not** in this ledger: K-15 forbids it from landing inside the
repository worktree at all, and T-28 owns a committed suite.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | new module-level function, `bin/sc` `# Share-URL parsers`, above `parse_vless` | `_userinfo(authority) -> (whole, first, rest)` | `authority` is the text in which a userinfo may be followed by `@`. `whole` is that text up to and **excluding its last `@`**, and is `""` when the text carries no `@`. `first` is `whole` up to its first **raw** colon; `rest` is everything after that colon, and is `""` when `whole` carries no raw colon. Each of the three is percent-decoded **exactly once**, and nothing outside them is decoded. Pure — no I/O, no module globals, no `urlparse` call of its own — and **total over every `str`**: it raises for no input. `whole` is not derivable from `(first, rest)` (`pw:` and `pw` both give `("pw", "")`), which is why three values are returned rather than two. |
| I-2 | `parse_vless` | `_, uuid, _ = _userinfo(p.netloc)` → `out["uuid"] = uuid` | The emitted `uuid` is the **first** projection (FR-7): a vless userinfo's first raw colon-delimited field, decoded once. The whole-userinfo reading of FR-5 is not applied here. |
| I-3 | `parse_trojan` | `password, _, _ = _userinfo(p.netloc)` → `out["password"] = password` | The emitted `password` is the **whole** projection (FR-5): every colon in the userinfo is a password byte. |
| I-4 | `parse_hy2` | `password, _, _ = _userinfo(p.netloc)` → `out["password"] = password` | Identical to I-3; hysteria2 and trojan consume the same projection, so they cannot diverge. |
| I-5 | `parse_tuic` | `_, uuid, password = _userinfo(p.netloc)` → `out["uuid"]`, `out["password"]` | The emitted pair is (**first**, **rest**) (FR-4): split at the first raw colon, every later colon belongs to the password, and a colonless userinfo gives that whole userinfo as `uuid` with `password` `""`. |
| I-6 | `parse_ss`, plaintext-userinfo arm (the `except` branch only) | `_, method, password = _userinfo(body)` | Same (**first**, **rest**) projection as I-5, over the `ss://` body: `_userinfo`'s last-`@` rule reproduces `body.rsplit("@", 1)[0]` value-for-value, so the arm's userinfo is unchanged while its decoding now comes from the one construct (FR-6, BC-10). `method` is URI text here, so it is decoded exactly once like every other field taken from that text (K-8 delta 2). Neither base64 arm calls `_userinfo` — material recovered from base64 is used exactly as decoded, and each keeps its own colon split (K-7). |
| I-7 | emitted configuration document (`generate_config()`, unchanged surface) | `nodes.json` outbound object → `_runtime_overlay()` `$replace` → `json.dumps(..., ensure_ascii=False)` → `CFG_PATH` | No code between a parser's return value and the written document re-encodes, truncates or re-splits a credential; FR-8 therefore needs **zero** edits here and is a property to be *observed* (V-1), not implemented. |

## Constraints

**K-1** — The implementer must obtain the raw userinfo inside `_userinfo` from the **last** `@` of the
authority text (`str.rpartition('@')[0]`, which yields `""` when there is no `@`) and from nothing
else; `partition`, `split('@', 1)` and `index('@')` are each wrong for BC-2.

**K-2** — The implementer must split the raw userinfo **before** any decoding and decode each of the
three projections exactly once, so that a `%3A` can never become a field boundary (FR-2, BC-5, AC-5)
and `100%2525` decodes to `100%25` rather than `100%` (BC-6, AC-6).

**K-3** — The implementer must not read `p.username` or `p.password` anywhere in the shipped file:
CPython's `_userinfo` property (`/usr/lib/python3.12/urllib/parse.py:194-203`, same shape on the 3.6
floor) returns `netloc.rpartition('@')[0].partition(':')` — i.e. `.username` silently means *first
field of the userinfo*, which is exactly the hidden premise that produced the tuic empty password and
the trojan truncation.

**K-4** — The implementer must keep `server` and `server_port` coming from `p.hostname` / `p.port`
unchanged; the stdlib takes both from `netloc.rpartition('@')[2]` and strips the IPv6 brackets
(`parse.py:206-217`), so BC-3's bracketed colons are already outside every userinfo and AC-7's `server`
is `2001:db8::1`, unbracketed, exactly the bytes HEAD emits. This design changes no host byte; a
bracketed `server` would be a different task, and no stage files the missing brackets as a defect
(BND-8).

**K-5** — The implementer must pass `p.netloc` (never the URL, never a re-parse) at the four
`urlparse`-based call sites, so `_userinfo` performs no parsing of its own and the harness can call it
on a bare authority string.

**K-6** — The implementer must leave `parse_ss`'s three-arm selection, its `body.rsplit("@", 1)`, its
`hostpart` query-stripping and its `int(port)` byte-for-byte unchanged; that `rsplit` is a split of the
`ss://` **body** (shadowsocks never reaches `urlparse`) and is therefore not the "netloc `@`-split"
AC-10 sweeps for — FR-6 pins it as unchanged, and the sweeper must be told so.

**K-7** — The implementer must not route either base64 arm of `parse_ss` through `_userinfo` or through
any `unquote`, so a base64-recovered password containing `%XX` is emitted verbatim (BC-9); the plaintext
arm is the only ss material taken from URI text. Both base64 arms keep their own colon split
(`decoded.split(":", 1)` at `bin/sc:715`, `method_pwd.split(":", 1)` at `:724`) unchanged — that is a
field boundary over material that was never URI text, so it is not a second opinion under FR-1, it is
pre-enumerated in V-6's sweep, and routing it through `_userinfo` would percent-decode it, which is
exactly BC-9's defect (PQ-3).

**K-8** — The implementer must accept, and the reviewer must not "fix", the **two** pre-declared
behaviour deltas on the ss plaintext arm. *Delta 1*: a colonless plaintext userinfo — including an
empty one (`ss://aes-256-gcm@h:443`, `ss://@h:443`) — today raises `ValueError` out of
`userinfo.split(":", 1)` and reaches the user as `cmd_add`'s untranslated
`Error: not enough values to unpack`; afterwards it yields `method` = that userinfo and `password` `""`,
matching BC-1's and Q-6's stance that a missing field is transcribed rather than rejected. Adding a
guard to preserve the exception is forbidden by rule 85 (deleting a special case beats adding one).
*Delta 2*: that arm's `method` is now percent-decoded, because it is URI text and FR-6 states it — a
no-op for every real method name, and the reason AC-3 / AC-4 byte-identity corpora must exclude `%`
from the **whole** userinfo rather than from the password alone.

**K-9** — The implementer must accept the third pre-declared delta: `vless://host:443` with **no**
userinfo emits `"uuid": ""` instead of HEAD's `"uuid": null`, because `p.username` is `None` there while
`_userinfo` returns `""`; the QA corpus for AC-4 must therefore give **every** vless fixture a uuid, and
a no-userinfo vless link is not a share link.

**K-10** — The implementer must add no new user-facing string, no `TRANSLATIONS` key, no new rejection,
warning or error path, and no new key inside an emitted outbound (Q-5, Q-6, AC-9, AC-11); `SECRET_KEYS`
and `VISIBLE_IN_OUTBOUND` stay byte-identical, so R-46 stays filed.

**K-11** — The implementer must add no import: `urllib.parse` is already imported and
`str.rpartition` / `str.partition` are 3.6-legal, so NFR-1 and the 3.6 floor hold with no new element.

**K-12** — The implementer must hold the diff in `bin/sc` to **≤22 added / ≤11 removed lines across
exactly six hunks**, a budget derived from this design's own element list (one function = signature +
≤6 docstring lines + ≤4 statements + 2 separating blanks = 13; five call sites × ≤2 added = 10;
removals = 1 vless + 1 trojan + 1 hy2 + 6 tuic + 2 ss = 11) and from no round number (NFR-2 / R-61).

**K-13** — The implementer must write `_userinfo`'s docstring as the contract itself — the last-`@`
rule, the first-raw-colon rule, the decode-once rule, the return order, and the no-second-opinion
sentence — following `srs_reject_reason`'s precedent at `bin/sc:813-825`. That sentence must be
**scoped to material taken from URI text**: no other site may restate these rules *for text that came
out of a URI*. Unscoped ("no other site in the file may restate any of them") it is falsified on
arrival by `parse_ss`'s two base64 arms, which split base64-**recovered** material at a colon
(`bin/sc:715`, `:724`) and which FR-6 / K-7 deliberately keep — a shipped file must not carry a claim
its own code contradicts.

**K-14** — The implementer must write the `CHANGELOG.md` bullet in **Chinese** (the file's language and
`00-core.md`'s human-facing arm) carrying four clauses. **(a) The damaged set, exactly — four
predicates and no wider claim**: every **tuic** node, whatever its share link carried, holds an empty
password; **trojan** and **hysteria2** nodes whose password contains a **raw** colon are truncated at
that colon; **shadowsocks** nodes whose **base64-recovered** password contains a `%XX` sequence are
altered by a decode that arm never needed; and, optionally, **vless / tuic** ids whose share link
percent-escaped them are stored still escaped. The bullet must **not** claim damage for a colon in a
shadowsocks password, nor for a percent sign in a trojan / hysteria2 / ss-plaintext password: HEAD
splits the ss userinfo at its *first* colon and keeps every later one, and a single `unquote` renders
`%25` correctly, so both are stored **correctly** today and telling their owners to re-add is a false
sentence in the one document its audience cannot check. **(b)** The repair is `sc rm <节点>` followed
by `sc add '<分享链接>'` — `sc reload` **cannot** repair it, because what is stored is the
already-parsed node and the share link is never persisted (Q-1). **(c)** What changed — one reading of
the userinfo, split on the raw text and decoded once, tuic `uuid:password`, trojan / hysteria2
whole-userinfo, shadowsocks base64 material no longer decoded a second time, vless uuid decoded.
**(d)** What did **not** change — vmess, host / port / tag / transport / TLS handling, every command,
every message, and every stored node outside clause (a)'s four predicates. English gloss for the
reviewer, not for the file: *"every tuic node carries an empty password; a trojan or hysteria2 password
containing a literal colon was cut there; a shadowsocks password recovered from base64 that contained
`%XX` was altered; percent-escaped vless / tuic ids were stored still escaped. Remove the node and add
its share link again — a reload cannot repair it. Nothing else is affected."*

**K-15** — Every stage that runs the AC-1…AC-4 harness must create it **outside the repository
worktree** (the agent scratchpad root) and never commit it; the ≤7-character cap on a synthetic
credential literal binds **only text that could become tracked**. `verify_all` A.1
(`.harness/scripts/verify_all.sh:33-34`) is a `git grep` for
`(api[_-]?key|secret|password|token)\s*[:=]\s*["'][^"']{8,}["']` over **tracked** files excluding
`*.md` and `.harness/*`; `MASK`'s six `*` is the in-repo precedent for the 8-character threshold.
AC-6's `100%2525` fixture is exactly 8 characters and is reconciled three ways over, not one: the
harness is untracked and outside the worktree, `*.md` (where the fixture may be quoted in a stage doc)
is excluded, and the pattern needs a bare `password:` / `password=` before the quote, which a
JSON-style `"password": "…"` does not match. The cap therefore constrains any snippet a stage copies
**into** the repo, never the harness itself (PQ-4).

**K-16** — Every stage that runs the harness must neutralise the import exactly as
`docs/dev-map.md:116-149` prescribes — assert `os.geteuid() != 0`, install the `os` shim so
`geteuid()` returns 0, `exec(compile(...))` into a fresh module object, restore `sys.modules["os"]` in
a `finally` — because an un-neutralised import re-execs the **installed** `/usr/local/bin/sc` against
the live service.

**K-17** — The harness must never call `main()` and never call `_init_files()`: `main()` reassigns
`LANG` and `CLASH_PORT` after import (insight index, 2026-08-14 ×2) and `_init_files()` hard-codes
`/var/lib/sing-box` as a `Path` literal (insight index, 2026-08-01), so a fully redirected fixture
still writes the real `/var/lib`. It must instead write `nodes.json` / `settings.json` / `if_inet6`
directly into the fixture root, set `sc.LANG = "en"`, `sc.CLASH_PORT = 29090`,
`sc.SYSTEMD = sc.OPENRC = False`, `sc.SB_BIN = <stub exiting 0>`, record `clash_api_port` in the
fixture's own `settings.json`, and **assert after every run** that `sc.LANG` and `sc.CLASH_PORT` still
hold those values.

**K-18** — The harness must repoint all **eight** path constants (`CFG_DIR`, `CFG_PATH`, `NODES_PATH`,
`SETTINGS_PATH`, `RULES_DIR`, `OVERRIDE_PATH`, `STATE_PATH`, `IF_INET6_PATH`) into one fixture root and
**assert every one of them resolves inside that root** before the first call; it must never write
`/etc/sing-box/` or `/var/lib/sing-box`, never invoke `systemctl` / `rc-service`, and never touch the
live service.

**K-19** — The harness must obtain its pristine baseline with `git clone` into a temp directory (never
`git worktree`), and must run baseline and candidate **at the same fixture root path**, in separate
processes, sequentially, capturing `CFG_PATH`'s bytes after each run — `RULES_DIR` is emitted verbatim
into `route.rule_set[].path` (`bin/sc:1884`), so two different fixture roots would make every
byte-identity comparison (AC-3, AC-4) fail for a reason that is not the change. Between runs it must
rewrite `nodes.json` / `settings.json` and delete `STATE_PATH` (`.config.sha256`) rather than move the
root: leftover state changes only stderr (a drift warning), never the emitted document (PQ-6).

**K-20** — No stage may print a real credential byte from the live host into any document, and no stage
may substitute an artifact check for AC-13 (R-31 / R-41 / R-47 / R-52 / R-60 precedent); AC-14 must be
labelled non-regression wherever it is reported, because a well-formed document with a wrong credential
passes `sing-box check`.

**K-21** — Every stage that builds a fixture URL must write its userinfo as **explicit text per fixture
class** — a raw `:` for `F-a`, a literal `%3A` for `F-b`, a literal `%2525` for `F-c`, explicit `%XX`
escapes for `F-d`, a raw `@` for `F-e` — and must never pass a known credential through a blanket
`urllib.parse.quote()`. `quote`'s default `safe='/'` percent-encodes a raw colon into `%3A`, which
silently converts every `F-a` fixture into an `F-b` one: AC-1 then goes green against a *truncating*
parser and AC-2's expected mismatch disappears for trojan and hysteria2, so the two criteria agree with
each other while observing nothing. The expected value of every assertion is the constant the URL text
was written to carry, never a value re-derived by encoding it.

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `parse_vmess` (`:650-685`) | Its credential comes from a base64 JSON payload with no userinfo (01 out-of-scope 7); it must appear in the AC-4 differential and in no hunk. |
| `bin/sc` `_q` / `_b64dec` / `_name` / `_attach_transport` / `_attach_tls` (`:565-626`) | Untouched helpers; `_name`'s and `parse_ss`'s fragment `unquote` (`:575`, `:710`) decode a **tag**, not a userinfo, and are not readings AC-10 sweeps for. |
| `bin/sc` `parse_ss` `:711-716`, `:718-725`, `:730` | Arm selection, last-`@` tolerance, `hostpart` handling and `int(port)` — pinned unchanged by FR-6 (K-6, K-7). |
| `bin/sc` `p.hostname` / `p.port` readings (`:634-636`, `:693-695`, `:741-743`, `:771-773`) | Host, port and tag are out of scope (01 out-of-scope 10); K-4. |
| `bin/sc` `MASK` / `VISIBLE_IN_OUTBOUND` / `SECRET_KEYS` / `_redact` | AC-9 pins both frozensets; Q-5 keeps R-46 filed on that condition. |
| `bin/sc` `TRANSLATIONS` / `t()` | No new user-facing string (K-10); the missing `en` table is T-25's. |
| `bin/sc` `# Config composition` + `generate_config()` + `_runtime_overlay()` + `CONFIG_BASE` | FR-8 already holds through them (I-7); an edit here would be a second opinion about what `sc` emits. |
| `bin/sc` `cmd_add` / `load_nodes` / `save_nodes` / `_write_private` | Q-1: no migration and no detection of already-stored broken nodes is expressible; storage shape is unchanged. |
| `install.sh`, `uninstall.sh`, `systemd/`, `README.md`, `README.zh-CN.md` | NFR-3; no existing README sentence becomes false (grep of `README.md` for tuic / password / share-link claims found none about credential fidelity). |
| `.harness/**`, `docs/tasks.md`, `docs/features/_archived/**` | Outside the permitted diff; the three records this task generates travel as residuals (RT-1…RT-3), as T-18 and T-19 did. |
| `/etc/sing-box/**`, `/var/lib/sing-box/**`, the running `sing-box` service, `/usr/local/bin/sc` | Live host state; K-16, K-17, K-18. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | CL-1 | `bin/sc` at HEAD; `python3 -m py_compile bin/sc` passes. | Delete the function — it has no caller yet, so the file is HEAD-equivalent. |
| 2 | CL-5 | CL-1 present. Highest-value site: it removes the structurally dead `":" in userinfo` branch, and tuic is the one scheme whose **whole** `F-a`…`F-e` row sits in AC-2's expected-mismatch set. | `git checkout -- bin/sc` (CL-1 is re-applied from the design). |
| 3 | CL-3, CL-4 | CL-1 present. Both consume the identical projection, so they are one edit in two places and must not diverge. | as above |
| 4 | CL-2 | CL-1 present. Do **not** apply FR-5's whole-userinfo reading here (Q-3). | as above |
| 5 | CL-6, CL-7 | CL-1 present; CL-7 must land in the same commit as CL-6 — CL-6 alone would double-decode the plaintext arm, and CL-7 alone would stop decoding it entirely. | as above |
| 6 | V-1…V-7 (Verification plan) | Steps 1-5 complete; harness built per K-15…K-21. | AC-2 is a control over an **enumerated** set (V-2): a mismatch *inside* that set is the control working, and the trojan / hysteria2 `F-b`…`F-e` fixtures agreeing with HEAD is likewise expected. Only a **match inside** the expected set, or a **mismatch outside** it, indicts the harness — and then the harness is repaired before any AC-1 result is read. Neither symptom is ever grounds to change `bin/sc`, and no stage goes hunting a product fault this row does not describe. |
| 7 | CL-8 | Behaviour final, so the bullet describes what shipped. | Revert the bullet; `## [Unreleased]` is not yet released, so no user sees a retraction. |
| 8 | CL-9, CL-10 | Code and changelog final. | Revert the row. |

**Data migration: none, and none is expressible.** Q-1 is binding — `cmd_add` stores the already-parsed
outbound and the share URL is never persisted, so the original password bytes are not on disk and no
code can recover them. Every already-stored node keeps its wrong credential until the user removes it
and adds its share link again; that obligation ships as the CHANGELOG clause (K-14 b) and as AC-13's
operator row (RT-1). **No feature flag, no compatibility shim, no version gate**: the change is
confined to how a share link is read at `sc add` time, so a host that never adds a node is unaffected
and `sc reload` on an untouched host emits the same bytes it emitted before.

## Out of scope

- Detecting, listing or repairing already-stored broken nodes in code (Q-11) — the obligation is
  documented, never automated.
- Any new rejection, warning or error path for a userinfo the grammar does not fit (Q-6); K-8's delta 1
  is the removal of an incidental exception, not the addition of one.
- The state-file `encoding=` / non-UTF-8 / non-object defect (T-23), the override error envelope
  (T-24), the `TRANSLATIONS` missing-`en` defect (T-25), `archive-task.sh` + rule 70's boundary rule
  (T-27), and a committed test suite with `verify_all` wiring and `baseline.json` (T-28).
- R-46 (`SECRET_KEYS` omits inbound TLS key material) — stays filed; this design emits no new outbound
  key and touches no name in either frozenset (K-10), so the Q-5 condition that would re-open it does
  not fire.
- `parse_vmess`, node tags, fragments, query parameters, transport and TLS handling in every parser.
- Host and port emission, including whether an IPv6 `server` should carry brackets (K-4).
- Percent-decoding of anything that is not a userinfo field — the tag `unquote` at `:575` and `:710`
  stays exactly as it is.
- Behaviour for a raw `?`, `#` or `/` inside a userinfo: `urlsplit` ends the netloc at the first of
  them (`/usr/lib/python3.12/urllib/parse.py:510-520`), so such a byte must be percent-encoded to
  survive. Unchanged from HEAD, which had the identical exposure through `p.username`.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | Driven fixture per K-15…K-21: for tuic × `F-a`…`F-e` and for trojan and hysteria2 × `F-a`…`F-e` where `F-a` is **three** fixtures (BC-4's `::`, `:pw`, `pw:`) — 19 fixtures — build the URL, `parse_share_url` it, write it as the single node of the fixture `nodes.json`, call `generate_config()`, then read the document **from `CFG_PATH` in that run** and locate the outbound by tag. Each URL's userinfo is **written per class as explicit text** (K-21): a raw `:` for `F-a`, a literal `%3A` for `F-b`, a literal `%2525` for `F-c`, explicit `%XX` escapes for `F-d`, a raw `@` for `F-e`. | `node["password"] == KNOWN_PW` **and** `len(node["password"]) == len(KNOWN_PW)`, and for tuic `node["uuid"] == KNOWN_UUID` in the same assertion. Expected values come from the constants the URL text was written to carry, never from the parser. | AC-1, FR-8 |
| V-2 | The V-1 procedure, byte-identical, against a **pristine `git clone` of HEAD** at the same fixture root (K-19). | Mismatch for exactly the **eleven** fixtures of AC-2's expected set: the five tuic `F-a`…`F-e`, the three trojan `F-a` and the three hysteria2 `F-a`. The trojan and hysteria2 `F-b` / `F-c` / `F-d` / `F-e` fixtures **match at HEAD by construction** — their userinfo carries no *raw* colon, so `p.username` is the whole userinfo and HEAD's single `unquote` already gives the right answer — and that agreement is the expected reading, never a symptom. Void condition: V-1 green while **any member of the expected-mismatch set also matches at HEAD**, or a mismatch **outside** that set — either means the fixture observes something other than the change, and both V-1 and V-2 are void until the harness is repaired. | AC-2 |
| V-3 | Differential over both checkouts for `F-h`, `F-i`, `F-j` plus one `F-a` and one `F-e` ss fixture: compare `json.dumps(node, ensure_ascii=False)` of the emitted node object. | Each field equals the value the fixture was constructed from; and for every ss fixture whose userinfo carries no `%` **anywhere** — in `method` as well as in the password, in the URI text as well as in any base64-recovered material (K-8's `method` delta makes the narrower password-only corpus wrong) — the serialized node object is byte-identical to HEAD's. | AC-3, BC-9, BC-10 |
| V-4 | Same differential over a vless + vmess corpus covering every transport (`tcp` / `ws` / `grpc` / `h2` / `http` / `httpupgrade`) and every TLS flavour (`none` / `tls` / `reality`) `_attach_transport` and `_attach_tls` can emit, **every vless fixture carrying a uuid** (K-9), and no `%` anywhere in any userinfo. | Serialized node object byte-identical to HEAD's for every fixture. | AC-4 |
| V-5 | Targeted fixtures, each written as explicit text per K-21: `tuic://a%3Ab:pw@host:443`; trojan + tuic with `100%2525` and with `100%25`; `F-f` bracketed IPv6 for trojan / hysteria2 / tuic; `F-g` no-userinfo for the same three; `vless://a%2Db@host:443`. | uuid `a:b` + password `pw`; `100%25` and `100%` respectively; `server` `2001:db8::1` **unbracketed** (K-4, AC-7), correct `server_port` and correct credential; `password` `""` (tuic also `uuid` `""`), no exception, and the document is written; vless `uuid` `a-b` (HEAD emits `a%2Db`, so this row positively observes FR-7's decode half). | AC-5, AC-6, AC-7, AC-8, AC-16 |
| V-6 | Static sweep of the `# Share-URL parsers` section — from its banner comment to the `# ============ Rule-sets ============` banner (`bin/sc:563-805` at HEAD; both banners move with the inserted function, so the sweep is anchored on them and not on those numbers) — for **two pattern groups**: (i) userinfo-boundary readings `\.username`, `\.password`, `netloc`, `rpartition('@')`, `rsplit("@"`, `unquote`; (ii) field-boundary readings `partition(':'`, `split(":"`, `rsplit(":"`. Plus a diff of the two frozensets and the emitted-key set. | Group (i): exactly one site reads `netloc` and exactly one `@`-partitions it — both inside `_userinfo`; zero `p.username` / `p.password` readings; `unquote` only at the two tag decodes (`:575`, `:710` at HEAD) and inside `_userinfo`; `parse_ss`'s `body.rsplit("@", 1)` present and unchanged (K-6). Group (ii): **exactly five hits, enumerated in advance** — `parse_ss`'s SIP002 base64-userinfo arm `decoded.split(":", 1)` (`:715` at HEAD), its legacy whole-body arm `method_pwd.split(":", 1)` (`:724`), its two `hostpart.rsplit(":", 1)` host/port splits (`:720`, `:725`), and the one inside `_userinfo`. A sixth hit anywhere is an FR-1 violation (a call site re-splitting a projection) and fails AC-10, whatever the credential assertions say. Frozensets unchanged; no new key inside an outbound. | AC-9, AC-10 |
| V-7 | Read `git diff` for user-facing strings, grep it for `失败：`, and read the `CHANGELOG.md` bullet clause by clause against K-14. | Zero new strings, zero `失败：`; the bullet states all four damage predicates of K-14 (a), makes neither of its two named non-claims, and states the remove-and-re-add repair with its `sc reload` negative. | AC-11, AC-12 |
| V-8 | `bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` at the Developer, Code-Reviewer and QA stages (there is no extensionless dispatcher on this host). | PASS with no new FAIL and no new WARN; A.1 still PASS (K-15 keeps every fixture credential out of tracked non-`.md` files). | AC-15 |
| V-9 | `sing-box check` against the document emitted for every V-1 fixture, on a host where a real `sing-box` exists (`SB_BIN` un-stubbed, fixture paths still redirected). | Accepted. **Non-regression only** — HEAD's defective output also passes, so this is never evidence for FR-1…FR-8. | AC-14 |
| V-10 | Operator row appended to `.harness/operator-obligations.md` (RT-1) and executed by the owner on the live host. | Re-added tuic node authenticates and carries traffic; `sc config` shows a masked, **non-absent** password for that outbound. Agent-side substitution is forbidden (K-20). | AC-13 |

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| RT-1 | AC-13's operator row must be appended to `.harness/operator-obligations.md` — install the new `bin/sc`, `sc rm` the tuic node, `sc add` its share link, `sc use` it, confirm egress and a masked non-absent password in `sc config`. `.harness/**` is outside NFR-3's permitted diff, so it is filed by the PM at delivery (T-18 / T-19 precedent). | PM → `07_DELIVERY.md` |
| RT-2 | A `rejected-decisions.md` record `share-url-userinfo-five-local-fixes` must be filed: the smaller five-site fix (see `02_RATIONALE.md` §"Smaller alternative rejected") was weighed under rule 85 and declined because it fails AC-10 and re-creates the divergence that caused this bug. | PM → `.harness/rejected-decisions.md` at delivery |
| RT-3 | `CONTEXT.md` needs the glossary term **userinfo reading** (the one judgment of where a userinfo ends, where its field boundary is and when decoding applies; _Avoid_: credential parsing, userinfo split, auth part). Deferred only because NFR-3 does not permit the file in this diff. | PM → `07_DELIVERY.md` |
| RT-4 | R-37 confirmed for the ninth time: `.harness/rules/70-doc-size.md` has no `## Stage-doc boundary rule`, so this document's gated `## Byte-form specification` section is absent by construction (CL-11). | T-27 |
| RT-5 | The AC-1…AC-4 harness is deliberately uncommitted (K-15); its shape is specified here and must be pasted into `06_TEST_REPORT.md` — **including its per-class fixture-construction block (K-21)**, which is the part a re-implementation is most likely to get wrong — so T-28 inherits a design rather than a blank page; the standing answer of the `ruleset-unit-tests-in-t02` record, now for the sixth time. Any credential literal in that paste is `.md` text and outside A.1's scope (K-15). | QA → `06_TEST_REPORT.md`, then T-28 |
| RT-6 | **Three** pre-declared behaviour deltas beyond FR-1…FR-8's stated effects must be re-confirmed as the **only** ones: K-8 delta 1 (colonless — including empty — plaintext `ss://` userinfo: `ValueError` → `method` = that userinfo, `password` `""`), K-8 delta 2 (ss plaintext `method` now percent-decoded, per the corrected FR-6), and K-9 (`vless://` with no userinfo: `"uuid": null` → `""`). The enumeration behind the number is per parser, HEAD versus design, in `02_RATIONALE.md` §"Behaviour deltas enumerated"; it found no fourth. Consequence carried with the number: AC-3 / AC-4 byte-identity corpora exclude `%` from the **whole** userinfo, not from the password alone. If a reviewer finds a fourth, the design is wrong, not the finding. | `05_CODE_REVIEW.md`, `06_TEST_REPORT.md` |

## Verdict

READY
