# 03 — Gate Review Rationale · T-23 `state-file-io-contract`

> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## Rule 85: the three designs, reconstructed line by line

I rebuilt both rejected designs against `bin/sc` at HEAD rather than reading the architect's account
of them.

**Design A — *three local hardenings, no new function* (≈ +13 / −9).** Reconstructed: two changed
lines in `load_nodes()` / `load_settings()`; four accessors narrowed to `except (OSError, ValueError)`
plus one `isinstance` line each; E-11/E-12/E-13/E-15 unchanged from the shipping design.

The architect claims it satisfies FR-4 and AC-1…AC-5 (minus the warning clause) "in full and without
argument". **That is false, and it is false in the smaller design's disfavour.** `_resolve_clash_port()`
is a *fifth* reader of `settings.json` (`bin/sc:439`) that Design A does not touch, and it is called at
`bin/sc:3661` — **outside** `main()`'s try. On AC-1's non-UTF-8 fixture its untouched tuple
`(FileNotFoundError, json.JSONDecodeError, OSError)` does not catch `UnicodeDecodeError`; on AC-3's
`null` / `42` / `"telemetry"` / `[]` fixtures the line `settings["clash_api_port"] = port` raises
`TypeError`. Either way every non-doctor command tracebacks, so Design A fails AC-1, AC-2 and AC-3 —
the very criteria it was credited with. It needs a fifth site (+2/−1) before it reaches parity with its
own claim, and even then it leaves all 16 unguarded call sites tracebacking, cannot satisfy AC-18
(it *adds* a fifth notion of "is this document usable?" at the accessors), and does not touch FR-12.

**Design C — the nearer alternative (this design minus `_settings_or_empty()` and `_unusable()`).**
Reconstructed by line count rather than by taste, because the architect's own rejection invites it.
`_settings_or_empty()` costs 8 code + 4 doc lines and *pays for itself*: it lets E-6/E-7/E-9/E-10 delete
four `try/except` blocks (4-5 lines each, ~16 lines) and replace them with one line each, so its net
effect on file size is approximately zero. Design C keeps those four blocks and adds an inline warn arm
in `_load_lang()`: net **+4 lines larger**, plus a fourth site deciding what a broken `settings.json`
means, plus five `OverrideError` construction sites for T-24 instead of one. So Design C loses the
"less is more" tie-break on its own terms — it is the larger design.

**`_unusable()` specifically.** It is the one place where I agree the architect is spending 3 lines on
something a trailing `except OverrideError as e: e.path = path; raise` would do for less. Rule 85
permits a refactor only when you can *name the future edit it prevents*. Here the future edit is named,
is filed, and is a pending row in the same batch: T-24 owns the override error model, and `_unusable()`
is the single line it must move if it re-parents the class. That is the strongest available form of
that justification, so the 3 lines stand — but they stand on RT-1 alone, and if T-24 lands first,
`_unusable()` must be re-examined rather than kept as decoration.

**Conclusion: the chosen (larger) design ships.** It is minimal in both directions — smaller than
Design C, and Design A does not satisfy FR-6, FR-8, FR-12 or AC-18 (and, as measured above, does not
satisfy FR-4 either). The extra ~57 lines buy four requirements and nothing else, and 43 lines come
back as deletions.

## The design's single load-bearing assumption — verified

"17 unguarded call sites inherit FR-6/FR-8 with zero edits" rests on every one of them sitting under
`main()`'s `try` at `bin/sc:3673-3674` with no intervening `except` that swallows an `OverrideError`.
I checked each:

- **Nodes, 7 sites:** `generate_config` `:2017`, `_resolve_node` `:2199`, `cmd_ls` `:2237`,
  `cmd_now` `:2271`, `cmd_use` `:2282`, `cmd_add` `:2308`, `cmd_status` `:2376`. All reached through
  the `handlers` dispatch at `:3674`. Critically, `generate_config`'s `load_nodes()` at `:2017` sits
  **after** the `try/except OverrideError: e.path = OVERRIDE_PATH; raise` block at `:2011-2015`, so a
  broken node store can never be mislabelled as the user's override file. The `except Exception` arms
  at `:730`, `:2306`, `:2387` and `:3282` each wrap a different expression (the `ss` parser, the share-URL
  parse, `_egress_ip()`, `_fetch_to_temp()`) and none encloses a state read; `generate_config()` at
  `:3310` is outside `:3282`'s arm.
- **Settings, 9 sites:** `:2345`, `:2357`, `:3090`, `:3125`, `:3188`, `:3217`, `:3377`, `:3416`, `:3454` —
  all inside handlers, none inside a `try`.
- The **guarded** ones are `:416`, `:439`, `:1572`, `:1791`, `_load_lang()`'s inline read at `:390`, and
  doctor's `:2763`. 22 call sites total, 6 guarded, **16** unguarded — hence F-5.
- The two sites that run **outside** `main()`'s try are `_saved_clash_port()` (E-7 routes it through
  `_settings_or_empty()`, which never raises) and `_resolve_clash_port()` (E-8 gives it its own
  `except OverrideError`). That is exactly why E-8 is not optional and why F-3/C-3 exist.

`_load_lang()` is called at exactly two places, `:3657` and `:3660`, one per arm of `main()`'s
read-only/initialising split, in both cases as the right-hand side of `LANG = …` with
`global LANG, CLASH_PORT` declared at `:3620`. Nothing else in the file calls it. FR-5's once-ness and
BC-12's English rendering are therefore structural, as K-7 claims.

## GA-1, at length

FR-11's text ("no write of an authored document reaches the user as a traceback") does reach
`save_settings()` on a literal reading, and out-of-scope item 7 excludes only its *mode* and
*atomicity*, not a write-failure guard. I nearly ruled the other way. Two things decided it:

1. **The diff does not change that function's failure surface.** I traced every value that can reach
   `save_settings()`: `lang`, `mode`, `ipv6`, `telemetry` and `default_tun` are validated ASCII enums or
   booleans at `:3452`, `:3088`, `:3116`, `:3178`, `:3205`; `clash_api_port` is an int; values read back
   from an existing document now come through a strict UTF-8 decode, so they can hold no lone surrogate.
   The one unvalidated key, `update_interval`, is `argv` verbatim — but under a non-UTF-8 locale that run
   already dies at `:3365`, where `override.conf` is written with `write_text()` and no encoding, *before*
   `load_settings()` is reached at `:3377`. So `ensure_ascii=False` + `encoding="utf-8"` cannot turn a
   HEAD success into a crash.
2. **The guard is not free.** `_resolve_clash_port()` deliberately swallows a failed persist
   (`:443-446`). A `save_settings()` that `sys.exit()`s like `save_nodes()` does would raise `SystemExit`,
   which `except OSError` cannot catch, so a read-only `/etc/sing-box` would start aborting every command
   — a behaviour change nobody asked for, repaired only by catching `SystemExit`, which is a wart.

Given the standing "less is more" directive and the burden of proof on the larger design, the smaller
answer wins on its merits rather than by deferral. RT-4 remains correct as filed; C-11 makes it carry
the reachability ground so T-2x does not re-litigate it blind.

## The R-22 trap, applied criterion by criterion

The question asked of each AC was: *what is the smallest wrong build that passes this?*

- **AC-1/AC-2/AC-3** are all passed by a build whose reader answers "unusable" for every document. The
  intended controls are AC-5 and AC-10, and I confirmed both are real: AC-5 demands Chinese output, the
  `off` decision, `allow`, a recorded port **and** no warning line, none of which an always-unusable build
  can produce; AC-10 demands two printed rows and an active tag. Both would fail such a build. The controls
  hold — that part of the criterion set is sound.
- **AC-3 individually does not discriminate** (F-2). Both builds print `auto` for the `"telemetry"`
  fixture; only the warning line separates them. And HEAD cannot demonstrate the "silently wrong `auto`"
  through `main()` at all, because `_load_lang()` tracebacks first on the same run — the substring accident
  is a unit-level fact, not a command-level one. This is the T-06 shape exactly: a criterion satisfied by
  the wrong build for the wrong reason.
- **AC-8** (F-1) is the T-22 shape exactly: a negative control demanding a mismatch correct code cannot
  produce. Four of the twelve runs are `sc status`, whose node read is behind `is_running()`, which K-13's
  own `SYSTEMD = OPENRC = False` makes permanently false. This is the third distinct appearance of the
  `is_running()`-under-a-fixture trap in this project (the insight index already carries it from
  `doctor-extended-checks`), which is why C-1 substitutes a command rather than relaxing K-13 — relaxing
  K-13 would put `SYSTEMD = True` and a `subprocess.run` stub between QA and the live service, and the
  substitute command costs nothing.
- **AC-8's other clauses are observable**: a sentence (from `main()`'s arm), a non-zero exit
  (`sys.exit(str)` → status 1) and byte-identity of the file (nothing writes before the raise).
- **AC-9** (F-9): `cmd_doctor`'s per-probe `except Exception` at `:2938` already guarantees "no
  `Traceback`" and "complete table" on **any** build, including one with no E-16 at all. The only
  discriminating clause is the node-delay row's text, which is unreachable without a stub.
- **AC-13** is passed trivially by a build that changed nothing — that is inherent to a preservation
  criterion, and it is fine *provided* it is never read as evidence that the feature works. Its live risk is
  the opposite one (F-8): correct code failing it on a legitimate input.
- **AC-6, AC-7, AC-11, AC-12, AC-14, AC-15, AC-16, AC-17, AC-18, AC-19, AC-20** each have a control that
  correct code can produce and wrong code cannot; AC-7's is fixture-dependent (F-10/C-7).
- **V-1…V-23**: the steps whose stated observable does not discriminate are V-3 (C-2), V-7 (C-7), V-8 (C-1)
  and V-9 (C-6). V-18's enumeration is good practice and is promoted into C-10. V-13's differential needs
  C-5's fixture restriction. V-11/V-12 are safe as written because the dev-map recipe stubs `SB_BIN`
  (`bin/sc:71` is a bare `"sing-box"` PATH lookup, so an unstubbed fixture would run the real binary), and
  AC-11's URL carries no fragment, so the tag it prints is ASCII and BC-14's stdout hazard is not hit.

## Verified good — positive notes behind the PASSes

- **T-13 (NFR-5/AC-15) is untouched.** `_write_private` `:504-526`: `mkstemp(dir=str(path.parent), …)` →
  `os.fchmod(fd, CRED_MODE)` on the still-empty descriptor → `fdopen`, `fd = -1` → write/flush/fsync →
  `os.replace` → `finally` closes a stray fd and unlinks a surviving temp. Adding `encoding="utf-8"` at
  `:509` changes the codec of the wrapper and nothing else; the mode is already exact one line earlier, so
  there is no instant at which credential bytes exist behind a wider mode.
- **T-14 (NFR-6/AC-16) is untouched.** `_config_digest()` `:1918-1928` hashes through
  `CFG_PATH.open("rb")` in 64 KiB chunks; nothing in the ledger goes near `:1906-1977`.
- **The reader has no rival.** `SETTINGS_PATH` is read at exactly two places (`:390`, `:556`) and
  `NODES_PATH` at exactly one (`:544`); after E-3/E-4/E-6 there is one. FR-1's "one reader" is achievable
  as stated, and FR-12's "one writer" needs only E-14 (`:539-540` is the second one).
- **E-16 is safe to narrow.** With `load_nodes()` converting `OSError`/`ValueError` into `OverrideError`,
  dropping those two from doctor's tuple loses nothing, and `TypeError`/`KeyError` are still genuinely
  reachable from `set(node["tag"] for node in nodes)` on a list of non-objects — BC-9's residual.
- **`verify_all`'s baseline is arithmetically consistent** with NFR-4: the script defines 18 checks
  (A.1, A.2, B.1, B.2, B.3, E.1, E.2, E.3, E.4, E.4b, E.5, E.6, F.1-F.6), of which exactly one — B.3, Lint —
  is a hard SKIP, giving PASS 17 / SKIP 1. I hold no `Bash` and did not run it; stages 4 and 6 must, from
  the repository root (insight index, 2026-08-15).
- **Anchors.** I resolved all seventeen anchors in the change ledger and the interface table against the
  file. Every one lands where the design says, with the single exception recorded as F-15. Stage 1's own
  dispatch carried two stale anchors; stage 2's carry one, and it is in the frozen set rather than in an
  edit.

## Why APPROVED WITH CONDITIONS and not ROLLBACK TO REQUIREMENTS

I considered the rollback seriously, on the T-22 precedent: two of the three FAILs are criterion defects
of exactly the class that rolled T-22 back twice. I did not take it because every one of them is a defect
in *how the work is verified*, not in what is to be built — no rollback would change a single line of the
design or of `bin/sc` — and because the fix for each is fully determined rather than a matter for the
author's judgment (substitute one command; name the discriminating observable; add a stub or declare the
criterion non-discriminating). The pipeline has a mechanism for precisely this, and it is the binding
conditions table, whose owner stages are 4 and 6 — the stages that would otherwise have written the
wrong test. Under the owner's standing decision grant for this batch I amended AC-8, AC-3's control,
AC-13's fixture set, AC-18's checking method, NFR-1, NFR-2 and NFR-3 in writing rather than approving
them while doubting them (R-61).
