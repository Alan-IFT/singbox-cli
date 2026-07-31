# PM Log — fix-rules-update-execstart

Task: T-09 · mode: `full` · started 2026-07-31
Goal: `systemd/sing-box-rules-update.service:7` invokes `/usr/local/bin/proxy`, which is never
installed, so the weekly ruleset timer has always failed `203/EXEC`. Point it at `/usr/local/bin/sc`.

Deferred-human mode: **defer, do not ask** — escalate as `BLOCKED: NEEDS-HUMAN` verdict.

## Pre-flight

- `.harness/intervention.md` — absent, nothing to consume.
- `.harness/agents/dev-*.md` — none found → **single Developer mode** (`harness-kit:developer`).
- `.harness/insight-index.md` — 8 entries read. Relevant to this task:
  - the `/usr/local/bin/proxy` entry (this defect, already recorded by T-02)
  - the **auto-elevate hazard**: `bin/sc` re-execs the *installed* `/usr/local/bin/sc` at import
    time under sudo — surfaced to QA as a hard do-not-touch-live-system constraint.
- `docs/tasks.md` — related history: T-01 (`install-enable-start-split`, commit 493eb6a, made
  `systemctl enable …timer` unconditional) and T-02 (`config-degrade-missing-rulesets`, ab4e4a4,
  owns `bin/sc` ruleset logic). Both DELIVERED. Both are declared out of scope by the owner.
- `docs/dev-map.md` — read; `systemd/` holds the three unit files, no build step, no test dir.

## Stage transitions

| # | Stage | Agent | Verdict | Note |
|---|---|---|---|---|
| 1 | requirement | requirement-analyst | **READY** | 10 behaviors, 13 boundary conditions, 14 AC, 9 open questions (all with recommended answers + proceeding assumptions) |
| 2 | design | solution-architect | **READY** | Q1 escalation did NOT fire; 9 static checks V-1..V-9; `CHANGELOG.md` kept in diff |
| 3 | gate | gate-reviewer | **APPROVED WITH CONDITIONS** | C-1..C-5 binding; no rollback |
| 4 | development | harness-kit:developer | **READY FOR REVIEW** | `verify_all` PASS 16 / WARN 0 / FAIL 0 / SKIP 2, delta 0 |
| 5 | code review | harness-kit:code-reviewer | **PASS WITH COMMENTS** | 0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT |
| 6 | QA | harness-kit:qa-tester | **PASS** | 0 BLOCKER/CRITICAL/MAJOR, 3 MINOR (upstream doc accuracy), 3 INFO |
| 7 | delivery | (PM) | **DELIVERED** | `07_DELIVERY.md` written; 0 rollbacks across the run |

### Stage 6 → 7 decision (deliver)

Delivery gate satisfied: stages 5 and 6 both PASS. Nothing was routed back to the developer — QA
found nothing wrong in the shipped diff.

QA did the job I most wanted done: it was the first independent party with a shell, and it
**rebuilt a pristine `HEAD` tree itself** in a scratch copy rather than trusting the developer's
`verify_all` numbers. Delta 0 confirmed independently. It also ran five mutation controls against
`systemd-analyze verify` to prove the tool was not passing vacuously — establishing that it catches a
typo'd path and a bad `ExecReload`, but lets a bare PATH lookup, CRLF and `/usr/bin/env` through. That
correctly narrows what AC-13 is allowed to claim.

**Three findings where the real host contradicted premises everyone upstream had accepted** — the
value of giving QA a shell:

- **D-2.** The "~100% of existing systemd hosts sit in `failed`" premise — asserted by the owner's
  brief, by stage 1 and by my own stage-6 dispatch — is **false on this host**. The unit is
  `inactive (dead)`, `Result=success`, `systemctl --failed` lists 0 units, and the journal has
  **no entries at all**. The unit has never run; the timer is `disabled`.
- **D-1.** Consequently `LastTriggerUSec` is empty, `list-timers` reports 0 timers, and no stamp file
  exists — so the BC-11 stamp argument, which stages 2 and 3 both re-derived and which underpins a
  user-facing sentence, has **zero empirical support anywhere in this project**. It remains correct
  reasoning; it is now labelled as reasoning in `07_DELIVERY.md` rather than implied to be observed.
- **D-3.** There is therefore a real host state where the `ExecStart` fix **alone** does nothing,
  forever. The repair works only because the same installer run also enables and starts the timer
  (`install.sh:472`/`:486`, unconditional since T-01). Nobody upstream had noticed the enable step was
  load-bearing. `07_DELIVERY.md` §2 now says so explicitly, with the warning not to hand-edit the unit.

QA self-disclosed that its first draft was 515 lines and did trip `verify_all` F.6 to WARN — exactly
the trap gate condition C-4 predicted — and compacted the document rather than touching the gate.

**C-5 discharged by me at stage 7 as committed at stage 5**: `07_DELIVERY.md` §3 carries both the
`sc update-interval`-to-shorter-cadence third catch-up path and F-8's "within minutes of the push"
phrasing, and states the no-catch-up claim conditionally throughout. C-1, C-2, R-1 and F-4 are all
carried into §5 with follow-up dispositions.

### Delivery-boundary scripts

I have no Bash tool, so `.harness/scripts/entropy-cadence` and `.harness/scripts/archive-task` were
run via a delegated Bash-capable agent rather than directly. Outcome recorded below.

**Entropy cadence: not run — resolved to NOT-DUE (fail-open).** `.harness/scripts/entropy-cadence`
does not exist in this project (the scripts directory carries `archive-task`, `verify_all`,
`guard-rm`, `harness-sync` and friends, but no cadence pair). Per the cadence contract, any cadence
I/O problem resolves to not-due, so: no supervisor entropy scan was dispatched, no
`## Entropy watch` section was added to `07_DELIVERY.md`, and the delivery verdict is unaffected.

**`archive-task.sh --task fix-rules-update-execstart`: exit 0.** Stage docs moved to
`docs/features/_archived/fix-rules-update-execstart/`; 4 insights harvested into
`.harness/insight-index.md`.

**Defect found in the harvest, reported not fixed.** `archive-task.sh` harvested only the **first
physical line** of each `## Insight` bullet, so all four new entries lost their continuation text
*and* their trailing `· evidence: fix-rules-update-execstart` tag. Example — the index now reads
`- 2026-07-31 · \`systemd-analyze verify\` only catches an unresolvable absolute \`ExecStart\`; a bare PATH`
and stops mid-sentence. This is **pre-existing, not caused by this task**: index entries 10-13 from
T-01/T-02 are truncated identically, while T-02's single-line entries (14-17) survived intact. So the
harvest is line-based rather than bullet-based, and any insight wrapped across lines is silently
mutilated — which also means the contract's required `· evidence:` suffix is dropped precisely for
the longer insights. Out of scope here (`.harness/scripts/` is not this task's diff boundary, and the
owner said do not commit), so it is surfaced to the owner as a follow-up row.

### Stage 5 → 6 decision (advance, no rollback)

Transcribed verbatim again — the code reviewer's tool set is also read-only. Authorship is the
reviewer's; keystrokes mine.

Both referred judgments came back decided, and neither produced a rollback:

1. **AC-3 collision — compliant, not a defect in the work.** The reviewer's evidence is decisive and
   not something I would have found: `01_REQUIREMENT_ANALYSIS.md` itself contains the literal
   `/usr/local/bin/proxy` **five times, including inside AC-3's own table cell**, as do
   `.harness/insight-index.md:12`, `BATCH_PLAN.md` and eleven archived-doc lines. AC-3's "anywhere in
   the repository" was therefore already false on a clean tree, before anyone touched anything — it
   is unsatisfiable as literally written, so the changelog prose cannot be what breaks it. The
   operative reading is AC-3's own verification column ("enumerate every hit with its disposition"),
   which the developer satisfied. Filed MINOR against the requirement-analyst, report-only.
2. **C-5 applied to the changelog — precision, not scope drift.** Design R-5 (`02:410`) already
   requires the conditional claim without scoping it to a filename, and §10 explicitly delegates
   prose to the developer. All four required facts verified present and accurate word by word.

**Rollback considered and declined** for the one MINOR that has a live owner: `04_DEVELOPMENT.md:401`
claims C-5 discharged while two of its clauses are still stage-7 obligations, and gate F-8 ("remote
installs pick the fix up within minutes of the push, not instantaneously") has no anchor in `04` at
all. The reviewer offered two remedies — a one-line developer edit, or the PM restating C-5 in the
stage-7 dispatch. I am taking the second. Sending a task back through a full development stage to
correct a bookkeeping sentence in a stage document, when the obligation it tracks is one I discharge
myself at stage 7, would burn a stage to buy nothing. **Recording it here so it cannot evaporate:
C-5 is NOT discharged; `07_DELIVERY.md` owes (a) the `sc update-interval`-to-shorter-cadence third
catch-up path and (b) F-8's "within minutes of the push" phrasing.** Both are restated in full in the
stage-6 and stage-7 briefs.

Reviewer's disclosed limitation, which I am converting into QA's primary job: its read-only tool set
could not reproduce `git diff`, `verify_all` or `systemd-analyze`, so V-3/V-5/V-6/V-7 remain
developer-reported. It corroborated them indirectly (every out-of-scope anchor still at its recorded
line with its recorded content) and found nothing contradicting them, but AC-11/12/13 are genuinely
unverified by an independent party until QA re-executes them.

### Stage 4 → 5 decision (advance)

Stage gate satisfied: `verify_all` PASSED (16/0/0, SKIP 2, exit 0), delta 0 against the pre-change
baseline taken with all stage documents present. Diff is exactly what was approved — unit file
1 insertion / 1 deletion, one `CHANGELOG.md` bullet at line 15, plus stage docs. Every out-of-scope
file asserted byte-unchanged via `git diff --quiet` rather than by inspection.

V-6 produced a clean discriminator on a real systemd 255 host: pre-change `systemd-analyze verify`
reports `Command /usr/local/bin/proxy is not executable: No such file or directory` and exits 1;
post-change it emits nothing and exits 0. That is the closest thing to end-to-end evidence available
without touching the live system, and it is a genuine executed result rather than a reasoned one.

Safety held: no execution or import of `bin/sc`, no `systemctl` write, no root, no live mutation. The
dev host's `failed` unit was deliberately left alone.

One item I am routing to the reviewer rather than ruling on myself: **the changelog bullet now
contains the literal `/usr/local/bin/proxy` as prose** (design §10 fact (1) requires naming the wrong
path). AC-3 as written says no occurrence remains outside the uninstaller's legacy-cleanup lines, so
the letter of the criterion and the letter of the design instruction now point in opposite
directions. The developer disclosed this unprompted instead of quietly choosing one — exactly the
right behavior. Whether prose-in-a-changelog counts as an "occurrence" under AC-3 is a
professional judgment, so it goes to stage 5.

Also flagged for the reviewer: the developer applied C-5's conditional phrasing to the changelog
bullet as well, reasoning it makes the same user-facing claim. Plausible, but it is the developer
extending a gate condition beyond its stated target — the reviewer should confirm it is precision
rather than drift. `docs/tasks.md` shows as modified at baseline; that is my board row, not the
developer's change.

### Stage 1 → 2 decision (advance)

Defect independently re-confirmed by the analyst from source; **four** independent sources agree on
`/usr/local/bin/sc` (installer step 3 `install.sh:376`, sudoers `install.sh:437-441`, auto-elevate
`bin/sc:77-78`, and the installer's own `sc update-rules` call `install.sh:456,479`).

Three things the analyst surfaced that I am carrying forward rather than letting them evaporate:

1. **Q1 is a conditional scope escalation.** If a manager `daemon-reload` is NOT sufficient for the
   corrected `[Service]` and the timer must be restarted, the repair cannot live inside the owner's
   diff boundary (that would require editing `install.sh`, explicitly out of scope). Architect
   instructed to answer Q1 explicitly and to escalate to me rather than edit the installer.
2. **The fix activates a weekly sing-box restart.** `bin/sc:1141-1143` — `if not applied and
   is_running(): restart_service()` — so a steady-state run with nothing to update still bounces
   the proxy. Never experienced by anyone, because the timer has never fired. Out of scope
   (`bin/sc` is T-02's), but must reach `07_DELIVERY.md` and a follow-up row.
3. **Owner brief anchor was stale.** `bin/sc:898` is now `_unique_tag`; the OpenRC periodic script
   lives at `bin/sc:1210-1218` and does correctly write `/usr/local/bin/sc update-rules`. The
   owner's do-not-touch instruction stands, now pointing at the right lines.

Sweep result (AC-3): exactly three literal `/usr/local/bin/proxy` hits — the defect, plus
`uninstall.sh:133-134`'s *deliberate* legacy cleanup (`rm -f … /usr/local/bin/proxy`), which is
correct and stays. Uninstaller residue found: no `systemctl reset-failed`, so a failed unit can
linger in `systemctl --failed` after uninstall → report-scope per the owner's brief.

Note: the analyst put `CHANGELOG.md` inside the diff boundary (B-9/B-10). The owner's brief forbade
four specific files and `CHANGELOG.md` was not among them; whether this respects rule 85's
minimal-shape instruction is a scope judgment I am routing to the gate reviewer, not deciding.

### Stage 2 → 3 decision (advance)

**Q1 resolved as (a) — `daemon-reload` alone is sufficient. The scope escalation did not fire and
`install.sh` stays out of the diff.** Architect's mechanism: what changed is the `[Service]`
fragment, not the `[Timer]`, so restarting the timer would re-arm the wrong unit; `daemon-reload`
(already unconditional at `install.sh:409`) re-reads the fragment, and a `Type=oneshot` unit has no
process and no queued job between triggers, so the next activation is a fresh start against the
reloaded fragment. Precedent cuts both ways and agrees: `bin/sc:1167-1179` restarts the timer only
after an `OnCalendar=` change; `install.sh:405-409` rewrites all three units and restarts nothing —
and the project has shipped `sing-box.service` changes that way for its whole history, which is the
harder case. Also confirmed: `failed` state does not block the next activation, and a weekly cadence
cannot reach `DefaultStartLimitBurst=5`.

**BC-11 confirmed with two stated exceptions.** The stamp
`/var/lib/systemd/timers/stamp-sing-box-rules-update.timer` is written when the timer *elapses and
enqueues the job*, not when the service succeeds — `203/EXEC` happens in the forked child, after
activation began — so every weekly elapse advanced the stamp exactly as on a healthy host. Hence no
`Persistent=true` catch-up burst after the fix. Exceptions that must reach the delivery text: a host
whose timer was stopped/disabled with a stale stamp *does* catch up moments after `install.sh:486`
starts it, and a host powered off across a boundary catches up at next boot.

**CHANGELOG decision: in the diff, zh-only.** Architect's reasoning: B-9/B-10 are binding upstream
(narrowing them silently would be a rollback, not a design choice); the owner's four do-not-touch
files are exactly those with competing task owners, which `CHANGELOG.md` has none of; every landed
fix in this pool wrote a `修复` bullet. I did not make this call — routing it to the gate as planned.

**R-1 carried forward** (weekly sing-box restart, `bin/sc:1141-1143`) — report-only, needs a
follow-up pool row at delivery. **Verification hazard is live**: `/usr/local/bin/sc` and
`/usr/local/bin/sing-box` are installed on this host, so the auto-elevate incident risk is real, not
theoretical. All 9 designed checks are read-only.

### Stage 3 → 4 decision (advance, conditions binding)

The gate reviewer's tool set is read-only (Read/Glob/Grep), so it returned the document body instead
of writing it. I transcribed it verbatim to `03_GATE_REVIEW.md` and added nothing. Recording that
here because a PM writing into a stage document is normally a red line — the authorship is the gate
reviewer's, the keystrokes were mine.

Verdict **APPROVED WITH CONDITIONS**. Both load-bearing claims survived independent re-derivation on
the *mechanism* rather than on upstream's citations: Q1 (reload sufficiency) and BC-11 (stamp
advances on elapse, not on service success). Six WARNs, five conditions C-1..C-5, all dischargeable
downstream inside the existing diff boundary — the gate states explicitly that none requires an
upstream document to change, so **no rollback**. Scope ruling: `CHANGELOG.md` stays in the diff,
architect upheld; no creep found in either direction.

Two gate findings I am tracking as PM because they can otherwise evaporate:

- **F-1 (new, nobody had examined it).** The timer path will run `sc update-rules` in a *systemd
  service environment* for the first time in project history. `bin/sc:1089` unconditionally prints a
  non-ASCII `↓` before any download; a system unit inherits no login-shell locale, so on a Python
  **3.6** host (the documented floor) with no locale in the manager environment, that first `print`
  raises `UnicodeEncodeError`. WARN not FAIL — it fails loudly before writing anything, and is still
  strictly more informative than today's `203/EXEC`. Every available remedy lies outside the owner's
  boundary (it would need a `unit` directive B-2 forbids, or a `bin/sc` edit T-02 owns), so it is
  report-only under C-1 and the routing call is the owner's, not mine.
- **F-2.** The uninstaller `reset-failed` residue was mis-cited upstream as carried by B-7/AC-3,
  which are scoped to `/usr/local/bin/proxy` only. No AC bound it → it could have vanished silently.
  C-2 binds it to `07_DELIVERY.md`.

**F-4** is a genuine wrong fact in a READY upstream document (E-17 claims all `B.*` checks are SKIP;
`verify_all.sh:52-68` runs a real B.1 syntax gate). The gate judged it non-blocking with no
consequence for this fix. I am **not** rolling back to the analyst for it: the erroneous claim
changes no behavior, no AC and no verification step here, and a rollback would cost a full stage to
correct a parenthetical. Logged instead as a docs-accuracy follow-up, with the note that its root
cause is a stale line in `.harness/rules/50-singbox-cli.md:34-36` — i.e. the wrong fact will keep
being inherited by future tasks until the rule file is corrected. That makes it worth a pool row.
