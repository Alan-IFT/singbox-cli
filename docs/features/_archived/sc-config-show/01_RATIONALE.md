# T-06 — sc-config-show · Rationale

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. The goal sentence, clause by clause, against `bin/sc` at HEAD

The row was written 2026-07-31, before T-13 … T-19 shipped. Re-derived first-hand from
`/home/alan/Programs/singbox-cli/bin/sc` (3214 lines) and `/home/alan/Programs/singbox-cli/install.sh`.

### Clause 1 — "`sc config --show`"

**Half phantom.** The need is real; the spelling is not, and neither is the mechanism the dispatch
prompt assumed.

- There is **no `config` subcommand**. `bin/sc:3183-3192`'s `handlers` dict enumerates twenty
  commands and `config` is not among them; no command prints `config.json` in any form.
- There is **no `parse_args()` function** in `bin/sc`. Argument parsing is inline in `main()`,
  `bin/sc:3146-3167`. T-05's constraint is real but attaches to a different anchor than the prompt
  states: the initialisation block sits at `bin/sc:3168-3182`, *after* `args = parser.parse_args()`
  at `:3167`, which is what lets `doctor` take a read-only arm.
- **`--show` matches nothing this CLI does.** Exactly two flags exist across twenty commands:
  `--mirror` on `update-rules` (`:3160`) and `-f/--follow` on `log` (`:3162`). `show` is a
  **positional value**, three times: `sc ipv6 show` (`:2649`), `sc telemetry show` (`:2711`),
  `sc update-interval <freq|show>` (`HELP_EN`, `:3051`). Bare read-only commands are the other
  established form: `ls`, `now`, `status`, `doctor`, `reload`.
- `.harness/rejected-decisions.md § telemetry-toggle-as-on-off` shows the project already
  adjudicates subcommand vocabulary deliberately rather than by habit.

Candidates weighed for the spelling: **`sc config`** (bare) · `sc config show` · `sc show-config` ·
`sc config --show`. `sc config --show` loses on consistency; `sc show-config` invents a verb-noun
form no other command uses; `sc config show` costs a positional, a validation branch and two
translated error strings to express a choice with exactly one member, and the moment a second member
is added (`raw`) it re-opens Q-2. **Bare wins on rule 85's tie-break with the smaller surface**, and
`sc status` / `sc doctor` are its precedent.

### Clause 2 — "an optional `--redact` that masks node credentials"

**Refuted as to the default and the option; the mask itself is the real work.** See §2.

The dispatch prompt's own hint list is also partly phantom: it names "private key" and "pre-shared
key" as things to enumerate. `bin/sc` contains **no** `private_key` and **no** `pre_shared_key`
anywhere — grep returns only `tls.reality.public_key` (`:563`), `tls.reality.short_id` (`:566`) and
`obfs.password` (`:697`). Those two key names can only enter the document through the user's own
`override.json`, which is precisely why FR-3 is fail-closed rather than a list.

### Clause 3 — "so `/etc/sing-box/config.json` can be inspected without root `grep`"

**The pain is real; the stated premise is backwards.**

- The premise is incoherent as written: the file is `0600` (T-13, `CRED_MODE` at `bin/sc:41`), so
  reading it *always* needs root. `sc` does not remove that requirement — it satisfies it. `bin/sc:117-118`
  re-execs `sudo /usr/local/bin/sc` at **import**, before any parsing.
- What the user actually gains is not "no root". It is: not having to know the path, not having to
  compose a `sudo cat`, getting a document that is safe to paste into a bug report, and getting one
  line saying whether what is on disk is still what `sc` generated. Nothing in the repo documents
  reading the file today — `grep -r 'cat /etc/sing-box'` over the whole tree returns nothing, in
  either README.

## 2. The security ruling (Q-2), and the measurement that settled it

The decisive fact was found in `install.sh`, not in `bin/sc`:

```
# ----------------- step 5: sudoers -----------------
cat > /etc/sudoers.d/sc <<EOF
$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/sc
EOF
```
(`install.sh:546-552`, step banner at `:213`.)

So on every installed host, the install user runs `sc <anything>` as root **without a password**,
and `bin/sc:117-118` makes that automatic. The same user reading the file by hand hits an ordinary
`sudo` password prompt, because the NOPASSWD grant is scoped to `/usr/local/bin/sc` alone.

That converts the question from taste into arithmetic. An unredacted `sc config` — or an opt-out flag
that reaches the same output — would be a **password-free read of a `0600` credential document,
through a sudoers rule this project installs itself**. It is a genuine change of privilege boundary,
not merely a scrollback risk, and it would be a regression against the file T-13 hardened
(`docs/features/_archived/config-write-permission-hardening/`) and against T-14's decision that the
drift record is *a digest, never a copy* (`bin/sc:32-37`, `CONTEXT.md § drift record`).

Candidates weighed:

| candidate | verdict |
|---|---|
| unredacted default + `--redact` (the goal sentence) | rejected — makes the dangerous output the one a user gets by accident, and every unflagged pipe, screen share and pasted bug report carries credentials |
| redacted default + `--raw` / `show-secrets` opt-out | rejected — the opt-out is password-free through the same sudoers rule, so it re-introduces the whole exposure while weakening the promise from "no invocation prints a credential" to "no invocation without flag X" |
| **redacted always, no opt-out** | **adopted** — one absolute, provable property; the raw bytes remain reachable by reading the file, which the header line names |

What the absolute buys, concretely: "`sc config` never prints a credential" is a single sentence a
bug-report template, a README and an AC can each rest on, and it cannot be falsified by a future
caller, a script, or an install-log capture (`install.sh:554-557` already notes that captured
`sing-box check` output can quote config fragments into a `0640` log).

What it costs: a user who wants to confirm a password parsed correctly must read the file. Accepted —
`sc ls` already answers the common form of that question for addresses, and the header names the path.

## 3. Credential shapes, enumerated from the parsers (FR-3/FR-4 evidence)

Everything `sc` itself can place inside a node outbound, read from `bin/sc:519-729`:

| key | where | source |
|---|---|---|
| `uuid` | vless `:578`, vmess `:601`, tuic `:715` | share-link userinfo |
| `password` | trojan `:637`, shadowsocks `:673`, hysteria2 `:685`, tuic `:716` | share-link userinfo |
| `obfs.password` | hysteria2 `:697` | `obfs-password` query parameter |
| `tls.reality.public_key` | `:563` | `pbk` — the server's key; opaque either way, so masking costs no readability |
| `tls.reality.short_id` | `:566` | `sid` |

Non-secret keys that the visible set must keep, or the output stops being worth printing:
`type`, `tag`, `server`, `server_port`, `method` (`:672`), `security` (`:603` — a vmess cipher name,
*not* a secret, and a naive name-based rule must not eat it), `alter_id`, `flow`, `packet_encoding`,
`congestion_control`, `udp_relay_mode`, and the `transport` / `tls` / `obfs` sub-objects
(`server_name`, `alpn`, `insecure`, `utls.fingerprint`, `path`, `host`, `headers.Host`,
`service_name`, `obfs.type`). The selector and `urltest` group keys emitted by `_runtime_overlay()`
(`bin/sc:1788-1804`) complete the list: `outbounds`, `default`, `url`, `interval`, `tolerance`,
`idle_timeout`, `interrupt_exist_connections`.

Outside `outbounds`, nothing `sc` writes is secret: `CONFIG_BASE` (`:1164-1231`) is DNS servers,
routing rules and a TUN inbound, and `experimental.clash_api.external_controller` is
`127.0.0.1:<port>` (`:1818`). The residual risk outside `outbounds` is entirely
user-`override.json`-supplied, which is why FR-4 is a short honest floor and FR-9 makes the limit
public rather than pretending it away.

**Why fail-closed inside `outbounds` beats a five-name deny-list even though it is more data.**
Rule 85's tie-break applies between designs achieving *the same* purpose; these do not. A deny-list is
provably wrong the first time a user appends a `wireguard` (`private_key`, `pre_shared_key`), `ssh`
(`private_key`) or `shadowtls` (`password`) outbound through the override path the README teaches, or
the first time sing-box adds a field — and it fails **open**, i.e. it leaks. The allow-list fails
closed: the worst outcome of forgetting a name is an over-masked, less readable document. The cost is
data (one name list), not machinery, which is the direction rule 85 explicitly prefers.

## 4. Which artifact (Q-3), and why no diff

`generate_config()` (`bin/sc:1900-1989`) has no shape that yields a document without installing it:
it composes, `_write_private()`s to `CFG_PATH`, `_record_generated()`s, then runs `sing-box check`.
Rendering "what would be generated" therefore needs either those side effects (forbidden by FR-7) or
a split of compose-from-install — a refactor of the layer T-14 just built, creating a second
definition of what `sc` emits, for a feature nobody asked for.

The honest and nearly free answer already exists: `_config_digest()` (`:1826-1848`) and the drift
record (`STATE_PATH`, `:37`) are the project's single definition of *is this the document sc
installed*. `sc config` reports that state as one line. It is the same judgement from the same
function, so it is a reuse of the seam, not a second opinion — but `_warn_drift()`'s own **string**
cannot be reused: it says the changes "are about to be replaced" (`:1894-1897`), which is false for a
read-only command. Its "no record ⇒ say nothing" precedent (`:1885-1890`, and `CONTEXT.md § drift
record`: *absent means unknown, not drift*) is reused verbatim as BC-12.

## 5. stdout / stderr, ordering, and the pipe (Q-6, BC-14 … BC-16)

Splitting the streams is what makes `sc config > cfg.json` and `sc config | <filter>` work while a
human still sees the path and the masking notice. Precedent in-tree: `_warn_degraded()` and
`_warn_drift()` write commentary to stderr while the product goes elsewhere.

Two measured traps from `.harness/insight-index.md` bear directly on this command:

- L28 (2026-08-14) — `cmd_status`'s `print()` is block-buffered when stdout is a pipe, so
  `sc status > file` reorders sections. Here it would put the whole document *above* its own header
  in a merged `2>&1` capture, which is exactly the bug-report case → AC-B6.
- L29 (2026-08-14) — `sys.exit(<str>)` flushes stdout before writing to stderr while an in-run
  `sys.stderr.write` does not, so the two error paths order differently. BC-1 … BC-5 print nothing on
  stdout, which sidesteps it; the header path does not, hence the explicit ordering criterion.

`sc config | head -5` (BC-14) is a likely first use and a `BrokenPipeError` traceback there would be
the command's most visible defect.

## 6. Read-only, and the constraint that shapes the mechanism (Q-8)

`_init_files()` (`bin/sc:470-482`) creates `/etc/sing-box`, `/etc/sing-box/rules` and — as a
hard-coded `Path` literal that no test harness can repoint (insight L10, `docs/dev-map.md`) —
`/var/lib/sing-box`, then seeds `nodes.json` and `settings.json`; `_resolve_clash_port()` persists a
port on first run. Both run for every non-`doctor` command.

T-05's comment at `bin/sc:3168-3177` states why `doctor` opts out and calls the mechanism "a positive
opt-out naming ONE command", and `docs/dev-map.md:153-155` forbids a `READ_ONLY_COMMANDS` set or a
per-subcommand flag, because those invert the failure direction for future commands. FR-7 therefore
binds the *property* (nothing is written; the positive-naming direction survives) and leaves the form
to stage 2. Naming a second command in the same positive test preserves the property; a general
opt-in flag does not.

## 7. Related historical work

Linked, not re-described — see `docs/tasks.md` and each task's own stage documents.

- **T-05 `sc-doctor`** — `docs/features/_archived/sc-doctor/`. Owns config location + `sing-box check`
  + the read-only arm and the "no second opinion" constraint (Q-7, Q-8).
- **T-13 `config-write-permission-hardening`** — `docs/features/_archived/config-write-permission-hardening/`.
  Establishes `config.json` as a credential document at `0600` at every instant (Q-2, BC-11).
- **T-14 `config-composition-layer`** — `docs/features/_archived/config-composition-layer/`. The
  composition layer, the user override, and the digest-never-a-copy drift record (Q-3, FR-6, BC-8).
- **T-15 `proxy-urltest-group`** — R-22, the reason AC-B1/AC-B2 observe behaviour rather than artifacts.
- **T-17 `telemetry-reject-list`** — precedent for `show` as a positional value and for a curated
  in-`bin/sc` name list as *data*, not machinery.
- **T-18 `status-egress-via-clash-api`** — R-31, the sudo-credential constraint behind AC-B9.
- **T-19 `ruleset-staleness-visibility`** — R-41's discipline (report BLOCKED, never substitute) and
  R-37 (rule 70 has no `## Stage-doc boundary rule`; confirmed absent again here).

Board rows this task must not absorb: **R-32 / R-38** (doctor wording → T-20), **R-19** (`ls.*` keys),
**R-29 / R-25** (`load_settings()` / `_load_lang()` traceback classes — on this command's start-up
path, but a family fix belongs to the settings I/O seam), **R-10 / R-11** (permission sweep → T-20).

## 8. Verification notes for stages 3-6

- A fixture must repoint all eight path constants **and** neutralise the import-time elevation at
  `bin/sc:117-118`; `docs/dev-map.md` carries the recipe and the `sys.modules` shim, and T-19's
  `06_TEST_REPORT.md` §12 carries a runnable 106-assertion harness to build from (R-9).
- Insight L13: `main()` reassigns `LANG` after import, so a harness that sets only `sc.LANG` renders
  English and every Chinese assertion passes vacuously. AC-S1's zh half must drive the real path.
- Insight L30: a fully repointed fixture is still not isolated from the live service. `sc config`
  opens no socket at all (FR-7), which removes that class here — but any control run of another
  command in the same harness reintroduces it.
- `verify_all` A.1 greps **tracked, non-`.md`** files for `(api[_-]?key|secret|password|token)\s*[:=]\s*"…{8,}"`
  (`.harness/scripts/verify_all.sh:33-34`). Stage documents are exempt by the `:!*.md` pathspec;
  a committed fixture or a docstring example inside `bin/sc` is not. NFR-3 exists for that.
- Two glossary terms already cover this task's vocabulary and were reused rather than coined:
  **credential document** and **drift** / **drift record** (`CONTEXT.md`). If stage 2 needs a name for
  the FR-3 mechanism, *visible key set* and *mask* are the terms used here.
