# 02 — Solution Design · T-23 `state-file-io-contract`

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

## Architecture summary

1. `bin/sc` gains **one reader** in `# State files` — `_read_state(path, default, member)` — which is
   the shipped file's only statement of how a state document is decoded, parsed and shape-checked;
   `load_settings()` and `load_nodes()` become one-line adapters over it and the inline read in
   `_load_lang()` disappears. Its *unusable* answer is the file's existing `OverrideError` envelope
   with `.path` set to the document that failed, so `main()`'s single `Cannot use {path}: {problem}`
   arm renders FR-6's and FR-8's sentence at **17 unguarded call sites with zero edits to them**.
2. The judgment "an unusable `settings.json` means an **empty settings document**" gets one home,
   `_settings_or_empty(warn=False)`; the four accessors' documented defaults (`en`, `None`, `auto`,
   `block`) then fall out of `{}` instead of being repeated in four `except` arms, and FR-5's single
   warning line needs no once-per-run flag because `main()` already calls `_load_lang()` exactly once
   per run, before `LANG` is assigned — which is also what makes that line English (BC-12).
3. Nothing else moves: `_write_private()`'s descriptor dance, `settings.json`'s mode and non-atomic
   write, the drift digest over file bytes, `_load_override()` and its sentences, the `config.json`
   readers (`cmd_config`, `_doctor_ipv6`), `CONFIG_BASE`, `_merge`, every existing translation entry,
   `install.sh` and both READMEs. The three writers gain an explicit UTF-8 encoding argument and the
   two write-failure renderers gain one widened catch each.

**Line budget actually spent (NFR-1):** **+70 / −43 in `bin/sc`, of which 46 added lines are code.**
Per-edit counts are in the `## Change ledger`; the +6 over NFR-1's 40-code-line figure and the −13
over its −30 figure are justified in `02_RATIONALE.md` §"Budget excess". Rule 70 declares no
`## Stage-doc boundary rule` in this project (Q-13, twelfth confirmation), so this schema is applied
as written and `## Byte-form specification` is absent by construction, not by omission.

## Change ledger

Total over every touched file. Each row is an edit id stage 5 reviews against; `+n/−n` are code lines
unless marked `doc`. FR/BC coverage per row here; the full requirement→edit matrix is
`02_RATIONALE.md` §"Requirement coverage".

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| E-1 | `/home/alan/Programs/singbox-cli/bin/sc` | edit | **New** `_unusable(path, problem)` in `# State files`, above `load_nodes` (`:543`): builds an `OverrideError` carrying the problem clause **and** the path whose document failed. FR-1. `+4 / +2 doc`. | single-dev |
| E-2 | same | edit | **New** `_read_state(path, default=None, member=None)` immediately below E-1 — THE reader (I-1). FR-1, FR-2, FR-3; BC-2, BC-3, BC-6, BC-8. `+16 / +7 doc`. | single-dev |
| E-3 | same | edit | `load_nodes()` `:543-544`: body becomes one `_read_state(NODES_PATH, member="nodes")` call. No `default` — an absent node store is a failure (FR-8, BC-5). `+1 / −1`. | single-dev |
| E-4 | same | edit | `load_settings()` `:555-556`: body becomes one `_read_state(SETTINGS_PATH, default={})` call. FR-1, BC-1. `+1 / −1`. | single-dev |
| E-5 | same | edit | **New** `_settings_or_empty(warn=False)` directly below `load_settings()` — THE degrade, and the only site that writes FR-5's warning line (I-5). FR-4, FR-5; BC-1, BC-12. `+8 / +4 doc`. | single-dev |
| E-6 | same | edit | `_load_lang()` `:388-392`: the inline `json.loads(SETTINGS_PATH.read_text())` and its three-name guard tuple are deleted; the body becomes one `_settings_or_empty(warn=True).get("lang", "en")`. FR-1, FR-4, FR-5, BC-12. `+1 / −4 / +3 doc`. | single-dev |
| E-7 | same | edit | `_saved_clash_port()` `:415-419`: the four-line try/except and its tuple are deleted; the port is read from `_settings_or_empty()`. FR-4, BC-3. `+1 / −5`. | single-dev |
| E-8 | same | edit | `_resolve_clash_port()` `:438-441`: guard tuple → `except OverrideError`, and its body becomes **return the probed port without writing** (K-6). FR-7, BC-15. `+2 / −2 / +1 doc`. | single-dev |
| E-9 | same | edit | `_ipv6_setting()` `:1571-1574`: try/except deleted, `settings = _settings_or_empty()`. Docstring's "degrades silently" clause corrected to name the language reader as the warning's home. FR-4, BC-3. `+1 / −4 / +1 doc / −2 doc`. | single-dev |
| E-10 | same | edit | `_telemetry_setting()` `:1790-1793`: same as E-9. Its docstring's **"THE SILENCE HAS TWO HOLES"** paragraph (`:1768-1778`) becomes false and is deleted, replaced by two lines stating the closed contract. FR-4, BC-3. `+1 / −4 / +2 doc / −11 doc`. | single-dev |
| E-11 | same | edit | `_write_private()` `:509`: `os.fdopen(fd, "w")` gains `encoding="utf-8"` and **nothing else** (K-4). One docstring line records that the encoding is now explicit. FR-10; BC-10, BC-11; NFR-5. `+1 / −1 / +1 doc`. | single-dev |
| E-12 | same | edit | `save_nodes()` `:550-552`: `except OSError` → `except (OSError, ValueError)`, and the cause clause `e.strerror or str(e)` → `getattr(e, "strerror", None) or str(e)` (K-5). FR-11, BC-10, Q-9. `+2 / −2 / +1 doc`. | single-dev |
| E-13 | same | edit | `save_settings()` `:559-560`: `json.dumps(d, indent=2)` gains `ensure_ascii=False` and `write_text` gains `encoding="utf-8"`. Mode and mechanism unchanged (Q-10). FR-10. `+2 / −1`. | single-dev |
| E-14 | same | edit | `_init_files()` `:538-540`: the direct `SETTINGS_PATH.write_text(...)` seed is replaced by a `save_settings({...})` call with the identical dict, plus a two-line comment mirroring the nodes seed's. FR-12. `+1 / −2 / +2 doc`. | single-dev |
| E-15 | same | edit | `generate_config()` `:2080-2082`: same catch widening and cause clause as E-12. FR-11, BC-10. `+2 / −2`. | single-dev |
| E-16 | same | edit | `sc doctor`'s node-delay probe `:2766`: `except (OSError, ValueError, TypeError, KeyError)` → `except (OverrideError, TypeError, KeyError)` — the reader's outcome plus the per-element residual BC-9 leaves. The row's text at `:2769-2770` is unchanged. FR-9, BC-9. `+1 / −1`. | single-dev |
| E-17 | same | edit | `TRANSLATIONS` beside `:351`: **one** new key, `the "{member}" member must be a JSON array`, with its zh entry (I-9). FR-3, AC-17. `+1`. | single-dev |
| E-18 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | edit | One Chinese bullet under `## [Unreleased]` stating the read contract, the UTF-8 write and the single `settings.json` writer. Bound by K-15: it may not claim non-ASCII tags print. Outside NFR-1's `bin/sc` budget, inside NFR-3. | single-dev |
| E-19 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | `# State files` cell amended, and one `## Reusable utilities` row for `_read_state` / `_settings_or_empty`. Stage-4 duty; a navigation ledger, no product bytes. | single-dev |
| E-20 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | One glossary term, **state document**, as drafted in `01_RATIONALE.md` §"Findings to re-home" item 3, appended to `## Language`. This design introduces the term as a binding category (I-1's subject), so the glossary records it; no product bytes. | single-dev |
| E-21 | `/home/alan/Programs/singbox-cli/docs/features/state-file-io-contract/04_DEVELOPMENT.md` | new | The Developer's own stage document (canonical pipeline filename). | single-dev |
| E-22 | *(schema gap)* | — | No committed test artifact is in this ledger: NFR-3 forbids a new file and T-28 owns the suite, so the fixtures of `## Verification plan` live in the stage documents and are never committed under the worktree. Recorded here because no other section of this schema can hold it. | single-dev |

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | new module-level function, `bin/sc` `# State files`, above `load_nodes` | `_read_state(path, default=None, member=None) -> dict` | THE reader of a state document, and the only one. Answers exactly one of three outcomes: **usable** — the parsed document, always a `dict`, and when `member` is given, one whose `member` value is a `list`; **absent** — the caller's `default` object, returned only for `FileNotFoundError` and only when the caller supplied one; **unusable** — raises `OverrideError` (never returns) carrying a one-clause already-translated problem and `.path` set to `path`. Four causes, in this order: any other `OSError` → `cannot be read ({err})` from `e.strerror or str(e)`; bytes that are not UTF-8 → `not valid UTF-8 text`; text that is not JSON → `not valid JSON ({err})`; a non-object top level → `the top level must be a JSON object`; a `member` that is absent or not an array → I-9's clause. Decodes with an **explicit** `"utf-8"` from `path.read_bytes()`, never `read_text()`, so the answer does not depend on the process locale. Prints nothing, exits nothing, writes nothing, repairs nothing (FR-1). Makes **no** other structural claim: a `nodes` element that is not an object is not its business (BC-9). No size cap (Q-11), no `S_ISREG` test, no whitespace-as-absent rule — those are `_load_override()`'s policies for the *user's* document and are deliberately not copied (K-9). |
| I-2 | new module-level function, immediately above I-1 | `_unusable(path, problem) -> OverrideError` | The only construction of an `OverrideError` outside the override pipeline, and the one place a state document's identity is attached to its failure. Returns the exception, so callers `raise _unusable(...)`; it never raises by itself. It exists as a named factory rather than five inline two-line blocks because it is **the single line T-24 must edit** if it renames or re-parents the class. |
| I-3 | `load_settings()` (existing name, new body) | `load_settings() -> dict` | The **strict** settings reader: the document, `{}` when the file does not exist, `OverrideError(path=SETTINGS_PATH)` when it exists and cannot be used. Every read-modify-write caller keeps calling exactly this (`sc lang`, `sc mode`, `sc ipv6 <v>`, `sc telemetry <v>`, `sc default-tun`, `sc on`, `sc off`, `sc update-interval` ×2, and `_resolve_clash_port`'s persist step), and each therefore aborts through I-8 before its `save_settings()` (FR-6, AC-6). Absent and empty are one state by construction, which is exactly BC-1's behaviour. |
| I-4 | `load_nodes()` (existing name, new body) | `load_nodes() -> dict` | The node store: a `dict` whose `"nodes"` value **is a list**, or `OverrideError(path=NODES_PATH)` — for an absent file too, whose clause is the OS's own `cannot be read (No such file or directory)`. Every caller may index `["nodes"]` without a guard; `.get("active")` is unconstrained. Seven unguarded call sites (`generate_config`, `_resolve_node`, `cmd_ls`, `cmd_now`, `cmd_use`, `cmd_add`, `cmd_status`) inherit FR-8's abort with no edit of their own. |
| I-5 | new module-level function, below `load_settings()` | `_settings_or_empty(warn=False) -> dict` | THE degrade, and the only place in the file that decides an unusable `settings.json` means an **empty settings document**. Never raises, never exits, writes no file. `warn=True` additionally writes **one** stderr line, `"⚠️  " + _plain(t("Cannot use {path}: {problem}", path=SETTINGS_PATH, problem=str(e)))`, and is passed by exactly one caller (I-6). Not for a read-modify-write: it cannot distinguish absent from unusable, and persisting its `{}` would be R-27's clobber (K-8). |
| I-6 | `_load_lang()` (existing name, new body) | `_load_lang() -> str` | The language, and THE once-per-run announcement that `settings.json` could not be used. `main()` calls it exactly once, in both arms (`:3657`, `:3660`), before every command and **before `LANG` is assigned** — so FR-5's "exactly one line however many readers consulted it" is a property of the call structure rather than of a flag, and BC-12's English rendering is structural rather than remembered. Returns `settings.get("lang", "en")`; value validation stays out of scope (BC-4). |
| I-7 | `_saved_clash_port()`, `_ipv6_setting()`, `_telemetry_setting()` (bodies only) | each reads `_settings_or_empty()` and keeps its existing key logic | Their four documented defaults are now consequences of one empty document: `{}.get("clash_api_port")` → `None`, `"ipv6" not in {}` → `auto`, `"telemetry" not in {}` → `block`, `{}.get("lang", "en")` → `en`. Because the reader guarantees a `dict`, `"ipv6" not in settings` is a membership test on a mapping and can never again answer from a JSON **string**'s substrings (BC-3). Neither their unrecognised-value stderr notices (BC-4) nor any other behaviour changes. |
| I-8 | `main()`'s existing `except OverrideError` arm (`:3675-3690`) — **no code change** | `sys.exit(_plain(t("Cannot use {path}: {problem}", path=e.path or CFG_PATH, problem=str(e)).replace("\n", " ")))` | Now the single rendering site for a document that cannot be used, whichever document it is: `e.path` is `OVERRIDE_PATH` from the override sites, `NODES_PATH` / `SETTINGS_PATH` from I-2, `None` → `CFG_PATH` for a fault in an overlay `sc` authored. Exit status 1, sentence on stderr, no state document written in that run. This arm must keep honouring `e.path` and must not be narrowed (K-9, and the residual to T-24). |
| I-9 | `TRANSLATIONS`, beside `the top level must be a JSON object` (`:351`) | key `the "{member}" member must be a JSON array` → zh `"{member}" 成员必须是 JSON 数组` | The one new user-facing key. Needed because no existing clause states the violation FR-3 names for `nodes.json`, and reusing `the top level must be a JSON object` would be **false** for a `{}` document, which is BC-6's fourth class. Same placeholder set in both languages; the literal contains no `失败` (AC-17); it renders only inside I-8's envelope. |
| I-10 | `sc doctor`'s node-delay row (`_doctor_clash()`, guard line only) | `except (OverrideError, TypeError, KeyError) as e:` → existing `cannot read {path}: {e}` UNKNOWN row | The third and last place that decides what a broken state document means. `OverrideError` replaces the now-impossible `OSError` / `ValueError`; `TypeError` / `KeyError` stay because `set(node["tag"] for node in nodes)` still meets BC-9's per-element residual. Doctor prints its whole table and exits on its own scale on every state-document cause (FR-9). |
| I-11 | on-disk byte form of every document `sc` authors | `_write_private(path, text)` with `encoding="utf-8"`; `save_settings` via `write_text(..., encoding="utf-8")` with `ensure_ascii=False` | `config.json`, `nodes.json`, the drift record and `settings.json` are written as UTF-8 regardless of the process locale, with non-ASCII characters literal (FR-10, Q-7). `_write_private` stays the only writer of `config.json` and the drift record (NFR-5), `save_nodes` the only writer of `nodes.json`, `save_settings` — after E-14 — the only writer of `settings.json` (FR-12). `_config_digest()` keeps hashing the file's **bytes** through `CFG_PATH.open("rb")` (NFR-6, AC-16). |

## Constraints

**K-1** — The implementer must decode inside `_read_state` as `path.read_bytes().decode("utf-8")` and
must not use `Path.read_text()` anywhere in the read path; `read_text()` decodes with the process
locale, which is the defect (R-62, insight index 2026-08-14).

**K-2** — The implementer must place the `UnicodeDecodeError` `except` arm **before** the `ValueError`
arm, because `UnicodeDecodeError` is a subclass of `ValueError` and the reverse order would report
"not valid JSON" for a document that is not text (FR-2, AC-1).

**K-3** — The implementer must attach `.path` to every `OverrideError` the state reader raises, through
`_unusable()` and through no other construction; an exception leaving the reader with the class default
`None` renders against `CFG_PATH` and names the wrong file (FR-6, FR-8, I-8).

**K-4** — The implementer must add `encoding="utf-8"` to `_write_private()`'s `os.fdopen` call and
change nothing else in that function: `mkstemp(dir=path.parent)` → `os.fchmod(fd, CRED_MODE)` on the
still-empty descriptor → write/flush/fsync → `os.replace`, in that order, with the `finally` cleanup
intact (T-13, NFR-5, AC-15, BC-11).

**K-5** — The implementer must fill every widened write-failure cause clause with
`getattr(e, "strerror", None) or str(e)`; `e.strerror` raises `AttributeError` **inside the error
handler** for a `UnicodeEncodeError`, which is the exact failure FR-11 and Q-9 exist to prevent.

**K-6** — The implementer must make `_resolve_clash_port()` return the freshly probed port **without
calling `save_settings()`** when `load_settings()` raises, and must not substitute `{}` for the
document; replacing an unreadable `settings.json` with a single-key document is R-27 (FR-7, AC-7).

**K-7** — The implementer must leave `_load_lang()` as the only caller passing `warn=True`, and must
not move, duplicate or conditionalise `main()`'s two `LANG = _load_lang()` calls; FR-5's once-ness and
BC-12's English rendering are both properties of that call site.

**K-8** — The implementer must not route any read-modify-write of `settings.json` through
`_settings_or_empty()`; the nine persisting call sites keep calling `load_settings()` so that they
abort through I-8 (FR-6) instead of writing `{}` over a document the user can still repair.

**K-9** — The implementer must not change `_load_override()`, `OverrideError`'s definition, `main()`'s
rendering arm, or any existing translation entry: T-24 owns the override error model, and this design
reuses its envelope precisely so that it needs no second one (out-of-scope item 1).

**K-10** — The implementer must not give the `config.json` readers — `cmd_config()` (`:3040`) and
`_doctor_ipv6()` (`:2634`) — a UTF-8 decode or a route through `_read_state`; each already answers with
one sentence and a non-zero exit, and decoding would convert that into a `UnicodeEncodeError` traceback
on strictly-encoded stdout (Q-6, BC-14).

**K-11** — The implementer must add exactly one translation key, I-9's, with a Chinese entry carrying
the same placeholder set and containing no `失败`, and must add no other user-facing string in either
language (NFR-2, AC-17).

**K-12** — The implementer must not add a guard, a `try`, or an `isinstance` test at any of the 17
currently unguarded call sites of `load_settings()` / `load_nodes()`; the whole design is that they
inherit the contract (AC-18).

**K-13** — Any fixture must load `bin/sc` through the `dev-map.md` neutralisation recipe, repoint all
eight path constants into a `mkdtemp()` root and assert each resolves there, set
`SYSTEMD = OPENRC = False`, and **replace `sc._init_files` with a no-op before driving `main()`** —
that function hard-codes `/var/lib/sing-box` and is not repointable (NFR-7). No agent may run the
installed `/usr/local/bin/sc`, touch the live service, or write `/etc/sing-box` or `/var/lib/sing-box`.

**K-14** — Any Chinese-language assertion must run on a fixture whose `settings.json` is **usable** and
sets `lang: zh`; on an unusable one `_load_lang()` returns `en` and a Chinese assertion passes
vacuously (NFR-9, BC-12).

**K-15** — The `CHANGELOG.md` bullet must not state or imply that a non-ASCII node tag can be printed
under a non-UTF-8 locale; this row makes the tag survive on **disk** only (BC-14, T-25).

**K-16** — No fixture, document or stage report may contain a real credential; `verify_all` A.1 stays
PASS with this task's documents in place (NFR-8).

## Smaller alternative rejected

**The smaller design, written out so stage 3 can reconstruct it line by line** — call it *three local
hardenings, no new function* (≈ `+13 / −9`, zero new functions, zero new concepts):

1. `load_nodes()` and `load_settings()` each become
   `json.loads(<PATH>.read_bytes().decode("utf-8"))` — two changed lines. Locale-independent decode,
   FR-2's mechanism without FR-2's vocabulary.
2. Each of the four accessors (`_load_lang` `:389-392`, `_saved_clash_port` `:415-418`,
   `_ipv6_setting` `:1571-1574`, `_telemetry_setting` `:1790-1793`) narrows its guard tuple to
   `except (OSError, ValueError)` — which does now cover `UnicodeDecodeError` — and gains one line,
   `if not isinstance(settings, dict): return <its default>`, immediately after the read. Four changed
   lines, four added.
3. The write end takes exactly this design's E-11, E-12, E-13, E-15: `encoding="utf-8"` on
   `os.fdopen`, `encoding="utf-8"` + `ensure_ascii=False` on `save_settings`, and
   `except (OSError, ValueError)` with `getattr(e, "strerror", None) or str(e)` at the two renderers.

**What it satisfies, in full and without argument:** FR-2's decode, FR-4 (all four accessors return
their documented defaults for every unusable cause, including the `AttributeError` pair R-29 missed),
FR-10, FR-11, BC-1, BC-2, BC-3 — including the `"telemetry"` substring accident, which the
`isinstance` line closes exactly as well as the reader does — BC-4, BC-10, BC-11, BC-14, BC-16, and
AC-1 through AC-5 minus their warning-line clause, plus AC-11, AC-12, AC-13, AC-14, AC-15, AC-16,
AC-17 (it adds no key at all) and AC-19 with room to spare. It is genuinely correct code, it is 57
lines smaller, and on R-29's and R-62's own terms it is a complete fix. **This is not a strawman: it
is what the brief asked for, and half of this design's own diff is literally its item 3.**

**What the extra code buys, against which requirement:**

- **FR-8 / AC-8 / AC-9 (twelve tracebacks).** The smaller design leaves all seven `load_nodes()` call
  sites unguarded: `sc ls`, `sc now`, `sc status`, `sc use`, `sc add`, `sc rm` and `generate_config()`
  still end in a `UnicodeDecodeError` / `JSONDecodeError` / `TypeError` / `KeyError` traceback on a
  broken node store, and `{}` still gives `KeyError: 'nodes'`. Closing them there costs a guard at each
  of the seven — seven decision sites, which AC-18 forbids by name. FR-3's `member` check plus the
  exception envelope closes all seven at one site.
- **FR-6 / AC-6 (nine tracebacks).** The nine read-modify-write settings sites are equally unguarded in
  the smaller design; `sc lang zh` on a non-JSON `settings.json` still tracebacks, and AC-6 demands one
  sentence and a non-zero exit. Again: nine guards there, one arm here — an arm that **already exists**
  and that this design does not touch.
- **FR-5 / AC-3.** With four independent readers there is no single site to warn from without a
  module-level flag; the shared degrade makes the one line free and structurally once.
- **FR-1 / FR-3 / AC-18.** "One contract, not per-caller guards" is a *checkable* requirement here, and
  the smaller design cannot satisfy it: it leaves four copies of the judgment "is this document
  usable?" and adds a fifth notion (`isinstance` at the accessor) that no `nodes.json` caller shares.
- **FR-12.** Untouched by the smaller design; `_init_files()` stays a second writer, and "add an
  encoding" is precisely the second edit that duplicated writer would force next time.

Rule 85's tie-break settles ties **between designs that satisfy the same requirement**. These two do
not: the smaller one leaves 16 of the 17 unguarded call sites tracebacking, which is the stated goal of
the row. The ~57 extra lines are bought by the four requirements above and by nothing else, and 30 of
them are recovered as deletions.

**Second, nearer alternative — this design minus `_settings_or_empty()` and `_unusable()`** (≈ `+45`
code instead of `+46`, but `+73 / −32` overall): keep `_read_state`, let each of the four accessors
carry `except OverrideError: return <default>`, put the warning inline in `_load_lang()`'s arm, and set
`.path` with a trailing `except OverrideError as e: e.path = path; raise` inside the reader. It
satisfies **every** FR and BC of this row. It was rejected on three counted grounds, not on taste: it
adds three more lines to the file than this design does (its deletions are 11 fewer); it leaves four
sites deciding what a broken `settings.json` means, where AC-18 allows three in total across both
documents; and it spreads the `OverrideError` construction that T-24 may need to re-parent across five
raise sites instead of one. The first ground is measured, the third is the nameable future edit rule 85
requires.

**Also declined as larger:** a sibling exception class plus a second `main()` arm (a second opinion
about one fact — rule 85 test 2); renaming `OverrideError` to a document-neutral name (`+23 / −23` for
zero behaviour, and a guaranteed conflict with T-24's diff); a `(doc, problem)` return tuple (17 call
sites); folding `_load_override()` into `_read_state()` (forbidden by out-of-scope item 1, and their
policies genuinely differ — stat-first, size cap, whitespace-as-absent); and returning `{}` for an
absent file in **both** documents, which would drop the `default` parameter but tell a user whose
`nodes.json` was deleted that its `"nodes"` member is not an array.

## Frozen set

| path | why frozen |
|---|---|
| `bin/sc` `_write_private()` body except the one `encoding=` argument (`:504-526`) | T-13's property: credential bytes never wider than `0600` at any instant. `mkstemp` → `fchmod` → write → `replace` ordering and `dir=` are each load-bearing (NFR-5, AC-15). |
| `bin/sc` `_config_digest()` / `_record_generated()` / `_drift_state()` (`:1906-1977`) | T-14: the drift record is a sha256 of the file's **bytes**. Adding a decode anywhere here would make the verdict locale-dependent (NFR-6, AC-16, BC-16). |
| `bin/sc` `_load_override()` (`:1425-1496`), `OverrideError` (`:1179-1198`), `main()`'s handler (`:3673-3690`) | T-24 owns the override error model; this design consumes the envelope and changes none of it (out-of-scope item 1, K-9). |
| `bin/sc` `cmd_config()`'s reader (`:3039-3058`) and `_doctor_ipv6()`'s (`:2634`) | Q-6: they already answer with a sentence and a non-zero exit; a UTF-8 decode would trade that for a traceback on stdout. |
| `bin/sc` `settings.json`'s mode and write mechanism (`write_text`, no temp, no `chmod`) | Q-10 / out-of-scope items 6 and 7; `sc doctor` excludes that surface by name. |
| `bin/sc` `_ipv6_setting()` / `_telemetry_setting()` unrecognised-value stderr notices (`:1580-1582`, `:1799-1801`) | BC-4 is explicitly untouched by this task. |
| `bin/sc` `main()`'s `("doctor", "config")` read-only enumeration (`:3656`) | A positive opt-out by name; a new command must keep inheriting the initialising arm (dev-map "patterns to avoid"). |
| `bin/sc` every existing `TRANSLATIONS` entry; `HELP_EN` / `HELP_ZH` | NFR-2: the vocabulary already carries every sentence this row owes; only I-9 is added. |
| `install.sh`, `uninstall.sh`, `systemd/`, `README.md`, `README.zh-CN.md` | NFR-3: the change lives in `bin/sc` plus `CHANGELOG.md` and this task's documents. No user-visible command surface changes. |
| `docs/tasks.md`, `.harness/**` | PM-owned at delivery (rotation, insight index, rejected-decisions record). |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | E-1, E-2, E-17 | None. The reader and its factory are unreferenced until step 2, so `python3 -m py_compile bin/sc` is the only gate; I-9's key must land with its zh entry in the same commit. | Delete the three additions; nothing else refers to them. |
| 2 | E-3, E-4 | Step 1 shipped. After this step every read of both documents already flows through the reader and the 17 unguarded call sites already behave per FR-6 / FR-8 — this is the step that carries the behaviour change. | `git checkout bin/sc`. On-disk formats are unchanged, so a downgrade reads every document the new build wrote. |
| 3 | E-5, E-6, E-7, E-9, E-10 | Step 2 shipped, otherwise the four accessors would degrade on an exception that cannot yet be raised. FR-4 and FR-5 hold only after this step; between steps 2 and 3 an unusable `settings.json` **aborts** every command, which is why 2 and 3 ship together. | Same; the accessors' defaults are unchanged either way. |
| 4 | E-8 | Step 3 shipped. Discharges R-27: no run after this point rewrites an unreadable `settings.json`. | Same. Reverting restores the clobber, so it is the last thing to revert. |
| 5 | E-11, E-12, E-13, E-14, E-15 | Independent of steps 1-4 and separately revertible. E-14 requires E-13 (the seed inherits `save_settings`'s encoding). | Same. Bytes written before and after are identical for ASCII documents (AC-13), so no data migration and no forward/backward compatibility step exists at all. |
| 6 | E-16 | Steps 2-3 shipped, otherwise doctor's guard would no longer catch the exception the reader used to raise. Ship in the same commit as step 2 if the steps are squashed. | Same. |
| 7 | E-18, E-19, E-20, E-21 | Product diff complete and `verify_all` PASS 17 / WARN 0 / FAIL 0 / SKIP 1 from the repository root. | Documentation only. |

**No data migration, no feature flag, no compatibility window.** Neither document's on-disk format
changes; the only byte-level difference is that a `settings.json` holding a non-ASCII value — which no
`sc` code path can produce — is rewritten with that value literal instead of `\uXXXX`, which decodes to
the same value under any build. A host that downgrades after this change loses the sentences and
regains the tracebacks; it loses no data.

## Out of scope

1. `override.json`, `_load_override()` and the merge pipeline's error model — T-24, including any
   rename or re-parenting of `OverrideError`.
2. The encoding of `sc`'s output streams; a non-ASCII node tag still fails while encoding stdout under
   a non-UTF-8 locale (BC-14) — T-25.
3. `t()` returning keys verbatim in English — T-25.
4. The `config.json` readers' decoding (Q-6) and any change to `sc config`'s or `sc doctor`'s output.
5. Per-element validation of `nodes.json` entries; a non-object element or a missing `tag` is still a
   traceback outside `sc doctor` (BC-9).
6. A byte-size cap on a state document (Q-11), an `S_ISREG` test, and a whitespace-as-absent rule.
7. `settings.json`'s file mode, the atomicity of its write, and a write-failure guard in
   `save_settings()` — a `write_text` that fails still tracebacks, exactly as at HEAD (Q-10,
   out-of-scope item 7; residual RT-4).
8. A new `sc doctor` row for state-document health (Q-3), and any change to doctor's exit scale.
9. Reordering `sc on` / `sc off` so the settings read precedes the service action (BC-13).
10. A committed test suite (T-28) and `archive-task.sh` (T-27); the fixtures below are stage artifacts.
11. Validation of setting **values** (BC-4) and of `lang`'s value in particular.

## Verification plan

Every step runs against a `mkdtemp()` fixture built per K-13. `HEAD control` means the same step on a
pristine checkout of `HEAD`; a step whose control does not reproduce the stated failure is inconclusive,
never a pass.

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `sc ipv6 show` through `main()` on a `settings.json` of invalid UTF-8 bytes | exit 0, the IPv6 decision printed, **exactly one** stderr line naming `settings.json` with a cause meaning not-valid-UTF-8, no `Traceback`; control tracebacks non-zero | AC-1 |
| V-2 | `sc telemetry show` and `sc status` on the same fixture | same single line; `block`; the saved port treated as unrecorded | AC-2 |
| V-3 | four fixtures — `null`, `42`, `"telemetry"`, `[]` — × all four accessors' observables, driven through `main()` | every accessor returns its documented default, one warning line per run, and the `"telemetry"` fixture yields `auto` **only** via the default path; controls show `TypeError` ×2, `AttributeError` ×2 and a silent `auto` | AC-3 |
| V-4 | any command with `settings.json` removed | no warning line on stderr, every accessor at its default, exit as usual | AC-4 |
| V-5 | a usable `settings.json` with `lang: zh`, `ipv6: off`, `telemetry: allow`, a recorded `clash_api_port` | Chinese output, the `off` decision, `allow`, that port in use, **no** warning line | AC-5 |
| V-6 | `sc lang zh` on an unusable `settings.json`; sha256 of the file before and after | non-zero exit, one `Cannot use …settings.json: <cause>` sentence, digest unchanged | AC-6 |
| V-7 | a run that probes a Clash port on an unusable `settings.json`; digest before/after | digest unchanged; control shows the file replaced by a single-key document | AC-7 |
| V-8 | 4 `nodes.json` fixtures (non-UTF-8 / non-JSON / non-object / `{}`) × `sc ls`, `sc now`, `sc status`; digest before/after each | 12 runs: non-zero exit, one sentence naming `nodes.json` and its cause, no `Traceback`, file byte-identical; control tracebacks all twelve | AC-8 |
| V-9 | `sc doctor` on those four fixtures | complete table including its last row, exit on doctor's own 0/1/2 scale, the node-delay row naming the unreadable file, no `Traceback` | AC-9 |
| V-10 | `sc ls` / `sc now` on a usable two-node `nodes.json` | both rows printed, exit 0; the active tag printed | AC-10 |
| V-11 | under **all three** of `LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0`, `sc add` of AC-11's trojan URL; then read `nodes.json` as bytes. The step's **first act** is to assert the environment is non-UTF-8 — `sys.stdout.encoding` and `locale.getpreferredencoding(False)` are not UTF-8 aliases (`ascii` / `ANSI_X3.4-1968` on this host). `PYTHONCOERCECLOCALE=0` alone does **not** produce one: PEP 540 auto-enables UTF-8 Mode whenever `LC_CTYPE` is `C`/`POSIX`, so without `PYTHONUTF8=0` the process is fully UTF-8 and HEAD passes this step unchanged. If that first assertion fails, nothing measured under it is evidence and the step is inconclusive, never a pass | **Disk clause (owed by this row):** the stored password decodes from the file's bytes as UTF-8 to exactly the constant the URL carries, with no `\uXXXX`; HEAD control raises `UnicodeEncodeError` while writing and stores nothing. **Process-exit clause: BLOCKED-BY-T-25** — with the environment corrected, correct code writes the right bytes and then dies at `bin/sc:2345` in `cmd_add`'s own success line, whose `U+2192` is an sc-authored character and not a node tag (out-of-scope item 2, BC-14, RT-3). Report that clause as blocked with this ground; never as a pass, never silently dropped | AC-11 |
| V-12 | same three variables and the same first-act environment assertion as V-11; `nodes.json` already holding a CJK-tagged node; add an ASCII-only node; byte-compare the pre-existing tag | **Disk clause (owed by this row):** that tag's bytes identical after the read-modify-write, no `\uXXXX` anywhere; HEAD control raises `UnicodeDecodeError` on the read and writes no node store. **Process-exit clause: BLOCKED-BY-T-25** on the same `bin/sc:2345` ground as V-11 | AC-12 |
| V-13 | differential run of both checkouts over one ASCII fixture set under a UTF-8 locale | `settings.json`, `nodes.json`, `config.json` byte-identical between builds | AC-13 |
| V-14 | `stat` after each write in V-11..V-13 | `config.json`, `nodes.json`, drift record `0600`; `settings.json` the mode HEAD gives under the same umask | AC-14 |
| V-15 | read the shipped `_write_private()` | `mkstemp(dir=…)` → `fchmod` on the empty descriptor → write → `fsync` → `replace`, unchanged apart from `encoding="utf-8"` | AC-15 |
| V-16 | read the shipped `_config_digest()` | still `CFG_PATH.open("rb")`, no decode | AC-16 |
| V-17 | `git diff` of `TRANSLATIONS`; `verify_all` A.1 | exactly I-9 added, with a zh entry, no `失败`; A.1 PASS | AC-17 |
| V-18 | count the sites in the shipped file that decide what a broken state document means | exactly three — `_settings_or_empty()` (degrade), `main()`'s `OverrideError` arm (abort), doctor's node-delay row — plus `_resolve_clash_port()`'s FR-7 *write* refusal, which decides not to overwrite rather than what the document means; no per-call-site guard among the 17 | AC-18 |
| V-19 | `git diff --stat bin/sc` | within `+70 / −43`, 46 added code lines, no new file, no new module | AC-19 |
| V-20 | `.harness/scripts/verify_all` from the repository root (never a subdirectory) | PASS 17 / WARN 0 / FAIL 0 / SKIP 1 | AC-20 |
| V-21 | **operator obligation, BLOCKED for every agent** (needs root and the installed binary): install the new `bin/sc`, `sudo sc add` a share URL with a non-ASCII password, `sc reload`, confirm the real `sing-box check` accepts the regenerated config | recorded in `07_DELIVERY.md` as an owner action with this recipe; never substituted by a fixture | AC-21 |
| V-22 | read the shipped `_init_files()` | exactly one writer of `settings.json` in the file (`save_settings`), reached by the seed; the `/var/lib/sing-box` literal untouched | FR-12 |
| V-23 | count stderr warning lines across a single run that reads `settings.json` three or more times (`sc ipv6 show`) | exactly one, and it is English even on a fixture whose intended `lang` is `zh` | FR-5, BC-12 |

## Residuals travelling

| id | statement | must reach |
|---|---|---|
| RT-1 | `OverrideError` now carries state-document failures too. If T-24 renames or re-parents it, `_unusable()` is the single construction site to move; `main()`'s arm must keep honouring `e.path` and must not be narrowed to the override. | T-24 (`01_REQUIREMENT_ANALYSIS.md` input) |
| RT-2 | `_load_override()` and `_read_state()` are two implementations of "is this JSON document usable?" with deliberately different policies (stat-first, size cap, whitespace-as-absent vs. none of them). Collapsing them is T-24's call and is only safe if the override's three policies survive. | T-24 |
| RT-3 | Under a non-UTF-8 locale `cmd_ls` and `cmd_config` still raise `UnicodeEncodeError` while encoding their own stdout, and `t()` still returns keys verbatim in English. This row closes the disk layer only. **Two facts measured here that T-25 must inherit:** the failure is not confined to user data — `cmd_add`'s success line (`bin/sc:2345`) carries an sc-authored `U+2192`, so even an all-ASCII `sc add` exits non-zero; and a genuinely non-UTF-8 environment requires `PYTHONUTF8=0` alongside `LC_ALL=C PYTHONCOERCECLOCALE=0` (PEP 540 auto-enables UTF-8 Mode when `LC_CTYPE` is `C`/`POSIX`), so T-25's own criteria must pin all three or they verify nothing. | T-25 |
| RT-4 | `save_settings()` has no write-failure guard: an `EROFS` / `ENOSPC` write of `settings.json` is still a traceback, its write is still non-atomic and its mode is still `0644`. Unchanged from HEAD and excluded by Q-10 / out-of-scope items 6-7, but it is now the only authored document without a rendered write failure. | the `followups` pool (new row) |
| RT-5 | `sc on` / `sc off` still act on the service before reading `settings.json`, so BC-13's abort follows an action that stands. | the pool (out-of-scope item 10) |
| RT-6 | A future accessor that reads `settings.json` through `load_settings()` instead of `_settings_or_empty()` will **abort** rather than degrade. That is the safe direction for a persisting command and the wrong one for a read-only one; the choice is a one-word decision at each new site. | `docs/dev-map.md` (E-19) |
| RT-7 | The fixtures of `## Verification plan` are stage artifacts and are never committed under the worktree. | T-28 |
| RT-8 | Insight candidates for `07_DELIVERY.md` §Insight: (a) `main()` calls `_load_lang()` exactly once per run **before** `LANG` is assigned, which is a free once-per-run hook that renders in English; (b) `json.loads` accepts `bytes` and would auto-detect UTF-16, so an explicit `.decode("utf-8")` is what makes "UTF-8 regardless of locale" true. | PM at delivery |

## Partition assignment

`.harness/agents/dev-*.md` does not exist in this repository, and `.harness/rules/50-singbox-cli.md`
§Partitioning states single-developer explicitly. **Stage 4 is single-Developer** (`harness-kit:developer`),
which owns every row of the change ledger in the order given by `## Migration & edit sequence`. No
dispatch order and no parallelism apply.

## Verdict

READY
