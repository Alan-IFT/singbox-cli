# 01 — Rationale · T-22 `share-url-userinfo-contract`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. Evidence — every dispatched fact re-derived first-hand

Read at `bin/sc` on 2026-08-15, and in CPython's `urllib/parse.py` on this host.

| # | claim | verdict | evidence |
|---|---|---|---|
| E-1 | `urlparse().username` stops at the first `:` of the userinfo and is **not** decoded | confirmed | `/usr/lib/python3.12/urllib/parse.py:194-203` — `_userinfo` does `netloc.rpartition('@')` then `userinfo.partition(':')`; `username`/`password` (`:157-162`) return those raw halves. |
| E-2 | `parse_tuic`'s `if ":" in userinfo:` is structurally dead; the `uuid, password = userinfo, ""` arm is the only reachable one | confirmed | `bin/sc:763-768`. `userinfo = p.username or ""` is by construction colon-free, so `"password": ""` (`:775`) is what every tuic outbound carries. |
| E-3 | `parse_trojan` and `parse_hy2` truncate at the first colon | **confirmed, and bounded to a raw colon** | `bin/sc:696` and `bin/sc:744`, both `urllib.parse.unquote(p.username or "")` for schemes whose whole userinfo is the credential. `p.username` is `netloc.rpartition('@')[0].partition(':')[0]` (`/usr/lib/python3.12/urllib/parse.py:194-203`), so the truncation fires only on a **raw** colon: for `a%3Ab`, `a@b`, `100%2525` and a percent-encoded non-ASCII password, `p.username` is the whole userinfo and the single `unquote` already yields the same bytes the whole-userinfo reading yields. That bound is what AC-2's expected-mismatch set and AC-12's damage clause are built on. |
| E-4 | `parse_vless` reads `p.username` as a uuid | confirmed | `bin/sc:637`. |
| E-5 | `parse_ss` splits correctly by hand | **confirmed for the split, refuted for the decode** | `bin/sc:711-725` splits `rsplit("@", 1)` then `split(":", 1)` on raw text — correct. But `:732` applies `unquote(password)` to the value of **all three arms**, including both base64 arms (`:714-715`, `:722-724`), where the material never was percent-encoded. |
| E-6 | Nodes are stored as parsed dicts; the share URL is never persisted | confirmed | `bin/sc:2295` parse → `:2301` append → `:2308` `save_nodes` → `:543-552` writes `nodes.json`. `generate_config()` reads them back (`:2007-2008`) and `_runtime_overlay()` splices them into `outbounds` verbatim (`:1875-1881`). No writer of `nodes.json` stores a URL: `_init_files`, `cmd_add`, `cmd_use`, `cmd_rm`, `generate_config`'s selection repair. |
| E-7 | The emitted document is well-formed either way | consistent with R-42's independent confirmations at T-06 stages 5 and 6 | `bin/sc:2069` writes the composed document before `:2076`'s `sing-box check`; an empty or truncated string is a valid JSON string. Not re-measured here (no Bash, no `sing-box`) — hence Q-10. |
| E-8 | A harness can drive `generate_config()` unprivileged | confirmed | `docs/dev-map.md:112-149` — the T-13 `os`-shim recipe, all eight repointable path constants, `SB_BIN` repointable to a stub, and the standing ban on driving `_init_files()` (its `/var/lib/sing-box` literal, `bin/sc:532`). This is why AC-1 is not BLOCKED. |
| E-9 | A new user-facing string needs an English key plus a `zh` entry | confirmed | `bin/sc:129-139` — English source strings are the keys, `TRANSLATIONS["zh"]` is the only table. `失败：` is produced by the key `"failed: {e}"` at `bin/sc:213`. |

## 2. Goal-sentence clauses refuted

1. **"`parse_ss` already does it correctly by hand."** Half true, and the false half is load-bearing:
   `parse_ss` is the reference for *where to split* and the counter-example for *when to decode*. Both
   base64 arms hand a password to `unquote()` at `bin/sc:732`, so an ss password containing a literal
   `%XX` sequence — exactly the password a user base64-encodes it to protect — is silently altered.
   The dispatch told me to treat `parse_ss` as the case not to regress; a case it already gets wrong
   is not one of those, so FR-6 fixes it rather than freezing it.
2. **"four call sites and three wrong ones."** There are **five** userinfo readers (`parse_vless`,
   `parse_trojan`, `parse_ss`, `parse_hy2`, `parse_tuic`) and **four** of them are wrong in some
   reachable input class once the decode half is counted. The count in the goal sentence undercounts
   the family by one and misplaces the correct member.
3. Not refuted, sharpened: "ships `"password": ""` on every node" is true of every **tuic** outbound
   specifically, which is what R-42 states.

## 3. Related prior work (links, not re-descriptions)

- **R-42**, `docs/tasks.md` T-06 block — the row this task closes. Its own citations (`bin/sc:713`,
  `:724`) are pre-refactor line numbers; the same code is at `:763-768` / `:775` today, which is why
  the contract anchors to behaviour and interfaces rather than lines.
- **T-06 `sc-config-show`**, `docs/features/_archived/sc-config-show/` — discovered R-42 while
  building a six-scheme fixture (`04_DEVELOPMENT.md:135`, `05_RATIONALE.md:54`); its
  `06_TEST_REPORT.md:28` documents the 13-share-link sweep AC-3 / AC-4 can be built from. It also
  fixed `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND` as the credential vocabulary (Q-5) and the standing
  rule that a new outbound key must be added to the visible set in the same change (`bin/sc:2965`).
- **T-15's R-22(a)** and **T-06's stage-3 pair of mutually-agreeing useless criteria** — the reason
  §4 exists.
- **T-13's `01_REQUIREMENT_ANALYSIS.md`** (credential document) and `.harness/rejected-decisions.md`
  § `unredacted-config-output-or-an-opt-out-flag` — the standing rule that credential bytes never
  widen, which is why AC-13 is an operator row rather than a pipeline run.
- `.harness/rejected-decisions.md` holds no record about share-URL parsing; nothing here re-litigates
  a prior decline.
- `CONTEXT.md` needs no new term: "credential document", "visible key set" and "mask" already cover
  this task's vocabulary, and "userinfo" is RFC-3986's word, not a project coinage.

## 4. Anti-vacuity — what wrong implementation also passes each criterion

The trap named in the dispatch is real and cheap to fall into: *"the parser returns a non-empty
password"* is satisfied by a parser that returns the **uuid** as the password. Each criterion was
therefore written against a specific wrong implementation.

| wrong implementation | which criterion kills it |
|---|---|
| returns the whole userinfo as the tuic password (uuid included) | AC-1 — one assertion covers uuid *and* password, so an implementation that moves bytes between the two fields fails. |
| returns a non-empty but wrong password | AC-1 — the expected value is the constant the fixture URL was built from, never the parser's own output. |
| decodes first, then splits | AC-5 (`a%3Ab:pw`) — the only case where the two orders disagree. |
| decodes twice (the current ss base64 arm's shape, generalised) | AC-6's `100%2525` half. |
| never decodes at all | AC-6's `100%25` half, plus `F-b`/`F-d` in AC-1. |
| splits the netloc at the *first* `@` or the *first* `:` | AC-7 (bracketed IPv6) and BC-2's `F-e` fixture in AC-1. |
| fixes tuic only and leaves trojan / hysteria2 truncating | AC-1 iterates all three schemes. |
| fixes the parsers but the value is lost downstream | AC-1 reads the **document written in that run**, not the parser's return value. |
| returns only a (first, rest) pair and rebuilds the whole userinfo as `first + ":" + rest` | AC-1's `F-a` class carries all three BC-4 shapes for trojan and hysteria2 — such an implementation emits `pw` for a password of `pw:` and `:` for `::`. |
| the fixture itself observes nothing (wrong path, stale file, unreached assert) | AC-2 — the same procedure must **fail** on HEAD for every member of its expected-mismatch set (the five tuic fixtures and the six trojan / hysteria2 `F-a` ones). AC-1 green while any member of that set also matches at HEAD voids both. |
| the harness builds every URL with a blanket `quote(known_password)` | AC-1's construction rule — each class is written as explicit text, because `quote`'s default `safe='/'` encodes `:` to `%3A`, converts every `F-a` fixture into an `F-b` one, and thereby greens AC-1 against a truncating parser while erasing AC-2's mismatch. |
| regresses ss or vless while fixing the rest | AC-3 / AC-4 differential byte-identity. |
| emits a well-formed document with the wrong credential | AC-14 explicitly does **not** cover this and says so; it is a non-regression check only. |

AC-14 is included with its own limitation written into it because T-06 stage 3 produced two criteria
that agreed with each other and with a useless build; a criterion whose weakness is stated cannot be
quoted later as evidence it does not carry.

## 5. Candidate answers considered, and the argument that chose among them

**Q-2 (decode order).** Candidates: (a) split raw, then decode each field; (b) decode the whole
userinfo, then split; (c) decode only the credential field and leave identity fields raw. (b) was
rejected because it makes an encoding choice by the URL's author change the URL's meaning — a
password written `%3A` would move a field boundary, so two encodings of the same password would
produce different nodes. (c) is what the code does today for ss (`method` raw, `password` decoded)
and is defensible, but it leaves the contract with a per-field exception list; (a) is one sentence,
matches `parse_ss`'s existing raw split, and is observationally identical to (c) on every well-formed
link, because neither a UUID nor a shadowsocks method name contains a percent sign.

**Q-3 (vless).** Candidates: (a) full family membership — whole userinfo, decoded; (b) adjacent —
frozen byte-identical; (c) the split-frozen / decode-applied half-measure that shipped. (a) changes
the emitted `uuid` for any vless link whose userinfo contains `:` or `@`, on the premise that a vless
id may be an arbitrary string (Xray derives a UUIDv5 from one) — a premise I could not verify from
in-repo evidence and cannot test here, and the failure direction is a working node breaking. (b) is
safe but leaves the contract with a member that is exempt from a rule costing nothing to obey. (c)
gives byte-identity on every `%`-free input — i.e. every legal UUID — while keeping one decoding
sentence for the whole file, and it leaves the genuinely open question (whole vs. first field) open
with a named revisit trigger instead of guessing.

**Q-4 (ss base64 double-decode).** Candidates: fix, or freeze and file a row. Freezing was tempting
under rule 85's counter-rule — it is not what the task was dispatched for. It was rejected because
the defect *is* the task's own judgment seen from the other side: any contract sentence about when
decoding applies is either violated by `bin/sc:732` or must carry an exception for it, and T-28 would
then pin the exception. The cost is one behaviour change, documented in AC-12.

**Q-6 (loud error for a grammar-violating userinfo).** Candidates: reject, warn, or transcribe. After
FR-4 a colon-free tuic userinfo genuinely carries no password, so transcribing is honest rather than
silent — the R-42 defect was inventing an empty password for a URL that *did* carry one. Rejecting
would need a new user-facing string and would change `sc add`'s contract for links that work today.

**Q-11 (detect already-broken stored nodes).** Candidates: a `sc doctor` row, an `sc ls` marker, a
one-shot warning at load, or documentation only. The first two land in output surfaces T-25 and T-26
own; all three need a new string; and none of them can *repair* anything, because Q-1 establishes the
original bytes are gone. Documentation plus the operator row is the whole of what is achievable.

**Q-1 (storage).** Not a judgment call — a fact, read out of the code (E-6). It is recorded as a
question because the dispatch was right that it is the single most consequential thing this stage
could establish: it converts "install the new `bin/sc` and reload" into "install the new `bin/sc`,
then re-add the nodes AC-12 enumerates", which is a materially larger promise and must reach the
user in the changelog.

**AC-12's damage set — derived per class from HEAD, not from the shape of the fix.** The four
predicates were obtained by asking, for each scheme, which stored value differs from the password the
link carried, and the answer is narrower than the fix is wide:

| stored node | damaged at HEAD? | evidence |
|---|---|---|
| any tuic node | **yes, unconditionally** — password `""` | `bin/sc:763-768`: `userinfo = p.username` is colon-free by construction (`urllib/parse.py:198`), so the `uuid, password = userinfo, ""` arm is the only reachable one. |
| trojan / hysteria2, **raw** colon in the password | **yes** — truncated at that colon | `bin/sc:696`, `:744`: `p.username` is `userinfo.partition(':')[0]`. |
| trojan / hysteria2, `%3A` / `%25` / percent-encoded non-ASCII / `@` in the password | **no** — correct today | no **raw** colon means `p.username` is the whole userinfo, and one `unquote` produces exactly what the new whole-userinfo reading produces; `rpartition('@')` (`parse.py:196`) already gives the last-`@` split. |
| ss, colon in the password | **no** — correct today | `bin/sc:717` / `:724` split with `split(":", 1)`, so every colon after the first is kept. |
| ss plaintext, percent sign in the password | **no** — correct today | `:717` splits raw URI text, `:732` decodes once. |
| ss, **base64-recovered** password containing `%XX` | **yes** — altered | `:714-715` / `:722-724` recover material that never was percent-encoded, and `:732` decodes it anyway. |
| vless / tuic id carrying a percent-escape | **yes** — stored still escaped | `bin/sc:637` and `:763` read `p.username` with no `unquote`. |

Writing the wider clause would have told a user with a colon in a shadowsocks password, or a percent
sign in a trojan password, to delete and re-add a node that was never broken — in a Chinese,
user-facing CHANGELOG whose readers cannot check the claim against the code. AC-12 therefore states
the two most tempting non-claims explicitly, so the entry cannot drift back to them, and requires the
same predicate set in both READMEs if a README sentence changes at all (`.harness/rules/00-core.md`'s
consumer split puts the CHANGELOG and `README.zh-CN.md` in Chinese and `README.md` in English; a
predicate that exists in one language only is a defect of this criterion, not a translation detail).

**AC-16 (one positive vless fixture) — added rather than declined.** FR-7's decode half was observed
by AC-10's static sweep alone, which reads the shipped construct rather than an emitted document; a
call site that re-escaped or bypassed the decoded projection for vless only would have passed every
criterion. The alternatives were (a) leave it observed statically and record that fact, (b) fold a
`%`-carrying vless case into AC-4's corpus, (c) one standalone fixture. (b) is wrong — it would break
byte-identity for a reason that is a pre-declared behaviour delta rather than a regression, which is
the same trap that forced AC-3's `%`-free clause to widen from "password" to the whole userinfo. (c)
costs one fixture, sits in no corpus and in no HEAD-mismatch set, and observes behaviour the approved
design already produces, so it demands nothing new of the architecture.

## 6. Insight-index entries consulted, and what each changed

- `urlparse().username` stops at the first `:` — the founding fact; drove FR-2 and E-1's first-hand
  re-derivation rather than inheritance.
- `_init_files()` hard-codes `/var/lib/sing-box` — AC-1's verification names the dev-map recipe and
  the ban on driving `_init_files()`, so the fixture cannot write outside its temp root.
- `main()` reassigns `LANG` after import — AC-11 asserts on the diff's strings rather than on rendered
  output, so no assertion can pass vacuously in the wrong language.
- `verify_all` E.6's `^##\s+Adversarial\s+tests` regex — QA's heading must stay unnumbered; recorded
  here so stage 6 does not spend the cycle.
- `Path.read_text()` can raise `UnicodeDecodeError`, a `ValueError` — the reason state-file I/O is
  T-23's and named in out-of-scope item 1, not something this task's diff may touch.
