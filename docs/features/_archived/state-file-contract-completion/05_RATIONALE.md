> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Round-2 scope

Everything round 1 approved is unchanged and was not re-derived: the codec sweep, the renderer, FR-6's
refusal, E-10's `.path` guard and the contract suite were re-read only far enough to establish that no
line moved. What was reviewed from scratch is the two prose hunks, their blast radius, and the
`cmd_config()` docstring the developer declined and disclosed.

## The two paragraphs, clause by clause

Read against `bin/sc:3731` (the `backslashreplace` wrapper, encoding preserved), `bin/sc:3163-3166`
(the single stdout write and its flush) and `04_DEVELOPMENT.md`'s measured three-tag table.

| AC-11 clause | `README.md:297` | `README.zh-CN.md:297` |
|---|---|---|
| (a) escape written, run does **not** end | "written as a backslash escape rather than ending the run: the whole masked document still reaches stdout and the command still exits `0`" | 「会以反斜杠转义写出、而不是让命令中断：整份隐去后的文档照样完整地写到标准输出，命令照样以 `0` 退出」 |
| (b) three spellings, chosen by the character | "`\xNN` for one in the Latin-1 range, `\uNNNN` for one elsewhere in the BMP (the CJK case), `\UNNNNNNNN` for one above the BMP" | 「Latin-1 范围内的字符写成 `\xNN`，BMP 之内其余的字符（中文正是这一类）写成 `\uNNNN`，BMP 以上的写成 `\UNNNNNNNN`」 |
| (c) only `\uNNNN` is a JSON escape | "of those three **only `\uNNNN` is a JSON escape**. A saved file whose escapes are all of that form is therefore still valid JSON; one carrying a `\xNN` or a `\UNNNNNNNN` is not" | 「这三种里**只有 `\uNNNN` 是 JSON 的转义写法**。所以转义全是这一种的文件，存下来仍然是合法 JSON；只要其中出现了 `\xNN` 或 `\UNNNNNNNN`，存下来的文件就不是」 |
| (d) UTF-8 stdout is the unescaped route | "In every case, running the command under a UTF-8 stdout is what gets you the document unescaped" | 「任何情况下，想拿到未经转义的文档，都是在 UTF-8 的标准输出下运行这条命令」 |

The Chinese was read as a document in its own right, not as a translation to be spot-checked. Three
things had to be true of it independently and are: the CJK case is named as the `\uNNNN` case in the
same breath as the spelling (「中文正是这一类」), the JSON-escape claim is exclusive (「只有 …」) rather
than merely illustrative, and the two-directional saved-file consequence is spelled out in both
directions (「仍然是合法 JSON；… 就不是」). A correction that landed only in English would have failed
AC-11 outright; this one did not.

Two further clauses of each paragraph were checked rather than waved through, because the whole line is
inside the hunk:

- "a non-UTF-8 locale, or `PYTHONIOENCODING` set to a narrower codec" / 「非 UTF-8 的 locale，或把
  `PYTHONIOENCODING` 设成了更窄的编码」. V-11 measured only the `LC_ALL=C` route, so the
  `PYTHONIOENCODING` half is not from this task's fixture — but it is this project's own recorded
  measurement from the output-layer-contract task (`.harness/insight-index.md`, 2026-08-15:
  `PYTHONIOENCODING=ascii` on a UTF-8 host makes `sc config` exit 0 with a document `json.loads`
  rejects). True and evidenced, not reasoned.
- the closing sentence about the stderr notes (absolute path, credentials masked, drift when a record
  exists) is true of `bin/sc:3149-3157`, where those are exactly the two-or-three notes written.

## The two negatives, and the hedge that survives

Negative 1 — no claim that escaping invalidates the saved file *irrespective of the character*. Both
paragraphs condition every invalidity claim on the spelling, which is the whole repair. What survives
from HEAD is the opening hedge, "whenever stdout's encoding can represent that document" /
「只要标准输出的编码表示得了这份文档」. Read strictly it is a **sufficient** condition — "in all cases
where X, then Y" — and asserts nothing about ¬X; the sentences that follow then state what actually
happens under ¬X, in full. So it does not violate the negative. It is recorded as CR-8 (NIT) because a
reader who stops at the first clause could infer the converse, and because it is worth having on record
that the clause was examined and kept rather than missed. Both languages hedge identically, so the
"same facts as each other" requirement is not disturbed by it.

Negative 2 — no claim about the saved file V-11's fixture does not verify. Every saved-file assertion in
each paragraph maps onto a measured row: `香港-01` → `香港`, parses; `café-02` → `\xe9`, does
not; `🚀-03` → `\U0001f680`, does not. The "whole masked document still reaches stdout" clause maps onto
the same table's completeness and exit columns (267 / 262 / 265 B, `uuid` masked, exit 0 in all three).
Nothing is claimed about file mode, atomicity or ordering of the saved file, which nothing measured.

## The ruling on `cmd_config()`'s docstring

`bin/sc:3119-3122` says the JSON half of the promise "holds for a stdout whose encoding can represent
the document", that an unencodable character is escaped "instead of ending the run", that
"`\xNN` / `\UNNNNNNNN` are not JSON escapes", and that "Both READMEs state the same condition."

Acceptable to ship. Four grounds:

1. *Nothing in it is false.* The two named spellings genuinely are not JSON escapes. The opening is a
   sufficient condition, not an exclusive one, exactly as the READMEs' surviving hedge is.
2. *Neither AC-11 negative is engaged.* The docstring draws **no** conclusion about the saved file — it
   never says the redirected file is invalid — so the falsehood stage 6 found in the README paragraph
   has no counterpart here. What is wrong with it is an omission and an understatement, not a claim.
3. *It delegates.* "Both READMEs state the same condition" points the source-only reader at the two
   paragraphs that now carry the complete three-way rule. The pointer is what keeps the omission from
   being load-bearing; the sentence is an understatement in the direction of *less*, not of *wrong*.
4. *The edit is not free and is not authorised.* No ledger row covers a `bin/sc` line here; E-18 states
   in terms that it adds no product code line; and the `+24/−9` figure is cited by NFR-1, K-11, AC-17
   and V-17, so touching it would re-price the task's own evidence for a docstring that ships nothing
   false. `.harness/rules/85-design-discipline.md`'s bar — a change may not ship a sentence it has
   itself made false — is met: this sentence was not made false, only less complete than its neighbour.

Where it does belong is T-32, whose limit ("correct the sentences and add nothing") fits a one-line
docstring alignment exactly. RES-5 carries it, so declining it here does not mean losing it. The
developer disclosing it rather than fixing it quietly is the behaviour this stage wants; had it shipped
a false clause the disposition would have been the opposite regardless of the line budget.

## Blast radius: what this stage could and could not check

No git. R-78 keeps this review read-only, an un-neutralised `bin/sc` import re-execs the installed `sc`
under sudo, and nothing was executed, driven or written; `/etc/sing-box`, `/var/lib/sing-box` and the
live service were not touched or queried. So "exactly one hunk per file" is not directly observable
here. What is observable, and was:

- `README.md:124`, `README.md:152`, `README.zh-CN.md:124`, `README.zh-CN.md:152` still carry HEAD's
  "every command except `sc doctor`" / 「除 `sc doctor` 以外」 wording — the inaccuracy round 1 raised as
  CR-2. An editor who had reflowed or re-read the file would very likely have touched it; it is
  untouched, which is what K-12's freeze asked for.
- **Every line number cited in round 1 is unmoved**, in both READMEs (`:124`, `:152`, `:297`) and in
  `bin/sc` (`:2074`, `:3130`, `:3405-3411`, `:3731`, `:3769`), and the text at each is what round 1
  approved. A one-line-for-one-line replacement at `:297` shifts nothing; any insertion or deletion
  above those lines would have shifted them. This is corroboration of `@@ -297 +297 @@` and of
  `--numstat 24 9`, not proof of them.
- `docs/dev-map.md:81` — the stream-configuration row, the other live document in this neighbourhood —
  describes `backslashreplace` and what it costs but makes **no** JSON-validity claim, so the falsehood
  stage 6 found has no second home in the project's live prose. `docs/dev-map.md:43`'s `cmd_config()`
  clause names the codec and stops there. Nothing else in `docs/` asserts the falsified claim.

RES-4 is restated on that basis rather than retired: the requirement it guarded (byte-identity of the
paragraph) is gone, but a real unverified half remains, and leaving the residual in its old form would
tell delivery to check something AC-11 no longer asks for.

## Carried forward from round 1

### The ruling on the unpinned guard (CR-1), now discharged

Collapsing E-10's arm to an undifferentiated `except OverrideError:` leaves the suite at 17/17/17,
exit 0. The ruling was **a written boundary, not a fourth assertion**, on three grounds: the property is
a regression guard for a HEAD behaviour (AC-19 says so itself), so FR-9 / Q-11 / I-8 / E-12 fix the
suite's growth at three; the honest pin needs the suite's first command-level fixture with a stubbed
download loop, which is stage-2 work and a pool row; and an `ast` shape assertion would pin the
`if e.path != SETTINGS_PATH: raise` *spelling*, reddening B.4 for the `if`/`else` form stage 2 priced as
correct. The clause landed at `docs/dev-map.md:76` — inside E-13's existing scope, no new row, no
`bin/sc` line, floor unmoved — and states the coverage gap, the green-B.4 consequence, AC-19 / V-19 as
the only control, and why the `ast` check is not the substitute. RES-1 and RES-2 remain the enforcement.

### The four raise sites

| site | `.path` | E-10's arm |
|---|---|---|
| `bin/sc:2063-2067` `_load_override()` wrapper | `OVERRIDE_PATH` | re-raise |
| `bin/sc:2068-2070` wrapper's non-`OverrideError` arm | `OVERRIDE_PATH` | re-raise |
| `bin/sc:2074` `load_settings()` | `SETTINGS_PATH` | swallowed → `regen_ok = False` |
| `bin/sc:2075` `load_nodes()` | `NODES_PATH` | re-raise |
| `bin/sc:2111-2113` `_merge()` of the user override | `OVERRIDE_PATH` | re-raise |
| `bin/sc:2122-2123` three-key array guard | `OVERRIDE_PATH` **or `None`** | re-raise |
| `bin/sc:2142-2145` composition fault clause | `OVERRIDE_PATH` **or `None`** | re-raise |
| `bin/sc:2100-2101` `_compose()` of sc's own overlays | class default `None` | re-raise |

`e.path != SETTINGS_PATH` is a `!=` against a `Path`, so `None` is unequal and takes the bare `raise` —
the fail-safe direction. Both sides read the module global at call time, so a repointing fixture moves
raise site and guard together.

### FR-5, the codec population, BC-7/BC-8, C-9

`save_settings()` (`:616-623`) now raises **only** `SystemExit`; `_resolve_clash_port()`'s persist
(`:449-453`) catches exactly that with a one-statement `try`, so the persist stays silent, non-fatal and
outcome-preserving. Every other `save_settings()` call site was read with its block; none sits inside a
`try`. The codec population recomputed independently: 8 text sites naming `encoding="utf-8"` (`:521`,
`:619`, `:1673`, `:2021`, `:2714`, `:3130`, `:3467`, `:3514`), 5 binary sites admitted by a literal mode
(`:938`, `:1202`, `:1549`, `:1972`, `:2649`) — both matching the assertion's evidence string. No site
hands `bytes` to the parser, and clause order (`OSError` first, `UnicodeDecodeError` / `ValueError`
after) holds at `:1674/:1676`, `:2022`, `:2715`, `:3131/:3133`. C-9's disposition stands: the credited
kill for I-5 is a codec **substitution**; the deletion is recorded as a fact, not as the kill.

### Verification limits

Every [B] row is "code present, observation owed to stage 6", not passed. The suite run, `verify_all`,
the mutation set, the locale rows and V-11's three-tag re-measurement are stage 6's evidence. The
developer's stage-4 measurement is what the paragraphs were written from and is coherent with the
shipped code at every clause, but it is not this stage's observation and is not credited as one.

## Rationale-read trigger record

`01_RATIONALE.md` and `02_RATIONALE.md` were not reached this round: every identifier this review acts
on (AC-11, E-18, K-12, Q-5, Q-14, NFR-3, V-11) is defined in a contract portion, so no T5.4 trigger
fired. T5.1 did not fire — no design-fidelity finding turned on why the design chose a shape, because
there is no design-fidelity finding. T5.2 did not fire: `04_DEVELOPMENT.md`'s `## Design drift` reads
"None", and the docstring item is an "Open issues for review" disclosure, not a recorded drift.
`04_RATIONALE.md` was reached for the measurement transcript behind the three-tag table. Round 1's own
T5.3 read of `02_RATIONALE.md` (before raising CR-1) stands and needed no repeat.
