> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

# T-25 — output-layer-contract · Design rationale

Upstream read: `01_REQUIREMENT_ANALYSIS.md` in full. `01_RATIONALE.md` opened under **T2.1** — FR-5
plus Q-6/Q-7 do not by themselves classify two byte phrases whose shape is *both* count and
fraction (`truncated: got {got} of {declared} bytes`, `{done}/{total} bytes ({pct}%)`); E-11/E-12/E-13
resolved them (§4). Rules loaded: `00-core`, `05-insight-index`, `50-singbox-cli` (via AI-GUIDE),
`70-doc-size`, `85-design-discipline` (in full). `CONTEXT.md` read; no new domain term is coined —
this task adds no concept, so the glossary needs no entry. `.harness/rejected-decisions.md` read
before deciding; §5's decline appended there.

## 1. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Bilingual rendering of every changed string | `t()` + `TRANSLATIONS["zh"]` | `bin/sc:131-471` | **Reuse untouched.** Only table *keys* change; the mechanism, the miss-fallback and the absence of an `en` table are all load-bearing (Q-1/Q-2). |
| Punctuation carried inside a translated string | `{reason}, {size} bytes, {age}` and its zh `，` | `bin/sc:290-293` | **Extend the existing convention** to `sc status` with one sibling key (I-6). No mechanism, one table row. |
| One invariant count form | the shipped `(s)` idiom: `{n} ruleset(s) failed to update`, `{n} path(s) …`, `... {n} more line(s) not shown` | `bin/sc:147,308,337-339` | **Reuse the idiom.** The compliant members prove the form already ships; the defective members adopt it. No helper, no second key. |
| Foreign text made output-safe | `_plain(text)` | `bin/sc:2461-2503` | **Reuse as-is** at four `cmd_status` sites. `sc doctor` already routes the same four value classes through it (`bin/sc:2865-2867`, `:2992`); FR-8 is literally "call the existing one". |
| Per-write flush before a child process runs | `_doctor_print`'s `flush=True` | `bin/sc:2978`, `:2993-2996` | **Do not copy.** It is the correct *local* fix for one function; copying it to `cmd_status` + `cmd_update_interval` is the patch-then-patch shape rule 85 forbids (§3). Left in place, unchanged. |
| Stream-level encoding tolerance | `sys.stderr`'s built-in `errors="backslashreplace"` (interpreter default) | insight index 2026-08-15 | **Reuse the same policy on stdout** rather than invent one: `⚠️` has survived on stderr since T-13 for exactly this reason. |
| Age vocabulary, status vocabulary | `_age_text()`, `_status_text()` | `bin/sc:1023-1055` | **Reuse.** The four ladder keys are edited in place; no second age or status renderer appears (T-19's `ruleset-timestamp-outside-the-single-reader` decline stays honoured). |
| Key/placeholder parity checking | `check-i18n-parity.sh` | `.harness/scripts/` | **Cannot reuse** — it is a Bash-`case` parser scoped to `install.sh` (Q-9, E-15). FR-3 is discharged by a one-time `ast` enumeration run **outside** the repository; the permanent gate is T-28's. |
| Test harness for `bin/sc` | the import recipe + eight repointed constants | `docs/dev-map.md:118-151` | **Reuse verbatim.** Every verification step uses it; nothing new is built. |

Nothing here is a new dependency: the only import added is `io` (stdlib, present since forever,
required because `TextIOWrapper` is the 3.6-compatible way to state the two stream properties).

## 2. Risk analysis

| # | Risk | Mitigation |
|---|---|---|
| R-a | **Line-buffered stdout changes the interleaving in `/var/log/sing-box/install.log`** (`install.sh:567` merges `sc update-rules`' streams). | The change can only move stdout lines *earlier*, into their write order — which is FR-6's whole point. The one ordering the code relies on is already explicit (`sys.stdout.flush()` at `bin/sc:3385` before the stderr aggregate) and is untouched (K-4). `.harness/scripts/restricted-network-regression.sh:238-284` asserts **counts** of `failed: ` / `OK (`, never order, and `OK (` is preserved verbatim (I-5). |
| R-b | **Double-wrapping `sys.stdout`'s buffer** — the original wrapper stays reachable through `sys.__stdout__` and both objects wrap one `BufferedWriter`, which could produce an `Exception ignored in: <_io.TextIOWrapper …>` at shutdown. | Nothing is written through the original after the swap (I-1 is the first statement of `main()`), interpreter shutdown flushes `sys.stdout` before any dealloc, and `TextIOWrapper.close()` short-circuits on an already-closed buffer. `detach()` was considered and rejected: it makes `sys.__stdout__` unusable and introduces an argument-evaluation-order trap (`encoding` must be read *before* the detach), for a hazard that is already closed. `cmd_config`'s `os._exit(1)` path (`bin/sc:3126-3132`) is unaffected — it skips shutdown entirely. |
| R-c | **A string edit breaks the `失败：` diagnostic grep** — the pool's highest-consequence accident for this task. | Structural, not vigilance: every `zh` **value** in the edited set is byte-identical to HEAD, so no Chinese text is authored at all except `，` (I-6). K-8 makes the enumeration over *rendered* strings in both languages the developer's deliverable, and `failed: {e}` / the config-check sentence are both in the frozen set. |
| R-d | **The developer "fixes" the whole punctuation family** — every `", ".join()`, both READMEs' samples, the zh sample's alignment — and AC-14 fails on an unbounded diff. | The design names FR-4's site as exactly one (`bin/sc:2423`; the grep for a printed literal separator outside `t()` returns that line and nothing else) and puts list joins, `README.zh-CN.md` and the zh alignment in `## Out of scope` / the frozen set. |
| R-e | **The FR-3 enumeration reports "pass" on a call site it could not resolve** — R-7's live blind spot re-created inside this task. | K-5 requires *undecidable with a line number* as a distinct outcome, and K-6 pre-names the three sites that must appear in it plus the rule-set-filename pass-through, so a report that shows zero undecidable sites is itself the failure signal. |
| R-f | **`sc ls` becomes unreadable on a non-UTF-8 host** because `●`/`→`/a CJK tag expand to escapes wider than their cells. | Accepted and stated (K-11): the requirement is that the run survives (AC-9/AC-10), and Q-11/Q-12 explicitly decline both a glyph promise and a character inventory. The alternative — dropping the characters — leaves user-supplied tags aborting the run, i.e. it does not satisfy FR-7 at all. |
| R-g | **A future command prints a heading and spawns a child again**, and someone re-derives a per-site flush. | I-8 puts the discipline in `docs/dev-map.md`'s reusable-utilities table with an explicit closing rule, and the design's own evidence is that `cmd_update_interval` (`bin/sc:3431-3435`) needs **no** edit under I-1 — the seam already covers a second, un-filed site. |

## 3. Rule 85 — the smaller alternative, and what the extra code buys

**Rejected smaller alternative (FR-6 in isolation): copy `_doctor_print`'s `flush=True` to the four
prints that precede a child process** (`bin/sc:2413`, `:2418`, `:2421`, `:3431`). That is 4 edited
lines, no import, no new object, and it is the in-tree precedent (E-7).

It was rejected because it **does not satisfy the requirement set at all**: FR-7 is a separate
statement about the same stream, and no amount of flushing keeps a `UnicodeEncodeError` from ending
`sc ls` on a non-UTF-8 host. Taking the flush route means *also* writing an encode-safety
mechanism — realistically a `print` wrapper or a `_safe(text)` helper applied at every call site —
which is a formatter by another name and is explicitly out of scope (out-of-scope 1). So the
comparison is not "4 lines vs 4 lines"; it is:

| | smaller-looking route | I-1 |
|---|---|---|
| FR-6 | 4 site-local `flush=True` | inherited by every present and future site |
| FR-7 | needs a second mechanism at N call sites | same statement, same line |
| BC-8 (`sc config`) | needs its own third fix (`sys.stdout.write` at `bin/sc:3123`) | inherited |
| total | ~4 + N edits + one new helper + one new convention | **1 import + 3 statements**, 0 helpers, 0 call-site edits |

So the *smaller* design here is the one-construct design, and it is taken for that reason rather
than for coherence. What the extra 3 statements buy over the 4-line flush patch: FR-7, BC-8, and
the second FR-6 site the filed row never mentioned (`cmd_update_interval`), with zero call-site
edits. Under the deletion test, deleting I-1 makes the complexity reappear at ~10 call sites in
three commands; it earns its keep. Its interface is three keyword arguments and it is exercised by
every `print()` in the file — depth without a new name.

**Also rejected, all larger, none adopted:** an `en` table (Q-2, ~250 rows of pure bulk); a plural
helper or a second key per phrase (Q-5, and NFR-3 makes two forms a grep regression); a `_out()`
print wrapper (a formatter at every call site, and it cannot fix `argparse`'s own output); a
character inventory (Q-12 — leaves user tags aborting the run); forcing `encoding="utf-8"` on the
stream (changes the emitted bytes on a host whose consumer cannot decode them, and claims a
readability guarantee AC-10 deliberately does not make); a `LANG == "zh"` branch for the separator
outside `t()` (a second i18n mechanism to keep correct forever, versus one table row).

**Where the owner's shape was already right and is kept:** the requirement's five-front framing
(strings / separator / plural / order / encoding) collapses to exactly two homes plus one reused
function. No front was re-homed to another task and none was invented.

## 4. The two contested count phrases (D-2)

`{done}/{total} bytes ({pct}%)` (`bin/sc:228`) — **unchanged**. Q-7 binds the literal `{n}/{total} …`
shape and says a plural noun after a fraction is correct for every value; this is that shape, and
`0/1 byte(s) (0%)` would be worse to read than what ships.

`truncated: got {got} of {declared} bytes` (`bin/sc:230`) — **changed** to `byte(s)`. It carries no
slash in English, its noun's number reads off `{declared}` alone (`got 0 of 1 bytes`), and E-11
lists it inside the byte family while E-12's fraction exclusions name only the three slash phrases.
Q-6's principle — excluding a family member because its wart is milder re-creates the
"fixed for this one" defect — settles the tie. Cost of being wrong either way: one table row.

`at {at}: {name} matched {count} elements …` (`bin/sc:370`) — **unchanged**, per E-13 and verified
first-hand: `bin/sc:1399` raises it only when `len(hits) != 1`, so the sentence cannot render
`1 elements`, and it is R-72's line. Listing it as a non-member with that reason is what AC-6 asks
for; changing it would be a wording change to a T-24 error sentence this task has no criteria for.

## 5. Decline recorded in `.harness/rejected-decisions.md`

Handle `per-print-flush-instead-of-one-stdout-configuration`, declined, with §3's reasoning and this
task as origin. Appended by stage 2 so a re-proposal (the obvious one, since `_doctor_print` is the
in-tree precedent) finds the ruling instead of re-litigating it.

## 6. Size estimate, measured against the batch bar

Recent bar: T-22 `+21/−11`; T-23 `bin/sc +76/−51`; T-24 `+79/−55` including two READMEs.

| file | estimate | composition |
|---|---|---|
| `bin/sc` | **≈ +47 / −35** | stream statement + import + its comment `+9/−0`; `TRANSLATIONS` keys and comment `≈ +19/−19` (16 keys touched, 1 added, every `zh` value unchanged); call sites `≈ +15/−12`; `_plain()` at four `cmd_status` sites `+4/−4` |
| `README.md` | ≈ +6 / −6 | one sample block, captured not composed |
| `docs/dev-map.md` | ≈ +8 / −3 | the convention bullet + one reusable-utilities row + one clause |
| `.harness/rejected-decisions.md` | +10 / −0 | stage-2 authored, not the developer's |
| **total** | **≈ +71 / −44** | of which ~40 lines are **data** (table keys), not machinery |

In band, and the machinery share is 3 statements. NFR-4 forbids a numeric cap, so this is an
expectation for the gate to test against, not a limit for the developer to meet.

## 7. What the gate should attack hardest

1. §3's claim that the one-construct route is *smaller*, not just better — test it by pricing the
   flush route's FR-7 obligation honestly (it cannot be zero).
2. K-3's guard: does `getattr(sys.stdout, "buffer", None) is None` really cover both `sc config >&-`
   (`sys.stdout is None`) and a `StringIO`-substituting harness, and does the guard itself never
   raise? BC-6 says "no worse than today", not "better than today".
3. The D-2 classifications, both directions.
4. Whether any string in I-3…I-6 can reach `install.log` and collide with `失败：` (K-8) — the
   `zh`-values-unchanged argument is the whole defence and it must hold key by key.
5. Whether I-2's six headings really keep every column start offset (AC-3 arithmetic:
   4/2/10/30/25/9 with two-space gutters), and that `#` is not silently `str.format`-significant.
