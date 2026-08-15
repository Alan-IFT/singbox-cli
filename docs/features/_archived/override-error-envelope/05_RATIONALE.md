> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Trigger record

- **T5.2** fired (adjudicating developer-recorded drift D-1…D-4) → `04_RATIONALE.md` read.
- **T5.1** fired (D-1 turns on *why* the design chose K-11's shape) → `02_RATIONALE.md` §"Risk table" RK-2/RK-3/RK-11/RK-12 and §"Candidates weighed at this stage" read.
- **T5.3** fired at round 2 for CR-8 (a risk finding). `02_RATIONALE.md` carries no statement on the anchor echo; the binding statements live in the owning stage's rationale — `01_RATIONALE.md:149-156`, re-homed finding 1 — and in the contract itself: `02_SOLUTION_DESIGN.md:294` and RS-4 (`:322`). Both read. Nothing new fired at round 3: closing CR-8 needed the code and the two delivered strings, not a rationale.
- **T5.4** did not fire: every identifier acted on is defined in a contract portion.
- `03_RATIONALE.md` was consulted only by search (BC-4/BC-8 confirmation at `:198`), not read whole.

## How round 3 was checked, and its limit

I have no execution tool, and have executed nothing at any of the three rounds — no `git`, no `verify_all`, no `systemctl`, no import of `bin/sc`, no write anywhere. `/etc/sing-box/` and `/var/lib/sing-box` were never touched; the live service was never queried, by `systemctl show -p MainPID -p ActiveEnterTimestamp` or otherwise. Every measurement in the contract portion is stage 4's or stage 6's, cited by name.

The developer's scope claim — `bin/sc` byte-for-byte, both READMEs / `CONTEXT.md` / `docs/dev-map.md` untouched — was checked the only way available: by re-reading every line rounds 1 and 2 cited and comparing content and line number. `bin/sc:356-383`, `:525-570`, `:1058-1105`, `:1340-1562`, `:1990-2140` and `:3725-3744` render identically to the quotations in the earlier rounds, including the load's arms, the gated assertion at `:2101`, the hoist at `:2118`, the two arms at `:2119-2124` and the write at `:2128` — a diff anywhere above them would have shifted these numbers. `README.md:394-411`, `README.zh-CN.md:394-411`, `CONTEXT.md:166-183` and `docs/dev-map.md:34-59` likewise, the last still carrying `:38`'s false clause and `:57`'s `README*.md:384` citation verbatim. That establishes identity **at the cited spans**, not byte-for-byte across each file; `+85/−55` and `git status --porcelain` remain the developer's measurement and travel to stage 6 as RES-5.

`verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1 before and after is likewise the developer's; a documentation-only round cannot plausibly move it, but I did not re-run it and do not claim it.

## CR-8: why it is closed

The shipped tail, read as delivered at `CHANGELOG.md:26`:

> …随后以非 0 退出：写错在哪儿说得清的（比如下面那条数组规则），这一行点的就是那个位置；说不清的（栈溢出、`AttributeError` 这类），带上一句指明故障类别的说明 —— **只写异常的类名**，异常自己那句可能抄着你文档内容的消息不会被打印出来；

Three things had to hold, and all three do.

**1. The property is true by construction where it is now claimed.** The class-name arm has exactly two sites, and both were read this round:

```
bin/sc:2051-2052   raise _unusable(OVERRIDE_PATH, t("no configuration could be produced from it "
                                                    "({fault})", fault=type(e).__name__)) from None
bin/sc:2122-2124   raise _unusable(OVERRIDE_PATH if override is not None else None,
                                   t("no configuration could be produced from it ({fault})",
                                     fault=type(e).__name__)) from None
```

`e` appears in each `raise` exactly once, inside `type(e).__name__`. There is no `str(e)`, no `e.args`, no `repr`. `from None` clears `__cause__`, and in any case no traceback is printed: `main()`'s single rendering site is

```
bin/sc:3737-3739   sys.exit(_plain(t("Cannot use {path}: {problem}",
                                     path=e.path or CFG_PATH,
                                     problem=str(e)).replace("\n", " ")))
```

where `str(e)` is the already-composed `OverrideError` message — for this arm, `无法据此生成配置（AttributeError）` — and nothing reaches out to the original exception. A class name is a property of the exception's type; no byte of the user's document can influence it. So the promise is structural, not measured, which is the strongest form the note could carry.

**2. Nothing in the region falsifies it.** I re-derived the enumeration rather than accepting the reported 17 rows — the row grouping is an artifact anyway (`_anchor_index` has two `raise` sites, not four; `_filter_rules` produces no sentence of its own, its `AttributeError` surfaces through the envelope). What matters is completeness, so I enumerated every sentence-producing site in the file and asked which are reachable inside `:2086-2118`:

| site | sentence | echoes a document value? |
|---|---|---|
| `:1376` | `{name} cannot be combined with other keys…` | a directive name — BC-4 permits |
| `:1379` | `unknown directive {name} — use one of {directives}` | a directive name — BC-4 permits |
| `:1394` | `{name} needs an object with "match" and "values"` | no |
| **`:1400-1404`** | `{name} matched {count} elements … — match: {anchor}` | **yes** — `json.dumps` of the user's anchor |
| `:1417` / `:1420` / `:1427` | `$…` shape sentences | no |
| `:1455` / `:1471` / `:1477` | the vocabulary and "already exists" sentences | `at`/`where`, i.e. a dotted position built from the user's key names — BC-4 permits |
| `:2101-2102` | `at {at}: this must stay an array` | no — `at` comes from a fixed tuple |
| `:1105` (`_warn_degraded`) | `{n}/{total} rule-sets unusable ({names})…` | no — `names` are `sc`'s own rule-set tags and `_status_text` values |
| `:2030-2033` (`_warn_drift`) | `{path} was modified outside sc … put them in {override}` | no — two path constants, nothing else |
| `:2122-2124` | the class-name arm | no, by (1) |

That is one echo, `_anchor_index`, and it belongs to the pass-through arm (`except OverrideError: raise`, `:2119-2120`) about which the new text asserts nothing. The surviving clause for that arm — "写错在哪儿说得清的…这一行点的就是那个位置" — states what the line *points at*, not what it *contains*, so the anchor's presence does not contradict it; and BC-4 (`01:78-80`) permits naming a position, a key name and a directive name outright.

Two sites needed the spot-check the PM asked for, and both came back clean. `_warn_drift` (`:2014-2033`) renders `CFG_PATH` and `OVERRIDE_PATH` and nothing else — its docstring's "never logs its content" is borne out by the code, which reads `config.json` only through `_drift_state()` → `_config_digest()`. The load span (`:1509-1549`) has six distinct sentences across eight raise sites: the dangling-symlink target (`:1523`, a filesystem path, not document content), `cannot be read ({err})` (`:1527`, `:1534` — `e.strerror`, an OS string), `larger than {n} bytes`, `not valid UTF-8 text`, `not valid JSON ({err})` and `the top level must be a JSON object`. The one worth attention is `not valid JSON ({err})` at `:1546`, which *does* print an exception's own message — but `json.JSONDecodeError.__str__` composes `msg: line L column C (char N)` from position data only, never from the offending text, so no document value reaches the stream there either. And it is not the class-name arm, so the delivered sentence's em-dash clause — grammatically inside the "说不清的" branch, attached to "带上一句指明故障类别的说明" — does not reach it.

Also checked: nothing inside the region reads a settings document. The three warning sites that could otherwise intrude — `:599` (state-document reader), `:1630` (ipv6 setting) and `:1833` (telemetry setting) — are reached from `_dns_overlay()` / `_telemetry_overlay()` at `:2079-2080`, above the `try` at `:2086`.

**3. The stage document says the same thing.** `04_DEVELOPMENT.md:25`'s E9 row now attaches the property to "that class-name arm alone, where it holds by construction", cites `bin/sc:2122-2124` for the construction and `:2084-2085` for the reasoning — and `:2084-2085` reads, verbatim, "Only the class name: an exception's own message can quote a value the document supplied", which is the same fact stated in the code's own comment. It then names `_anchor_index`'s `—— match：{anchor}` (`:1400-1404`, zh key `:370-371`) as the excluded sentence and attributes the exclusion to BC-4's scoping, `03_RATIONALE.md:198` and `02_SOLUTION_DESIGN.md:294`. Every one of those citations resolves. One imprecision, not worth a finding: the row cites only `:2122-2124`, while the claim's span also covers the load wrapper's arm at `:2051-2052` — which carries the identical construction, so the row understates its own evidence rather than overstating it.

This is the repair round 2 asked for, in the shape round 2 named first, and it costs the bullet nothing a user needed.

## Why this is APPROVED and not a third rollback

The escalation cost is real and I weighed it in both directions. What decided it is that no developer-owned MAJOR or CRITICAL survives: the code has been approved since round 1 and is unchanged; CR-1, CR-3 and CR-8 — every published falsehood found across three rounds — are closed against the delivered text; what remains developer-side is CR-5, CR-9 and CR-11, one MINOR and two NITs, all with residuals that stage 6 and the PM's delivery pass can carry.

The one MAJOR still open, CR-2, is a false clause in `docs/dev-map.md:38`, and C-7 puts that file outside the developer's permitted set. Rolling back to the developer for it would route a repair to the one agent contractually barred from making it, and would spend the human escalation on a hand-off that is already written out as exact old/new text at `04_DEVELOPMENT.md:103-111`. So the masking rule is honoured by naming it, not by hiding it: the Standards axis reports worst = MAJOR in plain words, the verdict line carries it, and RES-4 blocks the commit rather than the code. If the PM cannot or will not apply RES-4 before commit, that — not the developer's work — is what should reach the human.

CR-11 is raised deliberately even though it blocks nothing. Three rounds at this stage have each turned on a clause in this one bullet that claimed slightly more than the code delivers; recording the fourth instance as a NIT keeps the pattern visible to the delivery pass instead of letting it pass unremarked because the round finally came out clean.

## What did not change, and is not re-litigated

The code is identical to what round 1 approved, so every read recorded there stands: the R-22 gate (both arms `raise`, `text` unbound unless the region completed, no caller of `generate_config()` swallows the exception, `from None` on both arms), K-6/K-7's single un-copied assignment at `:1485`, K-8's absence of any cap, the C-8 budget reconstruction, and the C-12 licence under which a `_warn_degraded` / `_warn_drift` defect is attributed to `override.json`. CR-4, CR-5 and CR-7 stand as written. CR-9 was explicitly not a rollback item and the developer was right to leave `退出码仍然是 0` and `八种` untouched — both are present in the delivered line, verbatim. CR-2, CR-6 and CR-10 are unchanged and remain the PM's under C-7; the developer was right not to touch `docs/dev-map.md`, in all three rounds.
