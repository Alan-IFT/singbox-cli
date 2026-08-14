> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1. CR-1, verified in both directions

The fix is four lines (`:291-294`) and the whole of its correctness is in the initial value of `nok`
and the ordering of two tests, so I enumerated every path that reaches `:293`.

`nok` is declared `-1` at `:279`, inside the same `local` as `rcap`, `urc`, `nrf` and `rcf`, and is
assigned exactly once, at `:284`, inside the `if [ -x /usr/local/bin/sc ]` body. There is no other
assignment and no `unset`. So on arrival at `:293` there are precisely three states: `-1` (the guard
never entered — `sc` absent or not executable, which on this scenario means the install itself
failed), `0` (entered, and `grep -cF 'OK ('` matched nothing), or `≥1`. `[ "$nok" -lt 0 ]` selects
exactly the first, `[ "$nok" -eq 0 ]` exactly the second; they cannot both fire, so the ordering
carries no hazard and the second line cannot overwrite the first's reason. That is the direction the
developer was fixing, and it is right.

The direction a rushed fix breaks is the other one, so I spent most of the time there. `rblock` stays
empty for every `nok≥1`, and all three consumers test `[ -n "$rblock" ]` rather than re-deriving, so
E3 (`:299`), E4 (`:308`) and E6 (`:317`) all fall through to their verdict arms on a working recovery
arm. A **partial** recovery is the interesting case, because the guard is on `nok`, while E4's `pair=`
is about `defs`/`dns_refs` — if a partial recovery left the config unregenerated, E4's `pair=` would
be `rec_defs=0;rec_dns_refs=0` again and the vacuity would survive at `nok=2`. It does not:
`bin/sc:3295-3303` regenerates the config whenever `changed and CFG_PATH.exists()` and `gained` is
non-empty, and in this scenario every rule-set starts absent, so any successful download is a gain.
`generate_config()` therefore runs, and `rec_defs` reflects the recovered subset. That matches the
developer's measured row E (`nok=2 → rec_defs=2;rec_dns_refs=1`) and it is why I accept the
`nok≥1` threshold as the right predicate rather than a lucky one. `route_refs` is not in E4's pair,
so the one degenerate sub-case left — a partial recovery whose recovered tags happen not to be the
DNS-referenced ones, giving `rec_dns_refs=0` — still differs from the blackout reading in the other
pair field. Not a vacuity.

I also accept the two reason tokens over my single one, and the argument is better than the one I
made. E3 and E4 carry no `nok` anywhere in `obs=`, so on a BLOCKED arm the token is the operator's
only handle: `recovery_arm_not_run` says "read E1, the install failed", `no_reachable_source` says
"read your VM's egress". Collapsing them would have saved one line and cost the reader a
bisection. My round-1 named fix (`-lt 1`, one token) was the cheaper shape, not the better one.

## 2. CR-5: the refutation is correct, and my named fix was wrong

I will state this plainly because the pipeline is better off when it is stated plainly: the developer
refuted a reviewer's named fix with a measurement, and they are right.

The loop at `:259-266` ends its body with `prev5="$p5"` (`:265`). On the exhausted exit that
assignment has just run with the tenth read's value, so `p5 = prev5` holds by construction; on the
break exit the break condition at `:262` *required* `[ "$p5" = "$prev5" ]` to be true. Adding
`[ "$p5" = "$prev5" ]` to the PASS conjunction at `:267` would therefore have been a tautology at
both exits and would have changed no verdict on any input — exactly what their instrumented
`p5=111 prev5=111 equal=yes` shows on the crash-loop state I wanted caught. I described it in round 1
as "well-defined on both loop exits", which was true and was the wrong property to check; the
property that separates the exits is *whether the break was taken*, and the loop did not record it.
The `agree` flag at `:263` is the minimal thing that records it.

Then I audited the replacement for the two failure directions it could have introduced, because a
guard that BLOCKs a correct run is as expensive as one that PASSes a broken one.

*Can it BLOCK a correct quiet install?* No. The BLOCKED arm at `:273` requires `st = PASS` (i.e.
`st5 = active`) **and** `agree = 0`. On a correct install the service is started by `install.sh:593`
during step 7, and the settle loop does not begin until after the install capture (`:206`), five
`grep` passes and a `sing-box check` — several seconds later. Read 1 finds `active` with a stable PID
but `prev5` is empty, so it cannot break; read 2 finds the same PID and breaks with `agree=1`. PASS,
`settled_at=2s`. The only correct-run state that turns BLOCKED is "the service first became `active`
at second 10", and BLOCKED is the honest verdict there — K-7 caps the window, so the artifact stopped
looking before it could tell. That is FR-13's own vocabulary, not a false negative.

*Can it PASS a crash loop?* Not one whose cycle is shorter than the sampling interval, which is the
case CR-5 named: ten reads with a changing `MainPID` never satisfy `[ "$p5" = "$prev5" ]`, so
`agree` stays 0 and the arm is BLOCKED. A crash loop with a cycle longer than about two seconds can
still show two agreeing 1 s reads and PASS. The developer says so themselves and names the only
closures (`NRestarts`, an `ActiveEnterTimestamp` delta), neither of which is in the contract's
observation set for E5. Inventing one at stage 4 would have been design work; declining to is
correct, and the residual travels as RES-4(a) rather than as a finding.

One thing I checked separately because D-6 changes a status: a dead service still reports FAIL. `st`
is computed at `:267` before the arm, the BLOCKED branch is gated on `st = PASS`, and `st5 ≠ active`
falls to the `else` at `:275`. A product failure is not laundered. This is also what makes CR-13
below a real asymmetry rather than a stylistic one — the guard exists at E5 and is missing at E3/E4.

## 3. Where I looked for the fifth vacuous green, and what I found instead

Method as in round 1: for each arm, name a host state in which every term of the PASS conjunction is
true while the claim is false; then, new this round, the inverse — name a host state in which a
BLOCKED arm fires while the condition should have FAILed.

No fifth vacuous green exists. E1 (`:219`), E5 (`:273`), E3 (`:299`), E4 (`:308`) and E6 (`:317`)
are five BLOCKED arms and `finish` (`:73-80`) exits 0 only when all six lines begin `E<i> PASS `, so
BLOCKED is never green anywhere. E6's PASS additionally requires `nok=4`, which subsumes its own
guard. E2's and E5's pairs remain the pre-install readings, whose only degenerate case (a host whose
units were already installed and enabled but which carries no `nodes.json`, no `config.json` and no
`.srs`) survives from round 1, is not new, and is narrow enough that I left it unraised in both.

The inverse search did find something, and it is CR-13. `rblock` is consulted *before* each
condition's own verdict at `:299` and `:308`. E6 is the one place where that ordering is
unambiguously right — E6's own observation *is* the recovery arm, so if the arm reached nothing there
is nothing to judge. E3 and E4 are different: their `obs=` comes from the blackout arm and was taken
successfully; only their `pair=` is missing. So on a no-egress VM, a `log_mode` of `644`, a
`config.json` at mode `600` that `sing-box check` rejects, or the `is not writable` form that BC-10
names as `E3 FAIL` in so many words, all report BLOCKED. FR-10's purpose is to stop a vacuous PASS,
not to suppress a FAIL that needs no counter-observation to be true. K-11's letter ("a condition
whose `pair=` value could not be taken is BLOCKED with reason `unproven`") is unconditional and does
support what shipped, which is why this is MINOR and not MAJOR — it is a collision between K-11 and
BC-10 that the developer resolved toward the more specific and later clause, and BC-10's arm cannot
be triggered by this artifact anyway, since it never makes `/var/log` unwritable. The fix, if stage 6
or a later round wants it, is to give E3 and E4 the shape E5 already has: compute `st`, report it
when it is FAIL, and BLOCK only when the arm would otherwise have PASSed.

CR-14 is the same family, one step smaller: `nok=0, nrf=0` means `sc update-rules` produced neither a
success nor a failure line, which on a restored network is a product crash and not a reachability
problem, yet it is labelled `no_reachable_source`. `urc` is captured at `:283` and `nrf` at `:284`, so
the discriminator is in hand. I left it at NIT because E6's `obs=` prints `urc=` and `ok_lines=` one
line below, so nothing is hidden from a reader who reads all six lines — which is the reading
discipline the whole report format assumes.

## 4. CR-3's fix, and the one thing it costs (CR-15)

`die` at `:68` now reads `printf 'FATAL: …' >&2; unmet_all "fatal:${1// /_}"; finish 1`. I checked
the three properties that mattered. It emits six lines on all four call sites (`:187`, `:190`,
`:193`, `:278`), so I-5 now holds on every path past I-3. It writes nothing and consults no gate, so
GC-6 is untouched — `unmet_all` only assigns array elements and `finish` only prints, and the
earliest filesystem-creating construct in execution order is still `mktemp -d` at `:187`. And the
exit status is unchanged at 1, so no caller, gate or `verify_all` reading moves. The `_`-folding of
spaces matches the precondition path at `:174` and keeps the `;`-separated `obs=` grammar intact.

The cost is that `unmet_all` overwrites all six entries unconditionally. At the first three call
sites nothing has been composed yet, so it is free. At `:278` — the `/etc/hosts` restore failing —
E1, E2 and E5 already hold real verdicts, and they are replaced by `UNMET obs=fatal:…`. Three
genuine observations are discarded on the one path where the operator most needs them, since that
path also leaves the VM blackholed. The `EXIT` trap then retries the same `cp` with `|| true`, which
is harmless. NIT rather than MINOR because the path requires a `cp` to a writable `/etc/hosts` to
fail as root, and because nothing about it can produce a false green.

## 5. Re-verification after the line shift, and the citation spot-check

Every GC discharge I signed in round 1 was re-located and re-read at its new line: GC-1 at `:219-225`,
GC-2 at `:209`/`:214-215`/`:238-242`/`:249-250`/`:284`, GC-3 moved from `:311` to `:324`, GC-4 at
`:258-266`/`:268` (strengthened by `:263` and `:273-275`), GC-5 at `:117-120`, GC-6 at `:187`, GC-7 at
`:50-51`, GC-9 against 330/267, GC-10 with the sole `/usr/local/bin/sc` invocation now at `:283`. None
regressed. K-3's gate order is byte-unchanged (`:138-148` → `:151` → `:157` → `:163-175`) and every
round-2 edit is either inside `die` — whose four call sites are all past gate 4 — or past `:255`,
which is what makes the developer's claim that no argv, refusal or `--self-check` path changed
behaviour verifiable by reading rather than only by their re-runs.

K-1/K-2 around the new code specifically: `set -e` is still absent (`:40`); `agree` is initialised in
the `local` at `:258` so `set -u` cannot bite at `:273`; `i` is declared in the same `local` and, as a
word-list `for`, holds `10` on the exhausted exit rather than `11`, which is what `settled_at=${i}s`
at `:268` prints; the two new tests at `:293-294` are `&&` statements whose non-zero status is
consulted by nothing; and the round-2 edits added no redirect, no pipeline assignment and no `sleep`,
so K-7's 15 s budget is unchanged.

CR-6 is resolved and I spot-checked more than the four cells that were wrong, since the finding was
precisely that citations did not contain their construct. GC-2's ten citations (`209`, `214`, `215`,
`238`, `239`, `240`, `241`, `242`, `249-250`, `284`) and its two regex citations (`197`, `88`) all
land on the named construct; GC-1's `219-225`, GC-3's `320-325` with the `dns_refs` clause at `324`,
GC-4's `259-266`/`268`/`263`/`273-275`, GC-6's `187`, GC-7's `50-51` plus the three `git` occurrences
at `:17`, `:19`, `:48`, D-6's `258-275`, D-7's `:42`/`:22`, and the open-issue citations `291-294` and
`:68` are all correct at 330 lines. The GC-7 cell's round-1 error ("the string `git` does not occur")
is now stated accurately.

## 6. Rule 85 at 330 lines

Round 1's regional analysis stands and I will not repeat it; what is new is 13 lines, so the question
is only whether those 13 earn their place. Four of them (`:291-294`) closed a MAJOR by which two
conditions printed PASS with a `pair=` that restated their own `obs=`; two of those four are the
comment naming BC-9 and why the readings collapse, which is the reason the guard exists and is not
recoverable from the code. That is the cheapest possible discharge and it is unarguable.

The nine at E5 are the ones worth arguing about, and four of them are a comment (`:269-272`). I judge
the comment the *most* earned of the thirteen, not the least: it records that `[ "$p5" = "$prev5" ]`
is a no-op because of the loop's tail assignment. That is a fact a reviewer (me) got wrong from the
code, and without the comment the next reader to notice the missing agreement test will propose the
same tautology and, if they are less careful, ship it. Rule 85's counter-rule asks me to name the
future edit a different shape would prevent; here I can name it exactly, which is the rare case where
four comment lines are load-bearing. The remaining five are the `agree` initialisation folded into an
existing `local`, the `agree=1; break` at the break site, and the three-line BLOCKED arm — no
structure that a different shape would remove.

At 330 the floor argument is unchanged in kind and worse in degree: 28 mandated guide lines plus 239
code lines is 267 before a single comment or blank, against a 250 cap. The overrun is now 80 rather
than 67, and 63 of those 80 predate this round. Demanding a refactor now would mean deleting the
correctness commentary that this very round proved is what stops a wrong fix — so the answer is the
same as round 1: earned, no refactor, and the cap's provenance goes to stage 7 as RES-5.

## 7. Adjudication of the round-2 dispositions

**D-6 — accepted, and recorded as a correct refutation.** See §2. The named fix was wrong, the
measurement that showed it was the right way to establish that, and the shipped mechanism is
well-formed in both directions.

**D-7 and D-8 — accepted.** The substance of CR-8 and CR-11 was never that the resolutions were
wrong; both were the right reading of a self-contradictory or impractical contract clause. Declaring
them is the whole remedy, and it is done.

**CR-4's ruling — accepted, with one narrowing.** The developer's premise holds: gate 4 (`:163-166`)
refuses the run without `systemctl`, `sing-box`, `curl` or `python3`, so past that point `unknown`,
`absent` and `?` are the product failing to produce a unit, a log or a parsable document, and FAIL is
the truthful verdict. Calling them BLOCKED would hide three real failures behind harness vocabulary —
the mirror of the defect this task exists to prevent, and the same principle they applied to keep a
dead service at FAIL in D-6. The narrowing is only that the argument they use to decline CR-4 is the
argument that convicts CR-13: they are the same principle, applied at E5 and at the `sysread`/`stat`
degradations but not at E3/E4's `rblock` precedence. Accepting the ruling and raising CR-13 is
therefore one position, not two.

**CR-7, CR-9, CR-10, CR-12 — unchanged and unblocking.** CR-7's gap is upstream in FR-7/V-15 and is
not stage 4's to close. The other three are reading notes for stage 6 and stage 7.

## 8. Why the verdict is not plain APPROVED

Nothing open is CRITICAL or MAJOR, and neither axis carries an unaddressed one, so the masking rule
permits approval. `APPROVED WITH RESIDUALS` rather than `APPROVED` because five residuals travel with
real owners, and two of them (RES-2, RES-3) are verification this stage could only do by reading — the
`git`-level identity checks and the printed-derivation comparison genuinely require stage 6's
execution. That the artifact still cannot run end-to-end here is Q-15/RS-5's designed-for outcome and
is not counted against it. RES-4 now carries three `[VM]`-only readings rather than two, which is the
honest consequence of a round that closed a MAJOR by adding BLOCKED arms: each new arm is a state
only a real run can exhibit.
