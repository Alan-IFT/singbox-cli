# T-29 · state-file-contract-completion — Development Rationale

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## Mutation transcript (V-13, plus two the design names elsewhere)

Every mutant is a scratch **copy** of `bin/sc` under the session scratchpad, driven through the
suite's own `--source`; the working tree was never mutated. Command per row:
`python3 .harness/scripts/check-sc-contracts.py --source <copy>`.

| mutant | mutation | result |
|---|---|---|
| `mut_a_substitute` | `raw = CFG_PATH.read_text(encoding="latin-1")` at `cmd_config()`'s read (V-13(a), C-9) | **kills I-5** — `FAIL every_file_read_and_write_names_utf8 AssertionError: 1 site(s) leaving a codec to the process locale: line 3130: read_text(): no literal encoding="utf-8"`; `17 defined, 17 run, 16 passed`, exit 1 |
| `mut_a_delete` | the `encoding=` argument **deleted** at the same site — C-9's named false-kill shape | **also kills I-5**, and legitimately: I-5 is a source scan, so a deletion is visible to it where it is invisible to the behavioural assertion the insight was measured on. Reported as a fact; the substitution stays the mutation of record |
| `mut_b` | I-2's `load_settings()` statement deleted from `generate_config()` (V-13(b)) | **kills I-6** — `FAIL unusable_settings_refuses_regeneration FileNotFoundError: … /no-sing-box`; the refusal is gone, so the run composes, writes and reaches `sing-box check`, where the fixture's non-existent `SB_BIN` stub raises first. `17 run, 16 passed`, exit 1 |
| `mut_c` | the cause clause replaced by a bare `e.strerror` in `save_settings()` (V-13(c)) | **kills I-7** — `FAIL settings_write_failure_is_a_sentence AssertionError: a value UTF-8 cannot encode: AttributeError left save_settings(): 'UnicodeEncodeError' object has no attribute 'strerror'`, i.e. exactly the handler-raises-inside-itself failure Q-6 predicted |
| `mut_e` | the whole `try` removed from `save_settings()` (I-7's second stated kill) | **kills I-7** — `AssertionError: a parent directory that does not exist: FileNotFoundError left save_settings()` |
| `mut_d` | E-10's arm collapsed to one undifferentiated `except OverrideError:` (AC-19's control) | **kills nothing**: `17 defined, 17 run, 17 passed`, exit 0. No committed assertion covers E-10; AC-19 / V-19 at stage 6 is its only control. Carried into `04_DEVELOPMENT.md` `## Open issues for review` |

## FR-5 probe — why E-7 and E-8 had to land together

Migration step 2's hazard is that E-7 alone converts the opportunistic persist's swallowed `OSError`
into a fatal `SystemExit`. Measured on a fixture whose `settings.json` is usable, records no
`clash_api_port` and is mode `0444`, with `_free_port` stubbed so the probe opens no socket
(loader: the committed suite's `load()` + `fixture()`, i.e. the mandated recipe plus the exec-denial
shim; `main()` and `_init_files()` never driven):

```
candidate                    -> 29099                        stderr='' bytes-unchanged=True
mutant: except OSError kept  -> SystemExit: Could not write …/settings.json: Permission denied
```

So FR-5's silent continue survives the renderer, and the build the design warned about fails exactly
as predicted — which is also V-8's stated control (HEAD passes that row, so HEAD is not the control).

## Locale probe — the two reads this task repairs

Run in a child process under `env -i LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0`, with the
environment asserted **before** anything else was credited (K-9 / NFR-6):

```
environment: stdout=ascii preferred=ANSI_X3.4-1968
--- candidate
    sc config      exit=0  stdout=416 bytes  masked=True  escaped-tag=True
    doctor AAAA    (2, 'IPv6 (AAAA)', 'AAAA queries are answered empty (setting: auto …); config.json
                    does not carry this decision as the first dns.rules entry …')
--- HEAD-equivalent reads (no encoding= at the doctor and cmd_config reads)
    sc config      exit="cannot read …/config.json: 'ascii' codec can't decode byte 0xe8 in position
                    175: ordinal not in range(128)"  stdout=0 bytes
    doctor AAAA    (1, 'IPv6 (AAAA)', "cannot read …/config.json: 'ascii' codec can't decode byte 0xe8 …")
```

`cmd_config()` was called directly (never `main()`); stdout was captured through an
`io.TextIOWrapper` carrying `main()`'s own configuration — the stream's own encoding,
`errors="backslashreplace"`, `newline="\n"`, line-buffered — because `main()`'s re-wrap is what keeps
an unencodable character from ending the run and a bare `io.StringIO` capture would certify nothing.
The candidate's masked document reached stdout with the credential as `******` and the CJK tag as a
backslash escape (the probe asserted the six ASCII characters `\u8282` are present in the captured stdout),
and the run exited 0.
The candidate's AAAA row is class `2` here only because the probe's synthetic `config.json` does not
carry `_aaaa_rule()` at index 0; the load-bearing half is that it states a verdict about the document
instead of reporting that the file cannot be read.

This is the mechanism half of AC-9 / AC-10. The command-level rows, with `main()` driven end to end,
remain stage 6's.

## Why the first run of that probe certified nothing

The probe's first version wrote its fixture with `json.dumps(DOC).encode("utf-8")` and reported
candidate and control **identical** — both read the document, both printed the same row. The cause is
`json.dumps`'s `ensure_ascii=True` default: the bytes on disk were pure ASCII, so no decode could
fail and the criterion passed on broken and fixed code alike. With `ensure_ascii=False` the control
fails on the first CJK byte. This is the same vacuous-pass class the insight index already records for
tags transported through `os.environ`, reached through a different door — the fixture's own writer —
and it is what `04_DEVELOPMENT.md` surfaces as this task's insight, because stage 6 will write exactly
this fixture.

## Scan bound — why `Path.open` is inside the population and `subprocess.run(text=True)` is not

I-5 classifies a call by callee name and, for the open family, by a **literal** `mode` argument whose
index differs per callee (`Path.open(mode)` first; the builtin `open(file, mode)` and
`os.fdopen(fd, mode)` second) — hence the small table rather than a name test. The shipped file scans
as **8 text sites** (`os.fdopen` at `:521`, `save_settings`'s `write_text`, and the six E-1…E-6 sites)
and **5 binary sites** admitted by a literal `b` (`:938`, `:1202`, `:1549`, `:1972`, `:2649`); both
counts are asserted non-zero, which is what stops the scan passing by matching nothing. A mode that is
not a literal fails rather than passes, so a future text-mode `Path.open` is a violation of the rule
rather than a hole in it. `subprocess.run(..., text=True)` decodes a pipe, not a file, and stays
outside the bound by K-6 (RES-1 carries it).

`_literal_str()` uses `ast.literal_eval` rather than `ast.Str` / `ast.Constant`: `ast.Str` is
deprecated and merely *reading* the attribute emits a `DeprecationWarning` into B.4's output on 3.12,
while `ast.Constant` alone would silently match nothing on the project's stated 3.6/3.7 floor — and
"matches nothing" is the failure mode the two non-zero counts exist to catch.

## E-18's measurement — the three-spelling table the paragraphs were written from

Transcript, run once per case (a `bin/sc` fixture cannot call `main()` twice in one process), the
probe under the session scratchpad and never in the working tree. The shell does the redirect, so
`sys.stdout` is a real file whose `.encoding` is the locale codec — an `io.StringIO` stands in for
nothing here, because the whole subject is `main()`'s re-wrap of `sys.stdout.buffer`:

```
env -i PATH=/usr/bin:/bin LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0 HOME=$HOME \
    python3 probe_e18.py <case> out/<case>.json > out/<case>.json

env: sys.stdout.encoding='ascii'  locale.getpreferredencoding(False)='ANSI_X3.4-1968'
     PYTHONUTF8='0' LC_ALL='C' flags.utf8_mode=0

bmp-cjk  fixture: tag='\u9999\u6e2f-01'  on-disk non-ASCII bytes present=True
         run: exit=0   saved: bytes=267  pure ASCII=True
         json.loads(saved) valid=True   (tag read back as '\u9999\u6e2f-01')
         escaped tag line: "tag": "\u9999\u6e2f-01",
         masked uuid present=True  raw credential absent=True
latin1   fixture: tag='caf\xe9-02'  on-disk non-ASCII bytes present=True
         run: exit=0   saved: bytes=262  pure ASCII=True
         json.loads(saved) valid=False  (JSONDecodeError: Invalid \escape: line 8 column 18)
         escaped tag line: "tag": "caf\xe9-02",
astral   fixture: tag='\U0001f680-03'  on-disk non-ASCII bytes present=True
         run: exit=0   saved: bytes=265  pure ASCII=True
         json.loads(saved) valid=False  (JSONDecodeError: Invalid \escape: line 8 column 15)
         escaped tag line: "tag": "\U0001f680-03",
```

The saved files were read whole, not sampled: each is the complete masked document (`log`, both
outbounds, closing brace), with `uuid` at `"******"` and the fixture credential absent — which is
what makes clause (a)'s "the whole masked document reaches stdout" a measurement rather than an
inference from the exit status.

The spelling boundary in clause (b) is a separate measurement in the same environment, because
"Latin-1 range / elsewhere in the BMP / above the BMP" is a claim about the **codec**, not about
these three tags:

```
U+007F ->              len=1     U+0100  -> \u0100   len=6
U+0080 -> \x80         len=4     U+9999  -> \u9999   len=6
U+00E9 -> \xe9         len=4     U+FFFF  -> \uffff   len=6
U+00FF -> \xff         len=4     U+10000 -> \U00010000  len=10
                                 U+1F680 -> \U0001f680  len=10
```

## Why the first run of that probe certified nothing either

The first version passed each tag to the probe as an **`argv` argument**. Under `LC_ALL=C` the
interpreter decodes `argv` with `surrogateescape`, so what arrived was lone surrogates, and the run
died in the fixture's own writer before `sc` was ever called:

```
UnicodeEncodeError: 'utf-8' codec can't encode characters in position 98-103: surrogates not allowed
```

This is the `os.environ` tag-transport trap (insight, 2026-08-15) reached through `argv`, and it is
the same door as this task's own `ensure_ascii` insight: the fixture's **input path**, not the code
under test. It fails loudly here rather than passing vacuously only because the tag had to survive a
`.encode("utf-8")` on the way to disk; a probe that merely printed it would have reported a
plausible-looking escape that measured the transport. The fix is the one the earlier insight already
names — build the tag from source escapes in the probe itself, and assert no code point is a
surrogate before using it.

## What was deliberately *not* changed with E-18

`cmd_config()`'s docstring (`bin/sc:3119-3122`) makes the same two-spelling enumeration. It states no
falsehood — `\xNN` and `\UNNNNNNNN` genuinely are not JSON escapes, and it draws no conclusion about
the saved file — so nothing false ships; but its closing "Both READMEs state the same condition" is
now an understatement. Editing it would move `git diff --numstat bin/sc` off `24 9`, which is the
round's binding bound and the ledger's own "E-18 adds no product code line". It is recorded as an
open issue instead, for T-32's sweep.

`README*.md:124` / `:152` (CR-2's "every command except `sc doctor`") was not read, re-worded or
reflowed: different paragraph, inside the frozen set, travelling as RES-3.
