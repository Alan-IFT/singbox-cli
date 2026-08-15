# 06 — Rationale · T-23 `state-file-io-contract`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## Trigger record

- **T6.2 fired** (reproducing a developer-claimed measurement): `04_DEVELOPMENT.md` §Insight and
  §Open issues 1/2/3 claim (a) the PEP 540 locale fact, (b) the E-16 row-collapse measurement,
  (c) "AC-8's control is eleven tracebacks and one silently wrong answer". `04_RATIONALE.md` was
  read for the measurement narrative. All three are reproduced below from independent runs.
- **T6.1 / T6.3 did not fire**: every AC's verification step is specified (round 2 corrected the
  three that were not), and every code-review finding routed to stage 6 (RES-1, RES-5) is
  self-contained in `05_CODE_REVIEW.md`.
- `03_RATIONALE.md` §"The R-22 trap, applied criterion by criterion" and §"The design's single
  load-bearing assumption — verified" were read as named triggers. The 22-call-site inventory was
  used only to choose *which* commands to drive; every claim in the contract portion is a run.

## Harness

All fixtures live under
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa/`
and nothing was written into the worktree (RT-7, T-28 owns the committed suite).

| file | what it is |
|---|---|
| `drive.py` | K-13 loader: `os.geteuid` shim (re-exec neutralised without mutating `bin/sc`), `open(..., encoding="utf-8")` on the source, all **eight** path constants repointed into the fixture root **with an assertion per constant**, `SYSTEMD = OPENRC = False`, `SB_BIN` stubbed to a `#!/bin/sh exit 0` script, `_init_files` replaced by a no-op, optional `clash_api` stub, optional `--envproof/--require-non-utf8`, optional `--call <accessor>` for C-2's per-accessor controls, optional `--safe-init`. |
| `mkfix.py` | Fixture builder. 11 `settings.json` variants × 6 `nodes.json` variants; also writes a repointed `proc_if_inet6` so the fixture's stderr carries no unrelated warning line. Every credential is the invented constant `INVENTED-NOT-A-SECRET-*` (K-16 / NFR-8). |
| `run.sh` / `locale_run.sh` | One case each: rebuild fixture, digest before, run, digest after. `locale_run.sh` additionally pins `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0` and refuses (exit 97) if the environment does not prove non-UTF-8. |
| `ac13.sh` | The AC-13 / RES-1 differential. |
| `adv.sh`, `adv2.sh`, `adv3.sh`, `adv4.sh`, `adv5.sh` | The adversarial and boundary batteries. |
| `conc.py`, `count_reads.py`, `check_ac12.py`, `stability.sh` | BC-8 concurrency, V-23 read counting, AC-12 byte comparison, repeat runs. |
| `headclone/` | `git clone --no-hardlinks` of the repository at HEAD `cf164f9`. **A clone, not a `git worktree`.** `sha256(headclone/bin/sc)` = `2584722…` = `sha256(git show HEAD:bin/sc)`; the candidate is `012df62…`. |
| `noE16/sc`, `wrongbuild/sc` | Two mutated **copies** of the candidate, used as negative controls. `bin/sc` itself was never modified. |

### Why `--safe-init` exists (AC-13 / RES-1)

`_init_files()` is normally a no-op in the fixture, because it hard-codes
`Path("/var/lib/sing-box").mkdir(...)`. But RES-1 asks for the **seed dict's key order** and the
`write_text` codec to be compared against a real HEAD checkout, and that seed only runs inside
`_init_files()`. `--safe-init` therefore re-execs *each build's own* `_init_files()` source with the
single unrepointable line removed and asserts that exactly one line was removed and that `/var/lib`
appears nowhere in what it compiled. Nothing else in the function is touched, so the comparison is
between the two builds' real seeding code.

## Full runs whose ≤5-line excerpts the contract portion cites

### Service witness (NFR-7)

```
$ systemctl show -p MainPID -p ActiveEnterTimestamp sing-box      # before, 2026-08-15T13:27:58+08:00
MainPID=2566751
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
$ systemctl show -p MainPID -p ActiveEnterTimestamp sing-box      # after,  2026-08-15T13:40:49+08:00
MainPID=2566751
ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
$ stat -c '%y %n' /etc/sing-box /var/lib/sing-box
2026-08-11 12:13:57.458351383 +0800 /etc/sing-box
2026-07-30 12:59:24.302353878 +0800 /var/lib/sing-box
```

`is-active` was never used. Both mtimes predate this session, so nothing was written under either
path. `/usr/local/bin/sc` was never invoked.

### V-1 / AC-1 — candidate and HEAD on the invalid-UTF-8 `settings.json`

```
=== build=cand fix=ac1 s=badutf8 n=ok argv=[-- ipv6 show]
EXIT=0
--- STDOUT
IPv6 name resolution → auto
AAAA queries are answered empty (setting: auto — this host has no global IPv6 address)
--- STDERR
⚠️  Cannot use <FIX>/ac1/etc/sing-box/settings.json: not valid UTF-8 text
--- settings.json 18de9e76… -> 18de9e76… IDENTICAL

=== build=head fix=ac1 s=badutf8 n=ok argv=[-- ipv6 show]
EXIT=1
--- STDERR
Traceback (most recent call last):
  File ".../headclone/bin/sc", line 3660, in main
    LANG = _load_lang()
  File ".../headclone/bin/sc", line 390, in _load_lang
    return json.loads(SETTINGS_PATH.read_text()).get("lang", "en")
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 10: invalid start byte
```

### V-2 / AC-2 — HEAD control

`sc telemetry show` and `sc status` on the same fixture both exit 1 at HEAD with the identical
`UnicodeDecodeError` from `_load_lang():390`. The candidate exits 0, prints `block` plus the
name list, and writes the same single warning line. The saved-port clause is observed through the
accessor rather than `sc status` (F-16): `--call _saved_clash_port` on that fixture prints
`CALL _saved_clash_port -> None`, i.e. the port is treated as unrecorded.

### V-3 / AC-3 — C-2's two control layers, in full

Through `main()` (`sc ipv6 show`), all four fixtures:

| fixture | candidate | HEAD |
|---|---|---|
| `null` | exit 0, `IPv6 name resolution → auto`, one `⚠️ … the top level must be a JSON object` | exit 1, `AttributeError: 'NoneType' object has no attribute 'get'` |
| `42` | same | exit 1, `AttributeError: 'int' object has no attribute 'get'` |
| `"telemetry"` | same | exit 1, `AttributeError: 'str' object has no attribute 'get'` |
| `[]` | same | exit 1, `AttributeError: 'list' object has no attribute 'get'` |

Exactly C-2's prediction: one `AttributeError` from `_load_lang()` for all four, raised at
`bin/sc:390` outside `main()`'s try.

Per-accessor, by direct call on the imported module — and this is **richer than C-2 predicted**,
because the shape varies by fixture rather than being a fixed `TypeError ×2 / AttributeError ×2 /
silent auto`:

| fixture | `_load_lang` | `_saved_clash_port` | `_ipv6_setting` | `_telemetry_setting` |
|---|---|---|---|---|
| `null` HEAD | `AttributeError` | `AttributeError` | `TypeError: argument of type 'NoneType' is not iterable` | `TypeError` |
| `42` HEAD | `AttributeError` | `AttributeError` | `TypeError: … 'int' is not iterable` | `TypeError` |
| `"telemetry"` HEAD | `AttributeError` | `AttributeError` | **`'auto'` — silently, BC-3's substring accident** | `TypeError: string indices must be integers, not 'str'` |
| `[]` HEAD | `AttributeError` | `AttributeError` | **`'auto'` silently** | **`'block'` silently** |
| every fixture, candidate | `'en'` | `None` | `'auto'` | `'block'` |

So BC-3's substring accident **is** reproducible — but only by calling `_ipv6_setting()` directly,
never through `main()`, exactly as F-2/C-2 ruled. And the `[]` fixture is a second, unnamed instance
of the same hazard: HEAD's `_ipv6_setting()` **and** `_telemetry_setting()` both answer with the
right value for the wrong reason (`"ipv6" not in []` is `True`). Both make the *value* useless as a
discriminator and leave FR-5's warning line plus the absence of a traceback as the only one, which
is what the contract portion reports.

### V-6 / AC-6 and V-7 / AC-7 — the R-27 clobber, and a second clobber nobody had named

C-7's fixture is the valid-UTF-8-but-not-JSON `settings.json` (`this is not json but it is utf-8`).

```
=== build=cand fix=ac7 s=notjson n=ok argv=[-- ls]
EXIT=0   … --- settings.json 9e795e15… -> 9e795e15… IDENTICAL
=== build=head fix=ac7 s=notjson n=ok argv=[-- ls]
EXIT=0   … --- settings.json 9e795e15… -> 1c559f7c… CHANGED
$ cat fix/ac7/etc/sing-box/settings.json     # HEAD, after
{
  "clash_api_port": 29091
}
```

The same fixture under `sc lang zh` shows the clobber compounding at HEAD:

```
=== build=head fix=ac6_notjson s=notjson n=ok argv=[-- lang zh]
EXIT=0
--- STDOUT  语言 → zh
--- settings.json 9e795e15… -> 1053102a… CHANGED
$ cat fix/ac6_notjson/etc/sing-box/settings.json
{ "clash_api_port": 29091, "lang": "zh" }
```

i.e. at HEAD `_resolve_clash_port()` destroys the unreadable document first, and `cmd_lang` then
reads the *replacement* and succeeds with **exit 0** — the user's file is gone and nothing said so.
The candidate exits 1 on both, twice-rendered sentence (C-13), file byte-identical.

### V-8 / AC-8 — the twelve runs, and the HEAD control counted

24 runs (12 candidate + 12 HEAD), machine-counted from `log_ac8.txt`:

```
candidate blocks with Traceback: 0   HEAD blocks with Traceback: 11   total blocks: 24
```

The twelfth HEAD cell is `sc now` on the `{}` fixture: `EXIT=0`, stdout `(none)`. Developer open
issue 3 reproduced exactly — the control is **eleven tracebacks and one silently wrong answer**, and
a report claiming twelve tracebacks would be false.

Candidate causes, one per fixture, identical across `ls` / `now` / `use 1`:
`not valid UTF-8 text` · `not valid JSON (Expecting value: line 1 column 1 (char 0))` ·
`the top level must be a JSON object` · `the "nodes" member must be a JSON array`.
All twelve exit 1 and leave `nodes.json` byte-identical.

C-1 honoured: `sc status` was run alongside on the `{}` fixture and exits **0 on both builds** —
it reads no node store under `SYSTEMD = OPENRC = False`. Not counted.

### V-9 / AC-9 — C-6's stub, and the within-candidate control

With `sc.clash_api` stubbed to `{"proxies": {}}` and `clash_api_port: 29099` recorded,
`_doctor_clash()` reaches E-16's guard on all four fixtures. All eight runs (4 fixtures × 2 builds):
**20 rows, last row present, exit 1, no `Traceback`.** The node-delay row differs only in the cause
text:

```
cand: [UNKNOWN] node delays: cannot read …/nodes.json: not valid UTF-8 text
head: [UNKNOWN] node delays: cannot read …/nodes.json: 'utf-8' codec can't decode byte 0xff in position 27: invalid start byte
```

AC-9 as written is satisfied by both builds → **not discriminating vs HEAD**, which is what C-6
requires be reported rather than a pass. Stage 4's claim reproduced and confirmed.

E-16 is instead verified by a within-candidate negative control (`noE16/sc`, the guard reverted to
`(OSError, ValueError, TypeError, KeyError)` and nothing else changed):

```
$ python3 drive.py --sc noE16/sc --root <fix/e16> --stub-clash -- doctor
EXIT=1 ; rows = 17  (candidate: 20)
[UNKNOWN] Clash API: this check could not run: not valid UTF-8 text
```

Stage 4 measured 22 → 19 rows on its fixture; I measure 20 → 17 on mine. **The delta is the same
−3**, and the mechanism is the same: `_doctor_clash()` returns its four rows as one list, so an
exception anywhere in it collapses Clash API + responding + node delays + DNS lookup into one row.
The absolute row counts differ because the fixtures differ; the claim is reproduced, not refuted.

### V-11 / V-12 — the locale dimension

Environment probe, this host, Python 3.12.3:

```
LC_ALL=C PYTHONCOERCECLOCALE=0            -> stdout=utf-8 preferred=utf-8 fs=utf-8 utf8_mode=1
LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0 -> stdout=ascii preferred=ANSI_X3.4-1968 fs=ascii utf8_mode=0
(no variables)                            -> stdout=utf-8 preferred=UTF-8 fs=utf-8 utf8_mode=0
```

Developer insight reproduced: PEP 540 auto-enables UTF-8 Mode for a `C` `LC_CTYPE`, so the round-1
recipe produced no non-UTF-8 process at all. Every locale run below carries an in-process proof
written by the same interpreter before anything else happens:

```
{"stdout_encoding": "ascii", "stderr_encoding": "ascii", "preferred": "ANSI_X3.4-1968",
 "fsencoding": "ascii", "utf8_mode": 0, "LC_ALL": "C", "PYTHONUTF8": "0",
 "PYTHONCOERCECLOCALE": "0", "is_non_utf8": true}
```

`--require-non-utf8` exits 97 before loading `bin/sc` if that proof fails, so no assertion in AC-11
or AC-12 can be credited to a UTF-8 harness.

**V-11 full outcome.** Candidate: `EXIT=1`, and the traceback is
`File "/home/alan/Programs/singbox-cli/bin/sc", line 2345, in cmd_add / print(t("Added: {tag} ({type} → {server}:{port})", … / UnicodeEncodeError: 'ascii' codec can't encode character '→' in position 29` — i.e. **after** `nodes.json` was rewritten (`CHANGED`). Disk state:

```
raw bytes contain backslash-u escape: False
node count: 3   tags: ['alpha', 'beta', 'h.example:443']
stored password == 'péq' == 'péq' ? True
mode: 0o600
```

HEAD in the same proved environment: `UnicodeEncodeError: 'ascii' codec can't encode character
'\xe9' in position 487` raised at `headclone/bin/sc:512` inside `_write_private`'s `fh.write(text)`,
`nodes.json` **IDENTICAL** — the node is not stored at all.

**V-12 full outcome.** Candidate rewrote the file; HEAD raised
`UnicodeDecodeError: 'ascii' codec can't decode byte 0xe9 in position 15` on the *read* and left the
file untouched. Byte comparison of the pre-existing CJK tag, taken between HEAD's untouched copy
(the "before" bytes) and the candidate's rewritten copy:

```
pre  occurrences of tag bytes  : 2      (the `tag` field and the `active` field)
post occurrences of tag bytes  : 2
post contains backslash-u      : False
node count: 2 tags: ['香港节点', 'ascii.example:8443']  active: 香港节点
first tag field bytes: b'"tag": "\xe9\xa6\x99\xe6\xb8\xaf\xe8\x8a\x82\xe7\x82\xb9'
pre  first tag field : b'"tag": "\xe9\xa6\x99\xe6\xb8\xaf\xe8\x8a\x82\xe7\x82\xb9'
```

**Process-exit clause, both rows: BLOCKED-BY-T-25**, on the ground the run itself printed —
`bin/sc:2345`'s `U+2192` is sc-authored and fails for an all-ASCII URL too (V-12's URL is entirely
ASCII and still exits 1 at that line). Never a pass, never a fail, never dropped (RES-5).

Also observed and worth carrying to T-25: the ⚠️ rule-set warning line **survived** the same
process on stderr, rendered as `⚠️  4/4 rule-sets unusable …`. That is RES-6's
`stderr errors="backslashreplace"` vs strict `stdout` asymmetry, measured rather than read.

### V-13 / AC-13 / RES-1 — the differential

C-5 fixture set, listed and asserted in the contract portion. Both builds started from an **empty**
`/etc/sing-box` and ran their own `_init_files()` seed via `--safe-init`, then one ASCII
`sc add`:

```
settings.json      head=aede6a41b571030f cand=aede6a41b571030f BYTE-IDENTICAL
nodes.json         head=18621cfd54ec31fb cand=18621cfd54ec31fb BYTE-IDENTICAL
config.json        head=ca2d5f7106f7e942 cand=ca2d5f7106f7e942 BYTE-IDENTICAL
.config.sha256     head=543a5aa1c7d1f914 cand=543a5aa1c7d1f914 BYTE-IDENTICAL
$ cat fix/ac13_cand/etc/sing-box/settings.json   # identical on both builds, no trailing newline
{ "default_tun": true, "mode": "rule", "lang": "en", "clash_api_port": 29091 }
```

RES-1 discharged: the seed dict's key order (`default_tun`, `mode`, `lang`) and the `write_text`
codec change are byte-neutral against a real HEAD checkout, and the drift record over those bytes
agrees too. Repeated three times, identical each round.

**And the C-5 restriction was proved load-bearing**, not cosmetic: on an *excluded* input
(`update_interval: "每天"`, the one settings key copied verbatim from `argv`) the two builds
diverge exactly as F-8 predicted —

```
head EXIT=0
  bytes: {   "lang": "zh",   "mode": "rule",   "update_interval": "\u6bcf\u5929",   "clash_api_port": 29091 }
cand EXIT=0
  bytes: {   "lang": "zh",   "mode": "rule",   "update_interval": "每天",   "clash_api_port": 29091 }
```

Correct code fails AC-13 on that input by design (FR-10 / Q-7). Excluding it is required, and this
run is why.

### V-23 / FR-5 — once-ness, measured rather than assumed

`_read_state` was wrapped on the imported module for one `sc ipv6 show` run:

```
_read_state calls: ['settings.json', 'settings.json', 'settings.json', 'settings.json']
settings.json reads: 4
stderr lines naming settings.json: 1
stderr: '⚠️  Cannot use …/settings.json: not valid UTF-8 text\n'
```

Four reads, one line. On a fixture whose `settings.json` *would* have said `lang: zh` but is
truncated JSON, the single line is still English — BC-12 / K-14 structural, not remembered.

### AC-20 / V-20

```
$ bash .harness/scripts/verify_all.sh          # from the repository root
  PASS: 17   WARN: 0   FAIL: 0   SKIP: 1
```

`[A.1] No hardcoded secrets ... PASS` with this task's documents in place (K-16 / NFR-8): every
fixture credential is the invented literal `INVENTED-NOT-A-SECRET-*` and no real credential appears
in any artifact of this stage.

## The R-22 attack, and why AC-5 / AC-10 really are the controls

`03_RATIONALE.md` asserts that AC-1/AC-2/AC-3 are all passed by a build whose reader answers
"unusable" for every document, and that AC-5 and AC-10 are the intended killers. I built that wrong
build (`wrongbuild/sc`: one inserted `raise _unusable(...)` at the top of `_read_state`, nothing
else) and ran it on the **AC-5 fixture** (`lang: zh`, `ipv6: off`, `telemetry: allow`,
`clash_api_port: 29099`):

| criterion shape | wrong build's observable | does the criterion kill it? |
|---|---|---|
| AC-1 (`sc ipv6 show`) | exit 0, `IPv6 name resolution → auto`, one ⚠️ line, no traceback | **no** — passes |
| AC-2 (`sc telemetry show`) | exit 0, `Telemetry name rejection → block`, one ⚠️ line | **no** — passes |
| AC-5 | English not Chinese, `auto` not `off`, `block` not `allow`, **and** a warning line where AC-5 demands none | **yes** |
| AC-10 (`sc ls`, `sc now`) | exit **1**, no rows, no active tag | **yes** |

So the criterion set is sound in exactly the way stage 3 claimed, and — unlike a reading — that is
now measured. The candidate passes AC-5 and AC-10; the wrong build cannot.

## Notes on things deliberately not done

- **No `git worktree`** anywhere; the HEAD baseline is a clone, per the brief.
- **`bin/sc` was never modified.** Both negative controls are copies under the scratchpad, and both
  were verified to differ from the candidate in exactly the one intended line.
- **`sc update-interval`'s systemd arm was not exercised.** Reaching it needs `SYSTEMD = True`, and
  its first act is `Path("/etc/systemd/system/sing-box-rules-update.timer.d").mkdir(...)` +
  `systemctl daemon-reload` + `systemctl restart` — an unrepointable literal on the live host.
  NFR-7 forbids it, so the FR-6 clause for that one command is reported as not reachable under K-13
  rather than substituted. See the contract portion's `## Defects found` row DEF-1.
- **`sc doctor` reaches the network** (`egress IP`, `DNS lookup`). That is a read of the public
  internet by an already-read-only diagnostic; no service was touched and no host file was written.
