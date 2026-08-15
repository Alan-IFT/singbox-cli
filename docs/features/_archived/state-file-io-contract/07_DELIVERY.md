# Delivery Summary

## Summary

- Task: **T-23 `state-file-io-contract`** — give every JSON state file one read/write contract
  (explicit `encoding=`, one catch family, one shape check) so a non-UTF-8 or non-object
  `settings.json` / `nodes.json` reaches the user as a sentence instead of a traceback, for all
  readers at once rather than three guard tuples.
- Mode: **full** (7 stages). Pool: `followups`, dispatched by `/harness-batch`.
- Stages traversed (2026-08-15): 1 requirement-analyst → 2 solution-architect → 3 gate-reviewer →
  4 developer → **1′ + 2′ criterion correction (parallel)** → 5 code-reviewer → **4′ developer** →
  **5′ code-reviewer** → 6 qa-tester → 7 delivery.
- Rollbacks: **2**, neither for a code defect.
  1. **After stage 4, to stages 1 and 2** — the developer found three acceptance criteria that could
     not detect what they claimed. The sharpest: **AC-11/AC-12 named an environment that is not a
     non-UTF-8 environment.** Under `LC_ALL=C PYTHONCOERCECLOCALE=0` on Python 3.7+, PEP 540
     auto-enables UTF-8 Mode because `LC_CTYPE` is `C`, so **HEAD passed both criteria unchanged** —
     the whole locale dimension of this row would have been certified vacuously. Also: the "exits 0"
     clause was unsatisfiable in scope, and AC-8's control was eleven tracebacks and one silently
     wrong answer rather than twelve tracebacks.
  2. **After stage 5, to stage 4** — two MAJOR prose defects, no code. `CHANGELOG.md` claimed
     `sc add` 「不再报错」 under a non-UTF-8 locale (false, and BC-14 forbids the claim by name), and
     `docs/dev-map.md` still described a defect this very diff had closed.
- Final `verify_all` result: **PASS** — `bash .harness/scripts/verify_all.sh` from the repository
  root, `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, matching the batch baseline exactly. Measured at four
  independent checkpoints (stage 4, stage 4′, stage 6, and this PM checkpoint).
- Baseline changes: **none.** `baseline.json` holds at `test_count: 0` — no committed test was added
  (**T-28** owns the suite). Nothing was lowered, no test deleted or skipped. QA ran **≈150
  stage-artifact fixture runs** under the session scratchpad, none committed (RT-7).
- Files changed (product): **4** — `bin/sc` **+76 / −51**, `CHANGELOG.md` +2, `CONTEXT.md` +9,
  `docs/dev-map.md` +9/−4. Of `bin/sc`'s 76 added lines, **46 are code**, 24 comment/docstring, 6
  blank. Plus `.harness/operator-obligations.md` +1 (QA's obligation id 4) and the PM's delivery
  bookkeeping.
- Outstanding risks: none blocking. Five rows filed (R-64 … R-68), one BLOCKED criterion carried to
  the owner, and two clauses recorded BLOCKED-BY-T-25 rather than passed or dropped.

## What shipped

One reader, one degrade, one factory — and **`main()`'s existing error arm was not touched at all**.

`_read_state(path, default=None, member=None)` is the only statement in the file of how a state
document is decoded (`read_bytes().decode("utf-8")`, never `read_text()`), parsed and shape-checked.
Its *unusable* answer is the file's **existing** `OverrideError` envelope with `.path` set, so
`main()`'s untouched `Cannot use {path}: {problem}` arm renders the sentence for **16 unguarded call
sites with zero edits to them**. `_settings_or_empty(warn=False)` is the single place deciding that
an unusable `settings.json` means an *empty settings document*, from which all four documented
defaults (`en` / `None` / `auto` / `block`) fall out. FR-5's once-per-run warning needs no flag:
`main()` already calls `_load_lang()` exactly once, before `LANG` is assigned — which is also what
makes that line English (BC-12), structurally rather than by remembering to.

**Rows discharged.** **R-29 closed** (and **R-25**, which it supersedes and widens), **R-17 closed**,
**R-27 closed** (a document `sc` cannot parse is never again replaced by a single-key document it
composed), **R-62 closed** on the credential population.

## What the pipeline refuted in its own brief

The dispatch handed this task a completed diagnosis and told stage 1 to re-verify rather than
inherit it. **Nine clauses did not survive**, and three changed the design:

1. **R-29's own prescribed fix is insufficient.** `_load_lang()` and `_saved_clash_port()` reach
   `.get()` on a non-dict → **`AttributeError`**, which R-29's `except (OSError, ValueError,
   TypeError)` does not catch. Applied literally, R-29's fix leaves two of the four readers it names
   still tracebacking. The **is-a-dict check**, not the catch tuple, is what closes the class.
2. **R-29's `"telemetry"` example does not raise at all in one reader — it answers wrongly and
   silently.** `"ipv6" not in "telemetry"` is a legal substring test, so `_ipv6_setting()` returned
   `auto`. Worse than a traceback, and named nowhere upstream.
3. **"Four readers" undercounts by an order of magnitude** — two helper readers plus one inline read
   across **22 call sites**, 16 of them unguarded.
4. **"Make T-06's oracle the contract everywhere" was unsafe as written.** `cmd_config`'s good
   sentence exists *because* it does not decode UTF-8; giving it `encoding=` would turn a
   one-sentence failure into a `UnicodeEncodeError` traceback on strictly-encoded stdout. The
   `config.json` readers were therefore excluded by design (Q-6, K-10).
5. **The fix closes the non-ASCII *credential* population, not the *tag* population.** A `香港节点`
   tag moves from a decode traceback to an **encode** traceback on stdout — re-homed to T-25, with an
   explicit ban on over-claiming it in any user-facing text. That ban is what stage 5 later enforced.

## Rule 85 — tested by reconstruction, not asserted

The architect named the smaller design it rejected (*three local hardenings, no new function*,
≈+13/−9), wrote it out in full, and **conceded it was genuinely correct** on FR-2, FR-4, FR-10,
FR-11, BC-3 and 12 of the 21 criteria — "not a strawman: it is what the brief asked for, and half of
this design's own diff is literally its item 3."

The gate then **rebuilt both alternatives against `bin/sc` line by line and corrected the architect
in the smaller design's disfavour**: Design A does *not* satisfy FR-4/AC-1/AC-2/AC-3 as conceded,
because `_resolve_clash_port()` is a **fifth** reader of `settings.json` that Design A never touches
and that runs **outside `main()`'s try** — so it tracebacks on every one of those fixtures. And the
*nearer* alternative (this design minus `_settings_or_empty()`) is **~4 lines larger**, because that
helper pays for its own 8 code lines by letting four `try/except` blocks be deleted. **The chosen
design is minimal in both directions.** The gate also corrected the architect's headline: **16**
unguarded zero-edit call sites, not 17.

**R-61 honoured rather than repeated.** The gate found NFR-1's `−30` to be a prediction masquerading
as a cap and **amended it in writing** (`≤ +76 added, ≤ 48 code`) instead of approving a cap it did
not believe — exactly what R-61 says a gate should do. The diff landed at **76 added / 46 code**:
exactly at the amended cap, two under on code.

## The R-22 trap, closed at three stages independently

The dispatch predicted the specific trap: *a criterion that checks "no traceback" is satisfied by a
build that silently swallows the file and returns defaults.* It was attacked three times.

- **The gate** asked of each criterion "what is the smallest wrong build that passes this?" and found
  three that could not discriminate — including **AC-8 demanding of `sc status` an observable correct
  code cannot produce**, because `cmd_status`'s only `load_nodes()` is behind `if is_running():`,
  which the mandated fixture holds permanently false. Substituted `sc use 1` (C-1).
- **The developer** found the locale recipe verified nothing (rollback 1).
- **QA built the wrong build and killed it.** `wrongbuild/sc` — the candidate with an unconditional
  `raise _unusable(...)` at the top of the reader — **passes AC-1, AC-2 and AC-3's observables** and
  is killed by AC-5 (which demands `off` / `allow` / Chinese output / **no** warning line) and AC-10
  (two rows and an active tag). The controls are real, not decorative.

QA also proved **C-5's fixture restriction load-bearing rather than cosmetic**: on an excluded input
(`update_interval: "每天"`) HEAD writes `\u6bcf\u5929` where the candidate writes `每天`, so AC-13
would legitimately fail there — the gate's GA-2 ruling was right, and right for the reason it gave
(`update_interval` is the one settings key copied verbatim from `argv` with no enum check).

## Hard constraints — both prior hardenings survive verbatim

- **T-13 preserved.** `_write_private()` still runs `mkstemp(dir=path.parent)` → `os.fchmod(fd,
  CRED_MODE)` **on the still-empty descriptor** → write / flush / fsync → `os.replace`, with the
  `finally` intact. The only change inside the region is the `encoding="utf-8"` keyword and one
  comment; `encoding=` selects the `TextIOWrapper`'s codec and opens no second descriptor. **No
  instant exists at which credential bytes sit behind a mode wider than `0600`** — verified by the
  reviewer against T-13's own timeline, and measured by QA (`600` on `config.json`, `nodes.json` and
  the drift record after every write, on both builds).
- **T-14 preserved.** `_config_digest()` still hashes `CFG_PATH.open("rb")` in 64 KiB chunks; no
  decode entered the drift quartet, so the verdict stays locale-independent by construction.
- **`_write_private()` remains the only writer of `config.json`**, `save_nodes()` of `nodes.json`,
  and — newly, via FR-12/E-14 — `save_settings()` the only writer of `settings.json`, the second
  writer having been `_init_files()`'s direct seed.
- **No credential, real or fixture, appears in any stage document.** `verify_all` A.1 PASS.

## Live host untouched

`systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` (never `is-active`) read
`MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` before QA, after QA, and at
this delivery checkpoint — identical three times. `/etc/sing-box` and `/var/lib/sing-box` mtimes both
predate the session. `/usr/local/bin/sc` was never invoked; every fixture neutralised the import-time
re-exec and no-op'd `_init_files()`, which hard-codes `/var/lib/sing-box` and is not repointable.

## Operator obligations

**AC-21 is BLOCKED by construction and nothing was substituted for it** — filed by QA as
`.harness/operator-obligations.md` **id 4**, with V-21's recipe verbatim. It needs root and the
installed `/usr/local/bin/sc` against the live service, which no agent here may touch. **This is the
seventh consecutive un-substituted operator obligation** (R-31 / R-41 / R-47 / R-52 / R-60, and
T-22's id 3) — the discipline held again.

Recipe, as filed: install the new `bin/sc`, `sudo sc add` a share URL carrying a non-ASCII password,
`sc reload`, and confirm the real `sing-box check` accepts the regenerated configuration. It carries
the standing **R-30** obligation with it: this change reaches the running host only when a human
installs the new `bin/sc`.

**Two clauses are recorded BLOCKED-BY-T-25 — never a pass, never a fail, never dropped.** AC-11's and
AC-12's *process-exit* clause: under a proved non-UTF-8 locale the candidate writes the correct bytes
and **then** dies in `cmd_add`'s own success line (`bin/sc:2345`), whose `→` is an **sc-authored
character, not user data** — so even an all-ASCII share URL exits non-zero. The disk clause passed;
the exit clause belongs to the output layer, which is T-25's row.

## Insight

- 2026-08-15 · `LC_ALL=C PYTHONCOERCECLOCALE=0` does **not** give a non-UTF-8 Python — PEP 540 auto-enables UTF-8 Mode whenever `LC_CTYPE` is `C`/`POSIX`, so stdout, `getpreferredencoding()` and the filesystem encoding all stay UTF-8 and **every encoding assertion passes on broken and fixed code alike**; only adding `PYTHONUTF8=0` yields `stdout=ascii preferred=ANSI_X3.4-1968`, and any locale criterion in this repo that omits it certifies nothing · evidence: state-file-io-contract
- 2026-08-15 · `sys.stderr` is created with `errors="backslashreplace"` while `sys.stdout` is **strict**, so under a non-UTF-8 locale an `sc` diagnostic on stderr degrades to an escape and survives while a `print()` of the same character raises — which is why `⚠️` has been safe on stderr since T-13 and why `cmd_add`'s sc-authored `U+2192` at `bin/sc:2345` kills an otherwise-successful run; a criterion written against stderr cannot detect a stdout encoding defect · evidence: state-file-io-contract
- 2026-08-15 · `json.loads` accepts `bytes` and **auto-detects UTF-16/UTF-32**, so a `read_bytes()` fed straight to it silently accepts a document that is not UTF-8 at all — the explicit `.decode("utf-8")` is the whole of what makes "UTF-8 regardless of locale" true, proved by a UTF-16 `nodes.json` that the shipped reader rejects by name · evidence: state-file-io-contract
- 2026-08-15 · A `sc doctor` probe that raises loses its **whole section**, not one row: `_doctor_clash()` returns its four rows as a single list, so one exception collapses Clash API + responding + node delays + DNS lookup into one `this check could not run: {e}` row — measured by reverting a single guard, which drops the table by 3 rows while still printing no traceback and still exiting on doctor's own scale · evidence: state-file-io-contract

## Next steps for the user

1. **Install the new `bin/sc` on the live host and run `sc reload`** — the change reaches the running
   installation no other way (standing R-30).
2. **Then discharge operator obligation id 4** (`.harness/operator-obligations.md`), the one promise
   this task could not close by a run.
3. Nothing else is required. There is **no data migration and no compatibility window**: neither
   document's on-disk format changed, and a downgraded build reads every document this build writes.

## Verdict

DELIVERED
