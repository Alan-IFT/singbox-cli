# 01 — Rationale · T-30 `validate-before-baseline`

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## Method, and its limit

**No command was executed at this stage** — this analyst holds no shell. Every statement below is
read from source, from the shipped unit files and from prior contract portions, and every one carries
a `path:line` citation so the next stage can re-take it. The claims are therefore *established by
reading*, not *measured*; AC-1…AC-11 exist precisely to convert them into measurements, and stage 2
must not quote this document as a measurement. Two prior tasks were burned by the opposite habit
(T-24's inherited ordering claim, T-27's two upstream documents), which is why the ordering below was
re-read from the current file rather than inherited from the brief.

## The ordering, re-verified first-hand

`generate_config()` spans `bin/sc:2054-2161`. Its tail, in file order:

| line | statement |
|---|---|
| `:2138` | `_warn_drift()` — stderr only, "those changes are about to be replaced" |
| `:2139` | `text = json.dumps(config, indent=2, ensure_ascii=False)` — the document's bytes exist here |
| `:2147-2149` | comment "Ordering versus `sing-box check` is unchanged: the config is written first", then `_write_private(CFG_PATH, text)` |
| `:2150-2153` | `except (OSError, ValueError)` → one stderr line, `return False` |
| `:2154` | `_record_generated()` — "only after the document really reached disk" |
| `:2156-2157` | `r = subprocess.run([SB_BIN, "check", "-c", str(CFG_PATH)], capture_output=True, text=True)` |
| `:2158-2160` | non-zero → `⚠️ Config check failed:\n{stderr}` on stderr, `return False` |
| `:2161` | `return True` |

`reload_or_restart()` (`:2178-2182`) is `if not generate_config(): return False` then
`restart_service()`. So a rejected document reaches disk, is baselined, and the service is **not**
restarted. The brief's description of the ordering is confirmed exactly; nothing in it was
overstated. Note that `docs/tasks.md:186`'s R-70 row still cites `bin/sc:2135` / `:2603` for this
call and for `cmd_doctor`'s guard, both stale by ~20 lines — a live demonstration of why forward
requirement prose carries no line anchors while backward evidence must.

## The true consequence, in full

Four questions were asked; here are the answers with their evidence.

**1. Does the service keep running the previous configuration?** Yes. `restart_service()` is not
reached (`:2179-2181`), and `systemd/sing-box.service:7-10` is `Type=simple` with
`ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json` and
`ExecReload=/bin/kill -HUP $MAINPID`. `sc` never sends the HUP; the daemon re-reads the file only at
start. So the running process is serving bytes that no longer exist anywhere on disk.

**2. Does `sc doctor` report no drift on a document `sing-box` would refuse?** Yes for the drift row,
no for the report as a whole. `_record_generated()` (`bin/sc:1994-2000`) stores the digest of the
just-written file, so `_drift_state()` (`:2020-2029`) returns `False` and `_doctor_config()`
(`:2646-2647`) renders `config drift — matches what sc last generated`. That row is not *false*: `sc`
did last generate it. But S3 also runs its own `sing-box check` (`:2663`) and prints the checker's
error as a PROBLEM row (`:2682-2684`), so `doctor` is not blind — the invalidity is on the screen.
**The record's harm is that it removes the signal that the on-disk file is untrusted, not that it
hides the failure.** This is the finding that shrinks the fix: the write is the damage, the record is
the missing alarm, and one ordering change fixes both.

**3. Does a later restart load the rejected document and fail?** Yes, and this is what makes the row
severe rather than tidy. Three triggers, in increasing order of nastiness:

- **Reboot / crash.** `ExecStart` reads the file at every start (`sing-box.service:9`). With
  `Restart=on-failure` + `RestartSec=5` (`:11-12`) the unit retries the same rejected file until
  systemd's default start-rate limit drops it into `failed`. The host comes back with no proxy.
- **`sc on`**, or any operator restart, has the same effect immediately.
- **The weekly timer, unattended.** `sing-box-rules-update.timer` (`OnCalendar=weekly`,
  `Persistent=true`) runs `sc update-rules` (`sing-box-rules-update.service:7`). In
  `cmd_update_rules()` the regeneration is guarded by `gained` (`bin/sc:3401`) while the **restart**
  is guarded only by `regen_ok and is_running()` (`:3415`), inside `if changed and
  CFG_PATH.exists():` (`:3400`). On the ordinary weekly case — a rule-set's bytes changed, nothing
  was *gained* — `regen_ok` is still its hoisted `True` (`:3394`), no regeneration is attempted, and
  `restart_service()` runs (`:3420`) against whatever is on disk. That is the landmine detonating
  with no user present, up to a week after the error scrolled past.

So the user's timeline is: Monday, a bad override earns `⚠️ Config check failed`, the proxy keeps
working (in-memory config), the error is easy to dismiss; the following weekend the proxy dies. The
two events look unrelated from the user's seat. **Bounded and cosmetic is not the honest answer
here** — but note what *is* bounded: the user is told at the time (exit 1 on `sc reload`, the
check-failed line on `sc add`), and recovery is one `sc reload` after fixing the override. It is a
latent-failure defect, not a silent-corruption one.

**4. Is anything else lost?** The previous working `config.json` is unrecoverable — T-14 rules out a
second copy on disk, correctly (it would be a second credential document). That is an argument *for*
never overwriting with an unvalidated document, not for adding a backup.

## Why "move the record below the check" is rejected (Q-6)

The tempting one-line fix. It fails on its own terms:

- The rejected document still sits in `config.json`, so every trigger in §3 above still fires. The
  severe half survives untouched.
- The record now describes the *previous* document while the file holds the new one, so
  `_drift_state()` returns `True` and `_doctor_config()` (`:2642-2645`) renders *changed since sc
  generated it — keep the change in `override.json`, then run `sc reload`*. The user is told they
  edited a file that `sc` itself overwrote. The same sentence goes out of `_warn_drift()` on the next
  run (`:2046-2051`).

A one-line change that produces a false accusation is exactly the 修修补补 rule 85 forbids. The
coherent statement is the one FR-2 makes: the file, the record and the running service name one
configuration in **every** outcome.

## Candidate answers considered, and why the binding one won

| id | candidates | why the chosen one |
|---|---|---|
| Q-2 (one or two) | (a) two tasks — a `which` guard now, the ordering later; (b) one design. | (a) edits the same six lines twice and the second edit moves the call the first guarded. Rule 85 test 1 is weak here (each half is individually coherent), test 2 is decisive: both halves need the same judgement — what the checker said, and what to do about each answer. |
| Q-3 (R-81) | (a) widen the return to a 3-tuple; (b) sentinel value; (c) leave filed. | (a) and (b) both force a rendering decision at `sc ls` (`bin/sc:2319`) and `sc doctor` (`:2860`) or the distinction is computed and unconsumed. Neither is one line, and neither shares a seam with config installation. |
| Q-7 (no binary) | (a) refuse to install — "unvalidated is unacceptable"; (b) install with a warning. | (a) is defensible but forms a second opinion against `sc doctor`'s existing one (`bin/sc:2628`: "A missing binary makes the check UNKNOWN — never 'config invalid'"), and it newly breaks `sc add` / `sc use` on a host whose binary was removed, where today they work. (b) keeps the existing judgement in one place and changes no exit code on any host that has the binary. |
| Q-9 (`text=True`) | (a) leave it, file it; (b) fix at this site. | It is the same expression FR-1 relocates; the doctor's invocation already demonstrates the shape (`:2546-2547`: `stdout=PIPE`, `stderr=STDOUT`, `.decode("utf-8", "replace")` through `_plain()`). Leaving a known traceback inside a line being rewritten is the seam rule 85 names. |

## What the shape of the fix probably is (non-binding, stage 2 owns it)

The requirement is behavioral on purpose. But the analyst's own reading is that the whole defect is
an ordering, and that the smallest coherent form is: compose → install the bytes under the same
`mkstemp`/`fchmod`/`fsync` discipline that already exists → ask the checker about *that* name →
`os.replace` it into `config.json` only on a non-rejecting verdict → record. That is the existing
writer's own five steps with the verdict inserted between the `fsync` and the `replace`, plus a
three-arm guard around one `subprocess.run`. It should land well inside the 25-line budget. Two
recorded declines constrain how that is expressed (Q-8), and stage 2 must state the smaller
alternative it rejected.

One risk deserves naming loudly: **the transient object holds credential bytes.** T-13's whole
argument (`bin/sc:489-514`) is that no credential content ever exists at a mode wider than `0600` at
any instant, and its rationale explicitly declined a shared helper partly because the credential path
"needs no validation hook". This task gives it one. BC-1 therefore restates T-13's guarantees as
binding on whatever new object appears, and AC-7 makes the stub checker itself witness the mode at
the one instant the object is complete — the only way to observe it from a run rather than by
inspection. T-13's BC-10/NG-11 (no sweeper in the credential directory) is why "removed on every
outcome" is stated as a boundary condition rather than assumed.

## Related historical tasks

Linked, not re-described:

- T-24 `override-error-envelope` — established R-73's mechanism (and refuted its own brief);
  `docs/features/_archived/override-error-envelope/01_REQUIREMENT_ANALYSIS.md` BC-9 (no override that
  works today changes behaviour) and Q-8 (the envelope deliberately stops **above** the checker) are
  both inherited here.
- T-19 `ruleset-staleness-visibility` —
  `docs/features/_archived/ruleset-staleness-visibility/02_SOLUTION_DESIGN.md` I-4/I-5/K-9/K-10 and
  V-14: the one determination, the one exit site, and R-12's two unwind paths recorded rather than
  fixed.
- T-13 `config-write-permission-hardening` — `_write_private()`'s five elements and the declined
  shared helper (`.harness/rejected-decisions.md` `shared-atomic-write-helper-with-ruleset-downloader`,
  `umask-bracket-for-credential-writes`).
- T-14 `config-composition-layer` — digest-never-a-copy; the drift quartet's single judgement.
- T-05 `sc-doctor` — the declined `shared-singbox-check-wrapper`, `_plain()`, and DEF-1 (a fake
  checker cannot reveal that `sing-box check` colours a pipe).
- T-10, T-02 — one apply per run; 自动恢复 before the non-zero exit.
- T-29 `state-file-contract-completion` — the settings refusal now inside `generate_config()`, and
  the four-document-catch gate finding; R-100's deliberate decline.
- T-28 `committed-test-suite` — `.harness/scripts/check-sc-contracts.py`, the loader recipe's working
  reference and the assertion floor this task's ACs extend.

## Insight-index entries that bore on this document

All four surfaced by the PM applied:

- The silent-replacement class is reachable only at an **unguarded** array key, and the harm that
  survives un-stubbing is "the overwrite plus the baselined drift record, never the exit code" — this
  is the sentence Q-1 had to either confirm or refute, and it confirms it while adding the timer
  trigger the entry does not mention.
- The four `OverrideError` raise sites with four `.path` values — why Out-of-scope 6 forbids touching
  the composition guard, and why AC-10 freezes `cmd_update_rules()`'s discriminating arm.
- `main()`'s read-only arm is `("doctor", "config")` only — every fixture driving `main()` for
  anything else touches `_init_files()`; hence BC-13's "never drive `_init_files()`".
- One case per process for a `bin/sc` fixture — AC-1…AC-6 are six processes, not six calls.

## Notes for the architect that are not requirements

1. `docs/dev-map.md:41` currently documents the old order in prose ("installs it through
   `_write_private()` …, records the digest, then runs `sing-box check`") and `:70`'s drift-quartet
   row says the record "runs only after a successful `_write_private()`". Both need one edit; that is
   an E-row, not a new requirement.
2. `CONTEXT.md`'s **drift record** entry ("rewritten only after a successful install") stays true
   under FR-6 and needs no edit. The new **checker verdict** term is added there by this stage.
3. `sc.SB_BIN` is a repointable `str`, not a `Path`, so `check-sc-contracts.py`'s repointing
   assertion does not cover it (`docs/dev-map.md:176-177`) — a fixture must set it explicitly, and
   AC-4/AC-5 depend on that being remembered.
4. `shutil.which()` tests `X_OK`, which is why AC-5 needs an *executable* file of non-executable
   content to separate a presence guard from a real one.
