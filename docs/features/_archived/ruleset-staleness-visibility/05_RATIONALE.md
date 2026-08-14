> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Trigger log

- **T5.2** — `04_RATIONALE.md` opened to adjudicate `DESIGN DRIFT` D-1. Present; the measurement is there.
- **T5.1 / T5.3** — not fired. No design-fidelity finding turns on *why* `02` chose a shape, and no reuse-correctness or risk finding was raised, so `02_RATIONALE.md` was not opened.
- **T5.4** — not fired. Every identifier acted on (`R-12`, `RS-1…RS-6`, `F-1…F-14`, `A-1…A-7`, `C-1…C-8`, `P-1…P-8`) is defined in a contract portion.

## D-1 — the adjudication in full

**The claim.** A-3 answered "is `sys.stderr.write(s + "\n")` byte-identical to `sys.exit(s)`, including the interleaving `install.sh` sees?" with "the interleaving is unchanged too: stderr is unbuffered in both, and the buffered stdout is flushed at interpreter shutdown either way". The developer says the second half is false, and added `sys.stdout.flush()` at `bin/sc:2869` to restore what HEAD had.

**What I could and could not do.** I hold no execution tools, so I could not re-run the comparison. What I *could* do is test the transcript against the code for consistency — a fabricated or carelessly-produced transcript would have to get three non-obvious details right by accident:

1. **HEAD's capture has the aggregate last, after the outcome line.** That is only possible if the interpreter's `SystemExit`-with-a-string handling flushes Python-level `sys.stdout` before writing the string to `sys.stderr`. If it did not, HEAD's merged capture would already show the aggregate ahead of the buffered stdout — and the developer would have had nothing to fix. The transcript asserts the opposite of the cheaper, lazier answer.
2. **In the candidate-before-fix capture the fourth per-file line is terminated by the aggregate's own leading `\n`.** `print(prefix, end="", flush=True)` (`bin/sc:2791`) leaves `  ↓ geosite-private.srs ... ` on the line with no newline; `sys.stderr.write("\n" + …)` supplies one. The capture shows exactly that shape. Nobody writes that by hand.
3. **Only the last per-file line splits; the first three are intact.** That follows from the per-prefix `flush=True`: each file's `flush` also pushes out the *previous* file's still-buffered `failed: …` remainder. The fourth file has no successor to flush it, so only it is stranded. The developer states this mechanism explicitly and it is a correct reading of `:2787-2827`.

Three details, each a consequence of code the transcript does not quote, all consistent. I treat the measurement as sound.

**The fix's shape.** `sys.stdout.flush()` sits inside `if failed:` (`:2868`), immediately before the write, and changes no stream's *content* — only the point at which stdout's buffer is handed to fd 1, on the one path that also writes to stderr. It cannot affect the exit status, the outcome line, the wording, the leading newline or the single-line shape. It adds no envelope, no `try/finally`, no `atexit`, no wrapper, so K-15 stands. It is one line inside E-10's own hunk and inside the +80 budget, which the total still respects at +80 / −29.

**New failure modes?** A `flush()` can raise (EPIPE, ENOSPC) where the shutdown flush would instead print "Exception ignored". But `print(prefix, end="", flush=True)` at `:2791` already flushes stdout inside this same function on every run, and the outcome line at `:2857-2867` is printed *before* `:2869`, so a broken stdout has already failed earlier. The added line introduces no failure class the function did not already have.

**Why "small" is not the reason.** The instruction was explicit that size alone is not an argument, and I did not use it. The reason to accept is that K-13's *stated purpose* — the BC-8 / FR-9 freeze on what `install.sh:567` records — is achieved **only** with the flush. Rejecting the drift would ship a measurable, install-log-visible reordering of a stream the requirement freezes, in order to honour the letter of a constraint whose own justification the change serves. That is the inversion C-8 was written to prevent; the gate itself said "C-8 requires you to prove it rather than inherit this answer", and the developer proved it and found the inherited answer wrong. This is a condition working exactly as designed.

**What is owed, and to whom.** Nothing is owed to the developer. The document that carries the wrong statement is `02` K-13 (byte-identity claimed on the wrong granularity) and `03` A-3 (the interleaving asserted rather than measured). That is the solution-architect's wording to correct — but the behaviour shipped is already the correct one, so the correction travels as RES-2 to `07_DELIVERY.md` and to the insight ledger, not as a rollback. Stage 6 still owns C-8: the developer is explicit that he removed the failure the condition was aimed at, and did not discharge the condition.

## Every reachable state of the new tail, enumerated independently

I did not take stage 4's word for I-6's closure. Reading `bin/sc:2829-2873` as a state machine over `(failed, changed, CFG_PATH.exists(), gained, regen_ok, is_running(), restarted)`:

| state | path | outcome line | is every claim true? | `ok` | exit |
|---|---|---|---|---|---|
| nothing changed | `changed` empty ⇒ branch (a) | `No rule-set changed — the sing-box service was not touched` | yes — no apply block ran at all | `not failed` | 0, or 1 with the aggregate if a download failed, and the line is still true |
| no config (fresh install) | `CFG_PATH.exists()` False ⇒ apply block skipped, `restarted` stays `None` ⇒ (d) | `Rule-sets updated: … — the sing-box service was not touched` | yes — nothing was regenerated and nothing was touched | `True` unless `failed` | 0 / 1 |
| regeneration or `sing-box check` failed | `gained` non-empty, `regen_ok` False ⇒ no `Rule-sets restored` print, restart guard `regen_ok and is_running()` short-circuits ⇒ (d) | `… — the sing-box service was not touched` | yes, and crucially it makes **no** regeneration claim | `False` | 1 |
| service not running | `is_running()` False ⇒ `restarted` stays `None` ⇒ (d) | `… — the sing-box service was not touched` | yes | `True` unless `failed` | 0 / 1 |
| restart returned 0 | `restarted` True ⇒ (b) | `… — sing-box restarted to load them` | yes | `True` unless `failed` | 0 / 1 |
| restart returned non-zero | `restarted` False ⇒ (c) | `… — the sing-box service could not be restarted` | yes | `False` | 1 |

Six states, one line each, the chain is a single `if/elif/elif/else` so exactly one fires, and `Done` is unreachable on every non-zero path because `:2872` precedes `:2873`. Two extra observations worth recording:

- The state "content changed, `gained` empty, service running" restarts **without** regenerating and prints (b). That is T-10's behaviour preserved exactly: the line claims a restart, which happened, and claims no regeneration, which did not.
- The state "downloads partly failed, the rest changed, restart succeeded" prints (b) *and* the stderr aggregate *and* exits 1. Every claim on the stdout line is true of the run; the failure is stated on the stream the requirement assigns it. `ok` correctly reads `False` through `not failed`.

`restarted is False` is unreachable while `changed` is empty, because the only assignment sits inside `if changed and CFG_PATH.exists():` — so branch (a) can never be paired with a failed restart.

## The A-6 choice, checked rather than accepted

The developer took starred unpacking at all three sites (`:860`, `:887`, `:889`) plus `:2404`. I verified the tolerance he flags in `04_RATIONALE.md`: `for tag, fname, status, *_rest in states` no longer raises if the snapshot tuple *shrinks*. The exposure is genuinely bounded — `ruleset_states():837` is the single producer, `ruleset_state()` has exactly two callers (`:834`, `:849`) and both were widened, and no other site in the file destructures either shape. I checked for a stale 3-element or 5-element unpack anywhere in `bin/sc` and found none. The choice is sound and its cost is honestly recorded.

## Why CR-2 is worth a line at all

`docs/dev-map.md:51` is one of the two rows this task corrects, so it is already `+1 / −1` in the diff: changing more text inside it costs nothing in the numstat that C-6 polices, and out-of-scope item 11 admits a correction to a row it already admits correcting. The claim left standing — that `generate_config()` destructures the 3-tuple — is precisely what F-14 flagged and A-1 answered, and this row is the one T-20 will read when it wires `_age_text()` into `sc doctor`. The same sentence in `bin/sc:856-857` is a different matter: that line was not otherwise edited, `bin/sc` landed at exactly the +80 ceiling, and buying a truer docstring at the price of an overrun would have been the wrong trade. Hence one finding and one follow-up row rather than two findings.

## What I checked and found nothing wrong with

Recorded so a later reader knows these were examined rather than skipped:

- **Security.** No new input parsing, no new subprocess, no new network call, no new file write, no new path construction, no format-string reaching user data (`t()` at `:411-413` formats only with explicit keyword arguments). `_age_text()` renders an integer. Nothing in the diff touches credential handling or `_write_private()`.
- **Performance.** `cmd_status()` gains four full chunked `.srs` reads it did not perform before (RS-4) — bounded, local, no network, no subprocess — and one `fstat` per file on an already-open handle. C-2 makes stage 6 measure it rather than assert it. The unit-ladder tuple is rebuilt per call, four times per `sc status`; irrelevant.
- **Concurrency.** BC-14's story is unchanged because `_temp_path()` / `tmp.replace(target)` are untouched, and the `fstat`-on-the-same-handle rule is what makes the reported age belong to the bytes that decided the status even when a timer run replaces the inode mid-`sc status`.
- **The CHANGELOG entry.** Long, but at the file's existing density — every entry in `## [Unreleased]` is one dense paragraph. I read it for truthfulness rather than length and found no claim the code does not support, including the placement claim, the no-`\r` claim, the "两处对同一个文件的年龄各说各话" impossibility claim and the freeze list.
- **`t()`'s English path.** `TRANSLATIONS` has only a `"zh"` key (`:124-125`), so `t()` returns the English sentence verbatim; all seven new keys read as English prose. The one blemish is `1 days ago`, which is RS-5, already homed.
