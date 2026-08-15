# Delivery Summary

## Summary

- Task: **T-25 `output-layer-contract`** (pool `followups`) — give the user-facing output layer one
  contract: no key renders as its own name, one separator convention across `sc status` and
  `sc doctor`, plural handling for every count key at once, and flush discipline so a redirected
  `sc status` cannot interleave subprocess output above its own headings.
- Mode: **full** (7 stages).
- Stages traversed (2026-08-15): 1 requirement-analyst → 2 solution-architect → 3 gate-reviewer →
  4 developer → 5 code-reviewer → **4′ developer** → **5′ code-reviewer** → **4″ developer
  (PM-initiated, documentation-only)** → 6 qa-tester → 7 delivery.
- Rollbacks: **1** — stage 5 round 1, `CHANGES REQUIRED (0 CRITICAL, 1 MAJOR)`. CR-1: the developer's
  discharge of gate condition C-6 claimed BC-8's silent-corruption mode was **structurally**
  unreachable through `sc config`; the reviewer showed it was *conditional* on two unstated
  preconditions. No code defect was found at any stage. Round 4″ was not a rollback — the PM
  initiated it after the APPROVED verdict to close two of the reviewer's own open non-blocking
  findings rather than file them.
- Final `verify_all` result: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — the task-start baseline,
  measured by QA four times from the repository root. **0 new FAIL, 0 new WARN, no check added or
  removed.**
- Baseline changes: **none.** `baseline.json` stays at `test_count: 0` (frozen set + out-of-scope 10;
  a committed test is forbidden by this task's scope and is T-28's row).
- Outstanding risks: three, all recorded and none holding delivery. (1) **CR-10 is open by design** —
  both READMEs' `sc config` sentences are written for the *post-repair* world, so the filed
  `cmd_config` locale-decode row (R-76) carries the duty to **verify** them rather than change them.
  (2) `errors="backslashreplace"` **displaces** the POSIX locale's `surrogateescape` on stdout, so
  undecodable-byte data renders `\udcXX` instead of round-tripping — accepted (FR-7 is stated over
  survival, and QA measured that HEAD aborts before reaching either named site anyway, R-79).
  (3) R-45's price rose by two stderr lines at pipe-buffer scale; **R-45 stays declined** (R-75).
- Files changed: `bin/sc` **+80/−41**, `README.md` +6/−6, `README.zh-CN.md` +1/−1,
  `docs/dev-map.md` +12/−5 — **4 files, +99/−53**. Against the pool bar (T-22 +21/−11,
  T-23 +76/−51, T-24 +79/−55). Of `bin/sc`'s change, `#`-lines are **+33/−9**: the machinery share
  is **one import and one guarded statement**.
- Next steps for user: nothing required. `.harness/operator-obligations.md` row 4 step R-5 has been
  **marked in place** — the `sc add` non-UTF-8 exit-status residual it warned about is closed by this
  task (QA measured exit **0**), so the operator no longer owes that reading.

## What shipped

The output contract has **two homes, both already in the file**, and no third:

- **The string layer.** A key *is* its own English rendering (the five `ls.*` keys became `#`, `On`,
  `Type`, `Name`, `Address`), carries its own field punctuation (the separator moved *inside* the
  translated string, so `sc status` and `sc doctor` punctuate the same fact identically), and renders
  **one invariant form per count phrase** for every value of the number. Every `zh` value is
  byte-identical to HEAD; the only Chinese this task authors is `，`.
- **The stream layer.** One statement at the top of `main()` —
  `io.TextIOWrapper(sys.stdout.buffer, encoding=sys.stdout.encoding, errors="backslashreplace",
  newline="\n", line_buffering=True)`, guarded on the stream having a binary buffer — which buys
  write-order fidelity (FR-6) and unencodable-character survival (FR-7) **together**.

FR-8 is not a third home: it is four `cmd_status` call sites re-using the existing `_plain()`.
**Nothing new was created** — no `en` table, no message catalogue, no formatter, no plural-selection
helper, no second key per phrase, no print wrapper, no new file, no new function (`bin/sc`'s
top-level `def`/`class` count is **113**, unchanged), no new concept.

## Rows closed by this task

**All five named in the dispatch are closed, and one hand-off discharged.**

- **R-19 — CLOSED.** Known since T-02 and deferred by every task since; filed against these five keys
  at T-15. English `sc ls` now reads `#  On  Type  Name  Address  Delay`. **The row's stated cause
  was wrong and the analyst refuted it first-hand**: `t()`'s key-on-miss is not a defect — in English
  *every* lookup is a designed miss and the key **is** the rendering. The real defect is a key that
  is not its own English rendering, so no change to `t()` and no `en` table were needed or made.
- **R-33 — CLOSED, and it was wider than filed.** `cmd_status` runs **two** children
  (`systemctl`/`rc-service`, then `ip`), so two headings inverted, not one — and `cmd_update_interval`
  had the identical shape. Both are inside the guarantee, plus `argparse`'s own stdout output,
  because the statement sits before `parse_args()`.
- **R-34 — CLOSED by narrowing, as the row asked.** The falsifiable promise "exactly one value line
  per heading" is replaced by the true one: `sc` adds no line of its own.
- **R-38 — CLOSED.** One separator convention; `sc doctor`'s (punctuation inside the string) won and
  `sc status` adopted it. English rendering byte-identical.
- **R-40 — CLOSED for every count key at once**, exactly as the row demanded rather than for the one
  symptom: 14 members, one invariant form each, byte counts included, `{n}/{total}` fractions
  correctly excluded.
- **T-23's hand-off discharged.** Its AC-11/AC-12 *process-exit* clause, recorded **BLOCKED-BY-T-25**
  rather than passed or dropped, is closed by FR-7/AC-9 — and it was **far wider than
  `cmd_add`'s one `→`**: `sc ls` prints `●`/`→` on ordinary rows, so under a proved non-UTF-8 stdout
  `sc ls` was broken outright in English. No filed row said so.

## How the process behaved

- **Rule 85 was tested rather than accepted, and the smaller design won on its own merits.** The
  architect rejected the in-tree flush precedent and had to prove the larger construct earned its
  keep. The gate **re-priced the rejected route itself** and found no smaller construct exists on the
  3.6 floor (`reconfigure()` is 3.7-only; `sys.stdout.errors` is read-only; `PYTHONIOENCODING` needs
  a re-exec) — so `TextIOWrapper` is not a choice but the only option, and once it exists
  `line_buffering=True` costs **zero additional lines**. The gate also *corrected the site count in
  the rejected route's favour* (4 → 3) and still did not change the ruling. Recorded in
  `.harness/rejected-decisions.md`, corrected in place, no second record.
- **The batch's highest over-build risk did not materialise.** Two independent sweeps (gate,
  reviewer) confirmed every named over-build shape is absent, and round 4″ *shrank* the diff
  (`main()`'s comment block 15 → 8 lines).
- **The R-22 duty was discharged at three stages, and two criteria were reported
  NOT-DISCRIMINATING rather than passed** — repeating T-24's R-71 outcome deliberately. AC-12's
  comparison clause named a `sc doctor` routing-mode rendering **that does not exist** (QA measured
  `grep -ci` = 0 on both builds) and was re-pointed at the egress body; AC-13 was satisfiable by an
  empty screen, because `is_running()` returns `False` off its final line when neither init system is
  set. QA also reproduced the trap live: **HEAD's heading row `.isascii()` is `True`** — the naive
  "is it English?" check passes on the broken build.
- **Four dispatch claims were refuted by first-hand re-verification** rather than inherited (R-19's
  cause; R-33's width; the T-23 hand-off's width; and the defect being *published* in `README.md:94`
  and `docs/dev-map.md:90-92`, which no row mentioned).
- **A safety near-miss was caught, voided and re-taken.** In round 4′ the developer wrote its own
  `importlib` loader instead of the mandated recipe and re-exec'd into the **installed**
  `/usr/local/bin/sc` under password-less `sudo`. It was caught before any write, the run was
  declared **void** (never salvaged), and all five affected cases were re-taken on the mandated
  recipe, reproducing byte-for-byte. The reviewer then ruled the void run write-free on evidence
  *independent* of the harness's own witness — reading the installed build and finding
  `parse_args()` reached before `_init_files()`, so argparse's `invalid choice` ended execution
  before the first writer. The episode is why **R-78** is filed: the dev-map states the rule but not
  the **failure signature**, and a fresh context that skips the row sees an argparse usage error that
  reads like a harness bug.
- **C-1 held as a real floor**, not a formality: QA logged **142 runs, 142 `[C-1] VERDICT OK`, 0
  void**, and found a **second** hard-coded write path nobody had named (`cmd_update_interval` builds
  `Path("/etc/systemd/system/sing-box-rules-update.timer.d")` at `bin/sc:3439`), handling it with a
  fail-closed path jail rather than driving it. Live host untouched throughout: witnessed with
  `systemctl show -p MainPID -p ActiveEnterTimestamp`, `is-active` never called.
- **Nothing was BLOCKED.** No criterion needed root, a live service or a network, so for the first
  time in this pool's recent history **no operator obligation was appended**.

## Adversarial findings worth carrying

QA ran 14 unspecified cases; all survived. The two that would have caught a lesser design:

- **A latin-1 stdout that can encode *part* of the data** — the candidate prints `café-é` **and**
  `日本-jp` (escaped) at exit 0, while HEAD renders row 1 and then aborts. A character-inventory fix
  (which the requirement forbade by name) would have failed this.
- **A 240 KB child** — candidate headings land at lines 1 / 4003 / 8005; HEAD's at 8001 / 8003 /
  8005. **A per-site `flush=True` fix would not have survived this**, which is the rejected route
  measured rather than argued.

## Insight

- 2026-08-15 · Under the POSIX locale CPython gives `sys.stdout` `errors="surrogateescape"`, **not** `strict`, so a non-ASCII tag that arrives through `os.environ` under `LC_ALL=C` is silently surrogate-escaped and prints back as its original bytes — a "non-ASCII tag" fixture built that way **passes on broken code**, and only a tag transported as `\uXXXX` escapes makes the encoding defect observable · evidence: output-layer-contract
- 2026-08-15 · `sys.stdout.encoding` is resolved from `PYTHONIOENCODING` **before** the locale while `Path.read_text()` only ever asks the locale, so "the reader's codec is the writer's codec" is never a structural argument — `PYTHONIOENCODING=ascii` on a UTF-8 host makes `sc config` exit **0** with a document `json.loads` rejects (`\xe9` and `\U0001f1ef` are not JSON escapes) where HEAD aborted loudly · evidence: output-layer-contract
- 2026-08-15 · `docs/dev-map.md`'s mandated fixture-loader recipe cannot load `bin/sc` at all under the very environment every locale criterion needs — its bare `open("bin/sc").read()` decodes with the **locale** codec while CPython reads a script as UTF-8 (PEP 263), so `LC_ALL=C PYTHONUTF8=0` gives `UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 29`; `encoding="utf-8"` is required and its absence reads like a harness bug rather than a recipe defect · evidence: output-layer-contract

## Verdict

DELIVERED
