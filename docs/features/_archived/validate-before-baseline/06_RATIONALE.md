# 06 — Rationale · T-30 `validate-before-baseline`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## 0. Triggers, and what I read

- **T6.1** did not fire: every AC's verification column is executable as written.
- **T6.2** fired once — I re-derived `04_DEVELOPMENT.md`'s `_plain` / `_write_private` span hashes
  and its `+21` classification, so I opened `04_RATIONALE.md`. It exists; §4 gave the one-root
  differential discipline and §5 gave the two fences. Both were load-bearing (§5 became DEF-5).
- **T6.3** fired once — CR-6 / CR-17's fence is not self-contained in `05_CODE_REVIEW.md`; it
  points at `04_RATIONALE.md:186-194`. I opened it, and then built the mutant it describes rather
  than accepting the sentence. `05_RATIONALE.md` was not needed.
- No upstream document was edited.

## 1. The fixtures — construction, so the rows are rebuildable

All under the session scratchpad root `t30qa/`; they are session-local by design (QA adds no
uncommitted files to the repo, and `02` declines the fifth arm that would make them committed).

| file | what it is |
|---|---|
| `qalib.py` | The loader + fixture + **22 named cases**. `load()` is `docs/dev-map.md:129-177`'s recipe: `assert os.geteuid() != 0`, an `os` shim whose `geteuid` returns 0, `sys.modules["os"]` restored in a `finally`, and the exec denial applied by **name over `dir(os)`** — every `exec*`/`spawn*`/`fork*`/`posix_spawn*` plus `system`, `popen`, `startfile`, i.e. capability not prefix. `fixture()` repoints all **nine** `Path` constants into the run root and then asserts that **every** `Path` attribute of the module resolves inside it, raising by name otherwise. `SYSTEMD = OPENRC = False`, `CLASH_PORT = 29090`, `SB_BIN` a repointable constant. `_init_files()` is never driven; `main()` is never called. |
| `run.py` | One (build, case) pair per **process**, at a **fixed** root path (`t30qa/R`), wiped between runs. One case per process is not optional here — `main()` re-wraps `sys.stdout/err` and a second call in one process raises `ValueError: I/O operation on closed file`; I avoid the class entirely by never calling `main()`, which also keeps `sc.LANG` the one that renders. |
| `matrix.py` | The CAND-vs-HEAD differential. HEAD is `git clone --no-hardlinks` of `fc634e3` — **never** a `git worktree` — and both builds run at the **same** fixture path, because `RULES_DIR` is emitted verbatim into `route.rule_set[].path` and two roots would diff the paths rather than the behaviour. |
| `sweep.py` | Runs all 9 cases on a build and diffs 14 observables per case against a shipped-build baseline. This is the instrument that produced DEF-3's "0 observable difference(s)". |
| `spans.py` | `ast`-located function spans + a whole-file line classifier (executable / comment / docstring / `TRANSLATIONS` data / blank). Spans come from `ast`, never from the cited line numbers, so a stale citation cannot make me agree by accident. |
| `mutate.py` | Builds 14 mutants of the **candidate** `bin/sc` into `t30qa/mutants/`, each `compile()`d. Two more (`mut-CR6-arm-inside-try`, `mut-widened-finally-typo`) are built by a line-level script. The working tree is never mutated. |
| `freeze.py` | AC-9 (`_doctor_config()` over three on-disk states) and AC-10 (`cmd_reload`, `cmd_add`, `cmd_update_rules` with `_fetch_to_temp` stubbed and a rejecting checker), each captured as `{how, value, stdout, stderr, restarts}`. |
| `conc.py` | BC-6: N=10 `generate_config()` **processes** against one `CFG_DIR`, with a checker that sleeps 0.35 s so the windows genuinely overlap. |
| `probes.py`, `fence.py`, `res8_cmd.py` | BC-1 / BC-4 exception paths; the CR-6 fence under a selectively-failing stderr; DEF-1 at the command level. |
| `arm4only.py` | A copy of the committed suite with arms 1-3's loop tuple emptied, so **arm 4 is observable in isolation**. Without this the rejected arm fails first on a HEAD clone and the function aborts, and "arm 4 passes on HEAD" cannot be read off the suite's output at all. |

Sentinels: `config.json` pre-seeded with `SENTINEL-QA-CONFIG\n` (19 bytes, sha `5738058a…`) and
`.config.sha256` with `SENTINEL-QA-DIGEST\n` — distinct from anything a run emits, so "left
unchanged" and "replaced" are two observations rather than one. The composed document for the
standard node store is **4625 bytes, sha256 `c976467141f3f0e12378d10e57fbcb564efd570d7d1ae0da78fc300dd4c9fdc2`** —
independently reproduced, and equal to the developer's C-5 figure.

Six of the traps in my brief were live in this work: the one-root rule (used), the worktree ban
(obeyed), the `main()`/`LANG` trap (avoided by construction), the one-case-per-process trap
(avoided), the exec-denial-by-name rule (implemented over `dir(os)`), and the stub-cannot-colour
rule (AC-11 uses the real binary, and I verified the raw pipe colours first).

## 2. RES-6 — what I measured versus what I carried

Stage 5 had no shell in either round. Everything below is my own execution on this host.

| claim | source | what I did | result |
|---|---|---|---|
| `verify_all` PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0 | 04 + PM | ran it 4× (1 tally + 3 stability) | **re-measured, agrees** |
| B.4 `18 defined, 18 run, 18 passed` | 04 | ran the suite 11× directly | **re-measured, agrees** |
| `_plain` byte-identical, `f04a53be6c5599c8` both sides | 04 C-7 | `ast`-located spans `2493:2535` / `2549:2591`, 43 lines both; hashed under six conventions | **reproduced exactly** — the convention is sha256 of the newline-joined span, first 16 hex |
| `_write_private` `c394797931d99deb` both sides | 04 C-7 | same, spans `488:538` / `491:541`, 51 lines both; plus body-AST equality | **reproduced exactly**, and `ast.dump` equality confirms it independently of whitespace |
| net **+21** executable lines, bound 25 | 04 C-8 / V-12 | my own classifier, run identically over both whole files | **reproduced exactly**: 2097 → 2118 = +21; `generate_config()` 61 → 82 = +21 |
| probe A / A′ / B / C all redden B.4 | 04 | rebuilt all four from the descriptions and ran them | **reproduced exactly**, with the same four exceptions |
| live-service witness `MainPID=2566751 NRestarts=0` | 04 | `systemctl show -p MainPID -p ActiveEnterTimestamp -p NRestarts` before and after | **re-measured, unchanged** |
| C-1's real-binary transcript (1.13.15 quotes the path, colours a pipe) | 04 §C-1 | re-ran the colouring half myself, and drove the whole AC-11 fixture against `/usr/local/bin/sing-box` | **re-measured, agrees** |
| `_doctor_run` body unchanged, docstring widened (I-15) | 05 | body-AST equality with the docstring excluded | **re-measured: `True`** |
| K-7 / K-8 (`Config check failed` gone; `capture_output=` at two sites) | 05 | grep on the final tree | **re-measured**: 0 occurrences; `[2271, 3536]` |
| C-5's 4625-byte / `c9764671…` document | 04 | composed it in my own fixture from my own node store | **reproduced exactly** |

Nothing material was carried. The one figure I did not re-derive is the developer's **physical
line total** (3808 vs my 3807) and their blank/docstring split — a trailing-newline convention
difference in a class NFR-3 does not bound; the executable figure, which is the bounded one,
agrees to the line.

## 3. Full runs behind the ≤5-line citations

### 3.1 The differential matrix (`matrix.py`), 9 cases × 2 builds

`**` marks a divergence. The full table is 220 lines of output; the shape of it is:

- **accepted**: 12/12 observables identical, including `cfg_after_sha256`, `cfg_mode 0o600`,
  `state_after`, `restarts 1`, and both listings unchanged. NFR-4 and AC-1 in one row.
- **rejected**: 7 divergences, all in CAND's favour — `cfg_after_is_sentinel CAND=True HEAD=False`,
  `cfg_after_len CAND=19 HEAD=4625`, `state_after CAND='SENTINEL-QA-DIGEST\n' HEAD='c9764671…'`,
  `cfg_after_parses CAND='NO: JSONDecodeError' HEAD=True`. HEAD's own message is
  `⚠️  Config check failed:` — the key I-13 replaces.
- **rejected-fresh**: HEAD's listing goes from `['rules','if_inet6','nodes.json','sbcheck']` to the
  same plus `.config.sha256` and `config.json`; CAND's is unchanged. That is BC-3, measured.
- **absent-bin / unexec-bin**: `returned CAND=True HEAD=None`; HEAD's `raised` is
  `FileNotFoundError: [Errno 2] …` and `OSError: [Errno 8] Exec format error: …` respectively.
  Both HEAD runs had **already written** `config.json` (sha `c9764671…`) and its record before
  raising — R-70 and R-73 in one observation.
- **undecodable**: `HEAD raised "UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in
  position 6: invalid start byte"`; CAND rendered `FATAL �� bad` and returned `False`.
- **empty-reject**: CAND `⚠️ …was left unchanged…:` then `the checker reported an error, no
  message (exit 1)`; HEAD `⚠️  Config check failed:` then nothing — BC-10's exact defect shape.
- **quote-candidate**: the real child echoes `argv[3]`; CAND's rendered line names
  `$R/config.json`, HEAD's names it too (HEAD hands the checker `config.json` itself).
- **uncreatable**: identical on both builds — `Could not write $R/no-such-directory/config.json:
  No such file or directory`, `False`, nothing created. The run-level outcome is **preserved**,
  not introduced, exactly as I-14's arm-4 docstring claims.

### 3.2 The real-binary rows (AC-11)

Raw control, to prove the colouring is not a fixture artifact:

```
$ /usr/local/bin/sing-box check -c csi/bad.json 2>&1 | cat -v
^[[31mFATAL^[[0m[0000] decode config at csi/bad.json: dns.servers: json: cannot unmarshal string into Go struct field RawDNSOptions.servers of type []option.DNSServerOptions
```

Candidate build, `SB_BIN=/usr/local/bin/sing-box`, override
`{"dns": {"servers": {"$append": ["not-an-object"]}}}`:

```
returned False · restarts 0 · cfg_after_is_sentinel True · listing unchanged True
⚠️  $R/config.json was left unchanged — `sing-box check` rejected the new configuration:
FATAL[0000] decode config at $R/config.json: dns.servers[4]: json: cannot unmarshal string into Go struct field RawDNSOptions.servers of type option._DNSServerOptions
ESC: False CR: False .check.: False
```

HEAD, same fixture:

```
returned False · cfg_after_sha256 '1980c524cc5d16935ca0d863766b402851546dc32905aa378ced145d86e0e63a'
state_after      '1980c524cc5d16935ca0d863766b402851546dc32905aa378ced145d86e0e63a\n'
⚠️  Config check failed:
'\x1b[31mFATAL\x1b[0m[0000] decode config at $R/config.json: dns.servers[4]: …'
```

So AC-11 establishes two things at once: the complete CSI pair is removed **whole** (the surviving
`[0000]` is logrus' elapsed-time field, not a control sequence), and HEAD both leaked raw ESC and
baselined the digest of a document `sing-box` had just refused. `real-accept` on the same binary
returns `True` with the 4625-byte document and `0600`, so the row is not satisfied by a build that
rejects everything.

### 3.3 The real-child witness (AC-7 / FR-1 / BC-2)

A checker that reports, from inside the check, what it was handed:

```
argv       ['check', '-c', '$R/config.json.check.9oamlsl7']
cand_mode  '0o600'   cand_is_link False   cand_links 1   cand_dir '$R'
cand_sha            'c976467141f3f0e12378d10e57fbcb564efd570d7d1ae0da78fc300dd4c9fdc2'
cfg_sha_at_verdict  '5738058a3121f9bf51192f64080b43c8543d89d431d6fb031d74603d10629166'
dir_listing_at_verdict ['.config.sha256','config.json','config.json.check.9oamlsl7','if_inet6','nodes.json','rules','sbwitness']
```

`cand_sha` is the sha256 of the document that is later installed, and `cfg_sha_at_verdict` is the
pre-run sentinel. FR-1's "the verdict is taken on exactly the bytes that would be installed" is
therefore a measurement here, not an inference from the source, and the mode is read by a **run**
at the one instant the candidate is complete — the clause AC-7 asks for. Identical on the
rejecting variant. NFR-1 was taken the same way, with a checker that appends one line per
invocation: `real sing-box check processes started: 1` on both the accepted and the rejected path,
argv `check -c $R/config.json.check.<6 chars>` each time.

### 3.4 The mutation sweep — 16 mutants through B.4

| mutant | what it does | B.4 |
|---|---|---|
| `mut-probeA-no-guard` | delete `if name is not None:` | **RED** `TypeError: unlink: path should be string, bytes or os.PathLike, not NoneType` |
| `mut-probeAp-no-sentinel` | …and delete the sentinel | **RED** `UnboundLocalError: cannot access local variable 'name'` |
| `mut-probeB-mkstemp-outside` | `mkstemp` back above the `try:` | **RED** `FileNotFoundError: [Errno 2] … config.json.check.9u2b2xny` |
| `mut-probeC-tmpdir` | `dir=None` (candidate into `TMPDIR`) | **RED** `got '/tmp', want '<CFG_DIR>'` |
| `mut-W1-rejects-everything` | `if True:` in place of `if code != 0:` | **RED** `accepted: generate_config()'s return: got False, want True` |
| `mut-W2-never-installs` | drop the install | **RED** `accepted: config.json still holds the pre-run bytes` |
| `mut-W3-candidate-wide` | `os.chmod(name, 0o644)` after the write | **RED** `the candidate's mode …: got 420, want 384` |
| `mut-W4-leak-on-reject` | skip the unlink on the rejected path only | **RED** `the entries under CFG_DIR: got [… 'config.json.check.ib6hr7vy' …]` |
| `mut-W5-record-on-reject` | `_record_generated()` before the rejected `return` | **RED** `config.json and the drift record after the run: got (b'SENTINEL-CONFIG\n', b'2ce84bfd…')` |
| `mut-W6-check-installed` | install first, then check `config.json` (HEAD's order, new keys) | **RED** `the checker was pointed at config.json itself` |
| `mut-widened-finally-typo` | `except (OSError, NameError)` + `os.unlink(nmae)` | **RED** `the entries under CFG_DIR: got [… 'config.json.check.7kaqll62' …]` |
| `mut-res8-silent` | outer handler returns `False` with no line | **GREEN 18/18** → DEF-1 |
| `mut-res9-other-doc` | install a different valid document | **GREEN 18/18** → DEF-2 |
| `mut-res9-os-replace` | install by `os.replace(name, CFG_PATH)` | **GREEN 18/18** → DEF-3 |
| `mut-res2-no-substitution` | drop `.replace(name, str(CFG_PATH))` | **GREEN 18/18** → DEF-4 |
| `mut-CR6-arm-inside-try` | rejection arm absorbed into the inner `try` | **GREEN 18/18** → DEF-5 |

**12 of 16 killed by the committed suite; 4 by my own fixtures; 1 (`mut-res9-os-replace`) by
neither.** The four QA-authored kill-only-by-fixture cases are DEF-1, DEF-2, DEF-4 and DEF-5.

`mut-widened-finally-typo` deserves a note: `04_RATIONALE.md` §5 predicts that a widened
`except (OSError, NameError)` would leave arm 4 green while leaking a `0600` file. Both halves are
right — arm 4 **in isolation** does pass it (`arm4only.py` → `PASS`) — but the suite as a whole
still reddens, on arms 1-3's `sorted(os.listdir(CFG_DIR))` clause. The design's fear is
over-defended, not under-defended. The sentinel's justification survives on the *loudness*
argument even so.

### 3.5 Arm 4 in isolation (the trick, performed)

Arms 1-3's loop tuple emptied on a copy of the suite; only arm 4 runs:

```
sc (shipped)                PASS      head-clone/bin/sc            PASS
mut-res8-silent             PASS      mut-widened-finally-typo     PASS
mut-probeA-no-guard         FAIL  TypeError: unlink: path should be string, …
mut-probeB-mkstemp-outside  FAIL  FileNotFoundError: [Errno 2] …
```

This is the only way to read the claim. It confirms all three facts arm 4's docstring states — it
passes on a HEAD clone by design, it reddens for both documented mutations — and it falsifies the
docstring's *scope* claim in exactly the way CR-12 says: it is green on a build that unwinds
silently.

### 3.6 DEF-5, at length, because it is new

`04_RATIONALE.md` §5 says the inner `else` protects against absorbing the rejection arm into the
inner `try:` body, and that the loss would be silent. I built that edit and measured it. With a
`sys.stderr` that refuses only the rejection sentence (`OSError(28)`, i.e. ENOSPC on the log
device — the realistic trigger):

```
shipped:  {"value": false, "config.json UNCHANGED (AC-2)": true,  "config.json len": 19,
           "drift record UNCHANGED": true,  told: "⚠️  Could not write …"}
mutant:   {"value": true,  "config.json UNCHANGED (AC-2)": false, "config.json len": 4625,
           "drift record UNCHANGED": false, told: "⚠️  …was installed without being checked…"}
```

So the mutant re-creates R-73 in full — a rejected document installed and baselined — while
telling the user the opposite, returning `True` so the caller **restarts the service**, and
keeping B.4 at 18/18. The fence is real, its failure is silent, and nothing in the repository
watches it: the sentence that explains it lives in a stage rationale that is archived at delivery,
and `bin/sc:2185-2189`'s comment explains the path substitution instead. That is precisely CR-17 /
RES-10, now with a measurement attached, and it raises the priority of moving one sentence to a
comment at `bin/sc:2183`.

### 3.7 DEF-3, and why the reviewer's implied remedy would not work

RES-9 asks for the two mutants to be measured, and CR-16 proposes byte-comparing the installed
bytes to the composed document. That closes DEF-2. It does **not** close DEF-3: `os.replace(name,
str(CFG_PATH))` installs the *same bytes*, at the *same mode*, having already been `fsync`ed by
`_write_private` when the candidate was written, and the `finally`'s unlink then fails ENOENT and
is swallowed — no leak. I looked for a behavioural difference across 13 cases (the 9-case sweep
plus symlinked target, `0666` target, `umask 000`, and the real binary) and found **zero**. K-2's
"no second temp-then-replace construction" is a *structural* invariant about which code owns the
write, and only a structural control can hold it. Reporting it as "add a byte-comparison arm"
would have been a false remedy, so I am reporting the measurement instead.

### 3.8 DEF-6

`probes.py checker-raises-valueerror` binds a `subprocess` stub whose `run()` raises `ValueError`.
The shipped build renders `⚠️  Could not write $R/config.json: synthetic: a decode-shaped failure`
and returns `False` with `config.json` intact and no leaked candidate; HEAD lets the same
`ValueError` escape uncaught **after** having installed the document (`cfg_len 4625`). I-9 excludes
only a checker `OSError` from the write-failure wording, so the mis-wording is faithful to the
design; the outcome is right and the path is unreachable with `bin/sc`'s fixed argv (a `ValueError`
from `subprocess` needs an embedded NUL in argv, and every element is a constant or an `mkstemp`
name). NIT, filed for T-32, no rollback.

### 3.9 The freezes

AC-9: `_doctor_config()` over `{no config}`, `{config + matching record}`, `{config + stale
record}` — the two builds' captured `{how, value, stdout, stderr}` JSON is **byte-identical**.
AC-10: `cmd_reload` → `SystemExit 'Reload failed'`, stdout empty, restarts 0, identical on both;
`cmd_add` → stdout `Added: n2 (⚠️ config check failed — see \`sc log\`)`, exit 0, restarts 0,
identical; `cmd_update_rules` with four stubbed fetches, a pre-existing `config.json` and rule-sets
gaining usability → `SystemExit 1`, stdout **byte-identical** to HEAD, restarts 0, and exactly one
run-level outcome line (`Rule-sets updated: … — the sing-box service was not touched`). The only
differences are the reworded stderr and — the fix — CAND leaving `config.json` and `.config.sha256`
at their sentinels where HEAD replaces both.

## 4. Scope discipline

R-81, R-100, R-99's second site and R-86/R-89/R-90/R-92 were not touched and not tested against.
DEF-3's structural control and DEF-7's ratchet both belong to `verify_all` / the suite's owner, and
I did not edit `verify_all` or lower any floor; both are filed as rows. `04_DEVELOPMENT.md`'s open
issue 4 (FR-5 uncontrolled) is DEF-4 with a measurement attached rather than a restatement.

## 5. Schema-gap row

`.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule` carries no numbered rows, so no row
can be named for two units this stage produced that the QA schema declares no shape for: **the
fixture construction table** (§1) and **the RES-6 measured-versus-carried ledger** (§2). Under that
rule's precedence clause both are carried here, in the rationale, and the contract portion cites
them. No section was invented and no third document opened. The one artifact I wrote outside the
two stage documents is the append to `.harness/operator-obligations.md` (id **6**), which my own
contract names as the destination for a standing operator obligation.
