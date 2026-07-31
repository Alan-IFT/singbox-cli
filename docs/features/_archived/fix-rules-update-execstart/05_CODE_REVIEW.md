# 05 — Code Review · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream read, never edited: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY),
> `03_GATE_REVIEW.md` (APPROVED WITH CONDITIONS, C-1…C-5), `04_DEVELOPMENT.md` (READY FOR REVIEW).
> Rules loaded: `00-core`, `05-insight-index`, `50-singbox-cli`, `70-doc-size`, `85-design-discipline`.
> Memory read: `.harness/insight-index.md` (line 12 = this defect, line 14 = the auto-elevate hazard),
> `.harness/rejected-decisions.md`, `docs/dev-map.md`.
> **Safety posture of this stage:** read-only tool set (Read / Glob / Grep). No execution or import of
> `bin/sc`, no `systemctl`, no installer/uninstaller run, no root, no commit, no live-system mutation.
> `/usr/local/bin/sc` and `/usr/local/bin/sing-box` are both installed on this host, so the hazard was
> live and is naturally satisfied by the tool set — no workaround was attempted.
>
> Authored by `harness-kit:code-reviewer` (read-only tool set); transcribed verbatim by the PM
> orchestrator, which added no content of its own.

---

## 0. Verification limitation — stated before any claim rests on it

My tool set has **no `git`**, no shell, and no `systemd-analyze`. I therefore did **not** re-execute
`git diff`, `verify_all.sh`, or the before/after `systemd-analyze verify`. What I did instead:

1. Read the **post-change bytes** of both changed files directly.
2. Corroborated the "nothing else moved" claim **indirectly but strongly**, by confirming that every
   out-of-scope anchor cited by stages 01–03 *before* the edit still sits at exactly its recorded line
   number and holds exactly its recorded content: `install.sh:376,438,456,479`, the step-4 block at
   `install.sh:403-409`, step 6 at `:454-463`, step 7 at `:465-492`, `bin/sc:77-78`, `bin/sc:1217`,
   `uninstall.sh:113-130` and `:132-134`, `systemd/sing-box.service:1-17`,
   `systemd/sing-box-rules-update.timer:1-11`, `README.md:158,182,187` and its
   `README.zh-CN.md:158,182,187` mirrors. A line-number-preserving edit to any of those files is not a
   plausible failure mode here.
3. Re-ran the AC-3 sweep with Grep across the whole repo.

Claims that remain **developer-reported and not independently reproduced by me**: V-3's exact
`1 insertion(+), 1 deletion(-)` shape, V-5's `git diff --quiet` byte assertions, V-6's before/after
`systemd-analyze` outputs, V-7's `verify_all` delta-0 counts. Nothing I read contradicts any of them;
they are QA's to re-execute. This is a limitation disclosure, not a finding.

---

## Files reviewed

Changed (both read in full, post-change):
- `/home/alan/Programs/singbox-cli/systemd/sing-box-rules-update.service`
- `/home/alan/Programs/singbox-cli/CHANGELOG.md`

Read to verify the boundary held and the claims are true:
- `/home/alan/Programs/singbox-cli/install.sh` (`:400-419`, `:450-494`, plus grep of all `sc` sites)
- `/home/alan/Programs/singbox-cli/bin/sc` (`:70-83`, `:1217` — read only, never imported or executed)
- `/home/alan/Programs/singbox-cli/uninstall.sh` (`:108-142`)
- `/home/alan/Programs/singbox-cli/systemd/sing-box.service`, `/systemd/sing-box-rules-update.timer`
- `/home/alan/Programs/singbox-cli/docs/dev-map.md`, `/.harness/rules/70-doc-size.md`,
  `/.harness/rules/85-design-discipline.md`, `/.harness/rules/50-singbox-cli.md` (changelog convention),
  `/.harness/scripts/verify_all.sh` (E.6, F.6 definitions), `/docs/tasks.md` (T-09 row)

**Tests:** none exist and none was expected. `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02`
defers the committed harness to T-07; `verify_all` B.2/B.3 are `SKIP` by design. Adding a test file here
would itself have been a finding. The developer added none — correct.

---

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[TRACE / delivery carry-forward] `04_DEVELOPMENT.md:401`** — the verdict states "Gate conditions
  C-3, C-4 and **C-5** are discharged here". C-5 is **not** fully discharged at this stage, and the
  document knows it: `04:266-269` explicitly defers C-5's third catch-up path (`sc update-interval` to a
  shorter cadence) to `07_DELIVERY.md`. Worse, C-5's **other** half — gate F-8, "remote installs pick the
  fix up *within minutes of the push*, not instantaneously" (`03_GATE_REVIEW.md:296-299`) — appears
  **nowhere in `04_DEVELOPMENT.md`**, neither as discharged nor as carried forward. The `## Conditions
  carried forward` section lists C-1, C-2 and R-1 only. This is precisely the evaporation shape the gate
  itself flagged as F-2: an obligation with no downstream anchor in the document the next stage reads.
  Mitigating: `07_DELIVERY.md`'s author reads `03_GATE_REVIEW.md` directly, where C-5 is stated in full,
  so the risk is real but bounded. **Owner: developer.** Fix is one line in `04` (move C-5 to the
  carried-forward list, partial), or PM simply re-states C-5 in the stage-7 dispatch. Not a merge blocker.

- **[SPEC / requirement precision] `01_REQUIREMENT_ANALYSIS.md:171` (AC-3)** — AC-3 reads "No occurrence
  of `/usr/local/bin/proxy` remains **anywhere in the repository** except the uninstaller's **two**
  legacy-cleanup lines." Both italicised clauses are wrong as written, and were wrong **before the
  developer touched anything** (see §"The AC-3 ruling" below for the full disposition). **Owner:
  requirement-analyst.** Report-only: no rework, no re-approval, no change to the code. Recorded so the
  same phrasing is not reused as a literal gate in a future task.

### NIT

- **[DOC] `CHANGELOG.md:15`** — the bullet names one of design §8.3's two catch-up exceptions (stale
  stamp after a disabled timer) and omits the other (host powered off across a scheduled boundary). The
  omitted one is standard `Persistent=true` behaviour, unchanged by this task, and design §10 fact (4)
  required no exception list at all. Pure preference; do not act on it.

- **[STYLE] `CHANGELOG.md:15`** — the bullet is a single ~600-character line. That is the file's
  established shape (`:7`, `:11`, `:13`, `:14` are all one long line), so this is consistency, not a
  defect. Noted only so nobody "fixes" it into a different shape than its siblings.

- **[DESIGN, pre-existing] `systemd/sing-box-rules-update.service:3`** — `After=network-online.target`
  with no `Wants=`/`Requires=` on that target. Pre-existing, explicitly adjudicated as report-only
  (01 §8 Q5, 02 §15 item 4), and adding it here would have been a **finding against** the developer.
  Listed for completeness; it is not attributable to this change.

---

## The AC-3 ruling (judgment 1)

**Ruling: the implementation is compliant. AC-3 was written without contemplating prose, and its literal
text is unsatisfiable — it was already false at the moment it was authored.**

Evidence, gathered this stage with a repo-wide Grep for the literal `/usr/local/bin/proxy`:

| Where | Nature | Introduced by |
|---|---|---|
| `uninstall.sh:133` | shipped code, `rm -f` of a legacy filename — **not an invocation** | pre-existing, deliberate |
| `CHANGELOG.md:15` | **prose**, naming the wrong path to describe the defect | this change (design §10 fact (1) mandates it) |
| `.harness/insight-index.md:12` | prose | pre-existing |
| `docs/batches/default/BATCH_PLAN.md:17,58` | prose | pre-existing |
| `docs/features/_archived/…` (11 lines across T-01/T-02 docs) | prose | pre-existing |
| `docs/features/fix-rules-update-execstart/01_…md:25,30,87,171,304` | prose | **the requirement document that states AC-3** |

The last row is decisive. `01_REQUIREMENT_ANALYSIS.md` contains the literal **five times, including
inside AC-3's own cell**. A criterion that forbids an occurrence "anywhere in the repository" is
therefore violated by the sentence expressing it, at the instant it is written, on a clean tree. No
reading survives in which the changelog bullet is the thing that breaks it.

The operative reading is the one AC-3's own verification column supplies: *"Repo-wide search … and
enumerate every hit with its disposition"*, plus the substantive second clause *"no other file invokes a
`proxy` executable."* Against that reading:

- Every hit is enumerated with a disposition — `04_DEVELOPMENT.md:146-167`, five bullets, correctly
  separating the shipped-code hit, the sudoers twin (`/etc/sudoers.d/proxy`, a *different* literal), the
  changelog prose, and the documentation/memory prose.
- No file invokes a `proxy` executable. I re-verified the negative independently: the only remaining
  `proxy`-as-a-word hits in shipped non-Markdown files are `bin/sc:122,1075,1298` (GNOME **system proxy**
  UI string, its `print`, and the `sysproxy` help line) — none is an executable name.

Two further points that settle it:

1. **The gate had already found this exact imprecision class.** F-3 / C-3 corrected AC-3's "**two**
   legacy-cleanup lines" to **one** (`uninstall.sh:134` holds `/etc/sudoers.d/proxy`, not
   `/usr/local/bin/proxy`). The prose collision is the second instance of the same drafting flaw, not a
   new one. The developer executed V-4 per C-3 and correctly declined to record the mismatch as a defect.
2. **The design instruction does not actually conflict with the AC — the AC's *wording* does.** Design
   §10 fact (1) requires the entry to name the wrong path, which is the only way a changelog entry can be
   useful: a user searching `journalctl` for `203/EXEC` or grepping their own `/etc/systemd/system/` for
   the broken string must be able to match the entry. A changelog that describes a wrong-path defect
   without naming the wrong path is not a changelog.

**Disposition:** compliant, ship as-is. The residual is a MINOR documentation-precision defect owned by
the **requirement-analyst**, non-blocking, no rework. The developer's unprompted disclosure
(`04:157-159` in V-4 and `04:355-357` as Open issue 1) is exactly the behaviour this pipeline wants —
surfacing a collision rather than silently resolving it in either direction.

---

## The C-5 scope question (judgment 2)

**Ruling: precision, not scope drift.** Applying C-5's conditional phrasing to `CHANGELOG.md:15` was
correct, and the alternative would have shipped a false sentence to users.

- C-5 exists because an unqualified "the timer never fires immediately" is **factually wrong** for the
  stale-stamp population (design §8.3 case 1, upheld at gate §2.2). That falsity is a property of the
  *claim*, not of the *file it appears in*. `CHANGELOG.md` makes the identical claim to the identical
  audience.
- The design already says so on its own authority: R-5 (`02:410`) states "the claim shipped is *no
  catch-up on a host whose timer has been triggering*, not an unqualified *never*" — and R-5 is scoped to
  "the delivery text", not to one filename. Design §10 also states the changelog carries §9 "in condensed
  form".
- Design §10 delegates prose explicitly: *"exact prose is the developer's; these are the load-bearing
  facts."* Qualifying a fact for accuracy is inside that delegation.
- Under `.harness/rules/85-design-discipline.md` the counter-rule targets **new files, modules, config
  formats, speculative generality, and widened scope**. A subordinate clause in an existing sentence is
  none of those. No machinery, no file, no directive, no new fact beyond upstream-approved §8.1/§8.3.
- The developer also drew the line in the right place: the third path C-5 names (`sc update-interval` to
  a shorter cadence) was **left** to `07_DELIVERY.md` rather than pulled forward, and the reasoning is
  recorded (`04:266-269`). That is restraint, not expansion.

### The four required facts — checked against `CHANGELOG.md:15` word by word

| Design §10 fact | Present? | Accuracy check |
|---|---|---|
| **(1) The defect** — `ExecStart` pointed at `/usr/local/bin/proxy`, never installed, every trigger `203/EXEC`, advertised auto-update never ran on any systemd host | ✅ | Accurate, and adds the `systemctl --failed` residue (gate §3 item 4's point). Correctly notes the installer installs `/usr/local/bin/sc`. |
| **(2) The fix** — the unit now runs `/usr/local/bin/sc update-rules` | ✅ | Byte-matches `systemd/sing-box-rules-update.service:7`. |
| **(3) The user action** — re-run the one-liner or `sudo ./install.sh`; the installer reloads systemd itself; no manual unit edit, **no timer restart** | ✅ | Accurate against `install.sh:407` + `:409` and design §7's determination. Uses the file's existing `.../install.sh` elision (matches `CHANGELOG.md:30`). |
| **(4) What to expect** — no catch-up run, first run at next weekly point + ≤1 h; `systemctl start …` to run now **with the sing-box restart caveat**; `reset-failed` and its self-clearing condition | ✅ | All four sub-parts present. "…+ 最多 1 小时随机延迟" matches `RandomizedDelaySec=1h`. The restart caveat is true (`bin/sc:1135-1143` → `restart_service()` at `:834-838`). "不清也会在**下一次成功运行**后自动消失" is precisely right — it conditions self-clearing on *success*, which is the correct semantics and is subtler than the design text required. |

Plus the C-5 qualification itself: 「在定时器一直正常触发的机器上不会立刻补跑一次…若定时器此前被停用过、
时间戳已经过期，`Persistent=true` 会在安装结束后立刻补跑一次」— the conditional form C-5 demands, with
the stale-stamp exception named. **No unqualified claim anywhere in the bullet.**

---

## Scope fidelity, both directions (judgment 3)

**Over-building: none.** Verified by reading the post-change unit file directly. It is 7 lines:
`[Unit]` / `Description=` / `After=` / blank / `[Service]` / `Type=oneshot` / `ExecStart=`. A targeted
grep for `^(ExecStart|Type|User|Environment|Restart|Condition|Wants|ExecStartPre|ExecStartPost|SuccessExitStatus|\[Install\])`
returns **exactly two lines**: `6:Type=oneshot` and `7:ExecStart=/usr/local/bin/sc update-rules`. No
second `ExecStart`, no `ConditionPathExists=`, no `Environment=`, no `User=`, no `Wants=`, no `Restart=`,
no `SuccessExitStatus=`, no `ExecStartPre/Post=`, no `[Install]`. R-6 did not materialise; gate Q-D1 was
obeyed literally.

Out-of-scope files, checked at every anchor stages 01–03 recorded pre-change (see §0 for the method):

| File | Result |
|---|---|
| `bin/sc` | Unchanged. `:77-78` auto-elevate and `:1217` OpenRC script both at their recorded lines with recorded content. |
| `install.sh` | Unchanged. `:376`, `:438`, `:456`, `:479`, step-4 block `:403-409`, step 6 `:454-463`, step 7 `:465-492` all intact at recorded line numbers. |
| `uninstall.sh` | Unchanged. `:113-130` (still no `reset-failed` → C-2 still true), `:132-134` legacy cleanup intact. |
| `systemd/sing-box.service` | Unchanged — matches its documented content exactly. |
| `systemd/sing-box-rules-update.timer` | Unchanged — `OnCalendar=weekly`, `RandomizedDelaySec=1h`, `Persistent=true`, `WantedBy=timers.target` (E-10). |
| `README.md` / `README.zh-CN.md` | Unchanged, and still mirrored (`:158`, `:182`, `:187` in both). No README change was needed (Q7 a) and none was made. |
| `.harness/**` | No new rule, no `verify_all` wiring, no `rejected-decisions.md` entry (correct — nothing new was declined). |
| `docs/dev-map.md` | Unchanged, and correctly so: `:15` already lists `systemd/…{service,timer}`, `:17` already lists `CHANGELOG.md`. No dev-map update was owed. |
| `docs/tasks.md` | Modified in-tree. **Accepted as the PM's board row** (`:11` is the T-09 row), per your instruction and `04:38-40`. Not attributable to this stage. |

**No abstraction invented** across the systemd unit and the OpenRC periodic script — the literal is
copied, as design §3's three seam tests require. I re-ran the tests: the unit is a static asset copied by
`install.sh:407`; the OpenRC script is a runtime-written string at `bin/sc:1217`; neither consumes the
other's output, neither decides anything, and this project has no build step (`dev-map.md:22`) to host a
shared template. Extraction would remain unjustified.

**Under-delivery: none.** Every behaviour the *developer* owns is delivered (B-1…B-5, B-8, B-9, B-10 —
table below). B-6 and B-7 are `07_DELIVERY.md` obligations by their own wording ("the delivery document
names / lists"), and the developer supplied their raw material: the repair recipe is fixed in design §9,
and the B-7 sweep is executed and enumerated in `04:146-167`. Nothing was quietly narrowed.

---

## Design fidelity, on mechanism (judgment 4)

| Design / requirement item | Implementation | Status |
|---|---|---|
| §2.1 exact edit: `proxy` → `sc` on line 7, nothing else | `systemd/sing-box-rules-update.service:7` | ✅ |
| B-1 absolute, literal path; no `$PATH`, no `/usr/bin/env`, no quoting, no variable | `ExecStart=/usr/local/bin/sc update-rules` — leading `/`, no `$`, no `"`, no `'`, no `;`/`&`/`\|`/`` ` `` | ✅ |
| B-2 exactly one `ExecStart`, `Type=oneshot`, `[Unit]` untouched, no added directive, no `[Install]` | grep returns only `:6` and `:7`; `[Unit]` still `Description=Update sing-box rule sets` + `After=network-online.target sing-box.service` | ✅ |
| B-3 failure stays visible | Nothing added that could mask exit status — no `Restart=`, no `SuccessExitStatus=`, no `-` prefix on the command | ✅ |
| B-4 runs as root, auto-elevate does not fire | No `User=` in the unit; guard is `if os.geteuid() != 0:` at `bin/sc:77` — under uid 0 the `execvp` at `:78` is not reached | ✅ (mechanism verified, not assumed) |
| B-5 documented upgrade path repairs a broken host, installer unmodified | `install.sh:405-409`: one `if` block, three plain `install -m 644`, then unconditional `daemon-reload`; I re-read `:403-419` and found no `exit`, `return`, `\|\|`, `&&`, `trap` or subshell between `:405` and `:409`, and the block precedes step 6 (`:456`) and step 7 (`:465+`) | ✅ |
| B-8 no new runtime string, bilingual parity unaffected | No `bin/sc` / `install.sh` / `uninstall.sh` change → no `t()` key; both READMEs unchanged and still mirrored | ✅ |
| B-9 one `[Unreleased] / 修复` entry, zh-only | `CHANGELOG.md:15`, Simplified Chinese, four facts present | ✅ |
| B-10 diff boundary | Unit + `CHANGELOG.md` + stage docs (+ PM's `docs/tasks.md`) | ✅ (see §0 limitation) |
| BC-12 unit hygiene | 7 lines; grep for `[ \t]+$` → **0 matches** (no trailing whitespace on any line); one `ExecStart`; no shell metacharacter. Terminating-newline byte is developer-evidenced (`od -c` at `04:106-107`) and consistent with my read | ✅ |
| §10 placement: last bullet of `修复`, no blank line after `:14`, blank line before `## [0.1.0]` | Read confirms `13:` bullet, `14:` bullet, `15:` new bullet, `16:` blank, `17:## [0.1.0]`; `### 新增` (`:5-7`) untouched, no heading added, no reorder | ✅ |
| §15 out-of-scope list (9 items) | All honoured — see the scope table above | ✅ |
| Gate C-3 (V-4 = one shipped-code hit) | Executed as corrected; sudoers twin reported separately; not recorded as a defect | ✅ |
| Gate C-4 (all active stage docs ≤500 lines) | `01`=327, `02`=499 **byte-unchanged**, `03`=321, `04`=403, `PM_LOG`=… — all under cap. **This document is 246 lines**, so F.6 stays PASS after transcription | ✅ |
| Gate C-5 (conditional phrasing) | Applied to `CHANGELOG.md:15`; 07-bound remainder deferred — see MINOR finding | ⚠️ partial by design, one traceability gap |

---

## The six dimensions

**1 · Logic correctness.** The single behavioural change is an `execve` target. It is the correct
target, verified against **six** independent in-repo sites, all byte-identical (`install.sh:376`,
`:438`, `:456`, `:479`, `bin/sc:78`, `bin/sc:1217`). Boundary cases: BC-6 (`sc` absent) still fails
loudly `203/EXEC` because no guard was added — deliberate, and the loudness is what made this defect
findable. BC-3 (`failed` state) does not block the next activation. BC-5 (OpenRC) reads no unit file at
all. No concurrency, no off-by-one, no null/empty surface exists in a 7-line INI asset. No finding.

**2 · Requirement fidelity.** Table below; every criterion the developer owns is satisfied. No finding
beyond the AC-3 wording MINOR, which is upstream.

**3 · Design fidelity.** The implementation is design §2.1 verbatim plus the §10 bullet. `04`'s
"Design drift: **None**" is accurate — I looked for drift specifically in the three places it hides
(a forbidden directive, an out-of-scope touch, an invented abstraction) and found none. The two
"precision notes" the developer volunteered (`04:312-320`) are both correctly classified as non-drift.

**4 · Performance.** No material surface. The unit runs at most weekly with ≤1 h jitter and performs
four small validated downloads. What the fix *activates* is R-1: a weekly `systemctl restart sing-box`
even on a no-change run (`bin/sc:1141-1143` → `:834-838`), landing 00:00–01:00 local Monday. That is
pre-existing `bin/sc` behaviour owned by T-02, correctly out of scope, and correctly carried forward.

**5 · Security.** Nothing widened. The executed path is a root-owned, mode-755 file in a
root-writable-only directory (`install.sh:376`). The unit still carries **no `Environment=`**, so the
`SB_RULES_BASE` mirror override cannot be injected through it — I confirmed the absence by grep, not by
assumption. `/etc/sudoers.d/sc` untouched; sudo is not on this path at all (B-4). No shell is involved,
so the `update-rules` argument cannot be re-parsed. The change does make a root-privileged network fetch
weekly-reachable for the first time, but the fetch's validation (SRS magic, size floor, `Content-Length`
equality, atomic replace) is T-02's shipped contract, not new attack surface. No finding.

**6 · Maintainability.** The one-line shape is the right granularity and the design says why
(85's "when the owner's suggested shape is already right, keep it and say why"). No dead code, no
premature abstraction, no comment added where none was needed. The changelog bullet matches its
siblings' language, register and line shape, and lives where `dev-map.md:17` and
`.harness/rules/50-singbox-cli.md:66` say user-visible changes go. `04_DEVELOPMENT.md` is honest about
what it did not verify. **No invented rules were applied by me**: every standard cited above is in
`AI-GUIDE.md`'s rule set or in the upstream stage docs; my two style observations are filed as NIT.

---

## Requirement coverage check

| Criterion | Implementation / evidence | Status |
|---|---|---|
| AC-1 one `ExecStart`, exact value | `systemd/sing-box-rules-update.service:7`; grep → single match | ✅ |
| AC-2 byte-identical across all sites | `install.sh:376,438,456,479`, `bin/sc:78`, `bin/sc:1217`, unit `:7` — re-verified this stage | ✅ |
| AC-3 stale-path sweep enumerated | `04:146-167`; re-run independently this stage | ✅ (operative reading — see ruling; MINOR against the AC's wording, owner requirement-analyst) |
| AC-4 unit otherwise unchanged | `[Unit]` block + `Type=oneshot` intact; directive grep returns only `:6`,`:7` | ✅ (exact diff shape developer-reported, §0) |
| AC-5 upgrade path repairs broken host | `install.sh:403-409` re-read; no early-exit construct between `:405` and `:409`; precedes the failure-tolerant steps | ✅ |
| AC-6 reload-sufficiency stated | Determined in `02` §7, upheld at gate §2.1 | ⏭ `07_DELIVERY.md` must restate |
| AC-7 immediate-run / reset-failed commands | Fixed in `02` §9; condensed form already correct in `CHANGELOG.md:15` | ⏭ `07_DELIVERY.md` |
| AC-8 no CLI-behaviour change, no translation key | `bin/sc`, `install.sh`, `uninstall.sh` unchanged at every anchor | ✅ |
| AC-9 CHANGELOG entry | `CHANGELOG.md:15`, zh-only, four facts | ✅ |
| AC-10 diff boundary | Unit + CHANGELOG + stage docs; `docs/tasks.md` is the PM's row | ✅ (§0 limitation) |
| AC-11 no live mutation | Developer's posture at `04:70-91`; my own stage is read-only by tool set | ✅ / ⏭ QA re-attests |
| AC-12 `verify_all` delta 0 | `04:278-300` reports 16/0/0/2, exit 0, three runs | ⏭ QA re-executes; my 246-line doc keeps F.6 PASS |
| AC-13 `systemd-analyze verify` | `04:188-212`: pre-change exits 1 naming `/usr/local/bin/proxy`, post-change exits 0 silently | ⏭ QA re-executes |
| AC-14 activated consequences documented | R-1 carried at `04:344-349`; BC-7 and BC-11 in `02` §8/§13 | ⏭ `07_DELIVERY.md` |

No criterion is unimplemented. No `❌`.

---

## Carried-forward check — C-1 / C-2 / R-1 (judgment 5)

Compared clause by clause against `03_GATE_REVIEW.md:285-299` and `02:406`.

| Item | Gate text | `04_DEVELOPMENT.md` | Verdict |
|---|---|---|---|
| **C-1** (F-1) service environment | (a) `bin/sc:31` `SB_BIN` bare PATH lookup, benign because systemd's default service `PATH` includes `/usr/local/bin`; (b) Python-3.6 + no locale → `UnicodeEncodeError` on `bin/sc:1089`, also `:1136/1142`; exposed population Ubuntu 18.04 / CentOS 7; do not remedy in the unit | `04:326-338` — both halves, same line citations, same population, plus the explicit reason no remedy is available (`Environment=` is B-2-forbidden, `bin/sc` is out of scope) and "PM routes" | **Not thinner.** Faithful. |
| **C-2** (F-2) uninstaller `reset-failed` residue | `uninstall.sh:113-130`, E-14 / 01 §8 Q9, must be a follow-up row since no AC binds it | `04:339-343` — same citation, plus "Re-read this stage; still true". I re-read `uninstall.sh:113-130` myself: `disable --now`, three `rm -f`, `rm -rf` of the `.timer.d`, `daemon-reload` — **no `reset-failed`**. Still true. | **Not thinner.** Independently confirmed. |
| **R-1** weekly restart on unchanged run | `02:406` + gate §2.3's added detail that `OnCalendar=weekly` lands the drop 00:00–01:00 local Monday | `04:344-349` — `bin/sc:1141-1143` + `:834-838`, "every host gains a weekly connection drop", **and** the Monday 00:00–01:00 window picked up from gate §2.3 | **Richer, not thinner.** |
| **C-5 remainder** | third catch-up path + F-8 "within minutes of the push" | third path noted at `04:266-269`; **F-8 absent entirely**; verdict claims C-5 discharged | **Thinner — the MINOR finding above.** |

Three of four are intact or improved. The fourth is the MINOR.

---

## Axis status

- **Standards-conformance:** 1 MINOR (`04:401` C-5 discharge overstatement / F-8 with no downstream
  anchor), 2 NIT (changelog exception list, changelog line length). Worst = **MINOR**. Everything else
  is clean and explicitly so: doc-size caps hold (`02` still 499, this doc 246), `dev-map.md` needed no
  update and got none, `CHANGELOG.md` language and location follow `dev-map.md:17` +
  `50-singbox-cli.md:66`, bilingual parity is untouched because no runtime string was added, no
  `verify_all` wiring, no new test file against `rejected-decisions.md`, no rule invented by this review.
- **Spec/design-fidelity:** 1 MINOR (AC-3's unsatisfiable literal wording, owner requirement-analyst —
  a defect in the *criterion*, not in the *code*), 1 NIT (pre-existing `After=` without `Wants=`).
  Worst = **MINOR**. B-1…B-10 all satisfied; design §2.1, §3, §10, §15 all matched; zero design drift.
- **Aggregate:** MINOR — the more severe of the two axes, which are equal.

---

## Verdict

**PASS WITH COMMENTS** — 0 CRITICAL, 0 MAJOR, 2 MINOR, 3 NIT. Merge is not blocked.

The change is exactly the approved design and nothing more: one substituted path literal in a 7-line
unit file, verified against six agreeing in-repo sites, with no directive added, no out-of-scope file
touched, no abstraction invented, no test file, no gate wiring — and one Simplified-Chinese `修复` bullet
carrying all four load-bearing facts accurately, in the file's own language and shape.

On the two judgments referred to me:

1. **The AC-3 collision is not a defect in the work.** AC-3's "anywhere in the repository" is literally
   unsatisfiable — the requirement document containing AC-3 breaks it five times over on a clean tree,
   and the gate had already corrected the same sentence's "two lines" to one. The operative reading is
   the enumeration-with-disposition the AC's own verification column specifies, and the developer
   satisfied it and disclosed the tension unprompted. Filed **MINOR, owner: requirement-analyst,
   report-only**; no rework, no re-approval.
2. **Applying C-5's conditional phrasing to the changelog is precision, not scope drift.** The
   unqualified claim is false for the stale-stamp population; design R-5 already states the shipped claim
   must be conditional without scoping that to one filename; §10 delegates prose to the developer; and
   nothing was built, widened, or added. The developer also correctly declined to pull C-5's third path
   forward into the changelog.

The one thing to fix is bookkeeping: `04_DEVELOPMENT.md` declares C-5 discharged while two of its clauses
still belong to `07_DELIVERY.md`, and gate F-8's "within minutes of the push" phrasing has no anchor in
`04` at all. **Owner: developer** — one line, or PM re-states C-5 in the stage-7 dispatch. That is the
same evaporation shape the gate itself named as F-2, which is why it is worth catching now rather than
after `07_DELIVERY.md` is written.

Routing note for PM: C-1, C-2 and R-1 are correctly carried and need pool rows; C-5's remainder and
AC-6 / AC-7 / AC-14 remain live obligations on `07_DELIVERY.md`; AC-11 / AC-12 / AC-13 are QA's to
re-execute, since this stage's read-only tool set could not reproduce `git diff`, `verify_all` or
`systemd-analyze`.
