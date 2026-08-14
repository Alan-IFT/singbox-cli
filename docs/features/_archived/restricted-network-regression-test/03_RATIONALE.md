> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

Task T-07 · slug `restricted-network-regression-test` · mode **full** · round 1 · date 2026-08-14.
`.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37, now a fifth
occurrence — 01 called it the third, 02 the fourth), so the gate contract's schema is applied as
written and everything it admits no section for is routed here.

## 1. The headline refutation, re-derived rather than accepted

Stage 1's single load-bearing claim is that T-01's AC-9 is inverted at HEAD. I re-walked it in the
code without reference to stage 1's chain, and it holds in every link:

1. `install.sh:566-574` — `t step6` prints `▶ [6/7] Downloading rulesets (.srs) ...` **before**
   `/usr/local/bin/sc update-rules` runs, and the `if` guard leaves `PHASE_RULESETS` at its
   pessimistic `failed` default (`:27`) when the command exits non-zero. The `elif` arm fires
   because the log probe at `:561-563` succeeded, so the screen line is `step6_warn`, which names
   `$INSTALL_LOG` verbatim.
2. `bin/sc:3237-3329` — with all four bases sunk, every file exhausts the base list and takes the
   `for … else` arm at `:3281-3284`, printing one `failed: <base> -> <cause>; …` line per rule-set
   on **stdout**; `:3327` writes `4 ruleset(s) failed to update` to stderr; `:3329` exits 1.
   `install.sh:567` redirects both streams into the log, so all of E3's log-side markers land.
3. `install.sh:590` — `sc reload` → `cmd_reload` (`bin/sc:3433-3437`) → `reload_or_restart`
   (`:2098-2102`) → `generate_config` (`:1992-2081`). With no `.srs` present, `ruleset_report()`
   yields four unusable entries, the overlay's `route.rule_set` is empty, `:2058-2059` computes an
   empty `defined` set, `:2060-2061` **deletes** the empty array, and `:2062-2063` runs
   `_filter_rules` over `dns.rules` **and** `route.rules` — every rule whose only matcher was a
   `rule_set` reference is dropped (`:1029`), so no dangling reference can survive in either array.
   `_warn_degraded` (`:1033-1049`) emits `4/4 rule-sets unusable (…) — degraded to no-splitting
   mode: …`. `sing-box check` then passes and the function returns True.
4. `reload_or_restart` calls `restart_service()` itself, so the service is already up when
   `install.sh:593` runs `systemctl start`; that returns 0 and `PHASE_SERVICE=started`.
5. `install_report` (`:257-302`) takes the success arm at `:260`, prints `  ✅ Install complete`
   and returns 0; `:614-615` exits 0.

So E1 (success banner, exit 0) is the correct assertion and AC-9's second and third clauses would
have failed the test on correct code. Stage 1's Q-2 is right, and its consequences for E4 (`defs=0`,
`route_refs=0`, `dns_refs=0`) follow from `:2060-2063` rather than from a claim about T-02.

Stage 1's Q-3 also checks out: `bin/sc:113-118` ships four bases, `:3258-3271` breaks on the first
that validates, and `.harness/insight-index.md`'s final line records the measurement that
`cdn.jsdelivr.net` and `testingcf.jsdelivr.net` share one Cloudflare edge — three failure domains,
not two hosts. Q-4 likewise: `install.sh:5` fetches the script from `raw.githubusercontent.com`,
the remote-artifact loop at `:412-425` exits 1 on the first failure, and `RAW_BASE` at `:13` is a
plain assignment with no `${…:-}` override.

I queried the insight index for the design's load-bearing terms (rule-set sources, jsDelivr, stderr
buffering, `LANG`, `is_running`, E.6 heading). **No entry contradicts the design.** Three support it
(the three-failure-domain line behind FR-3; the 3.6 block-buffered-stderr line behind K-5; the
`main()`-reassigns-`LANG` line, which K-6 neutralises because `install.sh` persists `lang` before
step 6 and `_load_lang()` never reads `$LANG`).

## 2. Rule 85 — testing the architect's answer, not recording it

`02_RATIONALE.md`'s `## Smaller alternative rejected` names four smaller candidates. I tested each
against the code rather than against the argument:

- **#1, `SB_RULES_BASE` instead of `/etc/hosts`.** The argument is **correct and load-bearing**.
  `_ruleset_bases` (`bin/sc:1052-1061`) ends `return override or list(RULESET_BASES)` — the override
  **replaces** the shipped list, so under it the four shipped URLs appear nowhere in the log and E3
  as written cannot pass; rewriting E3 to accept the injected URL is precisely the "test agrees with
  itself and with nothing else" shape. It also cannot cover the three GitHub names. This is the
  T-19 precedent inverted: there the gate found the stated reason partly mis-argued; here the stated
  reason is exactly right and I could not weaken it.
- **#2, no `pair=` field.** Genuinely cheap as claimed — E2/E5's pairs are readings the precondition
  gate must take anyway, and E3/E4/E6's are the two arms the run already performs. The one place the
  claim over-reaches is E1 (F-1): "one extra `grep -c`" buys a restatement, not a control.
- **#3, guide in the file header.** Accepted; the drift argument (guide five lines above the `case`
  that parses the token) is the real one and the safety argument about `docs/faq.md` is sound.
- **#4, six fixed lines.** Accepted; FR-13/AC-20 are stated in those terms and the count check is
  what stops a silently skipped condition reading as success.

**What I could not find is an element that fails to earn its place**, with one qualification: E5 as
specified (F-5) is nearly implied by E1, and only earns its line once its observation is taken at
the end of the settle window. Everything else is either a requirement's only possible discharge or
a two-line reuse of a value already read. The design adds no framework, no fixture, no server, no
runner, no second file and no directory, and I confirmed the two ledger rows with no requirement
behind them (C-3, C-4) are one appended record and one appended glossary entry — the smallest
possible form of the project's own decision-recording conventions.

The 250-line cap (F-11) is the one place the design's own numbers do not close. My element-by-element
estimate lands at 240-265 lines with terse bash; K-10's "target ≤235" is not credible. GC-9 chooses
the honest response — record the overrun under the NFR's own rule-85 clause — over the dishonest one,
which is dropping a `pair=` field or the Chinese guide to make the number.

## 3. The vacuous-green interrogation, condition by condition

The question I asked of each condition: *is the stated `pair=` a state in which the assertion does
not hold, or a restatement that a broken artifact would also satisfy?*

- **E1 — restatement.** `install_report` prints exactly one of two banners, so "failure banner count
  = 0" in a passing run is a value under which the assertion **holds**. Worse, E1's assertion is
  satisfied identically by a completely unrestricted, healthy install: `✅ Install complete` and
  exit 0 are what a good install prints. The discriminating observation available for free in the
  same capture is the step-6 warning — proof that the success arm was reached *with*
  `PHASE_RULESETS=failed`. Hence GC-1.
- **E2, E5 — genuine.** The pre-install readings are real counter-observations: before the install
  the unit files do not exist, so `is-enabled` fails and `is-active` reads `inactive`. The assertion
  demonstrably distinguishes two states inside one run. E5's weakness is elsewhere (F-5).
- **E3, E4, E6 — genuine and mutually constraining.** These are the cross-arm pairs and they are the
  only reason the run cannot read all-PASS on a meaningless build: if the blackout never took
  effect, `sc update-rules` succeeds, the log carries no `failed:` line and the config carries
  `defs=4` — E3 and E4 **fail**, and I-4 makes the run non-zero. E3 (the log) and E4 (the emitted
  document) are separate observations of one cause, so a broken log path breaks one and not the
  other.
- **Do any two agree rather than constrain?** Only E1 and E5, through `PHASE_SERVICE=started`
  (`install.sh:593-595`) — E1's success arm already requires `systemctl start` to have returned 0,
  so an E5 that breaks out of its loop on the first `active` adds nothing. With
  `sing-box.service:11` `Restart=on-failure`, a crash-loop can read `active` at the sampling
  instant. GC-4 makes E5 constrain rather than agree, at zero extra cost.
- **Can the whole run read PASS on a run where nothing happened?** No, and I tried four routes:
  installer aborts before step 6 → K-12 makes all six UNMET and I-4 makes the run non-zero;
  rule-sets already present → BC-1/gate 4 UNMET before any installer byte; host already configured
  → K-3 gate 2 refuses (and I confirmed `sc reload` creates `/etc/sing-box/nodes.json` via
  `_init_files()`'s nodes branch, so a used host always trips it); blackout silently ineffective →
  I-9 fails, or E3/E4 fail. The design is fail-closed at run level. It is E1 **individually** that
  can print PASS on an unrestricted run, and that is what GC-1 closes.

**Is AC-5's uncovered-entry proof a real guard or a tautology?** Half real. The coverage predicate
is computed from the same parse it validates, so for a name-based host coverage is true by
construction; the **only** branch that can fail is the uncoverable class (empty host, IP literal,
`localhost`), and V-5's `https://127.0.0.1/geo` scratch entry exercises exactly that branch. So the
negative arm is honest. The **positive** arm is not a guard at all: a derivation that under-matches
and returns three of four bases still reports "all covered, exit 0" (F-6). At run time that is
caught — the un-derived base stays reachable, the download succeeds and E3/E4 fail loudly — but the
run-time arm is `[VM]` and will be BLOCKED here (RS-5), so the only executable evidence this
pipeline produces would be self-consistent. GC-5 turns V-5's "four bases listed" from an eyeball
into an explicit list-and-count comparison against `bin/sc:113-118`.

## 4. Mechanism feasibility — what I read

- **I-6's derivation.** Verified against the literal block. `sed -n '/^RULESET_BASES = (/,/^)/p'`
  opens at `:113` and closes at `:118`; the preceding comment at `:112` is outside the range;
  `grep -oE 'https?://[^"]+'` yields one match per line because the character class stops at the
  closing quote and the trailing `,` cannot restart a match. No over-match, no under-match, exactly
  four lines. Base 3's embedded second `https://` is consumed by the same single match, so field 3
  of a `/`-split is `ghfast.top` — the host the client actually connects to — and
  `raw.githubusercontent.com` is in FR-3's fixed union anyway.
- **I-8/I-9's injection.** `bin/sc` fetches through `urllib.request.urlopen` (`:1121`) and
  `install.sh` through `curl`; both resolve through glibc's NSS, whose `files` source is
  `/etc/hosts` and is first in every stock `nsswitch.conf`, including the `resolve` variant.
  `getent hosts` consults the same stack, so I-9 observes the resolution the fetchers get rather
  than a proxy for it. The `0.0.0.0`/connect-vs-resolve distinction is real but harmless here
  (see A-6). One residual worth naming and not blocking: Linux maps a connect to `0.0.0.0` onto
  loopback, so a local listener on 443 would change the failure text — implausible on a clean VM,
  and E3 asserts no cause text.
- **K-9's `SB_RULES_BASE` gate.** `bin/sc:1052-1061` cited exactly; `return override or
  list(RULESET_BASES)` is a replacement, not an addition, so an inherited value really would make
  the derived blackout irrelevant. The gate is necessary.
- **I-10's `cfg_facts`.** The shape it reads matches what `generate_config()` emits in both states:
  `route.rule_set` is deleted when empty (`:2060-2061`), so `defs` must treat absence as 0 — which
  I-10 says; `route.rules` carries four `rule_set`-bearing entries (`:1274,1276,1279,1280`) and
  `dns.rules` three (`:1249,1250,1253`) in the recovered state, and zero of each in the degraded one
  because `_filter_rules` drops a rule whose only matcher was the reference. This is where F-2 comes
  from: `dns_refs≥0` cannot distinguish 3 from 0.
- **E3's markers.** Every string V-14 matches exists verbatim in the shipped **English** table:
  `install.sh:216` `  ⚠️ Ruleset download failed — see %s for the cause; …`; `:236` and `:235` both
  carry `is not writable` for BC-10's alternate form; `bin/sc`'s `"failed: {e}"` (`:213` key) and
  `"{n} ruleset(s) failed to update"` (`:147` key) render as their English keys because
  `TRANSLATIONS` has no `en` table; the degradation warning's key (`:215`) contains both
  `rule-sets unusable` and `degraded to no-splitting mode`. The `0640` mode comes from the
  `( umask 027; … >>"$INSTALL_LOG" )` probe at `:561-563` and reads as `640` under `stat -c %a`.
  The language selection is safe (A-3). The only marker defect is syntactic, not semantic: `[6/7]`
  as a pattern (F-3).

## 5. Safety — the strictest item in the batch

I checked K-3's gate order against the design as written and against this host:

- Gate 1 (token) precedes everything; I-3's usage path prints no condition line and exits 2, so a
  bare invocation cannot even claim a status.
- Gate 2 (node store, `-e` **or** `-L`) precedes gate 3 (root), which is what makes AC-4
  dischargeable here. I confirmed **first-hand that `/etc/sing-box/nodes.json` exists on this
  host**, so V-4's refusal is a real observation and not a hypothetical. `/etc/sing-box` is created
  by `install.sh:486`'s `mkdir -p` at the default umask, so an unprivileged `[ -e ]` can traverse it
  — the gate sees the node store without needing root. And in the case where it could not (a
  hardened directory), the run falls through to gate 3 and refuses for lack of root, so the ordering
  is safe in both directions.
- The one gap is that no constraint pins **when `$WORK` is created** (F-7). It is the only way a
  refusal path could write anything, and it costs one line to place. GC-6.
- `--self-check` needs no temporary file at all: `derive_bases` is a pipeline to stdout and the
  coverage predicate is pure. Its "mutates nothing" claim is achievable exactly.
- **No design element imports `bin/sc`.** I-6 is textual and says so; I-10's `python3 - "$CFG"`
  heredoc reads `config.json` with the `json` module and never touches `bin/sc`. The auto-elevate at
  `bin/sc:124-125` (`os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] …)`) is real and would re-exec
  the **installed** `sc` against the live service, which is why the prohibition is load-bearing
  rather than stylistic.
- Nothing in the design's `[HOST]` verification steps (V-1 … V-11) runs `install.sh`, writes
  `/usr/local/bin`, `/etc/sing-box`, `/var/lib/sing-box`, a unit, `/etc/hosts`, a firewall or DNS.
  V-8's clone lands under `test/`, which `.gitignore:19` ignores; I checked that no `verify_all`
  step's `find` root reaches it (`E.6`/`F.6` are rooted at `docs/features`, `F.2`/`F.3`/`E.5` at
  `.harness/…` with `-maxdepth 1`, `A.1`/`A.2` at the outer repo's tracked files), so the clone
  cannot move a count. GC-10 and GC-11 make both properties obligations rather than expectations.

## 6. The two `verify_all` caps — what F.4 actually counts

The PM asked what F.4 counts, because delivery harvests into that file. `verify_all.sh:214-219`:

    n=$(wc -l < .harness/insight-index.md); if (( n > 30 )) … WARN

It counts `wc -l` over the **whole file** — the five header lines and the two comment lines
included — not insight bullets. The file's `wc -l` is **30** today (an editor shows 31 lines because
the 31st is the empty tail after the final newline), which is why it PASSes while looking over cap.
`archive-task.sh:85-95` counts something different: `grep -E '^[[:space:]]*-[[:space:]]'`, i.e.
**bullets**, and rotates only when bullets would exceed 30 — which is 38 whole-file lines. So the
rotation mechanism cannot protect F.4, and a single harvested insight at T-07's archive step turns
`WARN 0` into `WARN 1`, failing AC-2 and the project's declare-done gate (`AI-GUIDE.md:87`).

`docs/tasks.md` is in the same position at F.5's 300-line cap — 300 lines today, and
`docs/tasks-archive.md:194-199` records that T-11's R-1…R-8 block was rotated out at T-06 delivery
for exactly this reason. GC-8 is therefore about ordering and rotation, not about forbidding the
harvest.

`CONTEXT.md` and `.harness/rejected-decisions.md` are under no cap, and `A.1`'s secret scan excludes
both `*.md` and `.harness/*`, so C-3 and C-4 are count-neutral. The design's R-G is accurate on
every claim I checked.

## 7. Verified good, recorded so a later reader need not re-derive it

- The change ledger's stage-4 filename is the canonical `04_DEVELOPMENT.md` (C-5). Correct.
- Every FR, BC and AC maps to a design element; I walked `02_RATIONALE.md`'s coverage table row by
  row against `01_REQUIREMENT_ANALYSIS.md` and found no orphan requirement. The only design elements
  with no requirement behind them are C-3 and C-4 (F-9), and no verification step reads them — the
  reason that is a finding rather than a condition is that removing them would be a larger change
  than leaving them.
- `.gitignore` has exactly one directory pattern (`test/`, `:19`) and one extension pattern (`*.log`,
  `:18`), so `.harness/scripts/restricted-network-regression.sh` is unignorable by construction and
  AC-1 needs no `.gitignore` edit — the frozen set is right to forbid one.
- `check-i18n-parity.sh` is the only `.harness/scripts/*.sh` with no `.ps1` twin, confirming the
  reuse audit's "same directory, same no-mirror convention" precedent.
- `docs/dev-map.md:22`'s "no build step, no dependency manifest and no test directory" sentence
  stays literally true under C-1, as the design claims: no directory is added.
- BC-3's log-side half is exact in a way worth preserving: `cmd_update_rules` appends
  `base + " -> " + str(e)` (`bin/sc:3274`), where `base` is the **base URL**, not the per-file URL —
  so I-6's derived strings and E3's asserted strings are the same bytes. Any future change that made
  E3 assert the full per-file URL would silently break that identity.
- I-5's `pair=` for E3, E4 and E6 comes from the recovery arm, which runs after the blackout arm, so
  the six-line report is necessarily printed at the end of the run. That is consistent with I-5 and
  with BC-9's "E6 BLOCKED ⇒ E3/E4's pairs unproven ⇒ BLOCKED" chain, and it is why K-11's
  "unproven ⇒ BLOCKED, never a fifth status" is the right shape.

## 8. What I did not do

I executed nothing. Every finding above rests on reading `install.sh`, `bin/sc`,
`systemd/sing-box.service`, `systemd/sing-box-rules-update.timer`, `.harness/scripts/verify_all.sh`,
`.harness/scripts/archive-task.sh`, `.gitignore`, `.harness/insight-index.md`, `docs/dev-map.md` and
`docs/tasks-archive.md` at HEAD, plus a directory listing of `/etc/sing-box` (names only — no
credential document was opened, and the live service was not probed). Q-15/RS-5's outcome — the
artifact ships without ever running end to end here — is the designed-for result and is not a
blocking condition; `BLOCKED: NEEDS-HUMAN` was considered only for the host-mutation question in §5
and correctly declined, because K-3's gate order plus GC-6 and GC-10 close it without a human
decision.
