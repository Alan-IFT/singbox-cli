> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Round 2 — how `bin/sc` was proved byte-unchanged without a shell

The developer reports `git diff --numstat -- bin/sc` still reading `76 51`. That is their word, and
C-8 is the constraint their word is about, so it was confirmed independently.

The method exploits the fact that this reviewer recorded **absolute line numbers** throughout round 1.
Every one of those anchors was re-read in round 2 at its recorded number and compared to the recorded
content:

`:352` (I-9's key), `:386-392` (`_load_lang`), `:407-416` (`_saved_clash_port`), `:419-440`
(`_resolve_clash_port`, including K-6's arm at `:434-438`), `:498-524` (`_write_private`, whole),
`:527-538` (`_init_files`), `:541-569` (`_unusable` + `_read_state`, whole), `:572-586`
(`load_nodes` / `save_nodes` / `load_settings`), `:589-604` (`_settings_or_empty` / `save_settings`),
`:1602-1619` (`_ipv6_setting`), `:1800-1821` (`_telemetry_setting`), `:1960-1973`
(`_record_generated`), `:2098-2111` (`generate_config`'s write + K-5 renderer), `:2326-2350`
(`cmd_add`, whole), `:2786-2797` (`_doctor_clash`'s guard), `:3475-3484` (`cmd_lang`), `:3694-3720`
(`main()`'s arm and EOF).

All identical. The inference is not a spot check: an inserted or deleted line anywhere would shift
**every** anchor below it, and these anchors run from line 352 to the last line of a 3720-line file
with no gap larger than a few hundred lines. A `def`-line grep independently placed
`_status_view` 967, `usable_tags` 1016, `_warn_degraded` 1087, `_runtime_overlay` 1866,
`generate_config` 2027, `cmd_add` 2326, `_doctor_clash` 2747, `cmd_lang` 3475, `main` 3644 —
consistent with every round-1 citation inside those functions.

The one residue worth naming honestly: an **equal-length in-place substitution** between two anchors
would not shift anything and would not be caught. That residue is confined to code the diff never
touched, because every region the diff *did* touch was re-read in full this round rather than
sampled. C-8, K-1…K-16, C-9 and C-10 therefore stand without re-derivation.

## Round 2 — why CR-1 is closed on substance rather than reworded

The test applied is the one from round 1: *is the bullet true as a whole, and would a user who reads
it and then runs `sc add` under a proved non-UTF-8 locale be surprised in either direction?*

The shipped text makes exactly two claims about that locale, and they now point in opposite
directions on purpose:

1. **The write succeeds.** 「写入不再失败、凭据按 UTF-8 原样落盘」. Verified: `save_nodes:578` →
   `_write_private:507` `os.fdopen(fd, "w", encoding="utf-8")`, which cannot consult the locale.
2. **The command still fails.** 「在这类环境下 `sc add` 仍然会在打印它自己那行成功提示（`Added: … (… → …)`，
   其中的 `→` 是 `sc` 自己写的字符，因此**分享链接全是 ASCII 时同样会发生**）时失败，并以非 0 退出 —— 但此时
   **节点已经正确写进 `nodes.json` 了**」.

Claim 2 was checked against the control flow, not accepted on its face. In `cmd_add`, `save_nodes()`
is at `bin/sc:2343` and the `U+2192` print at `:2345`, with only `reload_or_restart()` between them —
whose own diagnostics go to **stderr**, which is `backslashreplace` (see below) and therefore does not
raise first. So the failure really does happen after the data is durable, and 「回到 UTF-8 环境下
`sc ls` 就能看到它」 is true. The `⚠️` in the alternate arm at `:2349` fails the same way, which does
not weaken the statement: in both arms the node is already on disk and must not be re-added, which is
the only thing the user has to act on.

The parenthetical 「写进文件的就是那串字符本身，而不是 `\uXXXX`，也不再是一段 `UnicodeEncodeError`」 is
worth noting for its precision. `ensure_ascii=False` was already at HEAD for `nodes.json`, so
「不是 `\uXXXX`」 is descriptive there and is a genuine change only for `settings.json` (E-13); the
change-marking 「不再」 attaches solely to the `UnicodeEncodeError`, which *is* new for both. A looser
draft that wrote 「不再是 `\uXXXX`」 would have been false for `nodes.json`. It does not.

BC-14 is now honoured affirmatively rather than by omission — the bullet closes with 「同样地，把一个
中文节点名**打印**到终端也仍然会失败」, which is the exact statement BC-14 exists to protect. K-15's
disk-only boundary is stated as 「本项终结的只是这两份文档在**磁盘**上的编码问题」 and is not breached by
any earlier clause, which was the whole of round 1's objection.

## Round 2 — CR-8, and why it is a NIT rather than a MINOR

The clause 「写入失败（包括参数根本无法编码成 UTF-8）会渲染成已有的那句「无法写入 …」并带上原因，原文件保持
不变、不留临时文件」 follows a sentence whose subject is four documents, one of which is
`settings.json` — and for `settings.json` the clause would be false on two counts: `save_settings()`
`:602-604` carries **no** `except`, so an `OSError` propagates past `main():3700` (which catches only
`OverrideError`) as a traceback, and `Path.write_text` truncates, so the previous document is *not*
preserved. `_record_generated():1972`'s `except OSError: pass` is a third document whose write failure
is silent rather than rendered.

It is nevertheless a NIT, not a MINOR, because the clause carries two independent internal markers
that scope it to the `_write_private` pair: the parenthetical 「参数根本无法编码成 UTF-8」 is precisely
E-12/E-15's widened `ValueError` catch and exists nowhere else in the file, and 「不留临时文件」 is the
temp-then-replace mechanism `settings.json` deliberately does not have (AC-14). So the sentence is
under-specified rather than false, and the misreading costs a user nothing they can act on wrongly —
unlike CR-1, which would have made a user re-add a node that was already stored.

It is recorded here that this clause is **unchanged since round 1** and was passed by this reviewer
then. Filing it now is a correction of my own coverage, not a regression by the developer, and it is
deliberately given a severity that cannot move the verdict.

## Round 2 — what was checked for C-12 and what a `git status` still owes

The developer's `04` states the touched set and that no new file was created. Read-only confirmation
this round: `bin/` contains only `sc`; `systemd/` and `.harness/scripts/` hold exactly the files they
held; the feature directory holds eleven documents — round 1's nine plus `05_CODE_REVIEW.md` and
`05_RATIONALE.md`, which the PM wrote from this reviewer's round-1 return — and no twelfth.

What cannot be confirmed by reading is the *tracked* change set. The environment supplied a
`git status` snapshot in this reviewer's context, and it must not be used: it lists
`?? docs/features/proxy-urltest-group/`, but that directory now lives at
`docs/features/_archived/proxy-urltest-group/`, so the snapshot predates T-22's archival and several
commits. It names neither `bin/sc` nor this task's directory. RES-2 therefore stands unchanged and
unweakened: a real `git status` before commit is the only thing that discharges C-12.

One near-finding was considered and deliberately not filed. `docs/dev-map.md:52` cites
`_runtime_overlay()` at `bin/sc:1815`, `usable_tags()` at `:905` and `_warn_degraded()` at `:976`;
the shipped file has them at 1866, 1016 and 1087. Those references were already wrong at HEAD by
roughly 50–110 lines (this diff's net shift above line 1000 is about +44 lines, and above 1815 about
−19), so the staleness is pre-existing and this diff neither created nor worsened it in any way a
reader could attribute to T-23. Filing it would be scope creep into a row the ledger never touched.

## C-8 — the independent line count, reconstructed (round 1, carried forward)

This reviewer holds no shell, so `git diff --stat` could not be run. Instead the added and deleted
lines were reconstructed **edit id by edit id** from the shipped file, using the ledger's description
of the HEAD shape and the gate's HEAD line numbers. The reconstruction is falsifiable: it had to land
on two independent totals at once, and it did.

| edit | added | deleted | of the added, code |
|---|---|---|---|
| E-17 `TRANSLATIONS` `:352` | 1 | 0 | 1 |
| E-6 `_load_lang()` `:390-392` | 3 | 4 | 1 |
| E-7 `_saved_clash_port()` `:415` | 1 | 5 | 1 |
| E-8 `_resolve_clash_port()` `:436-438` | 3 | 2 | 2 |
| E-11 `_write_private()` `:506-507` | 2 | 1 | 1 |
| E-14 `_init_files()` `:537-538` | 2 | 2 | 1 |
| E-1 `_unusable` `:541-545` | 5 | 0 | 4 |
| E-2 `_read_state` `:548-569` | 22 | 0 | 16 |
| E-3 `load_nodes()` `:573` | 1 | 1 | 1 |
| E-12 `save_nodes()` `:579-582` | 3 | 2 | 2 |
| E-4 `load_settings()` `:586` | 1 | 1 | 1 |
| E-5 `_settings_or_empty` `:589-599` | 11 | 0 | 8 |
| E-13 `save_settings()` `:603-604` | 2 | 1 | 1 |
| E-9 `_ipv6_setting()` | 2 | 5 | 1 |
| E-10 `_telemetry_setting()` | 4 | 20 | 1 |
| E-15 `generate_config()` `:2105-2107` | 3 | 3 | 3 |
| E-16 `_doctor_clash()` `:2791` | 1 | 1 | 1 |
| C-4 `:1224-1225`, `:3701` | 3 | 3 | 0 |
| blank separators (3 new module-level functions) | 6 | 0 | 0 |
| **total** | **76** | **51** | **46** |

`_read_state` counted line by line: `def` (1) + docstring `:549-554` (6) + `try` + the `json.loads`
line + thirteen lines `:557-569` = 22, of which 16 are code. `_settings_or_empty`: `def` + 3
docstring + 7 body = 11, of which 8 are code. `_unusable`: `def` + 1 docstring + 3 body = 5, of which
4 are code. `46 + 24 + 6 = 76` closes.

Against C-8's amended cap — `≤ +76 added, ≤ 48 code` — the added figure is **exactly at** the cap and
the code figure is **2 under**. The developer's reported numbers are reproduced independently, and
the reconstruction also confirms that `ensure_ascii=False` at `:578` and `:2104` was **already at
HEAD**: E-12 (`+3/−2`) and E-15 (`+3/−3`) only balance if those two arguments are not new. That
matters, because a silently-added `ensure_ascii` would have been an unledgered edit, and `02`
§Migration's claim that the *only* byte-level escaping change is in `settings.json` would have been
false. It is true.

Round 2 adds nothing to this table and subtracts nothing: the file it was computed from is unchanged.

## C-10 — why `isinstance(e, FileNotFoundError)` is not a fourth decide-site (round 1, carried forward)

C-10's trip-wire is a fifth `try` / `except OverrideError` / `isinstance` guard **around any state
read**. The three `isinstance` calls the developer declares in D-2 are all *inside* `_read_state`,
which is the read — there is no read for them to be around.

More precisely, the distinction that makes AC-18 checkable is between *producing* an outcome and
*deciding what the outcome means*. `_read_state` produces `usable` / `absent` / `unusable`; that is
one site by construction, and `isinstance(e, FileNotFoundError)` at `:558` merely picks which of the
reader's own four causes applies to the OSError the reader's own `read_bytes()` raised. `:565` and
`:567` are FR-3's two shape checks, which I-1 names as the reader's job in so many words. Nothing
outside the reader has gained a way to form its own opinion — verified by grep over every `isinstance`
in the file and by re-reading all 16 unguarded call sites.

The two `except OverrideError` arms in `generate_config()` (`:2038`, `:2072`) deserve their own note
because a careless enumeration would count them. They are pre-existing, they wrap `_load_override()`
and `_merge()` — the **user's** document — and they set `.path = OVERRIDE_PATH` before re-raising.
`load_nodes()` sits at `:2042`, *between* them, deliberately: `03_RATIONALE.md` records that this
placement is what stops a broken node store being mislabelled as the user's override file, and the
shipped file preserves it exactly.

## The stderr/stdout asymmetry, and the finding it dissolved (round 1, carried forward)

The first draft of this review carried a MAJOR against `_settings_or_empty()`'s new line —
`sys.stderr.write("⚠️  " + …)` at `:597-598` — on the theory that under a proved non-UTF-8 locale the
`U+26A0` would raise `UnicodeEncodeError` inside `_load_lang()`, which `main()` calls at `:3682` /
`:3685` **outside** its `try`, producing a traceback for every command including `sc doctor` and
falsifying FR-9's absolute wording.

That is wrong, and the reason is worth recording because it also explains why the project has lived
with `⚠️ ` on stderr since T-13 without incident. Since CPython 3.5, `sys.stderr` is created with
`errors="backslashreplace"` while `sys.stdout` is strict. So the new warning line degrades under an
ascii locale to `\u26a0\ufe0f  Cannot use /etc/sing-box/settings.json: not valid UTF-8 text` — ugly,
but one line, no exception, exit status untouched. FR-5 and FR-9 both hold. `cmd_add`'s failure is a
`print()` to **stdout**, which is a different stream with a different error handler.

The finding was withdrawn and re-filed as RES-6, because it is precisely the distinction T-25 will
need: "make sc's output survive a non-UTF-8 locale" is a stdout problem, and criteria written against
stderr will verify nothing. It is also what lets round 2 state that `reload_or_restart()`'s
diagnostics between `save_nodes()` and the failing `print()` do not raise first.

## What was checked and found clean, so a further round need not redo it

Carried forward from round 1 unchanged, because `bin/sc` is byte-unchanged and every item below is a
property of `bin/sc` alone.

- **T-13.** `_write_private()` `:501-524` compared line by line against
  `docs/features/_archived/config-write-permission-hardening/02_SOLUTION_DESIGN.md` §3.3's timeline.
  `t0` `mkstemp(dir=…)` with `O_CREAT|O_EXCL|O_NOFOLLOW` and `0o600` as a umask-maskable upper bound;
  `t1` `fchmod` on the still-empty descriptor makes it exactly `0600`; `t2` the first credential byte
  lands at `0600`; `t3` `os.replace` publishes an inode that was `0600` before it was nameable at the
  target. The `finally` still closes a live `fd` and unlinks a surviving `tmp`. `encoding="utf-8"` is
  a keyword argument to `os.fdopen` — it selects the `TextIOWrapper`'s codec and opens no second
  descriptor, exactly as Q-C rules. `newline` is still `None`, which on Linux maps `\n` to `\n`, so
  AC-13 is not disturbed by it either.
- **T-14.** `_config_digest()` `:1943-1953` still streams `CFG_PATH.open("rb")` in 64 KiB chunks into
  `hashlib.sha256()`. No decode was added anywhere in the quartet, and `_record_generated()` still
  writes a 65-byte ASCII digest through the one writer.
- **Single-writer properties, by grep rather than by assertion.** Every occurrence of `SETTINGS_PATH`
  and `NODES_PATH` in `bin/sc` was listed: the only write of `settings.json` is `save_settings():604`,
  the only write of `nodes.json` is `save_nodes():578` → `_write_private()`, and the only writes of
  `config.json` and the drift record are `generate_config():2104` and `_record_generated():1971`,
  both through `_write_private()`. `_init_files()` `:531-538` reaches both documents only through
  those writers, which is FR-12 discharged.
- **K-5 at every widened site.** Only two renderers were widened, and both carry
  `getattr(e, "strerror", None) or str(e)`. `_read_state:560`'s bare `e.strerror` is safe because it
  is inside an `OSError`-only arm; `_record_generated:1972`'s `except OSError` was not widened and
  writes ASCII.
- **BOM.** A UTF-8 file with a byte-order mark decodes to `\ufeff{…}` and fails `json.loads` as
  "not valid JSON". Identical to HEAD's behaviour and to `_load_override()`'s at `:1531-1537`, so it
  is not a regression, and Q-11's "no policies copied from the override reader" makes adding a strip
  out of scope. Not filed.
- **Recursion.** A pathologically nested state document still raises `RecursionError` past the
  reader's `except ValueError`. Identical to HEAD and to `_load_override()`; Q-11 declines a size cap
  by name. Not filed.

## Safety

No command was executed in either round of this stage. `/usr/local/bin/sc` was not run; `bin/sc` was
read as text only and never imported. Nothing under `/etc/sing-box` or `/var/lib/sing-box` was read
or written, and the live service was never queried. No credential, real or fixture, appears in either
portion of this stage document.

One risk is worth stating even though it was not triggered here: `bin/sc` re-execs itself through
`sudo` at import time (`# Auto-elevate`), so any future stage that loads it as a module without the
`dev-map.md` neutralisation recipe will act on the owner's live installation. K-13 states this; it is
repeated because a code reviewer is the stage most likely to reach for "just import it and check".
