# 01 — Requirement Analysis · T-22 `share-url-userinfo-contract`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

A password carried in a share URL's userinfo does not survive into the configuration `sc` emits: tuic
nodes carry an empty password unconditionally, trojan / hysteria2 passwords are cut at their first
colon, and shadowsocks passwords recovered from base64 are percent-decoded a second time — four
parsers, one missing judgment about where a userinfo ends and how it is decoded, and no error
reported anywhere.

## In-scope behaviors

**FR-1** — One userinfo→credential judgment exists in the shipped CLI, and every share-URL parser
that reads a userinfo obtains its credential fields from that one judgment. No parser forms a second
opinion about where the userinfo ends, where a field boundary is, or when percent-decoding applies.

**FR-2** — The judgment splits on the **raw** URI text and percent-decodes **afterwards**, exactly
once per extracted field. A percent-escape therefore never creates, moves, or removes a field
boundary: `%3A` inside a field is a data colon, never a delimiter.

**FR-3** — The userinfo of a share URL is the authority text preceding its **last** `@`; when the
authority contains no `@`, the userinfo is empty. A colon inside a bracketed IPv6 host, and a colon
introducing the port, are never field boundaries of the userinfo.

**FR-4** — For **tuic**, the userinfo is `uuid` `:` `password`, split at its first raw colon; both
fields are percent-decoded once. Every colon after the first belongs to the password. A tuic userinfo
containing no colon yields that whole userinfo as the uuid and an empty password.

**FR-5** — For **trojan** and **hysteria2**, the **entire** userinfo is the password, percent-decoded
once. Every colon it contains is a password byte, not a delimiter.

**FR-6** — For **shadowsocks**, percent-decoding applies only to material taken verbatim from the URI
text; material recovered from base64 is used exactly as decoded. The plaintext arm's `method` is URI
text, so it is decoded once like every other field taken from that text. Which arm a given `ss://`
URL takes (base64 userinfo, base64 whole body, or plaintext userinfo), the `rsplit`-at-last-`@`
tolerance, and the `method` / `password` boundary at the first colon of the decoded userinfo are
unchanged.

**FR-7** — For **vless**, the emitted `uuid` is the first raw colon-delimited field of the userinfo,
percent-decoded once. The whole-userinfo reading of FR-5 is **not** applied to vless.

**FR-8** — The credential a parser produces reaches the emitted configuration document unmodified:
for every supported scheme, the credential string in the document `generate_config()` writes equals
the password the share URL carries, byte for byte, including colons, percent-decoded characters and
non-ASCII characters.

**FR-9** — The change ships with a changelog entry stating which already-stored nodes carry a wrong
credential and that repairing one requires removing it and adding its share link again.

## Out of scope

1. The state-file `encoding=` / non-UTF-8 / non-object defect — owned by **T-23**.
2. The `TRANSLATIONS` missing-`en`-table defect — owned by **T-25**; no key-named string is added here.
3. The override / merge error envelope and its type-mismatch vocabulary — owned by **T-24**.
4. `archive-task.sh`'s dead rotation and rule 70's missing stage-doc boundary rule — owned by **T-27**.
5. A committed test suite, `verify_all` wiring, and `baseline.json` — owned by **T-28**.
6. **R-46** (`SECRET_KEYS` omits inbound TLS key material) — stays filed; see Q-5.
7. `parse_vmess`: its credential comes from a base64 JSON payload with no userinfo; untouched.
8. Detecting or repairing already-stored broken nodes in code; the obligation is documented, not automated (Q-11).
9. Any new rejection, warning, or error path for a userinfo the grammar does not fit (Q-6).
10. Node-tag, fragment, query-parameter, transport and TLS handling in every parser.

## Boundary conditions

**BC-1** — Authority with no `@` (`trojan://host:443`) → userinfo empty → password `""`, tuic uuid
`""`, no exception, and the emitted document is written.

**BC-2** — Userinfo containing an unencoded `@` (`trojan://a@b@host:443`) → the split is at the
**last** `@`, so the password is `a@b`.

**BC-3** — Bracketed IPv6 host (`tuic://uuid:pw@[2001:db8::1]:443`) → server, port, uuid and password
are each unaffected by the colons inside the brackets; the emitted `server` is the address without
its brackets (`2001:db8::1`), exactly as today.

**BC-4** — Password consisting of, beginning with, or ending with a colon (`::`, `:pw`, `pw:`) →
that exact string is the emitted password for trojan / hysteria2, and for tuic every colon after the
first delimiter is retained.

**BC-5** — Userinfo whose first field carries `%3A` (`tuic://a%3Ab:pw@host`) → uuid `a:b`, password
`pw`. The percent-escape does not become a delimiter.

**BC-6** — Password carrying a literal percent sign, encoded `%25` → exactly one decode pass, so
`100%2525` yields `100%25` and `100%25` yields `100%`.

**BC-7** — Password carrying percent-encoded non-ASCII UTF-8 → decoded to the characters it encodes
and emitted as those characters (the document is written with `ensure_ascii=False`).

**BC-8** — Percent-escape that is not valid UTF-8 (`%FF`) → decoded with the replacement character,
lossy and without an exception; a byte sequence that is not valid UTF-8 cannot be represented in the
emitted JSON document at all.

**BC-9** — `ss://` base64 arm whose decoded password contains a literal `%XX` sequence → emitted
verbatim, with no percent-decoding applied (FR-6).

**BC-10** — `ss://` plaintext-userinfo arm whose password contains `%3A` or a literal colon after
the method boundary → method taken from before the first colon, password from everything after it,
then decoded once.

**BC-11** — Userinfo of any length up to what the caller's shell and the JSON writer accept → no cap
is imposed and none is checked; the emitted document carries the whole credential.

**BC-12** — A share URL of an unsupported scheme, or one `urlparse` refuses (invalid IPv6 bracket,
non-numeric port) → the existing failure path and message are unchanged.

## Acceptance criteria

Class **[S]** = verifiable by reading or diffing the shipped artifacts; class **[B]** = verifiable
only by running the software and observing what it emits. Fixture classes referenced below:
`F-a` **raw** colon(s) in the password — for trojan and hysteria2 this class carries all three BC-4
shapes (`::`, `:pw`, `pw:`), so an implementation that keeps only a first / rest pair and rebuilds
`first + ":" + rest` cannot pass it · `F-b` `%3A` in the password · `F-c` `%25` in the password ·
`F-d` percent-encoded non-ASCII password · `F-e` unencoded `@` in the userinfo · `F-f` bracketed
IPv6 host · `F-g` no userinfo · `F-h` ss SIP002 base64-userinfo arm whose password contains `%XX` ·
`F-i` ss legacy whole-body base64 arm · `F-j` ss plaintext-userinfo arm.

Each fixture URL is written per class as explicit text — a raw `:` for `F-a`, a literal `%3A` for
`F-b`, a literal `%2525` for `F-c` — and never by passing the known password through a blanket
`quote()`: that encodes every raw colon to `%3A`, silently turns each `F-a` fixture into an `F-b`
one, greens AC-1 against a truncating parser and erases AC-2's expected mismatch.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | For each of tuic / trojan / hysteria2 × `F-a`…`F-e`: the share URL is built from a known password (and, for tuic, a known uuid), parsed, and emitted by `generate_config()`; the credential in the **document written to the config path in that run** equals the known value under exact string equality **and** equal length, and for tuic the emitted `uuid` equals the known uuid in the same assertion. | [B] | Driven fixture per `docs/dev-map.md`'s neutralisation recipe (all eight path constants repointed, `SB_BIN` a stub, no root); the expected value is the constant the URL was built from, never the parser's own output. |
| AC-2 | The AC-1 procedure run unchanged against **HEAD**'s `bin/sc` reports a mismatch for exactly this set: the five tuic fixtures `F-a`…`F-e`, and the three `F-a` fixtures of trojan and the three of hysteria2. The trojan and hysteria2 `F-b` / `F-c` / `F-d` / `F-e` fixtures match at HEAD **by construction** — a userinfo carrying no raw colon is already read whole there — and that agreement is not evidence of a broken harness. | [B] | Same fixture, second checkout. AC-1 green while any member of the expected-mismatch set also matches at HEAD means the fixture observes nothing: both criteria are void, and the harness is repaired before either result is read. |
| AC-3 | For `F-h`, `F-i`, `F-j` plus one `F-a` and one `F-e` ss fixture: every emitted field equals the value the fixture was constructed from; and for every ss fixture that HEAD parses without raising and whose userinfo contains no `%` anywhere — `method` as well as password, in the URI text as well as in any base64-recovered material — the whole emitted node object is byte-identical to HEAD's. | [B] | Differential run over both checkouts, comparing serialized node objects. |
| AC-4 | For a vless and a vmess corpus covering every transport and TLS flavour, with no `%` anywhere in the userinfo, the emitted node object is byte-identical to HEAD's. | [B] | Same differential harness as AC-3. |
| AC-5 | `tuic://a%3Ab:pw@host:443` emits uuid `a:b` and password `pw`. | [B] | Fixture; the unquote-then-split implementation emits uuid `a` / password `b:pw` and fails here. |
| AC-6 | A trojan and a tuic fixture with password `100%2525` emit `100%25`, and one with `100%25` emits `100%`. | [B] | Fixture; a double-decoding implementation fails the first, a non-decoding one fails the second. |
| AC-7 | `F-f` for trojan / hysteria2 / tuic emits, from `[2001:db8::1]`, the `server` value `2001:db8::1` — the address **without** its brackets, exactly the bytes HEAD emits — plus the correct `server_port` and the correct credential. | [B] | Fixture. The missing brackets are HEAD's host behaviour, which this change does not touch; a stage that files them as a defect is filing against a criterion this row does not make. |
| AC-8 | `F-g` for trojan / hysteria2 / tuic emits `password` `""` (tuic additionally `uuid` `""`), raises no exception, and writes the document. | [B] | Fixture. |
| AC-9 | The shipped file emits no key name inside an outbound that it did not emit before; `SECRET_KEYS` and `VISIBLE_IN_OUTBOUND` are unchanged. | [S] | Diff of the two frozensets plus the emitted-key sweep already used for the visible key set. |
| AC-10 | Exactly one construct in the shipped file states where a userinfo ends, where its field boundary is, and when decoding applies; no parser reads `username` / `password` / a netloc `@`-split anywhere else. | [S] | Static sweep of the `# Share-URL parsers` section for those readings. |
| AC-11 | Every user-facing string in the diff, if any, is an English sentence used as its own key, has a `zh` table entry, and contains neither `失败：` nor a namespaced `x.y` key name. | [S] | Diff read plus a `失败：` grep over the diff. |
| AC-12 | `CHANGELOG.md` names as damaged exactly these already-stored nodes, and no wider set: (a) **every** tuic node — its password is empty whatever its share link carried; (b) trojan and hysteria2 nodes whose password contains a **raw** colon — truncated at that colon; (c) shadowsocks nodes whose **base64-recovered** password contains a `%XX` sequence — altered by a decode that arm never needed; (d) vless and tuic nodes whose id carried a percent-escape — stored still escaped. It states that repairing one is removing the node and adding its share link again, and it claims damage for no other node — specifically not for a colon in a shadowsocks password and not for a percent sign in a trojan / hysteria2 / ss-plaintext password, each of which is stored correctly today. | [S] | Read the entry clause by clause against (a)–(d) and against the two named non-claims. If this change also alters a README sentence, `README.md` and `README.zh-CN.md` carry that same predicate set with no divergence between the two languages. |
| AC-13 | On the owner's live host, a real tuic node re-added after installing the new `bin/sc` authenticates and carries traffic. | [B] | **BLOCKED** — needs root, the installed `/usr/local/bin/sc` and a real credential, all forbidden to every agent here. Recipe: append a row to `.harness/operator-obligations.md` — install the new `bin/sc`, `sc rm` the tuic node, `sc add` its share link, `sc use` it, then confirm egress through it and confirm `sc config` shows a masked (non-absent) password field for that outbound. Never substitute an artifact check for this row (R-31 / R-41 / R-47 / R-52 / R-60 precedent). |
| AC-14 | `sing-box check` accepts the document emitted for every AC-1 fixture. | [B] | Stub-free run where a real `sing-box` is available. **Non-regression only**: the defective implementation also satisfies this criterion, because an empty or truncated password is a well-formed document — it is never evidence for FR-1…FR-8. |
| AC-15 | `.harness/scripts/verify_all` PASSes with no new FAIL or WARN. | [B] | Run at the developer, reviewer and QA stages. |
| AC-16 | A vless fixture whose share link carries a percent-encoded id emits that id decoded: `vless://a%2Db@host:443` emits `uuid` `a-b`. | [B] | Fixture; HEAD emits the still-escaped `a%2Db`, so this is the one criterion that positively observes FR-7's decode half. It is not an AC-1 fixture (so not in AC-2's expected-mismatch set) and not in AC-3 / AC-4's byte-identity corpora, which carry no `%` by construction. |

## Non-functional requirements

1. `bin/sc` stays a single self-contained file with no new import beyond the standard library already
   in use (`install.sh` fetches an enumerated artifact list).
2. Any size budget the design sets is derived from its own element list — one contract construct plus
   the per-parser call sites — and never from a round number (**R-61**).
3. The permitted diff is `bin/sc` + `CHANGELOG.md`; a README statement is added only if this change
   makes an existing README sentence false.
4. No stage prints a real credential byte from the live host into any document; `SECRET_KEYS` /
   `_redact()` is the in-tree vocabulary for what counts as one.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Are nodes re-parsed from a stored share URL, or stored as parsed dicts? | **Stored as already-parsed dicts, and the share URL is never persisted anywhere.** `cmd_add` parses once (`bin/sc:2295`) and appends the resulting outbound object to `nodes.json` (`:2301`, `:2308`); `generate_config()` loads those objects (`:2007-2008`) and `_runtime_overlay()` places them into `outbounds` verbatim (`:1880`). Consequence, **re-add case (the real one)**: a node added before this change keeps its wrong stored password and every regeneration reproduces it exactly, so it is repaired only by removing the node and adding its share link again. Consequence, **regenerate case (counterfactual)**: had the share URL been stored, `sc reload` alone would repair every affected node once the new `bin/sc` is installed, with no user action per node. No migration is expressible: the original password bytes are not on disk. |
| Q-2 | Split-then-unquote, or unquote-then-split? | **Split on the raw URI text, then percent-decode each field exactly once** (FR-2). Decoding first lets `%3A` in a first field forge a delimiter (`tuic://a%3Ab:pw@h` would emit uuid `a`, password `b:pw`), which makes the URL's meaning depend on how its author chose to encode it. The in-repo precedent is `parse_ss`, which splits raw (`bin/sc:717`) and decodes after (`:732`). |
| Q-3 | Is `parse_vless` in the family or adjacent? | **In the family for the decoding half; out of it for the splitting half** (FR-7). Its userinfo carries an identity token, not a password, and a UUID contains no colon — so the truncation this task removes is unobservable there, and the whole-userinfo reading would change the emitted `uuid` for links that work today on an unverified premise about non-UUID ids. Decoding it costs nothing: a legal UUID contains no `%`, so AC-4 requires byte-identity for every `%`-free vless input. Revisit only if a user reports a vless id containing `:` or `%`. |
| Q-4 | `parse_ss` percent-decodes a password recovered from base64. Fix it or freeze it? | **Fix it** (FR-6). It is the same judgment — when decoding applies — so freezing it would leave the one contract self-contradicting on its own reference implementation. It is a behaviour change for ss nodes whose base64 password contains a `%XX` sequence; AC-12's changelog clause covers them, and AC-3 pins every other ss case byte-identical. |
| Q-5 | Is **R-46** carried? | **No — R-46 stays filed.** The pool rule carries it only if the fix touches the credential vocabulary; this change emits no new key inside an outbound and adds no name to `SECRET_KEYS` or `VISIBLE_IN_OUTBOUND` (AC-9 pins both). Should the implementation emit a new outbound key after all, the standing rule in `bin/sc:2965-2967` fires and R-46 is re-examined in the same change. |
| Q-6 | Does a userinfo that does not fit its scheme's grammar become a loud error? | **No new rejection, warning or error path.** After this change a tuic URL with no colon carries no password *in the URL*, so emitting an empty password is a faithful transcription rather than a silent loss; adding a rejection would change `sc add`'s contract and require a new user-facing string, neither of which this task's goal carries. |
| Q-7 | Does a scheme's own share-link specification confirm these grammars? | **Assumed, with the defaults binding**: tuic userinfo is `uuid:password` and hysteria2 / trojan userinfo is wholly the credential. In-repo evidence supports both — `parse_tuic`'s own (dead) branch was written for `uuid:password`, and `parse_trojan` / `parse_hy2` map the userinfo to sing-box's single `password` field — but no scheme specification is in this repo and no agent here may fetch one. Revisit only on a report that a hysteria2 userinfo's colon is a client-side user/password delimiter the emitted document must split. |
| Q-8 | What happens to a percent-escape that is not valid UTF-8? | **Decoded lossily to the replacement character, no exception, no new error path** (BC-8). The emitted document is JSON, so a non-UTF-8 credential is unrepresentable regardless of what the parser does. |
| Q-9 | `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` on this project. | **Schema gap recorded, not worked around**: this document applies the requirement-analyst schema as written and blocks on nothing. This is **R-37**, confirmed here for the eighth time and owned by **T-27**. |
| Q-10 | Does `sing-box check` reject a tuic outbound with an empty password? | **Unverified at this stage, and no criterion depends on it.** AC-1 observes the emitted bytes rather than the checker's verdict, and AC-14 is labelled non-regression precisely because a well-formed document with a wrong credential passes it. |
| Q-11 | Should `sc` detect nodes already stored with a wrong credential? | **No detection in code.** An empty tuic password is detectable but not repairable (Q-1), so a detector could only print a sentence — which needs a new user-facing string and a home in a command whose output layer T-25 and T-26 own. The obligation is discharged by AC-12's changelog clause and AC-13's operator row. |
| Q-12 | Is FR-7's decode half observed by any criterion that runs the software? | **Yes — by AC-16, and by nothing else.** FR-7's split half is pinned by AC-4's byte-identity over `%`-free vless userinfos and by AC-10's static sweep; its decode half was carried by that static sweep alone, which observes the shipped construct rather than an emitted document. AC-16 costs one fixture, changes no other criterion (it belongs to no byte-identity corpus and to no HEAD-mismatch set), and observes behaviour the approved design already produces. |

## Verdict

READY
