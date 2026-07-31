# Code Review — install-binary-download-progress (T-08)

> **Provenance note (PM):** the code-reviewer agent runs with read-only tools (Read / Glob / Grep)
> and could not create this file itself. The body below is the reviewer's returned output,
> persisted verbatim by the PM Orchestrator. No PM edits to the content.

# VERDICT: `APPROVED`

0 CRITICAL · 0 MAJOR · 2 MINOR · 5 NIT. No rollback to developer, architect or analyst.
Neither review axis carries an unaddressed CRITICAL or MAJOR.

---

## Files reviewed

Product (the shipping diff):
- `/home/alan/Programs/singbox-cli/install.sh` — `:116-132` (policy block), `:149` (zh key),
  `:193` (en key), `:344-345` (loop), `:373` (version query), `:382-384` (tarball)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md` — `:9`, one `### 新增` entry under `[Unreleased]`

Read in full for context / non-regression: `install.sh:1-240` and `:240-520` (the whole file),
`docs/dev-map.md`, `.harness/insight-index.md`, `.harness/rules/50-singbox-cli.md`,
`.harness/rules/70-doc-size.md`, `.harness/rules/85-design-discipline.md`, and stage docs 01/02/03/04.

Verification artifacts read as evidence (uncommitted, QA-time, per D-A8 — **not** part of the diff):
`scratchpad/h/harness.sh`, `harness.out`, `static.out`, `gate_checks.out`, `ptyrun.py`, `states.py`,
and the extracted `scratchpad/c729tar/curl-7.29.0/` source tree.

Nothing was executed. `bin/sc`, `uninstall.sh`, `systemd/`, `README*.md`, `.harness/scripts/` are
untouched by the diff — confirmed by S-8's product-path listing and by grep over the file.

---

## Findings

### CRITICAL
None.

### MAJOR
None.

### MINOR

- **[MAINT] `docs/dev-map.md:42-54`** — the "Reusable utilities" table gains no row for the new
  installer-level seam (`CURL_OPTS_QUIET` / `CURL_OPTS_PROGRESS`, `install.sh:128-132`). The whole
  justification for D-A2 (rewriting two behaviourally-unchanged sites to cite the arrays) is *"T-07
  gets one edit point instead of three"* — and dev-map is precisely how T-07's developer would find
  that edit point. **The developer was right not to fix it here**: dev-map's own trigger is "whenever
  you add / move / remove a module" (`docs/dev-map.md:3`) and no module moved, and AC-19 restricts
  the shipping diff to `install.sh` + `CHANGELOG.md` with `docs/dev-map.md` *not* in the carve-out
  list, so editing it would have been a literal AC-19 breach. Route to **PM**, not to the developer:
  hand the one-line row to T-07, which owns the next edit to these flags. Open issue 1 in `04` asked
  for exactly this decision; this is the answer.

- **[TEST] AC-2 evidence is a summary, not a capture** (`04_DEVELOPMENT.md` "verify_all result").
  S-2 is the one Layer-S check that is **not** in `static.sh` (which runs S-1, S-3…S-8 = 7/7); the
  before/after `16 PASS / 0 WARN / 0 FAIL / 2 SKIP` table is asserted in prose with no pasted output,
  so it is the only AC in the set I could not corroborate from an artifact. Low risk — B.1 is the
  only real gate in `verify_all` and S-1 independently proves `bash -n install.sh` clean — and stage 6
  re-runs `verify_all` by charter. Recorded so QA does not treat it as already-discharged.

### NIT

- **[STYLE] `install.sh:116-127`** — 12 comment lines against 13 code lines. I checked this rather
  than assuming noise: the design made the comment load-bearing ("should ship close to this wording",
  `02` §3.1) and the shipped text *is* that wording plus one added line naming the curl 7.29 floor.
  It records two facts that are non-obvious and expensive to re-derive (the meter is a **stderr**
  artefact and curl does **not** self-gate on `isatty(stderr)`; `-s` beats `--progress-bar` rather
  than combining with it) and it is what stops a future editor from "simplifying" the gate to
  `[ -t 1 ]`. Justified. No change.

- **[MAINT] `04_DEVELOPMENT.md:29`** — "25 added lines / 3 replaced lines" double-counts: git's 25
  insertions already include the 3 replacement lines. Derived from S-7's hunk headers
  (`-115,0 +116,18`, `-130,0 +149`, `-173,0 +193`, `-324 +344,2`, `-352 +373`, `-362 +383,2`) =
  22 pure additions + 3 replacements = 25 `+` / 3 `-`. Wording only; the shape is exactly as designed.

- **[SEC] `install.sh:383`** — `$SB_VER` now reaches the terminal on the **success** path. Before this
  change the API-derived tag string was printed only on the failure path (inside `$SB_URL` at `:385`),
  and the semver guard at `:377` is an unanchored **prefix** match (`^[0-9]+\.[0-9]+`), so a tag like
  `1.10.0<ESC>[2J` would pass and now renders on a terminal. Requires a compromised or MITM'd
  `api.github.com` response over TLS, and `01` §7 explicitly sanctions this line ("apart from the
  version/architecture notice, which contains no credential"). Not a format-string hazard: the value
  lands in `"$@"`, never in `$fmt` (`install.sh:234`). No change requested; noted so it is on record.

- **[TEST] `scratchpad/h/harness.sh:332-335`** — AC-12 asserts the five artifact lines are *in loop
  order* only on the non-TTY capture (`ac12nt`); the TTY run asserts count and `0x0D` but not order.
  Same code path, zero risk, but the criterion says "in loop order … in both TTY and non-TTY mode".

- **[MAINT] `install.sh:344` vs `bin/sc:1183`** — gate F-10 stands: `install.sh` emits a *start* line
  per artifact with no completion line, whereas `bin/sc` emits a *completion* line carrying the
  outcome. B-6/AC-12 specify the start line, so this is correct as built; the two tools' "one complete
  line per item" contracts are only partly aligned. Record, do not act.

---

## Requirement coverage check

| # | Criterion | Implementation / evidence | Status |
|---|---|---|---|
| AC-1 | `bash -n install.sh` exits 0 | `static.out:2-4` (S-1) | ✅ |
| AC-2 | `verify_all` 0 FAIL, PASS ≥ baseline | `04` table, 16/0/0/2 both runs — summary only | ✅ (MINOR: evidence form) |
| AC-3 | ≥ 2 distinct increasing intermediate states on a pty'd stderr | `harness.out:30-36` — 26 states, **25 distinct intermediate**, monotonic, final 100.0; assertion in `states.py:24-27` requires `distinct ≥ N` **and** monotonic **and** final == 100.0; fixture 8 388 608 B throttled ~2.5 s | ✅ |
| AC-4 | stderr → file: zero `0x0D`, no states, tarball still installs | `harness.out:38-41` — stderr **0 bytes**, `0x0D`=0, `sing-box version 1.99.0-STUB` installed into the temp tree | ✅ |
| AC-5 | non-TTY: exactly one line beyond the two existing ones, naming version + arch | `harness.out:43-48` — 3 stdout lines; `↓ Fetching sing-box v1.99.0 (amd64) ...`; assertion is a line-count **and** a content grep (`harness.sh:194-197`) | ✅ |
| AC-6 | 500 on the tarball: `download_failed "$SB_URL"` → `check_network` → exit 1; byte-identity on the **non-TTY** capture | `harness.out:71-82` — stderr **byte-identical, 49 bytes**; stdout identical after removing the one mandated notice, delta asserted `== 1` line; all three runs exit 1; TTY run names the same URL + `check_network`. Code: `install.sh:384-388` unchanged inside `if !` | ✅ — see §"The one-byte discrepancy" |
| AC-7 | 302 → 200 installs | `harness.out:90-95` — request log `/redir/…` then `/gh/…`, rc=0 | ✅ |
| AC-8 | Both languages, no `unbound variable`, new key renders non-empty prose | `harness.out:58-69`; `harness.sh:225-234` greps for `unbound variable` on **both** streams and asserts the two notices are non-empty **and different**. Method substitution recorded as R-E (gate C-4) | ✅ |
| AC-9 | zh key set == en key set | `static.out:28-33` — 41/41, `zh-only=[] en-only=[]`, no placeholder mismatch. **Independently re-derived by this review** from `install.sh:145-185` / `:189-229`: same 41 names, same order | ✅ |
| AC-10 | T-01 phase model / banner / exit status unperturbed | `static.out:35-47` on **pre-change** coordinates (gate F-9 applied): replaced lines are exactly `324`, `352`, `362`; no overlap with `27-29` / `223-268` / `443-497`; 0 added code lines with `>`/`>>`/`2>&1`/`\|`; 0 `PHASE_*` assignments. Confirmed by reading `install.sh:27-29`, `:243-288`, `:465-519` — byte-for-byte the T-01 code | ✅ |
| AC-11 | Step 2 contributes nothing to the install log | Same diff-shape witness (D-13). Step 2 (`:366-393`) executes upstream of the log-sink probe (`:472-474`) and the diff introduces no redirection | ✅ |
| AC-12 | Exactly 5 artifact name lines, loop order, both modes, 0 × `0x0D` non-TTY | `harness.out:106-114` — 5 lines both modes, order compared against a literal expectation, `0x0D`=0 on **both** streams in both modes | ✅ (NIT: order asserted in one mode) |
| AC-13 | Loop 404 on the 3rd artifact: `download_failed` names it, exit 1 | `harness.out:116-124` — plus "minus the 5 new name lines, byte-identical to pre-change" | ✅ |
| AC-14 | Version query meter-free both streams in TTY mode; parsed version unchanged | `harness.out:84-88` — 0 `#` states, 0 `%` states, `SB_VER=1.99.0` identical to pre-change. Structurally guaranteed: `:373` takes `CURL_OPTS_QUIET`, which keeps `-s`, which sets `mute=noprogress` even on 7.29 | ✅ |
| AC-15 | Already installed → only the "already installed" line, no request | `harness.out:101-104` — 1 stdout line, **request log empty**. Code: `install.sh:367-368` short-circuit unchanged | ✅ |
| AC-16 | No new external command, no new file | `static.out:22-26`; grep over `install.sh` finds no `wget`/`pv`/`dd`/`stdbuf`; 0 new product files | ✅ |
| AC-17 | No curl option above the 7.29 floor | `static.out:12-20` — options in the file are exactly `-f -s -S -L --progress-bar`; forbidden trio absent. **Independently re-verified against the 7.29.0 tree** (below) | ✅ |
| AC-18 | No timeout/retry option added, removed or changed | `static.out:25` — 0 in the file, pre-change same. Grep confirms | ✅ |
| AC-19 | Shipping diff = `install.sh` + `CHANGELOG.md` over product paths | `static.out:49-58` — carve-outs (`docs/features/**`, `CONTEXT.md`, `.harness/**`) applied per gate C-3 | ✅ |
| AC-20 | No install, no `sc`, no service touched | `harness.sh:4-57` — non-root, `PATH` rebuilt **without** `/usr/local/bin`, host `sing-box` absence *asserted* (abort if visible), `systemctl`/`rc-*`/`sudo`/all six package managers stubbed to exit 99 (none fired), `install` stub refuses any destination outside the temp tree, `SB_BIN` repointed. Witness `MainPID=2500438` / `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST` identical before/after | ✅ — method is correct, see §Safety |

**20/20 implemented. No missing criterion.**

---

## Design fidelity check

| Design item (`02_SOLUTION_DESIGN.md`) | Implementation | Status |
|---|---|---|
| Policy block inserted after the curl bootstrap (`:110-114`) | `install.sh:116-132`, immediately after the `fi` at `:114` | ✅ |
| `CURL_OPTS_QUIET=(-f -s -S -L)` | `:128`, verbatim | ✅ |
| `CURL_OPTS_PROGRESS` = quiet off a terminal, `(-f -S -L --progress-bar)` on one | `:129-132`, verbatim | ✅ |
| `if/then/fi`, never `[ -t 2 ] && …` (Q3) | `:130-132` is `if … then … fi` | ✅ |
| No `${arr[@]+…}` guard (Q4) | Absent, correctly — both arrays are non-empty by construction | ✅ |
| Invariant: exactly one `-t 2`, zero `-t 1` | Grep over the whole file: one `[ -t 2 ]` at `:130`, zero `-t 1`. The shipped comment does **not** contain the literal, so textual and executed counts agree at 1/0 | ✅ (gate C-6 honoured) |
| `--progress-bar`, not `-#` (D-A3) | `:131` | ✅ |
| One `t()` key, both tables, same relative position (after `downloading)`) | `:149` (zh, after `:148`) and `:193` (en, after `:192`) — 5th entry of each block | ✅ (gate C-8 discharged) |
| Format strings `  ↓ 获取 %s ...` / `  ↓ Fetching %s ...`, one `%s`, no `\r` | `:149`, `:193` exactly; rendered through `printf "$fmt\n" "$@"` (`:234`) so always a complete line | ✅ |
| Artifact loop: name line then `"${CURL_OPTS_QUIET[@]}"` | `:344-345` | ✅ |
| Version query: flag substitution **and nothing else** on `:352-360` (→ `:373-381`) | `:373` swaps `-fsSL` → `"${CURL_OPTS_QUIET[@]}"`; `:374-381` (pipeline, semver guard, `download_failed`, `check_network`, `exit 1`) byte-identical to pre-change per S-7's hunk list (`-352 +373`, a 1-line replacement) | ✅ (gate C-7 discharged) |
| Notice placed **after** `SB_URL` and **after** the semver guard (Q2, BC-9) | `:382` `SB_URL=…`, `:383` notice, `:384` transfer | ✅ |
| Tarball: `"${CURL_OPTS_PROGRESS[@]}"`, still inside `if !` | `:384-388` | ✅ |
| Argument composed from **data only**, no prose outside `t()` | `"$rel"`; `"sing-box v$SB_VER ($ARCH)"` — no `SOURCE_DESC`-style language branch added | ✅ |
| No helper function, no new file, no new command, no new redirection, no `PHASE_*` | Confirmed by reading the file and by S-7 | ✅ |
| Quoting: `"${arr[@]}"` at all three sites | `:345`, `:373`, `:384` — all `"${…[@]}"`, none `[*]`, none unquoted. Additionally proven dynamically: `harness.out:132-138` parses each traced argv with `shlex` and asserts the four flags arrive as **four separate tokens**, which a `"${arr[*]}"` slip could not survive | ✅ |
| CHANGELOG: one Chinese entry (`docs/dev-map.md:17`) | `CHANGELOG.md:9`, under `[Unreleased] / ### 新增` | ✅ |
| Rule 85 counter-rule: no over-build | Two variables and one `if`. No function, no file, no knob, no Bash meter, no speculative generality. Under-build also checked: nothing the design required is missing | ✅ |
| Out-of-scope fences (`02` §14) | `bin/sc`, `systemd/`, ruleset path, timeouts/retries, checksums, `tar -xz` guard, `sc doctor`, `sc config --show`, step 1 / step 6 output — all untouched | ✅ |

**Zero design drift in the product.** Three refinements were declared rather than absorbed (C-3's byte
delta, R-3's token split, R-F's stdout scope); all three are verification wording, all three are
correct, and each is reviewed below or above.

---

## The one-byte discrepancy — derived, not waved through

The PM asked me not to accept "cosmetic" without deriving it. I did not.

**The measurement** (`gate_checks.out:16-20`): against a 500 response, `-fsSL` produces 49 bytes on
stderr; `-f -S -L --progress-bar` produces 50. Both exit 22, both end with the identical line
`curl: (22) The requested URL returned error: 500`. The extra byte is a bare **LF (`0x0A`)** that
curl's progress code emits to close the progress area — **not** a `0x0D`.

**Why AC-6 is nonetheless satisfied, structurally rather than by measurement:**

1. The extra byte exists only when `--progress-bar` is in the argv.
2. `--progress-bar` is in the argv only via `CURL_OPTS_PROGRESS`, and only when `[ -t 2 ]` was true
   at `install.sh:130`.
3. Between `:130` and the tarball transfer at `:384` nothing rebinds fd 2. I read every line: the only
   redirections in that span are per-command (`command -v curl >/dev/null 2>&1` at `:111`,
   `pkg_install`'s internal `>/dev/null`, `logname 2>/dev/null` at `:307`); there is no `exec 2>`, no
   block-level or function-level redirection. So `[ -t 2 ]` true at `:130` ⇒ fd 2 is still that
   terminal at `:384`.
4. Therefore the extra byte can only ever be written to a **terminal**. It can never reach
   `install.log`, CI output or a pasted issue report — those are exactly the cases where `[ -t 2 ]` is
   false and the flag vector is `-f -s -S -L`, which is bundling-identical to `-fsSL` (no option in
   the set takes an argument, so `-fsSL` and `-f -s -S -L` are the same four flags to curl's getopt).
5. AC-6's byte-identity clause is scoped by D-11 to the non-TTY capture, and that capture came back
   **byte-identical at 49 bytes** (`harness.out:73`).

**Conclusion: not a defect, and not a waiver.** It is confined by construction to the one stream where
no criterion asserts byte identity, it is an LF rather than the `0x0D` that B-3/AC-4 exist to keep out
of logs, and the developer surfaced it instead of burying it. The honest residue is that design C-3's
prediction ("does not change the failure text") was true of the *text* and false of the *bytes*; the
developer corrected the design's wording in `04` rather than restating it. That is the right handling.

**AC-6 vs B-4 (the developer's R-F).** AC-6 says "byte-identical" and B-4/AC-5 mandate one new stdout
line in **both** modes; taken literally the two cannot both hold on stdout. D-11 anticipated the
per-stream split but did not close it. The developer's resolution — stderr byte-identical, stdout
byte-identical after removing the one mandated line, plus an assertion that the delta is **exactly
one** line — is the strongest form the property can take and still pins text, URL, order and exit
status. Endorsed. No document needs editing; R-F records it.

---

## Dimension-by-dimension

**1 — Logic correctness.** `install.sh:130-132`: an `if` whose condition fails returns 0, so the block
cannot export a `1` into `set -e`; it is top-level anyway. Both arrays are non-empty at every
expansion, so the bash-4.2 unbound-array hazard guarded at `:324` genuinely does not apply and copying
that guard would have been misleading. `"${arr[@]}"` at all three sites (`:345`, `:373`, `:384`) — the
classic Bash defect this diff invited is absent, and is disproven dynamically as well as textually.
The three failure paths are untouched: `:346-348`, `:378-380`, `:385-387` still `download_failed` →
`check_network` → `exit 1` inside `if !` / `if [ -z … ]`, so `set -e` cannot pre-empt the bilingual
message. Boundary cases that are code-visible: BC-9 holds because the notice at `:383` sits after the
guard at `:377-381`; BC-13 holds because no new temp path is introduced and `:325` still owns
`$SB_TMPDIR`; BC-18 holds because `:367-368` short-circuits before any new output. No off-by-one, no
null/empty, no concurrency surface (the block is pure computation).

**2 — Requirement fidelity.** Table above: 20/20, walked criterion by criterion against code, not
against the developer's claims. B-1…B-12 all land: the meter is on the tarball only (B-1), gated on
stderr (B-2), silent off a terminal (B-3), one mode-independent notice line (B-4), failure handling
identical (B-5), five artifact name lines (B-6), version query meter-free (B-7), bilingual parity
(B-8), no new tool/file/knob (B-9), T-01 untouched (B-10), idempotent re-run inert (B-11), no
environment branching (B-12).

**3 — Design fidelity.** Table above: zero drift. Every gate condition C-1…C-8 discharged, including
the two the PM singled out (C-7: `:373-381` received the substitution and nothing else — the filed
abort defect was neither fixed nor re-filed; C-8: both tables, verified by me directly). C-6's
"exactly one *executed* `[ -t 2 ]`" reading was applied and the comment was not mutilated to satisfy a
grep.

**4 — Performance.** Zero additional requests: `--progress-bar` renders from the transfer already in
flight, no `HEAD` probe, no second connection. Two array expansions and one `test -t` at process
start. No loop, no allocation, no sync I/O added. Note in passing: the meter costs terminal writes
that were not there before, but only on a terminal, and only for a transfer already measured in tens
of megabytes.

**5 — Security.** Nothing changes about *what* is fetched, from where, or with what verification. No
credential is printed. No new file, no new permission, no sudoers change, no new interpreter input.
`$SB_VER` reaches the terminal on the success path for the first time — recorded as a NIT above,
explicitly sanctioned by `01` §7, and not a format-string hazard because arguments land in `"$@"`.
`-f` is retained at all three sites, so an HTML error page still cannot be mistaken for a payload.

**6 — Maintainability.** The names say what they select (`QUIET` / `PROGRESS`), not what letters they
contain. The block is 5 lines of code with a comment that earns its length. No dead code, no
premature abstraction — D-A1's refusal to write a wrapper function is vindicated by the code itself:
`:373` has no `-o` (its body goes to a command substitution) while `:345` and `:384` do, so any single
wrapper would need both a policy parameter and an output-mode parameter, i.e. `curl "$@"` wearing a
name. The one navigational gap is dev-map (MINOR above), and it is not the developer's to close.

---

## Test quality — I read the harness, not just its output

The gate predicted the harness would be the hard part and that its characteristic failure would be a
vacuous green. Assessment: **the evidence supports the AC claims.**

- **`ptyrun.py`** is a genuine `openpty` driver that can attach a pty to fd 1 only, fd 2 only, both or
  neither — so BC-3 ("stdout is a terminal, stderr is redirected") is actually expressible.
  `script -qec`, which cannot express it, was correctly refused. `raw_output()` clears
  `OPOST`/`ONLCR`/`ECHO` on the slave fd; without that, **every** `0x0D` assertion taken through a pty
  would have been measuring the terminal driver. This is a real, easily-missed defect that the
  developer found on itself and fixed.
- **Assertions are real.** Every `ok` is reached through `chk $r` with `r` set to 1 by a concrete
  comparison; `harness.sh:8` is `set -uo pipefail` (deliberately no `-e`, so a failing assertion
  records a FAIL rather than aborting the run — the right choice for a check runner).
- **AC-3 is not vacuous.** `states.py:24-27` requires `distinct ≥ N` **and** monotonic **and** a final
  state of exactly 100.0. The fixture is 8 MiB throttled to ~2.5 s, and NEG-1 proves the assertion
  fails on a 1 KiB unthrottled body (`states=1 distinct=0`). Insight L14's precedent — the T-02
  fixture that asserted nothing — is directly and demonstrably closed.
- **BC-3 is asserted on the right capture.** `harness.sh:217` tests `m_tf.err` where `m_tf` is
  `out=tty, err=file` — that is BC-3, not BC-1. `harness.sh:216` separately requires `m_ft.err` (BC-1)
  to be **non-empty**, so the pair proves the gate discriminates rather than merely being quiet.
  NEG-3 forces the progress array past the gate off a tty and the assertion fires (26 × `0x0D`) — the
  gate's central claim is falsifiable and was falsified on demand.
- **H-0 / NEG-2** close the anchored-`sed` vacuity hole: every extract is asserted non-empty **and**
  asserted to contain its expected anchor, and the policy block is proven **absent** from the
  pre-change file, so the "pre" arm cannot silently be the "post" arm.
- **The three self-caught vacuous greens are credible and material**, particularly the host
  `/usr/local/bin/sing-box` on `PATH` (insight L13's family — it would have short-circuited step 2 in
  every run while reporting PASS) and the stub-server port drift that had already produced a **false
  PASS** on NEG-3. A harness that catches a false PASS on its own negative control is a harness whose
  positives mean something.

Residual gaps, all minor and all disclosed: AC-2's evidence form (MINOR), AC-12's order assertion in
one mode (NIT), BC-16 not exercised (correctly — it imposes no requirement), and the
prompt→`LANG_CHOICE` mapping at `:300-305` not exercised (untouched by this diff, so no coverage lost;
recorded as R-E).

---

## Independent re-verification of the highest-consequence claim (C-1 / C-5)

R-1 was the design's top risk: if `--progress-bar` did not exist on curl 7.29, every RHEL/CentOS 7
install would die at step 2, and the failure is invisible on a modern box. The extracted 7.29.0 tree
is still on disk, so I checked it myself rather than trusting the paste:

- `include/curl/curlver.h:33` `#define LIBCURL_VERSION "7.29.0"`, `:67` timestamp `Wed Feb 6 … 2013`
  — the artifact dates itself.
- `src/tool_getparam.c:260` `{"#",  "progress-bar",             FALSE},` and `:863`
  `case '#': /* --progress-bar */`; also `src/tool_help.c:146`, `docs/curl.1:112`.
- `no-progress-meter` / `fail-with-body` / `retry-all-errors`: **0 occurrences** in the whole tree —
  AC-17's exclusion list is exactly the right list.
- C-2 on the floor: `src/tool_getparam.c:1484` `config->mute = config->noprogress = TRUE;` for `-s`,
  and `src/tool_operate.c:1124` installs the bar only under `… && !config->noprogress && !config->mute`
  — so `CURL_OPTS_QUIET` cannot leak a meter on RHEL 7 either.
- C-4 on the floor: `src/tool_operate.c:191` `config->showerror = -1; /* will show errors */`, so `-S`
  without `-s` is inert rather than an error — the progress variant keeps curl's error text.
- Bonus confirmation of D-1's leg 2 at the floor: `src/tool_operate.c:771` sets
  `noprogress = isatty = TRUE` only in the "body would go to the terminal" case, which `-o <file>`
  makes unreachable at all three sites. The gate is a correctness requirement, not cosmetics, on the
  oldest supported curl as well as the newest.

Two independent readers, one version-dated artifact, same conclusion. C-5 is discharged.

---

## Scope check

`git status`-equivalent from `static.out:49-58`: `M install.sh`, `M CHANGELOG.md` (product) plus
`M .harness/rejected-decisions.md`, `M CONTEXT.md`, `?? docs/features/install-binary-download-progress/`
(pipeline artifacts, carved out by D-12). **No leakage** into `bin/sc`, `systemd/`, the ruleset path,
timeouts/retries, `sc doctor` or `sc config --show` — verified by grep over the diff shape and by
reading the untouched regions of `install.sh`. `docs/dev-map.md` deliberately not edited (see MINOR).

---

## Safety

Nothing was executed by this review. The developer's AC-20 method is the **correct** one:
`systemctl show -p MainPID -p ActiveEnterTimestamp` taken outside every fragment, before and after the
whole session, identical on both sides (`MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31
17:04:23 CST`). Insight L22 is honoured — `is-active` would have printed `active` on both sides of a
restart and proved nothing. Corroborating structure rather than trust: `harness.sh:26-53` builds `PATH`
from scratch **without** `/usr/local/bin`, aborts if a host `sing-box` is visible, stubs
`systemctl`/`rc-service`/`rc-update`/`sudo`/all six package managers to print `HARNESS VIOLATION` and
exit 99 (none fired), and wraps `install` in a destination guard rejecting anything outside the temp
tree. The one disclosed leak — a read-only `sing-box version` against the host binary before the
`PATH` was rebuilt — touched no service and is exactly the kind of thing that should be reported
rather than quietly fixed.

---

## Carried forward (not this task's, not re-filed)

- `install.sh:373-381`'s silent abort on an API/transport failure — filed at
  `.harness/rejected-decisions.md:110`, correctly left alone (gate C-7 / F-8). **Not re-filed here.**
- F-7 — step 6's rule-set progress still invisible during an install. Structural reason, recorded
  upstream, unchanged by this task.
- F-11 — the committed key-parity gate is now four tasks deep. S-6 proves parity **today** but is not
  committed, so the `set -u` hazard is exactly as shippable for the next task. PM board item; AC-19
  forbids fixing it here. This is the highest-leverage open debt touching this file.

---

## Axis status

- **Standards-conformance**: 4 findings, worst = **MINOR** (`docs/dev-map.md` seam row, routed to
  PM/T-07 rather than to the developer). Repo conventions otherwise satisfied in full: bilingual
  parity (rule 50), Chinese CHANGELOG under `[Unreleased] / ### 新增` (dev-map:17), single
  self-contained installer file, no `\r` off a TTY (dev-map:69), curl-7.29 / bash-4.2 floors, all six
  package managers and both init systems untouched, all stage docs under the 500-line cap
  (`.harness/rules/70-doc-size.md`), insight-index at 25/30 lines with 2 proposed additions. No
  invented rules were applied — every NIT is labelled as preference and blocks nothing.
- **Spec/design-fidelity**: 2 findings, worst = **MINOR** (AC-2's evidence form). 20/20 acceptance
  criteria implemented and evidenced; 18/18 boundary conditions respected; zero design drift; all
  eight binding gate conditions discharged, including the two the file's history says are most
  dangerous (C-7 leave-alone, C-8 bilingual parity).

Aggregate = the more severe of the two = **MINOR**.

---

## Verdict

**APPROVED** — 0 CRITICAL, 0 MAJOR, 2 MINOR, 5 NIT.

Proceed to stage 6 (QA). The two MINORs are routed, not blocking: the dev-map row goes to **PM → T-07**
(it cannot be fixed here without breaching AC-19), and AC-2's re-run is already QA's charter. Nothing
returns to the developer.

The change is 22 net new lines, 12 of them a comment that stops the next reader from breaking the
gate. It does what the owner asked — the biggest download now shows progress — without putting a
single `0x0D` anywhere a log can see it, without touching T-01's outcome model, and without smuggling
in the adjacent bug it was explicitly told to leave alone.
