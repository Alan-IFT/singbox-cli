# 02 — Rationale · T-22 `share-url-userinfo-contract`

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "Where does a userinfo end?" | `urlparse(...).netloc` + CPython's own `rpartition('@')` | `/usr/lib/python3.12/urllib/parse.py:196`, `:208`, `:442` | **Reuse the stdlib's split point, not its accessors.** The stdlib already ends a userinfo at the last `@` in three independent places, so FR-3 needs no new rule — it needs one site that reads `netloc` and applies it. `.username` / `.password` are *not* reused: they bake in a `partition(':')` (`parse.py:198`) that is right for tuic and wrong for trojan / hysteria2. |
| "Split the raw text, decode afterwards" | `parse_ss` (`bin/sc:717` split, `:732` decode) | `/home/alan/Programs/singbox-cli/bin/sc` | **Reuse as the reference implementation** — Q-2 names it as the in-repo precedent. The new construct generalises exactly this order; `parse_ss` then calls it instead of restating it. |
| Percent-decoding of one field | `urllib.parse.unquote` | stdlib, already imported | Reuse as-is. No new import (NFR-1). |
| "One judgment, many adapters" pattern | `srs_reject_reason(head, size)` + its three adapters; `_drift_state()`; `ipv6_decision()`; `_directive_of()` | `bin/sc:813-825`, `docs/dev-map.md:48-67` | **Reuse the project's own shape**: a pure function whose docstring *is* the contract, with call sites that consume it and never re-derive it. `_userinfo` is the fifth instance of a pattern this repo already enforces ("never form a second opinion" — `docs/dev-map.md:108`, `:154`). |
| Base64 recovery for `ss://` | `_b64dec(s)` | `bin/sc:569-571` | Reuse unchanged; FR-6 changes only whether its **output** is decoded again, not the function. |
| Emitting a credential into the document | `_runtime_overlay()` → `_compose()` → `_write_private()` | `bin/sc:1831` (def; called at `:2032`), `:1489` (def; called at `:2032`), `:477` (def; called at `:2069`) | Reuse untouched. Nothing between the parser and `json.dumps(..., ensure_ascii=False)` re-encodes a credential, so FR-8 costs zero lines and becomes an observation (V-1) rather than an implementation. |
| Test harness for a driven `generate_config()` | The T-13 neutralisation recipe + the eight-constant repoint + the `_init_files()` / `LANG` / `CLASH_PORT` traps | `docs/dev-map.md:116-149`, `.harness/insight-index.md:10`, `:12`, `:19` | Reuse the recipe verbatim (K-16…K-18). Re-inventing it is what produced the live-service incident the index records. |
| A committed suite to run it in | (none — no test directory, `verify_all` B.3 is `SKIP`) | — | Not created here: T-28 owns it, and the `ruleset-unit-tests-in-t02` record in `.harness/rejected-decisions.md` is the standing answer for the same wall hit five times before. The harness design is handed on instead (RT-5). |
| A new module / file / library | (none needed) | — | **No new module, file, class, dependency or config key.** NFR-1 keeps `bin/sc` self-contained and `install.sh` fetches an enumerated artifact list. |

## Smaller alternative rejected

**The smaller design: five local fixes, no new construct.** It is genuinely smaller — about six changed
lines, zero added functions, no new name for any reader to learn:

- `parse_tuic`: `uuid = unquote(p.username or ""); password = unquote(p.password or "")` — this alone
  satisfies FR-4, BC-5 and AC-5, because CPython's `.username` / `.password` split the raw userinfo at
  its first colon *before* any decoding (`parse.py:198`).
- `parse_trojan` / `parse_hy2`: `unquote(p.netloc.rpartition("@")[0])`.
- `parse_vless`: `unquote(p.username or "")`.
- `parse_ss`: move the existing `unquote` from the shared tail into the plaintext arm.

Under rule 85's 「少就是多」 the burden of proof is therefore on the design that shipped. Three things
the extra ~13 lines buy, in decreasing order of force:

1. **It satisfies a stated requirement the smaller one fails.** FR-1 and AC-10 demand *exactly one*
   construct stating where a userinfo ends, where its field boundary is and when decoding applies, and
   AC-10 is a static sweep. The five-fix version ships **three** different idioms across five sites
   (`.username` alone, `.username`+`.password`, `netloc.rpartition`), each an independent opinion. Rule
   85's tie-break applies *between designs that satisfy the same requirement*; this one does not, so
   the comparison is not a tie to break. (Had FR-1 not existed, this alternative would win.)
2. **It removes the premise that caused the bug, rather than fixing its instances.** The defect was
   never "tuic forgot to split"; it was that `p.username` silently means *first field of the userinfo*
   in a file where two parsers used it to mean *the password*. The five-fix version keeps that hidden
   stdlib premise load-bearing at four sites — `docs/dev-map.md:113`-style knowledge that a reader must
   already have — and the sixth parser someone adds picks whichever reading they remember. `_userinfo`
   makes the reading un-guessable: one name, one docstring, one return order, and the emitted grammar
   per scheme becomes visibly a choice of *which projection*, side by side in five two-line call sites.
3. **The deletion test passes.** Delete `_userinfo` and the complexity reappears at five call sites, in
   three idioms, with the split/decode ordering restated each time — that is the opposite of the
   pass-through the `shared-singbox-check-wrapper` record declined. Named future edit it prevents
   (rule 85's counter-rule requires one): the next scheme with a userinfo — anything from the v2rayN
   roadmap `CONTEXT.md:165` points at, e.g. `anytls://`, `socks://`, `http://` — lands as one call and
   a projection choice, not as a fourth grammar plus a fourth chance to re-truncate.

**Cost honestly counted:** one new name and one return order for every future reader; two extra
`unquote` calls per parse (the projections a call site discards) on a path that runs once per
`sc add`; and one redundant `rpartition` in `parse_ss`, which computes the same last-`@` split the
construct does. All three were accepted; the last one is discussed under RS-2 below.

**Also rejected, as *larger*:**

- A per-scheme grammar table (`{"tuic": ("uuid", "password"), "trojan": ("password",), ...}`) driving a
  generic splitter. It is data-over-machinery in form only: five schemes with four distinct shapes
  means the table has one row per parser and buys nothing a projection choice does not, while adding a
  registry that the parsers must stay in sync with. Speculative generality, forbidden by rule 85's
  counter-rule.
- A `mode=` / `whole=True` parameter on one function instead of three returned projections. This is the
  mode-flag zoo the dispatch warns about, and it inverts the readability: the call site would state
  *how to parse* instead of *which field it wants*. The three-value return is not a flag — it is one
  computation with three named projections, and the caller's choice is visible in its own unpacking.
- A new module / file for URL parsing. Forbidden by NFR-1 and by `docs/dev-map.md:111`.

## Why three projections and not two

`whole` is **not** derivable from `(first, rest)`: a userinfo of `pw:` and one of `pw` both yield
`first="pw", rest=""`, while BC-4 requires trojan to emit `pw:` for the first and `pw` for the second.
Reconstructing `first + ":" + rest` is correct only when a raw colon was present, so a two-value return
would need a fourth thing — a "had a colon" flag — which is strictly worse than returning the value it
would be used to rebuild. Conversely `first` and `rest` are not derivable from `whole` after decoding,
because decoding is not length-preserving and a decoded `%3A` is indistinguishable from a delimiter —
which is precisely the bug FR-2 exists to prevent. So each of the three is needed by some parser and
computable from none of the others: three is the minimum, not a convenience.

## FR-3 reconciled with `urlparse` (read from the installed stdlib, not assumed)

Read at `/usr/lib/python3.12/urllib/parse.py`:

- `_userinfo` (`:194-203`) does `netloc.rpartition('@')` — the stdlib **already** ends the userinfo at
  the last `@`, so BC-2 (`trojan://a@b@host:443`) needs no new rule; what it needs is a site that keeps
  the whole of that left part instead of `partition(':')`-ing it (`:198`).
- `_hostinfo` (`:206-217`) takes the host from `netloc.rpartition('@')[2]` and then strips brackets, so
  every colon inside `[2001:db8::1]` is already outside the userinfo (BC-3), and `hostname` lowercases
  while preserving a `%zone` (`:164-173`). This design changes no host byte (K-4).
- `_check_bracketed_netloc` (`:439-454`) again rpartitions at `@` before validating brackets, so `[` /
  `]` **inside** a userinfo are harmless as long as they are balanced; an unbalanced one raises
  `ValueError("Invalid IPv6 URL")` from `urlsplit` (`:512-514`) — pre-existing and covered by BC-12.
- `urlsplit` ends the netloc at the first `/?#` (`:510-520`) and strips tab/newline first (`:497-499`).
  Both are pre-existing exposures of `p.username` and are carried unchanged (design "Out of scope").

Hence: the raw userinfo comes from **`p.netloc`**, not from the raw URL text and not from
`p.username`. Taking it from the raw URL text was considered and rejected — it would need its own
scheme-stripping, its own `/?#` boundary and its own bracket handling, i.e. a second `urlsplit`, which
is a strictly larger design that agrees with the stdlib everywhere it matters.

For `ss://`, `p.netloc` is unavailable by design (`parse_ss` never calls `urlparse`, because the legacy
whole-body base64 form has no parseable authority). The construct is therefore given the `ss://`
**body**, and `body.rpartition("@")[0]` is value-for-value what `body.rsplit("@", 1)[0]` already
computes at `bin/sc:712` — including the tolerance of an `@` inside a `?plugin=` query, which FR-6
pins as unchanged. The construct's input is thus consistently "the authority text", with `p.netloc`
and the `ss://` body as its two adapters.

## `parse_ss`'s three arms — exactly what moves

| arm | lines at HEAD | material | change |
|---|---|---|---|
| SIP002 base64 userinfo | `:713-715` (`try`) | recovered from base64 | **none** in the arm; it stops being percent-decoded because CL-7 removes the shared tail `unquote`. This is the FR-6 / Q-4 behaviour change, scoped to a password whose *decoded* bytes contain `%XX` (BC-9). |
| plaintext userinfo | `:716-717` (`except`) | verbatim URI text | the split moves into `_userinfo(body)`; `method` and `password` are each decoded exactly once (BC-10). `method` is now decoded too — a no-op for every real method name, which contains no `%`, but a real behaviour delta that FR-6 now states and that K-8 (delta 2) and RT-6 carry. A colonless userinfo here also stops raising (K-8 delta 1). |
| legacy whole-body base64 | `:721-725` (`else`) | recovered from base64 | **none** in the arm; same tail removal, same reason. |
| shared tail | `:732` | — | `unquote(password)` deleted (CL-7). |

Why the base64 arms cannot go through the decode: the bytes they produce are already the password. A
`%` in them is a password character that survived a base64 round-trip, and decoding it would silently
mutate a credential the user never percent-encoded — the same class of defect as the truncation this
task removes, in the opposite direction. AC-3 pins every `%`-free ss case byte-identical, which is what
keeps the change scoped to exactly the arm-crossing cases.

## Behaviour deltas enumerated, HEAD versus design

Done exhaustively, one parser at a time, reading `bin/sc:629-788` against CPython's `_userinfo`
property (`parse.py:194-203`). "Stated" = an effect FR-1…FR-8 already asks for; "pre-declared" = an
effect no FR asks for, which RT-6 pins as accepted.

| parser | HEAD | design | delta |
|---|---|---|---|
| `parse_vless` | `p.username`: raw first field, **never decoded**; `None` when the netloc carries no `@` (`parse.py:200-203`) | decoded first field; `""` when no `@` | uuid decoded — **stated** (FR-7, observed by AC-16). `None` → `""` — **pre-declared** (K-9). `vless://@h:443` is `""` at both, because CPython returns `""` (not `None`) once an `@` is present. |
| `parse_trojan`, `parse_hy2` | `unquote(p.username or "")` — the `or ""` already absorbs the no-`@` case | `unquote`d whole userinfo | truncation at a **raw** colon removed — **stated** (FR-5). Every other input is byte-identical, including BC-2's `a@b` (both `rpartition` at the last `@`) and every `%`-only password (one decode at both). This is precisely why AC-2's mismatch set stops at the `F-a` fixtures. |
| `parse_tuic` | `":" in p.username` is structurally dead, so uuid = raw first field, password = `""` always | (first, rest), each decoded once | password populated, uuid decoded — **stated** (FR-4). |
| `parse_ss` SIP002 base64 arm | own colon split (`:715`), then the shared-tail `unquote` (`:732`) | own colon split unchanged, no `unquote` | double-decode removed — **stated** (FR-6, BC-9). |
| `parse_ss` plaintext arm | `userinfo.split(":", 1)` (`:717`) + tail `unquote` on password only | `_userinfo(body)`, both fields decoded once | password: decode count is 1 at both, no delta. `method` now decoded — **pre-declared** (K-8 delta 2; the corrected FR-6 also states it). Colonless userinfo — **including the empty one** (`ss://@h:443`, where HEAD's `"".split(":", 1)` raises the same `ValueError`) — stops raising: that is the *same* delta as a non-empty colonless one, K-8 delta 1, not a fourth. |
| `parse_ss` legacy whole-body arm | own colon split (`:724`), then the shared-tail `unquote` | own colon split unchanged, no `unquote` | double-decode removed — **stated** (FR-6, BC-9). |
| `parse_vmess` | base64 JSON payload, no userinfo | unchanged | none. |
| failure modes, all five parsers | `p.username` cannot raise; `parse_ss`'s two `split` unpacks can | `_userinfo` is total over every `str`, so no call site can raise through it | no parser gains an exception; the only loss is K-8 delta 1. `urlparse`'s own raises (BC-12) are untouched. |

**Three pre-declared deltas, and no fourth.** The gate's independent enumeration (`03_RATIONALE.md`
GF-3) reached the same three; this table is the confirmation it asked for, plus the empty-userinfo ss
case, which is the one candidate a reviewer is likely to surface as a fourth and which folds into K-8
delta 1 by construction.

## Risk analysis

| id | risk | regression it would produce | caught by |
|---|---|---|---|
| RS-1 | Implementer writes `partition('@')` (or `split('@', 1)`) instead of `rpartition` | `trojan://a@b@host` emits password `a` and, worse, `urlparse` still routes the host correctly, so the node *looks* fine and fails to authenticate. | V-5 / AC-7 uses `F-e`; V-1's `F-e` row for trojan and hysteria2; K-1 states it explicitly. |
| RS-2 | The redundant last-`@` split in `parse_ss` (the arm calls `_userinfo(body)` while `:712` also splits) drifts apart in a later edit | Someone "optimises" one of the two and the ss userinfo and hostpart stop describing the same `@`. | V-6's sweep asserts `:712` present **and** unchanged (K-6); the mitigation chosen over removing the redundancy is that `hostpart` is genuinely a different value that the construct must not start returning — widening it to four values to serve one caller was rejected as a larger design. |
| RS-3 | Decoding applied before splitting at any site | `tuic://a%3Ab:pw@h` emits uuid `a` / password `b:pw`; the URL's meaning becomes a function of how its author encoded it. | V-5 / AC-5 is written as exactly this fixture; K-2. |
| RS-4 | Double decoding survives somewhere (e.g. `_userinfo` decodes and a call site decodes again) | `100%2525` → `100%`, and a password containing `%41` silently becomes `A`. | V-5 / AC-6 (both directions: a non-decoding implementation fails the second half); V-6 greps every `unquote` site. |
| RS-5 | The harness passes vacuously — un-neutralised import, unrepointed constant, or `main()` driving `LANG` / `CLASH_PORT` | Worst case it re-execs the installed `sc` against the live service (insight index) or writes the real `/var/lib`; best case a green AC-1 that observed nothing. | **AC-2 is the control, over an enumerated set**: V-1 green while any of the eleven expected-mismatch fixtures *matches* at HEAD voids both. The converse is not a symptom — the trojan / hysteria2 `F-b`…`F-e` fixtures match at HEAD by construction. Plus K-17's post-run assertions on `sc.LANG` / `sc.CLASH_PORT` and K-18's eight-constant containment assertion. Note the LANG trap cannot silently pass *this* task's assertions, because none of them reads rendered text — they read emitted JSON. |
| RS-6 | Baseline and candidate run at different fixture roots (two `mkdtemp`s, or a `git worktree`) | Every AC-3 / AC-4 byte-identity comparison fails on `route.rule_set[].path`, which is emitted verbatim from `RULES_DIR` — a red that has nothing to do with the change and costs a debug cycle. | K-19; V-3 / V-4 compare the *node object*, so even a stray document-level difference cannot masquerade as a credential defect. |
| RS-7 | A fixture credential lands in a tracked non-`.md` file and trips `verify_all` A.1 | The task's own gate turns red on its own test data (`100%2525` is exactly 8 characters). | K-15 (harness outside the worktree, literals ≤7 chars); V-8 runs the gate at three stages. |
| RS-8 | The CHANGELOG says "upgrade and reload" like every previous entry in this file | Users reload, believe they are repaired, and keep a tuic node that still cannot authenticate — the one clause where copying house style produces a false sentence. | K-14 (b) makes the *negative* explicit; V-7 reads the bullet against the three clauses; AC-12. |
| RS-9 | K-8's ss delta is treated as a defect at review and "fixed" with a guard | A special case returns, FR-1 is re-violated, and rule 85's "deleting a special case beats adding a guard" is inverted. | RT-6 pre-declares both deltas; K-8 / K-9 name them as accepted. |
| RS-10 | AC-14 (`sing-box check`) or an artifact check is offered as evidence for AC-13 | The pipeline declares a credential fix verified when nothing authenticated — the exact substitution R-31 / R-41 / R-47 / R-52 / R-60 record five times. | K-20; V-9 is labelled non-regression in the plan itself; V-10 stays an operator row. |
| RS-11 | The harness builds fixture URLs with `urllib.parse.quote(KNOWN_PW)` — the obvious spelling, `safe='/'` by default | Every raw colon becomes `%3A`, the whole `F-a` class collapses into `F-b`, AC-1 goes green **against a truncating parser** and AC-2's red disappears for trojan and hysteria2. The two criteria then agree with each other while observing nothing — the sharpest form of the vacuous green. | K-21 forbids a blanket `quote()` and fixes the per-class text; V-1 and V-5 restate it; V-2's mismatch set is enumerated, so the collapse shows up as a *match inside* the expected set rather than as silence. |
| RS-12 | A call site re-splits a projection (`whole.split(":", 1)`) after `_userinfo` returns | A second field-boundary opinion is back — FR-1 violated, the bug's premise reinstated — while every credential assertion stays green and AC-10's sweep, which listed no colon pattern, passes. | V-6 group (ii) sweeps `partition(':'`, `split(":"` and `rsplit(":"` over the whole parser section with **five** pre-enumerated permitted hits (`:715`, `:720`, `:724`, `:725` at HEAD, plus the one inside `_userinfo`); a sixth fails AC-10 by itself. |

## Evidence

- `.harness/insight-index.md:22` (2026-08-14, `sc-config-show`) already recorded the mechanism:
  `urlparse().username` stops at the first `:`, so `bin/sc:764`'s `if ":" in userinfo` is structurally
  dead and every tuic outbound ever emitted carries `"password": ""`. This design is the fix for the
  insight, and the insight is why AC-2 can be predicted to be red for *every* tuic fixture.
- The complete inventory of userinfo readings in the shipped file, from one grep of `bin/sc`:
  `:637` (vless `p.username`), `:696` (trojan), `:744` (hy2), `:763-768` (tuic), `:717` + `:732` (ss).
  Six readings, five parsers, one construct afterwards. `:575` and `:710` are tag decodes and stay.
- `verify_all` A.1's pattern and its `git grep` scope: `.harness/scripts/verify_all.sh:33-34`.
  `MASK`'s "six `*`, deliberately under A.1's 8-character threshold" (`docs/dev-map.md:67`) is the
  in-repo precedent for K-15's length rule.
- No README sentence claims credential fidelity for share links (grep of `README.md` for
  tuic / password / share-link: `:11`, `:74`, `:288`, `:292-293` — none is falsified by this change),
  so NFR-3's README clause does not fire and the product diff stays `bin/sc` + `CHANGELOG.md`.

## Notes on decisions taken under the owner's standing authority

- **AC-7's wording** ("emits the bracketed address as `server`") is read as *the address given in
  brackets*, i.e. HEAD's `2001:db8::1`, not `[2001:db8::1]`. Changing host emission is outside FR-1…FR-8,
  would alter every IPv6 node's document, and has no acceptance criterion describing the new bytes.
  Recorded as K-4 rather than raised as a stage-1 conflict, because the criterion's own verification
  column is a fixture whose other three expectations (server, port, credential) this reading satisfies.
- **Q-3 is followed, not overridden**: vless takes the decoding half and not the splitting half. The
  design makes that visible — I-2 is the only call site that unpacks the middle projection alone.
- **The construct is named `_userinfo`** rather than `_credentials` or `_userinfo_fields`: it names the
  URI concept exactly, matches the stdlib's own private name for the same thing (a reader who knows
  `parse.py` gains, not loses), and keeps the five call sites two-line. The glossary term travels as
  RT-3 because `CONTEXT.md` is outside the permitted diff.
