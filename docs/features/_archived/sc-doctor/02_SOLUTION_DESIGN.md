# 02 — Solution Design — `sc doctor` (T-05)

Mode: **full** · Stage 2 · Decision mode: **deferred-human (defer, do not ask)**.
Upstream: `docs/features/sc-doctor/01_REQUIREMENT_ANALYSIS.md`, verdict **READY** — binding and
unedited. Every design judgment this task needed is decided here in §3, each with its rejected
alternative. No question is routed to the owner; no safety red line was reached.

All file paths are absolute-from-repo-root and all `file:line` anchors are against `HEAD` =
`22502f9` (`bin/sc`, 1537 lines). Line numbers shift as the diff lands — every anchor is therefore
also named by its function.

---

## 1. Architecture summary

`sc doctor` is added as one more `cmd_*` handler inside `/home/alan/Programs/singbox-cli/bin/sc`
— no new file, no new module, no new flag, no new dependency. It is a **driver plus seven pure
probes**: the driver owns rendering, per-section failure isolation, streaming and the exit status;
each probe owns exactly one section's facts and returns rows as data. Every fact it prints is
obtained by calling the function that already owns that judgment (`ruleset_states()`,
`_status_text()`, `is_running()`, `clash_api()`, `SB_BIN`, `CFG_PATH`, `SYSTEMD`/`OPENRC`), so
`doctor` forms no second opinion (FR-17).

Four existing things change to make that possible, and nothing else:

1. `ruleset_state()` returns the byte count it already computes and today discards, so S2's size
   comes from the same single read that decided the status (FR-12) — §3.2.
2. `main()` gains one branch so that `doctor` never reaches `_init_files()` /
   `_resolve_clash_port()`, the two writers on the shared start-up path (FR-4) — §3.3.
3. `_resolve_clash_port()` is split so that "the persisted Clash API port" is one named,
   read-only definition both it and `doctor` consume (FR-15/FR-18) — §3.4.
4. The TUN interface name and the egress-IP query each become one definition, consumed by
   `generate_config()`, `cmd_status()` and `doctor` (FR-18), with `sc status`'s bytes unchanged
   (FR-19) — §3.5.

Everything else is additive.

---

## 2. Affected files

| File | Change | Why |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | the whole behaviour change (see §4 for the edit list) | single-file CLI |
| `/home/alan/Programs/singbox-cli/README.md` | `sc doctor` in the Service-control block + a new `### Diagnose the install` subsection incl. the exit-status table | FR-2/FR-28 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | the line-for-line mirror of the above | FR-2/AC-2 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one entry under `[Unreleased] → 新增` | FR-30 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | reusable-utility inventory rows (see §13) | FR-31 |

Untouched, and asserted byte-identical by AC-26: `install.sh`, `uninstall.sh`, `systemd/`.

Pipeline artefacts written outside the shipping diff (not product files, not covered by AC-26):
this document, and two records appended to
`/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` (§3.1 and §12.2).
`/home/alan/Programs/singbox-cli/CONTEXT.md` is deliberately **not** edited: stage 1 §7 already
ruled that "probe", "section" and "outcome class" describe this command's output shape, not the
domain, and this design coins no domain term.

---

## 3. Design decisions (each with rationale and rejected alternative)

### 3.1 D-1 — Exit-status policy (FR-25..FR-29, stage 1 R-7)

**Decision: three values, derived from the worst outcome class printed.**

| Exit | Meaning | Produced when |
|---|---|---|
| `0` | every printed row is OK | all seven sections healthy |
| `1` | at least one **PROBLEM** row | any of S1..S7 (a PROBLEM row anywhere wins) |
| `2` | no PROBLEM row, but at least one **UNKNOWN** row | S1 (binary present but unrunnable), S3 (no checker, or config unreadable), S4 (no init system — BC-8), S5 (`ip` missing — BC-9), S6 (no persisted port — BC-11/FR-15), and, in principle, any section whose probe raises unexpectedly (§7) |

Rule: `status = 1 if any PROBLEM else 2 if any UNKNOWN else 0`. It is a pure function of the set of
printed row classes, so it is independent of language, of TTY-ness, of init system and of the order
in which probes failed (FR-25). It is computed by a running `max()` over an ordered class constant
(§5.3), never by re-reading the report.

**Rationale.** (a) A pure `always 0` makes the command useless in the one automated context that
matters — a health check, a pre-flight step in a script, an issue-triage one-liner — and the project
already has the precedent that a command's status reports its findings: `sc update-rules` exits
non-zero when rule-sets failed (`bin/sc:1255-1256`) and T-01 made `install.sh` derive its status
from recorded phase state. (b) A two-value 0/non-zero policy would have to fold UNKNOWN into one of
the two, and both foldings lie: folding UNKNOWN into 0 says "healthy" about a host where the init
system could not be detected at all (BC-8) or no Clash port is recorded (BC-11); folding it into 1
says "broken" about the same host, on evidence that does not exist. FR-8 already forces the report
to distinguish three classes; the status simply does not throw that distinction away. Three values
is the ceiling FR-28 allows and it is used to say exactly three things.

**Rejected alternative 1 — always 0** (stage 1 R-7 candidate (a)): rejected because the surprise it
avoids is small and bounded (a `set -e` script running `sc doctor`, which is a deliberate act) while
the capability it destroys is the whole automated use of the command. Recorded in
`.harness/rejected-decisions.md` as `doctor-exit-status-always-zero`.
**Rejected alternative 2 — 0 / non-zero only** (candidate (b)): rejected for the folding lie above.
**Rejected alternative 3 — a bitmask or per-section codes**: rejected as speculative generality
(rule 85 counter-rule) and as exceeding FR-28's three-value ceiling.

**Known, documented overlap:** a *usage* error (`sc doctor extra-arg`) is argparse's error, and
argparse exits `2` as well. The two are never ambiguous in practice, because a usage error prints an
argparse message and **no report**, whereas every status `doctor` itself produces is preceded by a
complete seven-section report (FR-26). Choosing PROBLEM=2/UNKNOWN=1 would merely move the overlap
onto the more common value, so the collision is accepted rather than shuffled.

### 3.2 D-2 — How FR-12's byte size reaches S2

**Decision: widen the single reader's return, and let the existing projection absorb it.**

- `ruleset_state(path)` (`bin/sc:516-558`) returns `(status, digest, size)`. `size` is the count it
  already accumulates at `bin/sc:552` and discards at `:558`. Its three early returns
  (`bin/sc:543` twice, `:545`, `:557`) return `(…, None, None)`.
- The digest contract (`bin/sc:523-533`) is extended by exactly one clause and otherwise reproduced
  verbatim: **`size is None ⇔ digest is None ⇔ no complete read happened ⇔ status ∈ {absent,
  unreadable}`**. A readable empty file therefore yields `("too-small", sha256(b"")…, 0)` — a real
  `0`, not "unavailable" — because zero bytes *were* read successfully. This is exactly FR-12's
  "size is reported exactly when the reader's digest contract yields a digest".
- `ruleset_status(path)` (`bin/sc:561-572`) is untouched: it already projects with `[0]`.
- `ruleset_states()` (`bin/sc:575-588`) destructures three values at `:586` and appends 5-tuples
  `(tag, filename, status, digest, size)` at `:587`.
- `_status_view()` (`bin/sc:591-596`) — whose stated job is "generate_config() and usable_tags()
  destructure 3-tuples; this keeps both untouched" — absorbs the widening in its comprehension. Its
  **output shape is unchanged**.
- `changed_usable_tags()` (`bin/sc:608-636`) changes only the width of its two unpackings
  (`:623`, `:625`). Not one line of its logic, its dict pairing or its `None` reasoning moves.

**Consequence, deliberately: `ruleset_report()`, `usable_tags()`, `_warn_degraded()`,
`generate_config()` and `cmd_update_rules()` need no edit at all.** The restart decision T-10 owns
(`changed_usable_tags(before, after)` at `bin/sc:1224`, consumed at `:1230`) is computed from the
same digests, by the same code, in the same order; the only difference is that two tuple unpackings
name one more element. That is the smallest change that can carry a size out of the single read.

**Rejected alternative 1 — widen `ruleset_report()` to 4-tuples instead.** Rejected because
`_status_view()` exists precisely to shield `generate_config()` (`bin/sc:899`), `usable_tags()`
(`bin/sc:641`) and `_warn_degraded()` (`bin/sc:688`) from tuple-shape churn; widening the report
would delete that shield's reason to exist and put the edit inside the config-generation path, where
a mistake breaks every user's `sc add`/`sc reload` rather than one diagnostic row.
**Rejected alternative 2 — a size-carrying "view" or a second per-file function.** Rejected: any
function that returns a size without returning the status either re-reads the file (a third `.srs`
reading path, forbidden) or is a second entry point into the same read for no gain.
**Rejected alternative 3 — `path.stat().st_size` in `doctor`.** Rejected by FR-12/AC-14 and by
stage 1 R-6: it is a second notion of the file's facts and can disagree with the size the usability
judgment used.

**S2 consumes `ruleset_states()`** — one call, one read per file, four rows. Note for the gate:
AC-13's deletion test is phrased as "removing the existing rule-set **report** function breaks
`doctor`'s S2". `ruleset_report()` cannot carry a size, and calling both it and `ruleset_states()`
would mean two reads per file and a report that can contradict itself (FR-12 forbids it). The test
is satisfied in the stronger form: `ruleset_report()` is *defined* as `_status_view(ruleset_states())`
(`bin/sc:605`), so `doctor` and config generation stand on the same call; deleting `ruleset_states()`
or `ruleset_state()` breaks both at once, and there is no path by which `doctor` keeps working
independently. This is a reading of AC-13, not a change to it.

### 3.3 D-3 — How FR-4 (process-wide read-only) is achieved, and what protects every other command

Today `main()` (`bin/sc:1499-1503`) runs, before dispatch:

```
_init_files()              # bin/sc:222-231 — mkdir /etc/sing-box, /etc/sing-box/rules,
                           #   /var/lib/sing-box; writes nodes.json (0600) and settings.json
LANG = _load_lang()        # bin/sc:172-176 — read-only, tolerates a missing file
CLASH_PORT = _resolve_clash_port()   # bin/sc:191-212 — calls save_settings() on first run
```

**Decision: move `parser.parse_args()` above the initialisation block and branch on the dispatched
command name, with the non-`doctor` arm holding the three statements verbatim.**

```
args = parser.parse_args()            # was bin/sc:1522
if args.cmd == "doctor":
    LANG = _load_lang()               # the only start-up step doctor needs; reads, never writes
else:
    _init_files()                     # unchanged
    LANG = _load_lang()               # unchanged
    CLASH_PORT = _resolve_clash_port()# unchanged
```

**What protects `add` / `use` / `on` / `off` / `status` / `update-rules` / everything else
(stage 1 RISK-2) — four independent mechanisms, in order of strength:**

1. **The default is the old behaviour.** The branch is a *positive opt-out naming one command*.
   Every command that exists today and every command added later falls into the `else` arm without
   anyone doing anything. The failure mode of forgetting the mechanism is "a new read-only command
   wrote files" — never "an existing command lost its initialisation". A flag that each subcommand
   must set has exactly the opposite failure direction, which is why it is rejected below.
2. **The `else` arm is textually the current code.** The three statements keep their identity and
   their order; the diff on them is one indent level. A reviewer diffs three lines, not a refactor.
3. **Single call sites, greppable.** After the change,
   `grep -n '_init_files()\|_resolve_clash_port()' bin/sc` yields each name exactly twice: its
   definition and its one call inside the `else` arm. `_free_port()` (`bin/sc:179-188`) keeps its
   single caller `_resolve_clash_port()`, so it is structurally unreachable from `doctor` (D-4).
4. **An executed regression check, not an inspection.** Stage 6 runs, on a fixture with
   `/etc/sing-box` deleted: `sc lang zh`, `sc add <link>`, `sc mode global`, `sc status`, and
   asserts that `/etc/sing-box/{nodes.json,settings.json}` exist with mode 0600 on `nodes.json` and
   that `settings.json` carries `clash_api_port` — i.e. the start-up path still initialises (§14,
   T-6).

**Accepted, stated consequence.** Argument parsing now happens before the directories are created,
so `sc <unknown-command>` exits 2 from argparse *without* creating `/etc/sing-box`. Nothing
documented or scripted depends on a usage error creating directories; the new behaviour is
strictly more conservative. `sc` with no arguments and `sc help` are unaffected (`args.cmd is None`
takes the `else` arm, exactly as today).

**LANG for `doctor`:** `_load_lang()` reads `settings.json` and returns `"en"` on
`FileNotFoundError`/`JSONDecodeError`/`OSError` (`bin/sc:172-176`) — it is already the read-only,
missing-file-tolerant path, so `doctor` on a host with no install renders in English and writes
nothing. `CLASH_PORT` is left at its module default (`bin/sc:169`) during a `doctor` run and is
**never read by `doctor`** (D-4), so the stale default cannot be printed.

**Rejected alternative 1 — a `READ_ONLY = True` attribute/flag per subcommand, or a
`READ_ONLY_COMMANDS` frozenset.** Rejected: a set with one member is a hypothetical seam (rule 85
counter-rule — one adapter is not a seam), and a per-command flag inverts the failure direction as
described in (1).
**Rejected alternative 2 — make `_init_files()` and `_resolve_clash_port()` themselves no-ops under
a global "read-only" mode.** Rejected: it hides a mode switch inside two functions whose names
promise to initialise, and it makes the guarantee depend on a global that any code path can flip.
**Rejected alternative 3 — leave start-up as-is and scope FR-4 to `doctor`'s own code.** Not
available: stage 1 R-1 already decided this (`doctor` would create the very directory whose
emptiness is the diagnosis) and AC-5's second half tests it.

### 3.4 D-4 — S6's Clash-API port source (FR-15/FR-18)

**Decision: split `_resolve_clash_port()` into a read-only source and the probing resolver, and
give `clash_api()` an optional explicit port.**

```
def _saved_clash_port():
    """The Clash API port recorded in settings.json, or None. Reads; never probes, never writes.
    THE single reader of settings["clash_api_port"]."""
    -> load_settings() in the same try/except tuple as bin/sc:199-202
    -> return port if isinstance(port, int) and 1 <= port <= 65535 else None

def _resolve_clash_port():           # unchanged contract, unchanged behaviour
    port = _saved_clash_port()
    if port is not None: return port
    ... existing _free_port() + save_settings() first-run branch (bin/sc:206-212) ...
```

- `doctor` calls `_saved_clash_port()` only. `_resolve_clash_port()` and `_free_port()` are
  unreachable from `doctor`'s call graph (AC-7), so the tautological probe stage 1 R-2 names — a
  port that is free *by construction*, then persisted — cannot happen.
- When it returns `None`: S6 prints the port as not-configured (PROBLEM-free UNKNOWN) and the
  reachability row as UNKNOWN "not probed", and **`clash_api()` is not called at all** (FR-15).
- `clash_api(method, path, data=None, port=None)` (`bin/sc:945-956`) resolves
  `port or CLASH_PORT` when building the URL at `:946`. The three existing call sites
  (`bin/sc:1028`, `:1104`, `:1125`) are byte-identical and keep using the global; `doctor` passes
  the persisted port explicitly. The 3 s timeout at `:952` is untouched.
- AC-15 ("the Clash-API-port source occurs exactly once"): after the change the settings key
  `"clash_api_port"` is read in exactly one place (`_saved_clash_port()`) and written in exactly one
  place (`_resolve_clash_port()`'s first-run branch).

**The future edit this prevents (rule 85 requirement):** moving or renaming where the port is
persisted — e.g. a `clash_api` sub-object in `settings.json`, or honouring an override. Today that
edit has one site; with `doctor` reading the key itself it would have two, and the failure mode of
missing one is `sc doctor` reporting a port the service is not listening on, i.e. a diagnostic that
lies about the thing it exists to diagnose.

**Rejected alternative 1 — `doctor` assigns the global `CLASH_PORT` before calling `clash_api()`.**
Rejected: it breaks the documented invariant that `CLASH_PORT` is assigned once, in `main()`, before
dispatch (`bin/sc:169`, and `docs/dev-map.md` "main() … Assigns LANG and CLASH_PORT after import"),
in exchange for one keyword argument.
**Rejected alternative 2 — read the port from `config.json`'s
`experimental.clash_api.external_controller` (`bin/sc:906`).** Already rejected by stage 1 R-2:
`config.json` is exactly the artefact `doctor` cannot assume is present or parseable, which is why
S3 precedes S6. Flagging a *mismatch* between the persisted port and a parseable config's port is
out of scope by the same ruling.

### 3.5 D-5 — Single definitions for the TUN interface name and the egress-IP query (FR-18/FR-19)

**Decision: one module constant for the name, one function for the query; substitute the literal at
each existing call site and change nothing else about those callers.**

- `TUN_IFACE = "sb-tun"` in the `# Paths` section (next to `SERVICE`, `bin/sc:24`). Consumers:
  `generate_config()`'s `"interface_name"` (`bin/sc:873`), `cmd_status()`'s `ip -br addr show`
  (`bin/sc:1099`), `doctor`'s S5.
- `_egress_ip()` — the one egress query; the endpoint literal and the 8 s timeout live inside it and
  nowhere else:
  ```
  def _egress_ip():
      """The public egress address as text, from THE one endpoint sc queries. Raises on failure;
      the 8 s socket timeout is unchanged and is not a new constant."""
      with urllib.request.urlopen("https://api.ipify.org", timeout=8) as resp:
          return resp.read().decode()
  ```
  `cmd_status()`'s block (`bin/sc:1109-1114`) becomes `print(_egress_ip())` inside its existing
  `try` with its existing `except Exception as e: print(t("(error: {e})", e=e))`. `doctor`'s S7
  calls the same function.

**Why `sc status` stays byte-identical (FR-19/AC-16).** The rule the developer must follow is
literally *substitute the literal, do not restructure the caller*: the constant's value equals the
literal it replaces, `_egress_ip()`'s body is the two statements lifted verbatim out of
`cmd_status()`, and every `print()`, header, blank line, ordering and `is_running()` gate in
`cmd_status()` (`bin/sc:1092-1114`) is left exactly as it is — including the gate stage 1 R-5
declines to copy into `doctor`. The same exceptions arise from the same calls, so the
`(error: {e})` rendering is unchanged too. `generate_config()`'s output JSON is likewise unchanged
byte-for-byte, since `TUN_IFACE` is the same string.

**The future edit this prevents (rule 85 requirement):**
- `TUN_IFACE`: renaming the TUN device (a host where `sb-tun` collides, or a config change). Today
  that is two edits; with `doctor` it becomes three, and missing the probe site leaves `sc status`
  and `sc doctor` inspecting a device the generated config no longer creates — a false PROBLEM on a
  healthy host.
- `_egress_ip()`: replacing or adding an egress endpoint when `api.ipify.org` becomes unreachable in
  a region (this project's standing answer to reachability is "another source, not a longer wait").
  Two copies would let `sc status` and `sc doctor` report different egress addresses on the same
  machine.

**Rejected alternative — extract a shared `sing-box check` wrapper for `generate_config()` and S3
as well.** Rejected; recorded in `.harness/rejected-decisions.md` as
`shared-singbox-check-wrapper`. Reasons: (a) the *judgment* "is this config valid" is formed by the
external binary, not by `bin/sc` — what would be shared is a four-line invocation, i.e. a
pass-through that fails the deletion test (delete it and no complexity reappears); (b) the two call
sites genuinely differ — `generate_config()` checks a file it has just written as part of an apply
flow and routes the message to a stderr warning (`bin/sc:921-926`), while S3 checks a file it must
never write and must classify and truncate the message per BC-7; (c) `generate_config()`'s
invocation uses `capture_output=` — one of the three pre-existing 3.7+ sites that stage 1 §3.7 puts
in a different pool row — so a shared wrapper would either drag that fix into this diff or force
this diff to add a fourth occurrence. Both are forbidden. The consistent principle across D-4/D-5:
**this task consolidates shared *data* (a name, an endpoint, a persisted key); it does not wrap
shared *procedure*.**

### 3.6 D-6 — Outcome-class rendering, grep-ability, and the TTY question

**Decision: one uniform row shape, translated class markers, no padding, no colour, no ESC, no CR —
on a terminal and off one alike. There is no TTY gate, by construction.**

Every report line is exactly:

```
<marker><SP><label>: <value>
```

with `marker` = `"[" + t("OK"|"PROBLEM"|"UNKNOWN") + "]"` — the brackets outside `t()`, following
the project's existing convention that the `⚠️ ` prefix stays outside `t()`
(`docs/dev-map.md`, `bin/sc:702`). In English: `[OK]` / `[PROBLEM]` / `[UNKNOWN]`; in Chinese:
`[正常]` / `[异常]` / `[未知]` (BC-18 requires the classes to render in Chinese too).

- **Grep-able (AC-11):** the marker is a fixed three-element set per language, anchored at column 0,
  so `grep '^\[PROBLEM\]'` / `grep '^\[异常\]'` classifies every row. The label is followed by
  `": "`, so a section label is matched unambiguously by `grep '] <label>: '` even when another
  row's label extends it (`Clash API` vs `Clash API responding`).
- **No alignment, no padding (RISK-3 structurally removed):** the design computes no width
  anywhere, so there is no character-count-vs-display-width bug to have. FR-22 makes alignment
  optional; AC-24's 80-column bound is then trivially met for every fixed row.
- **No blank separator lines** (unlike `cmd_status`, which prints `"\n" + header`): the report is a
  paste-into-an-issue artefact and the physical-line budget is 25 (AC-24). See §6 for the count.
- **The one documented exception to the row shape** is BC-7's quoted checker message: those lines
  are printed as `"    " + <line>`, verbatim, with no marker and no label, because they are foreign
  text quoted whole. They are the only indented lines in the report, which is exactly what makes
  them recognisable as quotation.

**The TTY question (FR-21), answered directly.** `doctor` draws nothing that requires a terminal:
no progress redraw (contrast `_fetch_to_temp()`, gated on `sys.stdout.isatty()` via
`cmd_update_rules`' `tty` at `bin/sc:1176`), no colour, no cursor movement. So the correct design is
not a gate but an unconditional guarantee: **`doctor` emits no `0x0D` and no `0x1B`, ever.** *If* a
gate were needed it would be `sys.stdout.isatty()`, because `doctor`'s artefact is **stdout** — the
bug-report capture is `sc doctor > out.txt 2>&1` (BC-14/AC-17); T-08 gated on `[ -t 2 ]` for the
opposite reason, its artefact being curl's stderr progress bar. Stating it once here so that neither
the developer nor QA guesses.

The only bytes that could smuggle a CR or an ESC into `doctor`'s stdout are **foreign**: the
checker's message, `ip`'s output, `sing-box version`'s output, an exception's `str()`. They are
therefore all routed through one scrubber:

```
def _plain(text):
    """Foreign text (a tool's output, an exception message) made safe for the non-TTY output
    contract: CR and ESC removed, trailing whitespace stripped. Never abridges."""
    return text.replace("\r", "").replace("\x1b", "").rstrip()
```

Deletion test: delete `_plain()` and five call sites each need the same two replacements, and
AC-17 stops being a property of the code and becomes a hope about other programs' colour detection.
It stays. (ESC removal is byte-level rather than a full ANSI-sequence strip, deliberately: `re` is
not imported by `bin/sc` and adding it to delete a colour code nobody has observed is not worth an
import. If a coloured checker ever appears, the residue is `[0;31m` — ugly, and still AC-17-clean.)

### 3.7 D-7 — Per-probe isolation, streaming and flush ordering (FR-9/FR-10/FR-27)

**Decision: a driver loop over a seven-entry section table; each probe is called inside
`try/except Exception`; each section's rows are printed and flushed before the next probe starts.**

```
worst = DOCTOR_OK
for label_key, probe in DOCTOR_SECTIONS:          # the tuple IS the FR-6/FR-7 print order
    try:
        rows = probe()                            # returns a list of rows; see §5.2
    except Exception as e:                        # NOT BaseException, NOT a bare except
        rows = [(DOCTOR_UNKNOWN, None, t("this check could not run: {e}", e=_plain(str(e))))]
    for cls, sub_key, value in rows:
        <print the row, flush>                    # §5.2 rendering rules
        if cls is not None:
            worst = max(worst, cls)
sys.exit(DOCTOR_EXIT[worst])
```

- **`except Exception` is the isolation mechanism** (FR-9). `KeyboardInterrupt` and `SystemExit`
  derive from `BaseException`, not `Exception`, so they pass straight through — a bare `except:`
  (or `except BaseException`) would swallow Ctrl-C during the 8 s egress wait and is a defect.
  Ctrl-C behaviour is therefore unchanged from every other subcommand (`sc log -f`, `sc
  update-rules`); the exit-status enumeration in D-1 describes normal termination, and a
  signal-death status is not one of `doctor`'s outcomes.
- **The fallback row keeps the section on screen** (AC-8): its label is `None`, which the renderer
  resolves to the section label, so all seven section labels are printed under every failure.
- **Probes handle their own expected failures locally** and return a precise row (e.g. "`ip` is
  missing" → UNKNOWN with the `OSError` text); the driver's `except` is the backstop for the
  *unexpected* only. Both paths always produce a row, which is what FR-9 requires.
- **Streaming (FR-10/AC-12):** every row is printed with `print(..., flush=True)` — stronger than
  the requirement, which is per-section. Nothing is accumulated except `worst`, a single integer, so
  no output can be pending when a probe blocks. Without the explicit flush the whole report would
  sit in the 8 KiB block buffer when stdout is a pipe and AC-12 would fail exactly in the
  bug-report case; the flush is load-bearing, not decoration.
- **No probe reads another probe's result.** Where a probe needs a prerequisite (S3 needs to know
  whether a checker exists) it calls the same cheap, read-only resolver itself
  (`shutil.which(SB_BIN)`, already imported at `bin/sc:8`/`:35`). That is the same function giving
  the same answer, not a second judgment, and it keeps a failing probe from corrupting a later
  probe's inputs.
- **FR-7's dependency relation orders printing; it never suppresses a probe.** S5/S6/S7 run whether
  or not S4 found a running service (stage 1 R-5: the stopped-service egress address is the most
  diagnostic case). The only in-section prerequisites are S3's checker and S6's persisted port, both
  of which render as UNKNOWN per FR-8.
- **FR-27:** the only uncaught paths left are `BaseException` (deliberate, above) and the final
  `sys.exit(int)`, which prints nothing.

### 3.8 D-8 — RISK-1: can `sing-box check` touch `/var/lib/sing-box/cache.db`?

**Not settled here. Not pre-emptively worked around. Measured by stage 6.**

What is known from the repository: the generated config declares
`experimental.cache_file = {enabled: true, path: "/var/lib/sing-box/cache.db"}` (`bin/sc:903-905`),
and `sing-box check -c <config>` is already run on every `sc add` / `sc rm` / `sc reload`
(`bin/sc:921-926`). On this development host both `/usr/local/bin/sing-box` and
`/var/lib/sing-box/cache.db` exist — which proves nothing either way, because `_init_files()`
creates `/var/lib/sing-box` on every `sc` run (`bin/sc:225`) and the *running service* is the
expected author of the cache. I have no shell in this session, so I could not run the binary
read-only and I will not assert an answer from memory of sing-box's internals.

**Prediction, to be falsified or confirmed:** `check` builds the instance and closes it without
entering the start phase in which the cache-file service opens its database, so no write is
expected.

**What structurally limits the exposure regardless of the answer:** on a host with no
`/etc/sing-box` — AC-5's second half, the fresh-install case — S3 short-circuits at "no config
file" and **never invokes the checker at all**, so that half of AC-5 cannot be affected by this
risk. Only the config-present half depends on the checker's behaviour.

**Pre-agreed contingency if stage 6 measures a write** (so that nobody improvises during QA):
neither dropping the check nor substituting a JSON parse is acceptable — the first guts S3's whole
diagnostic value (the owner's failure chain ends in a `sing-box check` FATAL), the second forms a
second opinion about config validity that the codebase does not hold. The remedy is a **narrowly
scoped, documented exception covering `/var/lib/sing-box/cache.db` only**, recorded in
`.harness/rejected-decisions.md` and in the CHANGELOG entry, and re-reviewed at the gate — i.e. FR-4
is amended by evidence, in public, not weakened in advance. There is no third option available
without writing a modified config, which FR-4 forbids outright.

### 3.9 D-9 — Where the report's structure is pinned

The seven-entry `DOCTOR_SECTIONS` tuple is the single reviewable artefact of FR-6/FR-7's
topological order: reading it top to bottom is AC-3's check. No other code decides section order,
and no probe prints another section's rows.

---

## 4. Edit list for `bin/sc` (in file order)

| # | Anchor (HEAD) | Edit |
|---|---|---|
| E-1 | `bin/sc:24` (`# Paths`) | add `TUN_IFACE = "sb-tun"` with a one-line comment naming its three consumers |
| E-2 | `bin/sc:85-166` (`TRANSLATIONS["zh"]`) | add the new zh entries of §10, grouped under a `# doctor` comment, keeping the existing insertion style |
| E-3 | `bin/sc:191-212` | split out `_saved_clash_port()`; `_resolve_clash_port()` calls it (D-4) |
| E-4 | new, next to `_resolve_clash_port()` | `_egress_ip()` (D-5) |
| E-5 | `bin/sc:516-558` | `ruleset_state()` returns `(status, digest, size)`; docstring's DIGEST CONTRACT block gains the size clause (D-2) |
| E-6 | `bin/sc:586-587` | `ruleset_states()` unpacks three, appends 5-tuples |
| E-7 | `bin/sc:596` | `_status_view()` comprehension unpacks five, emits the same 3-tuples |
| E-8 | `bin/sc:623, 625` | `changed_usable_tags()` unpackings widen by one `_size`; **no logic change** |
| E-9 | `bin/sc:644-652` | `_status_text()` gains `"usable": t("usable")` so S2's healthy rows are bilingual (FR-11; existing callers only ever pass non-usable statuses, so their output is unchanged) |
| E-10 | `bin/sc:873` | `"interface_name": TUN_IFACE` |
| E-11 | `bin/sc:945-946` | `clash_api(method, path, data=None, port=None)`; URL uses `port or CLASH_PORT` |
| E-12 | `bin/sc:1099` | `subprocess.run(["ip", "-br", "addr", "show", TUN_IFACE])` |
| E-13 | `bin/sc:1111-1112` | `print(_egress_ip())` inside the existing `try`/`except` |
| E-14 | after `cmd_status` (`bin/sc:1114`) | the doctor block: class constants, `_plain()`, `_doctor_run()`, `_doctor_print()`, the seven probes, `DOCTOR_SECTIONS`, `cmd_doctor()` (§5) |
| E-15 | `bin/sc:1405` / `bin/sc:1457` | `doctor` entry in `HELP_EN` / `HELP_ZH`, inserted after `status`, descriptions at column 30 and sub-lines at column 32 per `docs/dev-map.md` |
| E-16 | `bin/sc:1510` | `sub.add_parser("doctor")` (no arguments — FR-1) |
| E-17 | `bin/sc:1522` → above `bin/sc:1501` | move `args = parser.parse_args()` above the init block and add the branch (D-3) |
| E-18 | `bin/sc:1525` | `"doctor": cmd_doctor,` in `handlers` |

---

## 5. New module decomposition (all inside `bin/sc`)

### 5.1 Public surface added

| Name | Signature | Responsibility |
|---|---|---|
| `TUN_IFACE` | `str` constant | the one name of this project's TUN device |
| `_egress_ip()` | `() -> str` | the one egress-IP query (endpoint + 8 s timeout + decode); raises on failure |
| `_saved_clash_port()` | `() -> int or None` | the one reader of the persisted Clash API port |
| `_plain(text)` | `(str) -> str` | foreign text made output-contract-safe |
| `_doctor_run(cmd)` | `(list) -> (int, str)` | run a read-only probe command, merged stdout+stderr, decoded, `_plain`ed. 3.6-safe on purpose: `stdout=subprocess.PIPE, stderr=subprocess.STDOUT`, `.decode("utf-8", "replace")` — **no `capture_output=`, no `text=`** (AC-23). Lets `OSError`/`FileNotFoundError` propagate to the caller, which is how BC-9 becomes an UNKNOWN row |
| `_doctor_print(cls, label, value)` | `(int or None, str or None, str) -> None` | render one row and flush |
| `_doctor_binary/_rulesets/_config/_service/_tun/_clash/_egress()` | `() -> [row]` | the seven probes; pure w.r.t. the filesystem (read-only), no printing |
| `DOCTOR_SECTIONS` | tuple of `(label_key, probe)` | the pinned print order (D-9) |
| `cmd_doctor(args)` | `(argparse.Namespace) -> NoReturn` | driver: isolation, rendering, accumulation, `sys.exit` |

### 5.2 Row shape

A **row** is `(cls, label_key, value)`:

| Field | Values | Meaning |
|---|---|---|
| `cls` | `DOCTOR_OK` / `DOCTOR_UNKNOWN` / `DOCTOR_PROBLEM` | the row's outcome class; contributes to `worst` |
| | `None` | **verbatim continuation line** (BC-7's quoted checker output): printed as-is, contributes nothing to the exit status |
| `label_key` | English translation key, or a data string (a `.srs` filename) | rendered with `t()`. `t()` returns unknown keys verbatim (`bin/sc:215-217`), so data labels pass through unchanged — the four filenames are constants and are not keys |
| | `None` | use the section's own label key |
| `value` | already-rendered `str` | the probe calls `t()` itself, because only it knows its placeholders |

Rendering (`_doctor_print`): for `cls is None`, `print(value, flush=True)` where the probe has
already prefixed the four spaces; otherwise
`print("[" + t(DOCTOR_MARK[cls]) + "] " + t(label) + ": " + value, flush=True)`.

### 5.3 Class constants and the exit map

```
DOCTOR_OK, DOCTOR_UNKNOWN, DOCTOR_PROBLEM = 0, 1, 2     # ordered: OK < UNKNOWN < PROBLEM
DOCTOR_MARK = {DOCTOR_OK: "OK", DOCTOR_UNKNOWN: "UNKNOWN", DOCTOR_PROBLEM: "PROBLEM"}
DOCTOR_EXIT = {DOCTOR_OK: 0, DOCTOR_UNKNOWN: 2, DOCTOR_PROBLEM: 1}
```

The ordering constant makes `worst = max(worst, cls)` the whole accumulator; the exit map is the
whole of D-1. `DOCTOR_MARK`'s values are translation keys, resolved at print time — they must not be
pre-rendered at module level, for the same reason `_status_text()` is a function and not a dict
(`bin/sc:645-646`): `LANG` is assigned in `main()`, after import.

---

## 6. Section-by-section probe table

`✔` = OK, `✖` = PROBLEM, `?` = UNKNOWN. Row labels are the English translation keys.

| § | Section label | Probe (all read-only) | Rows | Classification |
|---|---|---|---|---|
| S1 | `sing-box binary` | `shutil.which(SB_BIN)`; then `_doctor_run([SB_BIN, "version"])` | `sing-box binary` = the resolved absolute path; `sing-box version` = first non-empty output line | path found ✔ / not found ✖ `not found on PATH`. version: line found ✔ / no binary ? `no sing-box binary on PATH` / non-zero or empty ? `the binary produced no version line (exit {code})` / `OSError` ? `cannot determine: {e}` |
| S2 | `rule-sets` | `ruleset_states()` — one call, one read per file, FR-12's size | summary `rule-sets` = `{n}/{total} usable`; then one row per entry of `RULESET_FILES` (`bin/sc:60-65`) in that order, label = filename, value = `{reason}, {size} bytes` or `{reason}, size unavailable` when `size is None` | per file: `usable` ✔, anything else ✖. Summary row = worst of the four. `reason` is `_status_text(status)` — the existing bilingual renderer, extended with `usable` (E-9); no new status word (FR-11) |
| S3 | `configuration` | open `CFG_PATH` for reading and close it; if readable **and** `shutil.which(SB_BIN)`, `_doctor_run([SB_BIN, "check", "-c", str(CFG_PATH)])` | `configuration` = the path, or `no file at {path}`, or `cannot read {path}: {e}`; then (only when the file was readable) `sing-box check` = `no error reported` or `the checker reported an error:` + up to 5 verbatim lines + `... {n} more line(s) not shown` | file present ✔ / `FileNotFoundError` ✖ / other `OSError` ? (BC-6: permission is never rendered as absence). check: rc 0 ✔ / rc≠0 ✖ / no binary ? `no sing-box binary on PATH` (FR-8: the missing binary makes S3 UNKNOWN, never "config invalid") |
| S4 | `service` | init flags `SYSTEMD`/`OPENRC` (`bin/sc:35-36`); `is_running()` (`bin/sc:959-965`); then `systemctl is-enabled sing-box` or `rc-update show default` via `_doctor_run` | `service` = `running (via {init})` / `not running (via {init})`; `boot autostart` = `enabled` / `not enabled ({state})` | both ? with `no init system detected (neither systemd nor OpenRC)` when neither flag is set — **checked first, so `is_running()`'s hard `False` (`bin/sc:965`) is never rendered as "not running"** (BC-8/FR-14). autostart: systemd `is-enabled` stdout `enabled` ✔ else ✖ with the state word (or, when the unit does not exist, the tool's first output line) as `{state}`; OpenRC: the service name appears in `rc-update show default` ✔ else ✖. `OSError` from either tool → ? `cannot determine: {e}` |
| S5 | `TUN interface` | `_doctor_run(["ip", "-br", "addr", "show", TUN_IFACE])` | `TUN interface` = `TUN_IFACE` or `{iface} does not exist`; `TUN addresses` = the addresses joined by `", "` (only when the device exists) | rc 0 and a matching line ✔ / rc≠0 or no line ✖ (BC-10) / `OSError` (`ip` absent) ? `cannot query: {e}` (BC-9). Addresses row: none present ✖ with the existing key `(none)`. The `ip` operstate is deliberately **not** printed: for a TUN device it reads literally `UNKNOWN` and would collide with the outcome-class vocabulary |
| S6 | `Clash API` | `_saved_clash_port()`; then `clash_api("GET", "/configs", port=port)` (3 s, unchanged) | `Clash API` = `127.0.0.1:{port}` or `no port recorded in settings.json`; `Clash API responding` = `yes` / `no answer within the 3s timeout` / `not probed — no port recorded` | port recorded ✔ / absent ? (FR-15/BC-11). responding: non-`None` return ✔ / `None` ✖ (BC-12 — a down service is a PROBLEM, not UNKNOWN) / no port ?. **Test the return with `is not None`**: `clash_api()` returns `{}` for an empty body (`bin/sc:954`), which is falsy |
| S7 | `egress IP` | `_egress_ip()` — unconditional, never gated on `is_running()` (stage 1 R-5/FR-16) | `egress IP` = the address, or the existing key `(error: {e})` | success ✔ / any exception ✖ (BC-13). No claim is made about whether the address is proxied (FR-16) |

Physical-line budget (AC-24): healthy = 2+5+2+2+2+2+1 = **16**; worst realistic (S3 failing with a
6+-line message) = 2+5+8+2+2+2+1 = **22** ≤ 25.

### 6.1 Rendered sample — healthy host (English)

```
[OK] sing-box binary: /usr/local/bin/sing-box
[OK] sing-box version: sing-box version 1.11.5
[OK] rule-sets: 4/4 usable
[OK] geoip-cn.srs: usable, 1179447 bytes
[OK] geosite-cn.srs: usable, 619273 bytes
[OK] geosite-google.srs: usable, 4297 bytes
[OK] geosite-private.srs: usable, 696 bytes
[OK] configuration: /etc/sing-box/config.json
[OK] sing-box check: no error reported
[OK] service: running (via systemd)
[OK] boot autostart: enabled
[OK] TUN interface: sb-tun
[OK] TUN addresses: 172.19.0.1/30
[OK] Clash API: 127.0.0.1:29090
[OK] Clash API responding: yes
[OK] egress IP: 203.0.113.7
```

### 6.2 Rendered sample — the owner's failure chain (AC-4 fixture), English

```
[OK] sing-box binary: /usr/local/bin/sing-box
[OK] sing-box version: sing-box version 1.11.5
[PROBLEM] rule-sets: 0/4 usable
[PROBLEM] geoip-cn.srs: missing, size unavailable
[PROBLEM] geosite-cn.srs: missing, size unavailable
[PROBLEM] geosite-google.srs: missing, size unavailable
[PROBLEM] geosite-private.srs: missing, size unavailable
[OK] configuration: /etc/sing-box/config.json
[PROBLEM] sing-box check: the checker reported an error:
    FATAL[0000] decode config at /etc/sing-box/config.json: parse rule-set[0]: open /etc/sing-box/rules/geoip-cn.srs: no such file or directory
[PROBLEM] service: not running (via systemd)
[PROBLEM] boot autostart: not enabled (disabled)
[PROBLEM] TUN interface: sb-tun does not exist
[OK] Clash API: 127.0.0.1:29090
[PROBLEM] Clash API responding: no answer within the 3s timeout
[OK] egress IP: 203.0.113.7
```

Exit status `1`. The root cause is readable top-down: four missing rule-sets, then the check failing
*because of them*, then the dead service, then the missing TUN — which is AC-4.

---

## 7. Error and degradation model

| Condition | Behaviour |
|---|---|
| A probe raises an expected error it can name (`OSError`, missing tool, non-zero rc) | the probe returns an UNKNOWN or PROBLEM row naming the cause; the run continues |
| A probe raises anything else | the driver's `except Exception` turns it into one UNKNOWN row under the section's own label (`this check could not run: {e}`); the run continues (FR-9/AC-8) |
| `KeyboardInterrupt` / `SystemExit` | pass through (BaseException); already-printed sections stay on stdout because every row was flushed (FR-10/AC-12) |
| A tool prints CR or ESC | removed by `_plain()` before printing (FR-21/AC-17) |
| A checker message longer than 5 lines | first 5 lines printed verbatim, then `... {n} more line(s) not shown` (BC-7) |
| The report is interrupted | no cleanup is needed — `doctor` holds no resource, writes no file, and takes no lock (BC-15/BC-16) |
| Two concurrent `doctor` runs, or a concurrent `sc update-rules` | both complete; S2 reports whatever the single reader saw for whatever bytes were on disk, with no retry and no lock (BC-15/BC-16) |

---

## 8. Exit-status contract (documented in both help blocks and both READMEs — FR-28)

```
exit 0  every section OK
exit 1  at least one PROBLEM  (any section: a missing binary, an unusable rule-set, a failed
        config check, a stopped or non-autostarting service, a missing TUN device, an
        unanswered Clash API port, an egress query that failed)
exit 2  no PROBLEM, but at least one UNKNOWN (a probe could not run: no sing-box binary to
        check the config with, no init system detected, `ip` missing, no Clash API port
        recorded in settings.json)
```

The full report is always printed before the process exits (FR-26); the status never truncates it.

---

## 9. Read-only proof obligations (AC-7's enumeration, prepared here)

Complete list of everything `doctor` invokes or touches:

| Kind | Operation | Read-only because |
|---|---|---|
| subprocess | `sing-box version` | prints a version string |
| subprocess | `sing-box check -c /etc/sing-box/config.json` | validates only — the one residual doubt is D-8/RISK-1, measured by stage 6 |
| subprocess | `systemctl is-active --quiet sing-box` (via `is_running()`) | a query; `is-active` cannot even witness a restart, let alone cause one |
| subprocess | `systemctl is-enabled sing-box` | a query |
| subprocess | `rc-service sing-box status` (via `is_running()`), `rc-update show default` | queries; `rc-update show` takes no runlevel-modifying argument |
| subprocess | `ip -br addr show sb-tun` | `show` |
| file | `open(CFG_PATH, "rb")` then close | read mode |
| file | `ruleset_states()` → `ruleset_state()` | documented "never raises, never writes" (`bin/sc:534`) |
| file | `load_settings()` via `_saved_clash_port()`, `_load_lang()` | `read_text()` |
| network | `clash_api("GET", "/configs", port=…)` | a GET to loopback |
| network | `_egress_ip()` | a GET to the existing endpoint; NFR-6 — nothing leaves the machine but the request itself |

Not in the graph, by construction: `generate_config()`, `restart_service()`, `reload_or_restart()`,
`save_nodes()`, `save_settings()`, `_init_files()`, `_resolve_clash_port()`, `_free_port()`,
`_fetch_to_temp()`, `_temp_path()`, `_clear_stale_temps()`, `RULES_DIR.mkdir()`.

---

## 10. Translation keys introduced (FR-23/FR-24/AC-18/AC-19)

Every key is readable English prose used verbatim as the English output; every zh value carries the
identical placeholder set. **None contains `失败` in any form** — the load-bearing grep literal
`失败：` produced by `"failed: {e}"` (`bin/sc:127`) must not appear in `doctor`'s zh output (FR-24/
AC-20), and the safe rule for the developer is: do not use the word at all.

| English key (= English output) | zh value |
|---|---|
| `OK` | `正常` |
| `PROBLEM` | `异常` |
| `UNKNOWN` | `未知` |
| `sing-box binary` | `sing-box 可执行文件` |
| `sing-box version` | `sing-box 版本` |
| `rule-sets` | `规则集` |
| `configuration` | `配置文件` |
| `sing-box check` | `sing-box 配置检查` |
| `service` | `服务` |
| `boot autostart` | `开机自启` |
| `TUN interface` | `TUN 接口` |
| `TUN addresses` | `TUN 地址` |
| `Clash API` | `Clash API` |
| `Clash API responding` | `Clash API 是否响应` |
| `egress IP` | `出口 IP` |
| `usable` | `可用` |
| `not found on PATH` | `未在 PATH 中找到` |
| `no sing-box binary on PATH` | `PATH 中没有 sing-box 可执行文件` |
| `the binary produced no version line (exit {code})` | `该可执行文件未输出版本信息（退出码 {code}）` |
| `{n}/{total} usable` | `{n}/{total} 个可用` |
| `{reason}, {size} bytes` | `{reason}，{size} 字节` |
| `{reason}, size unavailable` | `{reason}，大小未知` |
| `no file at {path}` | `文件不存在：{path}` |
| `cannot read {path}: {e}` | `无法读取 {path}：{e}` |
| `no error reported` | `未报告错误` |
| `the checker reported an error:` | `检查器报告了错误：` |
| `... {n} more line(s) not shown` | `……另有 {n} 行未显示` |
| `running (via {init})` | `运行中（由 {init} 报告）` |
| `not running (via {init})` | `未运行（由 {init} 报告）` |
| `no init system detected (neither systemd nor OpenRC)` | `未检测到 init 系统（既没有 systemd 也没有 OpenRC）` |
| `enabled` | `已启用` |
| `not enabled ({state})` | `未启用（{state}）` |
| `cannot determine: {e}` | `无法确定：{e}` |
| `{iface} does not exist` | `{iface} 不存在` |
| `cannot query: {e}` | `无法查询：{e}` |
| `no port recorded in settings.json` | `settings.json 中没有记录端口` |
| `yes` | `是` |
| `no answer within the 3s timeout` | `3 秒超时内无响应` |
| `not probed — no port recorded` | `未探测 —— 没有记录端口` |
| `this check could not run: {e}` | `该项检查无法执行：{e}` |

**Reused, not re-added** (adding a duplicate dict key would silently override the existing zh value):
`(none)` (`bin/sc:103`) for S5's empty address list, `(error: {e})` (`bin/sc:105`) for S7's failure,
and `missing` / `not a rule-set file` / `file too small` / `unreadable` (`bin/sc:133-136`) through
`_status_text()`.

Note for QA reading AC-18 ("no line is the untranslated English key"): interpolated *data* is not a
key. Under `lang zh`, an exception text, a path, a filename, a tool's state word and
`sing-box version`'s own output stay English — as they already do in `sc status`'s `(error: {e})`.

---

## 11. Reuse map, with the deletion test

| Need (section) | Existing code reused | Anchor | Deletion test — what breaks if it is removed |
|---|---|---|---|
| rule-set status + digest + size from one read (S2) | `ruleset_state()` | `bin/sc:516-558` | S2 and `ruleset_states()` and thus `generate_config()` and `sc update-rules` all break at once — one reader, no alternative path |
| all four rule-sets in `RULESET_FILES` order (S2) | `ruleset_states()` | `bin/sc:575-588` | S2 breaks at call time, together with `ruleset_report()` (`bin/sc:605`) and both `cmd_update_rules` snapshots |
| the usability judgment itself (S2) | `srs_reject_reason()` | `bin/sc:501-513` | every consumer of "usable" breaks; `doctor` contains no magic/size test of its own |
| bilingual status words (S2) | `_status_text()` | `bin/sc:644-652` | S2's reason column loses its only renderer; `doctor` defines no status vocabulary (FR-11) |
| "is the service running" (S4) | `is_running()` | `bin/sc:959-965` | S4's first row breaks; `doctor` contains no `systemctl is-active` of its own |
| init-system detection (S4) | `SYSTEMD` / `OPENRC` | `bin/sc:35-36` | S4 breaks; `doctor` runs no second `shutil.which("systemctl")` |
| Clash API call (S6) | `clash_api()` | `bin/sc:945-956` | S6's reachability row breaks; `doctor` opens no socket of its own and inherits the 3 s timeout |
| persisted Clash port (S6) | `_saved_clash_port()` (new, extracted from `_resolve_clash_port()`) | `bin/sc:191-212` | S6 **and** `_resolve_clash_port()` break together — the extraction is a real seam with two adapters, not a hypothetical one |
| egress query (S7) | `_egress_ip()` (new, extracted from `cmd_status`) | `bin/sc:1109-1114` | S7 **and** `sc status`'s egress line break together — two adapters |
| TUN device name (S5) | `TUN_IFACE` (new constant) | `bin/sc:873`, `:1099` | `generate_config()`, `sc status` and S5 break together — three adapters |
| binary reference, config path, rules dir (S1/S3/S2) | `SB_BIN`, `CFG_PATH`, `RULES_DIR` | `bin/sc:32`, `:19`, `:22` | every path-touching section breaks; `doctor` hard-codes no path |
| bilingual output | `t()` + `TRANSLATIONS` | `bin/sc:85-217` | all output breaks |

Nothing in `doctor` re-decides a fact that another function already decides. The only judgments
`doctor` itself forms are about facts nothing in the codebase decided before: whether the TUN device
exists, whether a persisted port answers, whether the installed config passes the checker, and
whether the service is registered at boot.

---

## 12. Rule-85 disposition

### 12.1 Consolidations made (each names the future edit it prevents)

| Consolidation | Seam removed | Future edit it prevents |
|---|---|---|
| `ruleset_state()` returns the size it already computed | a second `.srs` read path, or a size that disagrees with the status | any change to what "one read of a rule-set" yields would otherwise have to be made twice, and a `stat`-based size can already disagree today under a concurrent `update-rules` (BC-15) |
| `_saved_clash_port()` | two readers of `settings["clash_api_port"]` | relocating/renaming the persisted port |
| `_egress_ip()` | two copies of endpoint + timeout + decode | changing or adding an egress endpoint |
| `TUN_IFACE` | three copies of the device name | renaming the TUN device |

### 12.2 Splits kept (consolidation declined)

- **`doctor` does not absorb `sc config --show` (T-06) and does not replace `sc status`** — stage 1
  R-8 decided this and this design keeps it: FR-19 pins `sc status`'s bytes, and the overlap between
  the two commands is now purely in the *rendering*, because the shared **facts** have exactly one
  definition each (§12.1). That is precisely what R-8 asked for.
- **No shared `sing-box check` wrapper** — §3.5, recorded as `shared-singbox-check-wrapper` in
  `.harness/rejected-decisions.md`.
- **No `--json` / `--quiet` / per-section flags, no remediation advice, no log excerpts** — stage 1
  §3.8; the counter-rule forbids inventing scope. Seven sections, no options.
- **No new file, no new module, no test directory** — the committed harness stays T-07's
  (`.harness/rejected-decisions.md` → `ruleset-unit-tests-in-t02`, now on its fourth re-occurrence;
  this task's harness is again handed to stage 6 and pasted into `06_TEST_REPORT.md`).

---

## 13. Documentation edits

- **`HELP_EN` / `HELP_ZH`** (`bin/sc:1405` / `:1457`): insert `doctor` immediately after `status`,
  descriptions at column 30, sub-lines at column 32, with the three exit values from §8 as
  sub-lines. Both blocks must gain the same number of lines at the same relative position.
- **`README.md` / `README.zh-CN.md`**: add `sc doctor` to the Service-control block (`README.md:94-101`
  / `README.zh-CN.md:94-101`, after the `sc status` line) and a new subsection
  `### Diagnose the install` / `### 诊断安装` immediately after it and before
  `### Ruleset update` / `### 规则集更新` (both at line 103), containing: what the seven sections
  are, the promise that the command changes nothing, and the exit-status table of §8. The two files
  must take the insertion at the same structural point (AC-2).
- **`CHANGELOG.md`**: one bullet under `[Unreleased] → 新增`, in Chinese per project convention.
  Draft: 「**新增 `sc doctor` 一键体检**：一条命令按因果顺序打印七项事实 —— sing-box 可执行文件、
  四个规则集（含来自同一次读取的字节数）、配置文件与 `sing-box check` 结果、服务是否运行与是否开机
  自启、TUN 接口、Clash API 端口与是否响应、出口 IP；每行标注 `正常 / 异常 / 未知` 三种结论之一，
  一项探测失败不会中断其余六项。**全程只读**：不生成配置、不下载、不重启、不启用、不修复，也不会
  再像其他子命令那样在启动阶段创建 `/etc/sing-box`、写入 `nodes.json` / `settings.json` 或探测
  并保存 Clash API 端口 —— 机器已经坏掉时运行它不会破坏现场证据。退出码：0 = 全部正常，
  1 = 至少一项异常，2 = 没有异常但至少一项无法判定。`sc status` 的输出没有任何改动。」
- **`docs/dev-map.md`** (FR-31 — the inventory really does change):
  - "Reusable utilities" → `ruleset_state(path)` row: `(status, digest)` → `(status, digest, size)`,
    and state the extended contract `size is None ⇔ digest is None`.
  - Same table → `ruleset_states()` note: 5-tuples; `_status_view()` is what keeps
    `generate_config()`/`usable_tags()` on 3-tuples.
  - New rows: `TUN_IFACE`, `_egress_ip()`, `_saved_clash_port()` — "the single definition of X;
    `sc status`, `generate_config()` and `sc doctor` all consume it".
  - "`bin/sc` internal sections" → `# Commands` row: mention the doctor block (driver + seven
    probes) and that `main()` now parses arguments before initialising, with `doctor` the one
    command that skips `_init_files()` / `_resolve_clash_port()`.
  - "Patterns to avoid" → one line: don't give `doctor` a second opinion; don't add a
    read-only-mode flag per subcommand (D-3).

---

## 14. Testability — what stage 6 must measure

**Harness neutralisation (RISK-4, non-negotiable).** Any harness that imports `bin/sc` must (a)
neutralise the import-time auto-elevate at `bin/sc:78-79` — otherwise it re-execs the **installed**
`/usr/local/bin/sc`, not the file under test, and sudo's `env_reset` drops the environment; (b) set
`SYSTEMD = OPENRC = False` unless the test is specifically about S4; (c) repoint `CFG_DIR`,
`CFG_PATH`, `RULES_DIR`, `SETTINGS_PATH` after import (they are only ever referenced inside function
bodies — `docs/dev-map.md`). Without (a) and (b), a test run drives the developer's live service.

| # | Must be measured | Method / expected |
|---|---|---|
| T-1 | **RISK-1 / D-8** — does `sing-box check` touch `/var/lib/sing-box/cache.db`? | Record existence + size + mtime + sha256 of `/var/lib/sing-box/cache.db` and of the directory itself, with the service **stopped**, before and after `sc doctor` on a host with a valid `config.json`. Repeat with the cache file deleted (expect: still absent afterwards). Expected: identical / still absent. A difference is a finding, not a licence to weaken FR-4 — apply §3.8's contingency and return to the gate |
| T-2 | AC-5 read-only, both halves | sha256+mode+mtime snapshot of every path under `/etc/sing-box` and `/var/lib/sing-box` before/after; and the fresh-host half — with both trees deleted, `sc doctor` must leave them non-existent (this is the D-3 branch under test) |
| T-3 | AC-6 no service touch | `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` before/after — `is-active` is not admissible evidence |
| T-4 | **NFR-2 runtime ceiling, claimed here** | Healthy host: **< 2 s**. Service down + Clash port unreachable + network blackholed (routes dropped, DNS answering): **≤ 12 s**, being the unchanged 3 s Clash timeout + the unchanged 8 s egress timeout + local subprocesses; the claim to verify is **≤ 15 s**. With DNS blackholed the run may exceed that without bound — `socket` timeouts do not cover name resolution — and that is reported, not failed; FR-10's streaming is what makes it tolerable, and S7 is last for that reason. `doctor` adds no timeout constant and no `timeout=` to any local subprocess (a hung local binary is unbounded — stated, not hidden) |
| T-5 | AC-8 / AC-9 / AC-10 | seven independent forced-failure runs; all seven section labels present, normal termination, exit status per §8 |
| T-6 | **RISK-2 regression** — other subcommands still initialise | with `/etc/sing-box` deleted: `sc lang zh`, `sc add <link>`, `sc mode global`, `sc status` each recreate the tree; `nodes.json` mode 0600; `settings.json` gains `clash_api_port` |
| T-7 | AC-16 | `sc status` captured before/after the change, both languages, same machine state, byte-identical (`cmp`) |
| T-8 | AC-14 | `doctor`'s call graph contains no `stat`/`st_size`/`getsize` on a `.srs`; plus the behavioural check — a rule-set whose apparent and read lengths differ is reported by read length |
| T-9 | T-10 non-regression (the serious one) | `sc update-rules` twice against unchanged mirror content: the second run must print "No rule-set changed" and `systemctl show -p MainPID` must be unchanged across it. This is the direct test that D-2's tuple widening did not perturb `changed_usable_tags()` |
| T-10 | AC-17 / AC-20 / AC-18 | `sc doctor > out.txt 2>&1` in every AC-8 state → zero `0x0D`, zero `0x1B`; under `lang zh`, render `t("failed: {e}")` at run time and assert no output line contains it; enumerate every new key and assert placeholder-set equality en vs zh |
| T-11 | AC-12 streaming | blackhole the network, SIGINT after S6's rows appear → S1..S6 present on stdout when redirected to a file |
| T-12 | AC-23 / B.1 | `python3 -m py_compile bin/sc`, and a 3.6 syntax check; grep the diff for `capture_output=`, `text=`, `:=`, `f"{x=}"`, `missing_ok=`, `dataclasses` |

---

## 15. Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | The external checker writes `/var/lib/sing-box/cache.db`, failing AC-5 through no fault of this task | §3.8: measured by T-1, not assumed; the fresh-host half of AC-5 never reaches the checker; a pre-agreed, narrowly-scoped contingency exists and returns to the gate |
| R-2 | The `main()` branch silently stops initialising state for other subcommands (stage 1 RISK-2) | §3.3's four mechanisms: default-is-old-behaviour, verbatim `else` arm, single greppable call sites, and executed check T-6 |
| R-3 | D-2's tuple widening perturbs `sc update-rules`' restart decision (T-10's guarantee) | only unpacking widths change in `changed_usable_tags()`; `_status_view()` absorbs the shape change so `generate_config()`/`usable_tags()`/`_warn_degraded()` are not edited at all; executed check T-9 |
| R-4 | zh double-width text misaligns a padded column (stage 1 RISK-3) | no padding and no computed width exists anywhere in the design (§3.6) — the failure mode is removed rather than handled |
| R-5 | A zh key with a mismatched placeholder set raises `KeyError` at run time, or a missing zh entry silently prints English (`t()` at `bin/sc:215-217` never aborts) | §10 fixes every key and its zh value up front; T-10 executes both languages instead of inspecting |
| R-6 | A new zh string collides with the `失败：` diagnostic grep (FR-24) | the rule "do not use 失败 at all" plus T-10's run-time rendering check; the repository-wide grep is deliberately **not** used as the criterion — that form of criterion is self-violating (insight index) |
| R-7 | A duplicate key added to `TRANSLATIONS["zh"]` silently overrides an existing zh value | §10 lists the four keys that must be **reused, not re-added**; review checks the dict for duplicates |
| R-8 | `clash_api()`'s falsy `{}` return misread as "no answer" | §6 S6: compare with `is not None`; called out because `bin/sc:954` really does return `{}` for an empty body |
| R-9 | S4 renders `is_running()`'s hard `False` (`bin/sc:965`, no init system) as "not running" | the init-system check runs first and short-circuits both rows to UNKNOWN (BC-8) |
| R-10 | Insight-index budget: 29 of 30 lines used (stage 1 RISK-5) | this task harvests at most one insight, written as a single physical line (`archive-task.sh` keeps only the first line of a bullet) |

---

## 16. Out of scope for this design

Everything in stage 1 §3, unchanged. In particular this design does **not** cover: any repair or
regeneration; `install.sh` / `uninstall.sh` / `systemd/`; the three pre-existing `capture_output=`
sites; a port-mismatch check between `settings.json` and `config.json` (stage 1 R-2); machine-readable
output; a committed test suite (T-07); and any change to `sc status`'s behaviour or output.

## 17. Partition assignment

Not applicable — `.harness/agents/` contains no `dev-*.md`; `.harness/rules/50-singbox-cli.md`
§Partitioning pins this project to a **single developer**. The whole diff is one file plus four
documentation files.

---

## 18. Verdict

**READY FOR GATE REVIEW**
