> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

Everything here is evidence, reasoning or a rejected reading. Nothing in it overrides the contract
portion. It lives here because `.harness/rules/70-doc-size.md` still defines no
`## Stage-doc boundary rule` (R-37, eighteenth confirmation) and the reviewer contract's section
schema has no shape that holds a byte-form transcript.

## How this review was conducted, and what that limits

Stage 5 was dispatched with `Read` / `Grep` / `Glob` only. No `git diff`, no `git show`, no
`git stash`, no numstat, no execution of anything. The review is therefore a **first-hand read of
the delivered working tree against the four upstream contracts**, plus grep-based counting where a
count was owed.

What that reaches: every shipped string, every signature, every call site, every guard, every
docstring, the two READMEs' mirrored lines, the dev-map rows, the glossary term, the changelog
entry, the top-level `def`/`class` count, and the absence of tokens (`membership`, `失败：`, a second
`Nothing changed` key, the old DNS `resolved in` string).

What it cannot reach: the *shape* of the diff — how many lines were added and removed, and whether a
line I read as pre-existing was in fact touched. Two obligations depend on that shape (BC-G's
numstat, AC-17's `git status`). I discharged each by a surrogate I could measure and routed the
machine measurement forward (RES-1) rather than either passing it on the developer's word or
blocking a delivery over a tool I was not given. Recording the substitution is the point: a reviewer
who quotes a number he did not measure, without saying so, reproduces the exact defect this task
exists to remove — a sentence claiming more than its probe established.

Rationale siblings opened: `04_RATIONALE.md`, under **T5.2** (adjudicating the developer-recorded
`DESIGN DRIFT` D-1). `02_RATIONALE.md` was not reached — no design-fidelity finding turned on why
the design chose a shape, and no reuse-correctness or risk finding was raised (T5.1 and T5.3 did not
fire). Every identifier cited in every contract row I acted on is defined in a contract portion, so
T5.4 did not fire either.

## BC-H, per key, both halves

The comparison was made by reading the four table entries and the four call sites and aligning them
character by character from the em-dash to the end. Source-level line continuations differ between
the table (single-line `zh` values, wrapped English keys) and the call sites (three-part
concatenations); both resolve to the same bytes.

English clause, from `bin/sc:338` and `:340`, and from the sites at `:2873-2875` and `:2882-2884`:

```
try another node with `sc use <n>`; an answer already cached by the running sing-box survives a node change
```

Chinese clause, from `:339` and `:341`:

```
可用 `sc use <编号>` 换一个节点试试；正在运行的 sing-box 已缓存的应答不会因为换节点而失效
```

Placeholder sets, all five re-worded keys:

| key line | en placeholders | zh placeholders | set-equal |
|---|---|---|---|
| `:309` / `:310` | `{decision}`, `{override}` | `{decision}`, `{override}` | yes |
| `:334` / `:335` | `{total}` | `{total}` | yes |
| `:336` / `:337` | `{name}`, `{ms}` | `{ms}`, `{name}` | yes (order is rendering order) |
| `:338` / `:339` | `{name}`, `{ms}` | `{name}`, `{ms}` | yes |
| `:340` / `:341` | `{name}`, `{ms}` | `{ms}`, `{name}` | yes (order is rendering order) |

The deleted key: grep for `Nothing changed` over `bin/sc` returns exactly one table entry
(`:208-211`) and two call sites (`:3219-3220` in `cmd_ipv6`, `:3282-3283` in `cmd_telemetry`). Both
sites concatenate to the table key byte for byte. The short sibling that lived at `:192` is absent
from the file. E4 and E5's "one deleted, none added" is therefore confirmed structurally, not
counted: a surviving orphan would have shown up in this grep, and a new key would have had to appear
in the region I read (`:180-220`, `:300-350`), which it does not.

## Why CR-1 is MINOR and not a NIT, and why it is not MAJOR

Not a NIT, because it is not a preference: the sentence is **false as written** after E2, in a file
whose docstrings are this repo's contract surface, in the one task whose entire subject is sentences
that outlive the check they describe. `docs/dev-map.md:65` gets it right in the same delivery, which
is what makes the code sentence a divergence rather than a shared imprecision.

Not MAJOR, because the immediately following paragraph (`bin/sc:2225-2227`) narrows it explicitly
and is joined to it by "therefore", so a reader who reads the docstring — which is how a docstring is
read — arrives at the correct contract; no behaviour, no caller and no published sentence depends on
the first paragraph standing alone.

## Why CR-2 is a finding at all

The developer disclosed a near-miss nobody would have found otherwise, in the contract portion,
with evidence. That deserves saying plainly, and it is why the finding is scoped to one sentence
rather than to the disclosure. But the sentence I flagged is the one a later stage will rely on:
"the final fixture drives `main()` only for `doctor` and `ipv6`" reads as "the initialising arm is no
longer reached", and `bin/sc:3755` puts only `doctor` and `config` on the read-only arm. `ipv6` is on
the `else` arm with `ls`. So the final fixture reaches `_init_files()` for exactly the same reason
the rebuilt case did.

The host exposure is unchanged and nil — `CFG_DIR`, `RULES_DIR`, `NODES_PATH`, `SETTINGS_PATH` and
the rest are repointed and asserted inside the temp root, and the one un-repointable line
(`bin/sc:543`) is a `mkdir(..., exist_ok=True)` on a directory that already exists. Nothing was
written on the near-miss and nothing is written on the final fixture. What is at risk is the record,
not the host, which is why the routing is to stage 6's fixture note (RES-3) rather than back to the
developer.

## Rejected readings

**"`+55/−44` at the ceiling is a scope escape."** Rejected. BC-G's bar is stated as a strict
threshold — "if the delivered diff **exceeds** `+55/−45`" — and `55 ≤ 55`, `44 ≤ 45`. Treating the
ceiling as the escape would be inventing a rule at review time, which is precisely what a reviewer
may not do. The honest report is: inside the bar, at the ceiling, above its own `≈ +50/−40`
projection, with the trim's history disclosed in `04_RATIONALE.md` and no interface, contract
sentence or removal dropped to reach it.

**"D-1 is a scope escape because `ipv6_decision()` is in the frozen set."** Rejected, for the reason
given in the contract portion. The alternative — ship a docstring that names `_dns_overlay()` as a
caller of a function it no longer calls, while `docs/dev-map.md:58` says the opposite in the same
commit — would have produced a genuine finding, and a worse one.

**"FR-6's zero case should be UNKNOWN, so the shipped PROBLEM row is drift."** Rejected. BC-A, a
binding gate condition written before the code existed, ratifies the PROBLEM-with-three-causes
shape by name. A reviewer overturning a discharged gate condition on the requirement's letter, after
the design argued the point (I-6, out-of-scope 3) and the gate tested it, would be re-litigating a
closed decision rather than reviewing an implementation. The state where it matters is
unobservable from a read, and BC-A already routes it to stage 6.

**"NFR-2 is violated on init-less hosts."** Rejected, with the tension recorded rather than buried
(ruling R-c). A requirement that forbade the request would forbid FR-6, which the same document
mandates and OQ-3 rules non-negotiable; NFR-2's subject is a probe this build does not already make,
and `stored_delays()`'s `GET /proxies` is not one. The developer raised this themselves in
`04_DEVELOPMENT.md` rather than letting it pass silently, which is the behaviour that made it
cheap to adjudicate here.

**"The AAAA `[OK]` sentence should have been widened to say 'first'."** Rejected — and it would have
been a finding if it had been. AC-4 and I-5 keep that key unchanged deliberately. A row may claim
less than its probe established; FR-1 forbids only the reverse.

## What I did not do

No request of any kind was issued to the live Clash API. The installed `sc` was never run. `bin/sc`
was never imported, neutralised or otherwise. Nothing under `/etc/sing-box`, `/var/lib/sing-box` or
`/usr/local/bin` was read or written. No file in the repository was modified — including the four
upstream stage documents, the code under review and every configuration file. The batch runner's own
modifications under `docs/batches/**` were ignored as instructed and were not opened.
