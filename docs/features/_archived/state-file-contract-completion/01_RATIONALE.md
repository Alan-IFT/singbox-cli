# T-29 · state-file-contract-completion — Requirement Rationale

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## Evidence, re-verified first-hand at this stage

All citations are backward-looking proof of what was found, read from the worktree at `1e454b6`.

### The remaining locale-decoded I/O — six sites, not four

| site | what it reads/writes | what the locale costs it today |
|---|---|---|
| `bin/sc:1667` `IF_INET6_PATH.read_text()` | `/proc/net/if_inet6`, kernel-owned, hex+space ASCII | Nothing observable. The function already answers `(None, t("unreadable"))` for a decode failure (`:1670-1678`) and its "never raises" contract holds. |
| `bin/sc:2015` `STATE_PATH.read_text().strip()` | the drift record — an `sc`-authored document, hex digest | Nothing observable (ASCII), but its **writer** is pinned to UTF-8 (`_write_private`, `bin/sc:520`) while its reader asks the locale. Insight 2026-08-15 (`output-layer-contract`): "the reader's codec is the writer's codec" is never a structural argument. Its own docstring (`:2005`) says "a record that … is not UTF-8", which is a claim about UTF-8 that the code only makes when the locale happens to be UTF-8. |
| `bin/sc:2705` `json.loads(CFG_PATH.read_text())` | `config.json`, in `_doctor_ipv6()` | Under `LC_ALL=C PYTHONUTF8=0`, a configuration carrying a CJK node tag raises `UnicodeDecodeError`, caught at `:2706`, and the AAAA row renders `[UNKNOWN] cannot read {path}: …`. The document is perfectly readable and carries the decision — a doctor row stating a cause it does not have, which is exactly the class T-26 exists to remove. |
| `bin/sc:3121` `raw = CFG_PATH.read_text()` | `config.json`, in `cmd_config()` | Same environment, same document: `sys.exit` at `:3128`, exit 1, nothing on stdout. This is the site R-76 names. |
| `bin/sc:3451` `(override_dir / "override.conf").write_text(...)` | the systemd timer drop-in, content `f"[Timer]\nOnCalendar=\nOnCalendar={on_calendar}\n"` | `on_calendar` is **unvalidated user argv** on the systemd arm (`:3444-3447`). A non-ASCII interval expression under a non-UTF-8 locale raises inside `write_text` with no guard above it. |
| `bin/sc:3499` `script.write_text("#!/bin/sh\n…")` | the OpenRC periodic script, ASCII literal | Nothing observable; included so the rule has no exception. |

Binary reads are already correct and are not in the population: `bin/sc:932`, `:1196`, `:1543`,
`:1966`, `:2640` are all `"rb"` / `"wb"`.

**Correction to the brief, load-bearing.** The brief states that `bin/sc:567`'s docstring "already
claims explicit `"utf-8"`, never `read_text()`" and that "the code contradicts a shipped sentence
today". Read in place, `:562-567` is `_read_state`'s own docstring — "THE reader of a **state
document** (settings.json / nodes.json), and the only one … read_bytes() + an explicit "utf-8", never
read_text()". The clause is scoped to that reader and to the two documents `CONTEXT.md:189-196`
defines as state documents; none of the four surviving `read_text()` calls reads one. **That sentence
is true as written, before and after this task.**

The paragraph that *is* wrong today is elsewhere and is stronger evidence. `README.md:297` and
`README.zh-CN.md:297` make **two** claims about a stdout that cannot represent the document, and the
repair does opposite things to them:

- *"a character `sc` cannot encode is written as a backslash escape **instead of ending the run**"* —
  **false at HEAD**: under a non-UTF-8 locale with a CJK-carrying `config.json` the run ends at the
  *read*, before stdout is ever reached. T-25's CR-10 wrote this clause for the post-repair world
  deliberately, and the repair is what makes it true. Verified unchanged.
- *"`\xNN` / `\UNNNNNNNN` are not JSON escapes — so the saved file is then **not** valid JSON"* —
  enumerates two of CPython's **three** `backslashreplace` spellings and then generalises over all of
  them. Measured at stage 6 on AC-9's own mandated CJK fixture: `'香港-01'` escapes as `\uNNNN`, which
  *is* a legal JSON escape, and the saved file parses; only `'café-02'` (`\xNN`) and `'🚀-03'`
  (`\UNNNNNNNN`) yield files `json.loads` rejects. The clause is **vacuous at HEAD** (that path saves
  no document at all) and **false after** the repair — R-76's predicted shape arriving in a clause
  nobody had enumerated. Corrected here, in both languages (AC-11, Q-14).

The insight-index line that anticipated the form of this (`PYTHONIOENCODING=ascii` makes `sc config`
exit 0 with a document `json.loads` rejects) names `\xe9` and `\U0001f1ef` and, correctly, never
`\uNNNN` — the distinction existed in the project's memory and not in its published prose.
`docs/dev-map.md:81`, the stream row, states what `backslashreplace` costs and makes no JSON-validity
claim at all, so it is not wrong today and is not touched.

One more document is wrong today and is cheap: `docs/dev-map.md:43` describes `cmd_config` as "one
`read_text()`, one `json.loads`, …". That clause is a navigation claim about how the read is spelled,
so it moves with the code (AC-18).

### R-66 — the settings writer, and why the family is one shape

`save_settings` (`bin/sc:615-617`) is one statement with no `try`; the node-store writer three
functions above it (`:589-595`) is the same act with a renderer:

```python
except (OSError, ValueError) as e:
    sys.exit(t("Could not write {path}: {err}",
               path=NODES_PATH, err=_plain(getattr(e, "strerror", None) or str(e))))
```

Eleven call sites write settings (`bin/sc:450, 551, 2411, 2423, 3176, 3211, 3276, 3305, 3465, 3504,
3542`), so a per-caller guard is not a candidate; one renderer inside the writer is the only shape
that scales, and it is the shape already in the file.

**T-23's declining ground, weighed rather than ignored.** (a) *No value reaching it can fail a UTF-8
encode.* This is true of the values `sc` itself sets — validated enums, a boolean, an int — but the
writer serialises the **whole document it just read**, and `json.loads` accepts an unpaired surrogate
escape, so a hand-edited `{"lang": "\ud800"}` yields a `str` that `write_text(..., encoding="utf-8")`
cannot encode. That is why FR-4 is written over "every failure class" and why AC-7 carries an explicit
NOT-DISCRIMINATING escape hatch: the reachability argument is reasoned here, not measured, and the
criterion is designed to report honestly if the control does not reproduce it. (b) *A guard would
break `_resolve_clash_port()`'s deliberate swallow* (`bin/sc:443-452`) — accepted in full, and
promoted to a requirement of its own (FR-5) rather than left as a side effect. The trap for stage 2:
a renderer that calls `sys.exit` raises `SystemExit`, which `except OSError` does not catch, so
"preserve the swallow" is a real design obligation and not a formality.

**R-66's "only" is imprecise**, and the imprecision is worth carrying rather than quietly inheriting:
`bin/sc:3451` and `:3499` are also `sc`-authored files with no rendered write failure. They are ruled
out of the *rendering* fix (Q-10) because both arms are gated on `SYSTEMD` / `OPENRC`, which the
mandated fixture holds permanently false (R-67's exact trap), so no criterion this task can run would
observe them; they are in the *codec* sweep because a source scan can.

### R-65 — the measurement re-taken by reading the path

The three harms the row measured all originate in one place, which is what makes one refusal close all
three:

1. `main()` (`bin/sc:3757-3759`) runs `_init_files()` then `_load_lang()` then `_resolve_clash_port()`
   for every non-`doctor`/`config` command. On an unusable document `_saved_clash_port()` answers
   `None` through `_settings_or_empty()`, so a fresh port is probed and lands in `CLASH_PORT`;
   `_runtime_overlay()` writes it as the Clash API's `external_controller`.
2. `generate_config()` (`:2091-2092`) composes `_dns_overlay(ipv6_decision()[1])` and
   `_telemetry_overlay()`, both of which read the settings through the degrade — so `telemetry` falls
   back to `block` (insight 2026-08-15: `block` is the absent-key default) and a stored `allow` is
   silently reversed.
3. `_record_generated()` (`:2145`) runs immediately after the write and re-baselines the drift digest
   onto the just-installed document.

Refusing before composition means step 2 never runs, step 3 is never reached, and step 1's probed port
never reaches a file — one act, three harms.

**The population is exactly five commands**, which is why the requirement is small: `sc reload`,
`sc add`, `sc rm`, `sc use` (only when the Clash-API hot switch is unavailable, `:2356-2361`) and
`sc update-rules`' recovery arm (`:3396`). Every other regenerating command already aborts today,
because it calls the strict reader before it regenerates — `cmd_ipv6` at `:3209`, `cmd_telemetry` at
`:3274`, `cmd_on` at `:2409`, `cmd_default_tun`, `cmd_update_interval`. **The status quo is therefore
incoherent in a nameable way: the eight commands that merely persist a preference refuse, while the
five that replace the running configuration proceed.** Coherence, not novelty, is the argument for
FR-6.

`cmd_update_rules`'s one-outcome contract (`bin/sc:3406-3426`, "a run that ends non-zero must still
state what it did to the service") is what forces FR-7: an exception propagating out of `:3396` to
`main()`'s arm would skip the outcome line entirely and break a shipped invariant — the R-74 shape,
caught before it was written rather than after.

## Candidates weighed, and what selected among them

### Q-1 — refuse / warn / preserve

- **Preserve** — eliminated on availability, not on merit: no design can recover the user's stored
  choices from a document the parser rejects. Its only reachable form is "do not act", i.e. refuse.
- **Warn** — keep degrading, add a sentence naming the consequence. Rejected on three counts: it needs
  a new user-facing key in both languages for a sentence that must enumerate what changed (the
  R-74 trap: a universal claim over a region no one enumerated); the harm is not the silence but the
  installation, so a louder installation is still an installation; and it leaves the incoherence above
  in place.
- **Refuse** — selected. Costs no new key, no new predicate and no new seam: the strict reader, the
  `OverrideError` envelope and `main()`'s single rendering arm all exist and are already used for this
  exact class by eight commands. It also makes the degrade's charter statable in one sentence
  (reporting degrades, acting refuses), which is what a future call site needs to make the one-word
  choice `docs/dev-map.md:76` already asks of it.
- The accepted cost, stated rather than discovered later: a host with a corrupted settings document
  cannot regenerate until it is repaired or removed. It is already substantially locked out by T-23
  (eight commands refuse), `sc doctor` — the tool that diagnoses it — keeps working by FR-8, `sc use`
  keeps working on a running host by BC-14, and the repair is deleting a `0644` non-credential file.

### Q-4 — blanket sweep vs targeted fix

The targeted fix (repair the two `config.json` readers only, `+2` arguments) is genuinely correct and
closes every observable defect. It was rejected because it leaves the project with **a rule that has
exceptions and therefore cannot be pinned**: two bare `read_text()` calls survive, no criterion can
state a property over the file, and the next editor must re-derive which reads are allowed to ask the
locale. The blanket sweep costs four more arguments and buys one mechanically checkable sentence plus
the assertion that keeps it true — rule 85's "delete the special case" preference, and the same
argument T-28 used when it enumerated every process-start name rather than a prefix.

### Q-14 — correct the paragraph here, or file it for T-32

- **Defer to T-32** — genuinely defensible on the pool's own ordering note, which puts the prose sweep
  last *precisely* so it can absorb the sentences the other three tasks change, and whose scope limit
  ("correct the sentences and add nothing") is the right shape for prose work. Rejected on one fact:
  the clause is vacuous at HEAD and **live** from the moment `sc config` starts reaching stdout, so
  deferral means publishing a measured-false claim about the behaviour this change introduces, for as
  long as T-32 waits. The owner's dispatch settles the direction in the same words.
- **Correct only `README.md`** — rejected on the project's language policy: the human-facing document
  of record is Chinese, both files carry the identical claim at the identical line, and a
  one-language correction leaves the more-read file wrong. Hence AC-11's "in each language" and its
  explicit FAIL for a one-language build.
- **State the escape rule once in `docs/dev-map.md`'s stream row and point both READMEs at it** —
  rejected as a new seam bought for a two-paragraph fix; that row is not wrong today (it makes no
  JSON-validity claim), so touching it is scope, not repair.
- **Selected**: the two paragraphs and nothing else. AC-11 binds the four behavioural assertions and
  leaves every word to the developer in each language; the diff clause (one hunk per file) is what
  keeps a prose correction from becoming a prose survey, which is the failure mode rule 85 names and
  the one T-32 exists to hold.

### Rejected as larger, explicitly

- **A serialization layer / document registry** ("every state file goes through one object"): the
  seam already exists (`_read_state`, `_settings_or_empty`, `_unusable`, `main()`'s arm). A registry
  would re-home four working call sites to buy nothing this requirement asks for, and it is the exact
  temptation rule 85's 「少就是多」 clause names.
- **Routing `cmd_config` / `_doctor_ipv6` through `_read_state`**: it would replace four
  purpose-written sentences with the state-document envelope's one, change `sc config`'s exit
  behaviour, and make `config.json` a state document — which `CONTEXT.md:189-196` defines it not to be.
  One argument per site is smaller and changes no sentence.
- **`json.loads(path.read_bytes())`** as the "obvious" spelling: forbidden by BC-7 — the parser
  auto-detects UTF-16/UTF-32 and would accept a document that is not UTF-8 at all (insight
  2026-08-15, proved by a UTF-16 `nodes.json`).
- **Making `settings.json` atomic, or `0600`**: a second write mechanism beside `_write_private`, and
  a mode change T-13 excluded by name and T-20 was rolled back for asserting. Declined at Q-9.
- **A repair hint in the unusable-document sentence**: one sentence serves the node store, the user's
  override and the settings document; "delete it" is wrong advice for two of the three. Declined at Q-8.

## Related work — read, not re-described

- `docs/features/_archived/state-file-io-contract/` (T-23) — the contract this task completes; its
  `01_REQUIREMENT_ANALYSIS.md` Q-1/Q-4/Q-6/Q-10 and `02_SOLUTION_DESIGN.md` I-1/I-5/I-8/K-6/K-10 are
  the seams reused here, and its RT-4/RT-6 are R-66 and FR-6's one-word choice respectively.
- `docs/features/_archived/output-layer-contract/` (T-25) — the `io.TextIOWrapper` re-wrap at
  `bin/sc:3715-3718` is what makes T-23's Q-6 ("a decode would trade a sentence for a traceback on
  strictly-encoded stdout") obsolete: stdout is no longer strict, so repairing the two `config.json`
  readers no longer buys a worse failure. This is the fact that unblocks R-76.
- `docs/features/_archived/committed-test-suite/` (T-28) — the artifact FR-9 extends, its floor
  mechanism, and its mutation discipline (a codec substitution kills, a deleted argument does not).
- `docs/features/_archived/doctor-rows-establish-their-fact/` (T-26) — the standard AC-10 is written
  against: a doctor row may not state a cause it does not have.
- `docs/features/_archived/config-write-permission-hardening/` (T-13) and
  `docs/features/_archived/sc-config-show/` (T-06) — the two contracts BC-9/BC-11 hold frozen.
- `docs/tasks.md` rows R-65 (:180), R-66 (:181), R-76 (:228) — whose "the repair's duty is to verify
  them, not to change them" holds for the clause it measured and is superseded for the JSON-validity
  clause it did not enumerate (Q-5) — R-77 (:229); R-67 (:182) for the
  init-gated-command criterion discipline; R-64 (:179) and R-73/R-81 for the boundaries this task
  does not cross.

## Insight-index entries consulted, and what each changed

- `PYTHONUTF8=0` is required for a non-UTF-8 process → NFR-6 and AC-9's proof-first clause; without it
  AC-9 and AC-10 would pass on HEAD unchanged.
- stdout was strict / stderr `backslashreplace` → superseded for stdout by T-25's re-wrap, which is
  precisely why AC-9 can demand **exit 0** rather than a survivable diagnostic.
- `json.loads` accepts `bytes` and auto-detects UTF-16 → BC-7.
- `PYTHONIOENCODING` resolves before the locale → the argument that a reader's codec must be named,
  not inferred from the writer's (Q-4, the drift record).
- Deleting `encoding="utf-8"` is invisible on a UTF-8 host; only a codec substitution kills → AC-13's
  mutation clause.
- `main()` cannot be called twice in one process; a locale criterion needs a child → AC-9's "child
  process whose harness loads the source through the mandated recipe".

## Glossary term drafted, not yet filed

FR-6 sharpens a distinction the project has been making implicitly since T-23. Following the T-23
precedent (its `state document` entry landed at **stage 2**, ledger row E-20, not at stage 1), the
entry is drafted here and filed in `CONTEXT.md` by whichever stage actually ships the behaviour:

> **regenerating run**:
> A run that composes and installs a new `config.json` — `sc reload`, `sc add`, `sc rm`, `sc use` when
> the Clash-API hot switch is unavailable, and `sc update-rules`' recovery arm. It is the boundary the
> settings document's usability is enforced at: a **reporting run** degrades to the documented
> defaults and says so once, a regenerating run refuses, because its defaults would be installed and
> become what the host runs.
> _Avoid_: write command, apply, reload path, mutating command

## Verification notes for stages 2-6 (non-binding)

- The mandated loader is `docs/dev-map.md:129-177` plus the exec-denial enumeration
  `.harness/scripts/check-sc-contracts.py:99-122`. `_init_files()` is never driven (`bin/sc:543`
  hard-codes `/var/lib/sing-box`); the fixture writes the node store through `save_nodes` directly, as
  the suite's own `fixture()` does.
- AC-5's fixture must reach `bin/sc:3391`'s `changed and CFG_PATH.exists()` **and** `gained`; with
  `SYSTEMD = OPENRC = False` the restart at `:3405` is unreachable, and R-67 requires that exclusion to
  be named in the report rather than silently satisfied.
- AC-6's denial is a `0444` settings file with the harness running non-root — the suite already
  refuses to load as root, so the denial is reliable and needs no read-only mount.
- AC-19 is AC-5's fixture with the settings document made **usable** and the fault moved to
  `override.json`, then moved again to `nodes.json`. One row, not two: `generate_config()`'s
  unusable-document failures differ only in which document the raised failure carries
  (`bin/sc:2060` `OVERRIDE_PATH`, `:2066` `NODES_PATH` through the state reader, `:2113`/`:2134`
  no document), so a second row would measure the same mechanism a second time — 「少就是多」. The
  no-document path is unreachable here: `bin/sc:2109`'s own note records that the array check cannot
  fire without an override present, so no fixture this task can run reaches it, and R-67 requires that
  exclusion named in the report rather than silently satisfied.
- AC-19's outcome-line clause is written as a **bound**, not a demand, because HEAD prints no
  run-level outcome line on this path at all — the failure leaves `cmd_update_rules()` before
  `bin/sc:3406-3420` — so demanding the line would be a new requirement over the override path rather
  than the guard FR-7 states over FR-6's refusal. What the row makes unconditional is what gate C-2
  asks for: the named document, its cause, and a non-zero exit.
- A run witness for the live host, if any command is ever run outside a fixture:
  `systemctl show -p MainPID -p NRestarts -p ActiveEnterTimestamp sing-box`, never `is-active`.
