# Delivery Summary

## Summary

- Task: `sc-config-show` (T-06) — give `sc` a command that renders the installed sing-box
  configuration readably with no credential byte in the output.
- Mode: full (stages 1→7, single-Developer)
- Stages traversed: 1 requirement-analyst → 2 solution-architect → 3 gate-reviewer →
  4 developer → 5 code-reviewer → 6 qa-tester → 7 delivery. All on 2026-08-14, one round each.
- Rollbacks: **0**. Every stage returned on its first round. The two MAJOR gate findings (F-1, F-2)
  and the four stage-5/6 MINOR findings were discharged by binding conditions or filed as pool
  rows rather than by re-running a stage — no finding changed an interface or a shipped line.
- Final verify_all result: **PASS** — `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, identical to the batch
  baseline measured independently after T-19. Measured at three PM checkpoints (post-stage-4,
  post-stage-6, and independently by the PM before commit). A.1, E.6 and F.6 all PASS with both new
  stage documents in the tree.
- Baseline changes: none. `test_count: 0` in `.harness/scripts/baseline.json` is unchanged — this
  project still has no committed test suite (R-4/R-9, now ten tasks running), so QA's harness was
  again built and discarded. B.3 (lint) remains the single SKIP.
- Outstanding risks: none blocking. Six numbered rows filed (R-42 … R-47); the only one with real
  user impact is **R-42**, a pre-existing silent authentication failure for tuic nodes that this
  task found but correctly did not fix. AC-B9 is **BLOCKED, not substituted** (R-47).
- Files changed: 6 product files, **+261 / −26** (`git diff --shortstat`; the added count is
  `--numstat`'s first field, not `--stat`'s bar). `bin/sc` +196/−20, `README.md` +21,
  `README.zh-CN.md` +21, `CONTEXT.md` +14, `docs/dev-map.md` +7/−6, `CHANGELOG.md` +2.
  `docs/batches/**` left unstaged — it belongs to the batch loop.
- Next steps for user: install the new `bin/sc` and run `sc reload` for the change to reach the
  live host (standing R-30), then discharge **R-47** — one run of `sc config` as root on the live
  host, confirming the live configuration renders with every credential masked.

### The goal sentence was wrong in all three clauses, and stage 1 proved it before any code

This was the oldest row in the pool (written 2026-07-31, before T-13…T-19 shipped) and it is the
fourth consecutive task whose goal sentence did not survive contact with the code:

1. **`sc config --show` — phantom shape.** No `config` subcommand existed, and there is **no
   `parse_args()` function at all** (parsing is inlined in `main()`). `--show` also contradicts the
   project's own vocabulary: of 20 commands only two carry a flag, while `show` is a *positional*
   with three precedents. Shipped as **`sc config`**, bare.
2. **"optional `--redact`" — default and optionality both overturned.** The decisive evidence was
   not in `bin/sc` but in the installer: `install.sh:546-552` writes `/etc/sudoers.d/sc` granting
   the install user `NOPASSWD: /usr/local/bin/sc`, and `bin/sc:117-118` re-execs through `sudo` at
   import. So unredacted output — or any opt-out flag, which carries the identical property — would
   convert a **password-gated** read of a 0600 credential document into a **password-free** one.
   That is a privilege-boundary change produced by the project's own sudoers rule, and it would
   reverse T-13's hardening and T-14's digest-never-a-copy precedent. Shipped **always redacted,
   no opt-out**. The gate verified the evidence first-hand and closed the reverse-risk question:
   the unredacted document stays reachable by `sudo cat`, the password-gated route the sudoers rule
   does not cover, so no legitimate need is left unmet.
3. **"without root `grep`" — premise incoherent.** The file is 0600; reading it always needs root.
   `sc` does not bypass root, it *satisfies* it. What the user gains is not needing the path, not
   composing `sudo cat`, output safe to paste into a bug report, and one provenance line.

### Decision surfaced under the owner's standing grant

The redacted-by-default ruling is red-line-adjacent — it overrides an explicit instruction in the
goal sentence on security grounds. Per the standing grant (「你来决策就行」) it was decided
downstream and is surfaced here rather than blocked on, the route T-17 took. **If the owner wants
an escape hatch, this is the decision to revisit** — and the reasoning against one is in
`03_RATIONALE.md` § "The security ruling", not merely in the requirement.

### Rule 85 — "less is more" — was tested, not accepted

Stage 2 named the smaller alternative it rejected; stage 3 was dispatched to **test that answer
against the code** rather than accept it, and did:

- It **re-derived** `VISIBLE_IN_OUTBOUND` from the emitting code (37 distinct names, minus four
  credential names, plus `detour` = 34) instead of comparing it to the architect's table — on the
  grounds that matching a table proves transcription, not correctness, and a *missing* name is
  invisible to every leak test because the failure direction is a masked field. Stage 5 then
  re-derived it a second time, independently. All three derivations agree.
- It confirmed the 5-name alternative really does cost debuggability: on a reality/vless node it
  would mask `tls`, `transport` and `flow` wholesale — SNI, ALPN, uTLS fingerprint, ws path,
  `Host`, gRPC service name, precisely the fields `sc ls` does not show.
- It verified the `_drift_state()` extraction is **load-bearing rather than a refactor riding
  along**: `_warn_drift()` discards the *matches* state at `bin/sc:1892` and no caller can observe
  it, so FR-6's provenance line is unreachable without the split.

What shipped is exactly the design's inventory — two frozensets, one constant, one pure function,
one command function, one extracted judgement, three wiring lines, four translation keys, two help
rows. Stage 5, holding no shell, checked for undeclared growth by **line-offset arithmetic**: every
design-cited pre-edit line number must differ from the shipped one by exactly the sum of additions
above it, and the chain reconciles to +196 with no slack — leaving no budget for an undeclared
helper, extra option or defensive cap. The dispatch change is one line:
`if args.cmd in ("doctor", "config"):`.

### R-22 honoured — and the gate caught the T-15 shape before QA had to

**F-1 is the finding this task exists to be proud of.** AC-B1 and AC-B2 as written were **both
satisfied by an all-masked document** — AC-B2 satisfies *better* the more is masked, so the two
criteria agreed with each other on a completely useless build. That is exactly T-15's failure mode
(35 ACs green through stage 5, not one observing the behavioural goal), and this time it was caught
at stage 3 rather than stage 6. GC-1 bound AC-B1 to its stronger form: the mask must appear at
**exactly** the fixture's credential positions and nowhere else, counts equal, **and an all-masked
run is a FAIL**.

QA discharged it with an independent reproducer that flattens both documents to leaf positions and
derives the credential set **structurally from disk** rather than from the fixture's own recipe:
masked positions in stdout **10**, credential positions on disk **10**, equal, unmasked positions
differing from disk **0**, positions rendered verbatim **187**. A real configuration is rendered
readably and a real secret is actually hidden.

## Insight

- 2026-08-14 · `json.loads` parses with the **C scanner**, whose depth budget is not the Python recursion limit, so a ~1000-level-deep document parses cleanly and it is the *pure-Python* walk over the result that raises `RecursionError` — refuting the natural assumption (ruled at gate D-2) that a recursive JSON transform inherits the parser's own depth protection · evidence: sc-config-show
- 2026-08-14 · `sys.stderr` became unconditionally line-buffered only in Python 3.9, so on this project's 3.6 floor a redirected stderr is block-buffered and shutdown flushes stdout first — proved live by a negative control in which deleting one `sys.stderr.flush()` moves the commentary from lines 1-3 to **line 350** of a merged `2>&1` capture; the stderr twin of the already-indexed `cmd_status` stdout entry · evidence: sc-config-show
- 2026-08-14 · `urlparse().username` stops at the first `:` in the userinfo, so the idiom `userinfo = p.username; if ":" in userinfo:` is **structurally dead** — `bin/sc:713` has therefore never stored a tuic link's password and every tuic outbound `sc` has ever emitted carries `"password": ""`, a silent authentication failure that no config-level test can see because the emitted document is well-formed · evidence: sc-config-show
- 2026-08-14 · A fixture that proves "the command under test created nothing" must also stop its **own loader** from creating the config directory or a stub binary, because those writes land in the same `find` listing and read exactly like the command having initialised — the negative is only meaningful with raisers over `_init_files` / `_resolve_clash_port` plus a positive control proving a raiser *does* fire for a command that initialises · evidence: sc-config-show

## Verdict

DELIVERED
