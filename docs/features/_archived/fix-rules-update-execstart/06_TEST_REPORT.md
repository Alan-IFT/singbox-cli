# 06 — Test Report · T-09 `fix-rules-update-execstart`

> Mode: **full** · Deferred-human (defer, do not ask) · 2026-07-31
> Upstream read, never edited: `01_REQUIREMENT_ANALYSIS.md` (READY), `02_SOLUTION_DESIGN.md` (READY),
> `03_GATE_REVIEW.md` (APPROVED WITH CONDITIONS C-1…C-5), `04_DEVELOPMENT.md` (READY FOR REVIEW),
> `05_CODE_REVIEW.md` (PASS WITH COMMENTS).
> Base commit: `d879ab3`. Working tree, **not committed, not pushed**.
> **This stage is the first with a shell.** Stages 3 and 5 had read-only tool sets and could not
> re-execute `git diff`, `verify_all` or `systemd-analyze`. Everything they left developer-reported
> (V-3, V-5, V-6, V-7) was re-executed here from scratch, with actual tool output below.

---

## 0. Executed vs. reasoned — stated first, because the whole report depends on it

The owner asked for this line to be drawn plainly. It is drawn here and nowhere else in this document
is it blurred.

**Mechanically evidenced in this session (tool output pasted below):** the unit now names
`/usr/local/bin/sc`, exactly once, absolutely, ASCII-only, LF-only, no metacharacters (§2 A1a–A1g);
`/usr/local/bin/proxy` does not exist on a real host while `/usr/local/bin/sc` does (§4); the
pre-change unit fails `systemd-analyze verify` **naming the missing binary** and the post-change unit
passes silently (§3), and that tool genuinely discriminates rather than vacuously exiting 0 (§5 M1,
M5); nothing else in the unit moved — lines 1-6 byte-identical to `HEAD` (§2 A4b); the diff boundary
is unit + `CHANGELOG.md` only, plus the PM's board row (§2 A10); exactly one shipped-code
`/usr/local/bin/proxy` hit remains (§2 A3); the installer copies the unit and reloads with no
reachable early exit and the unit is in the remote fetch list at `REF=main` (§6); `verify_all` is
delta 0 against a **pristine `HEAD` tree I built myself**, no FAIL, exit 0 (§7); and no live-system
mutation occurred (§8).

**Reasoned, NOT executed — do not read this report as proving it:**

1. **"The weekly timer now actually updates rulesets."** Not demonstrated. It would require installing
   the corrected unit as root and letting a trigger fire, which mutates the live system and, via
   `bin/sc:1141-1143`, restarts the operator's running sing-box. Gate §6 Q-D7 decomposes the claim
   into four links; **links 1-3 (the literal, the parse+stat, the installer ordering) are executed
   here; link 4 — that `daemon-reload` alone makes the corrected `[Service]` effective at the next
   activation — is a pure mechanical argument** (design §7, gate §2.1). I could not test it.
2. **BC-11's stamp claim** ("the trigger stamp has been advancing all along, so no catch-up run").
   Design §8.2 promised this would be empirically observable on this host. **It is not** — finding
   **D-1**. The claim remains 100 % argument, 0 % observation.
3. **`sc update-rules` behaving correctly inside a systemd service environment.** Never executed:
   running it is exactly the forbidden action. C-1's two residuals were verified by *reading* plus
   one read-only host query (§9), not by running the CLI.

---

## 1. Test plan — every acceptance criterion mapped to a check I ran myself

No committed test file was added: `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` defers
the harness to T-07, design §15 item 7 forbids a new test file, and adding one would break AC-12's
delta-0. My assertions therefore live in a **scratchpad** script written from the acceptance criteria
— **not** from `04_DEVELOPMENT.md`'s commands — reproduced in §2 so anyone can re-run them. Routing
note: that script is the natural seed for T-07's `verify_all` B.2.

| AC | Check(s) | Where | Result |
|---|---|---|---|
| AC-1 one `ExecStart`, exact value | A1a, A1b, A1c, A1d, A1e, A1f, A1g | §2 | PASS |
| AC-2 literal identical at every in-repo site | A2 (all `/usr/local/bin/*` literals, not just the 6 the developer listed) | §2 | PASS |
| AC-3 stale-path sweep | A3 + full repo sweep | §2 | PASS (one shipped hit) |
| AC-4 unit otherwise unchanged | A4, A4b + `git diff` | §2 | PASS |
| AC-5 upgrade path repairs a broken host | installer step-4 parse | §6 | PASS |
| AC-6 reload-sufficiency stated | present in `02` §7 | — | ⏭ `07_DELIVERY.md` must restate |
| AC-7 immediate-run / `reset-failed` commands | present in `02` §9 + `CHANGELOG.md:15` | §2 A9 | ⏭ `07_DELIVERY.md` |
| AC-8 no CLI behaviour change, no translation key | A10 byte-unchanged assertions | §2 | PASS |
| AC-9 `CHANGELOG.md` entry | A9 (placement, UTF-8, diff shape) | §2 | PASS |
| AC-10 diff boundary | A10 + `git diff --summary` (mode/rename check) | §2 | PASS |
| AC-11 no live mutation | full command log + before/after live-state read | §8 | PASS |
| AC-12 `verify_all` delta 0 | pristine-`HEAD` baseline built in scratchpad, both runs | §7 | PASS |
| AC-13 `systemd-analyze verify` | before/after + 5 mutants as controls | §3, §5 | PASS |
| AC-14 activated consequences documented | R-1 / BC-7 / BC-11 carried in `04` §Conditions | — | ⏭ `07_DELIVERY.md` |

---

## 2. Functional + boundary assertions — my own script, actual output

Script: `<scratchpad>/qa_ac_check.sh` (QA-authored, read-only, never touches `bin/sc` as code).

```
PASS  A1a one ExecStart (n=1)
PASS  A1a no '-' ignore-errors prefix
PASS  A1a only one Exec* directive total (n=1)
PASS  A1b exact literal
PASS  A1c unit file is pure ASCII (no homoglyph)
 E x e c S t a r t = / u s r / l o c a l / b i n / s c   u p d a t e - r u l e s
PASS  A1d no CR byte (LF-only)
PASS  A1e no line continuation
PASS  A1f no trailing whitespace
PASS  A1f terminating newline
PASS  A1g no shell metacharacter
      all /usr/local/bin/* literals in shipped code:
        /usr/local/bin/proxy
        /usr/local/bin/sc
        /usr/local/bin/sing-box
PASS  A2 '/usr/local/bin/sc' literal present and canonical
PASS  A2 no unexpected /usr/local/bin/* target
PASS  A4 no forbidden directive, no [Install]
PASS  A4b lines 1-6 byte-identical to HEAD
PASS  A3 exactly ONE shipped-code /usr/local/bin/proxy hit: uninstall.sh:133
PASS  A10 no mode/rename/create in tracked diff
PASS  A10 tracked diff = unit + CHANGELOG + PM board row only
PASS  A10 byte-unchanged: bin/sc            [10 identical "byte-unchanged" PASS lines collapsed:
PASS  A10 byte-unchanged: install.sh         uninstall.sh, systemd/sing-box.service,
PASS  A10 byte-unchanged: README.md          systemd/sing-box-rules-update.timer, README.zh-CN.md,
                                             .harness/scripts/verify_all.sh, docs/dev-map.md,
                                             .harness/insight-index.md — each `git diff --quiet` 0]
PASS  A9 CHANGELOG is valid UTF-8
PASS  A9 CHANGELOG diff = 1 insertion, 0 deletions
=== ALL QA ASSERTIONS PASSED ===   (script exit 0)
```

**Boundary conditions added by me beyond the developer's V-1** (ways a "correct-looking" one-line fix
could still be wrong): `ExecStart=-` ignore-errors prefix; a second `Exec*` verb; non-ASCII homoglyph
smuggled into `sc` (the `od -c` dump above proves every byte is 7-bit); CR bytes / CRLF; backslash
line-continuation hiding a second command; shell metacharacters; file-mode or rename entries in the
diff (`git diff --summary` empty); UTF-8 validity of the changelog bullet.

**V-3 re-executed (was developer-reported only):**

```
$ git diff --numstat
1	0	CHANGELOG.md
1	1	docs/tasks.md
1	1	systemd/sing-box-rules-update.service

$ git diff -- systemd/sing-box-rules-update.service
@@ -4,4 +4,4 @@ After=network-online.target sing-box.service
 [Service]
 Type=oneshot
-ExecStart=/usr/local/bin/proxy update-rules
+ExecStart=/usr/local/bin/sc update-rules
```

Exactly `1 insertion(+), 1 deletion(-)` on the unit. Confirmed independently.

**V-5 re-executed (was developer-reported only):** `git status --porcelain` is
` M CHANGELOG.md` / ` M docs/tasks.md` / ` M systemd/sing-box-rules-update.service` /
`?? docs/features/fix-rules-update-execstart/`. `docs/tasks.md` is the PM's board row (`:11`), not the
developer's work — confirmed by reading the hunk (`_(none)_` → the T-09 row). Every out-of-scope file
listed above is `git diff --quiet` clean.

**V-4 re-executed, per gate C-3.** Shipped code (`install.sh`, `uninstall.sh`, `bin/sc`, `systemd/`)
contains the literal `/usr/local/bin/proxy` exactly **once**: `uninstall.sh:133`
`rm -f /usr/local/bin/sc /usr/local/bin/proxy`, under the comment at `:132` ("legacy `proxy` filenames
left from pre-rename installs"). **Deliberately retained; a removal, not an invocation.**
Reported separately as C-3 requires: `uninstall.sh:134` is `rm -f /etc/sudoers.d/sc /etc/sudoers.d/proxy`
— a **different literal** (`/etc/sudoers.d/proxy`), also deliberate legacy cleanup, **not a defect**.
All other hits in the repo are prose: `CHANGELOG.md:15` (the bullet naming the defect, mandated by
design §10 fact 1), `.harness/insight-index.md:12`, `docs/batches/default/BATCH_PLAN.md:17,58`, and the
T-01/T-02/T-09 stage documents. **No file anywhere invokes a `proxy` executable** — the only remaining
`proxy`-as-a-word hits in shipped non-Markdown files are `bin/sc:122,1075,1295,1298` (GNOME *system
proxy* UI strings and the `sysproxy` help text).

---

## 3. AC-13 / V-6 — `systemd-analyze verify`, re-executed

`systemd-analyze` = `/usr/bin/systemd-analyze`, `systemd 255 (255.4-1ubuntu8.16)`.
Pre-change file recovered per gate Q-D3 into a scratch path whose basename is still
`sing-box-rules-update.service`.

```
$ systemd-analyze verify <scratch>/pre/sing-box-rules-update.service
sing-box-rules-update.service: Command /usr/local/bin/proxy is not executable: No such file or directory
EXIT=1

$ systemd-analyze verify systemd/sing-box-rules-update.service
EXIT=0

$ systemd-analyze verify <scratch>/post/sing-box-rules-update.service   # same basename, controls for path
EXIT=0

$ systemd-analyze verify systemd/sing-box-rules-update.timer            # control, unchanged unit
EXIT=0
$ systemd-analyze verify systemd/sing-box.service                       # control, unchanged unit
EXIT=0
```

The expected discriminator appears exactly as gate Q-D3 predicted: pre-change names
`/usr/local/bin/proxy` and exits 1; post-change is silent and exits 0. No `sing-box.service` /
`network-online.target` not-found noise was emitted in either run on this systemd version, so nothing
had to be discounted. Byte sizes: pre 158, post 155 (the 3-byte `proxy`→`sc` delta), lines 1-6
byte-identical.

---

### 4. Live-host facts corroborating the defect premise (read-only)

```
$ ls -l /usr/local/bin/          →  -rwxr-xr-x root root    42502 Jul 30 12:47 sc
                                    -rwxr-xr-x root root 58069248 Jul 30 12:47 sing-box
$ test -e /usr/local/bin/proxy   →  ABSENT
```

The `203/EXEC` premise is directly evidenced, not inferred — and the auto-elevate hazard
(`bin/sc:77-78` re-execing `/usr/local/bin/sc` under `sudo`) is confirmed live here, which is why
nothing in this stage executed or imported the CLI.

---

## Adversarial tests

One hypothesis per acceptance criterion, written **before** running the check, with the outcome and
the actual tool output. Verdict rests on whether the implementation survived these, not on whether the
developer's own checks pass.

| AC | Hypothesis — "I expect failure when…" | Reproducer (all NEW, QA-authored) | Outcome |
|---|---|---|---|
| AC-1 | the fix is a homoglyph/near-miss — Cyrillic `с`, or an `ExecStart=-` prefix, or CRLF, so it *reads* right and still fails at exec | `qa_ac_check.sh` A1a–A1g + `od -c` of the line | **Survived.** Every byte 7-bit ASCII, no CR, one `Exec*` directive, no `-` prefix, no continuation, no metacharacter |
| AC-2 | some site disagrees — a trailing slash, a case difference, or a *seventh* site the developer's six-row table missed | A2: extract **every** `/usr/local/bin/*` literal from `install.sh`, `uninstall.sh`, `bin/sc`, `systemd/` and set-compare | **Survived, and stronger than reported.** The literal appears **11×** (`install.sh:143,186,376,438,456,479`; `bin/sc:78,1217`; `uninstall.sh:46,65`; unit `:7`) — the developer listed 6; all 11 are byte-identical. Only three distinct targets exist: `sc`, `sing-box`, `proxy` |
| AC-3 | the changelog bullet, or some doc, smuggled a live `proxy` *invocation* back in | `git grep` restricted to shipped code + a `proxy`-as-command sweep | **Survived.** One hit, `uninstall.sh:133`, an `rm -f`. Zero invocations repo-wide |
| AC-4 | the diff is one line in `git diff` but the file changed mode, or gained a byte outside the visible hunk | `git diff --summary` (empty) + `diff` of lines 1-6 against `git show HEAD:` | **Survived.** No mode/rename/create entry; lines 1-6 byte-identical |
| AC-5 | an early exit or `\|\|` sits between the `install -m 644` and the `daemon-reload`, so an upgrade can leave a corrected file with a stale in-memory fragment | grep `405..409` for `exit\|return\|\|\|\|&&\|trap\|$(\|subshell` | **Survived.** Zero matches; `set -euo pipefail` at `install.sh:9`. See §6 |
| AC-9 | the bullet landed in `### 新增`, broke the `[0.1.0]` boundary, or contains mojibake | A9: section map + `iconv -f UTF-8 -t UTF-8` + `--numstat` | **Survived.** `9:### 修复`, bullets `11,13,14`, new `15`, blank `16`, `17:## [0.1.0]`; valid UTF-8; `1 0` |
| AC-12 | delta-0 is only "true" because the developer never measured a real pre-change tree | built a **pristine `HEAD` copy** (repo copied to scratchpad, `git checkout -- .` **in the copy**, stage docs removed) and ran `verify_all` there | **Survived.** Both trees: PASS 16 / WARN 0 / FAIL 0 / SKIP 2, exit 0, per-check identical. §7 |
| AC-13 | `systemd-analyze verify` exits 0 on *anything* — the "PASS" is vacuous | 5 mutants, §5 | **Survived, with a documented blind spot.** It caught the missing-binary class (the actual defect) and missed three other classes → finding **D-4** |
| AC-11 | verification itself moved the live system (the T-02 incident shape) | full live-state re-read after all work, §8 | **Survived.** Every observable identical, sing-box PID unchanged |
| — | **"Is there a host state where the corrected unit still does not run?"** | read-only queries against this host's real units | **BROKEN — see D-2/D-3.** This host's timer is `disabled`, never triggered, `journalctl` empty. On it, the ExecStart fix **alone** changes nothing |
| — | "Does anything else in the repo reference a non-existent binary?" | enumerate every absolute binary path in shipped code, then `systemd-analyze` all three units | **Survived.** Targets are `/bin/kill`, `/bin/sh`, `/sbin/openrc-run`, `/usr/bin/env`, `/usr/local/bin/{sc,sing-box}` (+ the `proxy` `rm`). `/bin/kill` exists; all three units verify clean |
| — | "Is `[Unit]` genuinely unchanged?" | byte-diff lines 1-6 vs `HEAD`, plus forbidden-directive grep | **Survived.** `Description=` and `After=network-online.target sing-box.service` intact; no `Wants=`/`Condition*=`/`User=`/`Environment=`/`[Install]` |
| — | "Could the changelog mislead a user into a broken state?" | read the bullet against `install.sh` behaviour and `README.md:29` | **Mostly survived** — two soft spots, D-3 and D-6. No instruction in it produces a broken state if followed |

### 5. Mutation controls — proving the AC-13 evidence has teeth

I refuse to accept `EXIT=0` as evidence without showing the tool can say `1`. Four mutants of the unit
plus one of `sing-box.service`, each in a scratch dir with a valid unit basename:

```
M1  ExecStart=/usr/local/bin/scc update-rules      (one-char typo)
    → sing-box-rules-update.service: Command /usr/local/bin/scc is not executable: No such file or directory
    → EXIT=1     ✅ CAUGHT — this is the defect class T-09 fixes
M2  ExecStart=sc update-rules                      (bare PATH lookup — B-1 forbids it)
    → EXIT=0     ❌ NOT CAUGHT
M3  CRLF line endings, correct path                (ExecStart=...sc update-rules^M)
    → EXIT=0     ❌ NOT CAUGHT
M4  ExecStart=/usr/bin/env sc update-rules         (B-1 forbids the env wrapper)
    → EXIT=0     ❌ NOT CAUGHT
M5  sing-box.service with ExecReload=/bin/nonexistent-kill -HUP $MAINPID
    → sing-box.service: Command /bin/nonexistent-kill is not executable: No such file or directory
    → EXIT=1     ✅ CAUGHT (Exec* coverage is not limited to ExecStart)
```

**Conclusion.** `systemd-analyze verify`'s post-change `EXIT=0` is **meaningful, not vacuous** — M1 and
M5 prove it discriminates on exactly the property this fix changes. But it is a narrow gate: it
stats absolute-path `Exec*` targets and nothing else. B-1's "absolute, literal, no `/usr/bin/env`, no
PATH lookup" and BC-12's byte hygiene are **not** covered by it — they are covered only by the
byte-level assertions in §2. Filed as **D-4** so nobody later treats AC-13 as a general unit lint.

---

## 6. AC-5 / BC-13 re-executed — the upgrade path and the remote path

```
403  # ----------------- step 4: service -----------------
405  if [ "$INIT_SYS" = "systemd" ]; then
406      install -m 644 ".../systemd/sing-box.service" /etc/systemd/system/
407      install -m 644 ".../systemd/sing-box-rules-update.service" /etc/systemd/system/
408      install -m 644 ".../systemd/sing-box-rules-update.timer" /etc/systemd/system/
409      systemctl daemon-reload
410  else
```

Scan of `405..409` for `exit`, `return`, `||`, `&&`, `trap`, command substitution or a subshell:
**zero matches**. `install.sh:9` is `set -euo pipefail`. Step 4 precedes step 6 (`:456`) and step 7
(`:465+`), the two failure-tolerant steps — so unit installation and the reload do not depend on
ruleset or config success. AC-5 holds, re-executed, not inherited.

BC-13: the remote fetch loop (`install.sh:317-329`) lists `systemd/sing-box-rules-update.service`
explicitly, from `RAW_BASE=https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main` (`REF="main"`,
`install.sh:11-13`). A `curl | bash` user gets the corrected file once the commit is on `main` —
and, per gate F-8, after `raw.githubusercontent.com`'s cache expires (minutes), not instantaneously.

---

## 7. AC-12 / V-7 — `verify_all`, both trees, actually run

The developer's baseline was taken before their own edit and could not be re-checked by stage 5. I
rebuilt a **pristine `HEAD` tree** independently: the repo was copied into the session scratchpad,
`git checkout -- .` was run **inside the copy only**, and this task's untracked stage-doc folder was
deleted **from the copy only**. The real working tree was never touched (proof: §8's final
`git status` is identical to the first one).

| Tree | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| Pristine `HEAD` (`ExecStart=/usr/local/bin/proxy`, no stage docs) — scratchpad copy | 16 | 0 | 0 | 2 | 0 |
| Real working tree, change applied, stage docs 01-05 present | 16 | 0 | 0 | 2 | 0 |
| Real working tree **+ this `06_TEST_REPORT.md`** | 16 | 0 | 0 | 2 | 0 |

**Delta 0 across PASS / WARN / FAIL / SKIP. No FAIL. Exit 0.** Per-check results are identical in all
three runs:
`A.1 PASS · A.2 PASS · B.1 PASS · B.2 SKIP · B.3 SKIP · E.1 PASS · E.2 PASS · E.3 PASS · E.4 PASS ·
E.4b PASS · E.5 PASS · E.6 PASS · F.1 PASS · F.2 PASS · F.3 PASS · F.4 PASS · F.5 PASS · F.6 PASS`

The two checks gate C-4 warned about:

- **E.6** — this document carries the literal `## Adversarial tests` heading, so E.6 stays PASS; verified by re-running `verify_all` **after** writing it.
- **F.6** — `01`=327, `02`=**499** (byte-unchanged, one under the cap), `03`=321, `04`=402, `05`=382,
  `PM_LOG`=192, this document ≤500. **Honest disclosure: my first draft was 515 lines and did trip F.6
  to WARN (exit 1) — the exact trap gate C-4 named. I compacted this document rather than touch the
  gate, re-running until F.6 was PASS. No `verify_all` check was modified.**

`B.1` runs `python3 -m py_compile bin/sc`, which per gate Q-D4 compiles to bytecode **without**
executing module-level code, so the auto-elevate never fires. `bin/__pycache__` was removed by
`verify_all.sh:59` — confirmed by `ls bin/` after the run: only `sc`.

**`.harness/scripts/baseline.json`: NOT updated, deliberately.** It reads `test_count: 0`,
`passing_count: 0`. No committed test was added (upstream forbids it), so the count did not increase
and the baseline must not move. Editing it would also breach AC-10's diff boundary. Baseline stays at
0; T-07 is the row that raises it.

---

## 8. AC-11 — live-system mutation attestation

**Every command class I ran, and why each is read-only:**

| Command class | Read-only because |
|---|---|
| `git status/diff/show/log/grep/rev-parse` | Inspection only. No `checkout`, `stash`, `reset`, `add`, `commit`, `push` **in the repo** |
| `git checkout -- .` (1×) | **In the scratchpad copy only** (`<scratch>/baseline-repo`), never in `/home/alan/Programs/singbox-cli` |
| `cat`/`cat -A`/`sed -n`/`head`/`tail`/`wc`/`od`/`grep`/`awk`/`diff`/`sha256sum`/`iconv`/`strings`/`ls` | File reads |
| `systemd-analyze verify` / `--version` (8×) | Parses and `stat`s; never executes `ExecStart`; needs no root |
| `systemctl cat / show -p / list-timers / is-enabled / --failed / show-environment` (~10×) | D-Bus **reads**. No `start/stop/restart/enable/disable/daemon-reload/reset-failed` was issued at any point |
| `journalctl -u … -n 20` (1×) | Log read |
| `bash .harness/scripts/verify_all.sh` (7×) | Explicitly sanctioned by gate §6 Q-D4 |
| `cp -a`, `mkdir`, `rm -rf`, `printf >` | **All targets inside the session scratchpad.** Nothing written to the repo except this document |
| `python3 --version`, `uptime -s`, `date` | Version/clock reads |

**Never executed, in any form:** `./bin/sc`, `python3 bin/sc`, `python3 -c "import sc"`, `runpy`,
`importlib`, `sc` on `PATH`, any `subprocess` invocation of the CLI, `install.sh`, `uninstall.sh`,
`sudo`, anything as root.

**Before/after live-state comparison — every observable identical:**

| Observable | At start | At end |
|---|---|---|
| `sing-box.service` MainPID | `2500438` | `2500438` |
| `sing-box.service` ExecMainStartTimestamp | `Fri 2026-07-31 17:04:23 CST` | `Fri 2026-07-31 17:04:23 CST` |
| `sing-box.service` ActiveState | `active (running)` | `active (running)` |
| `sing-box-rules-update.service` | `inactive (dead)`, `Result=success`, `NRestarts=0` | identical |
| `sing-box-rules-update.timer` | `inactive`, `UnitFileState=disabled`, `LastTriggerUSec=` (empty) | identical |
| `/etc/systemd/system/sing-box*` mtimes | all `2026-07-30 12:47:06.017957446 +0800` | identical |
| `/var/lib/systemd/timers/stamp-sing-box-rules-update.timer` | absent | absent |
| `systemctl --failed` | 0 units | 0 units |
| repo `git status --porcelain` | 3 ` M` + 1 `??` | identical |

The host's residual state was **not** "cleaned up". Nothing was started, cleared or reloaded.

---

## 9. Report-only items — re-verified TRUE, not fixed

- **C-1(a) — `bin/sc:31` bare PATH lookup.** Verified by reading: `SB_BIN = "sing-box"  # PATH lookup;
  installer places it at /usr/local/bin/sing-box`. **Newly corroborated empirically** (read-only):
  `systemctl show-environment` on this host returns
  `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/snap/bin` — `/usr/local/bin` **is** in the
  manager environment that services inherit, so `sing-box check` inside `generate_config()` resolves
  from a unit. The gate's "safe, but safe by luck" reading stands, now with evidence. **Still true.**
- **C-1(b) — Python-3.6 + no locale `UnicodeEncodeError`.** Verified **by reading only** (never run):
  `bin/sc:1088-1089` is `prefix = f"  ↓ {fname} ... "` then `print(prefix, end="", flush=True)`,
  unconditional, before any download; `bin/sc:1136` / `:1142` print `→ Restarting sing-box ...`. The
  exposure is real for a Python-3.6 host whose manager environment carries no locale. **Not
  reproducible here and I did not try**: this host is `Python 3.12.3` and its manager environment
  carries `LANG=en_US.UTF-8`. The exposed population remains Ubuntu-18.04 / CentOS-7-era hosts.
  **Still true as a residual.**
- **C-2 — `uninstall.sh:113-130` has no `reset-failed`.** Re-read and re-swept:
  `git grep reset-failed -- install.sh uninstall.sh bin/sc systemd/` returns **nothing**. The block
  does `disable --now` ×2, three `rm -f`, one `rm -rf` of the `.timer.d/`, then `daemon-reload`.
  **Still true.**
- **R-1 — `bin/sc:1141-1143` restarts sing-box even when nothing changed.** Re-read:
  `if not applied and is_running(): print(...); restart_service()`, and `restart_service()`
  (`bin/sc:834-838`) is a plain `systemctl restart sing-box`. Note the ordering that makes the caveat
  precise: `if failed: sys.exit(...)` sits **before** it, so a total-failure run does not restart.
  **Still true**, and live on this host — sing-box is `active (running)`, which is exactly why
  §"the immediate-run command" was not executed here.

---

## 10. Defects found

None in the shipped change. **0 BLOCKER, 0 CRITICAL, 0 MAJOR.** The following are documentation- and
evidence-accuracy defects in upstream documents, all report-only, all routed via PM.

- **[MINOR] D-1 — `02_SOLUTION_DESIGN.md:237-247` (§8.2) promises empirical BC-11 evidence that does
  not exist on this host.** The design says "this repo's dev host is installed (§12), so the
  observation is available here". **Reproducer:**
  `systemctl show -p LastTriggerUSec --value sing-box-rules-update.timer` → **empty**;
  `systemctl list-timers --all sing-box-rules-update.timer --no-pager` → **"0 timers listed"**;
  `systemctl show -p UnitFileState --value …timer` → `disabled`;
  `ls /var/lib/systemd/timers/stamp-sing-box-rules-update.timer` → *No such file or directory*;
  `journalctl -u sing-box-rules-update.service` → **"-- No entries --"**.
  The unit files *are* installed (since 2026-07-30 12:47), but the timer was never enabled or started,
  so it has never triggered. **Consequence:** the BC-11 "stamp has been advancing all along" claim has
  **zero** empirical support anywhere in this project; it rests entirely on gate §2.2's mechanical
  argument. That argument is sound and I found nothing contradicting it — but `07_DELIVERY.md` must
  not cite §8.2 as though the observation were made. **Owner: solution-architect (report-only).**

- **[MINOR] D-2 — the "~100 % of existing systemd hosts are in `failed`" population claim is not
  universal** (`01` BC-3, `02` §7.1 item 5, gate §2.1 item 5, and the dispatch brief for this stage).
  **Reproducer:** on this host `systemctl show -p Result,ActiveState,SubState
  sing-box-rules-update.service` → `Result=success`, `inactive`, `dead`; `systemctl --failed` → 0
  units. The service is not failed — it has **never run**. This is the pre-T-01 population `01` §9
  itself describes (installed before timer registration became unconditional). **Consequence:** the
  changelog's "`systemctl --failed` 里还会一直挂着这个单元" is true for the post-T-01 population and
  false for this one. Harmless, but the delivery text should say "on hosts whose timer has been
  firing". **Owner: PM / delivery author (report-only).**

- **[MINOR] D-3 — on a host in that state the ExecStart fix ALONE does not make the weekly update
  run; the installer's `enable`+`start` is load-bearing and no user-facing text says so.**
  **Reproducer:** the state in D-1 — timer `disabled` + `inactive`. Replacing the `.service` file and
  running `daemon-reload` on such a host produces exactly nothing, forever. It works only because the
  documented upgrade path also runs `install.sh:472` (`systemctl enable …timer || true`) and `:486`
  (`systemctl start …timer || true`) — verified by reading `install.sh:465-492`. B-5 is therefore
  satisfied, but design §6.2's upgrade narrative and `CHANGELOG.md:15` both frame the repair as "step
  4 copies the file and reloads", which is **insufficient** here, and R-4's hand-edit path is worse
  than described (`daemon-reload` alone is not enough — an `enable --now` is also required).
  **Fix is one clause in `07_DELIVERY.md`, not in code. Owner: delivery author (report-only);** routed
  to the developer only if the PM decides the changelog bullet must change — I did not change it.

- **[INFO] D-4 — `systemd-analyze verify` is a narrow gate; AC-13 must not be read as unit lint.**
  Evidence in §5: it catches missing absolute-path `Exec*` targets (M1, M5 → exit 1) and misses bare
  PATH lookup (M2), CRLF (M3) and `/usr/bin/env` wrapping (M4) — all exit 0. B-1 and BC-12 are held up
  by the byte assertions in §2, not by AC-13. **Owner: solution-architect (report-only, for T-07's
  gate design).**

- **[NIT] D-5 — `docs/tasks.md:11` still shows T-09 at stage `req`** while the task is at stage 6.
  PM's board row; outside this task's diff boundary; not touched by me.

- **[NIT] D-6 — `CHANGELOG.md:15` gives the install command as
  `sudo bash -c "$(curl -fsSL .../install.sh)"`** with the URL elided. Not copy-pasteable. **Not a
  defect:** it is the file's own established shape (`CHANGELOG.md:30` uses the identical elision) and
  the full URL is in `README.md:29`. A user pasting it verbatim gets a `curl` error, not a broken
  install. **No action.**

**Unresolved hypothesis, stated as such (not a defect claim).** Design §8.1's blanket "a host with no
stamp file also gets no catch-up" depends on which base systemd 255 picks for a `Persistent=true`
calendar timer when `last_trigger == 0`. If that base were the manager's userspace-start timestamp on
a machine whose uptime spans a weekly boundary, the recomputed elapse would be in the past and the
timer would fire at once. Resolving it requires enabling and starting the timer — a live mutation —
so I make no claim either way. It does not falsify the shipped text: C-5's conditional phrasing in
`CHANGELOG.md:15` («在定时器一直正常触发的机器上不会立刻补跑一次…») already scopes the claim to hosts
whose timer has been triggering, so both this host and this hypothesis fall outside it.
**Flagged for post-release watch alongside R-1.**

---

## 11. Stability

`verify_all` was executed **7 times** (pristine `HEAD` copy; working tree; then once per compaction
pass of this document). Every run on a tree whose docs were within the caps gave byte-identical output
and exit 0; the only variation was the F.6 WARN excursion caused by my own over-long draft (§7), which
disappeared deterministically once the document fit. The QA assertion script and the `systemd-analyze`
before/after pair were each run twice with identical results. No time-, network- or ordering-dependent
check exists in this task's surface, and no committed test suite exists to be flaky. **No flakes.**

---

## 12. Open obligations carried to `07_DELIVERY.md` (must not evaporate)

Not defects — live contractual obligations I verified are still unmet at this stage:
**AC-6** restate the reload-sufficiency determination (`02` §7); **AC-7** the three exact commands
(immediate run, `reset-failed`, self-clearing condition, `02` §9); **AC-14** R-1 (weekly sing-box
restart, 00:00–01:00 local Monday), BC-7 (genuine `failed` on restricted networks), BC-11 (no
catch-up — **now qualified by D-1: no empirical support**); **C-1** both service-environment
residuals, with §9's new host evidence; **C-2** the uninstaller `reset-failed` follow-up row;
**C-5 remainder** the `sc update-interval`-to-a-shorter-cadence catch-up path and gate F-8's "within
minutes of the push" phrasing — `05_CODE_REVIEW.md` filed a MINOR because `04_DEVELOPMENT.md:401`
declares C-5 discharged while both clauses are still open, **still open, confirmed this stage**; and
**D-1, D-2, D-3** above.

---

## Verdict

**PASS — APPROVED FOR DELIVERY.** 0 BLOCKER · 0 CRITICAL · 0 MAJOR · 3 MINOR (all upstream
documentation/evidence accuracy, report-only) · 3 INFO/NIT.

Every acceptance criterion the developer owns was re-verified by a QA-authored reproducer, not by
re-running the developer's commands. The four claims stage 5 could only corroborate indirectly —
V-3's `1 insertion(+), 1 deletion(-)`, V-5's byte-unchanged boundary, V-6's `systemd-analyze`
discriminator, V-7's delta-0 gate — are all **re-executed and confirmed**, with V-7 measured against a
pristine `HEAD` tree I built myself and V-6 backed by five mutation controls proving the tool is not
vacuously passing. `verify_all` is PASS 16 / WARN 0 / FAIL 0 / SKIP 2, exit 0, delta 0. AC-11 holds:
the live system is byte-for-byte and PID-for-PID where it started; the failed-unit residue was not
"cleaned up"; the CLI was never executed or imported.

What this report does **not** prove — and no honest gate artifact in this task could — is the
end-to-end claim that the weekly timer now updates rulesets. Three of its four links are mechanically
evidenced here; the fourth, reload sufficiency, is argument, and the first triggered run is a
post-release observation. D-1 further removes the empirical backing design §8.2 promised for BC-11,
and D-2/D-3 show a real host (this one) where the corrected unit still would not run without the
installer's `enable`+`start`. None of that impugns the change: a one-line correction of a path that
has never once resolved is unambiguously right, verified against 11 agreeing in-repo sites and against
the tool that flags exactly this defect class. It does mean `07_DELIVERY.md` owes the reader precision
it does not yet have.

**Routing.** No defect goes back to the developer: nothing in the shipped diff is wrong. D-1 →
solution-architect (report-only), D-2/D-3 → delivery author, D-4 → T-07 gate design, D-5/D-6 → no
action. PM to file the follow-up rows for R-1, C-1 and C-2, and to carry §12's obligations into the
stage-7 dispatch.
