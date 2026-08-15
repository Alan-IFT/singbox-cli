> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

# 04 — Development · T-22 `share-url-userinfo-contract`

## Summary

1. `bin/sc` gained one function, `_userinfo(authority) -> (whole, first, rest)` (CL-1), and the five
   parsers that read a userinfo now take their credential fields from it and hold no reading of their
   own (CL-2…CL-7) — 21 added / 11 removed, inside K-12's ≤22 / ≤11 cap (BND-13).
2. The AC-1/AC-2 differential harness was built outside the worktree per K-15…K-21: **19 AC-1
   fixtures built, all 19 green on the candidate, exactly 11 red at HEAD** — the five tuic `F-a`…`F-e`
   plus the three trojan and three hysteria2 `F-a`, i.e. BND-1's set fixture-for-fixture, with no
   match inside it and no mismatch outside it.
3. `CHANGELOG.md` carries K-14's bullet (four damage predicates, neither non-claim, remove-and-re-add
   with its `sc reload` negative), and `docs/dev-map.md` gained the `_userinfo` reusable-utility row.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `_userinfo(authority)` added immediately above `parse_vless`, inside `# Share-URL parsers` — signature + 5 docstring lines + 4 statements (`rpartition("@")[0]` → `partition(":")` → three single `unquote`s) | CL-1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_vless`: `_, uuid, _ = _userinfo(p.netloc)`; `"uuid": p.username` → `"uuid": uuid` (first projection, FR-7) | CL-2 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_trojan`: `password, _, _ = _userinfo(p.netloc)`; `"password": urllib.parse.unquote(p.username or "")` → `"password": password` (whole projection, FR-5) | CL-3 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_hy2`: identical replacement to CL-3, same projection, so the two cannot diverge | CL-4 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_tuic`: the six-line `p.username` / `":" in userinfo` / `unquote` block deleted, replaced by `_, uuid, password = _userinfo(p.netloc)`; the two dict keys untouched | CL-5 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_ss` `except` arm only: `method, password = userinfo.split(":", 1)` → `_, method, password = _userinfo(body)`; arm selection, `body.rsplit("@", 1)`, `hostpart` handling and both base64 arms untouched | CL-6 |
| `/home/alan/Programs/singbox-cli/bin/sc` | `parse_ss` return: `"password": urllib.parse.unquote(password)` → `"password": password` (the 5th reading, the one that decoded base64-recovered material) | CL-7 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one bullet at the head of `## [Unreleased]` → `### 修复`, in Chinese, carrying K-14 (a)–(d); damage predicate (a) ends 「因此存下来的这个节点手里已经没有它的分享链接带来的那份凭据」 — the stored artifact, not a server's response | CL-8 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | `## Reusable utilities` row for `_userinfo`; the `# Share-URL parsers` cell of the sections table now names it | CL-9 |
| `/home/alan/Programs/singbox-cli/docs/features/share-url-userinfo-contract/04_DEVELOPMENT.md` | this document | CL-10 |

Permitted product diff (NFR-3) held: `bin/sc` + `CHANGELOG.md`. `docs/dev-map.md` is the navigation
ledger CL-9 declares as a stage-4 duty outside that product diff; no other tracked file was touched
(`docs/batches/**`, `.harness/**`, `README*.md`, `install.sh` untouched).

Diffstat: `bin/sc` **+21 / −11** across **5** `git diff` hunks. CL-1+CL-2 and CL-4+CL-7 each merge
into one hunk at the default 3 lines of context (the change sites are ≤6 lines apart), so the seven
change sites BND-13 predicts render as five hunks; the binding number is the cap, and it holds.

## verify_all result

```
command: bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh
baseline (before any edit): PASS 17 · WARN 0 · FAIL 0 · SKIP 1
after   (all edits landed, incl. the final CHANGELOG wording): PASS 17 · WARN 0 · FAIL 0 · SKIP 1
delta: 0 new FAIL · 0 new WARN · 0 tests removed · baseline preserved
batch baseline (previous pool close): PASS 17 · WARN 0 · FAIL 0 · SKIP 1 — matched
A.1 (no hardcoded secrets): PASS before and after (BND-9: the harness is untracked and outside the worktree)
B.1 (syntax bin/sc): PASS; python3 -m py_compile bin/sc: OK
SKIP: B.3 lint only, unchanged from baseline
```

## Design drift

None.

Two decisions inside the design's latitude, recorded rather than drifted: (1) the CHANGELOG bullet was
placed **first** under `### 修复` because that section is newest-first at HEAD (the two most recent
fixes sit at its top), and CL-8 fixes the section, not the position; (2) `_userinfo`'s body binds
`dec = urllib.parse.unquote` once rather than spelling the call three times, which keeps the return
statement inside the file's line width and costs one line of the 21 (K-12's element list allows 4
statements); (3) damage predicate (a) is scoped to the stored artifact (「存下来的这个节点手里已经没有
它的分享链接带来的那份凭据」) rather than to what a server does with it — the differential measured the
node object, and AC-13, the only row that could observe authentication against a live server, is
BLOCKED by construction, so the consequence is not asserted.

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| BND-1 | **satisfied** (harness side; AC-2 row is QA's) | 19 AC-1 fixtures built; HEAD red on exactly `t_a t_b t_c t_d t_e j_a1 j_a2 j_a3 y_a1 y_a2 y_a3` = 11; the eight trojan / hysteria2 `F-b`…`F-e` match at HEAD by construction. No match inside the expected set, no mismatch outside it — the control was never used to "fix" `bin/sc`. |
| BND-2 | **discharged** | The shipped bullet names (a) every tuic node's empty password, (b) trojan / hysteria2 passwords containing a **raw** colon, (c) shadowsocks passwords **recovered from base64** containing `%XX`, (d) percent-escaped vless / tuic ids. Every damage predicate is stated about the **stored artifact**, which the differential measured: (a)'s parenthetical reads 「密码整段被丢掉了，因此存下来的这个节点手里已经没有它的分享链接带来的那份凭据」 — the node object on disk holds `password: ""`. It asserts nothing about how a live server responds; AC-13, the row that would establish server-side behaviour, is BLOCKED by construction, so no such consequence is claimed. It makes neither non-claim — it states positively that a colon in an ss password and a percent sign in a trojan / hysteria2 / ss-plaintext password are stored **correctly** today. Repair is `sc rm <节点>` → `sc add '<分享链接>'`, with `sc reload` **修不好**它 and the reason (the parsed node is what is stored; the share link is never persisted). Chinese, per `00-core.md`; no English gloss shipped, so no divergence is possible. No new `t()` key, no new `bin/sc` string, and `失败：` still appears exactly once in `CHANGELOG.md` (`CHANGELOG.md:39`, the pre-existing 0.1.0-era entry) and zero times in this bullet. |
| BND-3 | **observed; disposition owned by QA** | Exactly the three declared deltas appeared in the differential and no fourth: `s_k` (colonless ss plaintext userinfo — HEAD `ValueError: not enough values to unpack`, candidate `method="aes-256-gcm"`, `password=""`), the ss-plaintext `method` decode (no `%`-carrying `method` fixture diverges; the byte-identity corpus excludes `%` from the **whole** userinfo), and `v16`/no-userinfo vless (`"uuid": null` → `""`). Every `%`-free ss and vless/vmess fixture is byte-identical to HEAD. |
| BND-4 | **discharged** | Sweep output below: group (ii) has **exactly five** hits and they are the five pre-enumerated ones. |
| BND-5 | **satisfied** (fixture side; row is QA's) | `F-a` carries all three BC-4 shapes for trojan (`j_a1` `::`, `j_a2` `:pw`, `j_a3` `pw:`) and for hysteria2 (`y_a1..3`); tuic's `F-a` is one fixture (`t_a`, password `p:q`). 19 = 5 + 7 + 7. `j_a3`/`y_a3` (`pw:`) are the shapes a first+rest rebuild cannot emit; both are green on the candidate. |
| BND-6 | **discharged** | Every fixture URL is explicit per-class text: raw `:` (`t_a`, `j_a1..3`, `y_a1..3`, `v11`), literal `%3A` (`t_b`, `j_b`, `y_b`, `x5`), literal `%2525` (`t_c`, `j_c`, `y_c`), explicit `%XX` (`t_d`, `j_d`, `y_d`, `v16`, `s_h`), raw `@` (`t_e`, `j_e`, `y_e`, `s_e`). No `quote()` call exists anywhere in the harness (`grep -c 'quote(' fixtures.py runner.py` = 0); every expected value is the constant the URL text was written to carry. |
| BND-7 | **discharged** | Shipped docstring: *"No other site states any of these rules for a userinfo field taken from URI text."* Scoped to **userinfo fields taken from URI text**, so it is falsified neither by the base64 colon splits (`bin/sc:729`, `:738` after the edit — material that was never URI text) nor by the tag decodes (`:575`, `:724` — URI text, but a tag). |
| BND-8 | **observed; row is QA's** | `x7j` / `x7y` / `x7t` emit `server` `2001:db8::1` **unbracketed** with `server_port` 443 and the correct credential — byte-identical to HEAD's host bytes. Nothing here files the missing brackets as a defect. |
| BND-9 | **discharged** | The harness lives at `/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/t22/`, outside the worktree; `git status --short` shows no harness path; A.1 PASS after every edit. The only ≥8-character credential literal (`100%2525`, AC-6) exists in that untracked harness and in `.md` text, both outside A.1's scope (PQ-6). |
| BND-10 | **discharged** | `v11` = `vless://a:b@h.example:443#v11` — `%`-free, raw colon in the userinfo — emits `uuid` `a` and is byte-identical to HEAD's node object. It is the instrument separating FR-7's first-field reading (`a`) from FR-5's whole-userinfo reading (`a:b`), which AC-16's `v16` alone does not. |
| BND-11 | **discharged** | Group (i): exactly four `p.netloc` argument passes at the call sites (`:644`, `:704`, `:753`, `:778`) plus one application of the last-`@` rule inside `_userinfo` (`:635`), whose parameter is named `authority`; zero `.username` / `.password` reads. Group (ii) run quote-agnostically (`(partition\|split\|rsplit)\(\s*['"]:`), so a single-quoted `split(':', 1)` could not evade it. |
| BND-12 | **discharged — the order, named** | The ss plaintext arm splits at the first colon of the **raw** userinfo and percent-decodes **afterwards**, once per field: `_userinfo(body)` computes `raw = body.rpartition("@")[0]`, then `first, _, rest = raw.partition(":")`, and only then applies `unquote` to each projection. `01` FR-6's "first colon of the *decoded* userinfo" governs the two base64 arms only; for the plaintext arm FR-2 / BC-10 / I-6 / K-2 govern, as the gate adjudicated. Observed by `s_j`/`s_a` (byte-identical to HEAD) and by `x5`-style `%3A` behaviour: a `%3A` in an ss userinfo is a data colon, never the `method` boundary. |
| BND-13 | **discharged** | `git diff --numstat -- bin/sc` = `21  11`. ≤22 added / ≤11 removed across the six named edit locations. The docstring is **5** physical lines (element list would otherwise sum to 23 — the docstring was cut, the cap was not raised). Hunk count is 5, not 7, because git merges adjacent change sites; the seven change sites are all present. |

### AC-10 static sweep (V-6), command and output

Run over the `# Share-URL parsers` section, anchored on its two banner comments (`bin/sc:563-818`
after the insertion), not on line numbers. Script:
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/sweep.sh`

```
S=$(grep -n '^# ============ Share-URL parsers' bin/sc | cut -d: -f1)
E=$(grep -n '^# ============ Rule-sets'          bin/sc | cut -d: -f1)
awk -v s=$S -v e=$E 'NR>=s && NR<=e' bin/sc | grep -n -E '\.username|\.password|netloc|rpartition|rsplit\("@"|unquote'
awk -v s=$S -v e=$E 'NR>=s && NR<=e' bin/sc | grep -n -E "(partition|split|rsplit)\([[:space:]]*['\"]:"
```

```
section: bin/sc:563-818

=== group (i) userinfo-boundary readings ===
bin/sc:575:    return urllib.parse.unquote(frag) if frag else f"{host}:{port}"
bin/sc:635:    raw = authority.rpartition("@")[0]
bin/sc:637:    dec = urllib.parse.unquote
bin/sc:644:    _, uuid, _ = _userinfo(p.netloc)
bin/sc:704:    password, _, _ = _userinfo(p.netloc)
bin/sc:724:        name = urllib.parse.unquote(frag)
bin/sc:726:        userinfo, hostpart = body.rsplit("@", 1)
bin/sc:737:        method_pwd, hostpart = decoded.rsplit("@", 1)
bin/sc:753:    password, _, _ = _userinfo(p.netloc)
bin/sc:778:    _, uuid, password = _userinfo(p.netloc)

=== group (ii) field-boundary readings, quote-agnostic ===
bin/sc:636:    first, _, rest = raw.partition(":")
bin/sc:729:            method, password = decoded.split(":", 1)
bin/sc:734:        host, port = hostpart.rsplit(":", 1)
bin/sc:738:        method, password = method_pwd.split(":", 1)
bin/sc:739:        host, port = hostpart.rsplit(":", 1)

group (ii) hit count: 5
```

Reading, against BND-4's advance enumeration: `:636` is the one inside `_userinfo`; `:729` is the
SIP002 base64-userinfo arm (`:715` at HEAD, survives because CL-6 replaced only the `except` arm);
`:738` is the legacy whole-body arm (`:724` at HEAD); `:734` and `:739` are the two host/port splits
(`:720`, `:725` at HEAD). **No sixth hit.** In group (i): zero `.username` / `.password`; one `netloc`
`@`-partition, inside `_userinfo`; four `p.netloc` argument passes at the call sites; `unquote` only
inside `_userinfo` and at the two tag decodes (`:575`, `:724`); `parse_ss`'s `body.rsplit("@", 1)`
present and unchanged (K-6), and `decoded.rsplit("@", 1)` in the base64 arm likewise untouched.

### AC-9 / AC-11 static checks

```
frozensets touched by the diff (SECRET_KEYS|VISIBLE_IN_OUTBOUND|MASK): (none touched)
new user-facing strings / 失败： in the diff: (none)
emitted outbound key sets over all 50 fixtures — candidate-only: []  head-only: []  (14 keys)
```

### AC-1…AC-8 / AC-16 differential result

Harness per K-15…K-21; baseline is a `git clone` at `51c0f47`, candidate is the working tree, both
driven at the **same** fixture root with `nodes.json` / `settings.json` rewritten and `.config.sha256`
deleted between runs (PQ-7). `generate_config()` is driven directly; `main()` and `_init_files()` are
never called; `sc.LANG` and `sc.CLASH_PORT` are asserted after every one of the 100 runs.

| criterion | result | note |
|---|---|---|
| AC-1 | **PASS 19/19** | Credential read back from the document written to `CFG_PATH` **in that run**, by tag; exact string equality **and** equal length; tuic's `uuid` asserted in the same assertion. |
| AC-2 | **PASS — 11 red at HEAD, exactly BND-1's set** | `t_a t_b t_c t_d t_e j_a1 j_a2 j_a3 y_a1 y_a2 y_a3`. The other 8 match at HEAD by construction. |
| AC-3 | **PASS 6/6** | `s_j` `s_a` `s_e` `s_i` byte-identical to HEAD; `s_h` (base64 password `p%41q`) emits `p%41q` where HEAD emitted `pAq` (BC-9); `s_k` is K-8 delta 1. |
| AC-4 | **PASS 16/16** | 12 vless (6 transports × `none`, plus `tls` ×2 and `reality` ×2, plus `v11`, `v16`) + 4 vmess; every `%`-free fixture byte-identical to HEAD, `v16` the declared AC-16 delta. |
| AC-5 | **PASS** | `x5` = `tuic://a%3Ab:pw@h.example:443` → `uuid` `a:b`, `password` `pw`. |
| AC-6 | **PASS** | `100%2525` → `100%25` (`t_c`, `j_c`, `y_c`); `100%25` → `100%` (`x6j` trojan, `x6t` tuic). |
| AC-7 | **PASS** | `x7j` / `x7y` / `x7t` → `server` `2001:db8::1` unbracketed, `server_port` 443, correct credential. |
| AC-8 | **PASS** | `x8j` / `x8y` / `x8t` → `password` `""` (tuic also `uuid` `""`), no exception, document written (`generate_config()` returned `True`). |
| AC-9 | **PASS** | Frozensets untouched; emitted key set identical to HEAD's over all 50 fixtures. |
| AC-10 | **PASS** | Sweep above; five permitted group-(ii) hits, no sixth. |
| AC-11 | **PASS** | No new user-facing string, no new `t()` key, no `失败：` in the diff. |
| AC-12 | **PASS (developer side)** | The shipped bullet read clause by clause against K-14 (a)–(d); every damage predicate is a claim about the stored node object, none about live-server behaviour (AC-13's territory, BLOCKED here). QA re-reads it at V-7. |
| AC-13 | **BLOCKED by construction** | Needs root, the installed `/usr/local/bin/sc` and a real credential. Recipe (RT-1, for `.harness/operator-obligations.md`): install the new `bin/sc`, `sc rm` the tuic node, `sc add` its share link, `sc use` it, confirm egress through it and a masked **non-absent** password for that outbound in `sc config`. **No artifact check was substituted** (K-20). |
| AC-14 | **not run here** | Needs a real `sing-box` with `SB_BIN` un-stubbed; **non-regression only** wherever it is reported (K-20). QA's V-9. |
| AC-15 | **PASS** | verify_all above. |
| AC-16 | **PASS** | `v16` = `vless://a%2Db@h.example:443` → `uuid` `a-b` (HEAD emits `a%2Db`). |

Live-host isolation held: `/etc/sing-box` mtime `2026-08-11`, `/var/lib/sing-box` mtime `2026-07-30`
— neither touched by any run; no `systemctl` / `rc-service` invocation; no `is-active`; no real
credential byte printed anywhere.

## Open issues for review

- Non-UTF-8 percent-escapes (BC-8) were **not** exercised by a fixture: `%FF` decodes lossily to
  U+FFFD, and a fixture asserting that would be asserting the replacement character rather than the
  credential the URL carries. `unquote`'s `errors='replace'` default (`parse.py:688`) is the evidence
  the gate accepted at dimension 6; QA may want an explicit row.
- BC-11 (no length cap) is unobserved: no fixture carries a long userinfo. Nothing in the change can
  impose a cap — `partition` / `rpartition` / `unquote` are length-agnostic — but it is an assertion
  nobody has made.
- `parse_ss`'s arm selection is decided by a `ValueError` raised **inside** the `try`, not by base64
  validity (see `## Insight to surface`). Out of scope here (K-6 pins it), but it is the next reader's
  trap in that function.
- The harness is uncommitted by design (K-15 / RT-5). Its full listing must reach `06_TEST_REPORT.md`,
  **including the per-class fixture-construction block**; paths are named in `04_RATIONALE.md`.

## Dev-map updates

- `## Reusable utilities` gained a row: *"Where does this share URL's userinfo end, and when is it
  decoded?" → `_userinfo(authority)` → `(whole, first, rest)`* — the last-`@` rule, the first-raw-colon
  rule, decode-exactly-once, why three projections rather than two, the `p.username` prohibition with
  its cause, and the two base64 arms / two tag decodes that are deliberately not it.
- The `# Share-URL parsers` row of the `bin/sc` sections table now names `_userinfo` ahead of the six
  parsers and points at that utilities row.

## Insight to surface

- `parse_ss`'s SIP002 arm is chosen by a `ValueError` from the colon split **inside** its `try`, not by base64 validity — `_b64dec` succeeds on ordinary plaintext method names (`aes-256-gcm` is legal urlsafe-base64 text and `_b64dec` decodes with `errors="replace"`), so a colonless plaintext userinfo reached HEAD's `except` arm and raised a second, uncaught `ValueError` there · evidence: bin/sc:727-730, and the baseline run of `ss://aes-256-gcm@h.example:8388` reporting `ValueError: not enough values to unpack (expected 2, got 1)`

## Verdict

READY FOR REVIEW
