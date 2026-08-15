> Contract portion. Rationale: 05_RATIONALE.md (absent = none written).

# 05 — Code Review · T-23 `state-file-io-contract`

## Files reviewed

- `bin/sc` (whole file in round 1; in round 2 every anchor re-read at its recorded line number)
- `CHANGELOG.md`
- `CONTEXT.md`
- `docs/dev-map.md`
- `docs/features/state-file-io-contract/01_REQUIREMENT_ANALYSIS.md`
- `docs/features/state-file-io-contract/02_SOLUTION_DESIGN.md`
- `docs/features/state-file-io-contract/03_GATE_REVIEW.md`
- `docs/features/state-file-io-contract/03_RATIONALE.md` (T5.3/T5.4: the 22-call-site inventory)
- `docs/features/state-file-io-contract/04_DEVELOPMENT.md`
- `docs/features/state-file-io-contract/04_RATIONALE.md` (T5.2: adjudicating D-1/D-2/D-3)
- `docs/features/_archived/config-write-permission-hardening/02_SOLUTION_DESIGN.md` (T-13, for K-4)

Not reviewed and not counted as an out-of-scope edit: `docs/batches/**` (PM batch bookkeeping,
predates this stage, carries none of the developer's edits — R-36's known carve-out gap).

## Findings

| id | Severity | Axis | file:line | Finding |
|---|---|---|---|---|
| CR-1 | MAJOR | Spec/design-fidelity | `CHANGELOG.md:26` | **RESOLVED — closed on substance, not by rewording.** The false 「不再报错」 is gone. The write half now claims 「**写入不再失败、凭据按 UTF-8 原样落盘**（写进文件的就是那串字符本身，而不是 `\uXXXX`，也不再是一段 `UnicodeEncodeError`）」, which is true at every clause: `save_nodes:578` → `_write_private:507` `fdopen(fd, "w", encoding="utf-8")` cannot raise on the locale, and the 「不再」 attaches **only** to the `UnicodeEncodeError` while the `\uXXXX` contrast is stated descriptively — precise, because `ensure_ascii=False` was already at HEAD for `nodes.json` and is new only for `settings.json`. The 注意 now states that under a非 UTF-8 locale `sc add` **still fails and exits non-zero** while printing its own success line, that the `→` is sc-authored so **an all-ASCII share URL fails too**, and that 「**节点已经正确写进 `nodes.json` 了**……不需要、也不应该重新添加一遍」. Verified against the code path: `save_nodes()` runs at `bin/sc:2343`, two lines **before** the `U+2192` print at `:2345`, so the data really is on disk when the process dies. Neither over-claims the command nor implies data loss. BC-14 honoured (it now says the opposite of what BC-14 forbids, and adds that printing a Chinese tag still fails); K-15 honoured (the disk-only limit is stated as 「本项终结的只是这两份文档在**磁盘**上的编码问题」). |
| CR-2 | MAJOR | Standards-conformance | `docs/dev-map.md:59` | **RESOLVED.** The stale "inherits the same hole … `UnicodeDecodeError` … not an `OSError`" sentence is deleted; the `_telemetry_setting()` row now ends at "Reads one file; writes nothing." The rest of the row (absent ⇒ `block`, unrecognised ⇒ `block` + one stderr line, exactly two consumers, no `telemetry_decision()` sibling) re-checked against `bin/sc:1800-1821` and is true. The navigation ledger no longer contradicts the diff that ships beside it. |
| CR-3 | MINOR | Spec/design-fidelity | `CHANGELOG.md:26` | **RESOLVED.** Now reads 「此前**全文只有三处**读它们的代码」. Three is correct: `load_nodes()`, `load_settings()` and `_load_lang()`'s inline read (HEAD `:390`, deleted by E-6, now `bin/sc:392`). |
| CR-4 | MINOR | Spec/design-fidelity | `bin/sc:3232-3241`, `bin/sc:3388-3400` | **OPEN by agreement — travels as RES-3, no code change.** BC-13 and RT-5 name only `sc on` / `sc off` as commands that act before reading `settings.json`. `cmd_default_tun()` runs `systemctl enable/disable` before its `load_settings()`, and `cmd_update_interval()` writes `override.conf` + `daemon-reload` + restarts the timer (OpenRC: writes the periodic script) before its `load_settings()`. Both leave a standing system change and *then* abort per FR-6. The ordering is pre-existing and out-of-scope item 9 forbids reordering it; the boundary *statement* is what must widen. Accepted as a followups row rather than a re-review round. |
| CR-5 | MINOR | Spec/design-fidelity | `bin/sc:1615`, `bin/sc:1818` | **OPEN by agreement — travels as RES-4, no code change.** On an unusable `settings.json`, `_ipv6_setting()` / `_telemetry_setting()` degrade to `auto` / `block` (FR-4, correct), but they feed `_dns_overlay()` / `_telemetry_overlay()` inside `generate_config()`, so any regenerating run writes a `config.json` that silently discards the user's stored choices and records that digest as the new drift baseline. Authorised by FR-4 + Q-2 and safe under K-8 (verified: no read-modify-write is routed through the degrade); stated by no BC. Accepted as a followups row. |
| CR-6 | NIT | Standards-conformance | `bin/sc:506` | **CLOSED, no action, as accepted in round 1.** E-11 authorised "one docstring line"; the shipped edit is an inline comment between `fchmod` and `fdopen`. Behaviourally identical, prose-only, inside K-4's frozen function but not an executable line. |
| CR-7 | NIT | Standards-conformance | `docs/dev-map.md:38,74` | **RESOLVED (taken voluntarily).** `:38` now reads "An `OSError` **or `ValueError`** there is one translated stderr line + `return False`", with a parenthetical naming what the `ValueError` half buys — true against `bin/sc:2105-2108`. `:74` now spells `fdopen(fd, "w", encoding="utf-8")` (explicit since T-23 — never the locale's codec) inside the ordered chain, without disturbing the T-13 guarantees the rest of the row states. |
| CR-8 | NIT | Spec/design-fidelity | `CHANGELOG.md:26` | **NEW in round 2, on prose unchanged since round 1 (my round-1 miss, not a regression). Does not block.** The clause 「写入失败（包括参数根本无法编码成 UTF-8）会渲染成已有的那句「无法写入 …」并带上原因，原文件保持不变、不留临时文件」 has an elided subject and sits after a sentence naming four documents including `settings.json`. Two internal markers scope it correctly to the `_write_private` pair — the UTF-8-encode parenthetical is E-12/E-15's widened catch, and 「不留临时文件」 is the temp-then-replace mechanism — so the sentence is **under-specified rather than false**. But `save_settings():602-604` is a plain `write_text` with **no** `except`: an `OSError` there is an unrendered traceback (`main():3700` catches only `OverrideError`) and `write_text` truncates, so 「原文件保持不变」 would not hold for it. AC-14 deliberately left that mechanism alone, so the fix is one clause naming the scope (e.g. 「`config.json` / `nodes.json` / 漂移记录的写入失败……」), never a code change. Optional. |

**No CRITICAL finding, and no open MAJOR.** `bin/sc` is correct as shipped and byte-unchanged since
round 1; both round-1 MAJORs were in prose and are closed.

## Requirement coverage check

`[S]` rows are discharged here by reading the shipped source. `[B]` rows are discharged here only to
the extent that the **code path** can be walked; the run itself is stage 6's. This reviewer holds no
shell — no command was executed in either round, nothing was installed, nothing under `/etc` or
`/var/lib` was read or written.

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 | `cmd_ipv6`'s `show` arm returns at `bin/sc:3148` before `load_settings()`; `_ipv6_setting():1615` → `_settings_or_empty()` → `{}` → `auto`; the one line from `_load_lang():392` → `:597-598`; cause `not valid UTF-8 text` from `:561-562` | ✅ path verified |
| AC-2 | `_telemetry_setting():1818` → `block`; `_saved_clash_port():415` → `None`; same single line | ✅ path verified |
| AC-3 | `_read_state:565` rejects `null` / `42` / `"telemetry"` / `[]` as a non-object *before* any key logic, so `"ipv6" not in settings` can never test a JSON string's substrings (BC-3 closed) | ✅ path verified |
| AC-4 | `_read_state:557-559` returns `default` **only** for `FileNotFoundError` **and** only when `default is not None`; `load_settings():586` passes `{}`, so no exception, so no warn line | ✅ path verified |
| AC-5 | The usable path is `_read_state`'s fall-through `return doc` (`:569`); no accessor changed its key logic; no warn line without an exception | ✅ path verified |
| AC-6 | `cmd_lang:3479` calls `load_settings()` **unguarded**; the raise reaches `main():3700` → `sys.exit(...)` at `:3713-3715`; `save_settings():3481` is never reached, so the file is byte-identical | ✅ path verified |
| AC-7 | `_resolve_clash_port():434-438` — `except OverrideError: return port`, no `save_settings()`, no `{}` substitution (K-6) | ✅ path verified |
| AC-8 | `cmd_ls:2262`, `cmd_now:2296`, `_resolve_node:2224` (reached by `sc use 1`, C-1) all call `load_nodes()` unguarded and before any write; four causes from `:560/562/564/566/568` | ✅ path verified |
| AC-9 | `_doctor_clash:2787-2795` — `except (OverrideError, TypeError, KeyError)` → the existing `cannot read {path}: {e}` UNKNOWN row naming `NODES_PATH`; no other doctor probe reads a state document | ✅ path verified |
| AC-10 | Unchanged control path | ✅ path verified |
| AC-11 | **Disk clause:** `save_nodes():578` → `json.dumps(..., ensure_ascii=False)` → `_write_private():507` `os.fdopen(fd, "w", encoding="utf-8")`. **Exit clause:** `cmd_add:2345` prints `U+2192` to a strict stdout, two lines after the `save_nodes()` at `:2343` — which is why the changelog's "the node is already on disk" statement is true | ✅ disk clause by inspection · exit clause **BLOCKED-BY-T-25** |
| AC-12 | Read side: `_read_state:556` `read_bytes().decode("utf-8")`, no `read_text()` anywhere in the state read path (K-1 verified by grep) | ✅ disk clause by inspection · exit clause **BLOCKED-BY-T-25** |
| AC-13 | `_init_files():538` now seeds through `save_settings()`; for a pure-ASCII document `ensure_ascii=False` and `encoding="utf-8"` are byte-neutral under a UTF-8 locale, and `newline=None` still maps `\n`→`\n` on Linux. The seed dict's **key order** cannot be compared to HEAD without a checkout | ⚠️ stage 6 owns (RES-1) |
| AC-14 | `CRED_MODE` unchanged; `_write_private` unchanged apart from the codec; `save_settings():604` still a plain `write_text` (no `chmod`, no temp) | ✅ by inspection |
| AC-15 | `bin/sc:501-524` — `tempfile.mkstemp(dir=str(path.parent), prefix=…)` → `os.fchmod(fd, CRED_MODE)` **on the still-empty descriptor** → `os.fdopen(fd, "w", encoding="utf-8")` → `write` / `flush` / `os.fsync` → `close` → `os.replace(tmp, str(path))`, with the `finally` closing a live `fd` and unlinking a surviving `tmp`. **T-13's property survives verbatim**: the only change inside the region is the `encoding=` keyword and one comment | ✅ [S] verified |
| AC-16 | `_config_digest():1943-1953` — `hashlib.sha256()` fed from `CFG_PATH.open("rb")` in 64 KiB chunks. **T-14's property survives verbatim**: no decode anywhere in the drift quartet | ✅ [S] verified |
| AC-17 | Exactly one key added, `bin/sc:352` (see the C-9 row of `## Design fidelity check`) | ✅ [S] verified |
| AC-18 | Three decide-sites plus the permitted write-refusal arm; no fourth, no fifth (see the C-10 row) | ✅ [S] verified by enumeration |
| AC-19 | `+76 / −51` in `bin/sc`; no new file, no new module, no new package (see the C-8 row) | ✅ [S] verified |
| AC-20 | `04` reports PASS 17 / WARN 0 / FAIL 0 / SKIP 1 from the repository root, run twice. This reviewer cannot execute it | ⚠️ stage 6 owns |
| AC-21 | Owner action; nothing in this review substitutes for it | **BLOCKED** (C-15) |

## Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| E-1 `_unusable(path, problem)` | `bin/sc:541-545` — builds `OverrideError`, sets `.path`, **returns** it | ✅ |
| E-2 `_read_state(path, default=None, member=None)` | `bin/sc:548-569`; four causes; `member` array check; explicit `"utf-8"` | ✅ |
| E-3 `load_nodes()` | `:572-573` one line, no `default` | ✅ |
| E-4 `load_settings()` | `:585-586` one line, `default={}` | ✅ |
| E-5 `_settings_or_empty(warn=False)` | `:589-599`, the only warn site | ✅ |
| E-6 `_load_lang()` | `:389-392`, inline read and its tuple gone | ✅ |
| E-7 `_saved_clash_port()` | `:415`; range check unchanged at `:416` | ✅ |
| E-8 `_resolve_clash_port()` | `:434-438`, returns the probed port without writing | ✅ |
| E-9 `_ipv6_setting()` | `:1615`; docstring's "silently" clause now names `_load_lang()` (`:1605-1607`) | ✅ |
| E-10 `_telemetry_setting()` | `:1818`; "THE SILENCE HAS TWO HOLES" gone, replaced at `:1804-1806` | ✅ |
| E-11 `_write_private()` | `:507` gains `encoding="utf-8"` and nothing else; `:506` one comment | ✅ (CR-6) |
| E-12 `save_nodes()` | `:580` `except (OSError, ValueError)`; `:582` `getattr(e, "strerror", None) or str(e)` | ✅ |
| E-13 `save_settings()` | `:604` `ensure_ascii=False` + `encoding="utf-8"`; mode/mechanism untouched | ✅ |
| E-14 `_init_files()` | `:536-538` seeds through `save_settings()`; `/var/lib/sing-box` literal untouched at `:530` | ✅ |
| E-15 `generate_config()` renderer | `:2105-2107` same widening and cause clause | ✅ |
| E-16 doctor's node-delay guard | `:2791` `except (OverrideError, TypeError, KeyError)`; row text at `:2794-2795` unchanged | ✅ |
| E-17 one translation key | `:352` | ✅ |
| E-18 `CHANGELOG.md` bullet | `CHANGELOG.md:26` — write-scoped claim, corrected 三处 count, and a 注意 that states the non-zero exit, the sc-authored `→` (all-ASCII URLs included) and the data's safe arrival on disk. The five rendered causes in the bullet match `bin/sc:347-357` and `:560-568` one for one | ✅ **round 2** (CR-1, CR-3 closed) |
| E-19 `docs/dev-map.md` | `:34` cell amended, `:38` catch widened, `:59` stale sentence deleted, `:74` codec recorded, `:73` new reusable-utilities row. `+5/−4` is consistent with five single-line table rows, four amended and one added | ✅ **round 2** (CR-2, CR-7 closed) |
| E-20 `CONTEXT.md` | `:172-179` **state document** glossary term, excluding `override.json` and `config.json` by name — re-read in round 2, unchanged | ✅ |
| E-21 / E-22 | `04_DEVELOPMENT.md` present and corrected in place (E-18/E-19 rows now describe what the files say; the dev-map figure is now the measured `+5/−4`); no test artifact committed — the feature directory holds eleven documents, being round 1's nine plus this stage's own two, and nothing else | ✅ |
| I-1…I-11 | Each interface exists at its declared surface with its declared shape; `main()`'s arm (I-8) is code-identical | ✅ |
| K-1 | `read_bytes().decode("utf-8")` at `:556`; grep confirms no `read_text()` in either state path | ✅ |
| K-2 / Q-D | `except OSError` → `except UnicodeDecodeError` → `except ValueError`, one block. `UnicodeDecodeError` precedes `ValueError`, which is the only order Q-D forbids reversing | ✅ |
| K-3 | All five raises go through `_unusable()`; no bare `OverrideError` construction in the state path | ✅ |
| K-4 / NFR-5 / AC-15 | See AC-15 above — ordering, `dir=`, `finally` intact; **credential bytes never exist at a mode wider than `0600` at any instant**. `mkstemp`'s `0o600` remains `open(2)`'s umask-maskable mode argument, re-established exactly by the `fchmod` | ✅ |
| K-5 | `getattr(e, "strerror", None) or str(e)` at **both** widened renderers (`:582`, `:2107`). No other renderer was widened; `_read_state:560`'s `e.strerror` is inside an `OSError`-only arm and is safe; `_record_generated:1972`'s `except OSError` writes an ASCII digest | ✅ |
| K-6 | `:436-438` | ✅ |
| K-7 | `_load_lang()` is the only `warn=True` caller; `main():3682` / `:3685` unmoved | ✅ |
| K-8 | All nine read-modify-write sites call `load_settings()`: `:2370`, `:2382`, `:3115`, `:3150`, `:3213`, `:3242`, `:3402`, `:3441`, `:3479`. `_settings_or_empty()`'s four callers (`:392`, `:415`, `:1615`, `:1818`) are all read-only | ✅ |
| K-9 (as relaxed by C-4) | `_load_override():1479-1541`, `OverrideError`'s `path = None` at `:1242`, and `main()`'s `:3713-3715` are all untouched | ✅ |
| K-10 | `_doctor_ipv6():2659` still `CFG_PATH.read_text()`; `cmd_config():3065` still its own `read_text()` + `json.loads` + `isinstance`. Neither routed through `_read_state` | ✅ |
| K-11 | Exactly one key | ✅ |
| K-12 | **All 16 unguarded call sites re-verified in the shipped file** — nodes: `:2042`, `:2224`, `:2262`, `:2296`, `:2307`, `:2333`, `:2401`; settings: `:2370`, `:2382`, `:3115`, `:3150`, `:3213`, `:3242`, `:3402`, `:3441`, `:3479`. None acquired a `try`, a guard or an `isinstance`. `cmd_add`'s `except Exception` closes at `:2332`, one line **above** its `load_nodes()`; `generate_config`'s two override wrappers close at `:2040`, two lines **above** its `load_nodes()` | ✅ |
| K-15 | The bullet's write half is now write-scoped and its 注意 states the disk-only limit in full; no clause anywhere in it claims a command works under a non-UTF-8 locale | ✅ **round 2** (was CR-1) |
| K-16 | No credential in any artifact of this stage | ✅ |
| D-1 (drift) | **Accepted.** Q-D licenses the single-`try` shape explicitly and forbids only `ValueError` before `UnicodeDecodeError`; the shipped order is `OSError` → `UnicodeDecodeError` → `ValueError` | ✅ declared, adjudicated |
| D-2 (drift) | **Accepted, and ruled explicitly: `isinstance(e, FileNotFoundError)` at `:558` is inside the reader, not a fourth decide-site.** It runs inside the reader's own `except OSError` arm and selects which *cause* applies to the read the reader itself performed; it is not a guard *around* a state read. The two other `isinstance` calls (`:565`, `:567`) are FR-3's shape checks, which I-1 mandates by name | ✅ declared, adjudicated |
| D-3 (drift) | **Accepted.** Terse docstrings with the rationale re-homed to `02` §I-1/I-2; ground stated and measured in `04_RATIONALE.md` §"Why D-1 and D-2 were taken" | ✅ declared, adjudicated |
| Unauthorised edit? | None found. `ensure_ascii=False` at `:578` and `:2104` is **pre-existing at HEAD**, not an unledgered addition — `02` §Migration states that the only byte-level escaping change is in `settings.json`, and the E-12/E-15 line counts (`+3/−2`, `+3/−3`) only balance if it was already there | ✅ |
| **C-4** | `OverrideError`'s docstring opener at `:1224-1225` and `main()`'s comment opener at `:3701` both amended; **the diff contains no executable change inside either region** — `path = None` (`:1242`) and the arm's three executable lines (`:3713-3715`) are untouched. 3 changed lines, prose only, ≤4 | ✅ confirmed |
| **C-8** | Reconstructed independently in round 1 from the shipped file, edit id by edit id: 76 added, 51 deleted, 46 code, against the amended cap `≤ +76 added, ≤ 48 code`. **Round 2: `bin/sc` re-verified byte-unchanged** (method and its one residue in `05_RATIONALE.md`), so the reconstruction stands with no re-count | ✅ confirmed, carried forward |
| **C-9** | Both halves of I-9, quoted from `bin/sc:352`: `"the \"{member}\" member must be a JSON array"` → `"\"{member}\" 成员必须是 JSON 数组"`. Same single placeholder `{member}` in both; **the literal contains no `失败`**. It sits inside the block `:346` guards, and it renders only inside I-8's envelope | ✅ confirmed |
| **C-10** | **Enumerated from the shipped file, not from the developer's list.** Every `except` or guard that can decide what a broken state document means: (1) `_settings_or_empty():595` — the **degrade**; (2) `main():3700` — the **abort**; (3) `_doctor_clash():2791` — **doctor's row**; plus (4) `_resolve_clash_port():436` — the permitted **write-refusal** arm (Q-J). The only other `except OverrideError` in the file is `generate_config():2038` and `:2072`, both **pre-existing** wrappers of `_load_override()` / `_merge()` that set `.path = OVERRIDE_PATH` and re-raise — neither encloses a state read (`load_nodes()` at `:2042` sits between them). **No fifth guard. Three decide-sites plus one permitted arm.** PASS | ✅ confirmed |
| **C-12** | Round 2 re-inspection: no new file exists anywhere the developer could have written one — `bin/` holds only `sc`, `systemd/` and `.harness/scripts/` are unchanged, `test/` is `.gitignore`d, and the feature directory's only growth since round 1 is this stage's own two documents. `docs/tasks.md` is PM-owned by the frozen set. **Still not dischargeable by reading**: the environment's `git status` snapshot is demonstrably stale (it names `docs/features/proxy-urltest-group/` as untracked, and that directory now lives under `docs/features/_archived/`), so **the PM must confirm with a real `git status` before commit** (RES-2 stands) | ⚠️ verified as far as read-only inspection reaches |

## Axis status

- **Standards-conformance: no open findings** (worst open = none). Round 1's one MAJOR (CR-2) is
  closed by deleting the sentence, and CR-7's two NITs were taken voluntarily, so `docs/dev-map.md`
  now describes the shipped file at all five touched rows. CR-6 stays closed with no action, as
  accepted in round 1. `bin/sc` itself conforms and is byte-unchanged: house docstring style, no new
  module, no invented rule, no `re` import, `_plain()` at every foreign-text site, `⚠️  ` consistent
  with the file's existing stderr notices.
- **Spec/design-fidelity: 3 open findings, worst = MINOR** (CR-4, CR-5 MINOR — open by agreement and
  travelling as RES-3/RES-4 to the followups pool; CR-8 NIT). Round 1's MAJOR (CR-1) is closed on
  substance and K-15 with it, and CR-3's count is corrected. Every ledger row E-1…E-22 is present and
  does what it says; all three drifts remain declared and adjudicated; all 16 binding constraints
  K-1…K-16 hold; C-4, C-8, C-9, C-10 confirmed, C-12 as far as reading reaches.

## Residuals travelling

| id | Statement | Must reach |
|---|---|---|
| RES-1 | AC-13's byte-identity between builds cannot be discharged by reading: the `_init_files()` seed dict's key order and the `write_text` codec change must be compared against a real HEAD checkout on the C-5 fixture. | `06_TEST_REPORT.md` |
| RES-2 | C-12 was verified by filesystem inspection only; no `git status` was run in this stage, and the environment's snapshot of one is stale. The PM must confirm the tracked change set is exactly `bin/sc`, `CHANGELOG.md`, `CONTEXT.md`, `docs/dev-map.md` and this task's documents — plus the known `docs/batches/**` carve-out — before committing. | PM (`PM_LOG.md`, pre-commit) |
| RES-3 | BC-13's "act before reading" shape also holds for `sc default-tun` and `sc update-interval`, which are not named in BC-13 or RT-5. The ordering is out of scope to change; the statement is not. | the `followups` pool (widen RT-5) |
| RES-4 | On an unusable `settings.json`, any run that regenerates the configuration emits a `config.json` built from the degraded defaults `auto` / `block`, silently discarding the user's stored `ipv6` / `telemetry` choices, and records that digest as the new drift baseline. Authorised by FR-4/Q-2, stated by no BC. | the `followups` pool |
| RES-5 | AC-11's and AC-12's process-exit clause is **BLOCKED-BY-T-25** on the `bin/sc:2345` ground: never a pass, never a fail, never dropped. Verified as reachable by reading `cmd_add`'s success line, which sits two lines after the `save_nodes()` that makes the changelog's "already on disk" statement true. | `06_TEST_REPORT.md`, T-25 |
| RES-6 | Measured-by-reading fact worth carrying: `sys.stderr` is created with `errors="backslashreplace"` (CPython ≥3.5) while `sys.stdout` is strict, which is exactly why the new `⚠️  Cannot use …` line survives a non-UTF-8 locale (rendering the marker as an escape) while `cmd_add`'s `print()` of `U+2192` does not. T-25's criteria must distinguish the two streams or they will mis-scope the fix. | T-25 (`01_REQUIREMENT_ANALYSIS.md` input); `07_DELIVERY.md` §Insight |
| RES-7 | AC-21 stays BLOCKED and travels verbatim as an operator obligation with V-21's recipe; nothing in this review substitutes for it. | `07_DELIVERY.md` §Operator obligations |
| RES-8 | CR-8's one-clause scoping fix in `CHANGELOG.md:26` is optional and does not block delivery; if the bullet is touched again for any reason, take it then. | `07_DELIVERY.md` (optional, non-blocking) |

## Verdict

APPROVED WITH RESIDUALS
