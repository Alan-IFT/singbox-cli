> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## What this gate re-established first-hand

I hold `Read` / `Grep` / `Glob` and no execution tool. Everything below was established by reading
the shipped source, the installed binary and the published documents. Nothing was inherited from an
upstream document without being checked against the code it cites.

**Every code citation in `02_SOLUTION_DESIGN.md` and `02_RATIONALE.md` resolves.** I read each one:
`_aaaa_rule()` at `bin/sc:1743-1754`, `_dns_overlay()` at `:1757-1774`, `ipv6_decision()` at
`:1704-1740`, the compose list at `:2092-2093`, `stored_delays()` at `:2211-2255` with the guard at
`:2231`, `cmd_ls()`'s portless call at `:2308`, `_doctor_clash()` at `:2792-2876` with `/configs` at
`:2821-2823`, `stored_delays(port=port)` at `:2845`, the node-delay PROBLEM at `:2854-2857` and the
three DNS branches at `:2864-2875`, `_doctor_ipv6()`'s membership test at `:2717`, its PROBLEM
sentence at `:2720-2722`, `DOCTOR_SECTIONS` at `:2976-2986`, `cmd_doctor`'s envelope at
`:3002-3020`, `cmd_ipv6`'s no-op print at `:3209`, `cmd_telemetry`'s reusable sentence at
`:3271-3272`, the orphan `zh` entry at `:192`, the long sibling at `:209`, the five re-worded entries
at `:310-311`, `:335-336`, `:337-338`, `:339-340`, `:341-342`, the `OVERRIDE_PATH` rendering
convention at `:2634`, and `README.md:126`, `:263`, `:266`, `:272`, `:279`, `:280` with
`README.zh-CN.md` confirmed a line-for-line mirror at `:262-267`. This is the cleanest reuse audit
I have gated; dimension 3 is a positive PASS, not an absence of findings.

## Duty 1 — testing the rule-85 answer rather than accepting it

### Row 1: is E1's extra machinery bought?

The design's claim (a) is that a bare `rules[:1] == [_aaaa_rule(suppress)]` would, the day the
`$prepend` payload grows a second rule, "silently compare one element against two and report PROBLEM
on every healthy host". **That is not what the expression does.** A one-element slice compared to a
one-element list is a one-against-one comparison in every world. Working it through against
`_apply_directive`'s `$prepend` (`bin/sc:1444-1445`, `copy.deepcopy(payload) + current`):

- payload becomes `[aaaa, new]` → the document is `[aaaa, new, …]` → `rules[:1] == [aaaa]` is
  **True**. The bare slice keeps passing and silently stops checking the new rule. Silent
  under-check, not a false PROBLEM.
- payload becomes `[new, aaaa]` → the document is `[new, aaaa, …]` → `rules[:1] == [aaaa]` is
  **False** on every healthy host. That is the failure mode the design describes, and it is the
  shape `01_REQUIREMENT_ANALYSIS.md` BC-5 actually names ("inserting a `dns.rules` entry **ahead of**
  the AAAA rule").

So the design overstated the mechanism and understated the second half of it. **The rejection
survives anyway**, and rule 85's test — "if you cannot name the future edit it prevents, it is not
justified" — is met: the future edit is "when `_dns_overlay()`'s `$prepend` payload gains a rule, the
probe must be edited", it is named by the requirement's own BC-5, and under I-3 the probe follows at
zero edits in **both** growth shapes while the bare slice needs an edit in one and hides a hole in the
other.

I then tested whether `_aaaa_rule()`'s docstring really is the evidence the design says it is. It is
adjacent evidence, not the same evidence: read in full (`bin/sc:1746-1751`), the parenthetical warns
against a positional index **into the overlay** used to extract the authored rule, not against a
positional test **of the document**. The design cites it as though the two were one argument. The
better argument is the one `02_RATIONALE.md:96-101` actually makes and the contract portion
under-sells: `_aaaa_rule()` exists as a function taking `suppress` precisely so the decision is passed
in rather than reached for, and `_dns_overlay(suppress)` is that identical move one level up. After
E1 the two functions have the same shape; before E1 one takes its input and the other reaches for a
global. That is **one concept instead of two**, which is a reduction in what a future reader must
hold, and rule 85 counts a design's size as its diff plus exactly that. Six lines for a parameter, a
call-site edit and three corrected docstrings is not machinery — no new function, no new constant, no
new module, and one seam removed rather than a parallel one added.

I therefore did **not** move the ruling to the bare slice. I record that I considered doing so, and
what stopped me: FR-5 and AC-3 are contract, not design preference, so ruling for the bare slice
would have been a rollback to the requirement analyst over a six-line difference — and the six lines
are the smaller design once the concept count is priced honestly.

### Row 2: is the narrowed guard the smallest correct fix?

Yes, and it is the shape rule 85 most prefers: it **removes a second opinion** rather than adding a
check. `_doctor_clash()` establishes liveness at `bin/sc:2821-2823` (the `/configs` answer) and then
`stored_delays()` re-decides it at `:2231` through `is_running()`, whose final line returns `False`
without running a subprocess when neither `SYSTEMD` nor `OPENRC` is set (`bin/sc:2202-2208`) — the
weaker answer wins and the row prints a count no request produced. That is this project's own
insight-index entry of 2026-08-14, reproduced by reading. Deleting the guard is genuinely worse: it
is `+0/−2` but costs `sc ls` a request and a 3 s wait on a stopped host, and `cmd_ls` at `:2308`
passes no port, so the narrowed condition preserves that for every caller that does not name one. A
`running=True` parameter is strictly larger and adds a knob that can be passed **wrongly**, where
`port=None` cannot: a caller naming a port is by construction a caller that read one from settings.
The accepted cost — one parameter carrying two meanings — is recorded in I-4, travels as RS-6, and is
the honest price.

### Row 3: the sharp edge, and it is honoured

The dispatch predicted that for at least one row the smallest correct fix is to narrow the sentence
rather than strengthen the check. Row 3 is that row and the design took it: the probe, the endpoint,
the name, the type, the timing and the three classes are all untouched, and only what the sentence
claims changes. Covering all three branches rather than only `[OK]` costs the same one clause and is
required by OQ-9/BC-12 — a cached negative is held far longer than a positive, so "returned no
records — try another node" can restate a failure the user already repaired and propose a step that
cannot help. Spelling the clause four times (two English keys, two `zh` values) rather than factoring
it is correct under this project's whole-sentence key model; a shared fragment would be new
machinery inside `t()`. Nothing enforces the byte-identity, hence BC-H.

### The size argument

NFR-3's bar is `+40/−20` on `bin/sc`; the projection is `≈ +50/−40`. The design's answer is that
total churn is the honest ruler and that ~35 of ~50 added lines are docstring and translated-sentence
text. I accept the discharge and reject the ruler swap. A design does not get to redefine the bar a
contract states; it gets to discharge the burden the bar imposes, which is a different act. The
burden is discharged here on three checkable facts, not on the substituted number: no new top-level
`def` or `class` (K-1, AC-16, and I confirmed no edit introduces one); ~15 executable added lines;
and every removal is a replaced line, so no behaviour is deleted. The `−20` half genuinely is
unreachable for a task whose deliverable is re-worded sentences — each rewording costs one removal by
construction — and the comparison holds: ≈90 total churn against T-25's 121, T-24's 134, T-23's 127,
with T-25 having shipped a whole output contract with no new function at all. Recorded as F-9 and
capped by BC-G so the argument cannot quietly widen during implementation.

## Duty 2 — the BC-10 discharge, re-run

I re-ran the literal probe myself, read-only, over the same installed artifact. **No request of any
kind was issued to the live Clash API, and nothing under `/etc/sing-box` or `/var/lib/sing-box` was
read or written.** Reproduced:

| literal | my count | design's count |
|---|---|---|
| `clashapi.cacheRouter` | 1 | 1 |
| `disable_cache` | 4 | 4 |
| `/proxies` | 3 | ≥1 (calibration) |
| `/dns/query` | 0 | 0 (its own negative control) |
| `no_cache` / `bypass_cache` / `skip_cache` / `cache_bypass` / `fresh=` / `refresh=` | 0 | 0 |

The calibration and the negative control both hold, and the design is honest about the limit it
creates: `/proxies` survives as a literal while `/dns/query` does not, so a 0 in this artifact carries
information but does not prove absence. A literal search cannot exclude a parameter whose key is
assembled at runtime or spelled in a way my list does not contain.

**That limit does not matter, and the reason is the discharge's second leg.** Even granting a
cache-control parameter, the DNS-JSON body this endpoint returns carries no cache-hit indicator, so a
row asserting "resolved upstream on this query" would be inferring that the parameter was honoured —
one proxy swapped for another, which is exactly the defect FR-1 forbids. Distinguishing a hit needs a
second request comparing TTLs, forbidden by NFR-2 and AC-11. So the narrowed claim in FR-8 is true in
the world where the parameter exists and in the world where it does not, and FR-9's replacement clause
was stage-2-gated by construction.

**Ruling: BC-10 is discharged and does not survive to stage 6. RS-2 is upheld as written** — a later
QA observation of a cache-control parameter does not reopen this task. BC-I records the one
qualification: such an observation is filed as a pool candidate and an insight, and is never
exercised against the live service.

## Duty 3 — the R-22 lesson, applied to a diagnostic command

The trap in its sharpest form: all three of these rows already report OK, or a confident PROBLEM, on
a host where the thing is broken, so any criterion that merely re-asserts a row's current behaviour
would certify the defect. I tested each HEAD-failing label against the shipped line rather than
against the analyst's word:

- **AC-1** — `bin/sc:2717` is `_aaaa_rule(suppress) in rules`, a membership test with no position;
  a rule at index 3 reads `[OK]`. Discriminating, label correct.
- **AC-2** — `:2721-2722` names regeneration and nothing else. Discriminating.
- **AC-3** — HEAD's probe contains no expression that defines a position at all. Discriminating.
- **AC-5** — with `SYSTEMD = OPENRC = False`, `is_running()` returns `False` from its final line
  (`:2208`), `stored_delays()` short-circuits at `:2231-2232`, and `:2854-2857` renders `0/2`.
  Discriminating.
- **AC-9** — `:2869-2871` prints "resolved in {ms} ms, through the running sing-box", naming no
  cache and asserting an upstream resolution. Discriminating.
- **AC-10** — `:2865-2867` and `:2873-2875` keep the classes and carry no clause. Discriminating on
  the clause half, control on the class half, exactly as labelled.
- **AC-12** — `:3209` prints the short sibling with no escape named. Discriminating.

The seven labels are honest. The controls (AC-4, AC-6, AC-7, AC-8, AC-11, AC-13, AC-14) are genuine
regression guards, and AC-15 is fidelity by construction as stated.

**Where a control is hiding a criterion that should discriminate.** FR-6 forbids a row stating a
count no request produced. AC-5 covers the init-less host. AC-6 covers "request issued, answer
readable, no `history`" — and in that state HEAD and the candidate agree on class and numerals, so
control is the right label. But the state I-6's rewrite actually exists for is the third one:
`/configs` answers and `/proxies` does not, where `stored_delays()` returns absence from
`:2236-2240` and HEAD renders "0/N nodes carry a stored delay — either no probe has completed yet or
every node is failing", a claim about the world that no answered request established. That is an
R-48-class defect inside R-49's own row, it is inside FR-6, and no criterion observes it; `RS-3`
names the state but routes it to the delivery pool. Hence F-1 and BC-A.

Separately, the node-delay matrix never observes (init reports stopped, API answers), which is where
E2's mechanism is most visible under an init system — HEAD issues no request and prints `0/N`, the
candidate reads the real delays. RS-1 is right that this fixture is incoherent **for AC-7**, whose
subject is "no request is issued"; read carelessly it reads as a ban on the fixture altogether. Hence
F-2 and BC-B, which state the expected observable so stage 6 cannot misfile it as a regression.

On fixture coherence I agree with the design on all three of its own flags: RS-1's reasoning is
correct (an answering API on a host whose init reports stopped describes a live process, and reading
`/proxies` there is the fix); R-2's `sc.SYSTEMD = True` **plus** stubbed `subprocess.run` is
mandatory or the matrix agrees vacuously — that is this project's indexed 2026-08-14 trap and V-5/V-6
are self-checking about it; and R-3's Clash port in the fixture's **own** `settings.json` is the
indexed `CLASH_PORT` twin of the `LANG` vacuity trap, with V-5's HEAD half required to show
`/configs` in the stub log or the fixture is void. That last requirement is the right shape: a
fixture that must prove itself before its result counts.

## Duty 4 — the T-20 invariants

**No second opinion.** E2 removes one, which is the invariant cutting in its own favour. E1 adds no
validator and introduces no second liveness or decision source; after the signature change
`_dns_overlay()` no longer calls `ipv6_decision()`, so `_doctor_ipv6()` may call it without the run
reading the address source twice or printing the stderr warning twice — the objection its own
docstring records at `bin/sc:2685-2687` is removed by the change, not overridden by it. The call
count per command is unchanged everywhere.

**Process-wide read-only.** `_dns_overlay(suppress)` after E1 is a dict literal built from
`_aaaa_rule(suppress)`, which is pure by its own contract and by reading. No path is opened, no
service is touched, and the `doctor` arm still reaches neither `_init_files()` (whose hard-coded
`/var/lib/sing-box` is the project's first indexed insight) nor `_resolve_clash_port()`. Calling a
config-generation helper is safe here **because the helper composes nothing and writes nothing** —
`_compose`, `_merge` and `generate_config()` are all outside the doctor's reach and all frozen.

**`DOCTOR_SECTIONS`.** Untouched and frozen; order stays decided in one place at `bin/sc:2976-2986`.

**T-20's own rollback, tested in reverse.** Does E1's new PROBLEM class fire on a host state that is
actually fine? Yes, in one state: a user `override.json` that legitimately inserts into `dns.rules`
ahead of the AAAA rule. On such a host AAAA suppression is still in force for every query the user's
rule does not match, and the row will say PROBLEM and the command will exit `1` where it exited `0`.
I weighed this against T-20's actual mistake and it is not the same magnitude: T-20's clean-host row
was false on **100 %** of default installs because `settings.json` is 0644 on every one of them; this
fires only on hosts carrying an override that writes to `dns.rules` specifically. It is also ruled by
contract — OQ-1 clause 3 rejects narrowing because the class carries the verdict, BC-4 admits the
consequence explicitly, I-5 names the override as a cause to check without asserting that the user's
rule preempts anything, and I-9 publishes it in both READMEs. I did not reopen it. I did find that
BC-4 and I-5 name only `$prepend` while `$before`, `$after` and `$replace` on `dns.rules` reach the
identical row, and that for a `$replace` cause the regeneration route is ineffective because
regeneration reproduces the override — the sentence's second clause still points at the right file,
which is why F-8 is LOW and BC-F only protects that clause from being dropped.

**Blast radius.** Confirmed correct for the section it is actually in. The insight-index entry of
2026-08-15 is about `_doctor_clash()`, which returns four rows as one list, so one exception collapses
four rows into one. `_doctor_ipv6()` is a single-row section at `bin/sc:2980`, so I-3's deliberate
`KeyError` on a renamed directive costs exactly one row and renders
`[UNKNOWN] IPv6 (AAAA): this check could not run: '$prepend'` through `cmd_doctor`'s envelope at
`:3006-3013` — which is V-4's expected string, verbatim. Loud and cryptic beats silent and wrong, and
here it is also cheap.

## The composition fact neither upstream document names

`_telemetry_overlay()` (`bin/sc:1851-1885`) is a **second `sc`-authored writer of `dns.rules`, today**.
It uses `$before` anchored on `{"clash_mode": "Global"}`, `_apply_directive` resolves that anchor by
search rather than by index (`:1409-1418`, `:1428-1438`), and `_compose` applies `_dns_overlay()`
before it (`:2092-2093`), so its rule lands at index ≥ 1 and the AAAA rule keeps index 0. `_filter_rules()`
only removes rules and keeps the AAAA rule because it carries no `rule_set` (`:1078-1099`), so
filtering cannot move it either. The position claim therefore survives — but it survives by an
argument about anchor resolution and composition order that neither document makes, on a
configuration state a large fraction of hosts are actually in.

Two consequences. First, BC-5's premise is stronger than BC-5 states: the multi-writer world is
present tense, not future, which makes E1's coupling of emitter and probe better bought than the
design argued. Second, no verification step composes a `telemetry: block` fixture, so the interaction
is asserted rather than observed — F-3 and BC-C. This is the single item I would most regret waving
through, because it is the one place where "the row reports OK on a host where the thing is fine"
could invert into "the row reports PROBLEM on a large class of healthy hosts" if a future edit reorders
the compose list.

## Verified good, recorded so a later stage does not re-litigate

- **The R-24 ride-along is genuinely one line.** `cmd_telemetry`'s sentence at `bin/sc:3271-3272`
  with its `zh` half at `:209` is true of the IPv6 case word for word: `cmd_ipv6` reaches `:3209`
  only after `save_settings()` has persisted `settings["ipv6"]` (`:3201-3203`), and the state the
  sentence names — a document generated before the setting existed — is exactly what `sc reload`
  repairs. The key at `:192` has exactly one consumer, so deleting it is required rather than
  optional. BC-11's escape correctly not taken: keeping R-24 is net **negative** lines.
- **Ledger names.** Every downstream stage-doc filename the design names is exact:
  `03_GATE_REVIEW.md`, `05_CODE_REVIEW.md`, `06_TEST_REPORT.md`, `07_DELIVERY.md`, plus
  `02_RATIONALE.md`. `04_DEVELOPMENT.md` is not named anywhere and does not need to be. No
  malformed name appears.
- **R-78 prevention is adequate.** K-10 plus R-4's mitigation mandate the `docs/dev-map.md` recipe
  with `assert os.geteuid() != 0` first (`docs/dev-map.md:129-139`), all eight constants asserted
  inside the `mkdtemp()` root, and `sc.SYSTEMD = sc.OPENRC = False` by default — which is what stops
  an un-neutralised import re-execing `/usr/local/bin/sc` against the live service. The one hole is
  documentary, not procedural: the recipe's own line 136 still reads `open("bin/sc").read()` without
  `encoding="utf-8"`, so a stage that copies it verbatim under the locale every encoding criterion
  needs gets a `UnicodeDecodeError` that reads like a harness bug. K-10 names the fix at use time;
  F-7 and BC-J route the recipe itself to its owner rather than widening this task.
- **Credential contracts untouched.** No edit approaches T-13's credential handling or T-06's
  always-redacted `sc config`; no changed string carries a credential; no stage document produced by
  this gate contains any credential bytes.
- **`失败：` (R-75).** None of the five re-worded `zh` sentences in I-5…I-8 uses a failure noun, and
  K-9 plus V-14 grep every changed string. Checked against the proposed text, not only against the
  constraint.

## Why APPROVED WITH CONDITIONS and not a rollback

Every finding is dischargeable downstream without an upstream document changing its ruling. F-1, F-2
and F-3 add observations to a verification plan whose sentences are already specified — nothing needs
to be re-decided, only seen. F-5 narrows a frozen-set row that was drawn one line too wide. F-4 is a
correction of record to a rejection whose conclusion stands. F-6, F-7, F-8, F-9 and F-10 are each a
one-line discipline on a stage that is already running. There is no FAIL in the audit and no finding
that requires the requirement analyst or the solution architect to hold the pen again, so routing back
would cost a round and change no ruling.
