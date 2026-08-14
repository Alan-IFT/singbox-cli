# T-06 — sc-config-show · Requirement Analysis

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

A user who wants to see the sing-box configuration `sc` installed has no command that prints it, and
the only route to it — reading a `0600` credential document by hand — either fails or exposes every
node credential in the terminal; `sc` must be able to render that document readably with no
credential byte in the output.

## In-scope behaviors

**FR-1** — `sc config` prints the configuration document currently on disk at `/etc/sing-box/config.json`.
The command takes no flag and no positional value; it is a bare subcommand in the shape of `sc status`
and `sc doctor`.

**FR-2** — Every invocation of `sc config` is redacted. No flag, value, environment variable or
setting causes it to print an unmasked credential value; the unredacted document remains reachable
only by reading the file directly.

**FR-3** — Inside every element of the document's `outbounds` array, at every depth, a key that is
not named in the **visible key set** has its entire value replaced by the mask. The visible key set
is exactly: `type`, `tag`, `server`, `server_port`, `detour`, `outbounds`, `default`, `url`,
`interval`, `tolerance`, `idle_timeout`, `interrupt_exist_connections`, `method`, `security`,
`alter_id`, `flow`, `packet_encoding`, `congestion_control`, `udp_relay_mode`, `transport`, `tls`,
`obfs`, `enabled`, `server_name`, `alpn`, `insecure`, `utls`, `fingerprint`, `reality`, `path`,
`host`, `headers`, `Host`, `service_name`. A visible key whose value is an object or an array of
objects is walked with the same rule; every other visible value renders verbatim.

**FR-4** — Everywhere in the document, `outbounds` included, a value whose key is `password`, `uuid`,
`secret`, `token`, `private_key` or `pre_shared_key` is replaced by the mask. This set is a floor,
not the whole guarantee: FR-3 already masks `uuid`, `password`, `public_key` and `short_id` inside an
outbound by exclusion.

**FR-5** — The mask replaces the **value** and never the key, so which fields are present stays
observable. The mask is one fixed literal, identical for every masked value, carrying nothing derived
from the value it replaces — no prefix, no suffix, no length, no digest — and it applies whatever the
value's JSON type. Redaction preserves the document's structure: the printed text parses as JSON and
is equal to the file on disk at every unmasked position.

**FR-6** — The document is written to **stdout** and nothing else is, so `sc config > file` yields a
JSON document and `sc config | <filter>` works. The command's own commentary goes to **stderr** and
states, in the configured language: the absolute path of the document being shown, and that node
credentials are masked. When the drift record at `/etc/sing-box/.config.sha256` exists and is
readable, one further stderr line states whether the document on disk is what `sc` last generated or
has drifted from it; the judgement comes from the existing digest definition, never from a second one.

**FR-7** — `sc config` writes nothing: no file is created, modified, or removed anywhere, on any host
state, including a host where `/etc/sing-box` does not exist. It opens no socket, starts no
subprocess, does not contact the Clash API, does not touch the service, and forms no opinion about
whether the document is valid — validity is `sc doctor`'s answer and stays there. The mechanism keeps
`main()`'s positive naming of read-only commands: no per-subcommand read-only flag, and no structure
through which a future subcommand becomes read-only by default.

**FR-8** — Exit status is 0 when the document was printed in full, and non-zero when it was not.
Drift, a missing drift record and an unrecognised outbound shape are not failures and leave the
status 0.

**FR-9** — The command is documented where the existing commands are: `HELP_EN` and `HELP_ZH`,
`README.md` and `README.zh-CN.md`. The documentation states the mask's limit — that a secret placed
by the user's own `override.json` outside `outbounds` under a key outside the FR-4 set is printed
verbatim.

## Out of scope

1. Editing, writing or repairing the configuration from the CLI.
2. Rendering the document `sc` *would* generate, and any diff between it and the file on disk.
3. Any change to `generate_config()`'s composition semantics, to `_write_private()`, or to the drift record.
4. Any change to `install.sh`, to the install log, or to the `/etc/sudoers.d/sc` NOPASSWD rule.
5. Printing or masking `nodes.json`, `settings.json` or `override.json` — `sc config` shows one document.
6. Fixing R-29/R-25 (`load_settings()` / `_load_lang()` raising on a non-UTF-8 or non-object `settings.json`), although that code is on this command's start-up path.
7. Any validity verdict, `sing-box check` invocation, or change to `sc doctor`'s sections or wording (R-32, R-38 → T-20).
8. Paging, colour, syntax highlighting, key filtering, or a `--format` option.
9. R-19's five `ls.*` keys and any other pre-existing i18n defect not introduced here.

## Boundary conditions

**BC-1** — `/etc/sing-box/config.json` absent → one sentence naming the path on stderr, nothing on stdout, non-zero exit, no traceback.

**BC-2** — the file exists but cannot be read (EACCES, EIO) → a sentence that says *cannot read* and names the cause, distinct from BC-1's *absent*, non-zero exit.

**BC-3** — the file is not valid UTF-8 → a sentence naming the path, non-zero exit, no traceback; the decode failure is a `ValueError`, not an `OSError`, and must be caught as such.

**BC-4** — the file is empty, or is valid UTF-8 that is not valid JSON → a sentence naming the path, non-zero exit, and **the raw text is not printed**, because content that cannot be parsed cannot be masked.

**BC-5** — the document parses but is not a JSON object (`[]`, `42`, `null`) → treated as BC-4: a sentence, non-zero exit, nothing on stdout.

**BC-6** — `outbounds` is absent, or is present but not an array → the rest of the document renders under FR-4 alone, exit 0, no traceback.

**BC-7** — an element of `outbounds` is not an object → it renders verbatim, exit 0, no traceback.

**BC-8** — an outbound carries a key that `sc` never emits (any `override.json`-supplied outbound, any future sing-box field) → its value is masked by FR-3, not printed.

**BC-9** — an outbound contains an object whose keys are arbitrary (`transport.headers`) → FR-3 applies unchanged: `Host` renders, every other key in that object is masked.

**BC-10** — the document is large (a user override can inflate it) → it is printed whole; there is no size cap and no truncation, because a partial configuration is not inspectable.

**BC-11** — `sc reload` replaces `config.json` while `sc config` is reading it → the reader sees one whole document, old or new, never a mixture (the installer replaces by `rename(2)`).

**BC-12** — the drift record is absent → no provenance line is printed at all; absent means *unknown*, not drift.

**BC-13** — the drift record exists but is empty, unreadable, or not a digest → treated as BC-12.

**BC-14** — stdout is closed before the document is fully written (`sc config | head -5`) → the command terminates without a traceback and without a Python-level error message.

**BC-15** — stdout is not a TTY → the bytes on stdout are identical to the TTY case: no colour, no pager, no truncation, no re-ordering relative to the stderr commentary when the two streams are merged.

**BC-16** — a masked key holds a non-string value (`"password": 12345678`) → the value is replaced by the mask literal, not preserved and not omitted.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-B1 | `sc config` run against a fixture `config.json` that this same `sc` generated from one node of each supported share-link scheme prints, on stdout, a JSON document that parses and is equal to the file on disk at every position except the masked ones — i.e. a real configuration is rendered readably. | [B] | run the command in a fixture with all eight path constants repointed into a temp root and the import-time elevation neutralised; `json.loads` both sides and compare |
| AC-B2 | With a distinct, unique fixture value in every credential field of those nodes, no fixture credential value appears as a substring of stdout or stderr, in either language; a control read of the file on disk finds every one of them — i.e. the redaction actually hides real secrets. | [B] | byte-substring search over the captured streams, plus the on-disk control |
| AC-B3 | An outbound added through `override.json` carrying keys `sc` never emits (`private_key`, `pre_shared_key`, and one invented key name) has all three values masked. | [B] | run the command against a fixture whose override appends that outbound |
| AC-B4 | On a host where the configuration directory does not exist, `sc config` exits non-zero naming the absent path and leaves the filesystem unchanged: a recursive listing of the repointed roots plus `/var/lib` is byte-identical before and after. | [B] | run and diff the two listings |
| AC-B5 | `sc config > out.json` produces a file that a JSON parser accepts with no other text in it, while the path line and the masked-credentials line are present on stderr. | [B] | redirect the two streams separately and parse |
| AC-B6 | `sc config > f 2>&1` places the stderr commentary **before** the document in the merged capture. | [B] | one run, inspect the merged file |
| AC-B7 | The provenance line reads *is what sc last generated* when the drift record matches the file, reads *drifted* after one byte of the file is changed, and is absent when the record is absent. | [B] | three runs against three fixture states |
| AC-B8 | `sc config \| head -5` prints five lines and terminates with no traceback and no Python error text on either stream. | [B] | one run |
| AC-S1 | Every translation key introduced renders real text in both `en` and `zh`, no new `zh` string contains `失败：`, `sc help` lists the command in both languages, and both READMEs document it including the FR-9 limit. | [S] | `verify_all` B.2 plus a read of the four documents |
| AC-S2 | `.harness/scripts/verify_all` reports PASS with no new FAIL or WARN, A.1 included. | [S] | run the gate |
| AC-B9 | **Requires root on the live host — expected BLOCKED.** The shipped invocation `sc config` run as the installed binary on the owner's machine prints the live configuration with every credential masked, and the live service is untouched. No agent in this pipeline holds an interactive sudo credential (R-31); QA reports this BLOCKED and files a row rather than substituting an artifact check (R-41). | [B] | owner runs it; recipe recorded at delivery |

## Non-functional requirements

1. The command performs zero network I/O and starts zero subprocesses, so it stays usable on exactly the broken host it is run to inspect.
2. No new file is added to the project: `bin/sc` must remain one self-contained file, as `install.sh`'s enumerated artifact list requires.
3. No committed non-`.md` file may contain a literal matching `verify_all` A.1's pattern — a key named `password` / `secret` / `token` / `api_key` followed by `:` or `=` and a quoted literal of 8 or more characters. This binds the mask literal (which appears in `bin/sc` next to those key names) and any committed example.
4. Fixtures and stage documents carry synthesized credential values only; no credential byte from the live host reaches any document, log or test artifact.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does `sc config --show` match the CLI's established shape? | No, and it is not implemented. `bin/sc` has no `parse_args()` function and no `--<verb>` flag on any subcommand; `show` is a **positional value** in three commands (`sc ipv6 show`, `sc telemetry show`, `sc update-interval show`) and read-only commands are bare (`ls`, `now`, `status`, `doctor`). The command is **`sc config`**, bare, with no flag and no value. |
| Q-2 | Is redaction optional with unredacted output as the default, as the goal sentence says? | No. Redaction is unconditional and there is no opt-out. `install.sh` installs `/etc/sudoers.d/sc` granting the install user `NOPASSWD: /usr/local/bin/sc`, and `bin/sc` re-execs itself through `sudo` at import — so an unredacted `sc config` would convert a password-gated read of a `0600` credential document into a password-free one for any process running as that user. An opt-out flag carries the identical property and is therefore the footgun, not the convenience. |
| Q-3 | Does "show the config" mean the file on disk, the composition that would be generated, or the drift between them? | The **file on disk**, and the output says so by naming its absolute path. The would-be composition is not computed: producing it requires `generate_config()`, which writes the file and runs the checker, and splitting it would create a second definition of what `sc` emits. The drift *state* — which already has one definition — is reported as one line (FR-6); no diff is produced. |
| Q-4 | Are node server addresses, ports, tags and SNI masked? | No. `sc ls` already prints node addresses at the same privilege in the same terminal, so masking them here would buy nothing and would make the routing, DNS and TLS content unreadable — which is the whole purpose of the command. |
| Q-5 | Deny-list of credential key names, or fail-closed allow-list? | Both, in the two regions where each is provable: fail-closed allow-list inside `outbounds` (FR-3), where credentials live by construction and where an override or a future sing-box version can introduce key names nobody enumerated; name-based masking document-wide (FR-4) for the realistic cases outside it (`experimental.clash_api.secret`, an override-added inbound user's `password`). |
| Q-6 | Where does the document go, given the command may be piped or pasted? | The document alone on stdout; every word `sc` writes itself on stderr. This makes `sc config > file` a valid JSON document and keeps the human-facing facts visible when it is not redirected. |
| Q-7 | Does `sc config` say whether the configuration is valid? | No. `sc doctor` owns that judgement and invokes `sing-box check` itself; a second verdict here would be a second opinion of the same fact. |
| Q-8 | May `sc config` take the ordinary start-up path? | No. It writes nothing (FR-7), so it must not reach `_init_files()` (which creates `/etc/sing-box`, `/etc/sing-box/rules` and a hard-coded `/var/lib/sing-box`, and seeds two files) or `_resolve_clash_port()` (which persists a port on first run). The mechanism must keep `main()`'s positive naming, so a future subcommand still inherits the initialising arm by default — `docs/dev-map.md`'s standing constraint stands. |
| Q-9 | What is the mask literal? | One fixed, non-empty literal, identical everywhere, containing no character that JSON must escape, carrying no information about the value it replaced, not translated (it lives inside a JSON document, not in UI text), and short enough that `"password": "<mask>"` cannot match `verify_all` A.1's eight-character threshold. The exact characters are the architect's choice within those constraints. |
| Q-10 | Can this task's behavioural goal be observed without root? | Yes for AC-B1 … AC-B8, using a fixture whose eight path constants are repointed into a temp root owned by the running user. Only AC-B9 — the shipped invocation against the live `0600` document — needs root; it is marked as such up front and its expected outcome is BLOCKED with a filed row. |
| Q-11 | Does `sc config` also show `nodes.json`, the project's other credential document? | No. One command, one document. A second document would double the disclosure surface for a use case nobody has stated. |
| Q-12 | `.harness/rules/70-doc-size.md` defines no `## Stage-doc boundary rule` on this project (R-37). | The contract schema is applied as written and the task proceeds. Every unit produced at this stage fit a declared section; the clause-by-clause refutation of the goal sentence, the credential enumeration evidence and the candidate answers are evidence narrative and live in `01_RATIONALE.md`. |

## Verdict

READY
