> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

# T-25 — output-layer-contract · Rationale

## 1. Evidence — every claim in the dispatch re-verified first-hand at HEAD

Backward-looking citations; they cite path and line as proof of what was found, and the contract
never anchors a requirement to them.

| id | finding | evidence |
|---|---|---|
| E-1 | `TRANSLATIONS` holds exactly one table, `zh`; `t()` is `TRANSLATIONS.get(LANG, {}).get(s, s)`. In English **every** lookup is a designed miss and the key is the answer. So "a miss that fails loudly" is not expressible: the miss is the English rendering path. | `bin/sc:131`, `bin/sc:469-471` |
| E-2 | The five identifier keys are `ls.idx` / `ls.active` / `ls.type` / `ls.name` / `ls.address`, and they are the **only** keys in the file matching `identifier.identifier`. The sixth column header is already an English sentence key, `Delay`, with a comment naming the five as a defect not to copy. | `bin/sc:242-250`, header emitted at `bin/sc:2302-2303` |
| E-3 | The English defect is **published**: `README.md:94` ships `ls.idx  ls.active  ls.type     ls.name       ls.address        Delay` as the English sample output, and its heading row is visibly misaligned with its own data rows because a 6-character key overflows a 4-wide field. The Chinese sample at `README.zh-CN.md:94` is correct. | `README.md:93-99`, `README.zh-CN.md:94` |
| E-4 | `docs/dev-map.md` records the defect as a standing pattern note ("Namespaced keys (`ls.idx`) print literally in English — a pre-existing defect, not a pattern to copy"), so the fix makes that document's own text stale. | `docs/dev-map.md:90-92` |
| E-5 | R-38 exactly as filed: `sc status` builds its rule-set line with `"%-20s %s, %s"` — the `, ` is outside `t()` — while `sc doctor` renders `{reason}, {size} bytes, {age}` whose Chinese entry carries `，`. | `bin/sc:2423`, `bin/sc:290` |
| E-6 | R-33 is **wider than filed**: `cmd_status` runs *two* children before the second heading (`systemctl status` or `rc-service status`, then `ip -br addr show`), so both `=== Service status ===` and `=== TUN interface ===` are affected — and a **second command has the same shape**: `cmd_update_interval` prints `=== Next run ===` and then runs `systemctl list-timers` on the systemd arm. The filed row names only `cmd_status`. | `bin/sc:2413-2419`, `bin/sc:3430-3435` |
| E-7 | The fix shape is in-tree and its reason is written down: `_doctor_print` passes `flush=True` per row "without it the whole report would sit in the block buffer when stdout is a pipe, which is precisely the bug-report case". | `bin/sc:2968-2978`, `bin/sc:2993-2996` |
| E-8 | R-34's mechanism confirmed, and the class is larger than the mode field: `sc status` prints the Clash `mode` verbatim, the egress body verbatim (`_egress_ip` is documented as deliberately byte-faithful because "the value is printed verbatim by `sc status`"), the active node tag verbatim, and an exception as `e=e` — while `sc doctor` routes each of the same four through `_plain()`, including `_plain(str(e))` for the identical egress error. So `sc status` is the one screen with no foreign-text discipline. | `bin/sc:2427-2437`, `bin/sc:456-466`, `bin/sc:2865-2867`, `bin/sc:2461-2503` |
| E-9 | The T-23 hand-off is **much wider than `cmd_add`'s one `→`**. `sc`-authored non-ASCII reaches **stdout** from at least: `sc ls` (`●` on every active row, `→` on the auto-group row), `sc add` (`→` and `⚠️` inside the success keys), `sc mode` / `sc ipv6` / `sc telemetry` / `sc autostart` / `sc proxy` / `sc update-interval` / `sc lang` (`→` in the setting lines), `sc update-rules` (`→ Restarting sing-box ...`), and `sc help` (`●` in both help texts). Under a proved non-UTF-8 stdout each is a `UnicodeEncodeError`. `sc ls` is therefore broken outright on such a host, in English, which no filed row states. | `bin/sc:2308-2313`, `:156-157`, `:169-173`, `:178`, `:200`, `:238`, `:3529`, `:3600` |
| E-10 | Enumerating a character inventory would not close it: a node tag is user data. `sc add` derives a tag from a share URL, so `香港节点` reaches the same `print()`. T-23 closed the disk layer for exactly that population and re-homed the encode side here. | `docs/features/_archived/state-file-io-contract/07_DELIVERY.md:73-75`, `:155-159` |
| E-11 | The count-phrase population, read off the table: the four age-ladder phrases (`{n} seconds/minutes/hours/days ago`); the byte family (`OK ({size} bytes)`, `{done} bytes`, `{done}/{total} bytes ({pct}%)`, `larger than {n} bytes`, `truncated: got {got} of {declared} bytes`, `{reason}, {size} bytes, {age}` and its `— run \`sc update-rules\`` sibling); and the already-invariant `(s)` phrases (`{n} ruleset(s) failed to update`, `{n} path(s) grant access…`, `{n} path(s) could not be judged…`, `... {n} more line(s) not shown`). | `bin/sc:212`, `:223-230`, `:290-293`, `:147`, `:337-339`, `:308`, `:358`, `:1052-1055` |
| E-12 | The fraction phrases are correct as they stand: `{n}/{total} usable`, `{n}/{total} rule-sets unusable…`, `{n}/{total} nodes carry a stored delay…`. A plural noun after a fraction is right for every numerator, so they are not in the population. | `bin/sc:289`, `:215-218`, `:325-328` |
| E-13 | `at {at}: {name} matched {count} elements…` cannot render `1 elements`: the sentence exists because the anchor matched a number of elements other than one. It is also the R-72 line, deliberately untouched. | `bin/sc:370-371`, `bin/sc:1400-1404` |
| E-14 | **The bilingual-parity class appears to be empty today.** Every call-site key sampled across the file resolves to a `zh` entry, including the ones a scan would most expect to have drifted (`Done`, `Listed names…`, `not probed — …`, `no usable answer from {addr}`, `Showing the configuration on disk: {path}`, all four override-directive sentences, all nine `doctor` section labels). The sample was extensive but **not** a complete enumeration — which is exactly why FR-3/AC-4 requires one to be performed and its counts recorded rather than this document asserting the property. | `bin/sc:131-385` read whole; call sites enumerated by pattern across the file |
| E-15 | `verify_all` B.2 is `check-i18n-parity.sh`, and its blind spot is live and self-documented: it extracts `t()`, enumerates keys **from the `case` blocks**, and renders each in both languages. Its own R-7 self-check compares the two renders for byte-identity — a genuinely good guard against a broken language dispatch — but a `t <key>` call site naming a key in neither block is outside its input set. It is a Bash-`case` parser; reading Python call sites would need a second parser inside it. | `.harness/scripts/check-i18n-parity.sh:61-72`, `:98-107` |
| E-16 | Adding a `verify_all` step is not a one-file change: `verify_all.sh` hard-codes each `step` id (including `B.3 "Lint" SKIP`), a `.ps1` mirror exists and is already filed as diverging (R-6), and the PASS count is a task-start baseline PMs compare against. | `.harness/scripts/verify_all.sh:67-77`, `PM_LOG.md` task-start state |
| E-17 | **A pre-existing `失败：` collision, found while enumerating.** `"Config check failed:\n{stderr}"` renders in Chinese as `配置检查失败：…`, and it is written to stderr by the config regeneration path, which `sc update-rules` reaches when a rule-set is gained — and `install.sh` step 6 captures `sc update-rules`' streams into `/var/log/sing-box/install.log`. So `grep '失败：' install.log` can already match a line that does not mean "this rule-set file was not updated". `install.sh`'s own zh table independently carries `下载失败：` and `配置生成失败：`. Not this task's to repair (Q-17), but it must be recorded rather than re-discovered. | `bin/sc:135`, `bin/sc:2138`, `install.sh:150`, `:176` |
| E-18 | The Python floor is **3.6** and it is a written project rule ("no walrus, no `dataclasses`, no `capture_output=`, no `unlink(missing_ok=)`"), reinforced in code (`_doctor_run` is "3.6-safe deliberately"). Any stream-level design must respect it — notably, the 3.7-only stream reconfiguration convenience is not available. | `docs/dev-map.md:93-95`, `bin/sc:2509-2512` |
| E-19 | `sc config` writes its document with `ensure_ascii=False`, so it can emit non-ASCII to stdout; under a non-UTF-8 stdout it aborts today. Its stderr notes above it already survive, because stderr carries `backslashreplace`. This asymmetry is the reason BC-8 exists. | `bin/sc:3108-3125` |

## 2. Related historical work

Linked, not re-described.

- **T-23 `state-file-io-contract`** — closed the disk layer of the same encoding family and recorded
  its AC-11/AC-12 process-exit clause as BLOCKED-BY-T-25. `docs/tasks.md` R-64 … R-69.
- **T-19 `ruleset-staleness-visibility`** — Q-11's one deterministic age vocabulary, R-38 and R-40
  as filed, and the rejected `ruleset-timestamp-outside-the-single-reader` decision that keeps the
  timestamp inside one reader. `docs/tasks.md`, T-19 block.
- **T-18 `status-egress-via-clash-api`** — R-33 and R-34 as filed, plus the buffering insight this
  task acts on. `docs/tasks.md`, T-18 block.
- **T-05 `sc-doctor`** — the one-screen greppable report and `_plain()`'s reason for existing.
- **T-06 `sc-config-show`** — the always-redacted rendering, the `BrokenPipeError` scope (R-45), and
  the stderr-buffering insight.
- **T-02 `config-degrade-missing-rulesets`** — the origin of both the `失败：` invariant and the
  "no namespaced keys" rule; `.harness/rejected-decisions.md`
  § `mirror-fallback-cause-on-its-own-line-or-on-stderr`.
- **T-08 `install-binary-download-progress`** — `.harness/rejected-decisions.md`
  § `t-fmt-default-fallback`, the prior ruling on changing a `t()` miss into a key print, and
  § `ruleset-unit-tests-in-t02`, four consecutive deferrals of gate/test infrastructure.
- **T-24 `override-error-envelope`** — R-71 … R-74, and the practice of killing wrong builds rather
  than passing criteria.
- **T-28 `committed-test-suite`** — inherits the permanent key gate (Q-8) and already owns R-71.

## 3. Candidates considered per resolved question

**Q-1 / Q-2 — the mechanism behind R-19.** Three candidates. (a) *Add an `en` table*: every key
duplicated as its own value, ~250 rows of pure bulk, and it destroys the property that makes the
convention checkable by reading — that the source text *is* the English. (b) *Make a miss loud*:
not expressible, per E-1 — in English a miss is the rendering path, and making it loud only for
Chinese would print a diagnostic to the user least able to act on it, which is the trade
`t-fmt-default-fallback` already declined in the other direction. (c) *Chosen*: the key is its own
English rendering, the five violations are deleted along with the exemplar comment that named them,
and the convention becomes a positive statement in `docs/dev-map.md`. The dispatch framed the cause
as "`t()` returning the key on a miss"; re-verification says the fallback is load-bearing and
correct, and the cause is a **key that is not English**. FR-1 states that cause, not the symptom.

**Q-3 — the six English headings.** `#` / `On` / `Type` / `Name` / `Address` / `Delay`. `Active`
(6 chars) and `Act` (3) were rejected because the marker field is 2 characters and widening it
shifts every column after it, which the auto-group work deliberately avoided. Leaving the marker
column unheaded was rejected because Chinese would lose 激活. `Idx` and `No.` were considered for the
index column; `#` is one character and cannot overflow a 4-wide field.

**Q-4 — the separator.** Two candidates: punctuation inside the translated string (doctor's) or
punctuation in the format string (status'). The first wins on three grounds — it is already the
convention at every site but one; it lets Chinese read as Chinese; and it makes the fix one key plus
one Chinese entry, exactly the cost R-38's own row estimated. Choosing the second would change no
Chinese rendering, i.e. it would close the row by deciding the defect is the *other* screen's
correct behaviour.

**Q-5 / Q-6 — plural handling.** Candidates: (a) an inflection mechanism (a `_plural()` helper, or
`t()` growing count awareness, or two keys per phrase). Rejected on two counts: Chinese has no
plural inflection, so the whole apparatus serves one language's two forms; and two forms per phrase
means a captured report needs two grep patterns where it needed one, which NFR-3 calls a regression.
(b) *Chosen*: one invariant form per phrase, in the `(s)` idiom the file already ships. It is data,
not machinery; it renders identically for 0, 1 and 2; and it keeps the deterministic vocabulary
T-19's Q-11 chose. The accepted cost is that `1 byte(s)` reads clumsily — weighed against
`1 bytes`, which is simply wrong, and against a mechanism the counter-rule in rule 85 forbids.
(c) *Rewording each phrase so no noun follows the count* (e.g. a unit abbreviation) was rejected as
a wider product-wording change than any filed row asked for.

**Q-8 / Q-9 — the gate.** This is the largest single judgment in the task and the one with the most
over-build risk. Candidates: (a) *widen B.2* — rejected, it would put a Python call-site parser
inside a Bash-`case` parser (E-15), and the dispatch requires any widening to be a recorded
decision rather than a side effect. (b) *A new committed check wired into `verify_all`* — rejected
**for this task**: the class it would catch is, as far as an extensive sample can tell, **empty
today** (E-14) after thirteen tasks of hand-carried discipline; the wiring touches three artifacts
this task has no criteria for (E-16); and gate/test infrastructure has a designated owner and four
prior deferrals to it. Under rule 85's counter-rule, machinery for a class with no live instance is
speculative generality. (c) *Chosen*: establish the property **once, by measurement, inside this
task** (FR-3/AC-4) — which costs one enumeration and fixes anything it finds — and hand T-28 the
permanent gate with the two properties it must have. If AC-4's enumeration finds offenders, the
class is not empty and the evidence for T-28's gate gets stronger, not weaker; either outcome is
informative, which is the mark of a criterion worth running.

**Q-11 / Q-12 — the encoding population.** The alternative was to enumerate the `sc`-authored
characters and replace them (`→`→`->`, `●`→`*`). It is a smaller diff and it was rejected on
correctness, not taste: it does not cover user data (E-10), so `sc ls` would still abort on a
non-ASCII tag, and it pays for that incompleteness with a visible product change (`●` is documented
in both READMEs and both help texts). A stream-level statement covers both populations and removes a
special case rather than adding one — stderr has carried exactly this policy since T-13, so the
chosen requirement makes stdout stop being the exception.

**Q-13 / FR-8 — R-34.** The minimum discharge is to narrow the promise, which costs zero code
because no shipped document publishes it. FR-8 goes one step further and requires `sc status`'s
foreign values to carry `sc doctor`'s neutralisation. The extra is two or three call sites and no
new function; the ground is that `sc status` output is the paste-into-a-bug-report surface, that
`_plain()` exists because `sing-box` was measured emitting CSI colour into a pipe, and that the same
exception is already `_plain()`-ed on one screen and not the other (E-8). This is the one item in
the contract where a stage-2 or stage-3 reviewer could reasonably argue scope; the smaller
alternative is named here so that argument can be had on the merits.

## 4. Over-build watch — what this requirement set must not become

The dispatch names this task's defining risk correctly. Held against it:

- No requirement can be satisfied only by a framework. FR-1 is a data change; FR-4 is one key;
  FR-5 is a set of key edits; FR-2 is six words; FR-6/FR-7 are statements about one stream; FR-8
  reuses one existing function; FR-3 and FR-9 are one enumeration and two document corrections.
- The two largest cost centres were both **declined**: the permanent gate (Q-8) and the character
  inventory (Q-12) — the first because its class is empty, the second because it is incomplete.
- FR-6 and FR-7 are two symptoms with, plausibly, one cause at the stream boundary. The contract
  deliberately states them as two behaviours and names no mechanism, so a design that satisfies both
  with one construct is permitted and a design that satisfies each separately is also permitted.
  Choosing between them is stage 2's job under rule 85, with the burden of proof on the larger.
- Size expectation, for calibration only and binding on nobody: this is the shape of T-22 (+21/−11
  for one construct with five projections) and T-23 (+76/−51), not of a new subsystem.

## 5. Proposed `CONTEXT.md` glossary entries

Not written into `CONTEXT.md` at this stage — following T-19's precedent, they are proposed here and
adopted at delivery if the design keeps their shape.

**display key**: The argument passed to `sc`'s translation function. It is simultaneously the lookup
key and the English rendering, so it must be readable English text; a key that is an identifier
renders as itself to every English user. _Avoid_: message id, string id, namespaced key.

**count phrase**: A user-facing string in which a number is substituted next to the noun it counts.
Its contract is one rendered form for every value of that number, so a captured report needs one
pattern to match it and no rendering asserts a grammatical number the value does not have.
_Avoid_: pluralised string, singular/plural pair.

**foreign text**: Text `sc` prints that `sc` did not author — another tool's output, an API field, an
exception's message, a user's node tag. It is neutralised before printing (no carriage return, no
escape sequence) because `sc`'s screens are pasted into bug reports; it is never trusted to be
single-line, bounded, or encodable. _Avoid_: external output, raw output, untrusted string.

## 6. Fixture traps carried forward (also in the ACs' verification notes)

1. `main()` reassigns `LANG` from `settings.json` **after** import, so a harness that sets only
   `sc.LANG` renders English on every `main()`-driven path and any Chinese assertion passes
   vacuously. This task is about rendering, so the trap is directly load-bearing.
2. `LC_ALL=C PYTHONCOERCECLOCALE=0` does **not** give a non-UTF-8 Python; `PYTHONUTF8=0` is
   required, and the proof belongs in the report.
3. `sys.stderr` carries `backslashreplace` while `sys.stdout` is strict, so no criterion written
   against stderr can detect a stdout encoding defect.
4. R-33's assertion must be made over a real pipe or file and with the child process actually
   running; on a TTY, or with the child stubbed away, the defect does not exist to be seen.
5. Baseline and candidate must run at the **same** fixture path, from a **clone** — never a
   `git worktree`.
6. `verify_all.sh` must be invoked from the repository root or it self-reports a false red.
7. Where a criterion needs root that no agent here holds, the outcome is BLOCKED plus a filed row —
   never a quietly substituted weaker check. The precedent has held eight times.
8. Nothing in this task requires touching `/etc/sing-box`, `/var/lib/sing-box` or the live service,
   and an un-neutralised `bin/sc` import re-execs the **installed** `sc`.
