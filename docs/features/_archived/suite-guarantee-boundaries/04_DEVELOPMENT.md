# 04 — Development · T-31 `suite-guarantee-boundaries`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

1. `load()` gained a second, non-enumerated half of the process denial — `subprocess.Popen`
   displaced on the real module for the `exec()` window and restored in the **same** `finally` as the
   `os` shim, against a real `Popen` captured at **import** (`REAL_POPEN`) so no reordering of
   `load()` can make the restoration assert itself — and the suite gained one source clause,
   `config_json_is_installed_by_the_one_writer`, the first and only enforcement T-13's one-writer
   invariant has ever had.
2. `verify_all` gained `floor_of()` — one definition of how a floor is read, and of what a floor
   **is**: one number, so an unusable `test_count` reads as no floor instead of dying inside `(( ))`
   and falling through to a PASS — and step **B.6**, which makes `baseline.json`'s ratchet enforced
   against `git show HEAD:` instead of conventional.
3. Everything else this task closes is a **sentence**: the suite's header, `docs/dev-map.md`'s
   recipe bullet, `baseline.json`'s `notes` and two `rejected-decisions.md` records now say what is
   guaranteed, what is merely written, and — for four route families (one of which is open **today**,
   not prospectively), the **assertion phase** and four clause residuals — what is open, in the same
   words in both claim-surface texts. Half (a)'s completeness claim is scoped twice: to POSIX, and to
   the **public** spellings.

## Files changed

| path | what changed | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | `load()`: displace `subprocess.Popen` above the existing `sys.modules["os"] = shim` (`:222-223`), restore it in the one `finally` (`:233`), extend the post-`finally` leak check to it (`:234`); the real `Popen` is captured **at import**, `REAL_POPEN` (`:161`), never inside `load()`, so the restore-and-assert pair cannot be poisoned by a statement reorder; `_no_new_process`'s message generalised to name the attempt and offer **two possible** causes (`:182-184`) | E-1 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | new assertion `config_json_is_installed_by_the_one_writer` (`:587-627`), placed immediately after `every_file_read_and_write_names_utf8`; `TESTS` row inserted directly after that same name (`:854`). Defined count 18 → 19 | E-2 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/check-sc-contracts.py` | header: `NEUTRALISATION` block rewritten around the two halves (half (a) scoped to POSIX **and to the public spellings**), the four open route families (family **(ii)** carries the `dir(os)` enumeration and the two private-helper measurements), the assertion phase and the "what this is, said plainly" limit (`:12-98`); new block `WHAT THESE ASSERTIONS DO NOT REACH` (`:105-133`) | E-3 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` | `floor_of()` (`:90-93`, comment `:79-89`) — one reader, which now also decides **what a floor is**: a value that is not one run of digits is emitted as empty; B.4's inline `sed` rewritten to call it (`:99`) and its comparison base-10-pinned (`:106`); new step **B.6** after B.5 (comment `:116-124`, branch `:125-134`) — all inside the `HARNESS:B-CUSTOM` markers | E-4 |
| `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | `test_count` 18 → 19, `passing_count` 18 → 19, `notes` gains B.6's clause, BC-4's declared blind spot, B.4's unreadable-`test_count` FAIL condition, and the marking that no committed step reads `passing_count` or `warnings_baseline` | E-5 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | recipe bullet (`:128-267`): the two falsified sentences corrected in place, the same claims as the header added — two halves with half (a) doubly scoped, four open route families (`posix` named as the cheapest; **(ii)** carrying the enumeration and the two measurements), the assertion-phase paragraph that the header also carries, and the three "does not reach" limits appended at the bullet's end. Half (b)'s instruction now says **where** to capture the real `Popen` (at import, not below the displacement) and what a capture in the wrong place costs — the suite's own DEF-2 hazard, written where a future harness author meets it | E-6 |
| `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | `candidate-installed-by-os-replace-instead-of-the-one-writer`'s closing sentences amended (the ruling is made, the record is no longer the enforcement); one new record `denying-the-non-os-process-routes-by-a-wider-name-enumeration` appended, whose "also declined" clause now names `os._execvpe` / `os._spawnvef` explicitly and gives the measured ground (`os.path.os._execvpe` escapes anyway, so a name denies a spelling and not the capability) | E-7 |

Not touched, verified: `bin/sc` (`sha256` re-checked below), `verify_all.ps1`, B.3, B.5,
`check-sc-contracts.py`'s prefix tuple (`:216`, byte-identical), `archive-task.sh`, `guard-rm.sh`,
`.claude/`, `CLAUDE.md`, `.github/copilot-instructions.md`, `docs/tasks.md` (E-8 is the PM's).

## verify_all result

```
baseline (task start, before any edit) : PASS 19 / WARN 0 / FAIL 0 / SKIP 1, exit 0
after  (delivered tree, all edits in)  : PASS 20 / WARN 0 / FAIL 0 / SKIP 1, exit 0
delta                                  : +1 PASS (the new B.6); 0 new FAIL, 0 new WARN, SKIP unchanged
the one SKIP                           : B.3 Lint — the standing SKIP, untouched
B.4                                    : PASS — summary: 19 defined, 19 run, 19 passed
B.6                                    : PASS — tree test_count 19 vs HEAD 18
verify_all PASSED                      : yes, exit 0 — stated explicitly, this is the declare-done gate
verify_all stderr                      : empty. B.4's and B.6's reads of baseline.json put 2>/dev/null BEFORE the `<`, so a failed redirection is reported onto an already-silenced stderr; measured with the file absent in a scratch clone — 0 leaked lines, against 2 with the redirections in the other order, and byte-identical stdout both ways
bin/sc sha256 at task start            : 81d65da83ba23808c1f09ce81c94e067449eac698db7c625d67b775dbd31b312
bin/sc sha256 at delivery (AC-10)      : 81d65da83ba23808c1f09ce81c94e067449eac698db7c625d67b775dbd31b312 — identical
suite mode                             : 0755, unchanged; no import added; Python 3.6 syntax floor kept
host witness at start                  : MainPID=2566751 NRestarts=0 ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
host witness at end                    : MainPID=2566751 NRestarts=0 ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST — unchanged
/etc/sing-box entries at end           : config.json, config.json.bak-2026-08-01-1001, .config.sha256, nodes.json, rules/, settings.json — unchanged; nothing written there or under /var/lib/sing-box
git status --short (delivered)         : M on exactly the five intended files, plus the three that were ALREADY modified at task start (CONTEXT.md, docs/batches/closeout/BATCH_LOG.md, docs/batches/closeout/BATCH_PLAN.md) and ?? docs/features/suite-guarantee-boundaries/. Nothing else moved.
NFR-1 (V-11) over a B.4 run            : execve 1 (the interpreter itself), clone 0, clone3 0, fork 0, vfork 0 — strace -f, delivered suite, 19/19/19
dir(os) audit (half (a)'s scope)       : 402 names on CPython 3.12.3 linux; the tuple matches 22; of the 380 it does not, exactly TWO start or replace a process — os._execvpe and os._spawnvef. Every other unmatched name with a process-ish stem is a constant, a type, a module, a signal/wait wrapper, or _exit (which ends this process, starts none). No PUBLIC process-start spelling is unmatched, which is what makes the scoped sentence true rather than convenient
the two private helpers, measured      : subject `os._execvpe('/usr/bin/touch', [...])` -> marker PRESENT, exit 0, NO summary — the loading interpreter was replaced; `os._spawnvef(P_WAIT, ..., func=os.execv)` -> marker ABSENT, exit 1, but strace over the run shows execve 1 CLONE 1: it forked before the child's exec was refused. Control in the same sweep: `os.execvp` -> exit 2, marker ABSENT, LoadRefused. Named open in family (ii) of both texts
whether adding the names would help    : no, measured — `os.path.os._execvpe(...)`, the same helper one attribute hop away through family (iv), also replaced the interpreter (marker PRESENT, exit 0). A name added to the tuple denies a spelling, not the capability
half (b) after E-1's re-shaping        : all seven documented subprocess entry points re-swept against the delivered suite — call / Popen().wait() / run / check_call / check_output / getoutput / getstatusoutput, each exit 2, marker ABSENT, LoadRefused. posix.system unchanged and open, as named
Popen after a successful load()        : `<class 'subprocess.Popen'>` — the real one. With the restore deleted from the finally the post-`finally` clause raises `LoadRefused: a displacement made by the load did not survive its finally`, measured
B.6 no longer fails open               : baseline.json carrying a SECOND unescaped "test_count" — delivered: `[B.6] ... SKIP` + exactly one `comparison NOT performed` line, stderr 0, B.6 contributes no FAIL. The same state against the round-3 spelling of those two lines: `[B.6] ... PASS` with `((: 3 / 19: syntax error in expression` on stderr. Leading-zero floor 018 vs 19 — delivered `[B.6] ... FAIL` naming both numbers; round-3 spelling `PASS` with `value too great for base`
BC-2 still intact after that fix       : all four shapes (no .git; .git as a FILE; baseline.json absent in the tree; absent at HEAD) give `[B.6] ... SKIP` plus EXACTLY ONE printed line, and B.6 adds no FAIL to any of the four
```

### C-10 — the two numbers

Raw `git diff --numstat` (insertions / deletions), per file:

```
67  5   .harness/rejected-decisions.md      (prose)
 3  3   .harness/scripts/baseline.json      (2 data lines + 1 notes line, all rewrites)
175 19  .harness/scripts/check-sc-contracts.py
38  2   .harness/scripts/verify_all.sh
91  4   docs/dev-map.md                     (prose)
```

Net **executable** lines, docstrings / comments / prose excluded, itemised over the gate's element
list. A rewritten line counts 0; only lines that did not exist before count. Taken twice: by hand
per element, and mechanically from a `-U0` diff against `HEAD` that classifies every `+`/`-` line by
its position (the module docstring and every `#` line excluded) — the two agree.

| element | gate's re-derivation | delivered | what the lines are |
|---|---|---|---|
| E-1 denial | 4 | **3** | `REAL_POPEN = subprocess.Popen` at module scope (`:161`), `subprocess.Popen = _no_new_process` (`:222`), `subprocess.Popen = REAL_POPEN` in the `finally` (`:233`). The leak-check clause and its `raise` are **rewrites** of the old `os`-only check, and `_no_new_process`'s message is a 3-line rewrite — 0 net each. Moving the capture out of `load()` cost 0: one line left the function, one entered the module. |
| E-2 clause + registry row | 13 | **14** | 13 body lines + the `def`; the `TESTS` row cost **0** — the two existing tuple lines were re-wrapped to hold the new name (`-2 / +2`). |
| E-4 `floor_of()` + B.6 | 12–15 | **14** | `floor_of()` **4** (`:90` `def`, `:91` `local v; v=$(sed …)`, `:92` the one-run-of-digits test, `:93` `}`); B.4's read (`:99`) and its `10#`-pinned comparison (`:106`) are rewrites, 0; B.6 **10** (`:125-134`: `b6_now`, `b6_was`, `if`, `step` SKIP, `echo`, `elif`, `step` FAIL, `else`, `step` PASS, `fi`). The redirection order inside `:99` / `:125` and the comment lines at `:79-89` / `:116-124` are 0 net executable. |
| E-5 floor edit | 2 | **2 changed data lines, 0 net added** | `test_count` and `passing_count` are rewrites; `notes` is prose. |
| E-3 / E-6 / E-7 | 0 | **0** | prose only. |
| **total** | **31–34** | **31 net added (33 counting E-5's two changed data lines)** | Inside the gate's derivation and well under NFR-2's cap of **40**, which stands unamended. The one line above round 3's count is `floor_of()`'s shape test. |

### C-2 — the real-`os` attribute-chain family, before and after E-1

Scratch subjects under the run's scratch directory, marker files only, never `bin/sc` and never
`/usr/local/bin/sc` (BC-7). Host CPython **3.12.3**, `subprocess._USE_POSIX_SPAWN` **True**. Full
transcripts: `04_RATIONALE.md`.

| variant | instant | exit | marker | `os restored` line | summary |
|---|---|---|---|---|---|
| (a) `os.path.os.system("/usr/bin/touch <scratch>/escaped-realos-path")` | **before E-1** | 1 | **PRESENT** | not printed — see the note below | `summary: 18 defined, 18 run, 0 passed` |
| (a) same | **after E-1** | 1 | **PRESENT** | not printed | `summary: 19 defined, 19 run, 0 passed` |
| (b) `subprocess.os.system("/usr/bin/touch <scratch>/escaped-realos-subprocess")` | **before E-1** | 1 | **PRESENT** | not printed | `summary: 18 defined, 18 run, 0 passed` |
| (b) same | **after E-1** | 1 | **PRESENT** | not printed | `summary: 19 defined, 19 run, 0 passed` |

Both subjects are guarded by `if os.getuid() != 0:` — the uid source the `geteuid` shim does not
neutralise — exactly as C-2 specifies.

**About the missing `os restored` line, stated rather than glossed:** the suite prints it *only* on
the load-or-fixture failure path (`check-sc-contracts.py:868`). These four runs are escapes: the
load **succeeded**, so no such line exists to quote. The equivalent fact is available from a
different observation, and it is the stronger one — the post-`finally` leak check (`:234-235`) did
not raise on any of the four, so both displacements were in fact restored. This is a property of the
suite's output protocol, not a gap in the reading, and it means a criterion written as "quote the
`os restored` line" cannot be satisfied by an escaping variant at all.

**Reading, and what C-1's clause therefore says:** the family is open, and stayed open across E-1 —
marker **present** both times, on both variants. C-1's clause in both claim-surface texts is
written to that reading (family named **open**, with the measurement quoted), not to an
expectation. It appears as route family **(iv)** in `check-sc-contracts.py:69-75` and in
`docs/dev-map.md:180-185`.

### The `posix` route — the cheapest open member of family (i), measured before it was named

`import posix; posix.system("/usr/bin/touch <scratch>/escaped-posix-system")` from a scratch
subject's own import, run against the **delivered** suite (`--source` at the scratch subject, marker
target, never `bin/sc` and never `/usr/local/bin/sc`): marker **PRESENT**, `19 defined, 19 run, 0
passed`, no `LoadRefused`. The route is **open** and is the cheapest member of family (i) — it needs
no attribute chain and no `ctypes`. The mechanism, probed separately: `posix.system is os.system` is
`True`, and `load()` replaces `sys.modules["os"]` only, never `sys.modules["posix"]`. Named in both
claim-surface texts (`check-sc-contracts.py:45-50`, `docs/dev-map.md:160-166`) as family (i)'s
first-listed member.

### V-1 — the flip E-1 buys, and the two routes it does not

Same probe protocol, delivered tree (19 defined).

| variant | before E-1 | after E-1 (delivered) |
|---|---|---|
| `subprocess.call([...])` | exit 1, marker **PRESENT**, `18 defined, 18 run, 0 passed` | exit **2**, marker **ABSENT**, `LoadRefused: a process start or replacement during load (first argument: (['/usr/bin/touch', '<scratch>/…'],)) -- perhaps an elevate guard reading a uid the geteuid shim misses, perhaps another process API this load denies`, `os restored  True`, `19 defined, 0 run, 0 passed` |
| `subprocess.Popen([...]).wait()` | exit 1, marker **PRESENT** | exit **2**, marker **ABSENT**, `os restored  True`, `19 defined, 0 run, 0 passed` |
| `subprocess.run([...])` | exit 1, marker **PRESENT** | exit **2**, marker **ABSENT**, `os restored  True`, `19 defined, 0 run, 0 passed` |
| `ctypes.CDLL(None).system(b"…")` | exit 1, marker **PRESENT** | exit 1, marker **PRESENT** — unchanged, and named open (K-8 i) |
| `os.posix_spawn(...)` (**control**) | exit 2, marker **ABSENT**, refused | exit 2, marker **ABSENT**, refused — unchanged |

M-1's inherited readings are reproduced exactly; nothing in them needed refuting.

### C-9 — the floor control at both instants, both numbers

| instant | tree `test_count` | `git show HEAD:` `test_count` | B.6 | who took it |
|---|---|---|---|---|
| **pre-commit** (this delivery, the discriminating instant) | **19** | **18** | `[B.6] Assertion floor never below its last committed value ... PASS` | stage 4, in the real repository |
| **post-commit** | 19 | 19 | **owed** — it is the PM's at delivery, after the commit exists | PM at stage 7 |

The post-commit reading is **not** claimed here. A scratch clone with 19 committed was used to
pre-exercise that path and reported `[B.6] … PASS`, but that is a scratch-clone observation, not the
delivery instant; the real 19-vs-19 reading remains owed. Two further branch controls were taken in
the same scratch clone, since a control nobody has seen execute is not a control: floor lowered 19 →
18 with 19 committed gives `[B.6] … FAIL` with detail `test_count is 18 in
.harness/scripts/baseline.json and 19 at HEAD — the floor only goes up` (B.4 unaffected, still
PASS); `.git` absent, and `.git` present as a *file* (Q-F's worktree shape), each give `[B.6] … SKIP`
plus `      comparison NOT performed: no single readable test_count in the working tree or at HEAD`, with
`FAIL: 0` for the run. AC-4 / AC-6 remain stage 6's to take independently.

### M-4 — the one-writer clause against the mutant shapes (C-7)

`--source` driven at scratch copies of `bin/sc`; `bin/sc` itself only read.

| subject | verdict |
|---|---|
| task-start `bin/sc` (control) | **PASS** — `generate_config() installs config.json through _write_private(CFG_PATH, ...) at line(s) 2202` |
| `mut-res9-os-replace` (`os.replace(name, str(CFG_PATH))` for the second write) | **FAIL** — the discriminator; this is the mutant T-30 measured green over 13 cases |
| `_write_private(path=CFG_PATH, text=text)` (keyword-spelled) | **FAIL** — a **known red of the clause**, not a defect of `bin/sc` (C-7's third case) |
| `dest = CFG_PATH; _write_private(dest, text)` (aliased) | **FAIL** — same class |
| install moved into a helper `_install_config(text)` | **FAIL** — RES-4's second half, same class |

All four reds carry the same remedy, written in the assertion's own docstring: **re-aim the clause
at the new owner, never delete it.**

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | K-2 / I-1 — "extend the existing post-`finally` leak check so a still-displaced `Popen` raises `LoadRefused`". The ledger itemises the clause but not the message. | The clause was extended **and** the message rewritten: `"the os shim leaked out of the load"` → `"a displacement made by the load did not survive its finally"` (`check-sc-contracts.py:235`). | Once the condition covers two displacements, the old message asserts a cause it cannot know — the same defect I-2 exists to remove one function above. 0 net lines; the sentence is not in the frozen set. |
| D-2 | E-1 is priced at **+4 executable** in the change ledger and in C-10's re-derivation. | Delivered at **+3**. | The fourth line was never a new line: extending `:234`'s existing boolean and rewriting `:235`'s message are rewrites. The clause C-8 offered to drop is **present**; dropping it would have saved 0 lines and falsified BC-5 and I-1. See C-8's row below. |
| D-3 | E-2 is priced at **13** (12 in the function + 1 registry row). | Delivered at **14 + 0**. | The `TESTS` row cost nothing — the two existing tuple lines were re-wrapped to hold the new name — while the function needed one more line than estimated to keep the `defs` / `installs` comprehensions inside the file's ~90-column convention. Net effect on the total is +0. |
| D-4 | I-1 places the capture of the real `Popen` **inside** `load()`, immediately above the displacement. | The capture is at **module scope** (`REAL_POPEN`, `:161`); `load()` displaces and the `finally` restores *that* name. | I-1's placement makes the post-`finally` assertion compare `subprocess.Popen` against a value the same function computed, so an edit that captures **below** the displacement leaves the real `Popen` denied for the whole process while the suite stays green — measured on the delivered round-3 shape. A binding made at import cannot be reordered relative to a displacement made later; the assertion now compares against something the reorder cannot reach. **0 net lines**: one line left the function, one entered the module. What it does not cover — a deliberate rebinding of `REAL_POPEN` *inside* `load()` — is named in the code, at the binding. |
| D-5 | I-9 / K-13 spell `floor_of()` as the one `sed`. | `floor_of()` also decides **what a floor is**: the extracted text is emitted only when it is one run of digits (`:91-92`), and both `(( ))` comparisons are base-10-pinned (`:106`, `:130`). | A `baseline.json` with a second unescaped `"test_count"` made `floor_of` print two lines; `(( 19 3 < 19 ))` is a bash **syntax error**, and the error takes the `if / elif / else` chain to its **`else`** — the PASS arm. A monotonicity control that fails open is the class R-104 was filed for. Putting the shape test in the one reader (rather than at each call site) fixes B.4's identical fail-open in the same line, and leaves both callers' existing branches untouched: unusable → B.4 FAIL, B.6 SKIP with its one line. **+1 net line.** |

No behavioural drift beyond D-4 / D-5: every element does what I-1 … I-10 specify, in the
`## Migration & edit sequence` order (E-1 → E-2 → E-5 → E-3/E-6/E-7 → E-4). Both deviations were
made to close a measured defect, not to reshape a design decision, and neither widens what the
denial permits: D-4 changes which object the restore reads, D-5 changes only which readings are
treated as no reading at all.

## Condition disposition

| gate condition id | disposition | evidence |
|---|---|---|
| C-1 | **DISCHARGED** | The fourth family has its own clause in both texts: `check-sc-contracts.py:69-75` (route family **(iv)**, naming `os.path.os`, the `shim.__dict__.update(os.__dict__)` mechanism at `:213`, and `subprocess.os` / `shutil.os` / `tempfile.os`) and `docs/dev-map.md:180-185` (**(iv)**, same nouns, same mechanism). Both state the measurement, and both say **open**, because the reading says open. |
| C-2 | **DISCHARGED** | Both variants taken before E-1 was written and re-taken after, scratch subject + marker target only. Readings in `### C-2` above: marker **PRESENT** in all four runs; exit 1; the `os restored` line's absence explained rather than glossed. Re-taken at stage 6 per AC-1. |
| C-3 | **DISCHARGED** | `check-sc-contracts.py:95-98` ("WHAT THIS IS, SAID PLAINLY: a guard against an ACCIDENTAL process start from the subject's own import … and NOT a sandbox against a subject that seeks to escape … A reader may not take that list for a verified guarantee.") and the matching sentence closing `docs/dev-map.md`'s denial paragraph. |
| C-4 | **DISCHARGED** | The appended record `denying-the-non-os-process-routes-by-a-wider-name-enumeration` states candidate (3)'s **true** delta — it *would* close the attribute-chain family, it does **not** close `_posixsubprocess.fork_exec` or `ctypes` — and declines on the three surviving grounds (one CPython's dispatch choice; a second mutation of a global module the harness itself uses; the requirement admits the sentence at zero lines). G-2's refuted ground ("buys no coverage candidate (1) does not already give") is **absent** from the record. The same purge was applied to **candidate (2)**, whose inherited ground ("the subject's `import subprocess` returns the same module object either way") is false — measured: under that candidate the subject's import returns the **shim**. It is struck; the decline now rests on BC-6 and size, and the record states the true, narrower delta (a `__dict__`-copying shim still carries the real `os` at `shim.os`, so family (iv) survives it; a shim that dropped `os` would remove only `subprocess.os` from it). |
| C-5 | **DISCHARGED** | `baseline.json`'s `notes` now marks both numbers as read by no committed step. Repo-wide search for a reader: `git grep -n "passing_count\|warnings_baseline"` returns `baseline.json` itself and **archived stage documents only** — no script, no step, nothing executable. B.4 reads `test_count` (`verify_all.sh:99`) and B.6 reads the same key (`:125-126`), both through `floor_of()` (`:90-93`). The `notes` sentence names that function and those two steps rather than a line number: the line citation it carried decayed within this very task (the header edits moved B.4's read), so the durable form is the one committed. No executable line was added for either number. |
| C-6 | **DISCHARGED (dev half)** | K-10's delivered sentence states its own scope on **both** halves (`check-sc-contracts.py:117-123`, mirrored at `docs/dev-map.md:253-258`): "no committed artifact runs THIS REPOSITORY'S bin/sc as a program, and this suite starts no child process at all. Both halves are narrower than they read … verify_all.sh itself runs git, bash and python3 … and restricted-network-regression.sh:285 runs the INSTALLED /usr/local/bin/sc as root, on the destructive operator-token arm that verify_all cannot reach (B.5 wires --self-check only …)". Both citations were read first-hand: `restricted-network-regression.sh:283-285` is inside the token arm, and `main()`'s `--self-check` case (`:142-148`) exits before the gates. NFR-1's reading over a B.4 run: `execve` 1, `clone` 0. QA reports AC-8 against this scoping. |
| C-7 | **DISCHARGED** | The clause's docstring carries **three** residuals (`check-sc-contracts.py:602-613`), the third being the bare-name/first-positional pinning with both reddening spellings named and the reason the argument cannot be dropped (without it the clause passes `mut-res9-os-replace`, which keeps `bin/sc:2170`'s `_write_private(Path(name), text)`). M-4 extended by the keyword-spelled case and by the aliased one — both measured **red**, both reported as known reds of the clause, not defects of `bin/sc`. |
| C-8 | **KEPT, and reported NOT-DISCRIMINATING for the shape G-6 names** | The post-`finally` `Popen` clause is **kept** (`check-sc-contracts.py:234`). Reason: it is not a fourth line. That line already existed as the `os`-shim leak check; adding ` or subprocess.Popen is not REAL_POPEN` is a **rewrite at 0 net lines**, so dropping it would have saved nothing while falsifying BC-5 ("the restoration is asserted") and I-1 ("if either is still displaced afterwards, `LoadRefused` is raised"). G-6's characterisation still holds for the build shape it names — a `finally` that restores unconditionally cannot fail this line — but the clause is **not** vacuous: with the restore deleted from the `finally` it raises `LoadRefused: a displacement made by the load did not survive its finally`, measured. What it could **not** see, and now cannot happen, is a capture taken *below* the displacement: the captured value is bound at import (D-4), so there is nothing left in `load()` for a reorder to poison. **NOT-DISCRIMINATING against an unconditional-`finally` build; discriminating against a deleted restore** — stage 6's AC-12 list should say it that way (with BC-4, AC-3, AC-8). |
| C-9 | **DISCHARGED for the pre-commit instant; post-commit owed** | See `### C-9` above: pre-commit **19 vs 18 → PASS**, taken in the real repository, both numbers stated. Post-commit **19 vs 19** is the PM's at delivery and is explicitly **owed**, not claimed. |
| C-10 | **QA's — inputs supplied** | Both numbers are in `### C-10` above: raw `git diff --numstat` per file, and the net executable itemisation per element (**31 net added**, 33 counting E-5's two changed data lines) against the gate's 31–34 and NFR-2's cap of 40. No new file, directory, dependency, framework, runner or coverage machinery. |
| C-11 | **DISCHARGED — read line by line, re-taken after the round-4 edits** | `git --no-pager diff -- docs/dev-map.md` was read hunk by hunk and then checked mechanically: of HEAD's 190 lines, exactly **4** are absent from the worktree's 277, and all four lie inside the two sentences this change falsified — "on the shim, **every process-start name in `dir(os)`** must raise …" (falsified: the denial is two halves and its completeness claim is scoped to POSIX **and to the public spellings**) and "A name prefix is not a capability either: that list **is the whole guarantee**, so a name a future CPython adds to `os` belongs in it" (falsified: four families are open, one of them **today**, and adding names is refused). Every other line of the file — R-77 (`:236`), R-78 (`:239`), R-84 (`:240`), the "Then repoint all **nine** path constants" clause (`:216`) and the whole 11-line fenced recipe block (now `:204-214`, HEAD `:142-152`, compared slice-to-slice and **byte-identical**) — survives, verified by set-difference over the two texts, not by eye. The recipe block's line numbers moved because prose above it grew; its bytes did not. RES-2 is therefore taken here; stage 6 re-takes it independently. |

## Open issues for review

Residuals **written rather than closed**, with the place on the claim surface a reader meets each:

- **RES-1 / K-8(i)** — `import posix; posix.system(…)`, `ctypes` and a direct `_posixsubprocess.fork_exec` still start a process from a subject's import. Measured, not assumed: the `posix` and `ctypes` markers were both PRESENT against the delivered suite. `posix` is the **cheapest member of family (i)** — no attribute chain, no `ctypes`, one import of a module every CPython on this platform ships — and it is now named first in family **(i)** in both texts (`check-sc-contracts.py:45-50`, `docs/dev-map.md:160-166`), because a route left unnamed reads as a route not known.
- **The assertion phase is guarded by a list, not by a mechanism** — nothing in the suite prevents an assertion from driving `cmd_status`, `cmd_sysproxy`, `cmd_log` or a `doctor` probe, each of which runs a real child on this host (`ip -br addr show` at `bin/sc:2504`, `sudo -u … gsettings` at `:3406`, `tail -f` at `:3607` — which never returns — and `_doctor_tun`'s `ip` at `:2853`; `_doctor_service`'s `systemctl` `:2827` and `rc-update` `:2831` are **not** among them, because that function returns two UNKNOWN rows at `:2816-2819` when neither init flag is set). What holds today is which functions `TESTS` names, checked by review. Stated as such in both claim-surface texts rather than dressed as a guarantee; a mechanism (an import-time forbidden-callee assertion over the suite's own source) is a task, not a sentence, and is not in this scope.
- **NEW, C-1 / G-1** — the real `os` module, one attribute hop from the shim and from every pre-imported module. It needs no import at all — a subject that has already done `import os` is one attribute away — which makes it the cheapest route *for a subject that imports nothing further*; `posix` above is cheaper still for one willing to add an import line. Met as family **(iv)** in both texts, with its measurement quoted.
- **RES-2 / K-8(ii)** — a process-start name in `os` that no prefix matches. **Not only a future one, and this was the round-3 delivery's one false sentence**: `os._execvpe` and `os._spawnvef` are in `dir(os)` today and were measured escaping the delivered denial (the first replaced the loading interpreter, exit 0; the second forked before its child's `exec` was refused). Half (a)'s claim is now scoped to the **public** spellings in both texts, and family **(ii)** carries the 402-name enumeration, both measurements, and the reason no name was added: a copied function object keeps `__globals__` pointing at the real `os` dict, so the tuple can deny a spelling but not the capability — measured, `os.path.os._execvpe(...)` escapes with both halves in force. The `dir(os)` meta-assertion stays declined (Q-3). Filed row R-93 needs its wording widened at stage 7 — it still says "a name a **future** CPython adds".
- **NEW — the capture that the leak check compares against** — `REAL_POPEN` is bound at import (`check-sc-contracts.py:161`) precisely so that no reorder inside `load()` can leave the `finally` restoring the denial and the assertion comparing it with itself. A deliberate **rebinding** of that name inside `load()` would still do it and nothing asserts against that; it is named in the code at the binding, because it is a hazard of a future edit, not of this one.
- **RES-3 / K-8(iii)** — any module added to `check-sc-contracts.py:152-153` binds the **real** `os`; the next task that adds one owes the same pricing half (b) got. Met as family **(iii)**, beside the line that creates the hazard.
- **RES-4 + C-7** — the one-writer clause's three residuals (a second installer beside a surviving call; a helper reshape; the bare-name/first-positional pinning). Met in the assertion's own docstring (all three) and in both claim-surface texts (the first two).
- **RES-5** — `verify_all.ps1` has **no** B.6 and its B.4 is an unconditional SKIP, so on Windows neither the floor nor its monotonicity is checked at all. Met in B.6's own comment (`verify_all.sh:122-124`). It still needs the **new `docs/tasks.md` row** at stage 7 (owner: next task touching the mirror) — that is E-8, the PM's.
- **RES-7 / BC-4** — the floor control cannot see a lowering already present in the last commit. Declared, not discovered. Met in `baseline.json`'s `notes` and in B.6's comment, both in the same words: B.6 answers "did the change about to be committed lower the floor", never "is this floor honest".
- **Q-F's worktree shape** — where `.git` is a *file*, B.6 SKIPs, exactly as A.1 and A.2 already do there. Measured. Inside BC-2's intent; recorded here as a residual rather than as a widened condition.
- **B.4 carried the identical fail-open and was fixed in the same line as B.6's** — `floor_of()` has exactly two callers, and both fed their result straight into `(( ))`. A two-line reading made B.4's comparison a syntax error too, and B.4's chain also ends in a PASS. The shape test went into the one reader rather than into each caller, so the two steps cannot drift apart; B.4's own branch text ("absent or its `test_count` unreadable") already covered the new case, and `baseline.json`'s `notes` now says so. Scope note, stated rather than assumed: QA filed only B.6, and this is one token more than that finding required.
- **What B.6 still cannot do** — with an unusable floor it SKIPs, which means a `baseline.json` whose `test_count` is duplicated or non-numeric loses its monotonicity check entirely for that run. B.4 FAILs on the same reading, so the run is not green; but the *ratchet* is silent, not violated. No committed step produces that state.
- **Not mine, still stale**: `.harness/rules/50-singbox-cli.md:29-30` says "14 contract assertions" and is now stale at **19**. Out of scope 6 / RES-6 — it belongs to R-94's owner. Naming it, not touching it.
- **Upstream, reported not fixed**: G-3's finding is real and its scoping is what makes AC-8 reportable — FR-6/AC-8 as literally written ("no committed artifact starts a child process") is false of the committed tree and of this delivery too, since `verify_all.sh` runs `git`, `bash` and `python3`, and B.6 adds a `git show`. C-6's scoping is what was implemented and what the delivered sentences claim. The requirement text itself is still unamended; the analyst owns that, not this stage.

## Dev-map updates

- No line was added to `docs/dev-map.md`'s navigation: this task added **no** file, directory or module — every edit is inside five existing files, which is what NFR-3 and AC-13 require.
- `docs/dev-map.md`'s fixture-loader recipe bullet was edited as content (E-6), governed by C-11: two falsified sentences corrected in place, the denial's two halves and four open route families added, the **assertion-phase** paragraph added so the bullet and the suite header no longer disagree about the one phase where the denial is deliberately off, and the three "what the committed suite does not reach" limits appended at the bullet's end. Every other line of that file — 186 of HEAD's 190 — is byte-identical, checked by set difference and not by eye (see C-11). The 11-line fenced recipe block moved from `:185-195` to `:204-214` as the prose above it grew; its bytes are unchanged, compared slice-to-slice against HEAD's `:142-152`.

## Insight to surface

- 2026-08-16 · An `os`-shim denial can never be complete no matter how many names it enumerates, because the **real** `os` module sits one attribute hop away from the shim itself — `shim.__dict__.update(os.__dict__)` copies the real `posixpath`, whose `os` attribute IS the real `os` — and one hop from every pre-imported module (`subprocess.os`, `shutil.os`, `tempfile.os`); measured, `os.path.os.system(...)` and `subprocess.os.system(...)` from a scratch subject's import each left their marker **both before and after** the `subprocess.Popen` choke point was closed, while `subprocess.call` / `Popen().wait()` / `subprocess.run` all flipped to `LoadRefused`, exit 2, no marker · evidence: `.harness/scripts/check-sc-contracts.py:213` + T-31 `04_DEVELOPMENT.md` `### C-2`
- 2026-08-16 · `check-sc-contracts.py` prints its `os restored <bool>` line **only** on the load-or-fixture failure path, so a subject that successfully escapes the denial produces **no** restoration line at all — a probe criterion phrased as "quote the `os restored` line" is unsatisfiable by exactly the runs it exists to catch, and the restoration must be read from the post-`finally` leak check not raising instead · evidence: `.harness/scripts/check-sc-contracts.py:868`
- 2026-08-16 · A fixture's `sc.SYSTEMD = sc.OPENRC = False` defeats **branches**, not calls, and which way a defeated branch falls is **per function**: `_doctor_service` tests both names first and returns two UNKNOWN rows (`bin/sc:2816-2819`), so its `systemctl` (`:2827`) and `rc-update show` (`:2831`) calls are unreachable under any such fixture, while `cmd_log` branches on `SYSTEMD` alone (`:3594`) and the same setting **routes into** its `else`-arm and runs `tail -f` (`:3607`), which never returns — and every call behind neither name (`cmd_status`'s `ip -br addr show` `:2504`, `cmd_sysproxy`'s `sudo -u <user> gsettings` `:3406`, `_doctor_tun`'s `ip` `:2853`) was never guarded at all, so what keeps a contract suite off the live host in its assertion phase is which functions its test list names · evidence: `bin/sc:2816` + `bin/sc:3607` + `.harness/scripts/check-sc-contracts.py:76-94`

- 2026-08-16 · A `sys.modules` `os` shim built with `shim.__dict__.update(os.__dict__)` cannot be closed by any list of names, because the copy hands over **function objects** whose `__globals__` **is the real `os` module's dict**: `os._execvpe` and `os._spawnvef` are in `dir(os)` today, begin with `_` so no public prefix matches them, and call the **real** `execv` / `fork` no matter what the shim's attributes say — measured, a scratch subject calling `os._execvpe('/usr/bin/touch', [...])` **replaced the loading interpreter**, marker left, **exit 0, no summary, no refusal**, while `os._spawnvef` forked (`execve` 1, `clone` 1 under `strace`) before its child's `exec` was refused, and adding both names would buy nothing because `os.path.os._execvpe(...)` escapes identically · evidence: `.harness/scripts/check-sc-contracts.py:51-65` + `:216`
- 2026-08-16 · In bash, an `if unreadable → SKIP / elif bad → FAIL / else → PASS` chain **fails open**: `(( ))` on a value that is not one base-10 integer — two lines from a duplicated JSON key, or a leading zero read as octal — is a *syntax error*, the arithmetic evaluates false, and control lands on the **`else`**, so the step reports PASS and the only trace is a line on stderr nobody reads; the fix is one line in the one reader — emit the value only when it is a single run of digits — plus `10#` on every comparison, which costs nothing · evidence: `.harness/scripts/verify_all.sh:90-93` + `:130`

## Verdict

READY FOR REVIEW
