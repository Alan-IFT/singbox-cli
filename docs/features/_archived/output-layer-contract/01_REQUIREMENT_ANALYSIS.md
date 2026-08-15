> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

# T-25 — output-layer-contract · Requirement Analysis

Mode: **full** (7 stages). Pool: `followups`. Decision authority: standing (owner), so every
ambiguity below carries a binding answer rather than a question.

## Goal

`sc`'s user-facing output has no single statement of how a line is produced, so five headings
render as their own translation keys, one fact is punctuated two ways across two screens, counted
nouns disagree with their counts, and a redirected run can print a child process' output above the
heading that introduces it or abort mid-line on a character the stream cannot encode.

## In-scope behaviors

**FR-1** — Every string `sc` renders through the translation layer has an English rendering that is
readable English text, and no user-facing line ever contains an internal identifier. A key that is
an identifier rather than its own English rendering does not exist in the shipped file after this
task.

**FR-2** — `sc ls` prints six column headings that name their columns in the user's language. In
English each heading is the English word for the column's content; in Chinese each is the word it
renders today, unchanged. The heading row's column start positions coincide with the data rows'
column start positions in both languages' ASCII-width sense — i.e. no heading is wider than the
field it labels.

**FR-3** — Every translation key that `bin/sc` can reach at a call site renders readable Chinese
under `lang: "zh"` and readable English under `lang: "en"`. This is established once, by an
enumeration taken **from the call sites** (a key named only at a call site is visible to it), not
from the translation table; the enumeration, its two counts and any offender it finds are recorded
in this task's stage documents.

**FR-4** — Punctuation that joins the fields of one rendered line is part of the translated string.
No format string outside the translation layer supplies punctuation between fields, so the same
fact is punctuated identically wherever it is printed. The rule-set line of `sc status` and the
rule-set rows of `sc doctor` render the same separator in the same language.

**FR-5** — A **count phrase** — a user-facing string in which a number is substituted next to the
noun it counts — renders **one form for every value of that number**, and no form asserts a
grammatical number the value does not have. The whole population is changed in one step; a phrase
whose noun is already invariant for every value is already compliant and is left alone.

**FR-6** — When `sc`'s standard output is not a terminal, every line `sc` writes appears in the
position in which it was written relative to output that a child process writes to the same
stream. This binds every command that prints a heading of its own and then lets a child process
write to that stream — today `sc status` and, on systemd, `sc update-interval`.

**FR-7** — A character in a user-facing line that the standard-output encoding cannot represent
does not end the run, does not change the run's exit status, and does not truncate the rest of the
line: the character is rendered in a degraded form and the run continues. This holds for characters
`sc` authors and for characters that come from the user's own data alike, and it discharges T-23's
AC-11/AC-12 process-exit clause.

**FR-8** — Every value `sc status` prints that `sc` did not author — a routing mode read from the
Clash API, an egress address read from a public endpoint, an exception's text, a node tag taken
from a share URL — is neutralised for a captured report by exactly the neutralisation `sc doctor`
already applies to foreign text, through the same single implementation. `sc` adds no line of its
own beyond the heading and the value it received.

**FR-9** — Every shipped document that publishes a rendering this task changes is corrected in the
same change: the English `sc ls` sample output in `README.md`, and the translation-key convention
bullet in `docs/dev-map.md`, which today records the identifier-key rendering as a pre-existing
defect and must instead state the convention FR-1 makes binding.

## Out of scope

1. No `en` translation table, no message catalogue, no formatter class, no i18n framework, no new
   module and no new file in `bin/sc`'s deployment.
2. No plural-selection mechanism, no per-language plural rules, no CLDR-style engine.
3. No change to `t()`'s key-on-miss fallback.
4. No new `verify_all` step and no edit to `.harness/scripts/check-i18n-parity.sh`; B.2 keeps its
   `install.sh` scope byte-for-byte. A permanent `bin/sc` key gate is T-28's.
5. No column-width or alignment redesign of `sc ls`; the double-width misalignment of Chinese cells
   is not fixed here.
6. No adoption by `sc status` of `sc doctor`'s `[CLASS] label: value` row shape or its verdict
   vocabulary.
7. No fix for the pre-existing collision between `sc`'s config-check failure sentence and the
   `失败：` diagnostic grep (Q-17); it is recorded, not repaired.
8. No change to the existing stderr policy, to the `⚠️` prefix, or to which stream a message uses.
9. No repair of R-21, R-49, R-50, R-64, R-65 or any other filed row that merely happens to touch a
   printed line.
10. No committed test suite, no `baseline.json` change, no `verify_all.ps1` change.
11. No new user-visible feature, flag, setting or command.

## Boundary conditions

**BC-1** — A string this task adds or edits would contain `失败：` or `failed: ` → it is not
adopted in that form. Over the whole edited set, those two literals keep meaning exactly "this
rule-set file was not updated".

**BC-2** — The count is `1` → the rendered phrase does not read as a bare plural noun; it renders
the same form as every other value.

**BC-3** — The count is `0` → the same single form renders; no phrase is special-cased for zero.

**BC-4** — A rule-set has no readable timestamp (`mtime` unknown, per T-19's digest contract) → the
word form renders, never a number and never a date. Unchanged by FR-5.

**BC-5** — A translation key has no Chinese entry → the English text renders. This is the designed
fallback, not an error path, and FR-3 establishes that the population is empty rather than changing
what the fallback does.

**BC-6** — Standard output is closed or absent (`sc ls >&-`) → whatever configures the stream must
not itself raise; the outcome is no worse than today's.

**BC-7** — Standard output is a terminal → FR-6 and FR-7 hold unchanged, and the terminal rendering
is identical to today's apart from the string changes FR-1 … FR-5 enumerate.

**BC-8** — The standard-output encoding cannot represent a character inside the document `sc config`
prints → the document is printed with that character escaped rather than the run aborting. The
existing guarantee that `sc config`'s output re-parses as JSON is stated only for an encoding that
can represent the document.

**BC-9** — A value `sc status` receives contains a line break → the value occupies the number of
lines it contains and `sc` adds none. "Exactly one value line per heading" is not promised.

**BC-10** — A value `sc status` receives is empty or absent → the existing unavailable/none wording
renders, unchanged.

**BC-11** — The child process a heading introduces is missing, writes nothing, or fails → the
heading is still printed, in order; FR-6 is satisfied vacuously and no new message is introduced.

**BC-12** — Two `sc` processes write to the same redirected file concurrently → no ordering is
promised between processes. FR-6 is a within-process guarantee.

**BC-13** — A node tag is longer than its column, or renders wider than its column in Chinese →
existing truncation and existing width behaviour are unchanged.

**BC-14** — The maximum size of any rendered value (a Clash API field, an egress body, an exception
message) is not capped by this task; T-19's BC-12 declined a size cap and this task does not
introduce one.

## Acceptance criteria

| id | criterion | class | verification |
|---|---|---|---|
| AC-1 | With `lang: "en"` and at least one node, `sc ls`'s heading row is six English words naming the columns: the heading over the index column means *index*, over the marker column *active*, and the remaining four are `Type`, `Name`, `Address`, `Delay` (Q-3 binds the exact six). No heading contains a `.`. | [B] | Run through `main()` on a fixture whose `settings.json` carries `lang: "en"` — never by assigning `sc.LANG`, which `main()` overwrites. Compare against the **words**, not against "is ASCII": `ls.idx` is ASCII and must fail this criterion. |
| AC-2 | The same fixture with `lang: "zh"` renders the six headings 序号 / 激活 / 协议 / 名称 / 地址 / 延迟, byte-identical to HEAD. | [B] | Same run, `lang: "zh"` in the fixture's own `settings.json`; diff against a pristine HEAD clone at the same fixture path. |
| AC-3 | In English, `sc ls`'s heading row and its data rows start each of the six columns at the same character offset. | [B] | Same run as AC-1; compute offsets from the emitted text. Discriminating: HEAD's 6-character `ls.idx` overflows a 4-wide field and fails. |
| AC-4 | Every translation key reachable at a `t()` call site in `bin/sc` is present in the `zh` table; both counts and any offender are reported. The enumeration is derived from the **call sites**, and a key named only at a call site is visible to it. | [S] | One enumeration, run once; ≤5 lines of result recorded per rule 70. A call-site key formed by implicit string concatenation across source lines must resolve to its whole value or be reported as undecidable — never skipped. |
| AC-5 | For each unit of the rule-set age ladder, the rendering at exactly 1 unit and at 2 units differ **only** by the substituted number, and the 1-unit rendering does not read `1 <plural noun>`. | [B] | Render at 0 s, 1 s, 60 s, 3600 s, 86400 s and 129600 s (36 h). Discriminating: a build that fixes only the day unit fails at hours, minutes and seconds. |
| AC-6 | Every count phrase in the enumerated population renders one form at counts 0, 1 and 2 in both languages; the population itself is listed. | [B] | Render each member at the three counts. The listed population is the criterion's own evidence — a build that narrows the population to the age ladder fails, because the byte-count and path-count phrases are members. |
| AC-7 | With `lang: "zh"`, the separator between the status word and the field after it is the same character in `sc status`'s rule-set line and in `sc doctor`'s rule-set row. With `lang: "en"`, both render `, `. | [B] | Both commands on the same fixture in the same run. Discriminating: a build that changed only one of the two screens fails. |
| AC-8 | `sc status` with its output redirected to a **file** prints every heading above the output of the child process that heading introduces. | [B] | Redirect to a real file or pipe, never a TTY — the defect does not exist on a TTY. The child must actually run (`sc.SYSTEMD = True` alongside any `subprocess` stub, or the section is skipped and the fixture sees nothing). Run candidate and a pristine HEAD **clone** at the same fixture path; HEAD must show the inversion, or the fixture cannot detect the defect. |
| AC-9 | Under a **proved** non-UTF-8 standard output, `sc ls` on a fixture with an active node and `sc add` of an all-ASCII share URL each print their whole output, exit with the status they carry under UTF-8, and produce no traceback. | [B] | The environment must include `PYTHONUTF8=0`; `LC_ALL=C PYTHONCOERCECLOCALE=0` alone leaves Python in UTF-8 mode and passes on broken and fixed code alike. Record the proof (`stdout` encoding and `getpreferredencoding()`) in the report. Control: the same runs on a HEAD clone must abort. |
| AC-10 | Under the same proved non-UTF-8 standard output, a node tag containing non-ASCII characters does not abort `sc ls`: the row is printed and the run's exit status is unchanged. No claim is made that the tag is readable. | [B] | Same environment as AC-9; assert on the row's presence and the exit status, never on the tag's glyphs. |
| AC-11 | Every string this task adds or edits is listed against the two literals `失败：` and `failed: `, and none introduces either into a line that does not mean "this rule-set file was not updated". | [S] | The list is the evidence; a claim without the enumeration does not satisfy this criterion. Assertions must be made against the **rendered** strings in both languages, since the Chinese rendering is where the collision has occurred before. |
| AC-12 | A routing mode carrying a CSI escape sequence and a carriage return prints under `sc status` with the sequence removed, identically to what `sc doctor` prints for the same input. | [B] | One injected value, both screens, same run. Discriminating: HEAD prints the escape under `sc status` and not under `sc doctor`. |
| AC-13 | A routing mode containing a line break yields, under its heading, exactly the number of lines the value contains — `sc` adds none. | [B] | The narrowed promise of BC-9, asserted rather than assumed. |
| AC-14 | Outside the enumerated string changes, the English output of `sc status`, `sc doctor` and `sc ls` is byte-identical to HEAD on the same fixture. | [B] | Differential run against a pristine HEAD **clone** (never a `git worktree`) at the same fixture path; the diff must be a subset of the enumerated set. This is the guard against an output change that reads better and greps worse. |
| AC-15 | `README.md`'s English `sc ls` sample matches what the shipped build prints for the same node list, and `docs/dev-map.md`'s translation-key bullet states the convention rather than recording the defect. | [S] | Compare the sample against a real rendering of AC-1's fixture, character by character. |
| AC-16 | `.harness/scripts/check-i18n-parity.sh` is byte-identical to HEAD, and `verify_all` reports no new FAIL and no new WARN against the task-start baseline (PASS 17 / WARN 0 / FAIL 0 / SKIP 1). | [S] | Run `verify_all` **from the repository root** — from a subdirectory it self-reports a false red. |

## Non-functional requirements

1. Every behaviour required here holds on the project's Python **3.6** syntax-and-API floor
   (`docs/dev-map.md`, "Patterns to follow"): no API introduced after 3.6 may be required by any
   requirement in this document, standard library only.
2. `bin/sc` remains one self-contained file; the change adds no runtime file and no third-party
   dependency.
3. Each rendered fact keeps **one** form for every value, so a single fixed pattern matches it in a
   captured report. Output that reads better but needs two patterns where it needed one is a
   regression (AC-14 is the guard).
4. No numeric size cap is imposed on the diff. Its size is bounded by the element lists FR-3, FR-5
   and AC-11 require to be enumerated; a cap set as a round number is what R-61 filed against.

## Resolved questions

| id | question | binding answer |
|---|---|---|
| Q-1 | Does `t()`'s "return the key on a miss" behaviour change? | **No.** The key *is* the English rendering by design; in English every lookup is a designed miss. The defect is a key that is not its own English rendering, which FR-1 removes. `.harness/rejected-decisions.md` § `t-fmt-default-fallback` already declined the analogous change for `install.sh`. |
| Q-2 | Is an `en` table added? | **No.** It would duplicate every key as its own value — bulk with no behaviour, and it would make the convention that the source reads as English text unenforceable. |
| Q-3 | What are the six English `sc ls` headings? | `#`, `On`, `Type`, `Name`, `Address`, `Delay`, in the existing column widths and order. `On` is two characters because the marker field is two characters wide, and FR-2 forbids a heading wider than its field. |
| Q-4 | Which separator convention wins? | **The translated string carries its own punctuation** (`sc doctor`'s convention). `sc status`'s rule-set line adopts it. English rendering is unchanged (`, `); Chinese changes from `, ` to `，`, which is the point. |
| Q-5 | What does "plural handling" mean concretely? | **One invariant rendered form per count phrase**, correct for every value — the idiom `{n} ruleset(s)` already ships. Not a plural-selection mechanism, not two keys per phrase, not language-specific plural rules. Chinese has no plural inflection, so any mechanism would serve one language's two forms. |
| Q-6 | Are byte counts in the count-phrase population? | **Yes.** R-40's row requires every count key at once; excluding a family because its wart is milder re-creates the "fixed for this one" defect the row exists to prevent. |
| Q-7 | Are `{n}/{total} …` fraction phrases in the population? | **No.** A plural noun after a fraction is correct for every value, so those phrases already render one correct form. |
| Q-8 | Does this task add a permanent key-parity gate for `bin/sc`? | **No.** FR-3 establishes the property once by enumeration in this task. The permanent gate is filed for **T-28**, which owns test infrastructure, with two required properties: it enumerates from **call sites** (B.2's live blind spot is that it enumerates from the tables, so a call site naming a key in neither table is invisible), and it reports "cannot decide" rather than "pass" when it cannot resolve a call site. |
| Q-9 | Is `verify_all` B.2 widened to cover `bin/sc`? | **No.** `check-i18n-parity.sh` stays byte-identical and stays scoped to `install.sh`'s shell `t()`; it parses `case` blocks and could not read Python call sites without a second parser inside one script. AC-16 makes this checkable. |
| Q-10 | Is T-23's AC-11/AC-12 *process-exit* clause in scope? | **In scope**, and discharged by FR-7 / AC-9. T-23 recorded it BLOCKED-BY-T-25 rather than passing or dropping it; the disk layer it closed is unaffected. |
| Q-11 | Does FR-7 cover user-supplied text as well as `sc`-authored characters? | **Both.** The requirement is stated over the stream, not over a character list, because a list is incomplete the day it ships and a node tag is user data. This is narrower in claim than "non-ASCII output is readable everywhere": AC-10 asserts the run survives, never that the glyphs do. |
| Q-12 | Does the population of FR-7 include a specific character inventory (`→`, `●`, `⚠️`, `—`)? | **No inventory is binding.** Those characters may stay exactly as they are; a design that removes them instead of satisfying FR-7 over the stream does not satisfy FR-7, because user data would still abort the run. |
| Q-13 | Is R-34's "exactly one value line per heading" promise repaired or narrowed? | **Narrowed** to BC-9 / AC-13: `sc` adds no line of its own. No shipped document publishes the wider promise, so no shipped text changes for it. |
| Q-14 | Does `sc status` adopt `sc doctor`'s row shape or verdict vocabulary? | **No.** T-19 already declined this; `sc status` is a facts screen and states no verdict. FR-8 reuses only the foreign-text neutralisation, which is not a verdict. |
| Q-15 | Does `sc ls`'s `●` marker or the help line that explains it change? | **No.** |
| Q-16 | `.harness/rules/70-doc-size.md` declares no `## Stage-doc boundary rule` on this project (R-37, now confirmed a fourteenth time). Where do units that fit no declared shape go? | The contract schema is applied **as written**, and this row is the record of the gap. Nothing is invented and nothing is blocked. |
| Q-17 | `sc`'s config-check failure sentence renders in Chinese as `配置检查失败：…`, which contains the `失败：` diagnostic literal and is reachable into `install.log` through `sc update-rules` → config regeneration. Is it repaired here? | **No — out of scope, and filed.** It is not a string this task touches, and repairing it changes a failure sentence whose wording this task has no criteria for. It is a pre-existing violation of the invariant BC-1 protects, and the PM files it as a follow-up row so the next task that owns that sentence inherits it rather than re-discovering it. |
| Q-18 | May the design change which stream a message uses, or add a message? | **No.** No message is added, removed or moved between streams. Every requirement here is about how an existing line renders and when it reaches the stream. |

## Verdict

READY
