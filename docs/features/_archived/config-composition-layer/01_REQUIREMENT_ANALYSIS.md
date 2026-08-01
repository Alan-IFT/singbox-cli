# 01 — Requirement Analysis · T-14 `config-composition-layer`

Mode: **full** · Stage 1 · Decision authority: **deferred-human** (standing grant 「你来决策就行」;
`.harness/rules/25-decision-policy.md`). Every ambiguity below is **resolved here** as a numbered
decision with its rationale and the alternative rejected. Section 8 carries no questions for the user.

---

## 1. Goal

Replace the single hardcoded configuration literal inside `generate_config()` with a composition —
a base template held as data, an ordered sequence of overlays applied to it, and a user-owned
override applied last — such that with no override present the emitted `/etc/sing-box/config.json`
is byte-identical to today's for every input state, and a user's own configuration survives
`sc reload` / `use` / `add` instead of being silently destroyed.

## 2. Why this task exists (anchored, not restated)

Two facts, both verified against the source, justify the change under
`.harness/rules/85-design-discipline.md`:

- **Four queued tasks edit one literal.** `docs/batches/default/BATCH_PLAN.md` rows T-15, T-16,
  T-17 and T-21 all modify the same dict; T-16 and T-17 both modify `dns.rules`, an array whose
  order carries meaning (the reject rule must sit after the `clash_mode` rules and before the
  routing rules — visible in the current array, `bin/sc:1019-1029`).
- **A generated artifact leaves no room for the user.** `sc reload` means "regenerate from
  `nodes.json` plus the template baked into the script" (`cmd_reload` → `reload_or_restart` →
  `generate_config`), so a hand-edit to `config.json` is discarded with no message. The user's only
  recourse today is editing `/usr/local/bin/sc`, which `install.sh` overwrites on every upgrade
  (`install.sh:487`).

Rule 85's counter-rule test — *name the future edit the refactor prevents* — is satisfied five
times: T-15, T-16, T-17, T-21, and every user customization. Any capability below that serves none
of those five is out of scope and has been cut.

## 3. In-scope behaviors

Numbered, binding, testable. "The composition" means the mechanism replacing the literal.

**B-1.** `generate_config()` builds the configuration document by composing three ordered inputs:
a base template expressed as data, zero or more overlays applied in a fixed order, and the user
override applied last. No stage other than the base introduces a literal configuration fragment.

**B-2.** The base template holds every key/value the current literal holds that does not depend on
run-time state. It ships inside `bin/sc` (see D-11).

**B-3.** Run-time-dependent content is computed and placed by the composition at exactly the
position it occupies today: the `proxy` selector object and its `outbounds` / `default`; the node
outbounds; the trailing `direct` outbound; the `route.rule_set` definition list derived from the
rule-set report; the Clash API `external_controller` address containing the resolved port; the TUN
interface name; and the rule-set file paths under the rules directory.

**B-4.** Objects merge by depth: a key present in both the accumulated document and an overlay
recurses when both values are objects; a key present only in the overlay is added; a key absent
from the overlay keeps its current value and its current position.

**B-5.** Arrays merge only under an explicit directive. The vocabulary includes `$prepend`,
`$append` and `$replace`, plus a positional form that inserts relative to a **matched existing
element** (see B-6). Directive names are reserved: an object used as a merge value may not mix a
directive key with non-directive keys.

**B-6.** The positional form names an anchor by an object pattern matched against the elements of
the target array by subset equality (every key/value in the pattern equals the element's), inserting
the given elements immediately before or immediately after the single matching element.

**B-7.** Directives are interpreted **only at merge positions** — that is, as keys of an object
being merged into a corresponding object of the accumulated document. A value being inserted
wholesale into an array is copied verbatim; its nested keys and arrays are never scanned for
directives.

**B-8.** A user override is applied through the same merge implementation as the internal overlays.
There is exactly one merge implementation in `bin/sc`.

**B-9.** The user override is user-owned: `sc` never creates it, never writes it, never rewrites it,
and never deletes it. Its content survives `sc reload`, `sc use`, `sc add`, `sc rm`, `sc mode` and
`sc update-rules`, and survives re-running `install.sh`.

**B-10.** When the override is absent, empty, or contains no directives, the emitted document is
the base plus the internal overlays and nothing else.

**B-11.** A malformed override aborts generation before anything is written (see D-1/D-2). The
message names the override path, states what is wrong in terms the user can act on, and is emitted
in both languages.

**B-12.** Before overwriting `config.json`, `generate_config()` compares the file on disk against
the record of what `sc` last generated. When they differ, it states on stderr that the file was
modified outside `sc`, that the modification is about to be replaced, and where to put the change
permanently (the override path). Generation then proceeds (see D-3).

**B-13.** The record of "what `sc` last generated" is updated whenever `config.json` is
successfully installed, and only then.

**B-14.** Per-file rule-set degradation is preserved exactly: rules referencing tags outside the
usable set are dropped from **both** `dns.rules` and `route.rules` through the single
`_filter_rules` definition, and an empty `route.rule_set` is removed rather than emitted empty.

**B-15.** `config.json` reaches disk only through `_write_private()`. No second write path for it
exists after this task.

**B-16.** All new user-facing strings ship in English and Simplified Chinese.

**B-17.** If the override mechanism is documented for users, `README.md` and `README.zh-CN.md` are
updated as a line-for-line mirror of each other.

## 4. Out of scope

**O-1.** Any change to the *content* of the generated configuration. No `urltest` group (T-15), no
DNS server/rule changes (T-16), no telemetry reject list (T-17), no rule-source profiles (T-21).
T-14 ships **zero** shipped content overlays (D-12).

**O-2.** `install.sh` (T-01/T-08/T-11/T-13) and `systemd/` (T-09). Not edited, not executed.

**O-3.** Any timeout value (`.harness/rules/50-singbox-cli.md`, BATCH_PLAN "Explicitly out of
scope").

**O-4.** A deletion directive (D-8).

**O-5.** Managing the override file's mode or ownership, and auditing it for credentials. Re-homed
to **T-20** (`doctor-extended-checks`, which already owns the permission audit and depends on
T-14), alongside the open rows R-10/R-11 in `docs/tasks.md`.

**O-6.** Surfacing drift in `sc doctor`. T-20's row already names "config drift" and depends on
T-14; T-14 provides the record it reads, nothing more.

**O-7.** Backing up or restoring a drifted `config.json` (D-3). T-13 deliberately built no backup
feature; this task does not introduce one.

**O-8.** A committed `bin/sc` test harness wired into `verify_all` (open row **R-9**). The
differential harness this task builds is a throwaway, run only by the task's developer and QA.

**O-9.** Schema validation of the merged document beyond what `sing-box check` already does.

**O-10.** Any new dependency, plugin mechanism, templating engine, or configuration language.

## 5. Boundary conditions

**Input closure of `generate_config()` — established by reading the function (`bin/sc:977-1092`):**
it reads `nodes.json` (via `load_nodes()`), the on-disk rule-set states (via `ruleset_report()`),
and the module-level values `CLASH_PORT`, `TUN_IFACE`, `RULES_DIR`. **It does not read
`settings.json`**, so the route mode (`rule` / `global` / `direct`) does not influence the emitted
bytes — `cmd_mode` persists the mode and pushes it through the Clash API only. This is what makes
the differential closure below finite and enumerable.

**BC-1.** Zero nodes: `active` is `None`, the selector's `outbounds` is `["direct"]` and its
`default` is `"direct"`. Emitted bytes unchanged.

**BC-2.** One node; several nodes. Node order in `outbounds` follows `nodes.json` order.

**BC-3.** `active` naming a tag absent from the node list: the function rewrites `nodes_data`
and calls `save_nodes()` **before** building the document. This side effect and its ordering are
preserved. `save_nodes()` exits the process on write failure (open row **R-12**) — unchanged.

**BC-4.** A node whose tag or fields contain non-ASCII characters: emitted verbatim, unescaped
(`ensure_ascii=False`). A refactor that escapes them produces valid JSON with different bytes and
fails the gate.

**BC-5.** All 16 usable/unusable rule-set subsets (4 files, `bin/sc:70-75`). At the all-unusable
end, `route.rule_set` is deleted, both rule arrays are filtered, and the "degraded to no-splitting
mode" warning is emitted; at the all-usable end nothing is dropped.

**BC-6.** Each non-usable *status* (`absent`, `bad-magic`, `too-small`, `unreadable`) produces the
same configuration bytes as any other non-usable status for the same file, because only
`status == "usable"` is consulted.

**BC-7.** Override absent → identical to no override. Override present but an empty document
(`{}`), or an empty fragment directory → identical to absent.

**BC-8.** Override that is not valid JSON, is not a JSON object at the top level, exceeds a
readable size, or is not decodable as UTF-8 → malformed (D-1).

**BC-9.** Override path that is a directory, FIFO, device, or any non-regular file after symlink
resolution → malformed. A symlink resolving to a regular file is accepted (D-14). The FIFO case is
the load-bearing one: an unguarded read would hang the CLI indefinitely.

**BC-10.** Override unreadable (permission, I/O error) → malformed, with the OS cause rendered
through `_plain()` as `save_nodes` / `generate_config` already do.

**BC-11.** Override containing a bare array at a path where the base holds an array → error naming
the available directives (D-5). Override containing a bare array at a path absent from the base →
accepted, creates the key (D-6).

**BC-12.** Positional anchor matching zero elements, or matching more than one → error naming the
anchor and the count (D-7). An overlay that silently does nothing is the failure mode T-16 and T-17
cannot tolerate.

**BC-13.** Directive applied to a non-array (`$append` where the base value is an object or a
scalar) → error.

**BC-14.** Unknown key beginning with the directive sigil → error, not a silently accepted literal
key.

**BC-15.** An override that removes or renames what `sc` itself depends on
(`experimental.clash_api.external_controller`, the `proxy` outbound tag) produces a configuration
that `sing-box check` may still accept while `sc use` / `sc status` stop working. T-14 does not
prevent this; the documentation states it. Rationale: preventing it requires a schema of "what `sc`
depends on", which serves none of the five nameable edits.

**BC-16.** Drift record absent (every host upgrading from a pre-T-14 build) → treated as *unknown*,
**no** drift warning; the record is created on the next successful generation (D-4).

**BC-17.** `config.json` absent → no drift warning; this is a fresh install.

**BC-18.** Drift detected during `install.sh` step 7: `sc reload`'s streams are redirected to the
install log (`install.sh:590`), so the warning lands in `/var/log/sing-box/install.log` rather than
on screen. Accepted; the installer's own banner and exit derivation are unaffected.

**BC-19.** A malformed override during `install.sh` step 7 sets `PHASE_CONFIG=failed`, so the
installer reports a failed install and points at `sc reload`. This is the honest outcome and
requires no installer change.

**BC-20.** `generate_config()` invoked more than once in one process produces identical output each
time. The base template and any overlay data must not be mutated by composition — note that
`_filter_rules` mutates surviving rules **in place**, which is harmless today only because the
literal is rebuilt on every call.

**BC-21.** `nodes.json` is byte-unchanged by a generation whose `active` is already valid, with or
without an override present. The node objects reach `outbounds` from `load_nodes()`; composition
must not mutate them.

**BC-22.** The emitted document carries **no trailing newline**
(`_write_private(CFG_PATH, json.dumps(config, indent=2, ensure_ascii=False))`).

**BC-23.** Key order in the emitted JSON is insertion order. On the documented Python 3.6 floor this
relies on CPython's ordered `dict`; it is an implementation detail there and a language guarantee
from 3.7. No `OrderedDict` is required, but a composition that reorders keys fails the gate.

**BC-24.** `sing-box check` failure behaviour is unchanged: one translated stderr warning and
`return False`, never a traceback.

**BC-25.** `OSError` from `_write_private()` is unchanged: one translated stderr line naming the
path and cause, and `return False`.

**BC-26.** Nothing is written, and no override is read, at import time or during `sc doctor`.
`_init_files()` stays below `parse_args()` and `doctor` keeps the read-only arm (T-05).

## 6. Acceptance criteria

Each is independently verifiable. **AC-1 is the gate**: it is built first, it governs the refactor,
and no later criterion may be satisfied by weakening it.

### The hard gate

**AC-1 — Byte-identical output with no override, over the full input closure.** For every point in
the cross product below, the bytes written to `config.json` by the new build equal the bytes written
by the pre-change build, compared byte-for-byte:

- **16** rule-set usability subsets (4 files × usable / not-usable), ×
- **4** node/active states: (a) no nodes, `active` null; (b) one node, `active` = that node;
  (c) three nodes, `active` = the second; (d) three nodes, `active` naming a tag not in the list
  (the rewrite path of BC-3),

= **64 runs minimum**, each byte-compared. Plus, layered on state (c): one run with a non-ASCII
node tag (BC-4), one run per non-usable status (`absent` / `bad-magic` / `too-small` / `unreadable`,
BC-6), one run with a `CLASH_PORT` other than the base, and one run with a rules directory path
other than the default.

**AC-2 — The oracle is the pre-change source, not the installed binary.** The baseline is
`bin/sc` at the task's starting commit, obtained from the repository (e.g. a pristine clone or
`git show`). `/usr/local/bin/sc` is an older, divergent build and is never used as an oracle
(`.harness/insight-index.md`).

**AC-3 — The differential also covers the streams and the return value.** For each AC-1 run, stderr
bytes (including the degradation warning) and the boolean return value match the baseline, in both
`en` and `zh`.

**AC-4 — Non-vacuity.** The differential harness is demonstrated to FAIL when a deliberate
one-character change is made to the emitted document (e.g. a reordered key or an altered value), and
the demonstration is recorded.

### Structure

**AC-5** — The configuration literal no longer exists as a single expression inside
`generate_config()`; the base template is a named module-level data object.

**AC-6** — Exactly one merge implementation exists, and the user override is applied through it
(deletion test: removing the internal-overlay call site leaves the override path working through the
same function).

**AC-7** — `bin/sc` remains a single self-contained file: `install.sh`'s artifact list
(`install.sh:412-417`) is unchanged and a host installed via `curl | bash` obtains a working
template with no additional file.

**AC-8** — `_filter_rules` remains the single definition of "drop dangling rule-set references" and
is still called for both `dns.rules` and `route.rules` with the same usable set. It gains no
array-name parameter (`docs/dev-map.md`).

**AC-9** — The observable ordering is unchanged: the document is fully composed and filtered, the
degradation warning is written, the file is written, then `sing-box check` runs. A different
internal ordering is admissible only if the observable sequence and bytes are identical.

**AC-10** — `_write_private()` is the only writer of `config.json`; a repository-wide search finds
no other write, `open(..., "w")`, or `write_text` targeting it.

**AC-11** — Repeated `generate_config()` calls in one process yield identical bytes (BC-20), proven
by three consecutive calls in the harness.

**AC-12** — `nodes.json` is byte-unchanged across a generation whose `active` is valid, with and
without an override (BC-21).

### Override semantics

**AC-13** — Object deep-merge: an override setting one leaf key inside `log` leaves every other key
of `log`, and its position, unchanged.

**AC-14** — `$replace` on `dns.rules` yields exactly the override's array.

**AC-15** — `$prepend` / `$append` on `route.rules` yield the override's elements at the front /
back, with the base elements in their original order.

**AC-16** — Positional insertion places an element immediately after the element matched by the
anchor, with every other element's relative order preserved. Demonstrated on `dns.rules` with an
anchor matching the `clash_mode: Direct` rule — the T-16/T-17 shape.

**AC-17** — Two overlays inserting into the same array compose: applying overlay A then overlay B
yields both insertions, each at its anchor, with no index arithmetic performed against the base.

**AC-18** — A value inserted into an array is copied verbatim: an inserted rule containing a nested
array (e.g. `rule_set` or `domain_suffix`) is emitted unchanged and its nested keys are not
interpreted as directives (B-7).

**AC-19** — A bare array where the base holds an array is rejected with a message naming
`$prepend`, `$append` and `$replace`; a bare array at a key absent from the base is accepted.

**AC-20** — Every error case in BC-8 … BC-14 produces: no write to `config.json` (the previous file
is byte-identical afterwards), a non-zero exit from the invoking command, and a message naming the
override path and the specific problem.

**AC-21** — With a malformed override, the running `sing-box` service is not restarted and not
reloaded (no *service-affecting action*), because the failure precedes the write.

### Drift

**AC-22** — With `config.json` hand-modified after a successful generation, the next `sc reload`
prints the drift statement on stderr **before** the file is replaced, and the statement names the
override path.

**AC-23** — With `config.json` byte-identical to the last generated document, no drift statement is
printed.

**AC-24** — With no drift record on disk (BC-16), no drift statement is printed and the run creates
the record.

**AC-25** — The drift record does not place a second copy of credential bytes on disk unless that
copy is installed through `_write_private()` at mode `0600`.

**AC-26** — `sc doctor` writes nothing: run against a fixture root with a hand-modified
`config.json`, a malformed override and no drift record, the fixture tree is byte-identical
afterwards (T-05's read-only property, extended over the new artifacts).

### Bilingual & documentation

**AC-27** — Every new user-facing string has an entry in the `zh` table of `TRANSLATIONS` with the
same placeholder set, and no new `zh` string contains the substring `失败：`, which is a load-bearing
diagnostic grep meaning "this file was not updated" (`.harness/insight-index.md`).

**AC-28** — Every new `t()` key is readable English prose (`bin/sc` has no `en` table, so the key is
the English rendering) and no namespaced key such as `ls.idx` is added.

**AC-29** — If the override is documented, `README.md` and `README.zh-CN.md` gain the same sections
in the same positions, including the file-locations table row.

**AC-30** — `.harness/scripts/verify_all` PASSes, with no new FAIL relative to a pristine clone of
the starting commit. B.1 (`python3 -m py_compile bin/sc`) is a real gate and must pass.

## 7. Non-functional requirements

**NFR-1 — Harness safety (non-negotiable).** `bin/sc` auto-elevates at import time by re-exec'ing
the **installed** `/usr/local/bin/sc` under `sudo`, and `sudo`'s `env_reset` drops environment
overrides — an un-neutralised import runs the *installed older* tool against the *live* service.
Every harness and throwaway script for this task must use the neutralisation recipe in
`docs/dev-map.md` ("Patterns to avoid") verbatim, repoint `CFG_DIR` / `CFG_PATH` / `NODES_PATH` /
`SETTINGS_PATH` / `RULES_DIR` into a `mkdtemp()` root, set `SYSTEMD = OPENRC = False`, and never
drive `_init_files()` (it hard-codes `/var/lib/sing-box` as a `Path` literal). **Nothing under
`/etc` is written on this machine.** The service witness is
`systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`, never `is-active` — baseline
`MainPID=2887037`, `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`, to be reported identical at
every checkpoint.

**NFR-2 — No new dependency.** Standard library only; no plugin system, no schema language, no
templating engine, no new file format beyond JSON, which the project already parses.

**NFR-3 — Python 3.6 syntax floor.** No walrus, no `dataclasses`, no `capture_output=`, no
`unlink(missing_ok=)`. The three pre-existing `capture_output=` sites are a separate pool row and
are not fixed opportunistically.

**NFR-4 — Credential confidentiality.** The merged document contains node credentials and is a
*credential document*: it is mode `0600` at every instant it holds content, via `_write_private()`.
Nothing this task adds may write it, copy it, or log its content.

**NFR-5 — Cost.** Composition adds no network call, no subprocess, and no measurable latency to
`sc use` / `sc reload`; the document is a few hundred JSON nodes.

**NFR-6 — Compatibility.** The upgrade path is re-running `install.sh`, which must remain
idempotent and must not require the user to do anything for existing hosts (BC-16 is what makes
that true).

**NFR-7 — Non-TTY output contract.** The new drift and error messages carry no carriage return and
no intermediate state: one complete line per fact, since `sc reload` output is captured into
`/var/log/sing-box/install.log`.

## 8. Decisions taken under standing authority

Recorded as decisions, not questions. Each names the rejected alternative.

**D-1 — A malformed override blocks generation; it does not fall back to the base.** Generation
aborts, `config.json` is left byte-identical, the command exits non-zero, and the message names the
file and the fault. *Rejected: ignore the override and emit the base with a warning* — that produces
a valid configuration silently missing the user's intent, restarts the service with it, and the
warning is invisible when `sc reload` runs from `install.sh`. The whole task exists because the
user's configuration is silently discarded; a fallback re-creates that defect inside the fix. The
failure is recoverable without the tool (edit or delete one file) and the service keeps running on
the last good configuration.

**D-2 — The override is parsed and merged before anything is written.** *Rejected: validate after
writing, like the existing `sing-box check`* — today a syntactically valid but semantically broken
document does reach disk before `check` rejects it; extending that pattern to a user-supplied input
would let a typo install a broken document that the next service restart loads.

**D-3 — Drift is a loud warning that does not block, and nothing is backed up.** *Rejected (block):*
a drifted host could no longer switch nodes or re-run `install.sh` — the user would be locked out by
a diagnostic. *Rejected (auto-backup):* it creates a second on-disk copy of credential bytes, T-13
deliberately built no backup feature, and open row R-10 records that hand-made backups are already
an unowned hazard.

**D-4 — An absent drift record means "unknown" and prints nothing.** *Rejected: treat absent as
drift* — it fires on 100% of existing installs at the first upgrade, training users to ignore
exactly the warning that must stay loud.

**D-5 — A bare array where the base holds an array is an error.** *Rejected: RFC 7386 semantics
(bare array replaces).* The failure it produces — a user writing one `dns.rules` entry to *add* it
and silently getting a one-rule DNS section — is a valid configuration that misroutes traffic and
passes `sing-box check`. An error naming the three directives costs one line of typing and cannot be
misread.

**D-6 — A bare array at a key absent from the base is accepted and creates the key.** There is no
base array to be ambiguous about. This keeps the override usable for sing-box options this project
does not emit.

**D-7 — Positional insertion is anchor-based, matching exactly one element; zero or multiple matches
is an error.** *Rejected: numeric index.* Indices are computed against the base and become wrong as
soon as an earlier overlay inserts — precisely the T-16-then-T-17 case. The constraint the domain
states is semantic ("after the `clash_mode` rules, before the routing rules"), not numeric.

**D-8 — No deletion directive.** None of the five nameable consumers needs one; `$replace` expresses
element removal at array level. *Rejected: `$delete`, and null-means-delete* — the latter also makes
it impossible to set a key to JSON `null`.

**D-9 — Directives are interpreted only at merge positions (B-7).** *Rejected: scan inserted values
too* — it would corrupt any legitimate configuration value whose key happens to start with the
sigil, and inserted elements are content, not instructions.

**D-10 — The user override is the last overlay, applied by the same merge implementation.**
*Rejected: a separate user-override merge path* — two merge implementations is the duplicated-
judgment seam rule 85 forbids, and it would leave the overlay mechanism with no exercised consumer
in T-14 (which ships no content overlays), i.e. untested machinery.

**D-11 — The base template ships inside `bin/sc`.** This is scope-derived, not a design preference:
`install.sh` fetches an enumerated artifact list (`install.sh:412-417`) and is explicitly out of
scope, so a separate shipped file would be missing on every `curl | bash` install. The architect
still chooses its *representation* (Python literal, embedded JSON string, or other).

**D-12 — T-14 ships zero content overlays.** The overlay list is legitimately empty or contains only
the computed run-time overlays of B-3; behaviour change is entirely T-15/T-16/T-17's. *Rejected:
land one small overlay to "prove" the mechanism* — it breaks AC-1, and a structural change that also
changes behaviour cannot be reviewed.

**D-13 — The override file's mode and ownership are not managed by `sc`; re-homed to T-20.**
*Rejected: chmod it on read* — `sc` writing a user-owned file contradicts B-9, and T-13's precedent
is that a mode sweep belongs to the installer, not to a read path.

**D-14 — A symlinked override resolving to a regular file is accepted; a non-regular target is
malformed.** *Rejected: refuse all symlinks* — users legitimately symlink configuration into a
version-controlled directory, `/etc/sing-box` is root-owned and not world-writable, and the real
hazard is the FIFO/device hang, which the regular-file check closes.

**D-15 — The differential compares streams and return value, not only the configuration bytes.**
*Rejected: bytes only* — a refactor that moved `_warn_degraded` relative to the write would pass a
bytes-only gate while changing observable behaviour.

**D-16 — Handed to the Solution Architect, with the trade-off written out:** the override's
**location and shape** — a single `/etc/sing-box/override.json` versus a `conf.d/*.json` fragment
directory. Single file: one path to document, one parse, trivially "does it exist"; but two
independent customizations (the user's and, later, a profile shipped by T-21) collide in one file.
Fragment directory: composable and lets T-21 drop in a profile without touching the user's file; but
it needs a deterministic ordering rule (lexicographic by filename), doubles the "what is malformed"
surface, and `uninstall.sh` already removes `/etc/sing-box/` wholesale either way. **Binding
constraints on whichever is chosen:** ordering is deterministic and documented; empty is identical
to absent (BC-7); every fragment goes through the one merge implementation (B-8); and the path is
named in both READMEs and in the drift message.

## 9. Related work

| Task | Where | What it binds here |
|---|---|---|
| T-02 `config-degrade-missing-rulesets` (`ab4e4a4`) | `docs/features/config-degrade-missing-rulesets/` | The usable-rule-set model, `_filter_rules` for both arrays, the empty-`route.rule_set` deletion, the 16-subset closure. B-14, AC-8, BC-5/BC-6. |
| T-05 `sc-doctor` | `docs/features/_archived/sc-doctor/` | `doctor` is strictly read-only; `_init_files()` sits below `parse_args()`. BC-26, AC-26. |
| T-10 `ruleset-update-no-needless-restart` (`90ad762`) | `docs/features/_archived/ruleset-update-no-needless-restart/` | `ruleset_state()` digests and apply-once semantics; regeneration on `gained` inside `cmd_update_rules`. Must keep working unchanged. |
| T-13 `config-write-permission-hardening` (`629be49`) | `docs/features/_archived/config-write-permission-hardening/` | `_write_private()` is the single definition of installing a credential document. B-15, AC-10, NFR-4, AC-25. |
| T-15 / T-16 / T-17 / T-21 | `docs/batches/default/BATCH_PLAN.md` | The five nameable future edits that justify the refactor; T-16/T-17 are why insertion is anchor-based (D-7). |
| T-20 `doctor-extended-checks` | same | Consumes the drift record and owns the permission audit. O-5, O-6. |
| Open rows R-9 (committed harness), R-10/R-11 (credential modes), R-12 (`save_nodes` exit) | `docs/tasks.md` | Explicitly not closed here; O-8, O-5, BC-3. |
| Rejected decisions `shared-atomic-write-helper-with-ruleset-downloader`, `shared-singbox-check-wrapper` | `.harness/rejected-decisions.md` | Do not re-litigate: no shared write helper, no `sing-box check` wrapper. |

## 10. Evidence

Backward-looking citations, valid at the starting commit:

- `bin/sc:977-1092` — `generate_config()`; the configuration literal begins at `bin/sc:1001`; it
  reads only `load_nodes()` and `ruleset_report()` plus `CLASH_PORT` / `TUN_IFACE` / `RULES_DIR`,
  and never `load_settings()`.
- `bin/sc:1019-1029` — `dns.rules`, showing the semantic order (`clash_mode` rules, then the
  predefined answer, then the rule-set-driven routing rules).
- `bin/sc:1073-1077` — the empty-`route.rule_set` deletion, the two `_filter_rules` calls, and
  `_warn_degraded`, all after the literal is built.
- `bin/sc:1081` — `_write_private(CFG_PATH, json.dumps(config, indent=2, ensure_ascii=False))`, i.e.
  no trailing newline and `ensure_ascii=False`.
- `bin/sc:816-844` — `_filter_rules` mutates surviving rules in place.
- `bin/sc:70-75` — `RULESET_FILES`, four entries → 16 subsets.
- `bin/sc:88-89` — the import-time `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + …)`.
- `bin/sc:312-361` — `_write_private()`'s three guarantees.
- `bin/sc:1615-1624` — `cmd_mode` persists the mode and pushes it via the Clash API; it never
  regenerates, which is why route mode is outside AC-1's closure.
- `install.sh:412-417` — the enumerated artifact list; `install.sh:487` — `install -m 755 … sc`;
  `install.sh:590` — step 7 runs `sc reload` with streams redirected to the install log.
- `docs/batches/default/BATCH_PLAN.md:63-82` — the restructuring note naming the five future edits.

## 11. Verdict

**READY.**

No open questions: every ambiguity is resolved in section 8 under the standing decision grant, and
no safety red line was reached (nothing in this task requires writing under `/etc` or touching the
running service).

**For the Solution Architect:** the one decision deliberately left open is **D-16** — the override's
location and shape — with its trade-off and its binding constraints written out. Everything else is
settled. Build **AC-1** (the 64-run differential against the pre-change source, with AC-4's
non-vacuity proof) before the refactor; it is the criterion the whole task is measured by, and no
structural choice that cannot satisfy it is admissible.

---

## 12. Addendum A — stage 1′ (scoped rollback from stage 6)

Raised by `06` MAJOR **D-1**. Nothing above is rewritten, renumbered or withdrawn; this addendum
adds **BC-27**, **AC-31**, **D-17**, **O-11**, **O-12** and continues the existing sequences.
Verdict for the addendum: **READY** — no open questions, decided under the standing grant.

### 12.1 The BC-7 / BC-9 seam: a dangling symlink

**BC-27.** An override path whose final component is a **symbolic link whose target does not
exist** (directly, or through a chain of links) is **malformed**, not absent. Generation aborts
under D-1's rules: nothing is written, the command exits non-zero, and one line names the override
path and states that it is a symbolic link whose target is missing. Naming the target is permitted,
not required. A path with **no filesystem entry at all** remains **absent** (BC-7 is unchanged), and
a symlink resolving to a regular file remains accepted (D-14 is unchanged). The ruling covers the
final path component only; a missing or broken *parent* directory component remains absent.

**AC-31.** With a dangling symlink at the override path, the run satisfies AC-20's three guarantees
verbatim (no write to `config.json` — the previous file byte-identical afterwards; non-zero exit
from the invoking command; a message naming the override path and the specific problem) and AC-21
(no service-affecting action). Second clause, and the one that protects AC-1: with **no** filesystem
entry at the override path, the same code arm returns "absent" silently — no message, no non-zero
exit, no extra output on any stream.

**D-17 — A dangling symlink is malformed; "absent" is reserved for the absence of user intent.**
The discriminator BC-7 already uses is *can this shape encode a typo?* BC-7 admits empty and
whitespace-only as absent because `touch override.json` states "nothing yet" and whitespace cannot
encode a mistake. A symlink is the opposite: it is an affirmative act naming a target path, and a
**mistyped or moved target is exactly a typo**. `sc` never creates, writes or deletes this file
(B-9), so a link at that path can only have been placed there by the user — treating it as "the user
expressed no override" contradicts the observable fact that the user expressed one. *Rejected: treat
it as absent (the shipped behaviour).* It reproduces, inside the fix, the failure `01` §2 names as
the task's reason for existing — a user's configuration silently discarded, `exit 0`, and no drift
warning either because `sc` itself generated the replacement. *Rejected: warn and continue with the
base.* D-1 already ruled that shape out for every other malformed case, and the warning is invisible
when `sc reload` runs from `install.sh` (BC-18).

**On the `bin/sc` precedent (`ruleset_state`, the comment "A dangling symlink does not exist, but it
is broken rather than absent", `bin/sc:733-734`): corroborating, not decisive.** Read on its own it
is answerable — `ruleset_state` classifies a *downloaded artifact* under a digest contract where
`unreadable` also means "no digest exists", which is a different question from "did the user ask for
an override". The decisive argument is the intent argument above, which stands with no precedent at
all. What the precedent *does* decide is the tie-break: leaving the two opposite would put two
functions in one file holding contradictory opinions about the same filesystem shape, with the newer
and less-considered one winning — the duplicated-judgment seam `.harness/rules/85-design-discipline.md`
exists to prevent. Consistency is the reason not to hesitate; it is not the reason to rule.

**Rule 85, first edge — the consumer.** BC-27 serves **user customization**, one of the five
nameable consumers, on the workflow D-14 deliberately blessed: an override symlinked into a
version-controlled directory, broken by a branch checkout, a `git clean`, or an unmounted dotfiles
repo.

### 12.2 Blast radius

**AC-1 is untouched, and this addendum does not narrow it by one byte.** Verified rather than
assumed: AC-1's closure never places any entry at the override path, so no symlink exists in any of
its 64+ points. The arm BC-27 amends *is* entered on every AC-1 run (no entry → the not-found path),
which is why AC-31's second clause is binding: the not-a-symlink outcome must stay a silent
`absent`, adding no stream output and no return-value change. One extra `lstat`-class syscall on
that path is immaterial to NFR-5. `06`'s 164-run differential is the regression proof and must be
re-run green; it may not be relaxed, re-scoped, or re-baselined to accommodate the fix.

**BC-16 / BC-17 (drift): unchanged.** The override is read before composition and therefore before
the drift comparison, the write and the record update; the abort precedes all three. "Absent record
⇒ silent, record created" and "`config.json` absent ⇒ silent" are untouched. The one observable
change is at the defect's own fixture: it goes from *config replaced + record updated + no warning*
to *nothing written, nothing recorded, one error line*.

**BC-19 (install path): covered by its existing text, with no installer change.** A dangling symlink
during `install.sh` step 7 is now a malformed override, so BC-19 applies unmodified —
`PHASE_CONFIG=failed`, the installer reports a failed install and points at `sc reload`. This is a
real behaviour change for a host whose link target is unavailable at install time, and it is the
intended one: a failed banner the user can act on, instead of a successful install that silently
discarded their configuration. Recovery cost is the same as every other malformed case under D-1 —
restore the target or remove one file. O-2 holds: `install.sh` is not edited and not executed.

**AC-20 / AC-21: strengthened, not weakened.** AC-20's enumeration reads "BC-8 … BC-14" and BC-27
sits outside that range, which is why AC-31 exists rather than an edit to AC-20. Both criteria keep
their existing scope and wording.

**Not touched:** AC-5 – AC-19, AC-22 – AC-30, BC-1 – BC-26, every NFR, O-1 – O-10, D-1 – D-16.

### 12.3 Routing — one name: **developer**

The solution-architect is **not** required.

1. `02` §5.4's step *order* does not change. The stat-before-open ordering — the guard that stops a
   FIFO hanging the CLI — is untouched; the discrimination happens entirely inside the existing
   first step's failure arm, before any `open()`.
2. D-14's *rationale* does not change and is not contradicted. D-14 blessed a symlink resolving to a
   regular file and rejected a non-regular target. A link resolving to **nothing** was never inside
   D-14's grant; it was unenumerated, which is the requirement gap this addendum closes.
3. No design surface moves: no new component, no new call site, no interface or ordering change, no
   new data structure, no new dependency. The error channel BC-27 uses — abort with one
   already-translated problem sentence naming the path — is the channel `02` §5.4 designs in its
   opening paragraph and already carries eight members. Adding a ninth member to a designed set is
   implementation, and its wording is governed by B-11, B-16, NFR-7, AC-27 and AC-28, all of which
   already exist and all of which QA already tests.
4. The line `FileNotFoundError -> None (absent)` in `02` §5.4 is a faithful derivation of BC-7 and
   BC-9 as they stood; the architect had no third classification to derive because `01` gave none.
   Correcting the requirement removes the input that produced that line. The design's stated intent —
   every override shape `sc` cannot honour becomes a one-line actionable abort before any write — is
   served by the fix, not overruled by it.

Because downstream cannot edit upstream (`.harness/rules/00-core.md`), `02` §5.4 will retain a line
superseded by BC-27. The developer records this in `04` as a deviation from `02` §5.4 citing BC-27 /
D-17 / AC-31, which is the standing mechanism for a requirement-driven divergence and is what stage 5
reviews against. A stage-2 rollback for one branch in one function would cost a full design revision
on a 637-line document to change one pseudo-code line and add one error key.

### 12.4 Scope rulings on the two MINOR (`06` D-2 and D-3)

**O-11 — MINOR-A (deep nesting ⇒ `RecursionError` traceback): out of T-14.** Re-homed to a new open
row **R-15** in `docs/tasks.md`, which carries the whole family and lists both instances: `06` D-2
(500-level nesting ⇒ 2 999-line traceback via `copy.deepcopy`) and `05` MINOR-1 (a non-object element
in `dns.rules` ⇒ `AttributeError`). It is **not** separable from MINOR-1 on the reasoning that
matters: the gate's mechanical reason for excluding MINOR-1 (any fix touches `_filter_rules`, pinned
by AC-8) does not apply here, but the governing reason does — both are one defect stated twice,
*"an override shape outside BC-8 … BC-14's enumeration reaches the user as a Python traceback instead
of a sentence"*, and its coherent fix is a single exception envelope over the override pipeline, i.e.
a change to `02`'s error model that needs the architect. A per-shape depth counter in the merge would
patch this instance and leave the family open, which is the wrong trade. The instance is contained —
no write, no service-affecting action, non-zero exit — and its trigger is a pathological document, so
carrying it as a named row costs nothing that a rushed T-14 patch would not cost more.

**O-12 — MINOR-B (a bare object silently replaces an existing array): out of T-14.** Re-homed to a
new open row **R-16**, to be resolved by whichever of T-15 / T-16 / T-17 / T-21 first needs the
vocabulary. D-5's rationale does not extend to the mirror: D-5 made the array case an error because
the wrong result is *valid, passes `sing-box check`, and misroutes traffic silently and
indefinitely*. `06` measured the mirror and that premise is false — the real `sing-box` 1.13.15
rejects it (`rc=1`), `generate_config()` returns `False`, `sc reload` fails loudly in the same
invocation, and the service is never restarted. Symmetrising the merge's type policy is a semantic
change to the one merge implementation, serving no consumer that is not already told the truth by
the binary. No README change in T-14 (O-1, AC-29's parity is already discharged); R-16 carries the
documentation obligation with the fix.

### 12.5 Addendum evidence

Backward-looking, verified at the current working tree:

- `bin/sc:1279-1282` — `_load_override()`'s `os.stat` / `except FileNotFoundError: return None` arm;
  the classification BC-27 corrects.
- `bin/sc:1269-1273` — the docstring stating the stat-before-open ordering and D-14's accepted case,
  which BC-27 leaves intact.
- `bin/sc:732-734` — `ruleset_state()`: `if not path.exists(): return ("unreadable", …) if
  path.is_symlink() else ("absent", …)`, with the comment *"A dangling symlink does not exist, but it
  is broken rather than absent."*
- `02_SOLUTION_DESIGN.md:246` — `FileNotFoundError -> None (absent)`; `:261` — D-14's restatement.
- `06_TEST_REPORT.md:297-354` — the MAJOR, with `rv=True`, `stderr=''`, config replaced, `exit=0`;
  `:358-399` and `:403-431` — the two MINOR with their measurements.
- `.harness/insight-index.md:29` — T-13's measured symlink hazard at `config.json`; the project has
  already paid once for treating a planted link as an ordinary path.
