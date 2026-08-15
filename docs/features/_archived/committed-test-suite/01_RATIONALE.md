# T-28 · committed-test-suite — Rationale

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. Brief clauses checked against the code, and the four that did not survive

Every factual clause of the dispatch was read against the tree before being adopted. Four are
wrong as written; the requirement is specified against what is there.

**(a) "A suite full of realistic fixture credentials is the most likely thing in this pool to
trip A.1."** A.1's own pathspec is
`git grep -E … -- ':!*.md' ':!.harness/scripts/verify_all*' ':!.harness/*'`
(`verify_all.sh:33-34`, identically `verify_all.ps1:60`). The last exclusion is a git pathspec
whose `*` crosses `/`, so **everything under `.harness/` is excluded from A.1**, the suite
included once FR-1 places it there. The hazard is therefore not "A.1 fires"; it is that the
project's own secret gate is structurally blind to the directory holding its test artifacts, and
would only fire if a later task moved the suite. That is why BC-8/AC-22 bind the *content* and
AC-22 evaluates the regex **with the exclusions removed** — the requirement does not rest on the
exclusion it just discovered. Precedent that the threshold is real and already designed against:
`MASK = "******"`, six characters, "deliberately under `verify_all` A.1's 8-character threshold"
(`docs/dev-map.md:68`), and T-13's committed fixture credentials (`06_TEST_REPORT.md:490-508`)
are `203.0.113.7` / `example.invalid` / repeated-digit UUIDs.

**(b) "B.2's blind spot … a `bin/sc` suite is the natural place to close that."** R-7's second
blind spot (`docs/tasks-archive.md:238-244`) is a `t <key>` **call site in `install.sh`** naming a
key absent from both Bash tables: `t()` there declares `local fmt` with no default, so under
`set -u` the expansion error kills the installer and `|| true` cannot catch it. `bin/sc`'s `t()`
is `TRANSLATIONS.get(LANG, {}).get(s, s)` (`bin/sc:480-482`) — a missing key renders its own
English text, which `docs/dev-map.md`'s "Patterns to follow" calls the fallback **by design**, not
a gap. The two programs share no artifact and have opposite failure directions, and the filed
fix ("have the checker also extract `t <key>` call sites") is an edit to `check-i18n-parity.sh`,
i.e. exactly the silent widening of B.2 the same brief forbids. So R-7 stays open.

What *is* uncovered on the `bin/sc` side, and is checkable from the shipped table alone with no
call-site enumeration: `t()` runs `msg.format(**kwargs)` **only when kwargs are present**, and
`msg` is the `zh` string. A `zh` entry naming a placeholder its key does not name therefore raises
`KeyError` on a `zh` host at every call site that passes arguments. 89 keys carry placeholders.
`docs/dev-map.md`'s "Patterns to follow" states the same-placeholder-set rule as binding on every
new key, and **nothing enforces it**. That is FR-13. The reverse direction (a key with no `zh`
entry) is deliberately *not* asserted — it renders English by design, and asserting it would turn
FR-13 into the ~250-key parity gate this project has declined for `bin/sc` since T-11.

**(c) "R-85 (T-26): the AAAA position test has a silent failure mode."** R-85 is
`docs/tasks.md:265` — a `CHANGELOG.md` lead stating a direction where the fact is a bound, owned
by the next task editing that entry, wording only. The AAAA `[] == []` mode is **R-80**
(`docs/tasks.md:260`), also recorded as the accepted known cost in
`.harness/rejected-decisions.md § doctor-position-test-by-a-bare-head-slice`. The requirement
names R-80.

**(d) "R-71 … two criteria were reported NOT-DISCRIMINATING rather than passed."** R-71
(`docs/tasks.md:209`) reports **one**, QA-3, plus a related QA-4 about C-5's wording. The "two
criteria reported NOT-DISCRIMINATING" sentence belongs to the T-25 block
(`docs/tasks.md:230-231`). The substance of R-71 is unaffected and is discharged by FR-10/AC-11.

Two further clauses survive but needed sharpening. R-9's scope sentence says "populating
`baseline.json` (R-4)"; T-07's actual ruling (`PM_LOG.md:54-55`, Q-9) is that it stays at zero
because "nothing in the repo reads it and no assertion can run here" — so *populating* was never
the missing act, being *read* was, which is what Q-3 and FR-15 turn into a requirement. And
`docs/dev-map.md:83` says the wiring of `restricted-network-regression.sh` "is R-9's" without
saying which form; only `--self-check` is safe off a disposable VM (`:110-121`, `:140-146` return
before every refusal gate), so Q-11 splits the row rather than adopting or refusing it whole.

## 2. Evidence for the safety requirements

- The import-time re-exec is `bin/sc:125-126`: `if os.geteuid() != 0: os.execvp("sudo", ["sudo",
  "/usr/local/bin/sc"] + sys.argv[1:])` — the **installed** path, not the checkout's. Module level
  is otherwise inert: 18 stdlib imports, constants, two `shutil.which` calls (`:75-76`), and
  `if __name__ == "__main__"` at `:3791`, which a `types.ModuleType` load does not satisfy.
- `_init_files()` is `bin/sc:540-551`; `:543` is `Path("/var/lib/sing-box").mkdir(...)`, the one
  directory not built from a repointable constant. Its other two branches are a `save_nodes()`
  and a `save_settings()` call, which is why FR-3 loses nothing by refusing to drive it.
- The recipe FR-2 adopts is `docs/dev-map.md:121-158` and its executed form is T-13's `load_sc()`
  (`docs/features/_archived/config-write-permission-hardening/06_TEST_REPORT.md:456-476`),
  including the two post-conditions `sys.modules["os"] is real_os` and `mod.os is shim`. T-13's
  `point_at()` (`:532-544`) repoints only **five** constants — it predates `OVERRIDE_PATH`,
  `STATE_PATH` and `IF_INET6_PATH` — which is precisely why BC-2 requires the containment
  *assertion* over all eight rather than a checklist.
- The live near-miss is R-78 (`docs/tasks.md:241`): T-25 lost a round to a loader that re-exec'd
  `/usr/local/bin/sc` under password-less sudo, and its signature was an argparse usage error at
  exit 2 — not a warning. This is why FR-2 bans child execution outright rather than trusting a
  future author to remember, and why FR-19 puts the signature in the dev-map row.
- `sing-box check` accepts an empty tuic password (insight line 12), so no configuration-level
  assertion substitutes for the live handshake in operator obligation 3 — the suite makes no
  claim there.

## 3. Why these seven assertion groups, and what was weighed against them

Ruling by value, not by line count. The four contracts this batch shipped each replaced a
scattered defect with one seam and many call sites, which is what lets a 300-line file cover a
lot. Three of the four are covered; the fourth is structurally unreachable.

| candidate | verdict | why |
|---|---|---|
| `_userinfo()` (T-22) | in, FR-7 | pure, total, no fixture; five call sites; the defect it fixed emptied every tuic password. Highest assertions-per-line in the file. |
| `_write_private()` (T-13) | in, FR-8 | the credential contract; a regression is a silent permission leak. Needs only a temp dir and a `umask` bracket; T-13's `ac2_umask_0277` is the named precedent. |
| `_read_state()` (T-23) | in, FR-9 | one reader, 16 unguarded call sites; the UTF-16 refusal (insight line 16) is a one-fixture assertion with a known-good discriminator. |
| override envelope (T-24) | in, FR-10 | R-71 is addressed to this task by name and is the only filed row saying, in so many words, that a property holds *by construction only*. |
| `_redact()` (T-06) | in, FR-11 | not one of the four, admitted anyway: pure, zero fixture, and the only function in the file whose regression is a credential on the user's screen. Its fail-closed allow-list is exactly the property a test can hold and a reader cannot. |
| `_dns_overlay()` (T-26) | in, FR-12 | one assertion (`payload non-empty`) closes R-80's whole silent class. Cheapest row in the table. |
| `zh` placeholder subset | in, FR-13 | see §1(b); table-only, no call-site enumeration, ~18 lines. |
| output layer / stdout wrapper (T-25) | **out**, Q-8 | three independent blockers: `io.StringIO` presents no `.buffer` so the fixture silently tests the unwrapped stream (`docs/dev-map.md:78`); `main()` cannot run twice per process (insight line 25); every locale criterion needs `PYTHONUTF8=0` (insight line 14) in a child, and a child means executing `bin/sc` as a program. |
| `clash_api()` / `stored_delays()` | out | needs a socket peer, i.e. the mock server the sizing discipline forbids. `is_running()`'s init-less `False` (insight line 10) also makes a fixture agree on candidate and control unless `SYSTEMD` is forced. |
| `generate_config()` end-to-end / degradation | out | already covered at scenario level by `restricted-network-regression.sh`, whose blackout is the honest form; duplicating it in-process would be a second opinion about the same scenario. |
| `install.sh` coverage | out | B.1 and B.2 already gate it, and B.5 now gates the derivation that feeds its regression harness. |

## 4. Candidates weighed for each resolved question

**Q-1 (step id).** Candidates: repurpose B.3 (rejected — a lint SKIP is not a test step and the
brief, rule 50 and the standing "a permanently SKIPping check proves nothing" all name it);
extend B.2 (rejected — silently widens a real gate); a single new step covering both artifacts
(rejected — two subjects, one verdict, makes a failure ambiguous); **B.4 + B.5** (taken; B.4 is
already the id named in `.harness/rejected-decisions.md:89` as the unblock path).

**Q-3 (`baseline.json`).** Candidates: write the number and leave it decorative (rejected — this
is exactly the dishonesty the brief names, and T-07 refused it on the same ground); require exact
equality between `test_count` and the run's count (rejected — every future assertion added would
break the gate until the file was edited, so the gate would punish the good direction); **a floor**
(taken — monotone, so growth never breaks it, while deletion or a skipped group turns it red, and
`baseline.json` becomes the first file in the repository a program reads).

**Q-9 (non-vacuity).** Candidates: a committed `--prove` mode that mutates the subject (rejected —
that is a mutation framework living in the artifact, against the sizing discipline and against
T-07's one-file precedent); documented mutations replayed by hand at every future run (rejected —
not an artifact, so it decays immediately); **subject-as-parameter plus a stage-6 mutation sweep
recorded per assertion** (taken — one line in the artifact, the full R-22 proof at the stage that
owns it, and permanently repeatable by anyone who reads the report). The floor of FR-15 is the
committed residue: it cannot prove an assertion discriminates, but it does prove the suite still
runs the assertions it claims.

**Q-12 (the `.ps1` mirror).** Candidates: port the suite to PowerShell (rejected — a second
implementation of the same contract, and `os.geteuid` has no meaning there); leave B.4/B.5 absent
from the mirror (rejected — that is R-6 restated, the two mirrors disagreeing about what a `B.n`
is); **name the identical checks and SKIP with a stated reason** (taken — R-6's complaint is about
identity, not about results, and an honest SKIP is the same discipline as a BLOCKED criterion).

**Q-14 (`/var/lib/sing-box`).** Candidates: hoist it to a module constant so a fixture can drive
`_init_files()` (rejected — a product edit for a test's convenience, and FR-3 makes it unnecessary
since both branches are single calls the suite covers directly); leave it and say why (taken).
Worth recording for whoever picks up R-84: the trap is not that the literal exists, it is that
`main()`'s read-only arm is only `("doctor", "config")`, so `sc ls` and `sc ipv6` both reach it.

## 5. Sizing — how the cap was derived, and the bar it is measured against

R-61's lesson is about **provenance**: T-07's 250-line cap was a round number, was declared not
credible by its own gate, was approved unchanged, and shipped at 330 against a measured binding
floor of 267. So the cap here is a sum of an element list (contract, NFR section) rather than a
round number, and the requirement instructs a disbelieving gate to amend it.

Against the recent bar — T-27 shipped 8 executable added lines and deleted a designed table;
T-26 was net-negative on a row; T-25 added no new function; T-07 shipped one file with no
framework, no fixture library, no mock server, no runner and no new directory — 300 lines is
large for this pool. It is defended by the element list rather than by need: 128 of the 300 are
infrastructure that exists once (loader, fixture root, witness, runner, header), and the seven
assertion groups are 152 lines carrying, on the current draft, on the order of 45 assertions. The
alternative shapes were priced and rejected: a `tests/` package with one file per contract (seven
files, a discovery mechanism, a `.gitignore` edit); `unittest` (a dependency-free framework, but
it takes over process exit, name selection and reporting, and the summary line FR-15 needs would
have to be re-derived from its output); and a shell driver invoking a Python one-liner per
assertion (a child process per case, which FR-2 forbids for a reason).

## 6. Related historical work

Read in full and not re-described here; the requirement cites what binds.

- `docs/features/_archived/restricted-network-regression-test/` — T-07: the placement precedent,
  the six-condition `pair=` shape, the `[HOST]`/`[VM]` split, and the ruling that left
  `baseline.json` at zero.
- `docs/features/_archived/config-write-permission-hardening/` — T-13: `06_TEST_REPORT.md` §12
  carries the two harnesses verbatim (27 + 79 assertions) and is the artifact FR-2 builds from.
- `docs/features/_archived/share-url-userinfo-contract/06_RATIONALE.md` §"The harness, in full
  (RT-5 → T-28)" — T-22's four-file QA harness, preserved for this task; its driver contract is
  the differential shape AC-10 reuses at stage 6.
- `docs/features/_archived/state-file-io-contract/`, `override-error-envelope/`,
  `output-layer-contract/`, `doctor-rows-establish-their-fact/` — the four contracts under test,
  and the source of insight lines 14-22 and 25.
- `.harness/rejected-decisions.md § ruleset-unit-tests-in-t02` — five declines of this row, the
  structural reason T-13 gave (its AC-23 demanded zero delta in the `verify_all` counts, which any
  real step necessarily breaks), and the B.4 unblock path this task takes.
- `.harness/operator-obligations.md` rows 1-5 — the BLOCKED-and-file-a-row precedent, honoured
  eight times, that AC-10's NOT-DISCRIMINATING clause and out-of-scope 12 inherit.

## 7. Standing risks this requirement accepts

1. **The suite imports `bin/sc` on the owner's machine on every future `verify_all` run.** That is
   R-9's price and cannot be avoided while the assertions are about `bin/sc`'s functions. It is
   bounded by FR-2 (no child, no installed binary), BC-1 (no root), BC-2 (containment asserted,
   not remembered), BC-5 (host witness) and BC-16 (one stub child, no socket).
2. **FR-13 may fail on the delivered tree.** 89 keys carry placeholders and no gate has ever
   checked them. BC-11 bounds the repair at three translation-string edits before it becomes a
   re-homed row, so the discovery cannot silently grow into a translation task.
3. **B.4's floor creates a small standing obligation**: a task that deliberately removes an
   assertion must lower `test_count` in the same commit. This is intentional — it is the only
   place where deleting a test costs a visible edit.
4. **`/harness-upgrade` re-lands `verify_all.{sh,ps1}` by splice with a HALT and a `.bak`**
   (insight line 27), so BC-13's marker requirement is what makes the wiring survive; the suite
   itself is not in `refresh_set` and `baseline.json` is excluded from it as data.
