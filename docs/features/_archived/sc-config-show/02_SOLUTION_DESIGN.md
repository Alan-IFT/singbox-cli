# T-06 — sc-config-show · Solution Design

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

`sc config` is added as one command block inside `bin/sc`'s `# Commands` section — two frozensets, one
mask constant, one pure recursive redactor and one `cmd_config()` — plus three wiring lines in `main()`
and four translation keys; nothing else in the CLI changes behaviour.

The one existing seam that is reshaped is the drift judgement: `_warn_drift()`'s fused
read-record-compare-warn body is split so the judgement lives in `_drift_state()` and `_warn_drift()`
becomes its warning renderer, because `sc config` needs the same judgement with a different rendering
and needs the third state (*matches*) that `_warn_drift()` structurally discards.

The seam for "this command must not initialise" is `main()`'s existing positive opt-out at
`bin/sc:3177`; it gains a second named command and no new structure.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| C-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | New block after `cmd_doctor` (`:2616`), before `cmd_mode` (`:2619`): `MASK`, `VISIBLE_IN_OUTBOUND`, `SECRET_KEYS`, `_redact()`, `cmd_config()` (I-1…I-4, I-6). | developer |
| C-2 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `_drift_state()` extracted from `_warn_drift()` (`:1871-1897`); `_warn_drift()` reduced to the warning render (I-5, K-14). | developer |
| C-3 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `main()`: `sub.add_parser("config")` after `:3153`; `:3177` becomes `if args.cmd in ("doctor", "config"):`; comment `:3168-3176` restated for two commands; `"config": cmd_config,` in the handlers dict (`:3183-3192`) beside `"doctor"` (K-1). | developer |
| C-4 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | Four `TRANSLATIONS["zh"]` entries appended after `:329`, under one `# sc config` comment (I-8…I-11). | developer |
| C-5 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | `HELP_EN` row after `:3029` and `HELP_ZH` row after `:3095`, both immediately after the `doctor` row, in that block's column shape (I-12). | developer |
| C-6 | `/home/alan/Programs/singbox-cli/README.md` | edit | New `### Show the configuration` between `### Diagnose the install` and `### Ruleset update` (`:280`): the command, what is masked, the mask literal, that it writes nothing, and the FR-9 limit (K-12). | developer |
| C-7 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | edit | The line-for-line zh mirror of C-6, `### 查看配置`, at the matching position (before `### 规则集更新`, `:280`). | developer |
| C-8 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One `### 新增` bullet under `## [Unreleased]` (`:5`), Chinese, stating the command, the redaction guarantee, the read-only guarantee and the FR-9 limit. | developer |
| C-9 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | `# Commands` row gains the config block; `# Config generation` row's drift **trio** becomes a quartet naming `_drift_state()` as the judgement and `_warn_drift()` as its renderer; `main()` row states two read-only commands; one `## Reusable utilities` row for "show a credential document without its credentials". | developer |
| C-10 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | Two glossary entries in `## Language`: **visible key set** and **mask**. **Already applied at stage 2**; the developer edits this file only if the shipped wording diverges (K-15). | architect |
| C-11 | `/home/alan/Programs/singbox-cli/docs/features/sc-config-show/04_DEVELOPMENT.md` | new | The developer's stage document. | developer |

No other file is touched. There is no new file in the project and no new import (NFR-2).

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | `MASK` — module constant in the C-1 block | `MASK = "******"` (six U+002A) | Fixed, non-empty, six characters — so `"password": "<MASK>"` written anywhere in a non-`.md` file is 6 < 8 and cannot match `verify_all` A.1 (`verify_all.sh:33`). Contains no character JSON must escape, is never translated, is identical for every masked value, and carries nothing derived from the value it replaces (FR-5, Q-9). |
| I-2 | `VISIBLE_IN_OUTBOUND` — frozenset, 34 names | `type, tag, server, server_port, detour, outbounds, default, url, interval, tolerance, idle_timeout, interrupt_exist_connections, method, security, alter_id, flow, packet_encoding, congestion_control, udp_relay_mode, transport, tls, obfs, enabled, server_name, alpn, insecure, utls, fingerprint, reality, path, host, headers, Host, service_name` | **Derived, not invented**: every key name `bin/sc` emits inside an outbound, minus `uuid` / `password` / `public_key` / `short_id`, plus `detour` (see 02_RATIONALE.md's provenance table). Consulted only where `strict` is true. Membership is the *only* way a key inside `outbounds` renders its value. |
| I-3 | `SECRET_KEYS` — frozenset, 6 names | `password, uuid, secret, token, private_key, pre_shared_key` | Tested at every depth of the whole document, `outbounds` included, and tested **before** the region rule, so being inside a visible container can never expose one. A floor, not the guarantee (FR-4). |
| I-4 | `_redact(value, strict)` → new value | `def _redact(value, strict)` | Pure: no I/O, no print, no mutation of its argument. Total over every JSON type. Rules, in this order: a **list** maps element-wise with the same `strict`; a value that is neither list nor dict is returned unchanged; a **dict** maps each key `k` to `MASK` when `k in SECRET_KEYS`, else to `MASK` when `strict and k not in VISIBLE_IN_OUTBOUND`, else to `_redact(v, strict or k == "outbounds")`. `strict` therefore turns true on descent into any key named `outbounds` and never turns back to false (FR-3 "at every depth"). The **key is never replaced**, only the value, whatever its JSON type (FR-5, BC-16). |
| I-5 | `_drift_state()` → `True` / `False` / `None` | `def _drift_state()` | THE judgement "has `config.json` drifted from what `sc` last generated": `True` drifted, `False` matches, `None` unknown. `None` covers every BC-12 / BC-13 case — record absent, unreadable (`OSError`), non-UTF-8 (`ValueError`), empty after `.strip()`, or `_config_digest()` unavailable. The digest comes from `_config_digest()` (`bin/sc:1826`) and nowhere else (FR-6). Reads two files; writes nothing. |
| I-6 | `cmd_config(args)` | `def cmd_config(args)` | Writes no file and touches no service, socket or subprocess. Reads `CFG_PATH` once with one `read_text()`, then `STATE_PATH`+`CFG_PATH` through `_drift_state()`. Has **exactly one** write to `sys.stdout`, whose argument is produced by `_redact` (FR-2). Returns normally ⇒ exit 0; every failure path leaves stdout empty and exits non-zero (FR-8). |
| I-7 | CLI surface | `sc config` — bare subcommand, no flag, no positional | Registered as `sub.add_parser("config")`; `sc config <anything>` is argparse's own usage error (exit 2). No `--show`, no `--raw`, no opt-out (FR-1, FR-2, Q-1, Q-2). |
| I-8 | translation key | `"Showing the configuration on disk: {path}"` → `"正在显示磁盘上的配置：{path}"` | stderr line 1, always printed on the success path, `path=str(CFG_PATH)` (absolute). |
| I-9 | translation key | `"Node credentials are masked; a masked value shows as {mask}."` → `"节点凭据已隐去；被隐去的值显示为 {mask}。"` | stderr line 2, always printed on the success path, `mask=MASK`. |
| I-10 | translation key | `"This is what sc last generated."` → `"这就是 sc 最近一次生成的内容。"` | stderr line 3 iff `_drift_state() is False`. |
| I-11 | translation key | `"This has drifted from what sc last generated."` → `"这与 sc 最近一次生成的内容已经不一致。"` | stderr line 3 iff `_drift_state() is True`. No `⚠️` prefix and no non-zero status: drift is a fact here, not a failure (FR-8, BC-12). |
| I-12 | help row | `HELP_EN` / `HELP_ZH` row named `config`, description at column 30, sub-lines at column 32, placed immediately after the `doctor` row | States: prints `/etc/sing-box/config.json` with node credentials masked; reads only; document on stdout, notes on stderr. |
| I-13 | stdout document | `json.dumps(<redacted>, indent=2, ensure_ascii=False)` followed by one `"\n"`, written once | Parses as JSON; key order is the file's order (`json.loads` preserves it); `ensure_ascii=False` so non-Latin tags stay readable; equal to the file on disk at every unmasked position (FR-5, AC-B1). Nothing else is ever written to stdout (FR-6). |
| I-14 | stderr commentary | 2 lines, or 3 when `_drift_state()` is not `None`, in the order I-8, I-9, I-10/I-11 | Written, and `sys.stderr.flush()`ed, **before** the first byte of I-13 (K-4). |

## Constraints

**K-1** — The implementer changes `bin/sc:3177` to `if args.cmd in ("doctor", "config"):` and restates the
comment at `:3168-3176` to name two commands; the implementer introduces no `READ_ONLY_COMMANDS`
constant, no per-subcommand flag and no structure through which an unlisted future subcommand skips
initialisation (`docs/dev-map.md:153-155`, FR-7, Q-8).

**K-2** — The implementer uses `MASK = "******"` verbatim and writes no second mask spelling anywhere,
including the help text, the READMEs and the CHANGELOG.

**K-3** — The implementer calls `sys.stdout.isatty()` / `sys.stderr.isatty()` nowhere in this feature, so
the TTY and non-TTY byte streams are identical by construction (BC-15).

**K-4** — The implementer writes every stderr line and then calls `sys.stderr.flush()` before the stdout
write, because on the project's Python 3.6 floor a redirected `sys.stderr` is block-buffered (it became
unconditionally line-buffered only in 3.9) and `sc config > f 2>&1` would otherwise interleave by
buffer-drain order (AC-B6, insight index lines 28-29).

**K-5** — The implementer maps the read/parse failures onto the existing translation keys, catching in
this order: `FileNotFoundError` → `sys.exit(_plain(t("no file at {path}", path=str(CFG_PATH))))` (BC-1);
`(OSError, ValueError)` → `sys.exit(_plain(t("cannot read {path}: {e}", …, e=_plain(str(e)))))` (BC-2,
BC-3 — `UnicodeDecodeError` is a `ValueError` and not an `OSError`, insight index line 18); a
`json.loads` `ValueError` → `sys.exit(_plain(t("Cannot use {path}: {problem}", path=CFG_PATH,
problem=t("not valid JSON ({err})", err=str(e)))))` (BC-4); a parsed non-`dict` → the same frame with
`problem=t("the top level must be a JSON object")` (BC-5). Four new keys total (I-8…I-11), no others.

**K-6** — The implementer wraps the single stdout write plus its flush in `except BrokenPipeError:
os._exit(1)`, and states in a comment that stderr is already flushed (K-4) and that the buffered stdout
bytes are deliberately discarded because the reader is gone — so no `BrokenPipeError` reaches the
interpreter's shutdown flush and no "Exception ignored" text is emitted (BC-14, AC-B8).

**K-7** — The implementer keeps exactly one `sys.stdout.write` in `cmd_config()` and routes its argument
through `_redact` unconditionally: no branch, no setting, no environment variable, no argument selects an
unredacted rendering (FR-2).

**K-8** — The implementer calls none of `_init_files`, `_resolve_clash_port`, `generate_config`,
`clash_api`, `is_running`, `subprocess.*`, `socket.*`, `urllib.*`, or `sing-box check` from `cmd_config()`
or `_redact()`, and forms no verdict about whether the document is valid (FR-7, NFR-1, Q-7).

**K-9** — The implementer adds no file to the project and no import to `bin/sc` (NFR-2).

**K-10** — Any later change that emits a new key inside an outbound (a new share-link parser, a new
overlay) must add that key's non-credential names to `VISIBLE_IN_OUTBOUND` in the same change; the
failure direction of forgetting is a masked field, never a leaked one. The implementer records this
obligation in the constant's own comment.

**K-11** — The implementer writes no key named `password` / `secret` / `token` / `api_key` followed by
`:` or `=` and a quoted literal of 8 or more characters into any non-`.md` file, comments and help text
included (NFR-3, `verify_all.sh:33`).

**K-12** — The implementer states the mask's limit in both READMEs: a secret placed by the user's own
`override.json` **outside** `outbounds` under a key outside `SECRET_KEYS` is printed verbatim (FR-9).
The two README subsections stay line-for-line mirrors.

**K-13** — No zh string introduced here contains `失败：`, the load-bearing diagnostic grep literal
(`bin/sc:126`, `.harness/rejected-decisions.md` § mirror-fallback…).

**K-14** — `_warn_drift()`'s observable behaviour is unchanged by C-2: the same single `⚠️` line, with
the same text and the same placeholders, is written in exactly the case "a record exists, is non-empty,
the current digest is available, and the two differ", and nothing is written in every other case.

**K-15** — The implementer uses `CONTEXT.md`'s two new canonical names — **visible key set** and
**mask** — in the code, the comments, the help text and both READMEs, and uses none of their listed
`_Avoid_` synonyms (whitelist, redaction placeholder, censor, …).

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | Out of scope 4; its enumerated artifact list is why `bin/sc` stays one file. |
| `/home/alan/Programs/singbox-cli/uninstall.sh`, `/home/alan/Programs/singbox-cli/systemd/**` | Nothing in this feature installs, removes or schedules anything. |
| `bin/sc` `generate_config()`, `_compose()`, `_merge()`, `CONFIG_BASE`, the three overlays | Out of scope 3; `sc config` reads the emitted document and never re-derives it (Q-3). |
| `bin/sc` `_write_private()`, `_record_generated()`, `_config_digest()`, `STATE_PATH` semantics | Out of scope 3; T-13 owns the writer and T-14 owns the record. `_config_digest()` is **called**, never edited. |
| `bin/sc` `cmd_doctor()` and the whole `# doctor` block except `_plain()`'s call sites | Out of scope 7; `sc config` forms no validity opinion and changes no doctor row. `_plain()` is reused unchanged. |
| `bin/sc` `_load_lang()`, `load_settings()` | Out of scope 6 — R-25/R-29 stay open even though they sit on this command's start-up path (see residual RS-2). |
| `bin/sc` the five `ls.*` keys | Out of scope 9. |
| `.harness/**` | Not in this task's diff; see residual RS-1. |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | C-4 | none — keys are inert until a `t()` call site exists | delete the four entries |
| 2 | C-1 | C-4 present, so the first zh run renders text and not the English key | delete the block; nothing references it yet |
| 3 | C-2 | `python3 -m py_compile bin/sc` passes after step 2 | restore `_warn_drift()`'s pre-edit body verbatim (K-14); `cmd_config` then loses only its provenance line |
| 4 | C-3 | steps 1-3 in place — this is the step that makes `sc config` reachable and the step that changes `main()`'s start-up arm | revert the three wiring lines and the comment; the block from step 2 becomes dead code and the CLI is byte-identical to HEAD in behaviour |
| 5 | C-5, C-6, C-7, C-8, C-9, C-10 | step 4 done, so the documented shape is the shipped one | revert per file; no runtime effect |

No data migration, no flag, no compatibility shim: no on-disk format changes, `settings.json` gains no
key, the drift record's meaning and writer are untouched, and a host that never runs `sc config` cannot
observe this task. Rollback of the whole task is `git revert` of one commit with no host-side step.

## Out of scope

This design decides nothing about `sc doctor`'s rows, wording or exit status (T-20 owns R-32/R-38).
It decides nothing about R-25/R-29 (`_load_lang()` / `load_settings()` raising on a non-UTF-8 or
non-object `settings.json`), which remain reachable before `cmd_config()` runs.
It defines no rendering for `nodes.json`, `settings.json` or `override.json`.
It defines no diff between the document on disk and the document `sc` would generate.
It adds no test harness to the repo and does not wire a `verify_all` B.3 lint step.
It does not decide how `install.sh` or the install log mention the new command.

## Verification plan

Every `[B]` step runs `bin/sc` under `docs/dev-map.md:113-145`'s neutralisation recipe: the `os` shim so
the import-time elevation branch is not taken, all **eight** path constants repointed into one
`mkdtemp()` root with the assertion that all eight resolve inside it, `SYSTEMD = OPENRC = False`, and
`main()` driven with `sys.argv = ["sc", "config"]` (never `_init_files()`). Because `main()` reassigns
`LANG` from `_load_lang()`, a zh run needs `{"lang": "zh"}` in the fixture's own `settings.json`
(insight index line 13) — a `sc.LANG` assignment alone renders English and passes vacuously.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | Fixture `config.json` generated by this same `sc` from one node of each of the six supported schemes; run `sc config`; `json.loads` stdout and the file | Both parse; every position not masked is equal; the mask appears only at `uuid`/`password`/`public_key`/`short_id` positions | AC-B1 |
| V-2 | Each credential field of those nodes carries a distinct synthesized value; byte-substring search of both streams for each, under `lang en` and `lang zh`; control `grep` of the file on disk | Zero hits in stdout and stderr in both languages; every value found on disk | AC-B2 |
| V-3 | `override.json` appends an outbound carrying `private_key`, `pre_shared_key` and one invented key name; run | All three values render as `******`; the outbound's `type`/`tag`/`server` still render | AC-B3 |
| V-4 | Run on a root where the config directory does not exist; `find` listing of the whole temp root **and** `/var/lib` before and after | Exit non-zero; stderr one sentence containing the absent path; stdout empty; the two listings byte-identical (this is where K-1's dispatch change is observable — `_init_files()` would create `/etc/sing-box`, `rules/` and a hard-coded `/var/lib/sing-box`, insight index line 10) | AC-B4 |
| V-5 | `sc config > out.json 2> err.txt` | `out.json` parses with no other text; `err.txt` carries the path line and the masked-credentials line | AC-B5 |
| V-6 | `sc config > f 2>&1`, one run | Both stderr lines appear strictly before the document's first byte | AC-B6 |
| V-7 | Three fixture states: record matching, record matching after one byte **inside a string value** is changed (document stays valid JSON), record absent | Line I-10, then line I-11, then no third line; exit 0 in all three | AC-B7, BC-12 |
| V-8 | `sc config \| head -5` against a document larger than one pipe buffer | Five lines on stdout; no traceback and no `Exception ignored` / `BrokenPipeError` text on either stream | AC-B8 |
| V-9 | Boundary sweep, one run each: absent file, `chmod 000`, non-UTF-8 bytes, empty file, valid UTF-8 non-JSON, `[]`, `42`, `null`, `outbounds` absent, `outbounds` a string, an `outbounds` element that is a number, `transport.headers` with `Host` plus two other keys, `"password": 12345678` | BC-1…BC-9 and BC-16 as written: the first eight exit non-zero with one sentence and an empty stdout and no traceback, the rest exit 0 with the stated rendering | BC-1…BC-9, BC-16 |
| V-10 | Run with `sc.subprocess.run`, `sc.socket.socket`, `sc.urllib.request.urlopen` and `sc.clash_api` replaced by raisers, and with `sc.os.replace` / `sc._write_private` replaced by raisers | Command completes normally; no raiser fires | FR-7, NFR-1 |
| V-11 | Mechanical audit: the set of key literals assigned inside outbound-building code (`bin/sc:520-543`, `:546-567`, `:570-729`, `:1788-1811`) minus `{uuid, password, public_key, short_id}` | Equals `VISIBLE_IN_OUTBOUND` minus `{detour}` | I-2, K-10 |
| V-12 | `_warn_drift()` called directly across four record states (absent, empty, matching, differing) before and after C-2 | Byte-identical stderr in all four | K-14 |
| V-13 | `sc help` in both languages; read `README.md`, `README.zh-CN.md`; grep new zh strings for `失败：` | `config` listed in both help blocks; both READMEs document the command and the FR-9 limit at mirrored positions; no hit | AC-S1, K-12, K-13 |
| V-14 | `.harness/scripts/verify_all` | PASS, no new FAIL or WARN, A.1 included | AC-S2, NFR-3 |
| V-15 | Owner runs the installed `sc config` as root on the live host | **Expected BLOCKED** — no agent in this pipeline holds an interactive sudo credential (R-31); QA files a row and does not substitute an artifact check (R-41) | AC-B9 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RS-1 | Four approaches were declined with reasons (the 5-name minimal allow-list, the document-wide deny-list, textual/regex masking, an unredacted opt-out) and belong in `.harness/rejected-decisions.md`, which is outside this task's diff — the same route T-18 and T-19 took. | PM, at delivery (`07_DELIVERY.md` → `.harness/rejected-decisions.md`) |
| RS-2 | `sc config` inherits R-25/R-29: a non-UTF-8 `settings.json` makes `_load_lang()` (`bin/sc:337-341`, which catches `OSError` but not `ValueError`) raise before `cmd_config()` runs, so the command that exists to inspect a broken host tracebacks on one. Out of scope 6 forbids fixing it here; `cmd_config`'s own K-5 catch shows the correct family. | the open R-25/R-29 pool row (`docs/tasks.md`) |
| RS-3 | Provenance and document can describe two inodes if `sc reload` completes between the `read_text()` and `_config_digest()`: the document is still whole (BC-11, `rename(2)`), but the line may describe the newer file. Both outcomes are non-alarming and no code is bought for it. | `06_TEST_REPORT.md` (stated, not tested) |
| RS-4 | `json.loads` keeps the last of duplicate keys, so a hand-edited `config.json` containing a repeated key is shown without the earlier one. Accepted for the same reason BC-4 refuses to print unparseable text. | `05_CODE_REVIEW.md` / `06_TEST_REPORT.md` (disclosure) |
| RS-5 | Insight candidate for `.harness/insight-index.md`: `sys.stderr` became unconditionally line-buffered only in Python 3.9, so on this project's 3.6 floor any "stderr lands before stdout in a merged capture" claim needs an explicit `sys.stderr.flush()` — the stderr twin of the already-indexed `cmd_status` stdout-buffering entry. | PM at archive time (`07_DELIVERY.md` `## Insight`) |

## Verdict

READY
