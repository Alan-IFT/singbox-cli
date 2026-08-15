# 01 — Requirement Analysis · T-26 `doctor-rows-establish-their-fact`

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

## Goal

Three `sc doctor` rows state a verdict derived from a proxy for the fact instead of from the fact —
an init-system answer standing in for a delay read, a membership test standing in for a position, and
a cached answer standing in for a resolution — so each row reports a conclusion its own probe did not
establish.

## In-scope behaviors

**FR-1** — Every `sc doctor` row states only what its own probe established. Where the fact a row
exists to establish cannot be established by the probe available, the row states the narrower fact it
did establish, or it is UNKNOWN. No row's outcome class is derived from a proxy for its subject.

**FR-2** — FR-1 admits exactly two resolutions per row, and the choice is not free: **narrow the
claim** when the row's existing outcome class stays honest under the narrowed sentence, and
**establish the fact** when it does not. A row whose `[OK]` (or `[PROBLEM]`) class would still be
wrong on a host where the underlying thing is broken is not narrowable, and its check changes.

**FR-3** — The three rows are fixed by three separate changes. No abstraction, helper, wrapper,
decorator, registry or shared validator is introduced to serve more than one of them: what the three
share is FR-1, a rule about what a sentence may claim, not a computation.

**FR-4 — the AAAA row (R-50 ruling: position).** The IPv6 (AAAA) row reports `[OK]` only when
`config.json` carries the rule this build authors for this host's decision **at the position this
build emits it** — the first `dns.rules` entry — because that position is what makes the suppression
apply in `rule`, `global` and `direct` alike, and it is what both READMEs publish. A document
carrying that rule at any later position is a PROBLEM row. This amends T-20's FR-4 and I-6; see
OQ-1 for the amendment text and OQ-6 for which documents it amends.

**FR-5** — The emitted position has exactly one definition, and the row tests the document against
that same definition, so the generator's position and the probe's expectation cannot diverge
silently. This is the `_aaaa_rule()` arrangement applied to the position as well as to the rule: one
home, two readers, no second derivation and no re-spelling.

**FR-6 — the node-delay row (R-49).** On the branch where the Clash API has answered, the node-delay
row either states a count read from the `/proxies` answer, or it is UNKNOWN naming that the count
could not be read. It never states a count no request produced. The row's dependency on whether the
service is running is satisfied by a judgement `sc doctor` already holds; no second liveness
judgement is introduced anywhere.

**FR-7** — `stored_delays()` keeps issuing **no** request on a host whose init system reports the
service stopped, and `sc ls` is observably unchanged on every host that has an init system. The
guarantee BC-11 was written for — a stopped host pays no request and no wait — survives this task.

**FR-8 — the DNS row (R-48).** All three DNS-row outcomes state only what the probe established: that
the running install returned an answer / no records / no answer for the name, **and that the install
may serve any of those from its own DNS cache**, which this probe and every earlier query populate.
No row states or implies that the elapsed milliseconds measure a resolution performed upstream on
this query, and no row's next step is asserted to be effective against a cached answer.

**FR-9** — The DNS probe stays one read-only `GET` of the existing endpoint for the existing name.
Nothing in this task builds a cache bypass, a cache flush, a second endpoint constant, a second name,
a per-run varying name, or any mutating call to the live Clash API. If stage 2's first-hand read-only
probe establishes a cache-free bounded mechanism reachable through the Clash route at no new
constant (BC-10), FR-8's first clause is replaced by the stronger established fact.

**FR-10 — `sc ipv6`'s no-op line (R-24).** `sc ipv6 <value>` whose effective decision is unchanged
names the escape from a stale document on the line that today names none. It reuses the translated
sentence this project already ships for the identical state in `sc telemetry`, adding no
`TRANSLATIONS` entry, no branch and no call. Cost cap and drop rule: BC-11.

**FR-11** — `sc ipv6` forms no second opinion: the printed comparison keeps coming from the current
host only, never from the document on disk (T-16's AC-6 is untouched), and the new clause names a
command without asserting anything about the document's state.

**FR-12 — invariants carried forward, all unchanged by this task.** (a) No second opinion: every row
still stands on the call its feature owner already ships. (b) `sc doctor` stays process-wide
read-only: no path is written, created, removed or renamed, no service-affecting action is taken, and
the `doctor` arm still reaches neither `_init_files()` nor `_resolve_clash_port()`. (c) The report's
order stays decided in the one ordering table whose sole reader is the `doctor` driver, and the order
stays causal. (d) The row grammar `[<class>] <label>: <value>`, the three outcome classes, their
markers and the exit-status mapping are unchanged; per-section isolation and per-row flushing are
unchanged.

**FR-13** — Every published sentence describing these rows is true of the shipped build: both READMEs'
`sc doctor` section table, their exit-status table (including which causes produce `1` and which
produce `2`), their `sc doctor` changes-nothing paragraph, and `docs/dev-map.md` where it describes
any changed judgement. `CHANGELOG.md` gains one entry under `[Unreleased]` in Chinese.

## Out of scope

1. Any harness or tooling fix — `archive-task.sh`, R-18, R-36, R-37 belong to T-27.
2. A committed test suite (R-9/R-4) — T-28 owns it; this task's fixtures are QA-time artifacts.
3. Any new `sc doctor` row, section, flag, machine-readable output, quiet mode or per-section
   selection, and any widening of the report beyond the three rows named here.
4. Any change to `_aaaa_rule()`'s content, to `ipv6_decision()`, to the emitted document, or to the
   position at which `sc` emits the AAAA rule.
5. Any evaluation of sing-box's rule-matching semantics, and any validator, linter or checker of a
   user's `override.json`. The row judges `sc`'s own emission, never what sing-box would do with a
   foreign rule.
6. Any DNS cache flush, bypass, warm-up, TTL inspection or cache-hit detector built by this project.
7. Any change to `stored_delays()`'s return shape, to `sc ls`'s output on a host with an init system,
   or to `cmd_status`.
8. Every other open doctor row: R-51 (sub-directories never judged), R-21 (`GLOBAL` in the delay map),
   R-35 (`timeout=N` bounds a socket operation, not the call), R-56…R-59, R-70…R-79.
9. Any repair action from `sc doctor`, and any change to the outcome-class vocabulary, the row
   grammar, the section order or the exit mapping.
10. The live host: no install over `/usr/local/bin/sc`, no service action, no write under
    `/etc/sing-box` or `/var/lib/sing-box`.
11. R-24 beyond one changed line (BC-11).

## Boundary conditions

**BC-1** — `config.json` unreadable, not JSON, not an object, `dns` not an object, `dns.rules` not a
list → the AAAA row's existing classes and sentences are unchanged (T-20 BC-6/BC-7 and PQ-3 stand),
and the position test raises nothing on any of them.

**BC-2** — `dns.rules` is an empty list, or carries the rule for the other decision → PROBLEM, exactly
as today.

**BC-3** — `dns.rules` carries the authored rule at a non-zero index → PROBLEM, and the row's next
step is valid for **both** causes that branch now covers: a document that does not carry the rule
(regeneration repairs it) and a document whose `dns.rules` was reordered ahead of it (regeneration
reproduces it). Naming both admissible causes on the one line is the T-20 BC-13 shape.

**BC-4** — A user `override.json` that `$prepend`s to `dns.rules` → PROBLEM under BC-3, and the row
states nothing about whether the user's own rule preempts the decision; that judgement needs sing-box
semantics this project must not re-implement.

**BC-5** — A future `sc`-authored overlay inserting a `dns.rules` entry ahead of the AAAA rule → the
emitted-position definition and the probe change together (FR-5); neither may move alone.

**BC-6** — No init system detected, the Clash API answered, and `/proxies` holds delays → the row
states the count it read, or UNKNOWN. `0/{total}` in this state is forbidden.

**BC-7** — An init system reports the service stopped → no `/proxies` request is issued at all and the
node-delay row is UNKNOWN (T-20 BC-11, unchanged), and `sc ls` behaves exactly as it does today.

**BC-8** — No Clash port recorded, or the API did not answer → all four Clash-section rows are
unchanged (UNKNOWN, no request, no lookup).

**BC-9** — The node-delay row becoming UNKNOWN where it was PROBLEM changes an otherwise-healthy
init-less host's exit status from `1` to `2` through the existing mapping. That consequence is
accepted, no new exit value is introduced, and both READMEs' exit-status table states the new cause
(FR-13).

**BC-10** — Whether a bounded, cache-free lookup exists through the Clash route is established at
stage 2 by a first-hand read-only probe, and the probe and its result are recorded in
`02_SOLUTION_DESIGN.md`. If none exists, FR-8 ships the narrowed claim and no code chases a fresh
measurement. (T-20's BC-16 precedent, same shape, same discipline.)

**BC-11** — R-24 rides along only at one changed line reusing an existing translated sentence. If
stage 2 finds the reused sentence untrue for the IPv6 case, or that a new key, a branch or a second
fact is required, R-24 is dropped from this task and stays filed with its existing owner.

**BC-12** — A cached negative answer (held far longer than a positive one) makes the DNS row's
PROBLEM branches equally unestablished; FR-8's duty covers those branches, and no branch attempts to
detect a cache hit.

**BC-13** — `sc lang zh` → every changed sentence renders in Chinese, and no changed or added zh
string introduces the `失败：` literal (R-75).

**BC-14** — A probe raising, a concurrent `sc reload`, output to a pipe → unchanged: per-section
isolation renders one UNKNOWN row for that section, nothing blocks, retries or locks, and every row
is flushed as printed.

## Acceptance criteria

Every criterion below is verified through the rendered row, on a fixture loaded by the mandated
recipe in `docs/dev-map.md` (with R-77's `encoding="utf-8"`), never against the live host or the
installed `sc`.

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | A `config.json` whose `dns.rules` carries the authored rule at index 3 behind three decoy rules makes the IPv6 (AAAA) row PROBLEM. | [B] | One fixture run; assert marker and text. **HEAD prints `[OK] IPv6 (AAAA): …; config.json carries this decision` and fails this criterion.** |
| AC-2 | On the same fixture the PROBLEM row's next step is valid for both causes BC-3 covers, and on a fixture whose `dns.rules` lacks the rule entirely the row still names the regeneration route. | [B] | Two fixture runs; read the rendered value text against BC-3's two causes. **HEAD names regeneration only, which reproduces the reordered document, and fails.** |
| AC-3 | The position `sc` emits the rule at and the position the row tests have one definition; a reader arriving at either site is led to the other, and changing one without the other is not possible silently. | [S] | Read the emitter and the probe; attempt the divergence. **HEAD's probe defines no position at all (`in`), so HEAD fails.** |
| AC-4 | A `config.json` generated by this build, for each of the two decisions, reads `[OK]` with the row's existing sentence. | [B] | Two fixture runs. **Control, not discriminating: HEAD passes.** It is what a build that always says PROBLEM fails. |
| AC-5 | With no init system, the Clash API answering, and `/proxies` holding a delay for each of two configured tags, the node-delay row is not a PROBLEM stating `0/2`: it states `2/2` read from that answer, or it is UNKNOWN naming that the count could not be read. | [B] | Fixture with `SYSTEMD = OPENRC = False` and a stub API on a port recorded in the fixture's own `settings.json`. **HEAD prints `[PROBLEM] node delays: 0/2 nodes carry a stored delay …` and fails.** |
| AC-6 | With an init system reporting the service running and `/proxies` answering with entries that carry no history, the row stays PROBLEM stating `0/2` and naming `sc ls`. | [B] | Same fixture with `sc.SYSTEMD = True` **and** `subprocess.run` stubbed (both are required — without the stub the matrix agrees on candidate and control). **Control, not discriminating: HEAD passes.** |
| AC-7 | With an init system reporting the service stopped, no `/proxies` request is issued by `sc doctor` or by `sc ls`, and the node-delay row is UNKNOWN. | [B] | Stub API logging every request path; assert the log is empty for `/proxies`. **Control, not discriminating: HEAD passes; a build that satisfies AC-5 by deleting the guard fails here.** |
| AC-8 | The diff introduces no second judgement of whether the service is running, and no new liveness source. | [S] | Read every new call site; grep the diff for `is_running`, `systemctl`, `rc-service`, `SYSTEMD`, `OPENRC`. **HEAD passes; this pins FR-6's shape.** |
| AC-9 | On a fixture whose stub answers `/dns/query` immediately with a non-empty `Answer` — the warm-cache shape — the OK row names the install's own cache as an admissible source of that answer, and asserts nothing about where the name was resolved on this query. | [B] | One fixture run; read the rendered row against the two clauses. **HEAD prints `api.ipify.org resolved in 0 ms, through the running sing-box`, names no cache, and fails.** If BC-10 fires, clause 1 is replaced by the stronger established fact stage 2 recorded. |
| AC-10 | On fixtures where the stub answers with an empty `Answer` and where it does not answer at all, both rows stay PROBLEM and both carry FR-8's cached-answer clause. | [B] | Two fixture runs. **HEAD keeps the classes (control half) and carries no clause (discriminating half) — HEAD fails.** |
| AC-11 | A `sc doctor` run over all three fixtures issues exactly one `GET /dns/query`, no other DNS request, no mutating request, and leaves a full snapshot of the fixture root (existence, size, mtime, sha256, mode) identical. | [S]+[B] | Stub request log + before/after snapshot, plus a positive control proving the snapshot detects a write. **HEAD passes; this is FR-12(b) held.** |
| AC-12 | `sc ipv6 <value>` whose effective decision is unchanged prints a line naming `sc reload`, in both languages, and the diff adds zero `TRANSLATIONS` entries and zero branches for it. | [B]+[S] | Two fixture runs plus a diff read. **HEAD prints the line with no escape named and fails.** Dropped per BC-11 rather than weakened. |
| AC-13 | `sc ipv6 <value>` that does flip the decision still regenerates and prints the existing sentence, and neither side of its comparison is read from `config.json`. | [B]+[S] | Fixture run with a stubbed reload; read `cmd_ipv6`'s two comparison sources. **Control, not discriminating: HEAD passes; T-16's AC-6 held.** |
| AC-14 | On a wholly healthy fixture the report prints the same number of rows as HEAD, with the same labels in the same order, and the same exit status. | [B] | Row-by-row diff of a candidate run against a HEAD run on one fixture. **Control, not discriminating.** |
| AC-15 | Every published sentence describing the three rows is true of the shipped build: both READMEs' section table, exit-status table and changes-nothing paragraph, and `docs/dev-map.md`. | [S] | Enumerate each published sentence against a captured candidate run, one by one. **Fidelity criterion, not discriminating at HEAD by construction** — HEAD's prose describes HEAD's rows. |
| AC-16 | The three fixes share no new construct: no new module, class, decorator, registry or helper introduced to serve more than one row, and no new function unless it removes more lines than it adds. | [S] | Read the diff; count top-level `def`/`class` before and after. **HEAD passes; this pins FR-3 against the over-build risk.** |
| AC-17 | The committed diff touches only the files this task declares, excluding this task's own stage documents, `docs/tasks.md`, `.harness/**` and anything under `docs/batches/**` (R-36's carve-out). | [S] | `git status` + `git diff --numstat` read at delivery. |

## Non-functional requirements

1. The report's shape on a healthy host is unchanged: one line per row, no row added, no row's
   enumeration growing with the host's contents (T-20 NFR-3 held, measured by AC-14).
2. The added cost is zero requests: no probe issues a request this build does not already issue, and
   no probe reads a file this build does not already read.
3. Size bar, from the three most recent deliveries (T-25 `+80/−41` with no new function, T-24
   `+79/−55`, T-23 `+76/−51`): this task is smaller than all three. A design exceeding `+40/−20` on
   `bin/sc` carries the burden of proof under `.harness/rules/85-design-discipline.md`. FR-8 changes
   sentences only: the DNS row's check is unchanged unless BC-10 fires.
4. Every changed user-facing string keeps a `TRANSLATIONS["zh"]` entry in its existing thematic
   group; the table has no `en` half, so each key is its own English rendering (R-19's closure must
   not be undone).

## Resolved questions

| id | question | binding answer |
|---|---|---|
| OQ-1 | R-50: is the requirement membership, or position? | **Position.** T-20's FR-4 ("whether the document on disk carries that decision") and its I-6 (the membership test over `dns.rules`) are **amended**: the row reports `[OK]` only when the authored rule is the **first** `dns.rules` entry, and a document carrying it later is a PROBLEM row. The original is wrong for three first-hand reasons. (1) `README.md:126` and its zh mirror already publish the **position** as the product's promise — "evaluated **first**, ahead of both routing-mode rules, so it applies in `rule`, `global` and `direct` alike" — so membership tests something the product never promised. (2) `CONFIG_BASE`'s `dns.rules` places `{"server": "remote_dns", "clash_mode": "Global"}` and `{"server": "direct_dns", "clash_mode": "Direct"}` at the head of the chain, and both match every query in their mode, so any rule after them is dead in exactly the two modes a user switches to when something is already broken; the base's own comment and `_dns_overlay()`'s docstring both say so. (3) Narrowing the sentence cannot resolve this row: the class carries the verdict, and `[OK]` on a host where AAAA suppression is not in force is the R-22 trap whatever the value text says — while a row reporting "a dict is a member of a list" answers a question nobody asked. |
| OQ-2 | Does a probe that populates the install's DNS cache still satisfy "`sc doctor` is process-wide read-only"? | **Yes — and this ruling confirms a decision the product already publishes rather than making a new one.** `sc doctor` itself writes, creates, removes and renames no path, issues no mutating API call, and reaches neither `_init_files()` nor `_resolve_clash_port()`; the cache entry is written by the sing-box process as the ordinary consequence of a query any process on the host could make, and `README.md:272` already states exactly this ("the resolution is performed *by the running sing-box*, which may record it in its own DNS cache (`/var/lib/sing-box/cache.db`) exactly as it would any other query"). **The binding addition is where the duty actually lands**: a read-only probe whose side effect changes what a later run of the same probe can establish must not have its result stated as a claim wider than what one run establishes. That is FR-8, and it is the whole of R-48's fix. |
| OQ-3 | Per row: narrow the claim, or strengthen the check? | **R-48 → narrow** (subject to BC-10): the row's `[OK]` truthfully means "the running install answered", so the honest sentence and the existing check can coexist. **R-49 → establish or UNKNOWN; narrowing is inadmissible**: a count is not a narrowable claim — it was either read or it was not. **R-50 → establish; narrowing is inadmissible** (OQ-1 clause 3). One of three fixes is a sentence, which is the shape rule 85 predicts. |
| OQ-4 | Do the three fixes share one construct? | **No.** The shared unit is FR-1 — a rule about what a sentence may claim — and it is discharged three times in three sentences and one expression. A shared helper over three unrelated probes would be machinery bought with the coherence argument, which rule 85's counter-rule forbids; AC-16 pins it. |
| OQ-5 | Is R-24 in scope? | **In, at exactly one changed line, with a drop rule (BC-11).** It is cheap by an accident worth naming: `cmd_telemetry` already ships the translated sentence for the identical state — "Nothing changed … ; run `sc reload` to apply this setting to a configuration generated before it", with both language halves already in the table and a comment recording *why* it names `sc reload`. `cmd_ipv6` prints the shorter sibling of that key. So the fix is a key swap at one print site: no new key, no new zh entry, no branch. It is also causally coupled to FR-4 — this task makes more hosts read "run `sc reload`", and `sc ipv6` is where such a user goes next. |
| OQ-6 | R-50 is filed as amending "FR-4 and I-6"; whose? | **T-20 `doctor-extended-checks`, not T-16 `dns-resilience`** — the dispatch's attribution is corrected here by reading both. T-16's FR-4 governs `sc ipv6 on\|off\|auto\|show` and its I-6 is `_dns_overlay()`, which **authors** the index-0 position and argues for it explicitly. T-20's FR-4 is the doctor AAAA row and its I-6 is the probe; T-20's own stage 5 (RES-1) and stage 6 (DEF-3) name that pair. The amendment therefore **contradicts nothing in T-16** — it aligns the probe with the position T-16's design already made binding. |
| OQ-7 | What is the blast radius on `sc ls`? | **None on any host with an init system, and no new request on any host.** `stored_delays()`'s internal guard exists so a stopped host pays neither a request nor a wait, and that guarantee is preserved verbatim (FR-7, BC-7, AC-7). A design that satisfies FR-6 by deleting the guard is rejected by AC-7 rather than by argument. |
| OQ-8 | Stage 1 held no execution tool. Which claims are re-established first-hand, and which are inherited? | **Re-established by reading, in full:** R-49's whole mechanism (the guard, the short-circuit, the count, and that `sc ls` shows the same emptiness through the same call); R-50's position-blindness and *why* position is load-bearing (the two `clash_mode` rules at the head of the base chain, plus the published promise); R-24's cost (the reusable sentence exists in the table today). **Inherited, not re-measured:** R-48's timing and TTL figures (175 ms / 4 ms / 195→190→186 / 1800 s) and R-50's runtime measurement that types 64/65 are unsuppressed in `direct` at index 3 — both are stage-6 measurements of T-20, both are consistent with everything read here, and **neither is load-bearing for any requirement above**: FR-4 rests on the published promise and the base chain, FR-8 rests on the existence of the cache, not on its numbers. The obligation to measure moves to stage 2 (BC-10) and stage 6 (AC-1, AC-5, AC-9, AC-10), each of which must observe the behaviour rather than cite these figures. |
| OQ-9 | Does the DNS row's duty extend to its PROBLEM branches? | **Yes — R-48 is wider than filed.** The same call serves all three branches from the same cache, and a negative answer is held far longer than a positive one, so "returned no records — try another node" can restate a failure the user has already repaired and propose a step that cannot help. Covering all three branches costs the same one clause, so nothing is bought by covering one. |
| OQ-10 | Is the exit-status change from `1` to `2` on an init-less host acceptable? | **Yes.** It is the existing mapping applied to an honest class, and it is the direction the published contract already defines — `2` means "a check could not run". No new exit value appears, and FR-13 makes the READMEs' exit-status table state the new cause rather than leaving a published sentence false (R-74's practice). |
| OQ-11 | Schema gap: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` on this project — **R-37, fifteenth confirmation**. Where do the per-row re-verification record, the measurement obligations and the rejected readings go? | Into `01_RATIONALE.md`, the destination the analyst contract names for exactly these units, and this row records the gap rather than inventing a contract section. **T-27 owns the one-section fix.** |

## Verdict

READY
