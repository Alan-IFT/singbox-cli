# 04 — Rationale — restricted-network-regression-test (T-07)

> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

## 1. Transcripts of the three `[HOST]`-safe executions

### V-3 — no argument, unprivileged (AC-3)

```
$ bash .harness/scripts/restricted-network-regression.sh ; echo "exit=$?"
usage: restricted-network-regression.sh --i-will-destroy-this-vm
       restricted-network-regression.sh --self-check [--source FILE]

--i-will-destroy-this-vm  run the scenario. Root, on a DISPOSABLE single-use
                          systemd VM only. It edits /etc/hosts and installs.
--self-check              derive the blackout and check coverage. No root, no
                          network, writes nothing. --source defaults to bin/sc.
exit=2
```

Usage goes to stderr; **no condition line is printed** (I-3: nothing was asked, so nothing is
claimed). `/etc/hosts` sha256 and the `MainPID` / `ActiveEnterTimestamp` witness pair were captured
immediately before and after and are identical.

### V-4 — token supplied, node store present, unprivileged (AC-4, AC-20 host half)

```
$ ls -l /etc/sing-box/nodes.json
-rw------- 1 root root 633 Jul 30 13:00 /etc/sing-box/nodes.json
$ bash .harness/scripts/restricted-network-regression.sh --i-will-destroy-this-vm ; echo "exit=$?"
REFUSED: a configured installation is present: /etc/sing-box/nodes.json
This is not a disposable VM. Nothing was read, written or started.
E1 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E2 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E3 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E4 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E5 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E6 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
exit=3
```

This is the whole of K-3's point: the node-store gate precedes the root gate, so the refusal is
reached on a host that carries a live installation **without the script ever establishing whether it
could have mutated anything**. Six lines, exit 3, `/etc/hosts` unchanged.

### V-5 — `--self-check`, four arms (AC-5, GC-5)

Covered arm (exit 0):

```
derived bases (4):
https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
blackout hosts (6):
api.github.com
cdn.jsdelivr.net
ghfast.top
github.com
raw.githubusercontent.com
testingcf.jsdelivr.net
SELF-CHECK OK: 4 shipped base(s), all covered
```

The four URLs are byte-identical to `bin/sc:114-117` (compared side by side in the same shell), and
base 3's `/`-field-3 resolves to `ghfast.top` exactly as A-2 predicted. Six hosts, not seven,
because `raw.githubusercontent.com` is both a shipped base host and one of the three GitHub names —
the `sort -u` dedup is what makes that one line instead of two.

Uncovered arm, `--source` at a scratch list carrying `https://127.0.0.1/geo` (exit 1):

```
derived bases:
https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://127.0.0.1/geo
SELF-CHECK FAIL: uncoverable base(s): https://127.0.0.1/geo
```

BC-13 arm, a source file with no `RULESET_BASES` block (exit 1):

```
SELF-CHECK FAIL: no base parsed from …/sc-empty
```

Missing-file arm (exit 1): `SELF-CHECK FAIL: no such source file: /nope`.

The scratch files live in the session scratchpad, not in the repository — AC-5's second run needs a
file, not a committed fixture, and committing one would have been an edit with no ledger row.

## 2. GC-6, measured rather than asserted

Reading the code proves the *order*; it does not prove that nothing under some other root was
touched. So all four non-mutating forms were run with both `cwd` and `TMPDIR` pointed at fresh empty
directories:

```
$ ( cd $G/cwd && TMPDIR=$G/tmp bash $ART            ; echo "no-arg exit=$?"
    TMPDIR=$G/tmp bash $ART --self-check            ; echo "self-check exit=$?"
    TMPDIR=$G/tmp bash $ART --i-will-destroy-this-vm; echo "refusal exit=$?"
    TMPDIR=$G/tmp bash $ART --self-check extra      ; echo "extra-arg exit=$?" )
no-arg exit=2
self-check exit=0
refusal exit=3
extra-arg exit=2
$ find $G -mindepth 1
$G/tmp
$G/cwd
```

Only the two directories themselves are listed: nothing was created inside either. `TMPDIR` is the
right lever because `mktemp -d` honours it, so a stray `mktemp` anywhere on those paths would have
left a `tmp.XXXXXXXXXX` directory behind.

The `--self-check extra` arm exists because I-3 says *any* other argv gets usage; a trailing unknown
word was silently ignored in the first draft and now exits 2.

## 3. Unit checks of the two pieces no `[HOST]` path reaches

`cfg_facts` and `val` were extracted with the project's own precedent idiom
(`sed -n '/^cfg_facts() {/,/^}/p'`, `.harness/scripts/check-i18n-parity.sh:48`) and driven over two
fixture documents shaped like the degraded and the recovered `config.json`:

```
degraded : defs=0;route_refs=0;dns_refs=0
recovered: defs=4;route_refs=2;dns_refs=3
missing  : defs=?;route_refs=?;dns_refs=?
val defs=4 route_refs=2 dns_refs=3
val on degraded dns_refs=0
```

The recovered shape reproduces F-2's count exactly — three `rule_set`-bearing `dns.rules` entries
(`bin/sc:1249,1250,1253`) — which is what makes GC-3's `dns_refs != 0` a real assertion rather than
a tautology. The `?` row matters too: an unreadable or absent document yields `?`, and `?` compares
unequal to every numeric target, so E4/E6 fail closed instead of dividing by a missing fact.

The report/exit derivation was driven the same way:

```
six PASS                 → six lines, exit 0
five PASS + one BLOCKED  → six lines, exit 1
unmet_all + finish 3     → six UNMET lines, exit 3
```

## 4. The E3 substring trap (D-3), with its negative control

`02_SOLUTION_DESIGN.md` V-14 asks for "a `failed:` line naming all four derived bases". The obvious
implementation is `grep -qF "$base" "$LOG"` per base. It is wrong here, and the reason is in the
data rather than in the code:

```
base 3: https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
base 4: https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
python3 -c "print(bases[3] in bases[2])"  →  True
```

Base 4 is a byte-suffix of base 3, so any line naming base 3 also "names" base 4 under a substring
test — including a `; ` join and a following ` -> `, which defeats a boundary test on the right side
too. `sc` builds each cause line as `"; ".join(base + " -> " + cause)` (`bin/sc:3274,3284`), so the
left boundary is the discriminator: an entry is preceded by `failed: ` or by `; `.

Two synthetic logs were generated from the real `RULESET_BASES` — one naming all four bases per
line, one naming only bases 1-3 — and both counters run over them:

| log | substring form | entry-boundary form |
|---|---|---|
| all four named | nbase=4 | nbase=4 |
| base 4 present only *inside* base 3 | **nbase=4** (false PASS) | **nbase=3** (E3 FAIL) |

The boundary form is what shipped (artifact lines 249-250). This is a strengthening inside E3's
stated assertion, not a new claim, but it is flagged as drift because a reviewer comparing the code
against V-14's sentence would otherwise see an extra condition and wonder where it came from.

The same measurement is the task's one insight: the substring form reports 4-of-4 coverage on a log
that carries 3.

## 5. Why the artifact does not fit 250 lines

The composition, measured with `awk` on the shipped file:

| region | lines |
|---|---|
| I-15 Chinese operator guide (mandatory, GC-9 forbids trimming it) | 28 |
| shebang + English header: language rule, SAFETY paragraph, the `set -e` argument | 10 |
| helpers + derivation + `self_check` + `cfg_facts` (code only) | 76 |
| argv dispatch + the four K-3 gates + pre-install readings (code only) | 46 |
| blackout: backup, block append, resolver proof, installer invocation (code only) | 16 |
| the six conditions and the recovery arm (code only) | 98 |
| `main "$@"` and the closing brace | 2 |
| remaining comments | 42 |
| blank | 12 |
| **total** | **330** |

Strip every non-guide comment (51) and every blank line (12) — the maximum a reviewer could ask for
without deleting a contract element — and the file is still **267** lines. The cap is therefore
unreachable, and F-11's "roughly 240-265 lines, so the ≤250 cap has no margin" was optimistic by
about 60 lines rather than wrong in kind. Stage 5 reached the same conclusion independently under
rule 85 (CR-2, `05_RATIONALE.md` §1) and demanded no refactor; none was attempted in round 2, whose
CR-1 and CR-5 fixes added 13 further lines because both add a `BLOCKED` arm the contract requires.

What the machinery buys, per the NFR's rule-85 clause:

- **The `pair=` discipline (~45 lines).** Six `obs=` strings, six `pair=` strings, the four
  `BLOCKED` arms that fire when a `pair=` value could not be taken (E1's, E3's, E4's, E6's) plus
  E5's no-agreement arm, and the cross-arm ordering that forces E3/E4/E6 to be composed after the
  recovery arm. Removing it turns FR-10 into a comment.
- **K-1's explicit-status idiom (~20 lines).** `rc=0; cmd >f 2>&1 || rc=$?` at three sites, `|| die`
  at the four must-succeed commands, `${x:-default}` after every `grep -c` that may see a missing
  file. `set -e` would have saved the lines and aborted at the observations the artifact exists to
  take — the exact trap the insight index already records for this repo.
- **The four gates and the coverage predicate (~46 lines).** This is the whole of the safety
  argument, and it is what makes the artifact runnable at all on a machine that is not the VM.

Nothing here is machinery for its own sake, and there is no second file to move it to: K-10 says one
executable file, and splitting it would trade a line-count WARN for a real coupling.

## 6. Two contract readings that needed a decision

- **D-1, the off-by-two ledger ids.** `## Change ledger` C-2 says "(I-9, I-10)" for the dev-map
  rows, but the `## Interfaces` table assigns I-9 to the injection proof and I-10 to `cfg_facts`,
  and names the dev-map rows I-11 / I-12. `02_RATIONALE.md`'s coverage table ("FR-15, AC-14 | C-2,
  I-11, I-12") and the dispatch brief agree with the Interfaces table, so the parentheticals are a
  transcription slip in one cell rather than a second numbering. Implemented per the Interfaces
  table; recorded rather than silently absorbed because a reviewer reading only the ledger would
  otherwise think two interfaces went missing.
- **The `EXIT` trap (D-4).** I-8 names three operations on `/etc/hosts` and K-4 says the artifact
  writes nothing else outside `$WORK`. A restore-on-exit trap is a fourth operation on the same
  file, so it needed a decision rather than a reflex. It was added because the failure it covers —
  dying between the append and the restore — leaves the VM unable to reach anything, including
  whatever the operator would use to diagnose it; and it is inert on every path this pipeline can
  run here, which was verified rather than assumed (`/etc/hosts` sha256 identical across the four
  non-mutating runs).

## 7. Residuals for stage 5 / 6

- Stage 5 did read GC-1…GC-7 against `## Condition disposition` and found four citations off by a
  few lines plus one overstated claim about `git` (CR-6). All five are corrected in place and every
  remaining citation in that table was re-checked against the post-fix file, which the CR-1 and
  CR-5 edits shifted by 13 lines below `:255`.
- Stage 6 owns GC-5's second half: compare the four printed base URLs **character-for-character**
  against `bin/sc:114-117`, because exit 0 alone cannot detect an under-matching derivation (F-6).
- Stage 6 owns GC-11: the AC-16 baseline must be a `git clone` under an ignored path, never a
  `git worktree` — under a worktree `.git` is a file, A.1/A.2 turn SKIP and the summary falsely
  reads 14/4.
- RS-5 holds unchanged: the artifact was never executed end to end, and every `[VM]` criterion
  (AC-6…AC-13, AC-20's VM half) is `BLOCKED` in this environment. The unit checks in §3 and §4 are
  offered as design evidence, not as substitutes for a `[VM]` run, and AC-19 forbids treating them
  as such.

## 8. BC-9 at E3 and E4 (CR-1), exercised rather than reasoned

The composition block (`:291-326`) was extracted with the same idiom as §3 (`sed -n '291,326p'`),
given stub `set_c` / `finish` / `val` and driven over five recovery-arm states. E1/E2/E5 are the
stub's placeholders (`x`); only E3, E4 and E6 are under test.

```
A  nok=-1 nrf=-1   (arm never ran: /usr/local/bin/sc not executable)
   E3 BLOCKED ... pair=unproven;recovery_arm_not_run
   E4 BLOCKED ... pair=unproven;recovery_arm_not_run
   E6 BLOCKED ... pair=unproven;recovery_arm_not_run
B  nok=0  nrf=4    (CR-1's case: the arm ran, every source still unreachable)
   E3 BLOCKED ... pair=unproven;no_reachable_source
   E4 BLOCKED obs=mode=600;defs=0;route_refs=0;dns_refs=0;sing_box_check=0 pair=unproven;no_reachable_source
   E6 BLOCKED ... pair=unproven;no_reachable_source
C  nok=0  nrf=0    (`sc` died before its first file)
   E3/E4/E6 BLOCKED ... pair=unproven;no_reachable_source
D  nok=4  nrf=0    (correct run, recovery works)
   E3 PASS ... pair=rec_failed=0;rec_ok=4
   E4 PASS ... pair=rec_defs=4;rec_dns_refs=3
   E6 PASS ... pair=bo_defs=0;bo_dns_refs=0
E  nok=2  nrf=2    (partial recovery)
   E3 PASS ... pair=rec_failed=2;rec_ok=2
   E4 PASS ... pair=rec_defs=2;rec_dns_refs=1
   E6 FAIL ... obs=urc=1;ok_lines=2;defs=2;...
```

Row B is the defect: in round 1 it printed `E3 PASS` and `E4 PASS`, and E4's `pair=` was
`rec_defs=0;rec_dns_refs=0` — the same two numbers as its own `obs=`, so the field asserted to be a
counter-observation was a restatement. Row C is the second state the widened guard buys. Rows D and
E are the regression check that mattered most: the fix must not cost a correct run its PASS, and it
does not — a recovery arm that reached even two sources still produces a `pair=` whose values differ
from the blackout reading, which is exactly what FR-10 asks for.

Why two reason strings rather than the reviewer's single `unproven;no_reachable_source`: E3 and E4
carry no `nok` in their `obs=`, so with one token an operator could not tell "`sc` was never
installed" (an E1 failure) from "`sc` ran and the network was still down" (an environment problem).
The distinction costs one line and one variable, and `rblock` is computed once instead of being
re-derived at three sites.

## 9. E5: the named fix was a no-op, and what shipped instead (CR-5)

`05_CODE_REVIEW.md` names `[ "$p5" = "$prev5" ]` as the fix and calls it "well-defined on both loop
exits". It is well-defined, and it is also **always true**: the last statement of the loop body is
`prev5="$p5"`, so on the exhausted exit `prev5` has just been assigned the value of `p5`, and on the
break exit the break condition itself required equality. Instrumented, on the very state CR-5 wants
caught:

```
crash loop, MainPID changes at each of ten reads, is-active reads `active` throughout
  p5=111 prev5=111 equal=yes      <- the named clause admits the crash loop
healthy install, stable pid
  p5=777 prev5=777 equal=yes
```

Adding the clause would have changed no verdict anywhere. What distinguishes the two exits is
*whether the break was taken*, which the loop did not record — so `agree=0/1` is set at the break
(`:263`) and the verdict arm consults it (`:273-275`). The matrix, driven over stubbed
`sysread`/`sb_pid` sequences (both are called in command substitutions, so the sequence has to be
fed from a file rather than from a shell counter):

| ten 1 s reads | round 1 | now |
|---|---|---|
| `active`, stable pid from t=1 | PASS `settled_at=2s` | **PASS** `settled_at=2s` |
| down 3 s, then `active` with a stable pid | PASS `settled_at=5s` | **PASS** `settled_at=5s` |
| `active` only at t=10 | PASS `settled_at=10s` | **BLOCKED** `unproven;no_mainpid_agreement` |
| `active` throughout, new pid at every read (crash loop) | PASS `settled_at=2s` | **BLOCKED** |
| never `active` (dead service) | FAIL | **FAIL** |
| flapping, ends `active` with a fresh pid | PASS | **BLOCKED** |
| flapping, but two consecutive reads agree | PASS | **PASS** |

Two properties I checked first-hand because they are what a false verdict would cost: a correct,
quiet install still PASSes on the second read (the service is started by `install.sh` several
observations earlier, so it has long settled by the time the loop runs), and a genuinely dead
service still reports **FAIL**, not BLOCKED — the fix must not launder a product failure into a
harness excuse. The one state that changed from PASS to BLOCKED without being a crash loop is "the
service took the whole 10 s window to come up", and BLOCKED is the honest verdict there: K-7 caps
the window at 10 s, so the artifact stopped looking before it could tell.

The residual is in the sampling rate, not in the logic: a crash loop with a cycle longer than about
two seconds can still show two agreeing 1 s reads. Closing it needs an `NRestarts` or
`ActiveEnterTimestamp` delta, neither of which is in the contract's observation set for E5, and
inventing one here would be design work rather than implementation.

## 10. The two smaller review findings, and the CR-4 ruling

CR-3 is taken. `die` now composes the report instead of bypassing it:

```
$ die "cannot back up /etc/hosts"
FATAL: cannot back up /etc/hosts
E1 UNMET obs=fatal:cannot_back_up_/etc/hosts pair=none
... six lines ...
exit=1
```

The spaces are folded to `_` for the same reason the precondition path folds them (`:174`): `obs=`
is a `;`-separated field list read by eye and by `grep`, and a space in it would split the line into
something a reader has to parse twice. Exit status is unchanged at 1, so no `verify_all`, no gate
and no caller sees a different status; the only difference is that the six lines I-5 promises now
appear on all four `die` paths.

CR-4 is ruled and not changed, and the reason is that its premise does not hold past gate 4. The
gate refuses the run outright when `systemctl`, `sing-box`, `curl` or `python3` is missing
(`:163-166`), so a `sysread` returning `unknown`, a `stat` returning `absent` or a `cfg_facts`
returning `?` after that point is not the harness failing to look — it is the product failing to
produce the unit, the log or a parsable document. FR-13's "could not be taken" is about the
observer; here the observer worked and found nothing, which is FR-8's assertion failing. Turning
those into BLOCKED would hide three real product failures behind a harness-excuse vocabulary, which
is the mirror image of the vacuous-green defect this task exists to prevent. The one genuine case —
`python3` disappearing between gate 4 and `cfg_facts` — is not reachable without someone deleting an
interpreter mid-run on a disposable VM.

The `[HOST]`-safe forms were re-run after the edits (usage/exit 2, bad argv/exit 2,
token → refusal/exit 3, `--self-check` in four forms), from a fresh empty `cwd` and `TMPDIR`; output
was byte-identical to §1's round-1 transcripts, both directories were still empty afterwards, and
`/etc/hosts` sha256 and the live service's `MainPID`/`ActiveEnterTimestamp` were unchanged. That is
expected rather than lucky: no round-2 edit lies on a path those forms reach.
