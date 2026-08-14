# T-06 — sc-config-show · Rationale

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Read the document | `Path.read_text()` behind the repointable `CFG_PATH` | `bin/sc:23` | Reuse. No function in the repo parses `config.json` as JSON today (`json.loads` sites are `:339` settings, `:485/:497` nodes/settings, `:593` vmess payload, `:1422` override, `:2032` Clash API), so this one read is new — and it is a read of a constant, not a new reader abstraction. |
| "File absent" / "cannot read" sentences | `"no file at {path}"`, `"cannot read {path}: {e}"` | `bin/sc:280-281` (added by T-05 for `_doctor_config`) | Reuse as-is. BC-1/BC-2/BC-3 cost zero new keys. |
| "This document cannot be used" sentence | `"Cannot use {path}: {problem}"` + `"not valid JSON ({err})"` + `"the top level must be a JSON object"` | `bin/sc:304, 307, 308` | Reuse the **strings**, not the exception. BC-4/BC-5 cost zero new keys. |
| The `OverrideError` → `main()` rendering seam | `OverrideError` + handler | `bin/sc:1110-1129`, `:3195-3210` | **Not** reused. Raising it would render the identical sentence for free, but the class means "a fragment that cannot be *applied*" and `sc config` applies nothing; overloading it makes every future reader of `bin/sc:1110` hold a second meaning. Reusing the four translated strings gets the same bytes without stretching the seam. |
| "Has `config.json` drifted?" | `_config_digest()` / `_warn_drift()` | `bin/sc:1826, 1871` | Extend: `_config_digest()` is called unchanged; `_warn_drift()`'s fused body is split so the judgement has one home (rule 85 test 2, and T-19's precedent against a second display-site derivation). |
| Foreign text made output-safe | `_plain()` | `bin/sc:2308` | Reuse for every `{e}` / `{err}` fragment, per the standing call-site discipline. |
| Read-only start-up arm | `main()`'s positive opt-out | `bin/sc:3168-3182` | Reuse: one changed line names the second command. |
| Per-row flush discipline | `_doctor_print()`'s `flush=True` | `bin/sc:2585-2595` | Reuse the *reason*, not the function — `sc config` writes one document and two or three notes, so an explicit `sys.stderr.flush()` at the stream boundary is the same discipline at the right granularity. |
| Masking / redaction of any kind | none found | — | New. `git grep` for `mask`, `redact`, `\*\*\*` in `bin/sc` returns nothing; `_record_generated()` avoids the problem by storing a digest instead of a document, which is why no masking existed to reuse. |

## The 34 names are derived, not invented

`VISIBLE_IN_OUTBOUND` = { every key name `bin/sc` emits inside an outbound } − { `uuid`, `password`,
`public_key`, `short_id` } + { `detour` }.

| names | emitted at |
|---|---|
| `type`, `tag`, `server`, `server_port` | every parser: `bin/sc:573-579, 596-604, 632-638, 667-674, 680-686, 710-717` |
| `outbounds`, `default`, `interrupt_exist_connections` | the `proxy` selector, `:1797-1804` |
| `url`, `interval`, `tolerance`, `idle_timeout` | the auto-select group, `:1788-1796` |
| `method` | `parse_ss`, `:672` |
| `security`, `alter_id` | `parse_vmess`, `:602-603` |
| `flow`, `packet_encoding` | `parse_vless`, `:582, :585` |
| `congestion_control`, `udp_relay_mode` | `parse_tuic`, `:720, :723` |
| `transport`, `path`, `headers`, `Host`, `host`, `service_name` | `_attach_transport`, `:520-543`; `parse_vmess`, `:605-617` |
| `tls`, `enabled`, `server_name`, `alpn`, `insecure`, `utls`, `fingerprint`, `reality` | `_attach_tls`, `:546-567`; `:618-625`; `:687-694`; `:724-728` |
| `obfs` | `parse_hy2`, `:695-697` |
| `detour` | **not emitted by `sc`** — sing-box's outbound-chaining key, the one name added on top of the derivation, so an override-supplied chain stays legible as a chain |
| *excluded* `uuid`, `password`, `public_key`, `short_id` | `:578, :601, :715`; `:637, :673, :685, :697, :716`; `:563`; `:566` — exactly the four FR-3 says are masked by exclusion |

So the list is mechanically checkable (design step V-11) rather than a judgement call, and it is
**complete by construction**: a key `sc` emits and forgets to list renders `******`, which is a
readability bug, never a disclosure.

## Smaller alternatives rejected

**1. A 5-name allow-list (`type`, `tag`, `server`, `server_port`, `detour`) instead of 34.** Strictly
smaller (29 fewer strings), strictly *safer*, and it satisfies the fail-closed guarantee identically —
this is the alternative the size rule most wants. What the extra 29 names buy, in observable behaviour:
under the 5-name form a real reality/vless node prints `"tls": "******"`, `"transport": "******"`,
`"flow": "******"`, so the SNI, ALPN, uTLS fingerprint, ws path, `Host` header, gRPC service name and
congestion control are all invisible — every field you actually read when a node fails to connect, and
every field `sc ls` does *not* show. That defeats FR-1's stated purpose ("render that document
readably"), so the smaller form does not satisfy the same requirement. Testable at stage 3: run V-1's
fixture through both forms and count the fields a debugging user can see (34-name form: all
non-credential fields; 5-name form: four).

**2. A deny-list document-wide instead of the two-region rule.** One 6-name set, no `strict` parameter,
no region concept — the smallest design on the page. Rejected because Q-5 fixes the guarantee: inside
`outbounds` a name nobody enumerated (an override-supplied protocol, a future sing-box field) carries a
credential, and a deny-list prints it. The observable difference is AC-B3's invented key name, which a
deny-list renders verbatim.

**3. Textual masking (line- or regex-based) with no parse.** Smaller still — no `_redact`, no structure
walk. Rejected: `re` is deliberately not imported by `bin/sc` (`:2325`), a text mask cannot be
fail-closed on a key it has never seen, and it cannot guarantee the output parses as JSON (FR-5). BC-4
already forbids printing text that could not be parsed, for the same reason.

**4. `os.dup2(os.devnull)` + `sys.exit(1)` for BC-14** (the recipe in the Python docs) instead of
`os._exit(1)`. One line larger with identical observable behaviour here, because K-4 has already flushed
stderr and this codebase registers no `atexit` handler and holds no other buffered stream. Taken the
smaller way, with the precondition written in the comment so a future `atexit` user sees the coupling.

**5. Folding the two stderr notes into one sentence.** Saves one translation key. Rejected on AC-B5's
wording ("the path line **and** the masked-credentials line"), and because the masked-credentials line
is the one a user pastes into a bug report to explain why a field reads `******`; it should be
greppable on its own.

**6. Leaving `_warn_drift()` alone and re-reading the record in `cmd_config()`.** Genuinely smaller in
new names (no `_drift_state`), and roughly the same diff: 7 duplicated lines in `cmd_config` against 8
new lines in `_drift_state` minus 7 removed from `_warn_drift`. Rejected on rule 85 test 2: BC-12/BC-13
put four subtle *unknown* cases (absent, unreadable, non-UTF-8, empty-after-strip) into that read, and
two copies of a four-case judgement diverge on the first edit. The future edit it prevents is nameable:
a drift row in `sc doctor` (T-20) is one `_drift_state()` call rather than a third reader. This mirrors
T-19's ruling against a display-site `stat()` exactly.

**7. A named `READ_ONLY_COMMANDS` set in `main()`.** Same line count as the inline tuple and forbidden by
`docs/dev-map.md:153-155` — a named registry invites a future subcommand to opt in without anyone
reading the comment that explains why the arm exists. `if args.cmd in ("doctor", "config"):` keeps the
enumeration positive, keeps the default arm initialising, and is a data change, not machinery.

**Total size of the accepted design**: one ~9-line pure function, one ~20-line command, three constants
(one of which is a 34-string data literal), one extracted 8-line judgement that removes 7 lines from its
former host, three wiring lines and four translation keys. No new file, no new import, no new format, no
new concept beyond the two glossary words.

## Risks

| id | risk | mitigation |
|---|---|---|
| R-1 | A future parser or overlay emits a new outbound key and nobody updates `VISIBLE_IN_OUTBOUND`, so a legitimate field prints `******`. | The direction is fail-closed by construction (a leak is impossible). K-10 puts the obligation in the constant's own comment, and V-11 is a mechanical set-comparison any later task can re-run in seconds. |
| R-2 | The `_warn_drift()` split regresses the warning on `generate_config()`'s apply path — the one place a user is told their hand-edit is about to be overwritten. | K-14 pins observable behaviour; V-12 runs all four record states before and after. The refactor is a pure extraction: the four early-return conditions collapse into one `return None` and one falsy test, and `if _drift_state():` is false for both `None` and `False`. |
| R-3 | Stream reordering: if the explicit `sys.stderr.flush()` is dropped, `sc config > f 2>&1` interleaves by buffer-drain order on Python 3.6-3.8, exactly the merged-capture case the project already got wrong twice (insight index lines 28-29). | K-4 + AC-B6/V-6. The design writes all stderr first and flushes at the stream boundary, so ordering follows write order rather than buffering policy. |
| R-4 | `sc config` tracebacks before it starts on a host whose `settings.json` is not UTF-8, because `_load_lang()` catches `OSError` but not `ValueError` (`bin/sc:337-341`, insight index line 18) — the broken-host case this command exists for. | Out of scope 6 forbids the fix here; travelling as RS-2 to the open R-25/R-29 row. `cmd_config`'s own K-5 catches `(OSError, ValueError)`, so the new code does not add a second instance of the defect. |
| R-5 | A fixture proves nothing because it silently runs in English: `main()` reassigns `LANG` from `_load_lang()` after import, so `sc.LANG = "zh"` alone is vacuous (insight index line 13) — and AC-B2 explicitly requires "in either language". | Written into the verification plan's preamble: the zh runs put `{"lang": "zh"}` in the fixture's own `settings.json`. |
| R-6 | A user reads `******` as a value they must configure, or as the mask hiding a *missing* field. | The mask replaces values only, never keys (FR-5), so which fields exist stays visible; I-9's stderr line names the literal in the configured language; both READMEs state the rule and its limit (K-12). |
| R-7 | The command becomes a false sense of safety: a secret the user put in `override.json` outside `outbounds` under an unlisted key is printed verbatim. | This is a stated limit, not a defect (FR-4 is "a floor"). K-12 requires both READMEs to say so in the same subsection that introduces the command, so the limit ships with the feature rather than in a corner. |

## Evidence read for this design

`bin/sc:1-141` (paths, constants, elevation, i18n head), `:268-341` (zh table tail, `_load_lang`),
`:418-501` (`_write_private`, `_init_files`, settings/nodes IO), `:520-743` (transport/TLS attachers and
all six parsers), `:1110-1146` (`OverrideError`, directives), `:1410-1441` (`_load_override`, `_compose`),
`:1725-1820` (`_telemetry_overlay`, `_runtime_overlay`), `:1824-1898` (drift trio),
`:2290-2360` (`_plain`), `:2423-2460` (`_doctor_config`), `:2575-2617` (doctor driver),
`:3007-3141` (both help blocks), `:3144-3215` (`main()`); `.harness/scripts/verify_all.sh:29-39` (A.1's
exact ERE); `README.md:240-280, 412-419`, `README.zh-CN.md` heading map; `docs/dev-map.md` in full;
`.harness/rejected-decisions.md` in full (no prior record covers `sc config`, redaction, or a second
read-only command); `.harness/insight-index.md` in full; `CONTEXT.md` in full.
