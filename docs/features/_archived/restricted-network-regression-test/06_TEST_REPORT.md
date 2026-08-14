# 06 — Test Report — restricted-network-regression-test (T-07)

> Contract portion. Rationale: 06_RATIONALE.md (absent = none written).

- **Task ID**: T-07 · **Mode**: full · **Date**: 2026-08-15 · Upstream verdict read:
  `APPROVED WITH RESIDUALS` (RES-2, RES-3, RES-4 owed here; GC-5 and GC-11 owed here).
- Schema note: `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule`
  (R-37, sixth occurrence; its sections remain What this is / When to read this / Caps / Process
  discipline / Adversarial check), so this portion carries the QA schema as written. Every
  transcript, the full reproducer sources and the measurement narrative are in `06_RATIONALE.md`.
  The `[VM]` recipe AC-19 owes an operator is `.harness/operator-obligations.md` row **2**, because
  a standing human step belongs there by this harness's own rule and no section of this schema can
  hold it.
- No rationale trigger fired for T6.1/T6.2/T6.3 reading: `01_RATIONALE.md`, `02_RATIONALE.md`,
  `04_RATIONALE.md` and `05_RATIONALE.md` are all present. Every developer measurement reproduced
  below was reproduced from the AC table and from the artifact's own behaviour, not from stage 4's
  transcripts (`04_RATIONALE.md` §8/§9 were deliberately left unread until after my own runs).

## Test plan

| Acceptance criterion | Test case(s) | File |
|---|---|---|
| AC-1 tracked, not ignored — **PASS** | `git ls-files -s` → `100755 aa8477f3…`; `git check-ignore -v` → no output, rc=1; `stat -c %a` → `755` | RES-2 half discharged; transcript `06_RATIONALE.md` §1 |
| AC-2 parses, counts unchanged — **PASS** | `bash -n` rc=0 (330 lines); `bash .harness/scripts/verify_all.sh` → `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, measured three times (pre-clone, clone-present, delivery) | `06_RATIONALE.md` §2, §11 |
| AC-3 no token ⇒ exit 2, no write, no network-config change — **PASS** | 4 argv forms from a fresh empty `cwd` + `TMPDIR`; both dirs empty after; `/etc/hosts` + `/etc/nsswitch.conf` + `/etc/resolv.conf` sha256 unchanged; 0 condition lines on stdout | `06_RATIONALE.md` §3 |
| AC-4 token + configured install ⇒ refuse before mutation — **PASS** | `--i-will-destroy-this-vm` as uid 1000 → `REFUSED:` naming `/etc/sing-box/nodes.json`, six `UNMET` lines, exit 3; every mutating call site (`:196`, `:206`, `:283`) proved to sit past gate 2 | `06_RATIONALE.md` §3, §4 |
| AC-5 self-check covered arm 0 / uncovered arm non-zero — **PASS** | `--self-check` → 4 bases, 6 hosts, exit 0; `--self-check --source f1_iplit.py` → exit 1 naming `https://127.0.0.1/geo`; 16 further scratch source files | `06_RATIONALE.md` §5, §6 |
| AC-6 E1 installer completes, banner, exit 0 — **BLOCKED** | needs a root run of `install.sh` on a disposable VM; not substituted | recipe R-1…R-4, `.harness/operator-obligations.md` row 2 |
| AC-7 E2 both units enabled, timer running — **BLOCKED** | needs systemd unit registration on a disposable VM | recipe R-1…R-4, row 2 |
| AC-8 E3 install log 0640 + four cause lines + aggregate + degradation — **BLOCKED** | needs `/var/log/sing-box/install.log` produced by a real run | recipe R-1…R-4, row 2 |
| AC-9 E4 config 0600, no rule-set, `sing-box check` 0 — **BLOCKED** | needs a generated `/etc/sing-box/config.json` and the installed binary | recipe R-1…R-4, row 2 |
| AC-10 E5 service active after install — **BLOCKED** | needs a started `sing-box` service on the scenario host | recipe R-1…R-4, row 2 |
| AC-11 E6 recovery via one `sc update-rules` — **BLOCKED** | needs `/usr/local/bin/sc` and egress on the scenario host | recipe R-1…R-4, row 2 |
| AC-12 every condition has a same-run counter-observation — **BLOCKED** | the twelve `obs=`/`pair=` fields exist only in a full-run report | recipe R-4, row 2 |
| AC-13 pre-populated rule-set dir ⇒ UNMET — **BLOCKED** | needs a second disposable VM prepared with `*.srs` present | recipe R-5, row 2 |
| AC-14 two dev-map rows — **PASS** | 18-element fixed-string checklist over the two added rows + 1 negative control | `06_RATIONALE.md` §8 |
| AC-15 operator guide, Chinese — **PASS** | guide heading at `:2`, preconditions 1-7, VM prep at `:16-19`, verbatim token at `:22`, single-use sentence at `:26-28` | `06_RATIONALE.md` §8 |
| AC-16 frozen product files byte-identical to HEAD — **PASS** | `git clone` (not a worktree, GC-11) into ignored `test/head-baseline`; sha256 per file for `install.sh`, `bin/sc`, `uninstall.sh`, `systemd/*` — 6/6 identical, with a one-byte negative control | `06_RATIONALE.md` §7 |
| AC-17 `baseline.json` unchanged — **PASS** | `cmp` against the clone, rc=0; content still `test_count: 0` per Q-9 | `06_RATIONALE.md` §7 |
| AC-18 live instance untouched — **PASS** | `systemctl show -p MainPID -p ActiveEnterTimestamp` identical at task start, across 10 stability runs and at delivery; `is-active` never invoked against this host | `06_RATIONALE.md` §10, §12 |
| AC-19 every `[VM]` criterion BLOCKED with reason, nothing substituted — **PASS** | this table's eight BLOCKED rows + the `## Adversarial tests` rows carry a reason and a named recipe, and no artifact reading is offered as evidence for any of them | this document; row 2 |
| AC-20 six status lines, exit derived — **PASS `[HOST]`** / **BLOCKED `[VM]`** | host half: refusal path prints exactly six `E<n> UNMET …` lines and exits 3; `finish()` exit derivation exercised directly for 6×PASS→0, one BLOCKED→1, one FAIL→1, forced→3. VM half needs a full run | `06_RATIONALE.md` §4, §9 · recipe R-4 |

## Adversarial tests

| AC | Hypothesis ("I expect failure when…") | Reproducer | Outcome (with tool output) |
|---|---|---|---|
| AC-1 | the file is tracked but recorded `100644`, so the operator's `bash …` works and `sudo ./…` does not | `git ls-files -s` + `git check-ignore -v` (NEW, mine) | Survived — `100755 aa8477f3f09237d6b6cdac5b50274497b6bfe0a4 0	.harness/scripts/restricted-network-regression.sh` and `check-ignore rc=1` |
| AC-2 | adding a 330-line file under `.harness/scripts/` moves an F.* cap or E.4 sync | `bash .harness/scripts/verify_all.sh` before the clone, with it, and at delivery | Survived — `PASS: 17 / WARN: 0 / FAIL: 0 / SKIP: 1`, all three times |
| AC-3 | `usage()`'s here-document or an early `mktemp` leaves a file, so "writes nothing" is false | 4 argv forms with `cwd` and `TMPDIR` set to fresh empty dirs (NEW, mine) | Survived — `cwd contents: [] / TMPDIR contents: []`; control writer proves the predicate discriminates: `after a deliberate writer: cwd=[decoy] TMPDIR=[decoy2]` |
| AC-4 | a near-miss argv (case, trailing space, glob) slips past `case "$TOKEN")` and reaches the scenario on this live host | 10 near-miss argv forms + exact-token control (NEW, mine) | Survived — every near-miss `exit=2 stdout_lines=0`; only `argv=[--i-will-destroy-this-vm] exit=3` reaches gate 2: `REFUSED: a configured installation is present: /etc/sing-box/nodes.json` |
| AC-5 | the coverage guard is decorative: an IP-literal base still exits 0 | `--self-check --source f1_iplit.py` (NEW, mine, built from the AC text not from stage 4) | Survived — `SELF-CHECK FAIL: uncoverable base(s): https://127.0.0.1/geo` / `>>> exit=1`; also `localhost`, `:8443`, `[2001:db8::1]`, empty host all exit 1 |
| AC-5 | `--self-check` exits 0 on a source it never really parsed | empty block / no block / unreadable / directory / missing file (NEW, mine) | Survived — `SELF-CHECK FAIL: no base parsed from …f2_empty.py` (exit 1); unreadable → `sed: can't read …: Permission denied` then the same FAIL |
| AC-5 | exit 0 hides an under-matching derivation (F-6) — **it does** | `--self-check --source f5_three.py` (3 bases only) | **Confirmed unrepaired, as designed** — `SELF-CHECK OK: 3 shipped base(s), all covered` / `exit=0`. Exit 0 is not a guard; the printed list is. Hence the row below |
| AC-5 · **GC-5 / RES-3** | the four printed URLs differ from `bin/sc:113-118` in one byte and nobody notices | `python3 ast.literal_eval` of `bin/sc` lines 113-118 (an *independent* parser, not the artifact's `sed`+`grep`) then `cmp` against transcript lines 2-5 | Survived — `cmp rc=0 : BYTE-IDENTICAL, 4 of 4`; both sides `f1f66d7d857ee9a1…`. Negative controls: one-byte edit → `differ: byte 79, line 2`; one line dropped → `EOF … after byte 217, line 3` |
| AC-6 | E1 reports PASS on a healthy (unblocked) install because `step6_warn` never fired | none — needs a root `install.sh` run on a disposable systemd VM | **BLOCKED** — no VM/container runtime usable here (`docker` needs sudo; `podman`/`nspawn`/`qemu`/`vagrant` absent; LXD uninitialised; `bwrap --unshare-net` EPERMs), no interactive sudo credential, and the artifact refuses on this host at K-3 gate 2. Recipe R-1…R-4. No inspection substituted |
| AC-7 | `systemctl enable` succeeds but the timer is not `active`, and E2 passes anyway | none — needs unit registration on a disposable VM | **BLOCKED**, same reason. Recipe R-1…R-4 |
| AC-8 | E3 counts base 4 on a log that only ever named base 3 (the D-3 suffix trap), so a 3-of-4 blackout reads PASS | `qa_units.sh` U5 (NEW, mine): synthetic 3-of-4 log built from `bin/sc`'s own strings, both matchers replayed | **Partly discharged at unit level, condition still BLOCKED** — `substring form (the trap) counts = 4` vs `shipped entry-boundary form counts = 3`; `E3 with shipped matcher on a 3-of-4 log = FAIL`, `E3 with substring matcher on the same log = PASS`. The real log needs a VM. Recipe R-1…R-4 |
| AC-9 | E4's five clauses pass on a document that is not the degraded one | `qa_units.sh` U4 (NEW, mine): `cfg_facts` + E4 conjunction over degraded / recovered / unparsable / absent | **Partly discharged at unit level, condition still BLOCKED** — `E4(cfg_degraded …) -> PASS`, `E4(cfg_recovered …) -> FAIL`, `E4(cfg_broken …) -> FAIL`; `cfg_facts unparsable = defs=?;route_refs=?;dns_refs=?`. The real file needs a VM. Recipe R-1…R-4 |
| AC-10 | E5 reports PASS on a crash-looping service (the RES-4(a) residual) | none — needs a live `sing-box` unit on a disposable VM; probing this host's unit with `is-active` is a red line | **BLOCKED**, and the residual is explicitly carried to the operator: recipe R-4 reading (a) tells them to read `NRestarts` against an `E5 PASS` |
| AC-11 | E6 passes on the degraded document because `dns_refs>=0` was left unfixed (F-2/GC-3) | `qa_units.sh` U4 (NEW, mine): E6 conjunction replayed over all three documents | **Partly discharged at unit level, condition still BLOCKED** — `E6(cfg_degraded) -> FAIL`, `E6(cfg_recovered) -> PASS`, `E6(cfg_broken) -> FAIL`. GC-3 holds. The real recovery needs a VM. Recipe R-1…R-4 |
| AC-12 | a `pair=` field restates the assertion instead of carrying a value from the run | none — the twelve fields only exist in a full-run report | **BLOCKED**. CR-13's inverse hazard (E3/E4 reading BLOCKED where their own observation is already falsified) is carried to the operator as recipe R-4 reading (b) |
| AC-13 | a pre-populated `/etc/sing-box/rules/` still runs the installer | none — needs a second disposable VM | **BLOCKED**. Recipe R-5 |
| AC-14 | a row is present but one contract element (e.g. `[ -t 2 ]`, `0x0D`, `never inline flags`) is missing | 19-entry `grep -cF` checklist over the two added rows (NEW, mine) | Survived — 18/18 elements `present`; control `THIS-STRING-IS-NOT-IN-THE-ROWS  *** ABSENT ***` |
| AC-15 | the guide omits the verbatim token or the single-use sentence | line-addressed reads of `:1-29` (NEW, mine) | Survived — `22:#   sudo bash /root/singbox-cli/.harness/scripts/restricted-network-regression.sh --i-will-destroy-this-vm`; preconditions 1-7 at `:8-14`; single-use at `:26-28` |
| AC-16 · **GC-11** | a `git worktree` is used, `verify_all` A.1/A.2 turn SKIP and the summary falsely reads 14/4 | `git clone --no-hardlinks` into ignored `test/head-baseline` (NEW, mine), then `find` over all three `verify_all` roots | Survived — `directory /home/alan/Programs/singbox-cli/test/head-baseline/.git` (a directory, not a file); `root=.harness/agents -> 0 hits`, `root=.harness/rules -> 0 hits`, `root=docs/features -> 0 hits`; counts read only after that |
| AC-16 | a frozen file drifted by one byte and a coarse comparison misses it | per-file `sha256sum` both sides + `cmp` negative control | Survived — 6/6 `IDENTICAL`; control (one appended newline to a *copy*) → `cmp: EOF on test/head-baseline/install.sh after byte 29217, line 615` `rc=1` |
| AC-17 | `baseline.json` was bumped to make a count look better | `cmp .harness/scripts/baseline.json test/head-baseline/…` | Survived — `cmp rc=0`; file still carries `"test_count": 0` |
| AC-18 | some step of this stage restarted or re-read the live service | `systemctl show -p MainPID -p ActiveEnterTimestamp` at start, in each of 10 stability runs, and at delivery | Survived — `MainPID=2566751` / `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` at every one of the 12 sample points; `/etc/hosts` sha256 `2f3a6061…dcdf70` unchanged throughout |
| AC-19 | an artifact reading is quietly substituted for a `[VM]` run somewhere in this report | self-audit of every BLOCKED row against Q-15 | Survived — the three unit-level rows (AC-8/9/11) are labelled *partly discharged at unit level, condition still BLOCKED*, and none of the eight `[VM]` criteria is given a PASS |
| AC-20 | the six-line report can print fewer than six lines, or exit 0 with a non-PASS line | `finish()`/`unmet_all()` driven directly with a synthetic `E` array (NEW, mine) + the live refusal path | Survived — `six PASS -> exit = 0`, `one BLOCKED -> exit = 1`, `one FAIL -> exit = 1`, `forced refusal -> exit = 3`, `refusal prints condition lines = 6`; the live refusal path printed 6 lines and exited 3 |
| — (10th-vacuity hunt) | the coverage predicate reports "covered" for an authority `/etc/hosts` cannot map | `--self-check --source f6b_userinfo.py` (NEW, mine) + `urllib.parse` | **FOUND, filed D6-1 (MINOR)** — `SELF-CHECK OK: 1 shipped base(s), all covered` while the sunk name is `u@cdn.example` and `hostname = cdn.example` / `equal? = False` |

## Boundary tests added

- Empty argv, trailing-space argv, leading-space argv, uppercase argv, one-character-short argv, one-character-long argv, glob-metacharacter argv, token-plus-extra argv — 10 forms, all exit 2.
- Source file with an IPv4 literal base, with `localhost`, with a port-bearing authority, with a bracketed IPv6 literal, with an empty host — all exit 1 naming the entry.
- Source file with an empty `RULESET_BASES` block, with no block at all, unreadable (mode 000), a directory, a non-existent path, `--source` with no value — all refused (exit 1, or exit 2 for the missing value).
- Source file with CRLF line endings, with a non-ASCII (U+00E9) host, with duplicate bases, with a glob metacharacter in the base, with a single-quoted entry, with an unterminated block.
- `cfg_facts` over a degraded document, a recovered document, an unparsable document and an absent file; `val()` over the `?` triple.
- `finish()` over 6×PASS, one BLOCKED, one FAIL and a forced status; `unmet_all()` over an already-composed `E` array (CR-15 replay).
- Concurrency is out of the artifact's surface — it is a single-shot script with no shared state and no lock; the ten repeat runs in `## Stability` are the closest available analogue.

## verify_all result

- Total tests: 18 checks → 18 checks (unchanged; this project's suite is `verify_all` itself)
- Pass: 17
- Fail: 0
- Warn: 0
- Skip: 1 (B.3 Lint — no lint config committed; unchanged)
- Invocation: `bash .harness/scripts/verify_all.sh` (no extensionless dispatcher on this host)
- New tests added: 0 committed. 63 host observations were recorded across 6 reproducer scripts and 17 scratch fixtures; none could be committed — `02_SOLUTION_DESIGN.md`'s change ledger admits no new file, `.gitignore:19` ignores `test/`, and K-13 forbids wiring anything into `verify_all` (R-9 owns it). Their full source is transcribed into `06_RATIONALE.md` §13 so the T-02/T-08 loss of scratchpad-only harnesses is not repeated.
- Baseline updated: **no** — AC-17 binds `baseline.json` to byte-unchanged and Q-9 resolves `test_count` to stay `0` until a runnable suite exists. Recorded as a judgment call under the owner's standing grant; the baseline is not lowered, only held.
- F.4 headroom at measurement: `.harness/insight-index.md` = 30 / 30 lines. F.5: `docs/tasks.md` = 300 / 300. Both at their cap — GC-8 is delivery's, and one harvested insight or board row will turn `WARN 0` into `WARN 1`.

## Defects found

| id | severity | reproducer | file:line |
|---|---|---|---|
| D6-1 | MINOR | `bash .harness/scripts/restricted-network-regression.sh --self-check --source <file whose block holds "https://u@cdn.example/geo">` → `SELF-CHECK OK: 1 shipped base(s), all covered`, exit 0. `uncoverable()` rejects an empty host, `localhost`, an IP literal and a port-bearing authority but accepts a **userinfo**-bearing one, so the name it would sink in `/etc/hosts` (`u@cdn.example`) is not the name any fetcher resolves (`urllib.parse` → `hostname = cdn.example`). I-7 designates this predicate the single home of FR-3 coverage and BC-2, so it reports coverage for a base it cannot cover. Not reachable with the four bases at HEAD; on a VM the I-9 resolver proof would most likely fail closed to `UNMET`, which is why this is MINOR and not MAJOR. One `\|*@*` alternative in the `case` closes it. | `.harness/scripts/restricted-network-regression.sh:92` |
| D6-2 | NIT | `--source <file whose closing ")" is indented, followed by any later URL>` → the `sed` range `/^RULESET_BASES = (/,/^)/` never closes, sed runs to EOF and the derivation adopts unrelated URLs: observed `derived bases (2): https://a.example/geo` + `https://sneaky.example/geo`, `SELF-CHECK OK`. Harmless for `bin/sc` at HEAD (`:118` is a bare `)`), reachable only through `--source`. | `.harness/scripts/restricted-network-regression.sh:88` |
| D6-3 | NIT | `--source <file using single-quoted entries>` → `grep -oE 'https?://[^"]+'` overruns the closing delimiter and yields `https://single.example/geo',`. The *host* survives (`host_of` cuts at the first `/`) so the blackout would still be right, but E3's per-entry `failed: <base> -> ` match could never fire for that base. Reachable only through `--source`. | `.harness/scripts/restricted-network-regression.sh:88` |
| D6-4 | NIT | `grep -nP '[\x{4E00}-\x{9FFF}]' .harness/scripts/restricted-network-regression.sh` returns exactly one line below the guide block: `:31`, whose text is *"# of this file can collide with `bin/sc`'s load-bearing `失败：` grep."* — the sentence asserting the property is the file's only counter-example to it. Harmless in fact (a comment never enters any stream `bin/sc` greps; `bin/sc:213` greps runtime output), but I-15's "it is the only Chinese in the file" and `05_CODE_REVIEW.md`'s design-fidelity row *"everything below `:30` English"* are both false as written. Fix is to reword the comment, not the code. | `.harness/scripts/restricted-network-regression.sh:30-31` |

No BLOCKER, no CRITICAL, no MAJOR. Nothing here fails an acceptance criterion, and none of the four
is reachable with the four bases `bin/sc` ships at HEAD.

Owed-but-not-defects, carried to the first real `[VM]` transcript (RES-4, restated here so the
operator obligation is self-contained): (a) E5's 1 s sampler cannot see a crash loop whose cycle
exceeds ~2 s, so an `E5 PASS` must be read against `systemctl show -p NRestarts sing-box`;
(b) CR-13 — `rblock` is evaluated before E3's and E4's own verdicts, so on a no-egress VM a genuine
product failure, including the `E3 FAIL` BC-10 mandates, reports `BLOCKED`; (c) CR-4's ruling that
`unknown` / `absent` / `?` past gate 4 are product failures deserving `FAIL` rather than `BLOCKED`
is untested until a run produces one. A fourth, found here: E3's `nfail -eq 4` is an exact equality
over the **whole** append-only `install.log`, so any second `failed: ` line from an unrelated `sc`
invocation makes E3 `FAIL` — fail-closed, but the operator should expect it on a re-used host.

## Stability

- The full `[HOST]` set — usage path, refusal path, both self-check arms, two scratch-source arms and the 24-assertion unit suite — was run **10 times**. All 10 runs produced a byte-identical signature (exit statuses `2|3|0|1|1|0`, output digests `cebe74b8|1629c103|69343bf0`, `pass=24 fail=0`). No flakes observed.
- `cwd` and `TMPDIR` were empty after every one of the 10 runs; `/etc/hosts` sha256 was `2f3a6061…dcdf70` after every one.
- The live-service witness was sampled inside each of the 10 runs and was identical every time.
- Timing sanity: `--self-check` 0.010 s, the refusal path 0.003 s. The artifact's only two `sleep` sites (`:260`, `:286`, 15 s total) are past gate 4 and therefore unreachable on this host, so the ≤30 s NFR has no `[HOST]`-measurable component.
- Left behind: nothing of mine. The `test/head-baseline` clone was removed after the counts were read; `test/` itself was **not** removed because it pre-existed this task with `test/step7` and `test/t20` from earlier work. All reproducers and fixtures live in the session scratchpad and are transcribed in `06_RATIONALE.md` §5, §6, §9, §10.

## Verdict

APPROVED FOR DELIVERY
