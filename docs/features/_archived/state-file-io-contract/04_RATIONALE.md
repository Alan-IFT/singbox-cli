# 04 — Rationale · T-23 `state-file-io-contract`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

Rule 70 declares no `## Stage-doc boundary rule` in this project (confirmed again at this stage, Q-13's
thirteenth), so `04_DEVELOPMENT.md`'s schema is applied as written and everything below — transcripts,
measurement narratives and the argument behind D-1…D-3 — lives here.

## The fixture, and the two ways it lied before it told the truth

Every run below used one loader built to K-13 and the `dev-map.md` recipe: `os.geteuid` shimmed to `0`
so the import-time `sudo` re-exec is not taken (restored in a `finally`), all eight path constants
repointed into a `mkdtemp()` root **and each asserted to resolve inside it**, `SYSTEMD = OPENRC = False`,
`SB_BIN` pointed at a stub script, and `sc._init_files` replaced by a no-op before `main()` was driven
— that function hard-codes `/var/lib/sing-box` and is not repointable. Nothing ran as root, nothing
touched `/etc/sing-box`, `/var/lib/sing-box`, `/usr/local/bin/sc` or the live service, and no fixture
contains a real credential (every password literal is `PLACEHOLDER-n`, `pw`, or the AC's own `péq`).
Both builds were driven through the *same* loader at the *same* fixture path; the control build is a
`git clone` of this repository at `cf164f9`, not a `git worktree`.

**Lie 1 — the harness decoded `bin/sc` with the process locale.** The first non-UTF-8 run reported, for
*both* builds, `UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 29`, which reads
exactly like the product defect under test. It is not: `exec(compile(open("bin/sc").read(), …))` opens
the **source** with the locale encoding, and `bin/sc` holds `⚠️` and a Chinese translation table. The
interpreter itself always decodes source as UTF-8 (PEP 263), so the plain `open()` is a harness artefact.
Pinning `open(src, encoding="utf-8")` in the loader made both builds behave differently again — which is
the point of a control.

**Lie 2 — `LC_ALL=C PYTHONCOERCECLOCALE=0` is a UTF-8 environment.** Measured on this host:

| environment | `sys.stdout.encoding` | `locale.getpreferredencoding(False)` | `sys.getfilesystemencoding()` |
|---|---|---|---|
| *(inherited)* | `utf-8` | `UTF-8` | `utf-8` |
| `LC_ALL=C` | `utf-8` | `utf-8` | `utf-8` |
| `LC_ALL=C PYTHONCOERCECLOCALE=0` | `utf-8` | `utf-8` | `utf-8` |
| `LC_ALL=C PYTHONCOERCECLOCALE=0 PYTHONUTF8=0` | **`ascii`** | **`ANSI_X3.4-1968`** | **`ascii`** |

`01_RATIONALE.md` reasons only about PEP 538 (C-locale coercion, which `PYTHONCOERCECLOCALE=0` does
disable) and misses PEP 540: **UTF-8 Mode is auto-enabled whenever `LC_CTYPE` is `C` or `POSIX`**, and
`PYTHONCOERCECLOCALE=0` does not touch it. So AC-11/AC-12/V-11/V-12 as written select a fully UTF-8
process on Python 3.7+ (3.12.3 here). Under that environment HEAD passes both criteria — it stored
`péq` correctly and rewrote the `香港节点` fixture without a murmur — so the criteria are not merely
weak, they are **inverted**: they would have certified the unfixed build. The same rationale's
§"The write end" records R-62's own measurement as `LC_ALL=C PYTHONUTF8=0`, i.e. the correct recipe was
in the task's own documents and was dropped when the criteria were written. Every locale claim in
`04_DEVELOPMENT.md` uses `LC_ALL=C PYTHONCOERCECLOCALE=0 PYTHONUTF8=0`, and the K-14 direction was
proved separately: on a **usable** `lang: zh` fixture the run prints `IPv6 域名解析 → off`, on an
unusable one it prints `IPv6 name resolution → auto` — the vacuity trap NFR-9 names.

## Measurement transcripts

**V-1 / AC-1 — non-UTF-8 `settings.json`, `sc ipv6 show`.** Candidate: `exit=0`, stdout
`IPv6 name resolution → auto`, stderr exactly one line,
`⚠️  Cannot use …/settings.json: not valid UTF-8 text`, `Traceback` count 0. Control: `exit=99`
(the driver's marker for an uncaught exception), 0 warning lines, 1 traceback. V-2 on the same fixture
with `sc telemetry show`: candidate `block` plus the same single line; control tracebacks.

**V-3 / AC-3 — `null`, `42`, `"telemetry"`, `[]`.** Candidate: 4/4 `exit=0`, one warning line each, no
traceback, `auto` reached through the default path. Control: 4/4 `AttributeError` at `bin/sc:390` in
`_load_lang()` — `'NoneType'`, `'int'`, `'str'`, `'list'` object has no attribute `get`. C-2's
prediction, verified rather than assumed; the developer's first draft of that row guessed
`_saved_clash_port()` and was wrong. The `"telemetry"` fixture is the BC-3 case: HEAD's
`"ipv6" not in "telemetry"` was a legal substring test answering `auto` with no exception, and the new
build reaches `auto` only because `{}` has no `ipv6` key — which is why the warning line, not the
value, is the discriminator.

**V-4 / AC-4 — absent `settings.json`.** Both builds: `exit=0`, **zero** warning lines, and both create
`settings.json` during the run — not by seeding (`_init_files` is a no-op in the fixture) but through
`_resolve_clash_port()`'s legitimate persist step, which on the candidate goes through
`load_settings()` → `{}` → `save_settings({"clash_api_port": …})`. Absent is not a failure and must not
warn: confirmed.

**V-6 / AC-6 — `sc lang zh` over an unusable document.** Candidate `exit=1`, digest unchanged, last
stderr line `Cannot use …/settings.json: not valid JSON (Expecting property name enclosed in double
quotes: line 1 column 2 (char 1))`, and **two** occurrences of the sentence in the run (C-13).
Control: `exit=0`, digest **changed** — HEAD silently rewrote the user's broken document.

**V-7 / AC-7 / C-7 — the R-27 clobber control.** On `this is not json but it is utf-8`: candidate leaves
the file byte-identical; HEAD leaves `{\n  "clash_api_port": 29091\n}` in its place, i.e. it destroys
recoverable text to record a port. This is the row's headline defect and it reproduces exactly once —
on this fixture, which is why C-7 restricts the control to it.

**V-8 / AC-8 / C-1 — twelve runs.** Candidate 12/12: `exit=1`, one sentence naming `nodes.json`,
no traceback, file byte-identical. Control 11/12 tracebacks — `UnicodeDecodeError` (non-UTF-8, ×3),
`JSONDecodeError` (non-JSON, ×3), `TypeError: list indices must be integers` / `AttributeError: 'list'
object has no attribute 'get'` (non-object, ×3), `KeyError: 'nodes'` (`{}` × `ls`, `use 1`). The twelfth,
`sc now` over `{}`, exits **0** at HEAD and prints `(none)`: a silently wrong answer, not a traceback.
The cell still discriminates, but AC-8's "a traceback for all twelve" is false and `06` should not
repeat it.

**V-9 / AC-9 / C-6 — doctor.** With `clash_api` stubbed to a dict and `clash_api_port` recorded, the
node-delay row is reached on all four fixtures and reads
`[UNKNOWN] node delays: cannot read …/nodes.json: not valid UTF-8 text` (and the matching cause for the
others). HEAD produces the identical table, so **AC-9 does not discriminate against HEAD**. E-16 was
therefore verified by a negative control inside the candidate: reverting only the guard line, the table
goes from 22 rows to 19 and the Clash section collapses to one row,
`[UNKNOWN] Clash API: this check could not run: not valid UTF-8 text` — losing "Clash API: 127.0.0.1:29099",
"Clash API responding: yes", the node-delay row and the DNS row. Doctor still printed no traceback and
still exited 1 either way, which is precisely why F-9 was right that "no `Traceback`" cannot detect E-16.

**V-11 / AC-11 and V-12 / AC-12 — the corrected locale.** Candidate: `nodes.json` holds `péq`
byte-exactly with no `\uXXXX`; the pre-existing `香港节点` tag survives a full read-modify-write
byte-identically and the node count goes 1 → 2; `config.json`, `nodes.json` and the drift record are
`0600` and `settings.json` keeps HEAD's `0664` under this umask (AC-14). Control: `UnicodeEncodeError:
'ascii' codec can't encode character '\xe9'` while **writing** (V-11, nothing stored) and
`UnicodeDecodeError: 'ascii' codec can't decode byte 0xe9` while **reading** (V-12, no config written,
node count stays 1). Both runs then die on the candidate side too — at `bin/sc:2345`,
`print(t("Added: {tag} ({type} → {server}:{port})"))`, `UnicodeEncodeError … '→'`. The disk layer is
closed; the terminal layer is T-25's, exactly as BC-14 and RT-3 say. The AC's `exit 0` clause cannot be
met while `cmd_add`'s own success line contains an arrow, and no code in scope may change that line.

**BC-10 / FR-11 / Q-9 — the lone surrogate.** `sc add 'trojan://pw@h.example:443#café'` with the tag's
bytes raw in `argv` under the corrected locale. Candidate: `exit=1`, one sentence,
`Could not write …/nodes.json: 'utf-8' codec can't encode characters in position 82-83: surrogates not
allowed`, `nodes.json` byte-identical, **zero** temporary files left in the directory. Control:
`UnicodeEncodeError` traceback. This is the single measurement that justifies E-12/E-15's widened catch
*and* K-5's `getattr` — `e.strerror` on that exception would raise `AttributeError` inside the handler,
which is the failure Q-9 exists to prevent, and the cause clause here is non-empty precisely because it
fell through to `str(e)`.

**V-13 / AC-13 / C-5.** Same ASCII, sc-authored fixture driven through `sc add` then `sc telemetry
allow` on both builds under a UTF-8 locale: `settings.json`, `nodes.json` and `config.json` are
byte-identical across builds. No `update_interval` and no hand-edited value is in the fixture, per C-5.

**V-23 / FR-5 / BC-12.** One `sc ipv6 show` run over an unusable document that three readers consult:
exactly one `Cannot use …` line, in English, on a fixture whose intended `lang` is `zh`.

## Why D-1 and D-2 were taken, in budget terms

The design's `+70` never budgeted two costs the shipped file actually charges: **6 blank lines**, which
are what three new module-level functions cost under this file's two-blank-line convention, and
**C-4's 3 prose lines**, which the gate added after the budget was fixed. C-8's headroom is `+6`. So
`70 + 6 + 3 = 79` against a cap of `76`, and three lines had to come from somewhere before a single
docstring was written.

D-1 (one `try` for the decode and the parse) and D-2 (`isinstance(e, FileNotFoundError)` inside the
single `OSError` arm) return exactly 4 code lines — a separate `try:` + `raw = path.read_bytes()` pair,
and a separate `except FileNotFoundError as e:` + its own `raise`. Q-D licenses the first explicitly and
calls the second's shape free. The alternative — spending those 4 lines and taking them out of the
docstrings instead — was rejected because the docstrings were *already* cut to the bone: `_read_state`'s
is 6 lines against the ledger's 7, `_settings_or_empty`'s is 3 against 4, and `_unusable`'s is 1 against
2. The final measurement is `+76 / −51`, 46 code, which is the ledger's own `46 code` figure exactly and
`+6` on its added-line figure, all six of them blank separators.

The one thing not traded away: the reader still raises through `_unusable()` at every one of its five
raise sites, so RT-1's promise to T-24 — one construction site to move — holds literally.

## What was deliberately not done

- No guard, `try` or `isinstance` at any of the 16 unguarded call sites (K-12, C-10). The whole design is
  that they inherit the contract; a guard at even one would make the count of decide-sites a matter of
  opinion again.
- No write-failure guard in `save_settings()` (C-11), no UTF-8 decode for `cmd_config()`'s or
  `_doctor_ipv6()`'s `config.json` reads (K-10, Q-6), no change to `_load_override()` (`bin/sc:1435-1496`),
  to `OverrideError`'s `path` attribute or to `main()`'s three executable handler lines (K-9 as relaxed
  by C-4), and no second translation key (K-11).
- No `en` table for `TRANSLATIONS`, and no re-use of the `失败` literal: I-9's Chinese entry is
  `"{member}" 成员必须是 JSON 数组`, which contains neither.
- No committed test artifact. Everything in this document was produced by fixtures under the session
  scratchpad, which are not in the worktree and are not offered to T-28 as a suite (RT-7).
