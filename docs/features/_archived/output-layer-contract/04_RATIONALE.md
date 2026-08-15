> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

# T-25 — output-layer-contract · Development Rationale

Everything here is measurement transcript or argument. The binding record is
`04_DEVELOPMENT.md`. HEAD under test: `6c034d62ea30421dc61733ad79bb233d4693b5b6`.

## §1 — The harness, and why it is shaped this way (C-1, C-2, C-12)

Written outside the repository (K-5, out-of-scope 10, NFR-2), five files, none committed:
`fixture.py` (the `docs/dev-map.md:118-151` recipe + C-1's neutralisation and assertions),
`run.py` (one `sc` command through `main()`, stdout = whatever fd 1 the caller gave it),
`pair.sh` (three or four commands on one fixture, one build), `diff.sh` (candidate then HEAD
at the SAME fixture path), `enum_keys.py` / `check_ac3.py` / `render.py` / `cfg.py`.

**C-1's neutralisation.** `sc._init_files` is rebound, after the module `exec` and before any
command, to a function that makes `CFG_DIR` and `RULES_DIR` (both inside the `mkdtemp()` root)
and a `<root>/var-lib-sing-box` stand-in, then seeds through `save_nodes()` / `save_settings()`
exactly as `bin/sc:545-552` does. `bin/sc:544`'s `Path("/var/lib/sing-box").mkdir` (HEAD `:532`)
is therefore never reached on any code path in any run. The replacement carries a
`NEUTRALISED = True` attribute, and every run prints its value — a harness that forgot the rebind
would print `False` rather than pass silently.

**The auto-elevate line, and a process error of mine worth recording.** `bin/sc:125-126` is
module-scope: `if os.geteuid() != 0: os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] +
sys.argv[1:])`. Importing `bin/sc` as an ordinary user therefore does not load the file under test
at all — it replaces the process with the **installed** `sc`, under password-less `sudo`, against
the **live** host, carrying whatever `sys.argv` the harness happens to hold. `docs/dev-map.md:121-158`
already says this and supplies the loader verbatim, under the heading *"use this one, do not
re-invent it"*. Round 1's fixture used it. For round 2's V-17 I wrote a fresh `importlib` loader in
a fresh context **without** re-reading that row, and hit exactly the trap it exists to prevent: the
first attempt re-exec'd into the installed build, which is older, so argparse rejected the
harness's own argv (`invalid choice: '…/bin/sc'`, exit 2) before `_init_files()` or any command was
reached — no write, no service contact, but the run was void. Every V-17 result in
`04_DEVELOPMENT.md` was then re-taken on the dev-map recipe itself (module shim for `os`,
`geteuid → 0`, `sys.modules["os"]` restored in a `finally`), with all eight constants including
`IF_INET6_PATH` repointed and asserted, and `SYSTEMD = OPENRC = False`. The five cases reproduce
byte-for-byte on the recipe loader. The lesson is not about `bin/sc`; it is that the recipe row is
the isolation contract and skipping it costs a void run.

**C-1's assertion.** Two halves, both per run:
1. each of the eight path constants is `Path(...).resolve()`d and asserted to equal the root or
   to start with `root + os.sep`; anything else raises `PATH CONSTANT ESCAPES ROOT: <name> = <v>`
   before the command runs;
2. `/var/lib/sing-box` **and** `/etc/sing-box` are witnessed before the run and again in an
   `atexit` hook — `(exists, st_mtime_ns, st_ctime_ns, sorted(listdir))` — and asserted equal.
   `atexit`, not `finally`, so the witness still runs when the command aborts with a traceback
   (the AC-9 control does exactly that).

Both protected paths exist on this host and are root-owned (`/etc/sing-box` holds a real
`config.json`), so the witness is a real observation, not a vacuous "absent before, absent
after". Every V-step below ran with both halves in place; no V-step result predates them.

**C-2 / F-10.** No step uses `io.StringIO` or `contextlib.redirect_stdout`. `run.py` is a child
process whose fd 1 is a shell-supplied file or pipe, so `sys.stdout` is a real `TextIOWrapper`
with a `.buffer` and K-3's guard takes its true arm. The one place a capture object is
recorded per step is the `## Condition disposition` C-2 row.

**C-12.** Baselines come from `git clone /home/alan/Programs/singbox-cli <scratch>/head-clone`
(`git status --porcelain` empty; `cmp` against the worktree's pre-edit `bin/sc` identical), never
a `git worktree`. Both builds run at `<scratch>/fixture-root`, wiped and rebuilt between them.

## §2 — V-4 / K-5: the call-site enumeration, in full

`ast.parse` of `bin/sc`; every `Call` whose `func` is `Name(id='t')`; first argument resolved
when `Constant(str)` (implicit concatenation is folded by the parser, so `bin/sc:1404-1405`-style
keys resolve whole); anything else reported by line number as **undecidable**, never as a pass.

HEAD (run before any string was edited):

```
call sites total 205 | resolved 202 (159 distinct) | UNDECIDABLE 3 @ 1054, 2978, 2978
zh table keys 182 | OFFENDERS 0 | identifier-shaped keys in the zh table: 5
  ['ls.active','ls.address','ls.idx','ls.name','ls.type']
  undecidable @1054 Name('key') · @2978 Name('label') · @2978 Subscript(DOCTOR_MARK[cls])
```

Candidate (same script, after the edits): `206 / 203 (160 distinct) / 3 undecidable @1067, 2999,
2999 / zh keys 183 / OFFENDERS 0 / identifier-shaped keys **0**`. The three undecidable sites are
the same three, moved by the added lines.

**The three K-6 sites, resolved by name and checked against the table** (second script, output
verbatim):

```
DOCTOR_SECTIONS+probe row labels   n=16 missing=[]
DOCTOR_MARK                        n= 3 missing=[]
_age_text unit tuple               n= 3 missing=[]
```

- `bin/sc:1067` `t(key, n=…)` — key ∈ the three literals of `_age_text`'s unit tuple.
- `bin/sc:2999` `t(DOCTOR_MARK[cls])` — `OK` / `UNKNOWN` / `PROBLEM` (`bin/sc:2477`).
- `bin/sc:2999` `t(label)` — **16** distinct static labels, not ten: the nine `DOCTOR_SECTIONS`
  labels (`bin/sc:2976-2986`) plus `sing-box version`, `config drift`, `sing-box check`,
  `boot autostart`, `TUN addresses`, `Clash API responding`, `node delays`, `DNS lookup`
  (the section list and the probes' row labels overlap; the union is 16). K-6's "ten
  `DOCTOR_SECTIONS` labels" is a miscount of a nine-element tuple; nothing depends on it.
  The same argument also receives **rule-set filenames** (`bin/sc:2607`) — data passing through
  `t()`, rendering as itself in both languages, and correctly absent from `TRANSLATIONS`.

## §3 — C-8 / F-8: one membership test, stated once and applied once

F-8 is right that the design carries two tests. Neither alone reproduces the design's population:
the **form** test (a number substituted next to the noun it counts) admits
`at {at}: … matched {count} elements`, which K-9 excludes; the **reachability** test (some
reachable value contradicts the noun's number) excludes `larger than {n} bytes`, which I-5
admits. The test I applied, once, to every candidate:

> A phrase is a **count phrase** iff (a) a number is substituted immediately next to the noun it
> counts and that number is not the numerator of a fraction, and (b) some reachable value of that
> number contradicts the noun's grammatical number — where reachability is evaluated over the
> phrase's **family** (the phrases sharing one counted noun and one vocabulary), not per call
> site. A member whose form is already invariant is in the population and is left alone.

Clause (a) is FR-5's own definition plus Q-7's fraction ruling. Clause (b)'s family scope is
Q-6/R-40's ruling in operational form: "excluding a family because its wart is milder re-creates
the 'fixed for this one' defect". Under it, `larger than {n} bytes` is in — its `{n}` is only ever
`OVERRIDE_MAX_BYTES = 1048576` (`bin/sc:1269`, sole call site `:1549`), but its family, the
`bytes` vocabulary, is reachable at 1 (`{done} byte(s)` after a one-byte chunk;
`truncated: got {got} of {declared} byte(s)` at `{declared} == 1`; a readable empty rule-set file
gives a real `0`, per `ruleset_state`'s digest contract). `matched {count} elements` is out: it is
a family of one, and `bin/sc:1412-1413` raises it only when `len(hits) != 1`, so no reachable value
contradicts anything. Both answers now rest on the same sentence.

The population itself was derived mechanically, not by reading the design: every `TRANSLATIONS`
key matching `\{[a-zA-Z_]+\}\s+[A-Za-z]` (33 keys) was classified by that test. The result is the
table in `04_DEVELOPMENT.md`.

## §4 — C-6 / F-5 / CR-1: what round 1 got wrong, and the measurement that settles it

Round 1 answered F-5 with a **structural** claim: `cmd_config` reads the document with
`CFG_PATH.read_text()`, i.e. with the *locale's* codec, which is the same codec that gives stdout
its encoding, so a character that reached the write can always be encoded. The measurement backing
it was real but its environment was narrow — `PYTHONUTF8=0 LC_ALL=C PYTHONCOERCECLOCALE=0`, where
the read genuinely does fail first on both builds (`cand rc=1 bytes=0 · head rc=1 bytes=0`,
`cannot read …: 'ascii' codec can't decode byte 0xc3 …`), and the ASCII control is 163 bytes and
byte-identical between the builds. From two environments I generalised to "structural". That was
the error, and the reviewer is right.

**The identity has two preconditions, and I measured both rather than taking them on the
reviewer's word.**

**(a) `PYTHONIOENCODING` unset.** `Path.read_text()` with no `encoding=` calls
`locale.getpreferredencoding(False)`. `sys.stdout.encoding` does **not**: CPython resolves it from
`PYTHONIOENCODING` first and only then from the locale. Set `PYTHONIOENCODING=ascii` on this
UTF-8 host and the two diverge. Fixture: one `config.json` whose outbound `tag` carries U+00E9,
U+65E5 U+672C and the U+1F1EF U+1F1F5 flag pair — the emoji-flag case is not exotic, share-link
node tags routinely carry them and node tags reach `config.json`'s outbound tags.

```
$ env -u LC_ALL PYTHONIOENCODING=ascii  sc config > f
[proof] stdout=TextIOWrapper encoding=ascii errors=strict PYTHONIOENCODING='ascii' LANG='en_US.UTF-8'
cand  rc=0  bytes=269   stdout is pure ASCII
      json.loads: REJECTS — Invalid \escape: line 8 column 18 (char 101)
      \x forms: ['\xe9']   \u forms: ['日','本']   \U forms: ['\U0001f1ef','\U0001f1f5']
head  rc=1  bytes=0
      UnicodeEncodeError: 'ascii' codec can't encode character '\xe9' in position 101
```

So the reviewer's (a) is **CONFIRMED, not refuted**: the candidate exits **0** with a complete
document a parser rejects, exactly where HEAD aborted loudly. Of the three escape shapes only the
BMP one (`日`) is coincidentally valid JSON, and only because it always lands inside a string;
`\xe9` and `\U0001f1ef` are not JSON escapes at all.

**(b) the self-defeating premise.** The identity's other leg is `bin/sc:3113`'s bare
`read_text()` — T-23's locale-decode defect surviving in a third reader, which this document files
for repair. The reviewer argues that fixing it falsifies `README.md:297` under `LC_ALL=C` with no
env var set. That is a counterfactual, so I measured the counterfactual: same `LC_ALL=C
PYTHONUTF8=0 PYTHONCOERCECLOCALE=0` environment, no `PYTHONIOENCODING`, with `CFG_PATH.read_text()`
given the explicit UTF-8 decode T-23 gave `settings.json` / `nodes.json`.

```
cand + repair  rc=0  bytes=269  json.loads: REJECTS — Invalid \escape: line 8 column 18
head + repair  rc=1  bytes=0    UnicodeEncodeError: 'ascii' … '\xe9'
cand, today (locale read_text, no repair)  rc=1  bytes=0   — the round-1 result, reproduced
```

**CONFIRMED.** A future task doing an unambiguously good thing silently falsifies a published
sentence. Both preconditions therefore belong in the record, and door two — "record per sentence
why each stays true" — is no longer available, because the recorded reason is not true in general.

**What I changed, and what I did not.** Per the PM's binding scope ruling both sentences take
BC-8's narrowing, symmetrically: `README.md:297` and `README.zh-CN.md:297` now state the condition,
what happens instead of an abort, why the escape is not JSON, and the remedy. The
`README.zh-CN.md` frozen-set release is used for exactly one line; `README.zh-CN.md:94`'s `sc ls`
sample stays frozen and is byte-identical after this task (out-of-scope 5). I also narrowed the
same promise in its third home, `cmd_config`'s own docstring (`bin/sc:3102-3105`) — not a
published sentence, but the producer's contract sentence, and leaving a demonstrably false one in
the function whose defect CR-1 names would be the same class of finding as CR-2. **No behaviour
changed**: BC-8 already resolved the behaviour, and F-7 (`\xNN` at exit 0) is what BC-8 asks for.
The escape-vs-abort trade is not re-opened here.

## §5 — C-9 / V-14: what was pinned, and the one line declared variable

Declared **before** the run: the only line variable by construction on this fixture is
`sc doctor`'s DNS row, `{name} resolved in {ms} ms` (`bin/sc:2870-2872`), whose `{ms}` is measured
around one call. Everything else was pinned rather than tolerated:

| what could vary | how it was pinned |
|---|---|
| rule-set `_age_text` values | fixture `utime` at `now − 5000 s` → `1 hour(s) ago`, boundary at 7200 s; the two builds run seconds apart |
| egress body / egress error | `sc._egress_ip` stubbed to a constant (`203.0.113.7`) |
| Clash API port | `clash_api_port` in the fixture's own `settings.json` (C-4) |
| Clash `/configs`, `/proxies`, `/dns/query` | one in-process `http.server` responder, fixed bodies |
| `systemctl` / `ip` / `sing-box` output | `sc.subprocess` stub returning fixed bytes |
| config drift row | `sc reload` run first, so the record exists and reads `matches` |
| fixture path | one directory, wiped and rebuilt for each build |

In the event the DNS row read `0 ms` on both builds and did not appear in the diff at all.

Full V-14 diff, four commands (`reload`, `status`, `doctor`, `ls`), English, HEAD → candidate:
22 changed lines, all inside I-2…I-6 plus FR-6's reordering; `sc reload` byte-identical. The
`sc doctor` screen it was taken over is a complete 21-row healthy report (binary, version,
4/4 rule-sets + four rows, configuration, drift, check, AAAA, service, autostart, TUN + addresses,
Clash + responding + delays + DNS, egress, permissions + two quoted lines).

## §6 — Two behaviours a reviewer should know were measured, not assumed

**(a) `sys.stdout.errors` under the POSIX locale is `surrogateescape`, not `strict`.** The
insight index records stdout as strict; that is true under a UTF-8 locale. Under
`PYTHONUTF8=0 LC_ALL=C` CPython gives stdout `encoding=ascii errors=surrogateescape` (measured,
`[proof] stdout encoding=ascii errors=surrogateescape`). This matters twice. It does **not**
weaken AC-9/AC-10: `surrogateescape` re-encodes lone surrogates only, so a genuine `●` or `日`
still raises — HEAD aborts exactly as required. It **does** invalidate a fixture that transports
a non-ASCII tag through `os.environ` under that locale: the bytes decode to lone surrogates,
`json.dumps` writes them as `\udcXX` escapes, and HEAD then prints them back as their original
UTF-8 bytes and **passes**. My first AC-10 run did exactly that and looked like a pass on broken
code; the tag had to be transported as `\uXXXX` JSON escapes to be a real character. After that
fix HEAD aborts on the tag row and the candidate prints all three rows.

Consequence of the same fact for the product: `errors="backslashreplace"` replaces that
`surrogateescape` on the C locale, so any string carrying surrogate-escaped bytes now renders as
`\udcXX` rather than round-tripping to its original bytes — and the source is the whole OS byte
surface, not just `os.listdir`: `os.environ` and `sys.argv` decode the same way, which is why
`SB_RULES_BASE` / `--mirror` (`bin/sc:1129`) reaches stdout verbatim through `cmd_update_rules`'s
cause list (`:3346`, `:3360-3361` → `:3370`) and is a second site of the same class (CR-11). Survival
is unchanged or better in every case; byte-fidelity for undecodable-byte *data* is not. Filed as
an open issue rather than fixed, because every fix is machinery K-1 and rule 85 forbid.

**(b) The broken-pipe path.** `sc ls | head -2` on 4000 nodes: **both** builds raise
`BrokenPipeError` from the same `print()` at `cmd_ls` (HEAD's block buffer fills and flushes
mid-run too), same traceback, same exit. The candidate adds two stderr lines at finalisation —
`Exception ignored in: <_io.TextIOWrapper name='<stdout>' …> BrokenPipeError` — because two
wrappers now sit over one `BufferedWriter` and the second close attempt re-raises. `sc config`
is unaffected: its `except BrokenPipeError: os._exit(1)` (`bin/sc:3150-3159`) skips finalisation
entirely, and a 1 MB document through `| head -5` produced clean stderr and no message on either
build. At the sizes that fit in a pipe buffer (every realistic `sc ls`) neither build emits
anything.

**(c) The double-wrapper concern generally.** `sys.__stdout__` keeps the original wrapper alive,
so rebinding `sys.stdout` does not deallocate it and does not close the buffer. Directly
measured: a completed line plus a **partial** line with no `\n` written through the re-wrap are
both present in the captured file at exit, with empty stderr.

## §7 — BC-6 / K-3, measured on both builds

`sc ls >&-`: `sys.stdout is None`, `getattr(None, "buffer", None)` is `None`, the guard's false
arm is taken, nothing raises, exit 0 — identical on candidate and HEAD. (The first attempt
failed inside the *harness*, whose own diagnostic line read `sys.stdout.encoding` unguarded;
the harness was fixed, not the product.)
