# T-23 · state-file-io-contract — Requirement Analysis

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

`sc` reads and writes its own JSON state documents (`settings.json`, `nodes.json`) through one
contract — UTF-8 regardless of the process locale, one recognised failure family, one top-level
shape check — so that a non-UTF-8, non-JSON or wrong-shaped state document reaches the user as a
named sentence with the exit status its command owes, instead of as a Python traceback, and so that
a non-ASCII credential survives a write on a host whose locale is not UTF-8.

## In-scope behaviors

**FR-1** — Every read of a **state document** (`settings.json`, `nodes.json`) resolves through one
reader that answers exactly one of three outcomes: *usable* (the document, as a JSON object of the
shape FR-3 requires), *absent* (no such file), or *unusable* carrying a one-clause cause. That
reader prints nothing, exits no process, writes no file and repairs nothing — every rendering and
every exit decision belongs to its caller.

**FR-2** — The reader decodes a state document as UTF-8 independently of the process locale, so a
document holding non-ASCII text reads identically under `LC_ALL=C` and under a UTF-8 locale. A
document whose bytes are not valid UTF-8 is *unusable* with the cause "not valid UTF-8 text"; a
document that is valid UTF-8 but not valid JSON is *unusable* with the cause "not valid JSON",
carrying the parser's own message.

**FR-3** — The reader applies exactly one top-level shape check per document: `settings.json` must
be a JSON object, and `nodes.json` must be a JSON object whose `nodes` member is a JSON array. A
document failing its check is *unusable* with the cause naming the shape it violated, and no other
structural claim about the document is made or enforced.

**FR-4** — The four setting accessors — the language reader, the saved-Clash-port reader, the
`ipv6` reader and the `telemetry` reader — return their already-documented defaults (`en`, `None`,
`auto`, `block`) for *absent* and for every *unusable* cause, and propagate no exception. This holds
for a `settings.json` that is `null`, a number, or a JSON string, none of which may yield a value
derived from the document.

**FR-5** — In a run in which `settings.json` is present and *unusable*, `sc` writes exactly one
warning line to stderr naming the file and the cause, however many readers consulted it in that run.
A usable or *absent* `settings.json` produces no such line.

**FR-6** — A command that persists a setting (`sc lang`, `sc mode`, `sc ipv6 <value>`,
`sc telemetry <value>`, `sc default-tun`, `sc on`, `sc off`, `sc update-interval`) aborts on an
*unusable* `settings.json` with one sentence naming the file and the cause and a non-zero exit
status, and writes no state document in that run.

**FR-7** — Clash-API port resolution never writes to an *unusable* `settings.json`: it uses the
probed port for that run only, leaving the file byte-identical. This discharges R-27 — a document
`sc` could not read is never replaced by a single-key document `sc` composed.

**FR-8** — A command that requires `nodes.json` (`sc ls`, `sc now`, `sc use`, `sc add`, `sc rm`,
`sc status`, and configuration generation) aborts on an *absent* or *unusable* `nodes.json` with one
sentence naming the file and the cause and a non-zero exit status, before it writes any state
document and before it takes any service-affecting action.

**FR-9** — `sc doctor` aborts on no state-document cause: with `settings.json` and/or `nodes.json`
absent, non-UTF-8, non-JSON or of the wrong shape, it still prints its whole table and exits on its
own OK/UNKNOWN/PROBLEM scale, and the node-delay row it already owns keeps reporting the file it
could not read rather than a fabricated count.

**FR-10** — Every document `sc` authors — `settings.json`, `nodes.json`, `config.json`, the drift
record — is encoded as UTF-8 independently of the process locale, and non-ASCII characters are
written literally rather than as `\uXXXX` escapes, so the bytes written under a non-UTF-8 locale are
identical to those written under a UTF-8 one.

**FR-11** — No write of an authored document reaches the user as a traceback: a write that fails for
any cause, including an argument that cannot be encoded as UTF-8, renders the existing
"could not write" sentence with a non-empty cause clause at the site that already renders it, and
leaves the previous document byte-identical with no temporary file surviving.

**FR-12** — `settings.json` has exactly one writer, including its first-run seeding, as
`config.json` has exactly one; no second code path composes or emits that document.

## Out of scope

1. `override.json` and the merge pipeline's error model — T-24 owns them; the state reader must not
   change `_load_override()`'s behaviour or its sentences.
2. The encoding of `sc`'s **output streams**. Under a non-UTF-8 locale `sys.stdout` still encodes
   strictly, so printing a non-ASCII node tag still raises; this row closes the disk layer only, and
   the residual is stated in BC-14 and belongs to T-25.
3. `t()` returning keys verbatim in English (no `en` table) — T-25 owns it; this row must not spread
   it (NFR-2).
4. The `config.json` readers that already produce a sentence (`sc config`'s reader and doctor's AAAA
   probe): their reads keep their current decoding, for the reason in Q-6.
5. Per-element validation of `nodes.json` entries (a node lacking `tag` / `type` / `server` /
   `server_port`) — that is a schema, not a shape check; residual stated in BC-9.
6. Any byte-size cap on a state document.
7. The file mode of `settings.json` and the atomicity of its write — unchanged by this task.
8. A new `sc doctor` row for state-document health.
9. A committed test suite (T-28) and `archive-task.sh` (T-27).
10. Reordering `sc on` / `sc off` so the settings read precedes the service action (BC-13).

## Boundary conditions

**BC-1** — `settings.json` absent → every setting accessor returns its default, no warning line, no
non-zero exit; a fresh host and `sc doctor` on a wrecked host behave exactly as today.

**BC-2** — `settings.json` present and empty (zero bytes, or whitespace only) → *unusable* with the
"not valid JSON" cause; FR-4, FR-5 and FR-6 apply unchanged.

**BC-3** — `settings.json` valid JSON but `null`, a number, or a JSON string → *unusable*, never a
value derived from the document. In particular a JSON string must not answer a membership test: the
current build answers `auto` for a `settings.json` containing `"telemetry"` because `"ipv6"` is not
a substring of it, which is a silently wrong answer and is forbidden after this change.

**BC-4** — `settings.json` valid but a key's value is outside its accepted set → unchanged
behaviour: the accessor's existing one-line stderr notice plus its default. This class is not
touched by this task.

**BC-5** — `nodes.json` absent → FR-8's abort for every command that requires it, and doctor's
existing row for doctor. First-run seeding still creates it for every command that seeds, so this
case is reachable only when seeding is skipped or the file is removed mid-run.

**BC-6** — `nodes.json` present but not UTF-8, not JSON, not an object, or an object whose `nodes`
is absent or not an array → FR-8's abort with the matching cause; today three of these four classes
are tracebacks and the fourth (`nodes` absent) is a `KeyError` traceback.

**BC-7** — `nodes.json` usable with `nodes` an empty array → unchanged behaviour: `sc ls` prints its
"no nodes" line and exits 0. An empty node list is not a failure and must not become one.

**BC-8** — A state document replaced concurrently by `sc`'s own writer is read whole or not at all,
because the writer renames a completed temporary over it; this property is preserved, not added.

**BC-9** — `nodes.json` usable at the top level but holding an element that is not an object, or an
object missing a key a command indexes → still a traceback. Named residual, out of scope by item 5,
and no user-facing text may claim otherwise.

**BC-10** — A share-URL argument carrying raw (not percent-encoded) non-ASCII bytes under a
non-UTF-8 locale reaches the writer as text containing lone surrogates, which UTF-8 cannot encode.
FR-11 governs it: one sentence, non-zero exit or the existing warning-and-`False` at the
configuration writer, never a traceback, and the previous document intact.

**BC-11** — A write that fails at any point — encode, `write`, `fsync`, `replace` — leaves the
target document byte-identical to what it was, leaves no temporary behind, and leaves no credential
bytes at a mode wider than `0600` at any instant.

**BC-12** — The warning of FR-5 and every abort sentence of FR-6/FR-8 renders in **English**
whenever the cause is `settings.json` itself, because the language preference lives in the document
that could not be read; this is a consequence, not a defect, and no criterion may assume Chinese
output for that class.

**BC-13** — `sc on` / `sc off` act on the service before they read `settings.json`; on an *unusable*
document the service action stands, is not rolled back, and the command then aborts per FR-6. The
exit status is non-zero and the sentence names the file.

**BC-14** — Under a non-UTF-8 locale, a command that prints a non-ASCII node tag still fails while
encoding its own standard output. This row makes the tag survive on disk and does not make it
printable; no user-facing text, changelog or stage document may claim that non-ASCII tags work under
such a locale.

**BC-15** — A `settings.json` that is *unusable* leaves the Clash-API port re-probed on every run
(FR-7), so a run made while `sing-box` holds the previously probed port may resolve a different port
and report the Clash API unreachable. Accepted: the alternative is destroying a document the user
can still repair by hand.

**BC-16** — Reading a state document must not become a second definition of "which document is
this": the drift record keeps being a sha256 of the configuration file's **bytes**, never of decoded
text, so the drift verdict stays independent of locale and of this change.

## Acceptance criteria

Class **[B]** = verified by observing a run; **[S]** = verified by reading the shipped source or
measuring the diff. Every [B] criterion below names both the sentence owed and the exit status owed;
none is satisfied by the mere absence of a traceback.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | With a `settings.json` whose bytes are not valid UTF-8, `sc ipv6 show` exits 0, prints its IPv6 decision, and writes exactly one stderr line naming the settings file and a cause meaning "not valid UTF-8"; stderr contains no `Traceback`. | [B] | run under a redirected-paths fixture; HEAD-side control on the same fixture shows the traceback and a non-zero exit |
| AC-2 | The same fixture with `sc telemetry show` and with `sc status` gives the same one line and the same defaults (`block`, and the saved port treated as unrecorded). | [B] | run; compare against the documented defaults |
| AC-3 | For each of `null`, `42`, `"telemetry"`, `[]` as the whole content of `settings.json`, all four setting accessors return their defaults and the run carries FR-5's single warning line. The `"telemetry"` case must **not** yield `auto` by substring accident (BC-3). | [B] | four fixtures × the observable of each accessor; HEAD control shows `TypeError` for two accessors, `AttributeError` for two, and a silently wrong `auto` for the string case |
| AC-4 | With `settings.json` absent, no warning line is written on any command, and every accessor returns its default. | [B] | run with the file removed; assert stderr carries no such line |
| AC-5 | With a **usable** `settings.json` carrying `lang: zh`, `ipv6: off`, `telemetry: allow` and a recorded `clash_api_port`, each value is in effect (Chinese output, the `off` decision, `allow`, and that port used) and no warning line is written. | [B] | run; this is the control that fails any build whose reader always answers *unusable* |
| AC-6 | `sc lang zh` on an *unusable* `settings.json` exits non-zero with one sentence naming the file and the cause, and the file is **byte-identical** afterwards (sha256 compared before/after). | [B] | run + digest comparison; a build that rewrites the file fails, a build that exits 0 fails |
| AC-7 | On the same fixture, a command that would persist a freshly probed Clash port leaves `settings.json` byte-identical (FR-7 / R-27). | [B] | digest comparison across the run; HEAD control shows the file replaced by a single-key document |
| AC-8 | For each of a non-UTF-8, a non-JSON, a non-object and a `{}` (no `nodes`) `nodes.json`, each of `sc ls`, `sc now`, `sc use 1` exits non-zero with one sentence naming the nodes file and the cause; no `Traceback` on stderr; the file is byte-identical afterwards. The third command is `sc use 1`, not `sc status` (C-1): `sc status`'s only node-store read sits behind a service check that the mandated `SYSTEMD = OPENRC = False` fixture holds permanently false, so it reads no node store on either build and is not counted. | [B] | 4 fixtures × 3 commands, each against its HEAD control. The HEAD control is **eleven tracebacks and one silently wrong answer**, not twelve tracebacks: `sc now` on the `{}` fixture exits 0 at HEAD and prints `(none)`, because it reads only the `active` member and never the `nodes` member. That cell still discriminates — the candidate exits non-zero naming the file — and any report asserting "HEAD tracebacks all twelve" is false and fails this row |
| AC-9 | On those four fixtures `sc doctor` prints its complete table and exits on its own scale; where its node-delay row is reached it reports the unreadable file rather than a count. | [B] | run; assert the table's last row is present and no `Traceback` |
| AC-10 | With a usable `nodes.json` holding two nodes, `sc ls` prints both rows and exits 0; `sc now` prints the active tag. | [B] | control against a build that treats every document as unusable |
| AC-11 | Under an environment **proved non-UTF-8** — all three of `LC_ALL=C`, `PYTHONUTF8=0` and `PYTHONCOERCECLOCALE=0` set, with `sys.stdout.encoding` and `locale.getpreferredencoding(False)` asserted in that same process to be no UTF-8 alias **before any other assertion in this row is credited** — `sc add 'trojan://p%C3%A9q@h.example:443'` leaves `nodes.json` holding the new node, with its password decoding from the file's bytes as UTF-8 to exactly the constant the URL was written to carry, with no `\uXXXX` escape and no node lost. **Owed by this row:** that disk state, plus no `UnicodeEncodeError` or `UnicodeDecodeError` raised anywhere in the state-document read or write path and no "could not write" sentence on stderr. **Owed by T-25, not by this row:** the process exit status. Under the proved environment correct code writes the right bytes and then fails encoding `cmd_add`'s own success line, whose `U+2192` is an sc-authored character and not a node tag — out-of-scope item 2 / BC-14. That clause is recorded **BLOCKED-BY-T-25** in every report: never a pass, never a fail, never dropped. | [B] | assert the environment first (an assertion made where `PYTHONUTF8` is unset passes vacuously, because PEP 540 turns UTF-8 Mode on for a `C` `LC_CTYPE`, and credits nothing); then run and read the fixture file's bytes. HEAD control in that same environment raises `UnicodeEncodeError` inside the writer and leaves the node unwritten |
| AC-12 | Under the same proved-non-UTF-8 environment and under the same proof-first rule, with a `nodes.json` already holding a node tagged `香港节点` (written under a UTF-8 locale), adding a second, ASCII-only node leaves the rewritten file holding both nodes and the existing tag's bytes byte-identical to before — proving read **and** write survive the locale and that no `\uXXXX` escaping was introduced. **Owed by this row:** that byte comparison, plus no `UnicodeDecodeError` from the read path, no `UnicodeEncodeError` from the write path, and no "could not write" sentence on stderr. **Owed by T-25, not by this row:** the process exit status, for the reason stated in AC-11; recorded **BLOCKED-BY-T-25**, never a pass, never a fail, never dropped. | [B] | environment proof, then run + byte comparison of the pre-existing tag's bytes and a count of the nodes in the rewritten file; HEAD control in that same environment raises `UnicodeDecodeError` on the read and leaves the file unchanged |
| AC-13 | Under a UTF-8 locale and for identical inputs, the bytes of `settings.json`, `nodes.json` and `config.json` written by the new build are byte-identical to those written by HEAD. | [B] | differential run of both checkouts over one fixture set |
| AC-14 | After any run of the new build, `config.json`, `nodes.json` and the drift record are mode `0600`, and `settings.json` keeps the mode HEAD gives it under the same umask. | [B] | `stat` after each write |
| AC-15 | The credential writer still sets the mode on the descriptor before the first byte is written, still creates through an exclusive fresh name in the target's own directory, and still installs by rename. | [S] | read the shipped function; T-13's property is unchanged by the encoding argument |
| AC-16 | The drift digest is still computed over the file's bytes, never over decoded text. | [S] | read the shipped function (T-14) |
| AC-17 | The shipped diff adds no user-facing translation key; if any key is added it has a Chinese entry and its literal contains no `失败`. | [S] | diff the translation table; `verify_all` A.1 stays PASS |
| AC-18 | `bin/sc` contains at most three places that decide what a broken state document means (abort, degrade, doctor's row); the count does not grow with the number of call sites. | [S] | read the shipped source; the goal of this row is one contract, not per-caller guards |
| AC-19 | The product diff is within NFR-1's budget, adds no new file and no new module. | [S] | `git diff --stat` |
| AC-20 | `.harness/scripts/verify_all`, invoked from the repository root, reports PASS 17 / WARN 0 / FAIL 0 / SKIP 1. | [B] | run at stages 4 and 6 |
| AC-21 | On the owner's live host, after installing the new `bin/sc`, `sudo sc add` of a share URL carrying a non-ASCII password succeeds and `sc reload` regenerates a configuration the real `sing-box check` accepts. | [B] | **BLOCKED** for every agent (needs root and the installed binary) — file as an operator obligation with a recipe, never substitute |

## Non-functional requirements

- **NFR-1** — Product diff budget for `bin/sc`: **≤ +70 / −30 lines, of which ≤ 40 added lines are
  code rather than comment or docstring**. Provenance, not a round number: one reader (≈15 code
  lines with the house-style docstring), three reader call sites rewritten, four guard tuples
  narrowed to the reader's outcome, one warn-once site, one anti-clobber condition, three writer
  encoding arguments, two writer catch clauses, one seeding call, one central rendering arm. Stage 2
  states the itemised count it will actually spend and justifies any excess.
- **NFR-2** — Zero new user-facing translation keys are required: the existing vocabulary
  (`Cannot use {path}: {problem}`, `not valid UTF-8 text`, `not valid JSON ({err})`,
  `the top level must be a JSON object`, `cannot be read ({err})`, `no file at {path}`,
  `cannot read {path}: {e}`, `Could not write {path}: {err}`) already carries every sentence FR-5,
  FR-6, FR-8 and FR-11 owe, in both languages. Any key added anyway carries a Chinese entry and
  avoids `失败`.
- **NFR-3** — No new file, module, package or configuration format; the change lives entirely in
  `bin/sc`, plus `CHANGELOG.md` and the task's own documents.
- **NFR-4** — `.harness/scripts/verify_all` reports the batch baseline PASS 17 / WARN 0 / FAIL 0 /
  SKIP 1, and it is invoked from the repository root (running it from a subdirectory self-reports a
  false red).
- **NFR-5** — T-13 is preserved verbatim: credential bytes never exist on disk at a mode wider than
  `0600` at any instant, and the credential writer stays the only writer of `config.json`.
- **NFR-6** — T-14 is preserved verbatim: the drift record is a sha256 digest of file bytes, never a
  copy of credential bytes and never a hash of in-memory text.
- **NFR-7** — Safety, binding on stages 4 and 6: never write `/etc/sing-box` or `/var/lib/sing-box`
  on this host, never touch the live service, never run the installed `/usr/local/bin/sc`. Fixtures
  repoint the module-level path constants **and** must neutralise the first-run initialiser, which
  hard-codes `/var/lib/sing-box` as a literal and is therefore not repointable. Any service witness
  uses `systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active`.
- **NFR-8** — A fixture must not print or commit a real credential; `verify_all` A.1 ("no hardcoded
  secrets") stays PASS with the task's documents in place.
- **NFR-9** — A Chinese-language assertion is only valid on a fixture whose `settings.json` is
  usable and sets `lang: zh`, because the language is reassigned after import and an unusable
  document forces English (BC-12).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Is R-29's prescribed `except (OSError, ValueError, TypeError)` sufficient for the four accessors it names? | No. Two of the four reach `AttributeError`, which that tuple does not catch, and one reaches a silently wrong answer with no exception at all. The binding fix is the **is-a-dict check inside the single reader** (FR-1/FR-3); the catch family alone is not the contract. |
| Q-2 | Does a broken state document abort the command, or degrade to a default? | Both, split by document: `settings.json` degrades to documented defaults for the four accessors (FR-4) and aborts for the eight commands that persist a setting (FR-6); `nodes.json` always aborts (FR-8), because degrading to "no nodes" would let a subsequent write replace the user's node list. `sc doctor` never aborts on either (FR-9). |
| Q-3 | Is silent degradation acceptable for the accessors? | No. Degrading silently would replace a traceback with a wrong answer nobody can see, and no `sc doctor` row reports state-document health. Exactly one stderr line per run states the file and the cause (FR-5), and it is the only new output this row adds. |
| Q-4 | May the port resolver keep repairing a malformed `settings.json` by writing a fresh single-key document? | No (FR-7). A document `sc` could not parse may still be repairable by hand; replacing it destroys recoverable text. The consequence — a re-probed port each run — is accepted and stated in BC-15. |
| Q-5 | How deep does the shape check go? | Top level only: object for `settings.json`; object with an array `nodes` for `nodes.json` (FR-3). Per-element node validation is a schema and is out of scope; its residual is BC-9. |
| Q-6 | Should the `config.json` readers be re-pointed at the new reader, or given `encoding=`? | No, neither. They already answer with a sentence and a non-zero exit, and giving them a UTF-8 decode would turn `sc config`'s current one-sentence failure on a CJK-tagged document into a `UnicodeEncodeError` traceback while writing that document to a strictly encoded stdout. They become correct only after T-25; touching them now trades a good failure for a worse one. |
| Q-7 | Should the writers emit `\uXXXX` escapes instead of literal non-ASCII, which would make the locale irrelevant with no `encoding=` at all? | No. The disk documents are read by humans and by `sing-box`; escaping every CJK tag is a visible regression, and the read side needs a UTF-8 decode regardless because the user may hand-edit these files. Writers keep literal non-ASCII and gain an explicit UTF-8 encoding (FR-10). |
| Q-8 | Does the row own the encoding of `sc`'s output streams? | No (out-of-scope item 2). The disk layer and the terminal layer are different destinations with different failure semantics; the terminal belongs to T-25. This row closes the credential population of R-62 completely and the node-tag population only as far as disk; BC-14 states that limit and forbids over-claiming it. |
| Q-9 | Should the write path gain a guard for an argument that cannot be encoded, given UTF-8 encodes every ordinary string? | Yes. It is reachable: a raw non-ASCII byte in `argv` under a non-UTF-8 locale becomes a lone surrogate, which UTF-8 rejects. FR-11 requires a sentence for it, and the cause clause must not be filled from an attribute that only OS errors carry. |
| Q-10 | Should `settings.json` become atomic or `0600` while the write path is open? | No (out-of-scope items 6/7). Its atomicity is not part of the defect family, and narrowing its mode would change a surface `sc doctor` deliberately excludes by name. Its mode and write mechanism are unchanged; only its encoding and its single-writer property change. |
| Q-11 | Is a byte-size cap needed on a state document, mirroring the user override's? | No (out-of-scope item 6). The override is the user's document and untrusted by size; `sc` authors its own state documents. A cap would be a number with no owner, which is the defect R-61 records. |
| Q-12 | Is the family "four readers"? | No — restated bindingly: it is **two documents, two helper readers plus one inline language read, and 22 call sites**, of which 17 carry no guard at all. The contract is placed in the readers so that every call site inherits it, which is why the criteria are written per observable command rather than per call site. |
| Q-13 | Does rule 70 classify a unit this schema cannot hold? | Rule 70 declares no `## Stage-doc boundary rule` in this project (R-37, confirmed an eleventh time at T-22). The schema above is applied as written; evidence, measurements and rejected candidates live in `01_RATIONALE.md`. |

## Verdict

READY
