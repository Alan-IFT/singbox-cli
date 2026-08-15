> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## Rule 85 — unchanged, and not re-litigated

The architecture is byte-identical in substance to what round 1 approved: `_userinfo(authority) -> (whole, first, rest)` (I-1), five call sites (I-2…I-6), K-12's ≤22 / ≤11 budget, NFR-3's `bin/sc` + `CHANGELOG.md` diff, and the same eleven-row change ledger. Round 1's adjudication stands and is not re-argued here.

The one thing I did check is whether a correction smuggled size in through the criteria: the rework added exactly **one** criterion (AC-16) and **one** resolved question (Q-12), and AC-16 costs one fixture and no code — it observes behaviour I-2 already produces. K-21 and V-6 group (ii) are constraints on the *harness* and the *sweep*, not on the product. No new interface, no new constraint on `bin/sc`'s shape, no new ledger row. The design did not grow.

## How each round-1 finding was tested

I tested the code, not the claim. Every discharge below was re-derived before the corrected text was read as satisfying it.

**GF-1.** I ran all nineteen V-1 fixtures through HEAD by hand. For trojan / hysteria2, `p.username` is `netloc.rpartition('@')[0].partition(':')[0]`, so it truncates only on a **raw** colon: `a%3Ab`, `100%2525`, a percent-encoded non-ASCII password and `a@b` each leave `username` equal to the whole userinfo, and the single `unquote` at `bin/sc:696` / `:744` already yields the value the whole-userinfo reading yields — green at HEAD, as AC-2 now says. The three `F-a` shapes are each red: `::` → `""`, `:pw` → `""`, `pw:` → `"pw"`. All five tuic fixtures are red because `bin/sc:764`'s `if ":" in userinfo` is dead on a colon-free `p.username`, so `password` is `""` for every one of them. Eleven red, eight green, exactly as written. This is a changed instrument, not a re-worded one: the previous text demanded a red that correct code could not produce.

**GF-2.** I walked HEAD once per predicate. (a) tuic: `:763-768`, unconditional `""`. (b) trojan / hysteria2 raw colon: `:696`, `:744`. (c) ss base64-recovered `%XX`: `:715` / `:724` recover, `:732` decodes anyway. (d) vless / tuic escaped ids: `:637` and `:763` read `p.username` with no `unquote`. Both non-claims hold too: an ss password containing a colon is correct today because `:717` splits with `split(":", 1)` and keeps every later colon, and a percent sign in a trojan / hysteria2 / ss-plaintext password is correct today because one `unquote` renders `%25` as `%` and leaves an invalid escape alone. The clause is now narrower than the fix, which is the right direction for a sentence whose audience cannot check it.

**GF-3 / the fourth-delta question.** Re-derived per parser rather than read off `02_RATIONALE.md`'s table — see the next section. Same three, no fourth.

**GF-4.** Group (ii) now exists and its permitted hits are enumerated. The enumeration is where the architect corrected me; see the BND-4 ruling below.

**GF-5.** `pw:` is the discriminator and it is present: a two-value implementation rebuilding `first + ":" + rest` emits `pw` for a password of `pw:` (it passes `::` and `:pw`, which is why one shape was not enough). The class definition and V-1 both carry all three.

**GF-6.** AC-7 now names the unbracketed bytes, which is what `_hostinfo` produces, and it says in-row that a stage filing the missing brackets is filing against a criterion the row does not make.

**GF-7 — discharged with a residual.** K-13's scoping clears `:715` and `:724`. But `_name`'s `unquote(frag)` at `:575` and `parse_ss`'s fragment decode at `:710` are also "text that came out of a URI", and they restate *when decoding applies* for it. The frozen set already says they decode a **tag, not a userinfo**, so the fix is one more word in the scope, not a design change — BND-7 now says "userinfo fields taken from URI text". A shipped docstring is the one place where a claim its own file contradicts is expensive, which is why this got a corrected condition rather than a wave-through.

**GF-8.** K-21, AC-1's preamble, V-1 and V-5 all carry the per-class text, and RS-11 names the exact failure a blanket `quote()` produces. This is the finding whose discharge is most clearly a change in what the criteria can *detect*: with `quote()`, trojan's `pw:` fixture becomes `pw%3A`, HEAD matches, and V-2's void condition ("a match inside the expected set") fires — the collapse is now observable instead of silent.

**GF-9 — discharged with a residual.** AC-16 is correct and discriminating for the decode half: HEAD emits `a%2Db` (`bin/sc:637` has no `unquote`), the design emits `a-b`, and the fixture belongs to no byte-identity corpus (AC-3 / AC-4 exclude `%` anywhere in the userinfo) and to no HEAD-mismatch set (AC-2 covers only tuic / trojan / hysteria2). The residual is the split half: an implementation reading vless's **whole** userinfo also passes AC-16, and AC-4's `%`-free corpus only catches it if some fixture's userinfo carries a raw colon. One fixture (`vless://a:b@host:443`, expected byte-identical to HEAD) closes it — BND-10.

## Ruling on BND-4 — the architect is right, my round-1 enumeration was short by one

Verified first-hand at `bin/sc:711-725`. The SIP002 base64-userinfo arm is

```
try:
    decoded = _b64dec(userinfo)
    method, password = decoded.split(":", 1)      # :715
except Exception:
    method, password = userinfo.split(":", 1)     # :717
```

CL-6 replaces **only** the `except` arm (`:717`), and K-7 pins both base64 colon splits as deliberately kept. So `:715` survives the change and matches group (ii)'s `split(":"` pattern exactly as `:724` does. After the change the parser section carries five colon-splitting sites: `:715`, `:724`, `:720`, `:725` (HEAD numbering) and the one inside `_userinfo`. Round 1's BND-4 listed four and omitted `:715` — an enumeration error that would have produced a spurious FR-1 violation at stage 5 on correct code. The correction is **sustained**; BND-4 is corrected in place, and `02` V-6 already states five. Filing this here in writing follows the T-07 CR-5 precedent: a downstream stage that refutes the gate on the merits wins, and the record says so.

## The fourth behaviour delta — re-derived per parser, not accepted from the table

HEAD versus design, reading `bin/sc:629-788` against `parse.py:194-203`:

- **`parse_vless`** — `p.username` is the raw first field and `None` when the netloc carries no `@`. Design: decoded first field, `""` when no `@`. Deltas: uuid decoded (**stated**, FR-7); `None` → `""` (**pre-declared**, K-9). `vless://@h:443` is `""` under both, because CPython returns `''` once `have_info` is true. No third.
- **`parse_trojan` / `parse_hy2`** — `unquote(p.username or "")`; the `or ""` already absorbs the no-`@` case, and `rpartition` already gives BC-2. The only divergence is a **raw** colon (**stated**, FR-5). Nothing else moves, which is precisely why AC-2's set stops at `F-a`.
- **`parse_tuic`** — HEAD's uuid is the raw first field and its password is `""` always. Design: (first, rest), each decoded once (**stated**, FR-4). Note there is *no* `None` delta here, unlike vless, because `p.username or ""` already normalises it — `01`/`02` are right to attach K-9 to vless alone.
- **`parse_ss` SIP002 base64 arm** — split unchanged at `:715`; loses the shared-tail `unquote` (**stated**, FR-6 / BC-9).
- **`parse_ss` plaintext arm** — password: one decode at HEAD (`:717` split raw, `:732` decode) and one after; no delta. `method` now decoded (**pre-declared**, K-8 delta 2). A colonless userinfo — including the empty one, where HEAD's `"".split(":", 1)` raises the same `ValueError` — stops raising (**pre-declared**, K-8 delta 1). Arm selection is untouched, so a userinfo that HEAD routes to the base64 arm still goes there.
- **`parse_ss` legacy whole-body arm** — split unchanged at `:724`; loses the tail `unquote` (**stated**).
- **`parse_vmess`** — no userinfo, untouched.
- **Failure modes** — `p.username` cannot raise; `_userinfo` is total, so no call site gains a raise, and the only lost exception is K-8 delta 1. `urlparse`'s own raises (BC-12) are untouched.

I also checked the three places a fourth could plausibly hide: an `ss://` body whose last `@` sits in a `?plugin=` tail (`body.rpartition("@")[0]` is value-for-value `body.rsplit("@", 1)[0]`, so no delta), an unencoded `@` in a vless or trojan userinfo (`rpartition` at both ends, no delta), and a userinfo containing an invalid escape such as `%zz` (`unquote` leaves it alone at both ends). **Three deltas, no fourth.**

## Vacuous-green re-test (R-22) on the changed and added criteria

| changed/added | what wrong implementation also passes it | closed by |
|---|---|---|
| AC-2 (set + void condition) | A harness whose expected values come from the parser's own output — every fixture would then match at HEAD, including the eleven, and the void condition fires. A `quote()`-built corpus — trojan's `pw:` matches at HEAD, inside the set, and the void condition fires. | the void condition is the right instrument: "a match **inside** the set, or a mismatch **outside** it" catches both the collapse and the observe-nothing harness, and it cannot be tripped by correct code, because the eight expected-green fixtures are green *by construction* rather than by assumption |
| AC-3 (corpus widened to the whole userinfo, plus "HEAD parses without raising") | An implementation that double-decodes a base64-recovered password still fails `F-h`'s field-equality clause; the byte-identity clause is non-vacuous because I confirmed the two checkouts really do agree on every `%`-free ss input (both split raw at the same colon, and `unquote` is the identity on a `%`-free string) | — |
| AC-7 (unbracketed) | An implementation that breaks the credential still fails the row's credential clause | — |
| AC-12 / K-14 (four predicates, two non-claims) | A changelog copying house style ("upgrade and reload") fails the `sc reload` negative; a wider clause fails the two named non-claims | — |
| AC-16 (new) | A vless implementation reading the **whole** userinfo passes it | **open** → BND-10 |
| V-6 group (ii) (new) | A call site spelled `whole.split(':', 1)` with single quotes passes the sweep | **open** → BND-11 |
| V-6 group (i) (unchanged text, newly load-bearing) | Nothing passes it — the problem is the reverse: a *compliant* implementation fails it, because K-5 puts four `p.netloc` reads at the call sites and I-1 names the parameter `authority`, so "exactly one site reads `netloc`, inside `_userinfo`" is false on arrival | **open** → BND-11 |
| V-1 / K-21 (per-class text) | A harness that builds `F-b` by `quote()`-ing an `F-a` password — but that now shows up as a match inside AC-2's set | — |

## The three new findings, and why none of them is a rollback

**GF-10.** `01` FR-6 ends with "…the `method` / `password` boundary at the first colon of the **decoded** userinfo are unchanged". Read against the base64 arms it is true (`:715` and `:724` split material that *is* the base64-decoded text). Read against the plaintext arm it states decode-then-split — the order FR-2 exists to forbid, and the one that turns `ss://a%3Ab:pw@h:443` into `method` `a` / `password` `b:pw`. Every other governing sentence (FR-2, BC-10, I-6, K-2) says raw-split-then-decode, so this is one ambiguous phrase inside a document whose blanket rule already resolves it. Adjudicated in FR-2's favour under standing authority and bound as BND-12 rather than routed back — a rollback here would buy one word.

**GF-11.** A sweep is only as good as its spelling. Group (i)'s expectation contradicts K-5 (which *requires* `p.netloc` at four call sites) and I-1 (whose parameter is `authority`, so `_userinfo` contains no `netloc` token at all); run literally it goes red on correct code, and the tempting "fix" — re-parsing inside `_userinfo`, or passing `p` — is exactly what K-5 forbids. Group (ii)'s quote-specific patterns miss a single-quoted call-site split, which is the very evasion RS-12 exists to catch. Both are executable-instrument defects, fully repairable by the stage that runs the sweep, so they are bound (BND-11) rather than returned.

**GF-12.** Seven change sites more than six lines apart cannot produce six unified-diff hunks; and 1 signature + 6 docstring + 4 statements + 2 blanks + 5×2 call-site lines is 23, one over the ≤22 cap. Neither makes the design unbuildable — every element is an upper bound and the cap is the binding number — but read literally at stage 5 the hunk count produces a false red on a compliant diff. Bound as BND-13 with the cap kept intact: the docstring gives up a line, the budget does not.

## Verified good — positive statements

- **AC-2 is now a real negative control.** Not "I found nothing wrong": I computed HEAD's output for all nineteen fixtures and the set matches exactly, so the control is red where correct code makes it red and green where correct code makes it green.
- **The damage set is narrower than the fix and provably so.** Seven classes checked; four damaged, three correct-at-HEAD. That asymmetry is the evidence that the clause was derived from HEAD rather than from the shape of the change.
- **The harness constraints remain sufficient.** `docs/dev-map.md:116-149` carries the `os`-shim recipe, the eight-constant repoint (with the containment assertion) and the standing ban on `_init_files()` (`bin/sc:532`'s `/var/lib/sing-box` literal); `verify_all.sh:33-34` is a `git grep` over tracked non-`.md` files with an 8-character threshold, so K-15's reconciliation of the `100%2525` fixture holds three ways over.
- **The changelog target exists.** `CHANGELOG.md` has `## [Unreleased]` with a `### 修复` subsection, so CL-8's precondition is real rather than assumed.
- **No insight-index entry contradicts a design assumption.** The 2026-08-14 `urlparse().username` entry *is* this task's founding fact, and the `_init_files()` / `LANG` / `CLASH_PORT` entries are exactly what K-16…K-18 encode. One nit, non-binding and not a finding: that entry cites the tuic idiom at `bin/sc:713`, which today is the ss base64 split; the live code is at `:763-768`. `01_RATIONALE.md` E-2 already re-derived it against the right lines.
- **Rule 70 still has no `## Stage-doc boundary rule`** (R-37, confirmed again). This document applies the gate-reviewer schema as written and blocks on nothing; the 500-line per-stage-doc cap is what applies and both portions sit well under it.
