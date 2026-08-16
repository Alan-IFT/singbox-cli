# 01 — Rationale · T-32 `record-accuracy-sweep`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

Routing follows `.harness/rules/70-doc-size.md`'s `## Stage-doc boundary rule`; nothing here is
restated from it. Everything below explains, measures, compares or records how the contract's units
were reached. **This stage held no shell** (`Read`/`Grep`/`Glob` only), so every claim here is a
reading unless it names a prior task's measurement — and where a claim needs a run to settle, the
contract carries it as a criterion the developer or QA discharges.

## 1. Re-verification of the eleven — the attrition table

| row | filed location | current location | classification |
|---|---|---|---|
| R-63 | `bin/sc:634` docstring; coincidence at `:726`/`:729` | docstring `bin/sc:696-700`; split `:792`; sole consumer `_b64dec` at `:794` | **LIVE BUT DIFFERENT FROM FILED** — the sentence is **true today**; the defect is an unrecorded dependence, not a false claim |
| R-74 | no site — the general form | — | **LIVE as a practice**; needs the ruling, not an edit (§5) |
| R-77 | dev-map recipe's `open()` | `docs/dev-map.md:211` reads `open("bin/sc", encoding="utf-8")`; clause naming R-77 at `:236` | **ALREADY CLOSED** — by T-28 (`docs/tasks-archive.md:588`), and verified in fact here, not inherited |
| R-78 | `docs/dev-map.md:121-158` | signature clause at `docs/dev-map.md:237-239` | **ALREADY CLOSED** — and the clause is true of `bin/sc:125-126`, which re-execs `/usr/local/bin/sc` with `sys.argv[1:]` |
| R-79 | `docs/dev-map.md:78` | cost clause now `docs/dev-map.md:81` | **LIVE** — the clause still names two sites in the present tense and never says the loss was unavailable |
| R-82 | `docs/dev-map.md:39` | `# Clash API` file-map row now `docs/dev-map.md:42` | **LIVE** — states only the first clause; `bin/sc:2295-2296` and `docs/dev-map.md:68` state both |
| R-83 | AAAA PROBLEM row | English key `bin/sc:2800-2802`, zh entry `:312-313` | **LIVE BUT DIFFERENT FROM FILED** — the row's own repair is false (§3) |
| R-84 | recipe silent on `_init_files()` | clause at `docs/dev-map.md:239-240`, true of `bin/sc:3837` | **ALREADY CLOSED** |
| R-85 | `CHANGELOG.md` T-26 lead | `CHANGELOG.md:29` | **LIVE BUT DIFFERENT FROM FILED** — the row's proposed replacement is itself false (§4) |
| R-91 | rule 80's four ranges | `.harness/rules/80-delivery-policy.md:71-73` | **LIVE** — exactly as the row's own note says (§2) |
| R-94 | two counts + one stale clause | four documents + one stale clause | **LIVE AND WIDER** — five clauses, not three (§6) |

No row classified **NOT A PROSE DEFECT**. Two were tested for it and cleared: R-83's `sc reload`
advice is ineffective because applying the user's override last is the design
(`docs/dev-map.md:41`), not a defect; and R-85's exit mapping (`bin/sc:2546-2550`) is the outcome of
a decision that was taken deliberately and upheld — `.harness/rejected-decisions.md:202`
`doctor-exit-status-always-zero`. In both, the code is right and the sentence is wrong, so BC-2
never fires.

**Attrition is three of eleven.** T-29's precedent is the standard: it found R-77 already discharged
by T-28 and reported it rather than editing a sentence that was already right.

### Why the three closures were checked and not inherited

`docs/tasks-archive.md:588` asserts R-77 CLOSED by T-28 and cites `docs/dev-map.md:146` /
`:169-177`. Those coordinates have drifted (T-31 added +95/−4 to that file), so the claim was
re-established against the text rather than the line numbers: the fenced block at `:204-214` reads
its source with `encoding="utf-8"`, and the four clauses at `:233-242` name the encoding (R-77), the
exit-2 argparse signature (R-78) and the read-only command pair (R-84) by row id. Each clause was
then checked against the code it describes — `bin/sc:126` (`os.execvp("sudo", ["sudo",
"/usr/local/bin/sc"] + sys.argv[1:])`) makes the argparse-usage-error signature exactly right, and
`bin/sc:3837` (`if args.cmd in ("doctor", "config")`) makes the `_init_files()` clause exactly
right. **Which** task landed R-78's and R-84's clauses is not established by reading; the delivery
should name it with `git log -S` over the clause text, and that is a run this stage could not take.

## 2. R-91 — what actually resolves

Read in `.harness/scripts/upgrade-project.sh`:

- `:186-194` — the `refresh_set` array, exactly. ✔
- `:195-227` — the refresh loop that replaces each member with the template, no marker preservation,
  no backup. ✔
- `:136-141` — the hand-maintained invariant comment plus `known=(` and its `verify_all.ps1
  verify_all.sh` line, i.e. the statement that `verify_all.{sh,ps1}` is outside `refresh_set`. ✔
- `:548-556` — the **HALT** branch only (`emit "VERIFY-HALT|$shell"` at `:549`, whose CONFLICT
  message at `:550` merely *mentions* the `.bak`).

The sentence at `.harness/rules/80-delivery-policy.md:72-73` reads "it is spliced, HALTs on unmarked
custom `B.*` checks, and gets a timestamped `.bak` (`:548-556`)" — three clauses, one citation,
covering one of them. The splice is `:535-542` (`verb="VERIFY-SPLICE"` at `:542`) and the backup
write is `:570-573` (`bak="$proj_file.bak-$stamp"` / `cp` / `emit "BAK|$bak"`). Both sub-line
imprecisions the row recorded are confirmed exactly. The row's *headline* worry — that a refresh
drifts all four — is prospective and already mitigated by the prose naming `refresh_set` and
`VERIFY-HALT` in words; the **live** defect is the shared citation.

Rule 80 is 89 lines, rule 50 is 141: F.2's 200-line cap is not near.

## 3. R-83 — the row is wrong about its own subject, twice

`_apply_directive` (`bin/sc:1429-1454`) decides what each directive can do to `dns.rules`:

- `$prepend` returns `payload + current` → changes element 0. **Reaches the row.**
- `$replace` returns the payload → changes element 0 unless the user reproduces it. **Reaches.**
- `$before` inserts at `i = _anchor_index(...)`; when the anchor resolves to the first element the
  insert lands at index 0. **Reaches, conditionally.**
- `$after` inserts at `i + 1` with `i ≥ 0` — it can never place an element at index 0. **Cannot
  reach.**
- `$append` returns `current + payload`. **Cannot reach.**

The probe (`bin/sc:2796`) compares `rules[:len(prepend)] == prepend`, and `_dns_overlay`'s
`$prepend` payload is one rule, so "reaching the row" is exactly "element 0 is not the rule this
build emits". **The row's "four" is three**, and one of them is conditional on where the anchor
lands.

Second: the row says `sc reload` is ineffective "for a `$replace` cause". Regeneration re-applies
the user's document on **every** run (`docs/dev-map.md:41`; the override is merged last), so
`sc reload` reproduces *any* override-caused displacement — `$prepend` and `$before` included. What
`sc reload` genuinely repairs is a document that is stale (generated before the setting changed, or
by an older build that emitted the rule at index 3 — measured by T-26) or hand-edited.

So a developer who "corrects" this sentence from the row's text ships a second false sentence naming
a fourth directive that cannot reach the row and promising repair for two causes it does not repair.
That is precisely the inverted-R-22 failure the contract's AC-5/AC-6/AC-8 exist to stop.

The sentence lives only in `bin/sc` (English key `:2800-2802`, zh `:312-313`); a search for
`prepends a rule of its own` / `第一条不是` finds no README counterpart — `README.zh-CN.md:263` and
its English mirror describe *what row 4 checks*, not its repair advice. Neither string carries
`失败：` or `failed: `, so R-75's grep is untouched. Assertion 14 of the suite
(`zh_placeholders_are_a_subset_of_their_key`) is the reason BC-4 pins the placeholder set.

## 4. R-85 — the filed repair is false, and the derivation says what is true

`bin/sc:2546-2550`:

```
DOCTOR_OK, DOCTOR_UNKNOWN, DOCTOR_PROBLEM = 0, 1, 2   # ordered: OK < UNKNOWN < PROBLEM
DOCTOR_EXIT = {DOCTOR_OK: 0, DOCTOR_UNKNOWN: 2, DOCTOR_PROBLEM: 1}
```

The worst class decides the exit, and the mapping is **not monotone in the numeric exit value** —
which is the whole trap. T-26 changed two row *classes*:

1. AAAA (`_doctor_ipv6`, `bin/sc:2796-2802`): membership → position. A host whose rule is present but
   not first moves **OK → PROBLEM**.
2. node delays (`_doctor_clash`): on a host with no init system and a responding API, **PROBLEM →
   OK**.

Enumerating worst-class transitions:

| host | before | after | exit |
|---|---|---|---|
| rule not first, otherwise all OK | OK | PROBLEM | 0 → 1 |
| no init system, API answers, delays was the only PROBLEM | PROBLEM | UNKNOWN (service/autostart) | 1 → 2 |
| **≥1 UNKNOWN row, no PROBLEM, rule not first** | **UNKNOWN** | **PROBLEM** | **2 → 1** |

The third line refutes 「没有哪台机器的退出码会变小」. It needs an UNKNOWN row co-occurring with no
PROBLEM row; the code offers several — an unparseable `sing-box version` line
(`bin/sc:2636`/`:2641`, binary row still OK), `ip` absent (`:2855`), or no recorded Clash API port
(`:2898-2901`, four UNKNOWN rows and `sc doctor` never resolves a port because `main()` keeps it off
`_resolve_clash_port()`) — combined with an override that prepends a `dns.rules` entry, which both
READMEs publish recipes for.

I could not run `sc doctor` to witness such a host, and the loader recipe forbids driving a doctor
probe from a fixture (`docs/dev-map.md:198`), so AC-9/AC-10 are stated as a **source enumeration**
rather than a run. That is the honest shape: the transition table is derivable from the row
constructors and the mapping, and a reader can check it without a shell.

What the corrected lead therefore has to say is that the change moves exit codes in **both**
directions, naming the transitions — not "only one direction" (false under the severity reading) and
not "never smaller" (false under the numeric reading, which is the one the sentence is about).

**Why AC-9 compares the two sets in both directions.** The defect R-85 files is an enumeration that
*reads* complete and is not; a criterion that asks only "is every stated transition derivable" is
passed by a lead naming one true transition and omitting the rest, which reproduces the filed defect
inside the criterion written to catch it — R-74's own trap, inverted onto the AC. FR-7 already binds
the completeness half ("the transitions the build can produce"), so AC-9's equality is an alignment
with its FR, not a new demand. Its population follows from the same reasoning: `CHANGELOG.md:29`
names **three** rows T-26 changed (IPv6 (AAAA), 节点延迟, DNS 解析), while the table above traces
only the two whose class moves I could settle by reading; a derivation scoped to two probes would
make the derived set itself a subset, and equality against a short set is not completeness. The
DNS-lookup row's before-state classes need `git show`, which this stage could not take — so AC-9
binds the population by the changelog entry's own row list and leaves the per-probe reading to the
stage that holds a shell.

## 5. R-74 — the ruling, and the candidates it beat

**Candidate A — close it here.** Ground: the eleven instances are corrected; the practice is carried
in every dispatch and in the delivery records; T-32 is the last task of the programme, so an open
row with no owner is orphaned.

**Candidate B — close it and fold its content into R-22's practice row.** Ground: rule 85 prefers
deleting; two practice rows on one board cost two reads.

**Candidate C (taken) — it stays open as a standing practice with no code owner.** Grounds, in
order:

1. **The row's own text** says "Not work — a practice, in the shape of R-22" (`docs/tasks.md:169`),
   and R-22 has been carried open and honoured by T-18 … T-31 (`docs/tasks.md:33-36`). The only
   evidence either way is that this shape works while open.
2. **There is no closure predicate.** No artifact can be read to decide that R-74 is discharged, and
   the one mechanism that would supply one is declined (§7). Closing a row with no predicate is
   itself a sentence claiming more than the work delivers — R-74's own defect, committed on R-74.
3. **Orphaning does not apply to a practice row.** Its mechanism of action is the board read at task
   start plus the dispatch carry, not an owner; R-22 will be equally "orphaned" and has never needed
   an owner to fire.
4. Candidate B loses on content: R-74's traps (a universal quantifier over a region must be
   enumerated against every sentence the region can produce **before** it is written; a figure
   measured under a stub is a claim about the stub) are not R-22's trap (an AC that pins the artifact
   instead of the behaviour). Merging them would drop one of the two.

The evidence that R-74 is this project's most-repeated defect is worth keeping in the amended row:
T-24's **three** rollbacks were all prose with `bin/sc` byte-identical from round 1; T-25's rollback
was a record defect; T-26's MAJOR was a published exit transition the build cannot produce; T-29's QA
falsified a shipped README sentence with the task's own fixture; T-30's stage 5 had no shell and said
so; T-31 narrowed two claims rather than engineering to meet them. **T-32 adds two more instances of
the same defect found inside the filed rows themselves** (§3, §4) — which is the strongest available
argument that the practice, not the sweep, is the durable artifact.

## 6. R-94 — the population is five clauses

1. `docs/dev-map.md:33` — "The **eight path constants**"; `:216` says **nine** and enumerates nine
   (`CFG_DIR`, `CFG_PATH`, `NODES_PATH`, `SETTINGS_PATH`, `RULES_DIR`, `OVERRIDE_PATH`, `STATE_PATH`,
   `IF_INET6_PATH`, `LIB_DIR`). `LIB_DIR` (`bin/sc:43`, used at `:3549`) passes the row's own test
   and is not named in the `# Paths` row at all.
2. `.harness/rules/50-singbox-cli.md:29` — "14 contract assertions"; the suite defines **19**
   (`check-sc-contracts.py:846-857`, counted entry by entry).
3. `.harness/rules/50-singbox-cli.md:47` — "until B.2/B.3 are real", contradicted by `:36-40` of the
   same file (B.2 real since T-11; B.4/B.5 since T-28; B.6 since T-31).
4. **Not filed:** `docs/dev-map.md:87` — "THE committed test artifact: **18** named assertions". Same
   artifact, same class, one number off. Found while verifying clause 2.
5. **Not filed:** `docs/tasks.md:238` — "`baseline.json`'s `test_count` is **18** since T-30"; the
   file reads **19** (`baseline.json:4`), raised by T-31 in the same commit as its 19th assertion.

Clauses 4 and 5 are inside R-94's own general form ("documents disagree with the artifact about a
count"), and the precedent for taking the family rather than the filed instance is T-29's R-76 (six
sites where the row named one) and T-31's `subprocess` gap (larger than filed). `bin/sc:59-63`'s
"joins the seven repointable path constants as the eighth" is excluded by the row's instruction; it
is not false as a historical statement (it predates `LIB_DIR`), and the dev-map correction is what
keeps a reader from meeting two counts with no explanation.

## 7. Q-6 — why no mechanism, argued against the two precedents

The operator offered this expectation to be overturned with evidence rather than deferred to. I
looked for the evidence and did not find it:

- **T-27 designed a per-kind routing table, priced it, and deleted it** when all seven recurring unit
  kinds routed correctly under the bare test plus precedence — ten lines that earned nothing
  (`docs/tasks-archive.md:505`). A prose-drift check has the same shape: it would fire on the
  *spelling* of a count, and every defect in this sweep except the two counts is a **semantic**
  claim (a directive set, a transition set, an unrecorded dependence, a prospective cost) that no
  mechanical check can evaluate.
- **T-31 closed R-95 and R-96 with a written boundary at zero executable lines**, having measured
  that the alternative (a second-language pass; a child-process runner) was vacuous or destroyed a
  safety property. Here the analogous mechanism would have to run over prose, and its only
  achievable assertions are exactly the ones the tree already gets for free: `verify_all` F.2/F.5
  measure size, B.4/B.6 measure the assertion count, and no committed step can decide whether "four
  directives reach this row" is true.
- `.harness/rules/85-design-discipline.md:60-71` declines machinery whose future edit cannot be
  named, and `.harness/rules/25-decision-policy.md` asks for the decline to be recorded — hence
  FR-11's single entry in `.harness/rejected-decisions.md` rather than silence. Two of the five R-94
  clauses (a count of assertions) *are* mechanically checkable, and the mechanism that checks them
  already exists: B.4 prints `N defined` on every run, which is why AC-14 uses it.

## 8. Q-8 — pricing R-98 and R-106 for the PM's ruling

Neither is discharged; both are the same class as the eleven.

- **R-98(a)** — "every command except `sc doctor`" is false since T-06 (`bin/sc:3837` reads
  `("doctor", "config")`). Filed as two sites; the population is **six**: `README.md:124`, `:152`,
  `README.zh-CN.md:124`, `:152`, and two `bin/sc` docstrings that say the same thing —
  `:3271-3274` ("runs for `sc ipv6` exactly as for every other non-doctor command … `doctor` stays
  the one positively named read-only command") and `:3335-3338` (the identical clause for
  `sc telemetry`). Cost ≈ 6 short edits, four of them bilingual README lines. It is also the exact
  sentence the surfaced insight entry warns three consecutive documents got wrong.
- **R-98(b)** — `cmd_config()`'s docstring (`bin/sc:3186-3190`) enumerates `\xNN` and
  `\UNNNNNNNN` and closes "Both READMEs state the same condition"; the READMEs carry the three-way
  rule since T-29, so the equality claim is an understatement and the enumeration omits `\uNNNN`,
  the spelling that covers every CJK character. Cost ≈ 2 lines, `bin/sc` only.
- **R-106(a)** — `_record_generated()`'s docstring still argues from adjacency ("would have failed
  the `config.json` write **one line earlier**", `bin/sc:1990-1992`); since T-30 the write is a
  whole `finally` block earlier. Cost 1 line, inside T-14's frozen span.
- **R-106(b)** — `README.md:376` and its zh mirror: "anything you hand-edit there is discarded
  without a word", while `_warn_drift()` does warn. Pre-existing overstatement, bilingual, cost ≈ 2
  lines.
- **R-106(c)** — explicitly **not** to be fixed: upstream-ruled by T-30's BC-5 and recorded so a
  sweep does not re-discover it.

Total if the PM widens: ≈ 11 short edits, all prose, four of them bilingual, none behavioural. The
argument for widening is that T-32 is the programme's last task and these rows name T-32 as owner, so
declining leaves them unclaimed. The argument against is the operator's "add nothing else" and the
fact that R-98(b) and R-106(a) sit in `bin/sc` docstrings whose repair was already priced and
declined once at T-29's stage 5 for costing a line no ledger row authorised. The contract's Q-8
answers only the scope question and leaves the disposition where the operator put it.

## 9. Related historical work

Linked, not re-described — read the entries on the board rather than a summary of them:

- `docs/tasks.md:16` (T-31 `suite-guarantee-boundaries`) and
  `docs/features/_archived/suite-guarantee-boundaries/07_DELIVERY.md` — the loader recipe's current
  facts, R-109, and the measured `test_count` 18 → 19.
- `docs/tasks-archive.md:574` (T-30) and `:575` (T-29) — the standard for "a task fixes the sentences
  it breaks", and the `backslashreplace` three-spelling precedent.
- `docs/tasks.md:169` (R-74), `:33-36` (R-22), `:213` (R-85), `:210-212` (R-82/R-83/R-84),
  `:234` (R-91), `:258` (R-94), `:193-194` (R-78/R-79), `:142` (R-63).
- `docs/tasks-archive.md:505` (T-27's deleted routing table) and `:516`/`:588` (R-77's text and its
  closure claim).
- `.harness/rejected-decisions.md:202` (`doctor-exit-status-always-zero`) — why R-85's exit mapping
  is the code being right.

## 10. Notes for downstream that are not requirements

- The dispatch states `test_count: 18`; the tree reads **19** (`baseline.json:4`), and T-31's
  delivery records the raise. Nothing was measured wrongly — the figure simply aged, which is this
  task's subject arriving in its own brief. Now settled three ways: `baseline.json:4` = 19,
  `check-sc-contracts.py:846-857` defines 19 names, and a full run reports B.4 PASS.
- The task-start `verify_all` baseline was measured by the PM (neither this stage nor the gate held a
  shell): **PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0**, B.3 the single SKIP, B.4/B.5/B.6 PASS, and
  F.4 PASSes — `.harness/insight-index.md` is 30 lines by `wc -l` against F.4's `> 30` test, not the
  31 rendered lines a read counts. AC-19's "measured, not inherited" (Q-7) is discharged by that run.
- The surfaced insight entry cites `bin/sc:3769` for `main()`'s read-only enumeration; the statement
  is at `:3837` today. The insight is exactly right and its coordinate has drifted — the reason the
  contract's BC-10 keeps line numbers out of corrected sentences and inside evidence.
- `docs/tasks.md` is **299** lines as measured at task start (`wc -l`; my own read counted 300
  rendered lines, and the PM's run settles it). F.5 tests `> 300`, so it PASSes today either way and
  BC-6's rotation duty is unchanged — it binds before any row is added, and the margin is one line.
- No `INPUT.md` exists for this task; the dispatch prompt was the input, and its eleven rows were
  read from `docs/tasks.md` and `docs/tasks-archive.md` directly.

## 11. Why AC-3 settles by reading only, and why "a scratch tree" was never containment

AC-3's subject is a **source-order** question — which non-ASCII write a pre-`backslashreplace` run
reached first — and `git show` answers it as text. The criterion previously offered a fallback that
ran the retrieved copy "on a scratch tree" when order did not settle a site. That fallback was
false about its own containment, and the evidence is in this file already: `bin/sc:124-126` is

```
if os.geteuid() != 0:
    os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])
```

— at **import** time, to a **hard-coded absolute** target. So the process that would execute is not
the copy invoked: it is the installed build, under `sudo`, reading `/etc/sing-box` and able to
restart the live service depending only on the argv chosen. Neither the historical copy nor the
scratch tree is in that path at all, so the containment the wording implied did not exist anywhere.
The same fact is what makes R-78's clause true (§1), which is the uncomfortable part: this document
cited the re-exec as evidence in one section while a criterion in another instructed the act it
makes unsafe.

Three reasons the repair had to be the criterion's text rather than a condition attached elsewhere:

1. **Self-contradiction, not omission.** NFR-4 ("no stage runs the installed `sc`") and BC-8 (a
   criterion needing the installed `sc` is BLOCKED-and-filed) already forbade it, so a reader met two
   instructions and resolved them by whichever they trusted — and resolving them correctly required
   already knowing the re-exec. A safety rule that holds only for a reader who has made the inference
   the wording conceals is not a safety rule.
2. **This project has paid for that exact invisibility.** R-78's near-miss voided a T-25 round when a
   loader re-exec'd the installed `sc` under password-less sudo. The recipe's accuracy about that is
   a safety property (§1), and a criterion contradicting it spends the property.
3. **R-110(a), filed against this stage today**, records the failure mode of scoping a false
   requirement sentence by condition and never amending the sentence. That row's subject is a
   *claim*; AC-3's was an *act*, on the batch's last row, against a running service.

What did **not** change: the criterion's substance. The reading at both named sites, from
`git show`, is correct and stays, and 02's V-3 already implements the corrected form, so no design
re-emission follows. The only structural consequence is that a site source order cannot settle now
terminates at BC-8 — BLOCKED and filed — rather than escalating to a run, which is the same
disposition every other unrunnable criterion in this contract already carries. That costs coverage
of at most one site of one clause, and FR-4's claim is prospective ("the price is prospective"), so a
site left BLOCKED weakens a claim the delivery is free to narrow rather than forcing a stronger one.
