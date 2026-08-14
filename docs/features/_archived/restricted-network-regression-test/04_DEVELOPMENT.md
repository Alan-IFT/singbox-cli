# 04 — Development — restricted-network-regression-test (T-07)

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

- **Task ID**: T-07 · **Mode**: full · **Date**: 2026-08-15 · Upstream verdict read:
  `APPROVED WITH CONDITIONS` (GC-1 … GC-11); code-review findings CR-1 … CR-12 are dispositioned in
  `## Design drift` (D-6 … D-8) and `## Open issues for review`.
- Schema note: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`
  (R-37, fifth occurrence), so this portion carries the developer schema as written and every
  transcript, measurement narrative and drift argument is in `04_RATIONALE.md`.

## Summary

One new executable, `.harness/scripts/restricted-network-regression.sh` (330 lines, mode `0755`),
drives the whole blackout → install → recovery scenario and prints six condition lines E1…E6, each
carrying an `obs=` and a `pair=` value read in that same run. Nothing in the shipped product moved:
`install.sh`, `bin/sc`, `uninstall.sh`, `systemd/*`, `baseline.json`, `verify_all.{sh,ps1}` and
`.gitignore` are byte-unchanged, and `verify_all` still reads `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`.
The artifact was **not** executed end to end (that is RS-5's designed-for outcome); the three
`[HOST]`-safe forms — usage, refusal, `--self-check` — were run and are transcribed in the rationale.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `.harness/scripts/restricted-network-regression.sh` | New. Chinese I-15 operator guide (28 lines) + English body: `usage`/`die`/`set_c`/`unmet_all`/`finish`/`sysread`/`sb_pid`/`val`, the derivation trio `derive_bases`/`host_of`/`uncoverable` + `derive`, `self_check`, `cfg_facts`, and `main` (argv → 4 gates → blackout → install arm → E1/E2/E5 → recovery arm → E3/E4/E6 → report). Mode `0755` at creation; `git ls-files -s` records `100755`. | C-1 |
| `docs/dev-map.md` | Exactly two rows appended to `## Reusable utilities`: the `CURL_OPTS_QUIET`/`CURL_OPTS_PROGRESS` seam row (I-11) and the artifact row (I-12). `git diff -U0` = 2 added lines, 0 removed. | C-2 |
| `.harness/rejected-decisions.md` | One appended record `## blackout-by-sb-rules-base-env-var` (I-13): decision, why (it replaces `sc`'s list instead of making the shipped one unreachable, cannot cover the three GitHub names, and its injection is unprovable at the resolver), origin. | C-3 |
| `CONTEXT.md` | One appended `## Language` entry `**blackout**` (I-14), 2 sentences + `_Avoid_` line. | C-4 |
| `docs/features/restricted-network-regression-test/04_DEVELOPMENT.md` | This document. | C-5 |
| `docs/features/restricted-network-regression-test/04_RATIONALE.md` | Rationale portion (transcripts, measurements, drift arguments). | C-5 |

No file outside this ledger was edited. `git status --porcelain` over the frozen set
(`install.sh`, `bin/sc`, `uninstall.sh`, `systemd/`, `baseline.json`, `verify_all.{sh,ps1}`,
`.gitignore`, `README*.md`, `CHANGELOG.md`) is empty.

## verify_all result

```
baseline (before any edit): PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after C-1…C-4:              PASS 17 / WARN 0 / FAIL 0 / SKIP 1
after the CR-1/CR-3/CR-5 fixes: PASS 17 / WARN 0 / FAIL 0 / SKIP 1
delta:                      0 new FAIL, 0 new WARN, 0 lost PASS
invocation:                 bash .harness/scripts/verify_all.sh   (no extensionless dispatcher here)
skip (unchanged):           B.3 Lint — no lint config committed
bash -n on the artifact:    passes
F.4 headroom at measurement: insight-index.md = 30 / 30 lines (GC-8 is delivery's, not mine)
F.5 headroom at measurement: docs/tasks.md = 300 / 300 lines (same)
```

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | `## Change ledger` C-2/C-3/C-4 name their interfaces as `(I-9, I-10)`, `(I-11)`, `(I-12)` | The dev-map rows were written as **I-11/I-12**, the rejected-decisions record as **I-13** and the `CONTEXT.md` entry as **I-14** | The ledger's parentheticals are off by two against the `## Interfaces` table, where I-9 is the injection proof and I-10 is `cfg_facts`. `02_RATIONALE.md:37` ("FR-15, AC-14 \| C-2, I-11, I-12") and the dispatch brief both resolve it the same way. Documentation-level only; no behaviour depends on it. |
| D-2 | K-10 / NFR: one file of **at most 250 lines** | 330 lines (28 guide + 51 other comment + 12 blank + 239 code incl. shebang) | Measured, not estimated: at zero non-guide comments and zero blank lines the file is still **267** lines, so the cap is unreachable without dropping a required element. Per GC-9 nothing was dropped — six conditions, twelve `obs=`/`pair=` fields, four gates, the derivation + coverage predicate, the hosts block + resolver proof, both arms and every I-15 guide element are present. Round 2 added 13 lines: 4 for BC-9's E3/E4 guard (CR-1), 9 for E5's crash-loop arm (CR-5). Stage 5 adjudicated the overrun as earned (CR-2) and demanded no refactor. |
| D-3 | V-14 / E3: "per `.srs` a `failed:` line naming all four derived bases" | Each base must be named **as its own entry** — the fixed strings `failed: <base> -> ` or `; <base> -> ` — on every one of the `failed:` lines | Base 4 (`https://raw.githubusercontent.com/…/sing/geo`) is a byte-**suffix** of base 3 (`https://ghfast.top/` + base 4). A plain substring test counts base 4 on a line that only ever named base 3, so E3 would report PASS on a log missing one of the four sources. Proved with a negative control: the boundary form yields `nbase=3` on that log, the substring form `nbase=4`. This strengthens E3 within its stated assertion; it does not change what E3 claims. |
| D-4 | I-8: `/etc/hosts` is backed up, appended to, and restored | Same, plus an `EXIT` trap that restores from `$WORK/hosts.orig` when it exists | A run that dies between the append and the restore would otherwise leave the VM blackholed, and the operator's own diagnosis of that failure would be network-blocked. The trap is guarded on `$WORK` being non-empty **and** the backup existing, so it is inert on the usage path, both refusal paths and `--self-check` — verified on this host (`/etc/hosts` sha256 identical across all four runs). |
| D-5 | K-3 gate 4: "the remaining FR-2 preconditions" | Also refuses when `curl` or `python3` is absent, and when `/etc/sing-box/config.json` already exists | `curl` and `python3` are `install.sh`'s own dependencies and `cfg_facts` needs `python3`, so their absence is an unmet precondition rather than a failed condition. The `config.json` check tightens BC-11: a host with a generated config is a used host even if its rule-set directory was emptied by hand. |
| D-6 | V-16 / AC-10: "`active` within the settle window → `E5 PASS`", and K-11 fixes E5's `pair=` as the pre-install `is-active` reading | `active` **and** two consecutive 1 s reads agreeing on a non-zero `MainPID` → `PASS`; `active` with no agreement anywhere in the window → `BLOCKED` with `pair=unproven;no_mainpid_agreement`; not `active` → `FAIL` as before (artifact `:258-275`) | CR-5: `active` alone cannot separate a settled service from one crash-looping under `Restart=on-failure`, and E5 was the last place two conditions agreed rather than constrained. This is a claim E5 could not take within K-7's 10 s, so FR-13/BC-12 make it `BLOCKED`, not `PASS` — and never `FAIL`, so a genuinely dead service still reports `FAIL` and a healthy one still `PASS` (proof in `04_RATIONALE.md` §9). The `pair=` substitution on a BLOCKED arm follows the shape E1 already ships and that the gate discharged under GC-1. |
| D-7 | I-1: the confirmation token is "spelled exactly once in the file" | Spelled twice — the `TOKEN` constant (`:42`) and the I-15 operator guide's invocation (`:22`) | I-1 and I-15 cannot both hold: I-15 requires the guide to carry the invocation with the token **verbatim**. Every *test* of the token reads `$TOKEN`, so the property I-1 protects (one place to change it) holds; the guide's copy is documentation. Declared here because stage 5 (CR-8) rightly noted it was resolved silently in round 1. |
| D-8 | I-10: `cfg_facts` prints `defs=<n> route_refs=<n> dns_refs=<n>` (space-separated) | Same three counts, `;`-separated | The three counts are spliced whole into `obs=`, whose field grammar is `;`-separated, and `val()` slices them back out; a space would break the one-line-per-condition report. One line, three counts, no document byte — I-10's substance is unchanged. Declared here because stage 5 (CR-11) noted it was undeclared in round 1. |

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| GC-1 | discharged | E1's `pair=` is `step6_warn=<n>;fail_banner=<n>` where `step6_warn` counts the step-6 rule-set-failure warning (`grep -cF 'Ruleset download failed'`) in the **same** capture — the one marker that separates a degraded success from a healthy one, since the banner and exit 0 are identical in both. The failure-banner count rides along as the companion GC-1 permits. `step6_warn=0` ⇒ E1 is `BLOCKED` with `pair=unproven;step6_warn=0`, never PASS (artifact lines 219-225). |
| GC-2 | discharged | Every capture/log match is `grep -qF` or `grep -cF`: `[6/7]` (line 209), `✅ Install complete` and `❌` (214), `Ruleset download failed` (215), `failed: ` (238), `ruleset(s) failed to update` (239), `degraded to no-splitting mode` (240), the log path (241), `is not writable` (242), the per-base entry forms (249-250), `OK (` and `failed: ` in the recovery capture (284). The only regex in the file is the resolver-answer anchor `^0\.0\.0\.0[[:space:]]` in the I-9 proof (197) and the `https?://[^"]+` extractor of I-6 (88), both of which are anchoring/extraction, not marker matching. |
| GC-3 | discharged | E6 PASS requires `urc=0 && ok_lines=4 && defs=4 && route_refs≠0 && dns_refs≠0 && MainPID changed` (lines 320-325, the `dns_refs` clause at 324); `dns_refs` is compared `!= 0`, never `>= 0`. E6's `pair=` is `bo_defs=<n>;bo_dns_refs=<n>` — the blackout document's own reading, `dns_refs=0` on a correct run. Verified against fixture documents: degraded `defs=0;route_refs=0;dns_refs=0`, recovered `defs=4;route_refs=2;dns_refs=3`. |
| GC-4 | discharged | The settle loop (lines 259-266) breaks only when a positive read agrees with the **previous** read's `MainPID`; `prev5` starts empty, so the first positive read can never break it. `st5` therefore always holds either the agreeing second read or the tenth read, and it is printed verbatim in `obs=state=<string>;mainpid=<n>;settled_at=<n>s` (268). `MainPID` is read with `systemctl show -p MainPID` + prefix strip, not `--value` (systemd 219 on RHEL 7 has no `--value`). Since round 2 the break also sets `agree=1` (263), and a window that expired with `active` but no agreement is `BLOCKED` (273-275) — see D-6. |
| GC-5 | discharged | The covered arm prints `derived bases (4):` + the four URLs, `blackout hosts (6):` + the six names, then `SELF-CHECK OK: 4 shipped base(s), all covered`. The four printed URLs are byte-identical to `bin/sc:114-117`. The uncovered arm prints the derived list and `SELF-CHECK FAIL: uncoverable base(s): https://127.0.0.1/geo`, exit 1; an unparsable list prints `SELF-CHECK FAIL: no base parsed from <file>`, exit 1. |
| GC-6 | discharged | `mktemp -d` is at line 187, after gate 4 and after the coverage derivation; there is no redirection, no `>`/`>>` and no `cp` anywhere on the argv, refusal or self-check paths. Proved empirically, not only by reading: all four non-mutating forms were run with `cwd` and `TMPDIR` pointed at fresh empty directories, and both directories were still empty afterwards. |
| GC-7 | discharged | `SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)`; `REPO=$(cd "$SELF_DIR/../.." && pwd)` (lines 50-51). No code path invokes `git`: the only occurrences of the string are the operator guide's VM-prep example (`:17`, `:19`, both inside the `#` block) and the comment at `:48` saying why `git rev-parse` is not used. K-10's dependency list is unchanged (bash, coreutils, curl, python3, systemd, `getent`, plus `sing-box` itself for E4's check, which FR-2 already requires on the host). |
| GC-9 | discharged | D-2 records the overrun (330 vs 250) with the measured floor (267 with every optional line removed) and what the extra machinery buys; no condition, no `pair=` field and no I-15 guide element was dropped to chase the number — including in round 2, where the CR-1 and CR-5 fixes added BLOCKED arms without removing any element. Stage 5 adjudicated the overrun as earned (CR-2). |
| GC-10 | held | Nothing in this stage ran `install.sh`, `uninstall.sh` or `/usr/local/bin/sc`, and nothing wrote `/etc/hosts`, `/usr/local/bin`, `/etc/sing-box`, `/var/lib/sing-box`, `/var/log/sing-box` or any unit. The only executions of the artifact were V-3 (no argv → usage, exit 2), V-3b (bad argv → usage, exit 2), V-4 (token → refusal at K-3 gate 2, exit 3) and `--self-check` in four forms — all re-run unchanged after the round-2 edits, from a fresh empty `cwd` and `TMPDIR`, both still empty afterwards. Witnesses: `/etc/hosts` sha256 `2f3a6061…dcdf70` identical at task start, round-1 end and round-2 end; `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` identical across the same three points; `is-active` was never invoked against this host's service. Every round-2 edit is either past `:255` (E5's verdict, the BC-9 guard, E3/E4/E6's BLOCKED arms) or inside `die` (`:68`), whose four call sites are all past gate 4 — so no argv, refusal or `--self-check` path changed a byte of behaviour, as the re-runs confirm. |

GC-8 (delivery) and GC-11 (QA) are not this stage's.

## Open issues for review

- The 80-line overrun of K-10 is real and structural: the explicit-status idiom K-1 mandates
  (`rc=0; cmd >f 2>&1 || rc=$?`, `|| die` on the four must-succeed commands) costs roughly 20 lines
  that `set -e` would have hidden, the twelve `obs=`/`pair=` fields plus the four BLOCKED arms cost
  about 45, and the I-15 guide is 28. A reviewer who wants the number down has to remove a contract
  element, not a comment. Stage 5 (CR-2) adjudicated the overrun as earned and demanded no refactor;
  none was attempted, and RES-5 carries the cap's provenance to stage 7.
- E3's `nbase` counter and E6's `MainPID`-changed clause are the two assertions with no `[HOST]`
  coverage at all; both were unit-checked against synthetic logs with negative controls
  (`04_RATIONALE.md`), which is weaker than a `[VM]` run and is offered as such, not as a substitute.
- F-6 stands unrepaired by design: `--self-check`'s covered arm still validates the derivation
  against itself. GC-5's printed list + count is what makes it falsifiable by a **reader**, which is
  why stage 6 must compare the four URLs character-for-character against `bin/sc:114-117` rather
  than accept exit 0.
- CR-1 (MAJOR, the rollback cause) is fixed: one `rblock` reason computed once after the recovery
  arm (`:291-294`) now gates E3, E4 **and** E6 — `unproven;recovery_arm_not_run` when the arm never
  ran (`nok=-1`), `unproven;no_reachable_source` when it ran and reached nothing (`nok=0`, which
  covers both `nrf=4` and the `sc` that died before its first file). Both reasons were kept rather
  than collapsing to the reviewer's single token, so the operator still learns *which* of the two
  happened. Exercised on five synthetic states (`04_RATIONALE.md` §8): `nok=0` now yields three
  BLOCKED lines where round 1 printed `E3 PASS` and `E4 PASS`, and a working recovery arm
  (`nok=4`) still yields `E3/E4/E6 PASS`, so the fix took nothing away from the correct run.
- The recovery arm is skipped whole when `/usr/local/bin/sc` is not executable, and E3/E4/E6 then
  report `BLOCKED` with `pair=unproven;recovery_arm_not_run`. That is K-11-correct but means a
  failed *install* produces three BLOCKED lines whose reason names the recovery arm; a reader must
  read E1 to see why.
- **CR-5 (MINOR) — taken, but not by the named fix.** `[ "$p5" = "$prev5" ]` is a **no-op** in the
  PASS conjunction: the loop's tail `prev5="$p5"` runs on the exhausted exit, so the identity is
  true at *both* exits (demonstrated in `04_RATIONALE.md` §9). The working equivalent is an `agree`
  flag set at the break; D-6 records the resulting BLOCKED arm. A dead service still reports FAIL,
  not BLOCKED, so FR-10's product signal is unweakened. Residual, and it is the honest limit of a
  1 s sampler: a crash loop whose cycle is longer than ~2 s can still show two agreeing reads and
  read PASS. Only a `NRestarts`/`ActiveEnterTimestamp` delta would close that, and neither is in
  the contract's observation set.
- **CR-3 (MINOR) — taken.** `die` now prints `FATAL:` **and** the six condition lines
  (`unmet_all "fatal:<reason>"; finish 1`, `:68`), so I-5 holds on every path past I-3 and the
  contract's K-1/I-5 tension is resolved in favour of both. Spaces in the reason are `_`-folded to
  keep the `obs=` field grammar. Exit status is unchanged at 1.
- **CR-4 (MINOR) — ruled, no change.** Past gate 4 the degraded values are not harness blindness,
  they are the product's own failures: gate 4 already refuses without `systemctl`, `sing-box`,
  `curl` and `python3`, so after it a `sysread` yielding `unknown` means the unit is absent, `stat`
  yielding `absent` means `sc` wrote no log where BC-10's `nolog_form` says it should have, and
  `cfg_facts` yielding `?` means the generated document is unparsable. Each of those is FR-8's
  assertion genuinely failing, so FAIL is the correct verdict and BLOCKED would understate it. The
  one case FR-13 would really want is `python3` disappearing mid-run, which gate 4 forecloses.
- CR-7 through CR-12 are read and accepted as recorded. CR-8 and CR-11 are now declared as drift
  (D-7, D-8) since the substance of both findings was that the resolution went undeclared. CR-9,
  CR-10 and CR-12 change nothing verdict-bearing and are left as stage-6/stage-7 reading; CR-7's
  gap is upstream (FR-7/V-15) and is not this stage's to close.
- `install.sh`'s remote-artifact branch stays unexercised (Q-4), and BC-10's alternate-log arm
  (`nolog_form≥1` ⇒ E3 FAIL) has no way to be triggered without making `/var/log` unwritable, which
  the artifact deliberately never does.

## Dev-map updates

- Added to `## Reusable utilities`: `Which curl flags the installer uses | CURL_OPTS_QUIET /
  CURL_OPTS_PROGRESS | install.sh # download flag policy | …` — names the two arrays, the
  non-additivity of `-s` and `--progress-bar`, the retention of `-S` in both, the `[ -t 2 ]`
  stderr-terminal-ness selector and its `0x0D`-in-a-captured-log consequence, the curl 7.29 floor,
  and the closing rule "a new transfer uses one of the two arrays, never inline flags".
- Added to `## Reusable utilities`: `"Does a restricted-network install still end in a working
  degraded state?" | restricted-network-regression.sh [--self-check] | .harness/scripts/ | …` — what
  E1…E6 assert (E5's clause now reads "active **and settled** — two agreeing `MainPID` reads, or
  `BLOCKED`", per D-6), the `pair=`/`BLOCKED` discipline, the textual (never imported) derivation from
  `RULESET_BASES`, where it may run (root on a disposable single-use systemd VM with `/dev/net/tun`;
  it refuses with exit 3 on a host carrying `nodes.json`; `--self-check` is the only developer-machine
  form), and that it is deliberately not wired into `verify_all` and has no `.ps1` mirror.
- No other line of `docs/dev-map.md` changed; in particular the "no test directory" sentence stays
  true, because the artifact added no directory.

## Insight to surface

- `RULESET_BASES`' fourth entry is a byte-**suffix** of its third (`https://ghfast.top/` + base 4), so any substring test for "this log line names base 4" also matches a line that only ever named base 3 — an assertion over `sc`'s `failed:` output must match the entry boundary (`failed: <base> -> ` / `; <base> -> `), and the substring form silently reports 4-of-4 coverage on a log carrying 3 · evidence: bin/sc:116-117

## Verdict

`READY FOR REVIEW`
