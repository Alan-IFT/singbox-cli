# Development Record — install-binary-download-progress (T-08)

- **Stage**: 4 (Developer), single-developer mode · **Date**: 2026-08-01
- **Inputs (read-only)**: `01_REQUIREMENT_ANALYSIS.md`, `02_SOLUTION_DESIGN.md`,
  `03_GATE_REVIEW.md` (`APPROVED FOR DEVELOPMENT`, conditions C-1…C-8), `.harness/insight-index.md`,
  `.harness/rules/50-singbox-cli.md`, `.harness/rules/85-design-discipline.md`, `AI-GUIDE.md`.
- **Verdict**: `READY FOR REVIEW`

## Summary

`install.sh` gained one **download flag policy block** after the curl bootstrap — `CURL_OPTS_QUIET`
(literally today's `-fsSL`, spelled out), `CURL_OPTS_PROGRESS` (the same off a terminal,
`-f -S -L --progress-bar` on one) and the file's only `[ -t 2 ]` — and all three curl invocations are
re-expressed through it; only the tarball takes the progress variant. One new `t()` key,
`fetching_item`, was added to **both** language tables and prints one complete line before the
artifact-loop fetches and before the tarball transfer. 13 lines of code + 12 of comment in
`install.sh`, plus one `CHANGELOG.md` entry. No new file, no new command, no new redirection, no
`PHASE_*` touched.

## Files changed

- `install.sh` — policy block after the curl bootstrap (`:116-133`); `fetching_item` in the zh table
  (`:149`) and the en table (`:193`); `t fetching_item "$rel"` + `"${CURL_OPTS_QUIET[@]}"` in the
  artifact loop (`:344-345`); `"${CURL_OPTS_QUIET[@]}"` at the version query (`:373`, **and nothing
  else on `:373-381`** — C-7); `t fetching_item "sing-box v$SB_VER ($ARCH)"` +
  `"${CURL_OPTS_PROGRESS[@]}"` at the tarball (`:383-384`).
- `CHANGELOG.md` — one Chinese `### 新增` entry.

Diff shape: 25 added lines / 3 replaced lines in `install.sh`; the 3 replaced lines are exactly the
three pre-change `curl` lines (`324`, `352`, `362`). Nothing else in the file was deleted or edited.

---

## C-1 — the curl 7.29 option floor (gating; discharged BEFORE the edit)

**Result: `--progress-bar` exists on the floor. The edit was safe to write.**

Evidence source is the **official 7.29.0 release tarball**, not a modern host:
`https://curl.se/download/archeology/curl-7.29.0.tar.gz`
(`sha256 67dc5b952ac489191b62dbe95b18d336b821649f61404a280186c72e8cd0b9d6`, 3 260 535 bytes).
`https://curl.se/download/curl-7.29.0.tar.gz` is 404 today — the archive lives under `archeology/`.

Version-dating the artifact — `include/curl/curlver.h`:

```
33:#define LIBCURL_VERSION "7.29.0"
67:#define LIBCURL_TIMESTAMP "Wed Feb  6 10:13:08 UTC 2013"
```

The option, in that tarball:

```
src/tool_getparam.c:260   {"#",  "progress-bar",             FALSE},
src/tool_getparam.c:863     case '#': /* --progress-bar */
src/tool_help.c:146       " -#, --progress-bar  Display transfer progress as a progress bar",
docs/curl.1:112           .IP "-#, --progress-bar"
```

The other four flags are in the same table on the same version: `-f` `:209`, `-L` `:223`, `-s` `:243`,
`-S` `:244`. A `grep -rn` over `src/` and `docs/curl.1` for `no-progress-meter`, `fail-with-body` and
`retry-all-errors` returns **no match** — the three options BC-10 forbids genuinely post-date the
floor, so AC-17's exclusion list is the right list.

Bonus, and it settles design C-2 **on the floor version** rather than only on my curl 8.5:
`src/tool_operate.c:1123-1124` installs the bar only under
`(progressmode == CURL_PROGRESS_BAR) && !noprogress && !mute`, and `src/tool_getparam.c:1481-1484`
shows `-s` setting `mute = noprogress = TRUE`. So on curl 7.29 `-s` beats `--progress-bar` exactly as
it does today — `CURL_OPTS_QUIET` cannot leak a meter on RHEL/CentOS 7 either.

> **Warning for anyone repeating this.** The obvious shortcut — the `curl-7_29_0` **git tag** — is
> *not* a clean version-dated source: at that tag `include/curl/curlver.h` still reads
> `LIBCURL_VERSION "7.28.2-DEV"`. The content is the same, but the tag cannot date itself. Use the
> release tarball.

## C-2 — design §8 C-1…C-4, C-6 (dynamic, non-root, local stub only)

Script: `scratchpad/h/gate_checks.sh`; full output `scratchpad/h/gate_checks.out`. Run as `alan`
(uid 1000) against a local `http.server` stub serving an 8 MiB throttled body.

| # | Claim | Observed | Verdict |
|---|---|---|---|
| C-1 | meter on **stderr**, not self-gated on `isatty` | stderr = 2081 bytes containing **26 × `0x0D`** *while stderr was a plain file*; stdout capture = **0 bytes**; exit 0 | PASS — D-1's leg 1 and leg 2 both hold, so `[ -t 2 ]` is a correctness gate, not cosmetics |
| C-2 | `-s` beats `--progress-bar` | `curl -s --progress-bar …` → stderr **0 bytes** | PASS (and confirmed on 7.29 source, above) |
| C-3 | dropping `-s` does not change the failure text | both exit **22**; both last non-empty lines are `curl: (22) The requested URL returned error: 500` | PASS **with a refinement — see below** |
| C-4 | `-S` without `-s` is accepted and inert | exit **22**, not 2 (`option unknown`) | PASS |
| C-6 | `VAR=$(pipeline)` aborts under `set -euo pipefail` | `V=$(false \| grep x \| head -1 \| sed …); echo reached` → no output, exit 1 | PASS — §11 R-D stands; `install.sh:373-381`'s abort is real and **left alone** (C-7) |

**C-3 refined.** The design predicted an identical trailing line. Byte-exactly, the
`--progress-bar` run's stderr is **one byte longer**: it appends a bare `\n` closing the progress
area. The error *text* is identical. No criterion is affected — AC-6's byte-identity clause is
evaluated on the non-TTY capture, where the two flag vectors are the same and the extra byte cannot
occur. Recorded, not hidden.

---

## Verification

### Layer S — static, 7/7 PASS (`scratchpad/h/static.sh`, output `static.out`)

| # | AC | Result |
|---|---|---|
| S-1 | AC-1 | `bash -n install.sh` clean |
| S-3 | invariant | **executed** `[ -t 2 ]` = 1, `[ -t 1 ]` = 0; textual counts also 1 / 0 — see C-6 note below |
| S-4 | AC-17 | none of `--no-progress-meter` / `--fail-with-body` / `--retry-all-errors`; options in the file are exactly `-f -s -S -L --progress-bar` |
| S-5 | AC-16, AC-18 | no `wget`/`pv`/`dd`/`stdbuf` in added lines; 0 timeout/retry options in the file (same as pre-change); 0 new files |
| S-6 | AC-9 | zh 41 keys / en 41 keys, **zero** one-sided keys, zero placeholder-count mismatches, `fetching_item` = 1 `%s` in both |
| S-7 | AC-10, AC-11 | pre-change lines replaced = `324`, `352`, `362` only; **no** overlap with `27-29` / `223-268` / `443-497`; added code lines carrying `>`/`>>`/`2>&1`/`\|` = **NONE**; added lines assigning `PHASE_*` = **NONE** |
| S-8 | AC-19 | product paths touched = `install.sh`, `CHANGELOG.md` (C-3 applied — see below) |

**C-6 applied to S-3.** The invariant is read as "exactly one *executed* `[ -t 2 ]`". The check
strips comment lines before counting and reports **both** numbers. As it happens the comment does not
contain the literal `-t 2`, so the textual count is also 1 — but the check is the stricter one either
way, and no comment was removed to satisfy a grep. The same comment-stripping is applied in S-7,
where it is load-bearing: the shipped comment legitimately contains `` `... > install.log 2>&1` ``,
and a naive token scan would have reported a false "new redirection introduced".

**C-3 applied to S-8.** S-8 as designed was a bare two-file `git diff --stat`, which fails on a
compliant diff once the pipeline's own documents exist (gate F-1). It is evaluated over **product
paths**, with `docs/features/**`, `CONTEXT.md` and `.harness/**` filtered out. Full tree state:
`M .harness/rejected-decisions.md`, `M CONTEXT.md`, `?? docs/features/install-binary-download-progress/`
(all carved out) + `M install.sh`, `M CHANGELOG.md` (the shipping diff).

### Layer H — extracted-fragment harness, 18/18 PASS (`scratchpad/h/harness.sh`, output `harness.out`)

Real `curl`, real bytes, fake world: a local stub server, a **PTY driver** that attaches a pty to
fd 1 only / fd 2 only / both / neither, fragments extracted from the real `install.sh` by comment
anchor, and a stub `PATH` prefix. `script -qec` was **not** used — it cannot express BC-3, which is
the case the whole design turns on.

| Criterion | Observed |
|---|---|
| AC-3 | pty on fd 2: **26 progress states, 25 distinct intermediate**, monotonically increasing, final `100.0%`; exit 0 |
| AC-4 | stderr → file: stderr **0 bytes, 0 × `0x0D`**; binary still installed (`sing-box version 1.99.0-STUB`) |
| AC-5 | non-TTY stdout = exactly **3 lines**: `step2_installing`, the notice, `step2_done`; the notice names `v1.99.0` and `amd64` |
| BC-1/2/3/4 | stdout is **byte-identical (149 bytes, 0 × `0x0D`) in all four modes**; stderr = 26 × `0x0D` when fd 2 is a pty, **0** otherwise. **BC-3 (stdout tty, stderr file) → 0** |
| AC-6 | non-TTY vs pre-change: **stderr byte-identical (49 bytes)**; stdout differs by **exactly one line**, the mandated notice, and is byte-identical once removed. TTY: same URL, `check_network`, exit 1. All three runs exit 1 |
| AC-7 | `302 → 200`: request log shows `/redir/…` then `/gh/…`; binary installed; exit 0 |
| AC-8 | `LANG_CHOICE=en` and `=zh` both exit 0, **no `unbound variable`**, notices non-empty and different (`↓ Fetching …` vs `↓ 获取 …`) |
| AC-12 | loop: exactly **5** `↓ Fetching` lines in loop order, both modes; 0 × `0x0D` on stdout **and stderr** (D-4: the loop gets no meter even on a tty) |
| AC-13 | 404 on the third artifact: `download_failed` names that URL, `check_network`, exit 1; minus the 5 new name lines the output is **byte-identical to pre-change** |
| AC-14 | TTY mode, tarball 404 so only the query could have drawn: **zero** `#` and **zero** `%` states on stderr; parsed `SB_VER` unchanged (`v1.99.0` in the URL, identical to the pre-change capture) |
| AC-15 | `sing-box` pre-installed: **1** stdout line ("already installed"), no `↓`, **request log empty** |
| BC-5 | chunked, no `Content-Length`: transfer succeeds, binary installed, exit 0 |
| R-3 | argv at all 7 curl sites verified by `shlex`; traces identical to pre-change modulo the token split — **see refinement** |
| H-0 | all 9 extracts non-empty **and** carrying their expected anchor; the policy block is provably absent from the pre-change file |
| H-1 | the mutation changes **exactly 2 lines**, and both are identical after erasing the host |

**Negative controls (proof the tests can fail).** NEG-1: retarget the stub to a 1 KiB unthrottled
body — AC-3's assertion **fails**, so the insight-L14 "fixture too small to assert anything" case is
detected. NEG-2: an anchor that matches nothing — the extractor **reports it** instead of silently
producing an empty fragment. NEG-3: force `CURL_OPTS_PROGRESS` past the gate off a tty — the BC-3
assertion sees **26 × `0x0D`** on a redirected stderr and **fails**.

**R-3 refined.** The design asks for traces that are "argv-identical". They cannot be, by the
design's own choice: `-fsSL` is **one** argv token and `-f -s -S -L` is **four**. The property R-3
protects (D-A2: a `${arr[*]}` or unquoted slip changes argv silently) is checked in the honest form —
that split is normalised away, everything else (flag set, order, URL, `-o` path, invocation count) is
compared byte-for-byte, and each invocation's argv is additionally parsed with `shlex` to assert the
four flags arrive as **four separate tokens**, which a `"${arr[*]}"` slip could not survive.

### Three vacuous-greens the harness caught on itself

The gate predicted the harness, not the diff, would be the hard part. It was, and all three near-misses
were of exactly the predicted kind:

1. **The host's real `/usr/local/bin/sing-box` was on `PATH`**, so `command -v sing-box` short-circuited
   step 2 in every run: the first pass reported `[2/7] sing-box already installed: sing-box version
   1.13.15` and would have "passed" AC-15 while testing nothing else. The fragment also invoked the
   **real** binary (`sing-box version`, read-only). This is insight L13's family. Fixed by building
   `PATH` from scratch without `/usr/local/bin` and **asserting** no host `sing-box` is visible,
   aborting the harness if one is.
2. **The pty was in cooked mode**, so `ONLCR` turned every `\n` into `\r\n`: the stdout captures came
   back with 2 spurious `0x0D` bytes the program never wrote. Every "no `0x0D` off a TTY" assertion
   would have been measuring the terminal driver. Fixed by clearing `OPOST`/`ONLCR`/`ECHO` on the
   slave fd.
3. **Restarting the stub server to change a fixture moved its ephemeral port**, so every later
   scenario silently hit a dead socket — which made NEG-3 report a false PASS. Fixed by making the
   server re-read a `control.json` (faults + throttle + fixture) per request and never restarting it.

## Method substitutions, recorded (C-4)

Recorded in the R-A / R-B / R-C style, so the reviewer sees the substitution rather than inferring it:

- **R-E — AC-8 is discharged by fragment runs with `LANG_CHOICE` preset, not by "a full run answering
  1 / answering 2".** A full run is forbidden by AC-20 (it reaches `pkg_install`, `systemctl`, `/etc`,
  `/usr/local`). Presetting `LANG_CHOICE` drives both `case` blocks of `t()` directly, which is what
  BC-11/E-14 is about. What it does **not** exercise is the prompt → `LANG_CHOICE` mapping at
  `install.sh:280-285`; that code is untouched by this diff, so no coverage is lost. [gate F-2]
- **R-F — AC-6's byte-identity holds exactly on stderr, and modulo one line on stdout.** D-11 argues
  byte-identity is achievable off a TTY because the flag vector is unchanged. True of stderr (49
  bytes, identical). It cannot be literally true of stdout, because the same task adds one line there
  *by design* in both modes (B-4/AC-5) — D-11 and the design overlooked the interaction with their own
  B-4. Discharged in the strongest available form: stderr byte-identical, stdout byte-identical after
  removing the one mandated line, plus "the delta is exactly one line". AC-13 is asserted the same way.
- **R-G — S-7 and S-3 count *code*, not text.** See the C-6 note above.

## Design drift

**None in the product.** Every edit site, the array contents, the `if/then/fi` form (not `&&` — Q3),
the absence of an `${arr[@]+…}` guard (Q4), the notice's placement between `SB_URL` and the transfer
(Q2), the one-key-two-tables shape and the exact format strings are as specified in `02` §3.

The three items above (C-3, R-3, R-F) are refinements to **verification wording**, not to the design's
behaviour. They are flagged rather than absorbed, so the reviewer can overrule any of them.

## Safety (AC-20) — the live system was not touched

- Everything ran as **`alan` (uid 1000)**, never root, never `sudo`.
- No fragment reached `pkg_install`, `systemctl`, `/etc`, `/usr/local`, or `bin/sc`. `systemctl`,
  `rc-service`, `rc-update`, `sudo` and all six package managers were stubbed on the `PATH` prefix to
  print `HARNESS VIOLATION` and exit 99; **none of them fired**. `install` was stubbed with a guard
  that refuses any destination outside the temp tree; `SB_BIN` was repointed to `$TMP/bin/sing-box`.
- `install.sh` was never executed end-to-end. Only two comment-anchored fragments were run.
- Witness, taken with `systemctl show -p MainPID -p ActiveEnterTimestamp` (**never `is-active`** —
  insight L22 records that `is-active` prints `active` on both sides of a restart):

```
before: MainPID=2500438  ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
after:  MainPID=2500438  ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST
```

  Identical. `/usr/local/bin/sing-box` and `/usr/local/bin/sc` still carry their 2026-07-30 12:47
  mtimes. The one leak that did occur — a read-only `sing-box version` on the host binary, before the
  `PATH` was rebuilt — touched no service and is described in "vacuous-greens" above.

## verify_all result

| | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| Baseline (pre-change, same tree) | 16 | 0 | 0 | 2 |
| After changes | 16 | 0 | 0 | 2 |

**Delta: 0 new failures, 0 new warnings, baseline preserved.** B.1 (`bash -n install.sh`) is a real
gate and passes. B.2/B.3 remain `SKIP` — this task may not commit a harness (AC-19 / D-A8), so it does
not replace them; the committed harness is T-07's, and the Layer S/H scripts are handed to QA and to
T-07 rather than committed.

## Open issues for review

1. **`docs/dev-map.md` was deliberately not updated.** No file, folder or module was added, moved or
   removed, so the "update on structural change" trigger did not fire; and AC-19's carve-out list
   (`docs/features/**`, `CONTEXT.md`, `.harness/**`) does **not** include `docs/dev-map.md`, so editing
   it would arguably widen the shipping diff. A one-line row under "Reusable utilities" —
   *"download flag choice → `CURL_OPTS_QUIET` / `CURL_OPTS_PROGRESS` in `install.sh`; never re-spell
   `-fsSL` at a call site"* — would genuinely help T-07 find the seam D-A2 was built for. **PM/reviewer
   decision**, not taken unilaterally here.
2. **`install.sh:373-381`'s silent abort was left untouched** (C-7). Already filed at
   `.harness/rejected-decisions.md:110`; **not re-filed** (gate F-8).
3. **Gate F-7 stands unchanged**: step 6's rule-set progress is still invisible during an install.
   Out of scope here, recorded upstream, still the one place the owner's original symptom can recur.
4. **Gate F-11 (committed key-parity gate) is now four tasks deep.** S-6 proves parity today but is
   not committed, so the `set -u` hazard is exactly as shippable for the next task as it was for this
   one. PM board item, not fixable inside AC-19.
5. `BC-16` (very narrow terminal / unset `TERM`) was not exercised: BC-16 imposes no requirement, so
   there is nothing to assert. Noted so QA does not assume it was covered.

## Dev-map updates

None — no structural change. See "Open issues" item 1.

## Insight to surface

- The dev box carries a real `/usr/local/bin/sing-box`, so any installer harness that prepends to `$PATH` instead of rebuilding it makes `install.sh:346`'s `command -v sing-box` short-circuit step 2 and then invokes the *installed* binary — the harness reports PASS having tested nothing · evidence: install-binary-download-progress
- A pty in cooked mode translates every LF into CR LF, so a `0x0D`-count assertion taken through a PTY driver measures the terminal driver unless `OPOST`/`ONLCR` are cleared on the slave fd — the project's "no `\r` off a TTY" rule (`docs/dev-map.md:69`) cannot be tested with a default pty · evidence: install-binary-download-progress

## Verdict

**READY FOR REVIEW**
