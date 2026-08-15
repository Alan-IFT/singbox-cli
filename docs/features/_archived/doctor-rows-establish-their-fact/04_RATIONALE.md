# 04 — Development rationale · T-26 `doctor-rows-establish-their-fact`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

Everything here is a transcript or a narrative. Nothing in it overrides the contract portion, and
full acceptance verification remains stage 6's. It lives here because
`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37) and the
developer contract's section schema has no shape that holds a verification transcript.

## The fixture

One case per process, `python3 case.py <repo-root> <case> [lang]`, held in the session scratchpad
(`/tmp/claude-1000/-home-alan-Programs-singbox-cli/<session>/scratchpad/case.py`). It is a QA-time
artifact, deliberately not committed (out-of-scope 2; T-28 owns a committed suite).

Shape, in the order the mandated recipe states it:

1. `assert os.geteuid() != 0` first — refuse to run as root, loudly.
2. The dev-map recipe verbatim: an `os` shim whose `geteuid` returns `0` so the elevate branch is
   simply not taken, `sys.modules["os"]` restored in a `finally`, and — **R-77** —
   `open(src, encoding="utf-8")` at use time, because the recipe's own line 136 omits it. The
   recipe file itself was left alone (BC-J).
3. All **eight** path constants repointed into a `mkdtemp()` root, then *asserted* to resolve inside
   it — assertion, not vigilance. `TUN_IFACE` is not repointed: `CONFIG_BASE` captured it at import.
4. `sc.SYSTEMD = sc.OPENRC = False` by default; the two cases that need an init system set
   `sc.SYSTEMD = True` **and** stub `sc.subprocess.run`, both or neither.
5. The Clash port is written into the fixture's **own** `settings.json` (`clash_api_port`), because
   `main()` reassigns `CLASH_PORT` after import; `lang` likewise, because `main()` reassigns `LANG`
   from `_load_lang()` and a fixture that sets only `sc.LANG` renders English and passes Chinese
   assertions vacuously. The `zh` transcripts below are genuinely Chinese, which is the check.
6. `SB_BIN` points at a `#!/bin/sh; exit 0` stub inside the temp root; `_init_files()` is never
   driven (see the near-miss note in the contract portion); the stub Clash API is a threaded
   `HTTPServer` on 127.0.0.1 that logs every request path and 503s any route the case did not mount.

**Why one case per process.** `main()` re-wraps `sys.stdout` in an `io.TextIOWrapper` over
`sys.stdout.buffer` (`bin/sc:3717`). A second `main()` in the same interpreter creates a second
wrapper over the *same* `BufferedWriter`; the first is then collected and closes it, and every
subsequent `print()` — inside `sc` or inside the harness — raises
`ValueError: I/O operation on closed file`. With stderr discarded this is silent: the case prints
its pre-run lines and then nothing, which reads exactly like "the probe produced no rows". This cost
a rebuild of the harness and is the first insight line.

## V-1 · byte identity, candidate vs HEAD (K-7, AC-4, BC-C)

HEAD is a **clone** at `6d16caf` (never a worktree). `generate_config()` on one fixture per row:

| composition | candidate sha256 | HEAD sha256 | `dns.rules[0] == _aaaa_rule(suppress)` |
|---|---|---|---|
| `ipv6: on` | `a87ee4f9…dbca7d5` | `a87ee4f9…dbca7d5` | True |
| `ipv6: off` | `59cba87a…fc62bc7e` | `59cba87a…fc62bc7e` | True |
| `ipv6: on` + `telemetry: block` (BC-C) | `a87ee4f9…dbca7d5` | `a87ee4f9…dbca7d5` | True |
| `ipv6: on` + `telemetry: allow` (contrast) | `8e4f569f…f29c90d21` | `8e4f569f…f29c90d21` | True |

Identical in every composition, both decisions, both telemetry settings. E1 changes how the overlay
receives the decision, never what it emits.

## BC-C · the second `sc`-authored `dns.rules` writer, present tense

`telemetry: block` written into the fixture's own `settings.json`. Composed document:

```
dns.rules[0] = {"action": "predefined", "query_type": [64, 65], "rcode": "NOERROR"}
dns.rules[1] = {"ip_accept_any": true, "server": "hosts_dns"}
dns.rules[2] = {"action": "predefined", "domain_suffix": ["telemetry.microsoft.com", …
rules[0] == _aaaa_rule(suppress): True          ← asserted, per PQ-2's instruction
[OK] IPv6 (AAAA): AAAA queries are resolved normally (setting: on); config.json carries this decision
```

Two things worth recording. First, `_telemetry_setting()` returns `block` for an **absent** key, so
this is the default host, not an exotic one — F-3's "present tense" is stronger than it reads.
Second, the reject rule lands at index **2**, not 1: its `$before {"clash_mode": "Global"}` anchor
resolves by content and the `hosts_dns` rule sits between. PQ-2's "index ≥ 1" holds either way.

## V-2 / V-3 · the AAAA row across six documents (AC-1, AC-2, BC-1, BC-2)

Candidate vs HEAD, same fixture, `en`:

| document | candidate | HEAD |
|---|---|---|
| authored rule at index 3 behind three decoys | `[PROBLEM] IPv6 (AAAA): … does not carry this decision as the first dns.rules entry — run \`sc reload\` to regenerate it, and check …/override.json if it prepends a rule of its own` | `[OK] … config.json carries this decision` |
| rule absent entirely | same PROBLEM sentence (both causes named) | `[PROBLEM] … does not carry this decision — run \`sc reload\` to regenerate it` |
| `dns` is a string | same PROBLEM sentence | HEAD's PROBLEM sentence |
| `dns.rules` absent | same PROBLEM sentence | HEAD's PROBLEM sentence |
| top level not an object | `[UNKNOWN] … cannot read <path>: the top level must be a JSON object` | identical |
| generated by this build, `ipv6: off` | `[OK] … AAAA queries are answered empty (setting: off); config.json carries this decision` | identical |

AC-1 is discriminating exactly as labelled (HEAD says `[OK]` on the index-3 document). No exception
was raised on any BC-1 shape, and the `[OK]` key is unchanged.

`zh` on the index-3 document (BC-13, BC-F, K-9):

```
[异常] IPv6（AAAA）: AAAA 查询正常解析（设置：on）；config.json 的 dns.rules 第一条不是该决策对应的规则
—— 运行 `sc reload` 重新生成；若 /tmp/t26-…/override.json 自己往前插了规则，请检查它
```

Both clauses present in both languages; no `失败：` literal in any changed `zh` string.

## V-4 · the divergence attempt (AC-3)

A healthy document is generated first, then the emitter's directive is renamed in the loaded module
(`$prepend` → `$prependx`) while the probe is untouched — the divergence AC-3 asks for. Result:

```
[UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'
rows printed: 21          ← the same 21 rows; the section is one row, per PQ-3
```

Loud and cryptic, never a silent `[PROBLEM]` on a healthy document, and the blast radius is the one
row `_doctor_ipv6()` owns — PQ-3 confirmed by observation, not inherited.

## V-5 / V-6 / V-7 · the node-delay matrix (AC-5, AC-6, AC-7, FR-7)

| cell | candidate | HEAD |
|---|---|---|
| no init system, `/configs` + `/proxies` answer with a delay per tag (V-5) | `[OK] node delays: 2/2 nodes carry a stored delay (history, not a fresh measurement); auto-select is on n1`; stub log `['/configs', '/proxies', '/dns/query?…']` | `[PROBLEM] node delays: 0/2 nodes carry a stored delay …`; stub log `['/configs', '/dns/query?…']` — **no `/proxies` at all** |
| `SYSTEMD = True` **and** `subprocess.run` stubbed running, `/proxies` entries carry no `history` (V-6) | `[PROBLEM] node delays: a stored delay was read for 0/2 nodes — either no probe has completed yet, every node is failing, or the list could not be read; see \`sc ls\`` | `[PROBLEM] node delays: 0/2 nodes carry a stored delay — either no probe has completed yet or every node is failing; see \`sc ls\`` |
| `SYSTEMD = True`, `subprocess.run` stubbed **stopped**, API not answering (V-7, RS-1's coherent fixture) | `[PROBLEM] Clash API responding: no usable answer …` + `[UNKNOWN] node delays: not probed — the Clash API did not answer`; doctor stub log `['/configs']` | identical |
| `sc ls` on a stopped host, API **answering** `/proxies` (the strongest FR-7 check) | table byte-identical to HEAD's, delay column all `-`; stub log `[]`; `stored_delays()` → `({}, None)` with the log still `[]` | identical |

The last row is what would fail had the guard been deleted rather than narrowed: `sc ls` names no
port, so it still pays neither a request nor a wait even when the API would have answered.

## V-9 / V-10 · the DNS row and the read-only invariant (AC-9, AC-10, AC-11, BC-12)

| stub answer | candidate | HEAD |
|---|---|---|
| non-empty `Answer` | `[OK] DNS lookup: the running sing-box answered for api.ipify.org in 0 ms, possibly from its own DNS cache` | `[OK] … api.ipify.org resolved in 0 ms, through the running sing-box` |
| object carrying no `Answer` | `[PROBLEM] … returned no records after 0 ms — try another node with \`sc use <n>\`; an answer already cached by the running sing-box survives a node change` | same class, no clause |
| `/dns/query` not answered | `[PROBLEM] … no answer for api.ipify.org after 0 ms — try another node with \`sc use <n>\`; an answer already cached by the running sing-box survives a node change` | same class, no clause |

Every run: exactly one `GET /dns/query`, no other DNS request, no mutating request. A before/after
snapshot of the whole fixture root (existence, size, mtime\_ns, mode, sha256) is **identical** on all
three runs, and a positive control that writes one byte afterwards is detected — the snapshot is not
vacuous. `zh` renderings of all three carry the identical trailing clause.

## V-11 · `sc ipv6 auto` on a host already deciding `auto` (AC-12, AC-13)

`reload_or_restart` is replaced by a function that raises if reached; it never was.

```
en  candidate: Nothing changed — the sing-box service was not touched; run `sc reload` to apply this
               setting to a configuration generated before it
en  HEAD:      Nothing changed — the sing-box service was not touched
zh  candidate: 设置无变化 —— 未改动 sing-box 服务；若当前配置生成于该设置之前，请运行 `sc reload` 使其生效
zh  HEAD:      设置无变化 —— 未改动 sing-box 服务
```

Zero `TRANSLATIONS` keys added, exactly one deleted (183 → 182), zero branches added; both sides of
`cmd_ipv6`'s comparison still come from `ipv6_decision()` and neither is read from `config.json`.

## V-12 · row-by-row against HEAD (AC-14, NFR-1)

Same fixture, candidate and HEAD: **21 rows both sides, same labels, same order, same exit status**.
The only two differing lines are the two rows this task exists to change (node delays, DNS lookup).
No row added, no row removed, no row's enumeration growing with the host's contents.

## Parity and BC-H self-check

Computed over the loaded module rather than read by eye:

```
placeholder parity, all six changed keys:      en == zh   (True on each)
BC-H en clause identical across both keys:     True
BC-H zh clause identical across both values:   True  ('可用 `sc use <编号>` 换一个节点试试；正在运行的
                                                       sing-box 已缓存的应答不会因为换节点而失效')
orphan key "Nothing changed — … not touched" deleted:  True
no `失败：` in any changed zh value:            True
zh key count: 183 (HEAD) → 182 (candidate)
```

## The size trim, recorded because the first draft failed the bar

The first complete draft measured `+79/−45` — over BC-G's `+55/−45`. Nothing was removed from the
interfaces, the sentences, the corrected docstring contracts or the removals; the whole of the trim
was prose density in five added docstring paragraphs plus putting each re-worded `zh` value on one
line (the table already carries lines of 250 characters, so that is house style, not a new one). The
sequence was `+79 → +61 → +57 → +55`, each step measured with `git diff --numstat`. The lesson worth
carrying: on this project a docstring paragraph costs 4–7 lines of the diff bar, and a design that
projects `≈ +50` of which "~35 are docstring and translated-sentence lines" has almost no slack for
a second thought about wording.

## F-4, not transcribed

The gate's correction of record was applied: nothing in the code, the comments or the contract
portion repeats the claim that a bare `rules[:1]` "silently compares one element against two". The
implemented probe slices by `len(prepend)` precisely so that a payload that grows a second rule is
followed at zero edits, which is the property the rejection was really about.
