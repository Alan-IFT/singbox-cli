# 06 — Rationale · T-27 `harness-self-maintenance`

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

## 1. Setup, and why not stage 4's fixtures

Stage 4 built 25 fixture trees under `test/t27/`. I read none of them for an expected value and
reused none for a run. A reproducer must come from the criterion, not from the developer's test: if
`mkfix.sh` and the implementation share an assumption — a header shape, a bullet regex, a join
convention — a test built on it cannot detect that assumption being wrong. Everything under
`test/t27/qa/` is mine: `build.py` (fixture generator, 20 cases, byte-exact indexes including a
`final_newline=False` switch), `check_ac2.py` (conservation check with its **own** re-implementation
of the harvest join, written from FR-2/FR-4 rather than from `archive-task.sh:57-71`), `snap.py`
(full-tree snapshot: path, size, `mtime_ns`, sha256, directory entries) and `apply_lost_action.py`
(the AC-13 *lost* action as two anchored hunks).

Both scripts under test were pinned by digest before anything ran — `cand` (working tree)
`558eaf1c07b0…`, `head` (`git show HEAD:…`) `794279cc95f6…` — and copied into each tree at
`.harness/scripts/archive-task.sh`, because the script derives its root from its own location
(`:27`) and a run of the repository's copy with a fixture `--task` would rotate the **repository's**
index and consume AC-15's single observation (PQ-4, K-9, C-9).

## 2. RES-2 first, before any run

T6.2 fired — RES-2 is a measurement stage 5 could not take and AC-15 rides on it — so it was taken
before anything touched anything:

```
$ wc -l .harness/insight-index.md          → 30
$ tail -c 1 .harness/insight-index.md | xxd → 00000000: 0a    .
$ /usr/bin/grep -cvE '^\s*-\s' …            → 8   (lines 1-8, leading)
$ tail -n 1 …                               → "- 2026-08-15 · `telemetry: block` is the **abs…"
```

Three consequences, all the good case:

1. The file ends with `0a`, so `wc -l` = 30 is the true physical line count. RES-2's failure mode
   (`wc -l` = 29 → rotate `h−1` → land at 31 → F.4 WARN with E-1 working correctly) is **absent**.
2. All 8 non-bullet lines are leading, so `header=$(grep -vE …)` at `:118` hoists nothing —
   C-3(iii)'s reorder and QA-2's hoist cannot fire on the real index.
3. The final line is a bullet and no blank line sits between entries, so QA-1's silent deletion
   cannot fire either.

The simulation (§7) then ran the candidate over a byte-identical **copy**, never the file itself.

## 3. Per-criterion transcripts

### AC-1

```
[cand] before: 30 lines → "Rotating 3 old insight(s) to insight-history.md" → after: 30 lines
       report tail: "Rotated:      3 -> …/insight-history.md" ; EXIT=0 ; history exists: yes
[head] before: 30 lines → (no rotation line) → after: 33 lines ; EXIT=0 ; history exists: no
history file, whole content after the candidate run:
  # Insight history (rotated from .harness/insight-index.md)
  ## Rotated 2026-08-16
  - 2026-01-02 · pre-existing entry 01 …   ← the three OLDEST, in order
  - 2026-01-03 · pre-existing entry 02 …
  - 2026-01-04 · pre-existing entry 03 …
```

### AC-2 — `check_ac2.py`

```
pre entries 22 · harvested 3 · rotated 3 · remaining 22
header sha256[16]: fa03a015032a5477 (pre) / fa03a015032a5477 (post)
longest pre line : 402 bytes; present after: True
hostile '- -n leading' / '- back\\slash' / '- $VAR'  round-trip byte-identical: True / True / True
AC-2 OK    CHECK_EXIT=0
```

Three assertions that would have failed loudly: `rotated + post == pre + harvested` (conservation),
`rotated == pre[:n]` (oldest, in order), `post_header == pre_header`. PQ-6's claim that bash's
builtin `echo` interprets no escape without `-e` is thereby confirmed by measurement, not inherited.

### AC-3, AC-4

```
AC-3  before 25 → EXIT=0 → after 27 ; history: none ; first 25 lines identical: yes
AC-4  before 30 sha=59fe2f678bb06c11 → EXIT=0 → after 30 sha=59fe2f678bb06c11 ; history: none
```

### AC-5 — both fixtures, both scripts

```
ac5i  [cand] before 32 (entries 2) → "Over cap: 1 line(s) remain above 30 after rotating every
                                      entry present" + "Rotating 2 …" → after 31 ; 31−30 = 1
      [head] before 32             → (no Over-cap / Rotating line)     → after 33 ; 33−30 = 3
ac5ii [cand] before 32 (entries 0) → "Over cap: 3 …" , clamp reduced the rotation to ZERO,
                                      no "Rotating" line               → after 33 ; 33−30 = 3
      [head] before 32             → (no Over-cap / Rotating line)     → after 33 ; 33−30 = 3
header comparison vs a freshly rebuilt pristine copy:
      ac5i  byte-identical, 30 header lines after ; ac5ii byte-identical, 32 header lines after
```

The identity closes digit for digit on both, including the clamp-to-zero path where the residual is
the run's **only** signal that the file is over the cap (PQ-2, I-2). Recorded explicitly: on fixture
(ii) the resulting **file** is the same on HEAD and candidate (33 lines). What AC-5 states as its
observable is the *report line stating a residual equal to `wc -l` − 30*, and HEAD prints no such
line — no such `echo` exists in HEAD's file at all — so the criterion discriminates on the observable
it states, and not on the resulting file for that fixture.

### AC-6

```
[cand] and [head] identical: index line 26 =
  "- 2026-08-16 · a wrapped insight whose first physical line ends here and whose second physical
   line continues the sentence, and whose third line carries the tag · evidence: fixture-wrapped"
```

Control, as declared. It pins `archive-task.sh:44-77` against regression (FR-4, K-5).

### AC-7 — dry run, both scripts, plus the positive control

```
[cand]  [DRY RUN] No files written. Would have:
          - Appended 3 insight(s) to .harness/insight-index.md
          - Rotated 3 old insight(s) to insight-history.md
[head]    - Rotated 0 old insight(s) to insight-history.md
snapshot diff, both trees: identical (existence, size, mtime_ns, sha256)
index bytes identical across the two trees: yes (cmp)
positive control — one byte appended, snapshot re-taken:
  < .harness/insight-index.md|size=1561|mtime_ns=1786815910980109772|sha256=59fe2f678bb0…
  > .harness/insight-index.md|size=1562|mtime_ns=1786815921073329236|sha256=3cd0822d1ef4…
```

`rotated` is populated at `:101-103`, **before** the `DRY_RUN` guard at `:109`, which is why the
dry-run report can state the absolute count. The two strings differ, so AC-7 is **not**
NOT-DISCRIMINATING.

### V-2b / RES-3 — both exit statuses

```
[head] EXIT STATUS = 0 ; full dry-run report ; tree unchanged ; index not created
[cand] EXIT STATUS = 0 ; identical output    ; tree unchanged ; index not created
HEAD :82        [[ "$DRY_RUN" == false ]] && touch "$insight_index"
candidate :84   if [[ "$DRY_RUN" == false ]]; then touch "$insight_index"; fi
```

`02_SOLUTION_DESIGN.md:31` states HEAD's AND-list "aborts a `--dry-run` run whose index is absent"
under `set -e`. It does not: bash exempts a failing command inside an `&&` list from `errexit` unless
it follows the final `&&`, and here the failing command **is** the `[[ … ]]`. E-1b is therefore
hardening (K-4), not a bug fix — C-1's pre-ruling and CR-2's reading, confirmed. Hence RES-4: RS-5's
second candidate insight must not reach `07_DELIVERY.md`.

### AC-9 — the spot-check RES-7 asks for

`/usr/bin/grep -n '^## '` over the four documents gives **33** H2 units (8 + 5 + 13 + 7) where
`04_DEVELOPMENT.md`'s C-11 row says 30. The criterion's clauses are counts of *zero*, so the
convention difference cannot move the verdict; filed as QA-5.

| unit | route under `70-doc-size.md:80-96` | portion occupied | destinations |
|---|---|---|---|
| T-26 `01_*` `## Goal` | stage 2 designs to it → contract | contract | one |
| `## Acceptance criteria` | later stages verify → contract | contract | one |
| `## Resolved questions` | binding answers; also named by the stage-1 contract → precedence → contract | contract | one |
| `## Non-functional requirements` | contract | contract | one |
| `01_RATIONALE.md` §1 per-row re-verification | records how it was reached → rationale | rationale | one |
| `01_RATIONALE.md` §2 candidate answers | compares → rationale | rationale | one |
| `01_RATIONALE.md` §4 "Traps the fixtures must avoid (for stage 2's V-table and stage 6)" | the **bare test** could read "a later stage must satisfy it" → contract; the **precedence clause** decides first, and the stage-1 contract declares the contract portion's sections by name, none of which is a trap list → rationale | rationale | one, *via precedence* |
| T-19 `02_*` `## Verification plan` | stage 6 executes it → contract | contract | one |

Zero with none, zero with two. §4 is the unit that needed the precedence clause rather than the bare
test, which is what makes B-1 non-degenerate: a rule reading "everything → contract" mis-routes it.

C-11's routing, re-verified first-hand rather than taken from stage 4:

```
doctor-rows-establish-their-fact/01_RATIONALE.md:5-10
  "… Where a claim needs a runtime observation it is marked inherited and routed to a later stage
   (contract OQ-8, BC-10, AC-1/AC-5/AC-9/AC-10)."
…/01_REQUIREMENT_ANALYSIS.md:212 = OQ-8, a CONTRACT row
```

So `measurement obligation → **contract**`. Nothing in either portion records the rationale routing.

### AC-11 — the partition, re-derived

`git show --name-only --pretty=format:` over `d849234` (T-26), `6d16caf` (T-25), `6c034d6` (T-24) —
25 paths each, 75 total.

| bucket | paths |
|---|---|
| that task's **product** files | `bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`, `docs/dev-map.md` |
| B-2 board | `docs/tasks.md`, `docs/tasks-archive.md` — all three |
| B-2 stage docs | 13 stage documents + `PM_LOG.md` + `insight-history.md` per commit |
| B-2 harness files | `.harness/insight-index.md` ×3; `.harness/rejected-decisions.md` ×3; `.harness/operator-obligations.md` (T-25, T-24); `CONTEXT.md` (T-26, T-24) |
| **neither** | **none** |

HEAD control, `ruleset-staleness-visibility/01_REQUIREMENT_ANALYSIS.md:149`, lists only
`docs/tasks.md`, `docs/tasks-archive.md`, `.harness/insight-index.md`,
`docs/features/_archived/insight-history.md`, `.harness/rejected-decisions.md` and the task's own
stage documents — so `CONTEXT.md` and `.harness/operator-obligations.md` fall in neither list.
HEAD fails, measured rather than asserted.

`docs/batches/**` appears in **none** of the three commits, so this PASS is not evidence for that
bullet; `04_DEVELOPMENT.md:83` discloses the same thing and I confirm rather than repeat it —
`git diff --numstat` shows `docs/batches/followups/BATCH_{PLAN,LOG}.md` modified right now, which is
itself an instance of a delivery commit carrying that path.

### AC-12 — both homes

```
80-delivery-policy.md:11-12
  Read also **when writing an acceptance criterion over the committed diff** (stages 1-2) — for the
  process-path list below — and **after `/harness-upgrade`**, for the vendored-script fixes below.
AI-GUIDE.md:30
  … also when writing an acceptance criterion over the committed diff (stages 1-2), and after
  `/harness-upgrade` …
HEAD, both homes: delivery-time only.
```

The two trigger clauses are byte-identical; only the connective prose differs, which AC-12 does not
bind.

### AC-16 — the diff read

```
$ diff <(git show HEAD:…archive-task.sh | grep 'echo ') <(grep 'echo ' …archive-task.sh)
7a8
> if (( rotate_count > ${#current[@]} )); then rotate_count=${#current[@]}; echo "Over cap: …" ; fi
functions:  HEAD 0 → candidate 0      'wc -l' occurrences: HEAD 0 → candidate 1
file length: HEAD 150 → candidate 154 (150 + 8 − 4)
```

Exactly one `echo` added and I-2 mandates it; no pre-existing report string moved or changed. The
`wc -l` is at `:81`, outside every loop; the only `$( )` in the rotation body are the pre-existing
`date` at `:114` and `grep` at `:118`, both outside the per-entry `for` loops. NFR-3 holds.

## 4. The AC-13 drill in full

```
$ sed -n '56p' .harness/scripts/upgrade-project.sh
template_common_scripts="$TEMPLATE_ROOT/skills/harness-init/templates/common/.harness/scripts"
harness-kit 0.47.0 · 425 lines · sha256 4c8db8c81ee8b74f903585d00d94224f20fd46a9210ea451ab08d07ac4e82d9e
copied read-only:  -r--r--r-- test/t27/qa/refresh/template-0.47.0.sh
```

**Check 1 (metric row).** B-3: *"archive a fixture whose index is at the cap with ≥1 harvested
insight, then `wc -l` the resulting index"*. PQ-6 settles "at the cap" as **lines**, which is also
what `70-doc-size.md:27` now says, so the AC-1 fixture is used unchanged.

```
index at cap before: 30 ; EXIT STATUS = 0
Index tally: entries 22, unaccounted lines 0, entries after run 25
wc -l of resulting index = 33          → exit 0 = completed → 33 > 30 → ***lost***
```

**Check 2 (join row).**

```
EXIT STATUS = 0
tail: "- 2026-08-16 · a wrapped insight whose first physical line ends here" /
      "  and whose second physical line continues the sentence," /
      "  and whose third line carries the tag · evidence: fixture-wrapped"
grep -c 'evidence: fixture-wrapped' = 1 (exit 0) ; grep -c 'continues the sentence' = 1 (exit 0)
→ completed → continuation + tag present → ***already provided*** → change nothing (nothing changed)
```

**The *lost* action, performed.** B-3 states it as a metric: *"make the rotation decision read
`wc -l` of the index — F.4's own measurement, `verify_all.sh:213-219` — instead of whatever it
counts, and rotate until the file it writes is ≤30 lines."* Here an entry may occupy several physical
lines (check 2 just produced one that occupies three), so PQ-7's reading is the only one satisfying
the stated metric: rotate **entries until the emitted line count** reaches the cap. Two anchored
hunks, `+17 / −5`, 425 → 437 lines, nothing discarded:

```
hunk 1 (the decision):  idx_lines=$(wc -l < "$insight_index") behind [[ -f ]]
                        emit_lines = #IDX_HDR + #HARVEST + Σ(IDX_E_HI[e] − IDX_E_LO[e] + 1)
                        lines_after=$emit_lines
                        while (( emit_lines > 30 && rotate_count < idx_entries )) → drop one entry
hunk 2 (write-phase branch head):  if (( total_after > 30 ))  →  if (( lines_after > 30 ))
```

No step opened `archive-task.sh:51-56` (the in-file note the replacement deletes) and neither defect
was re-diagnosed: the metric came from B-3's own words and the arriving text's own variables.
`git log -p` was not needed.

**Both observables, against the resulting script:**

```
AC-1 fixture: before 30 → "Rotating 3 old insight entry(ies) …" → EXIT=0 → after wc -l = 30,
              history entries: 3
AC-6 fixture: EXIT=0 → the wrapped bullet's three lines, ending "· evidence: fixture-wrapped"
```

**ADV-4, the refusing arrival — C-12's reason for existing.** F-15's hazard reproduced live. A
`## Rotated 2026-01-01` line — the residue a hand rotation of the kind this project performed sixteen
times leaves — **replaces** one entry so the file stays at exactly the cap:

```
before wc -l = 30  (at the cap, 3 harvested)
cmd exit status = 3
archive-task: refusing to harvest — 1 unclassifiable line(s); nothing written.
  …/refuse3/.harness/insight-index.md:19: unaccounted line: ## Rotated 2026-01-01
wc -l of resulting index = 30
```

Pre-CR-1 a reader would have read `≤30` → *already provided* → *change nothing*, and the line-count
fix would have been silently dropped on the next refresh. The landed clause at
`80-delivery-policy.md:76-78` forecloses exactly this. I ran the drill from `:66-83`'s bytes alone,
as a future reader would, and the clause did the work — CR-1 earned its line. A variant where the
same heading is *inserted* rather than replacing an entry exits 3 at `wc -l` = 31, i.e. the naive
reading would have reached the right verdict by luck; the at-the-cap variant is the discriminating
one.

## 5. The adversarial attacks that broke something

### QA-1 — a blank line between two entries is deleted, silently, with F.4 PASS

C-3(iii)'s shape is stated as *"final line a non-bullet line"*. The **mechanism** is different:
`header=$(grep -vE …)` at `:118` loses whatever trailing newlines the *grep output* ends with, so
what is lost is the file's **last non-bullet line, when it is blank** — wherever in the file that
line sits. A blank line between two entries, with the file's final line still a bullet, satisfies
the mechanism and falls outside C-3(iii)'s words:

```
before wc -l = 32  non-bullet=9   →  "Rotating 3 old insight(s) …"  →  after wc -l = 29  F.4 PASS
non-bullet after = 8 (was 9) ; bullets after = 21 ; rotated = 3
post-run last line: "- 2026-08-16 · harvested insight 1 · evi…"   (a bullet)
```

Accounting: 8 leading header lines + 1 mid blank + 23 entries = 32; decision `index_lines` 32, `h` 1,
rotate 3; the rewrite emitted header **8** (not 9 — the blank was stripped) + 20 remaining + 1
harvested = 29. Not repaired here: same `:118`, inside the frozen `:109-136` (AC-16, NFR-1,
out-of-scope 8). What it changes is the **statement** RS-9 carries to the pool — the trigger is "the
file's last non-bullet line is blank", not "the final line is a non-bullet line", and a hand rotation
is a plausible way to create one. The real index has no such line (§2).

### QA-2 — RES-9's multi-line entry, reproduced

```
before wc -l = 33  non-bullet=9  →  "Rotating 4 …"  →  after wc -l = 30  F.4 PASS
9:  a second physical line that is not a bullet · evidence: hand-edit   (was physical line 15)
```

No new WARN shape — the count lands at 30 — but the line moved 15 → 9. Same `:118`, same pool row.

### QA-3 — the append path onto an unterminated final line

```
advx1 (header-only over cap, unterminated): before wc -l = 31 last-byte=34
  "Over cap: 2 line(s) remain above 30 …" → after wc -l = 32 ; 32−30 = 2
  last line: "> filler header line 24- 2026-08-16 · harvested insight 1 · evidence: fixture-new"
advx2 (under cap, unterminated, plain append), candidate AND head:
  line 25: "- … pre-existing entry 17 · evidence: fixture-old- 2026-08-16 · harvested insight 1 …"
  cmp candidate vs head → byte-identical
```

`echo "$h" >> "$insight_index"` at `:128` appends after an unterminated final line, concatenating the
harvested entry onto it and destroying its bullet marker. Both scripts do it identically — HEAD
behaviour, not a regression, and `:126-130` is not in E-1's edit. RES-2 measured the real index
terminated, so it cannot fire at delivery. Note the AC-5 identity survived even here: `Over cap: 2`
against `wc -l` − 30 = 2.

### The attacks that held

- **The residual identity.** I put the clamp on top of an unterminated final line (`advx1`) to make
  the reported number disagree with `wc -l` − 30. It still closed at 2 == 2.
- **A silent over-cap.** Is there a path where F.4 WARNs and no residual prints? It needs
  `rotate_count == ${#current[@]}` with an over-cap header. `rotate_count = index_lines + h − 30` and
  `index_lines = header + entries`, so the equality reduces to `header + h == 30` — the header cannot
  be over the cap. Measured at both sides: `advx3` (header 30, 3 entries, h 0) → no residual line,
  30 lines, F.4 PASS; `advx4` (header 31, 3 entries, h 0) → `Over cap: 1`, 31 lines, F.4 WARN.
- **Newest instead of oldest, or a dropped header.** `check_ac2.py` asserts the oldest-prefix and
  header equality directly and exits 0; both AC-5 fixtures kept their 30- and 32-line headers
  byte-identical.
- **The evidence tag.** AC-6 on both scripts; `:44-77` is byte-identical to HEAD.

### QA-4 — the harvest heading, exercised rather than read

```
07_DELIVERY.md heading = "## Insight to surface"
before wc -l = 30 ; (no harvest/rotation line) ; EXIT=0 ; after wc -l = 30
```

`archive-task.sh:58` matches `/^##[[:space:]]+Insights?[[:space:]]*$/` — anchored; a suffix harvests
zero. Worth stating loudly because `04_DEVELOPMENT.md`'s own insight section is titled `## Insight to
surface`: copying that heading into `07_DELIVERY.md` fails AC-15's first clause at exit 0, silently.

## 6. Stability and measurement hygiene

Ten fresh AC-1 builds and runs: `lines=30`, `idx_sha=bd0b7ae23302`, `hist entries=3` — 10/10
identical. Three `verify_all` runs from the repository root: `PASS: 17  WARN: 0  FAIL: 0  SKIP: 1`,
exit 0, no step changing verdict between runs.

Every count that decides a criterion was taken with `/usr/bin/grep` explicitly. Stage 4's second
insight — this project's interactive `grep` is a function wrapping ugrep 7.5.0 while a script gets
GNU grep 3.11, and `-cv` disagrees by one on a file with no trailing newline — is exactly the error
class that would have corrupted the C-3(i) numbers, so it was honoured rather than re-discovered.

## 7. The AC-15 pre-flight, and why it is not AC-15

AC-15 is dischargeable only at delivery and only once (C-7, RS-4). What is dischargeable now is
whether the delivery run **can** succeed, which reduces to RES-2 plus one simulation over a
byte-identical copy:

```
copy sha256: e148278e434dfff7   real: e148278e434dfff7
before wc -l = 30 → "Rotating 3 old insight(s) to insight-history.md" → EXIT=0
after wc -l = 30  → F.4 PASS
real index untouched: git diff --numstat -- .harness/insight-index.md → empty ; sha e148278e434dfff7
```

Arithmetic for the general case, re-derived rather than inherited: with `index_lines` = 30 and `h`
harvested, `total_after` = 30 + h, `rotate_count` = h clamped to 22 entries, and the rewrite emits
8 header + (22 − h) remaining + h harvested = **30** for any 1 ≤ h ≤ 22. At h = 0 neither branch
writes and the file stays at 30. So the only ways the delivery run misses are h = 0 (QA-4's hazard)
or a hand edit to the index between now and the run.

## 8. What this stage did not do

- No production file, rule fragment or upstream stage document was edited; `git diff --numstat` shows
  the same four product paths after this stage as before it.
- `.harness/scripts/archive-task.sh` was never executed against this repository; `docs/features/**`
  and `.harness/insight-index.md` are untouched (C-7, C-9, BC-8).
- `verify_all` and its checks were not modified; `baseline.json` was not modified in either
  direction, and no test was deleted.
- `HARNESS_ALLOW_OUTSIDE_RM` was never set. Every fixture lives inside the working tree under
  `test/t27/qa/`, ignored by `.gitignore:19`, so cleanup needs no override. Multi-line files were
  written with the `Write` tool or `printf`, not shell heredocs, because `guard-rm.sh`'s tokenizer
  has blocked heredocs containing no `rm` eleven times (OQ-1).
- No byte of harness-kit 0.47.0 entered `.harness/`; the template copy is `-r--r--r--` under
  `test/t27/qa/refresh/` (K-14).
- No service action, no write under `/etc/sing-box` or `/var/lib/sing-box`, no install over
  `/usr/local/bin/sc`, no `bin/sc` import (K-11, R-78).
- No credential bytes appear in either portion (A.1).
