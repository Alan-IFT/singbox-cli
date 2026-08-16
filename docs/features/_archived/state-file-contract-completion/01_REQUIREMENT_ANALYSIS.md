# T-29 · state-file-contract-completion — Requirement Analysis

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

Finish the file-I/O contract T-23 started: no read or write in `sc` may let the process locale decide
how a document is interpreted, the settings document's write failure must reach the user as a
sentence rather than a traceback, and a run that *acts* on an unusable settings document must refuse
instead of silently installing a configuration built from defaults the user did not choose.

## In-scope behaviors

**FR-1** — Every text read and every text write `sc` performs names its codec explicitly, and that
codec is UTF-8. The population this completes is six sites: the kernel IPv6 address source, the drift
record, the two readers of the generated configuration (`sc config`'s and `sc doctor`'s AAAA probe's),
the systemd timer drop-in writer and the OpenRC periodic-script writer. After this change no
interpretation of any file's bytes depends on `LC_ALL` / `LANG` / `LC_CTYPE`.

**FR-2** — Under a process locale that is not UTF-8, `sc config` produces the output it produces under
a UTF-8 locale for the same document: the read succeeds, every credential is masked, the masked
document reaches stdout and the run exits 0. A character stdout cannot encode is written as a
backslash escape by the existing stream configuration instead of ending the run.

**FR-3** — Under a process locale that is not UTF-8, `sc doctor`'s AAAA row states the same verdict it
states under a UTF-8 locale for the same document. It reports that the configuration cannot be read
only when the document genuinely cannot be read.

**FR-4** — A failed write of `settings.json` renders the project's existing "could not write" sentence
— naming that file and carrying a non-empty cause clause — and exits non-zero. This holds for every
failure class, including one whose exception carries no `strerror`; the renderer itself never raises.

**FR-5** — The Clash-API port resolver's opportunistic persist keeps its silent-continue outcome: when
recording a freshly probed port fails, the run emits no sentence, does not change its exit status, and
proceeds with the probed port. It is the one write of `settings.json` that is not the run's own purpose.

**FR-6** — A run that would regenerate `config.json` while `settings.json` is present and *unusable*
refuses: it composes no document, writes no configuration, records no drift digest, takes no
service-affecting action, states the file and the cause in one sentence and exits non-zero. The
settings document is left byte-identical, and so are the configuration and the drift record.

**FR-7** — `sc update-rules` keeps its one-outcome contract when FR-6 refuses its recovery
regeneration: the run still prints exactly one run-level outcome line saying what happened to the
service, and then exits non-zero.

**FR-8** — Commands that only report are unaffected by FR-6. On an unusable `settings.json`,
`sc doctor`, `sc config`, `sc ls`, `sc now`, `sc status`, `sc log` and the `show` forms of `sc ipv6` /
`sc telemetry` / `sc update-interval` still run, on the documented defaults, with the single warning
line the run already emits and with their usual exit status.

**FR-9** — The committed contract suite gains one assertion for each property this task establishes
that no existing assertion covers — FR-1's explicit-codec property over the whole source, FR-6's
refusal, and FR-4's rendering — and the assertion floor rises by exactly the number of assertions
added.

## Out of scope

1. `settings.json`'s file mode (`0644`) and the atomicity of its write — both unchanged. It is not a
   credential document, and narrowing its mode is a user-visible change nobody asked for.
2. Routing `settings.json` through the credential writer, or giving it any second writer.
3. The write-failure *rendering* of the systemd timer drop-in and the OpenRC periodic script; only
   their codec changes here. Their arms are init-system-gated and their outcome is already reported
   through the init system's own result.
4. Reordering any command so its settings read precedes its service action.
5. The drift record's ordering against `sing-box check`, and the delay reader's return shape — T-30.
6. `archive-task.sh`'s index rewrite and the destructive-command guard — both owned elsewhere.
7. Per-element validation of `nodes.json`; the user override's error model; any change to the
   redaction rule, its key sets, or `sc config`'s single stdout write.
8. Any new user-facing sentence **the program emits** in either language, including a repair hint
   appended to the unusable-document sentence. AC-11's paragraph correction is documentation, not
   program output, and adds no translation key.
9. Any byte-size cap, `S_ISREG` test or whitespace-as-absent rule on any document.
10. Any change to either README beyond the one `sc config` stdout/stderr paragraph AC-11 requires.
    That paragraph is corrected here, in both languages (Q-14); every other sentence of both files
    stays byte-identical, and the sweep of the project's remaining prose stays T-32's.

## Boundary conditions

**BC-1** — `settings.json` absent → unchanged: it is seeded, every accessor answers its documented
default, no warning line is written, and FR-6 does not fire. Absence is not unusability.

**BC-2** — `settings.json` present and empty (zero bytes or whitespace only) → *unusable*: FR-6
refuses every regenerating run, FR-8 keeps every reporting run working.

**BC-3** — `settings.json` valid JSON but `null`, a number, a string or an array → *unusable*,
identically to BC-2; no value may be derived from such a document by any accessor.

**BC-4** — `settings.json` usable but carrying an unrecognised value for a key → unchanged: the
accessor's existing one-line notice plus its default, and regeneration proceeds. An unrecognised value
is not an unusable document.

**BC-5** — A write of `settings.json` that fails part-way leaves a truncated or empty document,
because that write is not atomic and this task does not make it so. The next run reports it as
*unusable* by name (BC-2) and FR-6 refuses; removing the file restores every default. Stated, not
repaired.

**BC-6** — A settings value that UTF-8 cannot encode — a lone surrogate a hand edit supplied through a
`"\udXXX"` escape, which the parser accepts — reaches the writer → FR-4's sentence with a non-empty
cause and a non-zero exit. The cause clause must not be filled from an attribute only OS errors carry.

**BC-7** — No site hands `bytes` to the JSON parser: the parser auto-detects UTF-16/UTF-32 and would
silently accept a document that is not UTF-8 at all. The explicit decode precedes the parse at every
site FR-1 touches.

**BC-8** — A decode failure is reported as a read failure, never as a JSON failure, at every site whose
sentences distinguish the two — the decode error class is a subclass of the parse error class, so
clause order and catch family are load-bearing.

**BC-9** — T-13 is untouched: the credential writer remains the single definition of installing a
credential document and the only writer of `config.json`; the mode is set on the descriptor before the
first byte; credential bytes never exist at a mode wider than `0600` at any instant. No site this task
changes writes a credential document.

**BC-10** — T-14 is untouched: the drift record stays a sha256 digest of the configuration file's
**bytes**, never a copy and never a hash of decoded text, so it is immune to every codec change here
by construction.

**BC-11** — T-06 is untouched: `sc config` renders always-redacted with no opt-out. Nothing added here
creates a path to an unmasked value, and a backslash-escaped rendering of a masked document carries no
credential byte.

**BC-12** — Every sentence FR-6 renders about `settings.json` is in **English**, because the language
preference lives in the document that could not be read. No criterion may assert Chinese output for
that class; a Chinese assertion is valid only on a fixture whose settings document is usable and sets
`lang: zh`.

**BC-13** — A node-store write a command already performed before FR-6's refusal stands and is not
rolled back, exactly as a service action already taken stands today. The refusal's job is to stop the
configuration being replaced, not to unwind the command.

**BC-14** — `sc use` on a running host reaches its Clash-API hot switch before any regeneration, so
FR-6 does not fire on that path; the node switch still applies on an unusable settings document.

**BC-15** — A state document replaced concurrently by `sc`'s own writer is still read whole or not at
all wherever that property exists today (a completed temporary renamed over the target); `settings.json`
gains no such property here (BC-5).

**BC-16** — The assertion floor is a floor: no assertion is removed to make a number, and the floor is
raised by exactly the count of assertions added. A change that touches a pinned contract updates the
suite honestly.

## Acceptance criteria

Class **[B]** = verified by observing a run; **[S]** = verified by reading the shipped source or diff.
Every [B] row names the sentence owed *and* the exit status owed; none is discharged by the absence of
a traceback. A row whose HEAD control does not reproduce the stated failure is reported
**NOT-DISCRIMINATING**, never passed.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | On a fixture holding a usable node store, a `config.json` of known bytes, a drift record of known bytes and a `settings.json` that is not valid JSON, `sc reload` exits non-zero, writes **exactly one refusal sentence** naming the settings file and its cause — *in addition to* the single announcement of that same fact the run already emits before the command dispatches (FR-8's line), which this row does not count and does not forbid — and leaves `config.json`, the drift record and `settings.json` all byte-identical. No restart is attempted. | [B] | run + sha256 of all three before/after. HEAD control on the same fixture exits **0** and replaces both the configuration and the drift record. A build that avoids a traceback while still writing `config.json` FAILS this row |
| AC-2 | On that same fixture, whose `config.json` was generated while the settings document was usable and carried `telemetry: allow` and a recorded Clash port, the HEAD control's regenerated document differs from the pre-existing one in both ways the defect names — a telemetry NXDOMAIN rule appears, and the Clash API's external controller port changes — while the candidate emits no document at all. | [B] | diff the two emitted documents on the control; assert non-existence of a new document on the candidate. If the control reproduces neither difference, report NOT-DISCRIMINATING |
| AC-3 | With a **usable** `settings.json` carrying `lang: zh`, `ipv6: off`, `telemetry: allow` and a recorded Clash port, `sc reload` exits 0; the written configuration carries no telemetry rejection rule, carries the AAAA rule for the `off` decision at the head of the DNS rules, and names the recorded port as the Clash API's external controller; the drift record equals the sha256 of the written file's bytes; the output is Chinese. | [B] | run + read the emitted document. This is the control that fails any build which refuses on a usable document, and the row that proves a valid settings file still takes effect unchanged |
| AC-4 | On AC-1's unusable fixture: `sc doctor` prints its complete table including its last row and exits on its own 0/1/2 scale; `sc ls` exits 0 and prints its node rows; each run writes exactly one warning line naming the settings file and no `Traceback`. | [B] | two runs; assert the table's last row and the node rows are present. Fails a build that made the refusal global |
| AC-5 | With no init system detected, `sc update-rules` driven so its recovery regeneration is reached (an existing configuration, a rule-set whose bytes changed and which became usable) prints **exactly one** run-level outcome line naming what happened to the service and then exits non-zero on the unusable-settings fixture. | [B] | run with stubbed fetches; count outcome lines. The restart arm is unreachable under this fixture and is named as excluded, not counted |
| AC-6 | With `settings.json` mode `0444` and the process not root, `sc mode global` exits non-zero with the existing "could not write" sentence naming that file and a non-empty cause; stderr carries no `Traceback`. | [B] | run; HEAD control raises `PermissionError` as a traceback |
| AC-7 | With `settings.json` holding a value that UTF-8 cannot encode (a `"\udXXX"` escape the parser accepts), `sc mode global` exits non-zero with the same sentence and a non-empty cause, with no `Traceback` and no error raised from inside the handler itself. | [B] | run; the HEAD control must show an encode error escaping as a traceback, otherwise report NOT-DISCRIMINATING |
| AC-8 | With a usable `settings.json` that records no Clash port and is mode `0444`, a reporting command completes with its usual output and exit status, writes no "could not write" sentence, and leaves the settings file byte-identical. | [B] | run + digest. Fails a build that made the opportunistic persist loud |
| AC-9 | Under an environment **proved non-UTF-8** — `LC_ALL=C`, `PYTHONUTF8=0` and `PYTHONCOERCECLOCALE=0` all set, with `sys.stdout.encoding` and `locale.getpreferredencoding(False)` asserted in that same process to be no UTF-8 alias **before any other clause of this row is credited** — `sc config` on a configuration carrying a CJK node tag and a fixture credential exits **0**, prints the masked document on stdout with that tag rendered as a backslash escape, and writes no "cannot read" sentence. | [B] | assert the environment first (an assertion made without `PYTHONUTF8=0` passes vacuously and credits nothing); then run in a child process whose harness loads the source through the mandated recipe. HEAD control in that same environment exits 1 with "cannot read" and prints no document |
| AC-10 | Under the same proved environment and the same document, `sc doctor`'s AAAA row states the host's decision and whether the configuration carries it, and never reports that the file cannot be read. | [B] | run; HEAD control reports the row as UNKNOWN naming a decode error |
| AC-11 | Both READMEs' `sc config` stdout/stderr paragraph is true of the shipped code, and carries **in each language** all four assertions: (a) a character stdout cannot encode is written as a backslash escape and the run does not end — the whole masked document reaches stdout and the run exits 0; (b) the escape has **three** spellings — `\xNN`, `\uNNNN`, `\UNNNNNNNN` — and which one appears is decided by the character: a character in the Latin-1 range, a character elsewhere in the BMP (the CJK case), and a character above the BMP respectively; (c) **only `\uNNNN` is a JSON escape**, so a redirected file whose escapes are all of that form is still valid JSON, while a file carrying either other spelling is not; (d) running under a UTF-8 stdout is how an unescaped document is obtained in every case. Neither paragraph claims that escaping makes the saved file invalid irrespective of the character, and neither makes a claim about the saved file that the fixture below does not verify. The two paragraphs assert the same facts as each other; the wording is the author's, in each language. Every other sentence of both files is byte-identical to HEAD. | [S]+[B] | under AC-9's proved non-UTF-8 environment, run `sc config` on a configuration carrying one node tag per spelling (AC-9's CJK tag among them), redirect stdout to a file, and `json.loads` each of the three saved files; each paragraph is read against that measured three-row table. Then `git diff` both READMEs and assert the only hunk in each is that paragraph. **The control is HEAD's own text, which FAILS clause (c)** on the CJK row — the saved file parses — so the row is not vacuous; a build that leaves either paragraph at HEAD, or corrects only one of the two languages, FAILS |
| AC-12 | No text read or write in the shipped `bin/sc` leaves its codec to the process locale: every text read and every text write names UTF-8 explicitly, and no site passes `bytes` to the JSON parser. | [S] | scan the shipped file; pinned by AC-13's new assertion so the property survives the next edit |
| AC-13 | The contract suite reports `defined == run == passed` at the raised floor, and **each** newly added assertion is killed by a stated mutation applied to a scratch **copy** of the source — for the codec property a codec **substitution**, never deletion of the argument, which is invisible on a UTF-8 host. | [B] | run the suite per mutation; report any assertion no mutation kills as NOT-DISCRIMINATING rather than passed |
| AC-14 | `.harness/scripts/verify_all`, invoked from the repository root, reports PASS 19 / WARN 0 / FAIL 0 / SKIP 1 and exit 0, and the assertion floor in the baseline equals the number of assertions the suite defines. | [B] | run at stages 4 and 6; a subdirectory invocation self-reports a false red and is not evidence |
| AC-15 | T-13 and T-14 are preserved verbatim: the credential writer is unchanged and remains the only writer of `config.json`, still setting the mode on the descriptor before the first byte; the drift digest is still computed over the file's bytes; `settings.json`'s mode and write mechanism are unchanged. | [S] | read the shipped functions and `stat` the settings file after a run |
| AC-16 | T-06 is preserved verbatim: `sc config` still has exactly one stdout write whose argument passed through the redaction walk, the key sets and mask literal are unchanged, and no flag, setting or environment variable added here reaches an unmasked rendering. | [S] | read the shipped command and diff the key sets |
| AC-17 | The change adds no user-facing translation key, no new file, module, package or configuration format, and the product diff stays inside NFR-1's budget; `verify_all` A.1 stays PASS with this task's documents in place. | [S] | diff the translation table and `git diff --stat` |
| AC-18 | Every project document describing how these files are read is true of the shipped code — in particular the navigation entry describing `sc config`'s reader — and no document claims that a read decodes with the process locale. | [S] | read the shipped documents against the shipped code |
| AC-19 | On AC-5's fixture (no init system detected, an existing configuration, a rule-set whose bytes changed and became usable, stubbed fetches) but with a **usable** `settings.json` and an **unusable** `override.json`, `sc update-rules` driven to its recovery regeneration exits non-zero and writes **one sentence naming `override.json` and carrying a non-empty cause clause**. The same run with a usable `override.json` and an unusable `nodes.json` names `nodes.json` in that sentence instead. Neither run prints a line claiming the rule-sets were restored or the configuration regenerated, and neither prints more than one run-level outcome line: an arm that renders the cause and still reaches the outcome line prints exactly one (AC-5's contract, unchanged), an arm whose failure reaches the run's abort envelope prints none, as HEAD does — the cause sentence and the non-zero exit are the unconditional clauses. The absence of a `Traceback` discharges no clause of this row. | [B] | two runs; assert the failing document's name and a non-empty cause in the run's streams. **The discriminating control is a mutation**: a scratch **copy** of the source whose recovery regeneration handles every unusable-document failure in one undifferentiated clause must FAIL this row; if it passes, report NOT-DISCRIMINATING. The HEAD control also passes this row — the failure reaches the abort envelope, which names the path — so this is a **regression guard**, not a defect fix, and is reported as such. `settings.json` is usable here, so the pre-dispatch degrade line does not fire and cannot be counted as the cause sentence. The composition-fault path, whose failure carries no document, cannot fire under this fixture without an override and is named as excluded, not counted |

## Non-functional requirements

- **NFR-1** — Product diff budget for `bin/sc`: **≤ +25 / −12 lines, of which ≤ 14 added lines are
  code**. Provenance, not a round number: six codec arguments (six changed lines), the settings
  write-failure renderer mirroring the node-store writer's (+4 code), FR-6's refusal (+2 code), FR-7's
  outcome preservation (+2 code), and ≤ 6 documentation lines correcting comments the change falsifies.
  Stage 2 states the itemised count it spends and justifies any excess.
- **NFR-2** — Zero new user-facing translation keys. The existing vocabulary — `Cannot use {path}:
  {problem}`, `Could not write {path}: {err}`, `cannot read {path}: {e}`, `not valid JSON ({err})`,
  `not valid UTF-8 text`, `the top level must be a JSON object` — already carries every sentence FR-4
  and FR-6 owe, in both languages.
- **NFR-3** — No serialization layer, document registry, per-document class, new module or new
  configuration format. The three seams T-23 established — one state reader, one degrade, one abort
  envelope rendered at one site — are reused exactly as they stand; this task adds no fourth seam.
  Permitted paths: `bin/sc`, the contract suite, the assertion baseline, `CHANGELOG.md`,
  `docs/dev-map.md`, `README.md` and `README.zh-CN.md` (in the two READMEs, only the one paragraph
  AC-11 names), and this task's own documents.
- **NFR-4** — `.harness/scripts/verify_all` reports PASS 19 / WARN 0 / FAIL 0 / SKIP 1, invoked from
  the repository root.
- **NFR-5** — Safety, binding on stages 4 and 6: every fixture loads the source through the mandated
  loader recipe **and** the exec-denial shim the contract suite demonstrates; the first-run initialiser
  is never driven (it hard-codes a directory no fixture can repoint); `/etc/sing-box` and
  `/var/lib/sing-box` are never written; the live service is never touched; any service witness uses
  `systemctl show`, never `is-active`.
- **NFR-6** — Every locale criterion carries `PYTHONUTF8=0` alongside `LC_ALL=C` and asserts the
  process is non-UTF-8 before crediting anything measured under it; a locale criterion without that
  proof certifies nothing on Python 3.7+.
- **NFR-7** — No fixture, stage document or report contains a real credential.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | On an unusable `settings.json`, does a regenerating run refuse, warn, or preserve? | **Refuse.** Preservation is unavailable — nothing can recover choices from a document that cannot be parsed — and a warning still installs a configuration built from defaults the user did not choose. The run states the file and the cause, exits non-zero, and writes nothing (FR-6). The rule this settles for the whole project: **an unusable settings document blocks every run that writes, and blocks no run that only reports.** |
| Q-2 | Does that refusal create a second opinion about the document's usability, which T-16's AC-6 forbids? | No. The refusal is the existing single reader's *unusable* outcome, rendered by the existing envelope at the one site that already renders it. No new predicate, no second definition of "is this document usable", and the four accessors keep their degrade for reporting runs. |
| Q-3 | Does the refusal overturn R-27's ground that "what is discarded was not in effect"? | It does not overturn it; it bounds it. That ground holds where a discarded value is only *read* — the wrong answer dies with the process. It stops holding where the run *acts*: the regenerated document is installed and becomes what runs, so the discarded choices are exactly what the user loses. |
| Q-4 | For the remaining locale-dependent reads: a blanket sweep or a targeted fix? | **Blanket**, over six sites, on one stated rule: `sc` names the codec of every text read and write it performs. Two of the six carry a demonstrable defect today; one is an `sc`-authored document whose writer is already pinned to UTF-8 while its reader asks the locale; one reads kernel-owned ASCII and cannot change behaviour. The last is included because the cost is one argument and the benefit is a rule with **zero exceptions**, which a source scan can pin — a rule with one exception cannot be checked mechanically and costs every future reader a judgment call. |
| Q-5 | Which shipped sentence does the repair falsify, and is the duty to change it or to verify it? | Both READMEs' `sc config` stdout/stderr paragraph — and it holds two claims that part company. The **"instead of ending the run"** claim is **false at HEAD** (the run ends at the read, before stdout is reached) and **true after** the repair: verified unchanged. The **"so the saved file is then not valid JSON"** claim is **vacuous at HEAD** (that path saves no document at all) and **false after** the repair for exactly the document AC-9 mandates: `backslashreplace` has three spellings, the paragraph enumerates two, and the third — `\uNNNN`, the one a CJK tag produces — *is* a legal JSON escape, so that saved file parses. The duty is therefore **both**: verify the claim the repair makes true and correct the claim the repair makes false, here, in both languages (AC-11, Q-14). R-76's "verify, not change" disposition holds for the claim it measured and is superseded for the claim it did not enumerate. The state reader's own "never `read_text()`" clause is scoped to that reader and is true both before and after; the navigation entry describing `sc config`'s reader is corrected under AC-18. |
| Q-6 | T-23 declined the settings write guard because no value reaching it can fail a UTF-8 encode. Does the renderer still need the non-`OSError` arm? | Yes. The document written is the document read, and the JSON parser accepts an unpaired surrogate escape, so a hand-edited settings document yields a string UTF-8 cannot encode. The renderer therefore takes the same catch family and the same cause clause as the node-store writer, filled so that it cannot itself raise on an exception carrying no `strerror`. |
| Q-7 | Does the fix break the port resolver's deliberate swallow? | No — the swallow is preserved as a requirement (FR-5), and it is the one settings write that is not the run's own purpose. Whatever mechanism renders the other failures must leave that outcome silent and non-fatal; a renderer that exits cannot be caught as an OS error, and any design that ignores this converts a read-only command on a read-only host into a failure. |
| Q-8 | Should the unusable-document sentence gain a repair hint ("delete the file to return to defaults")? | No. The sentence renders at every unusable-document site, including the node store and the user's own override, where that advice would be wrong; making it per-document costs a second sentence and a conditional for a sentence that already names the file and the cause. |
| Q-9 | Should `settings.json`'s write become atomic, or its mode narrowed, while the write path is open? | No to both. It is not a credential document, its mode is excluded from the permissions report by name, and atomicity here would need a second write mechanism beside the credential writer. The truncation residual is stated (BC-5), not repaired. |
| Q-10 | Are the two init-gated writers (the timer drop-in, the periodic script) in scope for the rendering fix? | No — codec only (FR-1). Both arms are gated on a detected init system and are unreachable under the mandated fixture, so a rendering requirement over them could not be verified by any criterion this task can run; and their outcome is already reported through the init system's own result. That the settings writer is not the *only* authored document lacking a rendered write failure is stated here rather than left implied. |
| Q-11 | Does the contract suite grow, and does the floor move? | Yes: three assertions, one per property this task establishes (FR-1, FR-6, FR-4), and the floor rises by exactly three. The floor is never lowered; an assertion is never dropped to make a number. |
| Q-12 | Is the loader-recipe row (a missing `encoding="utf-8"` in the mandated recipe) still owed by this task? | No. The mandated recipe already carries the explicit codec and already names the silent-re-exec failure signature; the row is discharged in fact by the current text, and this task adds nothing to it. |
| Q-13 | Does any unit of this stage fit no declared section of the schema? | No. Rule 70 now declares a `## Stage-doc boundary rule`; every unit routed cleanly to this contract or to `01_RATIONALE.md`, and no schema-gap row is owed. |
| Q-14 | The clause the repair falsifies sits in a paragraph out-of-scope item 10 froze, and T-32 is the project's prose sweep. Where is the correction made, and how far does it reach? | **Here, in this task, in both languages, and no further.** A change may not ship a sentence it has itself made false: the claim is vacuous at HEAD and live the moment `sc config` starts reaching stdout, so deferring publishes a measured-false claim about the behaviour this very change introduces, for as long as T-32 waits. The reach is fixed by AC-11 and by out-of-scope item 10: the `sc config` stdout/stderr paragraph of `README.md` and `README.zh-CN.md`, one hunk per file, every other sentence byte-identical. This task adds **no** requirement about documentation accuracy in general, **no** doc-lint or prose-checking mechanism, **no** review of any other README sentence, and **no** change to `sc config`'s behaviour; the remaining prose sweep stays T-32's, at its own "correct the sentences and add nothing" limit. What binds the developer is the paragraph's behavioural assertions (AC-11 (a)–(d)); the wording is the developer's, and each language carries the same facts. |

## Verdict

READY
