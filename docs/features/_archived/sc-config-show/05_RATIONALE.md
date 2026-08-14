> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Tooling constraint, and what was done instead

This reviewer was dispatched without a shell: no `git diff`, no `git show`, no `verify_all` re-run, no ability to execute `bin/sc`. Everything in the contract portion was established by reading the working tree and by structural argument. Where that leaves a claim weaker than a run would, the contract portion says so (`AC-S2` is marked "inspected", not "run"; `GC-4`'s "no other glossary wording changed" is qualified below). Nothing was accepted on `04_DEVELOPMENT.md`'s word.

**The substitute for `git diff` was line-offset arithmetic.** The design cites pre-edit line numbers throughout; the shipped file's line numbers must then differ from them by exactly the sum of the additions above each citation, and any *undeclared* edit would break the chain. The chain holds end to end:

| symbol | design cite | shipped | delta | additions above it |
|---|---|---|---|---|
| `_load_lang()` | `:337` | `:345` | +8 | the four zh keys (8 lines, `:330-337`) |
| `_config_digest()` | `:1826` | `:1834` | +8 | same |
| `_warn_drift()` body start | `:1871` | `:1879` (now `_drift_state()`) | +8 | same — the extraction begins exactly where the old body began |
| `_plain()` | `:2308` | `:2338` | +30 | 8 + the drift extraction's net +22 |
| `cmd_mode()` | `:2619` | `:2782` | +163 | 30 + the 131-line config block + 2 blank separators |
| `main()` opt-out | `:3177` | `:3352` | +175 | 163 + 8 help-row lines + `add_parser` + the restated comment's growth |

Two consequences. First, `# doctor` (`:2321-2646`), `generate_config()` (`:1930`), `_write_private()` (`:426`), `_config_digest()`, `_record_generated()`, the parsers and `_runtime_overlay()` are displaced by exactly the additions above them and by nothing else — which is the frozen set's negative, established without a diff. Second, the totals reconcile with the reported `+196/−20` for `bin/sc` with no slack left over: 8 (i18n) + ~42/−20 (drift extraction) + 131 (config block) + 8 (help) + 1 (`add_parser`) + 1 (handlers) + ~5 (comment growth) ≈ 196. There is no room in that budget for an undeclared helper, an extra option or a defensive cap — which is the "Less is more" check made quantitative rather than impressionistic.

The one check this cannot fully make is GC-4's "no other glossary wording changed". `CONTEXT.md`'s reported `+14` is consistent with the developer's account (13 lines of the architect's stage-2 C-10 block, already in the working tree before stage 4, plus one reworded line), and the two glossary entries read exactly as C-10 and GC-4 require. A byte-level assurance that no *other* entry moved would need a diff. The contract portion marks GC-4 discharged on the strength of the entry's content plus that arithmetic, and points here for the limit.

## The redaction guarantee, traced by hand

`_redact` (`bin/sc:2694-2720`) was not read as prose. It was executed on paper against the four shapes the brief named, because each stresses a different clause:

1. **A T-15 `urltest` group whose `outbounds` is a list of tag strings.** Root dict, `strict=False`. Key `outbounds` is not in `SECRET_KEYS`, and the region rule is inert because `strict` is false, so control reaches `:2719` with `strict or k == "outbounds"` → `True`. The array maps element-wise at `:2709` with `strict=True`. The group dict's own `outbounds` key **is** in `VISIBLE_IN_OUTBOUND`, so it too reaches `:2719`, recurses with `True or True`, and each element is a `str` → `:2710-2711` returns it unchanged. The member tags render. Had `outbounds` been omitted from the visible set, this array would have become a single `"******"` and the auto-select group would have been unreadable — which is precisely the fail-closed failure direction K-10 describes and which no leak test can detect. It is present.
2. **`transport.headers` with arbitrary keys plus `Host`.** `strict` is already `True` two levels up (inside an outbound element). `transport` → visible → recurse; `headers` → visible → recurse; inside, `Host` → visible → the string returns unchanged, and every sibling hits `:2716-2717` and becomes the mask. BC-9 exactly.
3. **`obfs.password` nested inside a visible `obfs`.** `obfs` is visible, so descent happens; `password` is then caught by `:2714-2715` **before** the region rule is consulted. This is the case that makes I-4's ordering load-bearing in principle: a visible container must not be able to shelter a credential. The two frozensets happen to be disjoint today, so the ordering changes no byte of today's output — but the ordering is what keeps that true after someone adds a name to `VISIBLE_IN_OUTBOUND` under K-10's obligation. Shipped in the right order.
4. **`experimental.clash_api.secret` at the root.** `strict` is `False` for the entire descent (`experimental` and `clash_api` are not named `outbounds`), so the region rule never fires and `SECRET_KEYS` is the only thing standing between that value and stdout. `:2714-2715` fires. This is the case Q-5 invented the document-wide floor for, and it works.

Two structural properties were checked in addition. `strict` is **monotone**: the sole expression that computes it is `strict or k == "outbounds"` (`:2719`), which can only raise it, and no call site passes a literal `False` except the single entry point at `:2770`. And the **key is never replaced**: both mask assignments are `out[k] = MASK`, so which fields are configured stays observable (FR-5), and because the assignment precedes any inspection of `v`, a numeric `"password": 12345678` becomes the mask rather than being preserved or dropped (BC-16).

## `VISIBLE_IN_OUTBOUND` — re-derived, not compared

A name-by-name comparison against I-2 proves the developer transcribed the design; it does not prove the *design* enumerated correctly, and the omission of one name is invisible to every leak test. So the set was re-derived from the emitting code:

- `_attach_transport` (`:527-551`): `transport`, `type`, `path`, `headers`, `Host`, `service_name`, `host`.
- `_attach_tls` (`:554-575`): `tls`, `enabled`, `server_name`, `alpn`, `utls`, `fingerprint`, `insecure`, `reality`, plus the credentials `public_key` and `short_id`.
- `parse_vless` / `parse_vmess` / `parse_trojan` / `parse_ss` / `parse_hy2` / `parse_tuic` (`:578-737`): `type`, `tag`, `server`, `server_port`, `flow`, `packet_encoding`, `alter_id`, `security`, `method`, `obfs`, `congestion_control`, `udp_relay_mode`, plus the credentials `uuid` and `password`.
- `_runtime_overlay` (`:1796-1819`): `type`, `tag`, `outbounds`, `url`, `interval`, `tolerance`, `idle_timeout`, `default`, `interrupt_exist_connections`.

The union minus `{uuid, password, public_key, short_id}` is 33 names, every one of them present in the shipped frozenset; the shipped frozenset's 34th member is `detour`, which no emitter produces — matching I-2's derivation claim and GC-4's stated exception, and matching V-11's reported result by an independent route. `$replace` (`:1817`) is an overlay directive consumed by `_merge()` and never reaches the emitted document, so it is correctly absent. `route.rule_set` elements (`tag`/`type`/`format`/`path`) live outside `outbounds`, so the region rule never applies to them.

## The one-stdout-write invariant, read as an invariant

K-7 is the security guarantee, and "there is one write" is weaker than "there is no second path". Three greps over `bin/sc` establish the stronger form: `_redact` has exactly one call site outside its own recursion (`:2770`); `MASK` is referenced at exactly three sites, all inside the block; and `cmd_config()` contains no `print()`, no second `sys.stdout` reference, and no conditional around the write — its argument is a single expression, `json.dumps(_redact(doc, False), indent=2, ensure_ascii=False) + "\n"`. There is no setting read, no environment variable consulted and no argument inspected anywhere in the function; `args` is accepted and never touched. The only way to a different rendering would be a different function, and none exists.

The stream discipline was checked in the same spirit. `sys.stderr.flush()` at `:2768` is the last statement before the `try`, so the K-4 ordering is a property of statement order rather than of buffering luck. The stdout flush is **inside** the `try`, immediately after the write, which is where D-3 puts it and where it must be — a buffered `write` usually does not raise, and `EPIPE` surfaces at the flush. `os._exit(1)` (not `sys.exit(1)`) is what skips the interpreter's shutdown flush and therefore the "Exception ignored in: `<_io.TextIOWrapper …>`" text; the comment at `:2774-2778` states the reasoning, including the two preconditions it depends on (stderr already flushed, no `atexit` handler registered).

CR-2 came out of this reading. The guard's boundary is the `try` at `:2769`, and the stderr writes above it are unprotected. `sc config | head -5` is safe because stderr goes elsewhere and all stderr writes precede the pipe's closure anyway; `sc config 2>&1 | head -1` is not. Fixing it would mean a second `try`, or hoisting the guard, and both are machinery the design declined to buy for a case BC-14 never stated. Under `.harness/rules/85-design-discipline.md` § "Less is more" the burden of proof is on the larger shape, and it is not met by a case nobody has reported — so the disposition is a pool row (RES-6), not a change order. A downstream agent cannot edit upstream, and this is upstream's call.

## `parse_tuic()` — confirmed, and what it costs T-06

The developer's reading is correct. CPython's `urllib.parse` splits userinfo on the first `:` inside the `username`/`password` properties, so `p.username` for `tuic://uuid:secret@host` is `uuid` — a string that by construction cannot contain a `:`. `bin/sc:713`'s `if ":" in userinfo:` is therefore never true, `:717` runs instead, and `:724` writes `"password": ""`. Every tuic outbound `sc` has ever emitted carries an empty password.

Not fixing it here was right. The change would touch `# Share-URL parsers`, which no C-row names; it would alter what `generate_config()` emits, which out-of-scope 3 forbids; and it would put a real behavioural change into a task whose entire verification argument rests on `sc config` being observationally inert. The correct route is the pool row, where it gets its own severity — and it deserves a high one: it is not a display defect, it is a silent authentication failure for one of six supported schemes.

Its effect on *this* task is narrow and worth stating precisely, because it is the kind of thing that quietly weakens a passing test. AC-B2's method is a byte-substring search for each synthesized fixture credential, with a control read proving each value is on disk. The tuic password fails the control — it never reached disk — so the developer correctly searched for nine values rather than ten. That leaves one of GC-1's ten masked positions (the tuic outbound's `password` key, present with an empty value) proved masked **structurally** (it is in `SECRET_KEYS`, `:2714-2715`, and `MASK` is assigned before `v` is examined) rather than **observationally**. The structural proof is sound; QA should simply not report AC-B2 as covering all ten.

This also resolves CR-1's arithmetic. Six schemes yield uuid ×3 (vless, vmess, tuic), password ×5 (trojan, ss, hy2, `hy2.obfs.password`, tuic), `public_key` ×1 and `short_id` ×1 — ten positions, of which nine carry a value on disk. V-1's "password x4" is a slip; the count 10 it accompanies is right, and V-2's independent "9 distinct synthesized credential values" is what confirms it. The finding is filed because GC-1's discharge is an *identity between two counts*, and an evidence line whose own enumeration does not add up is not evidence a downstream stage can lean on.

## A.1, checked with the gate's own regex

`.harness/scripts/verify_all.sh:33` is `(api[_-]?key|secret|password|token)[[:space:]]*[:=][[:space:]]*["'][^"']{8,}["']`, excluding `*.md`, `verify_all*` and `.harness/*`. Run against the repo's non-`.md` files it returns nothing. The two shapes worth naming as *near* misses, since both are new in this diff and both sit next to those key names by construction: `MASK = "******"` is six characters (the pattern needs eight, which is I-1's entire reason for choosing six), and `SECRET_KEYS`' members are comma-separated string literals — `"password", "uuid"` — where the character following the key name is `"`, not `:` or `=`. Neither can match. NFR-3 and K-11 hold as written, and the mask literal's length is load-bearing rather than aesthetic.

## Trigger record

**T5.3** fired: raising a reuse-correctness observation about `_config_digest()` / `_warn_drift()` required knowing why the design split the judgement rather than re-reading the record in `cmd_config()`. `02_RATIONALE.md` is present and was consulted (its reuse table and its rejected-alternative 6 and risk R-2). It named the future edit the extraction prevents — T-20's doctor drift row becoming one `_drift_state()` call — which is what `.harness/rules/85-design-discipline.md` requires of a refactor riding along with a feature, and which is why the extraction is not itself an over-build finding.

**T5.1, T5.2 and T5.4 did not fire.** No design-fidelity finding turned on why the design chose a shape (CR-2 turns on a boundary the design did not cover, not on a shape it chose); `04_DEVELOPMENT.md` records `## Design drift — None`, and reading the code confirmed it, so there was no drift to adjudicate; and every identifier a contract row obliged me to act on — GC-1…GC-8, C-1…C-11, I-1…I-14, K-1…K-15, FR/BC/AC/NFR, RS-1…RS-6 — is defined in a contract portion.
