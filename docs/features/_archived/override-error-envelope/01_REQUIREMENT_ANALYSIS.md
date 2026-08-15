# 01 — Requirement Analysis · T-24 `override-error-envelope`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

Every way the user's `override.json` can fail to produce an emitted configuration document must end
as one complete named line, a non-zero exit and no write — today two classes end as a Python
traceback and one class ends as a silently replaced array whose broken document reaches disk.

## In-scope behaviors

**FR-1** — Any exception raised while `sc` reads, parses or applies the user's override document is
rendered as one complete line through the single existing rendering arm, and the command exits
non-zero. No traceback reaches any stream. The rendered line names the override path and carries a
clause identifying the fault; it is never the bare generic outcome line of the invoking command.

**FR-2** — The enveloped region covers the whole path from the override document's bytes to the
emitted document: the load and parse of the override file, the merge of the override into the
composed document, and every step between the merge and the write of `config.json` whose input
includes override-supplied content. A failure anywhere in that region satisfies FR-1.

**FR-3** — A key whose current value in the composed document is an array accepts exactly one kind
of overlay value: a directive object from the directive vocabulary. Any other overlay value at that
key — an object, a scalar, a JSON `null`, or a bare array — is an error naming the directives, and
it is the same sentence for all of them. A key whose current value is not an array is unchanged by
this requirement.

**FR-4** — Provenance is decided by whether the user supplied an override, not by the class of the
exception. When an override document is present, the rendered line names the override path; when
none is present, the same failure names `config.json`. No failure is ever attributed to a document
the user did not supply.

**FR-5** — When the override document is absent, empty or whitespace-only, the emitted document and
every stream is byte-identical to the pre-change build in every settings and rule-set state.

**FR-6** — Both READMEs state the rule FR-3 establishes, in the section that already documents the
directives, and in both languages at the same relative position. The standing sentence in both
READMEs that an override which cannot be applied stops the command before anything is written, leaves
`config.json` exactly as it was and names the file and the problem, is true after this task for the
whole malformed set defined in BC-1.

## Out of scope

1. No schema language, no validator, no new error taxonomy, and no exception class hierarchy — the
   existing single unusable-document exception and its single rendering arm are reused.
2. No depth cap, no node-count cap and no new size cap on any document; `OVERRIDE_MAX_BYTES` is
   unchanged.
3. `_filter_rules()` is not touched — not its body, not its signature, not its call sites (T-14 AC-8).
4. The composed-document array assertion is not widened; gating it narrower is in scope (FR-4), and
   widening it is forbidden (R-15).
5. Type mismatch at a key whose current value is an **object** (an overlay scalar or array replacing
   an object) is not changed; only the array position gets the vocabulary.
6. The credential-masking walk used by `sc config` is not enveloped and gains no cap (R-44 stays open).
7. `_load_override()` and the state-document reader are not collapsed into one reader (R-69).
8. The missing run-level outcome line of `sc update-rules` is not added (R-12 stays open).
9. No change to which side effects precede an abort: the stale-selection repair of `nodes.json` and
   `sc add`'s persistence of the new node keep their pinned ordering.
10. No new command, no new setting, no new file under `/etc/sing-box`.

## Boundary conditions

**BC-1** — The malformed set this task is measured over is exactly: **M0** an override deep enough
that the JSON parse itself overflows; **M1** an override deep enough that the merge's deep copy
overflows; **M2** a non-object element inserted into `dns.rules`; **M3** a non-object element
inserted into `route.rules`; **M4** an object at a key whose current value is an array; **M5** a
scalar at such a key; **M6** a JSON `null` at such a key; **M7** an object whose only key is
index-like (`"0"`) at such a key. Every member satisfies FR-1.

**BC-2** — For every member of BC-1: `config.json` is byte-identical after the run to before it, the
drift record is byte-identical, and no `sing-box` invocation and no service-affecting action occurs.
`nodes.json` may differ only by the stale-selection repair T-14 pinned.

**BC-3** — Combined stdout and stderr for a member of BC-1 is **exactly one line**. A fix that turns
2 999 lines into 40 has not satisfied this requirement. The stream is redirected into
`/var/log/sing-box/install.log` by the installer, which consumes one complete line per fact.

**BC-4** — No sentence introduced or newly reachable by this task contains any value taken from the
override document. Naming a type, a dotted position, a key name or a directive name is permitted;
echoing a value is not. `verify_all` A.1 (no hardcoded secrets) stays PASS.

**BC-5** — `_write_private()` remains the only writer of `config.json`, and credential bytes never
exist at a mode wider than `0600` at any instant (T-13). The drift record remains a sha256 digest of
the file's bytes and never a copy of them (T-14).

**BC-6** — The unusable-document exception keeps its `path` attribute and the single rendering arm
keeps honouring it. The arm is never narrowed back to the user's override: it serves the state
documents too. If the class is renamed or re-parented, the state-document factory is the one
construction site that moves with it (R-69).

**BC-7** — There is no call-graph edge from directive application back to the merge. A new envelope
must not create one: "directives are interpreted only at merge positions" is structural, not
remembered (T-14 B-7).

**BC-8** — The process recursion limit is never raised, and no change makes a document mergeable that
is not mergeable today. The merge's deep copy overflowing at roughly half the depth the masking walk
does is currently the only thing that keeps R-44's failure unreachable through `override.json`;
raising the limit or removing the copy would open it.

**BC-9** — No override document that today yields a `config.json` the real `sing-box check` accepts
changes behaviour. The published override recipes in both READMEs keep working unchanged.

**BC-10** — Every new user-facing string ships in both languages: the key is a readable English
sentence (there is no `en` table, so the key renders verbatim in English), with a `zh` entry carrying
identical placeholders. No new string contains `失败：` — it is a load-bearing diagnostic grep. Keys
are prose, never namespaced.

**BC-11** — With an override present, `sc` cannot distinguish "this document broke the merge" from "a
defect in the merge broke on this document" without a taxonomy this task does not build, so the line
names the override. The fault-identifying clause required by FR-1 is what keeps such a defect
reportable; a line that states only "your override is wrong" does not satisfy FR-1.

**BC-12** — Safety, binding on every stage: an un-neutralised import of `bin/sc` re-execs the
**installed** `/usr/local/bin/sc` against the live service, and `_init_files()` hard-codes
`/var/lib/sing-box` as a path literal that no harness can repoint. **Never write `/etc/sing-box/` or
`/var/lib/sing-box`; never touch the live service.** Any run driving a non-`doctor`/`config` command
through `main()` must neutralise `_init_files()`. Service state is witnessed with
`systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active`.

**BC-13** — A language assertion asserts positively-present content in the asserted language. "No
newline and no `失败`" is true of English as well, and the language is reassigned inside `main()`
after import, so a harness that sets only the module's language global renders English on every
`main()`-driven path.

**BC-14** — Where a criterion needs root or the live service it is reported **BLOCKED** and filed as
an operator obligation. No weaker observable is substituted. That precedent has held seven times.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | With no override present, the whole emitted tree is byte-identical to the pre-change build across the settings and rule-set state matrix T-14's byte-identity harness already drives, and every stream is empty where it was empty. | [B] | Differential against the pre-change source, both trees, whole file. Control: the harness must be shown non-vacuous by a deliberately perturbed build that the same run reports as different. Smallest wrong build that passes: none — a build that changes the override-less path fails here, which is why this runs first. |
| AC-2 | For **each** member of BC-1 independently: (i) combined stdout+stderr is exactly one line, (ii) that line contains the override path and a clause identifying the fault, (iii) the exit status is non-zero, (iv) `config.json` and the drift record are byte-identical to before the run. | [B] | Per-member fixture through the composition entry point with paths repointed and `_init_files()` neutralised. Control: the same fixtures on the pre-change build produce a traceback (M0–M3) or a written broken document (M4–M7). Smallest wrong build that passes: one that catches everything and returns the invoking command's generic failure line — killed by (ii), which requires the override path and a fault clause and forbids the bare outcome line. |
| AC-3 | A build that swallows a member of BC-1 and emits a `config.json` anyway fails at least one criterion of AC-2. | [B] | Adversarial: construct that build and run AC-2 against it; it must fail (iv). This is the R-22 gate — a criterion that only checks "no traceback" is satisfied by a build that silently ignores the user's override. |
| AC-4 | A **valid** override — each recipe published in both READMEs, plus one directive of each name in the vocabulary — produces an emitted `config.json` byte-identical to the pre-change build's for the same fixture. | [B] | Byte comparison of the emitted document, candidate vs pre-change source, per recipe. Control: a recipe whose effect is removed must show as different. Smallest wrong build that passes: one that rejects every override — killed because this criterion requires the override's effect to be present byte-for-byte. |
| AC-5 | For M4, M5, M6 and M7 the rendered line is the **same** sentence, and it names the directive vocabulary. | [B] | String equality across the four fixtures modulo the dotted position; membership test for each directive name. Smallest wrong build that passes: four separate per-shape guards with four sentences — killed by the equality clause, which is what makes this a vocabulary rather than a patch list. |
| AC-6 | The pre-existing bare-array-over-an-existing-array error is unchanged in text and in trigger. | [B] | Fixture from T-14's own criterion, re-run; string equality against the pre-change build. |
| AC-7 | With **no** override present and one of `sc`'s own overlays perturbed so that it leaves a non-array at a guarded position, the rendered line names `config.json` and not the override path. | [B] | Harness perturbs one overlay function; assert the path in the line. Control: the same perturbation on the pre-change build names the override path — the defect R-26 records. Smallest wrong build that passes: one that gates the assertion on override-presence but has no envelope — killed because that build produces a traceback here instead of a line. |
| AC-8 | `_filter_rules()` is byte-identical to the pre-change build, and so are its call sites' argument lists. | [S] | Source diff of the function and its call sites. |
| AC-9 | There is no call edge from directive application to the merge in the shipped file. | [S] | Call-graph extraction over the module, as T-14 verified B-7. |
| AC-10 | Every translation key added by this task is present with identical placeholders in the `zh` table, contains no `失败：`, and is unnamespaced prose. | [S] | AST extraction of keys from the code — not from the design document — as T-14's key-parity criterion does. |
| AC-11 | Both READMEs carry FR-6's statement at the same relative position, and their heading / fence / table / blank-line structure still matches line for line. | [S] | Structural line-number equality of the two files, as T-14's README-parity criterion does. |
| AC-12 | The published sentence in both READMEs — an override that cannot be applied stops the command before anything is written, leaves `config.json` exactly as it was, and names the file and the problem — is true for every member of BC-1. | [B] | The conjunction of AC-2 (i)–(iv) evaluated per member; the criterion is the promise, restated as a check. Control: on the pre-change build it fails for every member. |
| AC-13 | `verify_all` run **from the repository root** reports no new FAIL and no new WARN against a pristine `HEAD` clone. | [S] | Two runs, counts compared. Run from a subdirectory it self-reports a false red purely from the caller's cwd. |
| AC-14 | Live-host witness: `MainPID` and `ActiveEnterTimestamp` are identical before and after every run of every criterion, and `is-active` is never invoked. | [B] | `systemctl show -p MainPID -p ActiveEnterTimestamp`, read at the start and end of each stage that runs anything. |
| AC-15 | The shipped invocation, end to end: install the new `bin/sc`, place each member of BC-1 at the override path in turn, run `sc reload`, and confirm one line in `/var/log/sing-box/install.log`'s capture form, a non-zero status, and an unchanged `config.json`. | [B] | **BLOCKED by construction** — needs root and the installed binary against the live service. File as an operator obligation with this recipe; substitute nothing. |

## Non-functional requirements

**NFR-1** — The array vocabulary of FR-3 adds **zero** new translation keys: the sentence it needs
already exists as the bare-array-over-an-existing-array error, and FR-3 routes more shapes to it. At
most **two** new keys total may be added by this task, both for the envelope's fault clause.

**NFR-2** — The product diff touches `bin/sc`, `README.md`, `README.zh-CN.md` and `CHANGELOG.md` and
no other product file. No new module, no new file, no new class.

**NFR-3** — No line-count cap is set here. Any cap the design adopts is derived from its own element
list and not from a round number; a gate that finds a cap not credible amends it rather than
approving it (R-61).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does this task close R-15? | **Yes, both instances.** M0 and M1 (recursion) and M2/M3 (non-object rule element) are all inside BC-1 and all measured by AC-2. Neither forbidden fix is used: the composed-document assertion is not widened and `_filter_rules()` is untouched (AC-8). |
| Q-2 | Does this task close R-16, given T-14 measured the mirror to be loud? | **Yes.** The counter-weight is refuted: the binary's rejection happens *after* the document has already been written and its digest baselined as "what `sc` last wrote", so the loudness protects the running service and not the stored configuration, and the previous working `config.json` is destroyed. Both READMEs already publish the opposite promise, in both languages, at the same line. R-54's re-homing is discharged: this task is the owner. |
| Q-3 | How wide is the type-mismatch vocabulary? | **The array position only, as one sentence.** An existing array accepts a directive object and nothing else — object, scalar, `null` and bare array all earn the same error (FR-3, AC-5). The object position is explicitly out of scope: it has no measured symptom and the meaning of a `null` there is unresolved. This subsumes the existing array-over-array rule rather than adding a fourth. |
| Q-4 | Does this task close R-26? | **Yes**, and its "zero behavioural cost" holds on every input reachable today. The refinement is binding on the design: gating the assertion on override-presence is only *safe* together with the envelope, because alone it converts an unreachable-today mislabelled sentence into a traceback. The two land in one change (AC-7 fails a build that has only the gate). |
| Q-5 | Does this task close R-44? | **No.** No cap is added, on anyone's say-so. R-44 stays open and is honoured as a bound (out-of-scope 2 and 6, BC-8). Its stated reachability is corrected: the override route is structurally closed already, because every container an override contributes is deep-copied and the copy overflows at roughly half the depth the masking walk does; the reachable route is a hand-edited `config.json`. |
| Q-6 | Does this task close R-12? | **No**, and it widens R-12's population: shapes that previously ended in a traceback now end in the sentence-and-exit path that still prints no run-level outcome line. R-12 stays open with that note. |
| Q-7 | What does R-69 bind here? | **Constraints, discharged, not a defect closed.** BC-6 carries them. Its "three policies" count is corrected to **five**: stat-before-open ordering, the regular-file test, dangling-symlink-as-malformed, the read-enforced size cap, and whitespace-as-absent. Collapsing the two readers is out of scope (out-of-scope 7), so all five survive trivially. |
| Q-8 | Does the envelope's extent include the load, or only the merge? | **The load too** (FR-2). The load's failure enumeration catches `ValueError`, and a sufficiently deep document overflows inside the JSON parse itself, which is not a `ValueError` — a third instance of R-15 that no row records. An envelope scoped to the merge alone leaves M0 a traceback. |
| Q-9 | May the envelope report an internal defect as the user's fault? | **It may name the user's document, and it must still identify the fault class** (BC-11, FR-1). Provenance is decided by override-presence, never by exception class, so a document the user did not supply is never blamed; with an override present the fault clause is what keeps an internal defect reportable. |
| Q-10 | What is the smallest wrong build this criteria set must kill? | **One that catches everything and generates a `config.json` anyway.** AC-3 constructs it and requires it to fail; AC-2 (iv) is the clause that kills it, and AC-4 kills the opposite failure (a build that rejects every override). Neither "no traceback" nor "exits non-zero" is ever the whole of a criterion here. |
| Q-11 | `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` on this project. | **Proceed on the schema as written** (R-37, now confirmed a thirteenth time). Reasoning, measurement transcripts and refuted-clause detail go to `01_RATIONALE.md`; the contract carries only the declared sections. Recorded here because the unit fits no declared shape. |
| Q-12 | Findings outside this task's scope, re-homed rather than absorbed. | **Four rows for the PM to file**, stated in `01_RATIONALE.md` under "Re-homed findings": the anchor-echo in an existing error message; `docs/dev-map.md`'s parenthetical citation of R-16 as a missing *additive* directive; the drift record baselining a document the checker then rejects; and the absence of a run-level outcome line widening under Q-6. None is absorbed into this task. |

## Verdict

READY.
