# 04 — Development rationale · T-32 `record-accuracy-sweep`

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## 1. The delivered `verify_all` run, in full (G-11 / AC-19)

Both runs were taken on this tree by this stage. The first is stage 4's own task-start baseline,
which reproduced the PM's measured one exactly; the second is over the delivered tree.

```
=== verify_all (generic) ===
Project: singbox-cli
[A.1] No hardcoded secrets ... PASS
[A.2] No .env files committed ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS
[B.2] install.sh bilingual key parity ... PASS
[B.3] Lint ... SKIP
[B.4] bin/sc contract assertions ... PASS
[B.5] restricted-network self-check ... PASS
[B.6] Assertion floor never below its last committed value ... PASS
[E.1] Bootstrap files present ... PASS
[E.2] workflow.md present ... PASS
[E.3] Agents layout v0.30+ (.harness/agents/ = partition dev-* only) ... PASS
[E.4] Binding in sync (.harness/ -> .claude/) ... PASS
[E.4b] Hook commands resolve to existing scripts ... PASS
[E.5] AI-GUIDE.md indexes every .harness/rules/*.md ... PASS
[E.6] Adversarial tests section in completed task reports ... PASS
[F.1] AI-GUIDE.md <=200 lines ... PASS
[F.2] Rule fragments <=200 lines each ... PASS
[F.3] Agent definitions <=300 lines each ... PASS
[F.4] insight-index.md <=30 lines ... PASS
[F.5] docs/tasks.md <=300 lines ... PASS
[F.6] Active task docs <=500 lines each ... PASS
=== Summary ===  PASS: 20  WARN: 0  FAIL: 0  SKIP: 1     exit 0
```

Step-by-step comparison against the task-start baseline: **every step has the same id, the same
name and the same status**; no step was added, removed or renamed (AC-18's second half). The two
steps whose status this task could plausibly have moved are B.4 (the suite loads the edited
`bin/sc`) and F.5 (`docs/tasks.md`'s cap); both were re-read from the delivered run rather than
inherited, and F.5's measurement moved 299 → 293 lines against a cap of 300.

## 2. Why the AC-2 / K-2 proof is an AST comparison rather than a diff review

A hunk-by-hunk `git diff` review is what AC-2 asks for and it was done — three hunks, all comment or
sentence text. But "no statement was added, removed or reordered" is a claim about the **statement
list**, and a diff review is a human reading of a rendering of it. So the claim was established
mechanically as well, by parsing both revisions and normalising away exactly the thing this task is
allowed to change:

```
HEAD statements  : 15550        (ast.walk node count)
tree statements  : 15550
AST identical after normalising every str constant: True
top-level def/class list identical: True (113 names)
str constants changed: -3 / +3
  - {decision}; config.json does not carry this decision as the first dns.rules entry — run `s…
  - {decision}; config.json does not carry this decision as the first dns.rules entry — run `s…
  - {decision}；config.json 的 dns.rules 第一条不是该决策对应的规则 —— 运行 `sc reload` 重新生成；若 …
  + {decision}; config.json does not carry that decision at the head of its dns.rules — run `s…
  + {decision}; config.json does not carry that decision at the head of its dns.rules — run `s…
  + {decision}；config.json 的 dns.rules 开头没有该决策对应的规则 —— 若该文档已过期或被手工改过，运行 …
```

Two things this shows that the diff does not. First, the English sentence appears **twice** in the
changed set — the key and the call-site literal — which is the identity K-3 wanted, arriving as a
by-product. Second, comments are not AST nodes at all, so the R-63 clause is provably invisible to
the statement list; "zero executable lines" is not an eyeball verdict here.

The script parses; it never imports or executes `bin/sc` (NFR-4).

## 3. R-79 — the retrieval, and what the retrieved text actually says

`git log -S 'backslashreplace' -- bin/sc` returns exactly one commit, `6d16caf`
(`fix(sc): give the user-facing output layer one contract (T-25)`), so the pre-`backslashreplace`
build is its parent. It was retrieved to a scratch path **outside the repository**, saved with a
`.txt` extension so nothing can treat it as a module, and read. It was never executed, and neither
was any other `sc` build: `bin/sc:124-126` re-execs a hard-coded `/usr/local/bin/sc` under `sudo` at
**import** time, so a "scratch tree" gives no containment at all (RS-3, and R-78's incident).

**Site 2 (`sc update-rules`), the decisive lines of the retrieved text.** Inside
`cmd_update_rules`'s `for fname, relpath in RULESET_FILES:` loop, before the base loop:

```
prefix = f"  ↓ {fname} ... "
print(prefix, end="", flush=True)
```

and only afterwards, inside the same iteration, `causes.append(base + " -> " + str(e))` and finally
`print(t("failed: {e}", e="; ".join(causes)))`. So the very first thing this command puts on stdout
for the very first rule-set file is an `sc`-authored `↓` (U+2193). Under `LC_ALL=C PYTHONUTF8=0` the
stream's codec is ASCII with `surrogateescape`, which encodes a `\udcXX` back to its byte and
**raises** on a real non-ASCII character — so the run ends at that `print`, uncaught, before a
mirror base string can reach a printed line. The `--mirror` / `SB_RULES_BASE` bytes the clause
mourns were never rendered by any shipped build.

**Site 1 (`sc doctor`'s permission rows).** `_doctor_permissions()` builds `details` from
`CFG_DIR.iterdir()` but returns them only after a summary row:

* `wide` branch → `"{n} path(s) grant access to group or other — run the command shown for each"`
* `links` branch → `"{n} path(s) could not be judged — see below"`
* neither → a single row that names **no** path at all.

Both summary sentences carry an em dash (U+2014). `cmd_doctor` prints row by row, so the summary is
encoded before any `details` line exists on the stream. And the detail strings themselves —
`"{path} is mode {mode} — run: {cmd}"`, `"{path} is a symbolic link; sc never creates one here —
check it with: ls -l {path}"` — each carry an em dash in the same string as `{path}`, so even
reached in isolation the encode raises and the whole line is discarded (TextIOWrapper encodes before
it writes). Two independent reasons, same conclusion.

**What is inherited rather than re-measured (NFR-5).** That `LC_ALL=C PYTHONUTF8=0` gives this
process an ASCII stdout with `surrogateescape` is T-25's measurement, already asserted by the
dev-map clause being repaired; this stage did not re-run it, and the corrected sentence is a claim
about **source order** given that premise. Re-measuring it would have meant running an `sc`.

## 4. R-85 — how the transition set was derived, and what a smaller derivation would have missed

The derivation was written **before** the changelog lead (M-4's precondition) and is in the contract
portion. Three notes on how it was taken, because the shape of the mistake matters more than the
answer:

1. **The population came from `CHANGELOG.md:29` itself, not from `02`'s V-8.** V-8 scoped it to "the
   two changed probes"; the entry names three (IPv6（AAAA）, 节点延迟, DNS 解析). The third moved no
   class — `git show d849234 -- bin/sc` shows `DOCTOR_OK` / `DOCTOR_PROBLEM` on the DNS-lookup rows
   as **context** lines, with only the message strings inside them changed — so it contributes
   nothing; but "contributes nothing" is a finding, not an omission, and G-3 is right to demand it.
2. **The `1 → 0` candidate was chased and killed.** If the node-delay row's PROBLEM → OK could ever
   leave a host at worst = OK, the set would have a fourth member. It cannot: the change only bites
   where `is_running()` is False while the API answers, and `_doctor_service` gives such a host
   either two UNKNOWN rows (no init system at all) or a PROBLEM service row (an init system that
   says not-running). Either way the new worst is ≥ UNKNOWN. This is the one case where the answer
   depended on a probe the row is not about.
3. **Both live claims fail for the same reason.** The shipped 「只有一个方向」 and the filed
   「没有哪台机器的退出码会变小」 are the same error in two spellings: they read `DOCTOR_EXIT`'s values
   as a scale. `{OK: 0, UNKNOWN: 2, PROBLEM: 1}` is a labelling, and `max` runs over the **classes**,
   not over the exit codes — so the ordering the code enforces (OK < UNKNOWN < PROBLEM) and the
   ordering of the printed integers are different orderings. The delivered lead says that first and
   then enumerates, which is why it cannot be re-broken by adding a transition later.

The AC-10 witness was chosen so its displacement is **override-caused**: a hand-edited `config.json`
would make `_drift_state()` return `True`, the drift row PROBLEM, and the host would no longer be an
instance of "no PROBLEM row" — the trap G-4 names. Using the *absence* of `.config.sha256` for the
required UNKNOWN row keeps the witness an ordinary upgraded machine rather than a contrived one, and
`_drift_state()`'s own docstring says that state is what "every host upgrading from a build before
the record existed" has.

## 5. The two ledger-ceiling overruns, argued rather than taken silently (G-10, rule 85)

**E-1, ≤3 → 4 lines.** I-1 asks the comment for two clauses: what the binding *is* (a base64
candidate with one consumer) and what a second consumer *falsifies*. At the file's ~92-column
convention the three-line form either drops the second clause — which is the whole trap R-63 exists
to set — or splits "the / except arm" across a line break at 96 columns. The fourth line is prose
economy, not scope: no clause was added beyond I-1's two.

**E-8, ≤4 → 8 lines.** The old paragraph spent four short coordinates (`:186-194`, `:195-227`,
`:136-141`, `:548-556`); I-8 replaces them with six named mechanisms, and a name is longer than a
range. F-8 had already recorded that this ceiling was asserted against a reflowing paragraph rather
than measured. The alternative was to drop the sentence explaining *why* the anchors are tokens —
which is the one sentence that stops the next editor putting the ranges back — so the paragraph kept
it and the overrun is reported. NFR-2's binding total is 26 of 30.

Neither overrun is a design change: no clause, mechanism or file was added that the design did not
specify.

## 6. R-91 — the sub-line correction PQ-4 flagged, honoured by removal

The old citation `:548-556` covered the **HALT branch alone**, while the sentence attached to it
named three things (splice, HALT, `.bak`). In the delivered `upgrade-project.sh` the splice sits at
`:534-542`, the HALT branch at `:548-554` and the `.bak` write at `:571-573` — three separate places
(PQ-4 gives the HALT branch as `:548-556`; read against the delivered file its `if … fi` closes at
`:554`, and either bound makes the same point: one range covered one of the three). Rather
than correct one range into three, the paragraph now names five tokens and no range at all, which is
what makes it survive the refresh event it describes. Each token was grepped against the delivered
script **before** the ranges were removed (M-5's precondition):
`refresh_set` 5 hits, `known` 7, `VERIFY-SPLICE` 1, `VERIFY-HALT` 2, `"$proj_file.bak-$stamp"` 1.
PQ-4's warning was taken literally: the token written is the script's own literal
(`bak="$proj_file.bak-$stamp"`), not the prose form `.bak-<stamp>`, which greps to nothing. The full
literal also matters because the script has two sibling `.bak-$stamp` writes (`$settings` at `:351`,
`$hook_path` at `:424`); only the `$proj_file` spelling is the one this paragraph is about.

## 7. What was deliberately not touched

`docs/dev-map.md:76`'s `18 defined / 18 run / 18 passed when last measured, T-30` is a **true
past-tense measurement attributed to the task that took it**, in a sentence that already says the
count is whatever `baseline.json` currently carries. R-94's repair would have made it false. It sits
two rows above one of the four hunks and was re-read at the end of the edit to confirm it survived.

`bin/sc`'s `# Paths` comment ending "as the eighth" is frozen by the row's own instruction; the
dev-map row now carries the reason (`LIB_DIR` arrived with T-28), so a reader meets one explanation
instead of two counts (RS-4).

R-98, R-106, R-86, R-89/R-90/R-92, R-107, R-109 and R-110 were left exactly as filed. R-109 in
particular lives inside the frozen loader block, and the four dev-map hunks are at lines 33, 42, 81
and 87 — nowhere near it.

## 8. Process notes

* **R-86, sixteenth instance.** `guard-rm.sh` refused a `python3 - <<'PYEOF'` heredoc containing no
  `rm` at all, with *could not parse nested pwsh command safely*. `HARNESS_ALLOW_OUTSIDE_RM` was
  **not** set. The cost was one indirection: every multi-line script was written to the session
  scratch directory and run from there. Four such scripts were used (rotation, board row, the
  rejected-decisions append, and the two read-only checks) and none of them lives in the repository.
* **`.harness/scripts/doc-query.js` is absent on this host**, so the mandated insight-index query
  could not be run; `.harness/insight-index.md` was read directly instead. Handled fail-open and
  recorded, the same way every task since T-16 has handled R-88's absent artifacts.
* Two insight-index lines were load-bearing for this task and are worth naming as *used*: the one
  recording that `archive-task.sh` harvests `^##\s+Insights?\s*$` **exactly** (so the delivery's
  heading must be bare `## Insight` — the PM's problem at stage 7, flagged here), and the one
  recording `_telemetry_overlay()` as a second `sc`-authored writer of `dns.rules` on an ordinary
  host, which is what makes "the array is always non-empty" true in the `$append` half of the
  directive derivation.
