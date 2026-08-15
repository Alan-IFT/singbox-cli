> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

# T-25 — output-layer-contract · Gate rationale

Boundary rule: `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` on this
project (Q-16, R-37), so the contract schema was applied as written and everything below — the
re-derivations, the verified-good notes and the discriminator table — lives here.

## 1. Rule 85 — I re-priced the rejected route rather than accepting §3

The design's own framing is that the flush route "only looks smaller". I tested that from the
other end, by asking what the *smallest possible* construct for FR-6 + FR-7 is on this project's
3.6 floor, and the answer is I-1's shape:

- `sys.stdout.reconfigure(...)` would be one line with no import, no second object and no
  `sys.__stdout__` hazard at all — and it is 3.7-only. K-2 and `docs/dev-map.md:93-95` are right to
  exclude it; NFR-1 makes that binding, not stylistic.
- `sys.stdout.errors` is a read-only attribute, so FR-7 cannot be met by assignment.
- `PYTHONIOENCODING` cannot be set for a process already running without a re-exec, which is
  strictly larger than a re-wrap.
- Therefore `io.TextIOWrapper(sys.stdout.buffer, …)` is not merely the design's choice; it is the
  only construct on the floor. And once the re-wrap exists for FR-7, `line_buffering=True` is a
  keyword on a call already being made — FR-6 costs **zero additional lines**.

The converse: FR-7's cost on the flush route cannot be driven to ~zero, because Q-11 states FR-7
over the *stream* and over *user data*, so no enumeration of call sites closes. Any flush-route
FR-7 needs a wrapper applied everywhere, which out-of-scope 1 forbids by name, plus `sc config`'s
own `sys.stdout.write` at `bin/sc:3123` and `argparse`'s sub-parser help (the sub-parsers created
at `bin/sc:3672-3690` default to `add_help=True`, so `sc use -h` really does print to stdout —
the top-level parser's `add_help=False` narrows but does not remove that claim).

So the smaller design wins here **and it is the one stage 2 took**. This is the opposite outcome
to T-23's and T-24's gates, and it is reached the same way: by pricing rather than by deferring.

The one place §3 does not survive contact: it prices the rejected route at four `print()`s. Under
block buffering `cmd_status`'s children write fd 1 directly while every Python `print` sits in the
buffer, so flushing `bin/sc:2413` and `:2418` (each immediately followed by a child at `:2415`/
`:2417` and `:2419`) restores the whole order; `:2421` is followed by `:2422-2423`, which are pure
Python prints whose mutual order the buffer already preserves. Three sites, not four — a correction
that *favours* the rejected route and still does not change the ruling. It matters only because
`.harness/rejected-decisions.md` is memory-layer and will be read years from now (C-11).

Over-build check, which is the other half of rule 85: the ledger adds one import, one guarded
statement, key edits, four `_plain()` calls and two document edits. No `en` table, no catalogue, no
formatter, no plural engine, no new file, no new function, no new concept. The batch's stated
over-build risk did not materialise.

## 2. D-2, ruled in both directions

- `{done}/{total} bytes ({pct}%)` — **unchanged, and the architect applied the right authority.**
  Q-7 is a contract row and E-11 is rationale; where they pull opposite ways the contract governs,
  full stop. The merits agree: the noun follows `{total}`, `0/1 bytes` is idiomatic and
  `0/1 byte(s) (0%)` is worse, and the phrase is emitted only under `if tty:` (`bin/sc:1194`), so
  it can never reach the captured report NFR-3 is written to protect.
- `truncated: got {got} of {declared} bytes` — **changed, correctly.** Q-7's literal scope is the
  slash shape `{n}/{total} …`; this phrase has no slash in English, and `got 0 of 1 bytes` is
  reachable whenever a server declares one byte and delivers none. It is a count phrase by FR-5's
  own test.
- `at {at}: {name} matched {count} elements …` — **unchanged, verified first-hand.** `bin/sc:1399`
  is `if len(hits) != 1`, so `{count}` is `0` or `≥2` and the sentence structurally cannot render
  `1 elements`; `matched 0 elements` is correct English and BC-3 is satisfied without a change.
  E-13 is sound.

What the three rulings expose is F-8: the population was decided by a **reachability** test twice
and by a **family** test once, and `larger than {n} bytes` is the phrase where the two disagree.
`OVERRIDE_MAX_BYTES` is `1024 * 1024` at `bin/sc:1256` with one call site at `:1536`, so `{n}` is a
compile-time constant and `byte(s)` makes a fixed sentence read worse for no reachable benefit. Q-6's
"do not exclude a family member because its wart is milder" is a real principle and I am not
overriding it — I am asking that one test be stated and applied once (C-8). Cost of being wrong
either way remains one table row.

## 3. The R-22 duty — every rendering criterion tested as a discriminator

For each, the wrong build that would still pass:

| criterion | discriminating? | the build that would still pass |
|---|---|---|
| AC-1 | **yes** | none reachable — it compares against the *words* (`Type`, `Name`, `Address`, `Delay`) and adds the `.` clause, and `ls.idx` fails both. This is the criterion that satisfies the R-22 requirement: it tests the word the key means, not a property (ASCII-ness) the key name also has. |
| AC-2 | yes | none — byte-identity against a HEAD clone |
| AC-3 | yes | none — offsets are computed from emitted text; HEAD overflows at two columns |
| AC-4 | partly | a build shipping a present-but-wrong `zh` value: AC-4 tests *presence*, not FR-3's "readable". Acceptable — readability is not machine-decidable — but it should not be reported as proving FR-3 whole. |
| AC-5 | yes | a day-only fix fails at hours/minutes/seconds; the 129600 s case pins the coarse-unit rule |
| AC-6 | yes | the listed population is the evidence; a narrowed population fails on its own face |
| AC-7 | zh half yes, en half no | the English half (`, ` on both screens) is passed by HEAD unchanged — by design, since I-6 keeps English byte-identical. It is a no-regression check, not a discriminator, and reading it as one would be the error. |
| AC-8 | yes | self-validating: it *requires* HEAD to show the inversion, or the fixture is declared unable to detect the defect |
| AC-9 | yes | self-validating twice: `PYTHONUTF8=0` proof recorded, and the control must abort |
| AC-10 | by inheritance | on its own it names no control; it is discriminating only through "same environment as AC-9". The report must carry the shared proof, or a fixture that quietly kept UTF-8 mode passes AC-10 on HEAD. |
| AC-11 | yes | it is a census whose absence is itself the failure |
| AC-12 | **NOT-DISCRIMINATING** on its comparison clause (F-2) | any build at all: `sc doctor` prints no routing mode, so "identically to what `sc doctor` prints" compares against nothing. This is the pool's sharpest instance of the R-22 trap and it is reported, not passed. |
| AC-13 | **NOT-DISCRIMINATING** as written (F-3) | a fixture with `SYSTEMD`/`OPENRC` both false: `is_running()` returns `False` from `bin/sc:2195`, `=== Route mode ===` never prints, and "sc adds no line" is true of an empty screen |
| AC-14 | yes, but fails on correct code unless pinned (F-9) | — |
| AC-15 | yes | none — character-by-character against a real capture; but see F-4, the capture is not obtainable as specified |
| AC-16 | yes | none — byte-identity plus the baseline counts, from the repository root |

Reporting two criteria NOT-DISCRIMINATING is the T-24 (R-71) outcome repeated deliberately.

## 4. K-3's guard, checked against the actual code

`getattr(sys.stdout, "buffer", None) is not None` covers both arms and cannot itself raise:

- `sc config >&-` / `sc ls >&-`: CPython's stdio initialisation sets `sys.stdout` to `None` when fd
  1 is not a valid descriptor, and `getattr(None, "buffer", None)` returns `None` rather than
  raising, because `getattr`'s three-argument form suppresses `AttributeError`. I-1 is skipped and
  the run reaches exactly today's path — `print()` is a no-op with a `None` stream, and
  `cmd_config`'s `sys.stdout.write` at `bin/sc:3123` raises the `AttributeError` it raises today.
  BC-6's "no worse than today" is met; it does not promise better, and the design does not claim it.
- A `StringIO` substitution: no `buffer` attribute, so the guard skips. Correct — and this is
  exactly what makes F-10 worth filing, because the same correctness silently disables I-1 in a
  harness that captures stdout the convenient way.

## 5. R-a and R-b, verified against the files

R-a holds. `.harness/scripts/restricted-network-regression.sh:238-242` are `grep -c` counts of
`failed: `, `ruleset(s) failed to update`, `degraded to no-splitting mode`, the log path and
`is not writable`; `:249-250` matches entry boundaries (`failed: $b -> ` / `; $b -> `) within lines
that already contain `failed: `; `:284` is `grep -cF 'OK ('` and `grep -cF 'failed: '`. Not one of
them asserts an order. I-5 preserves `OK (` verbatim because only `bytes` → `byte(s)` changes, and
the aggregate key `{n} ruleset(s) failed to update` (`bin/sc:147`) is not in the edited set at all.
The cause text that changes (`truncated: … byte(s)`) travels inside a `failed: ` line as
`base + " -> " + str(e)` at `bin/sc:3333`, which neither count reads.

R-b holds on the mechanism the design names: nothing is written through the original wrapper after
the swap (I-1 is `main()`'s first executable statement — `bin/sc:3669` is a `global` declaration,
not executable, and `:3670` is the parser construction), interpreter shutdown flushes `sys.stdout`
before any dealloc, and `TextIOWrapper.close()` short-circuits on an already-closed buffer. The
rejection of `detach()` is also right for the stated reason and for a second one the design does not
need: `detach()` would break `cmd_config`'s `os._exit(1)` reasoning at `bin/sc:3126-3132`, which is
written against the current object graph.

## 6. AC-11, key by key

Every edited `zh` value read at HEAD: `序号` / `激活` / `协议` / `名称` / `地址` (`bin/sc:242-246`),
`{n} 秒前` / `{n} 分钟前` / `{n} 小时前` / `{n} 天前` (`:223-226`), `成功（{size} 字节）` (`:212`),
`{done} 字节` (`:229`), `传输不完整：收到 {got}/{declared} 字节` (`:230`),
`{reason}，{size} 字节，{age}` (`:290`), its stale sibling (`:292-293`), `超过 {n} 字节` (`:358`).
None contains `失败`. I-6's only authored Chinese is `，`, and its substituted fields draw from
`_status_text` (`可用` / `缺失` / `不是规则集文件` / `文件过小` / `无法读取`, `bin/sc:1031-1037`) and
`_age_text` (`bin/sc:1049-1055`, including `更新时间未知`). No edited English key contains
`failed: `. The defence holds key by key — which is why C-7 asks the developer to reproduce the
table rather than cite this paragraph: the value of that enumeration is that it was made against the
build, and mine was made against HEAD.

## 7. Verified good, worth recording

- AC-9's fixture requirement "at least one active node" is load-bearing, not decorative: the `●`
  at `bin/sc:2309`/`:2313` and the `→` at `:2308` are what raise under an ASCII stdout, and a
  node-less fixture would print only the `(no nodes …)` line and certify nothing.
- K-6's three indirect `t()` sites are exactly the three that exist in the file — no fourth.
- I-6's English rendering is byte-identical to HEAD's `"%-20s %s, %s"`, so AC-14's guard is not
  self-defeating on the one line FR-4 changes.
- FR-1's "no `identifier.identifier` key" is satisfiable: the five `ls.*` keys are the only ones of
  that shape in `bin/sc:131-385`, and K-5's call-site enumeration is what would find a sixth that a
  table scan cannot see.
- The `.harness/rejected-decisions.md` heading format matches the file's recent convention
  (backticked handle + date + task id), so L-7 needs no stylistic correction — only F-6's number.

## 8. Why the L-7 write was in-bounds

Three reasons, in order of weight: the file's own header instructs "**append** when something is
deliberately declined" and names no stage; T-24's record at `:551-552` carries the provenance
"stage 2 (`## Smaller alternative rejected`), corrected at stage 3", so this project's established
shape is stage 2 writes and stage 3 corrects; and the record's purpose — that the obvious
re-proposal finds the ruling instead of re-litigating it — is only served if it exists before the
developer reads the design. It should stand. The two riders in C-11 are that it is memory-layer and
therefore outlives the task folder (so an abandoned T-25 leaves it needing review), and that "one
record per concept" means the F-6 correction is made **in place**, never as a second record.
