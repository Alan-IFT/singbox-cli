# 02 — Solution Design: `install-binary-download-progress`

- **Task**: T-08 (`docs/batches/default/BATCH_PLAN.md:19`) · **Mode**: `full` · **Date**: 2026-08-01
- **Upstream**: `docs/features/install-binary-download-progress/01_REQUIREMENT_ANALYSIS.md` — verdict
  `READY`. Not edited by this stage. One rationale defect found in it: §11 R-D.
- **Decision mode**: deferred-human (`defer, do not ask`). Every judgment call below is resolved and
  recorded in §9 with its rationale.
- **Partition**: single-developer (`.harness/rules/50-singbox-cli.md` §Partitioning; no
  `.harness/agents/dev-*.md` exist) — no partition-assignment section.

---

## 1. Architecture summary

`install.sh` gains **one download flag policy block** — two arrays and the file's only `[ -t 2 ]` —
placed immediately after the curl bootstrap (`install.sh:110-114`), and every one of the script's
three `curl` invocations is re-expressed through it. Two of them (`:324` artifact loop, `:352`
version query) take the quiet array, which expands to today's exact `-fsSL`; the tarball transfer
(`:362`) takes the progress array, which is the same flags off a terminal and `-f -S -L
--progress-bar` on one. One new `t()` key, `fetching_item`, prints one complete line before a named
transfer starts and is used by both the artifact loop and step 2, so the installer's "a transfer is
starting, here is what it is" line has exactly one spelling. No new file, no new command, no new
redirection, no phase variable touched.

The deep-module claim, stated honestly: the policy block is **not** a deep module — it is two
variables and one `if`. It earns its place by the *duplicated judgment* test in
`.harness/rules/85-design-discipline.md` §2: "which flags does an installer download use, and can it
put control characters on a captured stream" is currently answered by copy-pasting `-fsSL` at three
sites. After this change it is answered in one place and cited at three, and the next row that must
touch download flags (T-07's restricted-network harness) has one edit point instead of three.

---

## 2. Affected modules

| File | Change |
|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | the only production file changed — 4 edit sites, ~14 net lines |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one user-visible entry (written in Chinese, per `docs/dev-map.md`) |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | glossary term **quiet notice** (added by this stage, already written) |
| `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | two records (added by this stage, already written) |

Not touched, deliberately: `bin/sc`, `uninstall.sh`, `systemd/`, `README*.md`,
`.harness/scripts/verify_all.sh`. AC-19 constrains the *shipping* diff to `install.sh` +
`CHANGELOG.md`; the three files above are harness/doc artifacts of this stage, not product code.

---

## 3. Module decomposition

### 3.1 The download flag policy block (new; `install.sh`, inserted after line 114)

Placement constraint: after the curl bootstrap (`install.sh:110-114`, where curl's availability is
established) and before the first consumer (`install.sh:324`). It has no dependency on
`LANG_CHOICE`, so it does not need to follow the language prompt.

Public API — two shell globals and one invariant:

| Name | Type | Value | Consumers |
|---|---|---|---|
| `CURL_OPTS_QUIET` | array | `(-f -s -S -L)` — literally today's `-fsSL` | `install.sh:324`, `install.sh:352` |
| `CURL_OPTS_PROGRESS` | array | `CURL_OPTS_QUIET` off a terminal; `(-f -S -L --progress-bar)` when `[ -t 2 ]` | `install.sh:362` |
| invariant | — | `install.sh` contains exactly **one** `-t 2` test and exactly **zero** `-t 1` tests | grep-checkable (§10 S-3) |

Pseudo-code (the developer writes the real thing; the comment is load-bearing and should ship close
to this wording):

```
# Download flag policy — decided once, for every curl in this script.
#
# curl writes its progress meter to STDERR, and does NOT suppress it when stderr
# is not a terminal — silencing it is exactly what -s does. So the terminal-ness
# of STDERR, not stdout, decides whether 0x0D and partial redraws can land in a
# captured log (`... > install.log 2>&1`, CI output, issue reports).
#
# -s and --progress-bar are not additive: -s wins and shows nothing. So the
# progress variant DROPS -s rather than adding a flag. -S is kept in both: with
# -s it is what keeps curl's error text on stderr, without -s it is a no-op.
CURL_OPTS_QUIET=(-f -s -S -L)
CURL_OPTS_PROGRESS=("${CURL_OPTS_QUIET[@]}")
if [ -t 2 ]; then
    CURL_OPTS_PROGRESS=(-f -S -L --progress-bar)
fi
```

Two shell constraints the developer must honour:

- **Never** write this as `[ -t 2 ] && CURL_OPTS_PROGRESS=(...)`. The file uses that idiom safely at
  `:69`, `:272`, `:310`, but only because those are top-level statements; the `if/then/fi` form is
  used here so the block can never become the last statement of a function and export a `1` into
  `set -e`. (`.harness/insight-index.md:12` is the sibling trap for redirections.)
- `"${CURL_OPTS_QUIET[@]}"` needs **no** `${arr[@]+...}` guard. The bash-4.2 unbound-array hazard
  guarded at `install.sh:304` applies to arrays that can be *empty*; both of these are non-empty by
  construction. Do not copy that guard here — it would suggest the arrays can be empty.

### 3.2 The `fetching_item` message key (new; one key, both tables)

One key, one `%s`, used by both call sites, because both print the same thing: *a named transfer is
starting*. Insert at the **same relative position** in both `case` blocks — immediately after
`downloading)` (`install.sh:130` zh / `:173` en) — so the two tables stay line-for-line parallel and
a one-language patch shows a lopsided diff.

| Language | Format string |
|---|---|
| zh (`install.sh` ~`:131`) | `  ↓ 获取 %s ...` |
| en (`install.sh` ~`:175`) | `  ↓ Fetching %s ...` |

Both branches: exactly one `%s`, no other `%`, no `\r`, rendered by `t()`'s
`printf "$fmt\n"` (`install.sh:212-217`) so it is always a complete line. The `↓` follows the file's
existing glyph vocabulary (`▶ ● ✗ ⚠️ ✅ ❌`); the two-space indent matches `step2_done`
(`install.sh:140`/`:183`).

Arguments, composed at the call site from **pure data only** (no prose, therefore no second language
branch outside `t()`):

- artifact loop: `t fetching_item "$rel"` → `  ↓ Fetching bin/sc ...` (B-6: repository-relative path)
- step 2: `t fetching_item "sing-box v$SB_VER ($ARCH)"` → `  ↓ Fetching sing-box v1.10.0 (amd64) ...`
  (B-4: resolved version + target architecture)

This is the design's answer to the "make the `set -u` abort class structurally hard" instruction, and
it is the honest one: **one new key instead of two halves the parity surface**, and composing the
argument from data avoids reproducing the `SOURCE_DESC` pattern at `install.sh:309-310`, which is a
language branch living *outside* `t()`. What it does **not** do is make the class impossible — see
§9 D-6 for why the `local fmt="$key"` fallback was declined and where the structural fix is homed.

### 3.3 Edit sites (existing code)

| Site | Current | After |
|---|---|---|
| `install.sh:317-329` (artifact loop) | `do` body starts with `if ! curl -fsSL ...` | `do` body starts with `t fetching_item "$rel"`, then `if ! curl "${CURL_OPTS_QUIET[@]}" "$RAW_BASE/$rel" -o "$ARTIFACT_DIR/$rel"; then` |
| `install.sh:352` (version query) | `SB_VER=$(curl -fsSL "https://api.github.com/..." \| ...)` | `-fsSL` → `"${CURL_OPTS_QUIET[@]}"`; **nothing else on `:352-360` changes** |
| `install.sh:361-362` (tarball) | `SB_URL=...` then `if ! curl -fsSL "$SB_URL" -o ...` | `SB_URL=...`, then `t fetching_item "sing-box v$SB_VER ($ARCH)"`, then `if ! curl "${CURL_OPTS_PROGRESS[@]}" "$SB_URL" -o "$SB_TMPDIR/sing-box.tar.gz"; then` |

The notice goes **after** the `SB_URL` assignment so that nothing can fail between the notice and the
transfer it labels, and after the semver validation at `:356-360` so BC-9 holds (no line can name an
empty version).

---

## 4. Data model changes

None. No file, schema, state file, settings key, environment variable or on-disk artifact is added,
removed or changed. `/etc/sing-box/settings.json`, `/var/log/sing-box/install.log` and
`$LIB_DIR/distro-info` are all untouched by this diff.

---

## 5. Contracts

This is a CLI, so the contracts are stream contracts.

### 5.1 Output contract (per stream, per mode)

| Stream | stderr is a TTY | stderr is not a TTY |
|---|---|---|
| stdout | 5 artifact lines (remote path only) + 1 notice line; no `0x0D` | identical, byte for byte |
| stderr | curl's own single-line bar for the tarball only, redrawn with `0x0D` | nothing (identical to today) |
| exit status | derived by `install_report` (`install.sh:496-497`), unchanged | unchanged |

`stdout` is **mode-independent**: that is the whole point of gating on stderr, and it is what makes
BC-1 (`... | tee install.log`) work — the terminal gets the bar, the log gets the notice.

### 5.2 curl invocation contract

| Property | Guarantee | Why it survives |
|---|---|---|
| HTTP ≥ 400 → non-zero exit | kept | `-f` in both arrays |
| redirects followed | kept | `-L` in both arrays |
| error text on stderr | kept | `-S` with `-s`; default behaviour without `-s` |
| body written to `-o <file>` | kept | argument, not a flag |
| no timeout/retry option | kept | none added (AC-18) |
| option floor | curl 7.29 | only `-f -s -S -L --progress-bar`, all pre-7.29 |

### 5.3 Failure contract (unchanged)

For all three sites: non-zero curl → `t download_failed "<url>"` → `t check_network` → `exit 1`, with
the same URL argument as today, still inside an `if !` condition so `set -e` cannot abort before the
bilingual message prints (`install.sh:325-327`, `:363-365`).

One honest qualifier on AC-6 ("byte-identical to the pre-change run"): that is literally achievable
**in the non-TTY capture**, where the flags are identical to today's. In the TTY capture the
pre-change run has no meter and the post-change run has one, so AC-6 must be evaluated on the non-TTY
capture, plus a TTY variant asserting *message present, same URL, exit 1*. Recorded as an
interpretation, not a change: §11 R-A.

---

## 6. Flow

```
step 2 (install.sh:345-371), sing-box NOT already present
  │
  ├─ t step2_installing                                  → stdout
  ├─ mktemp -d ; CLEANUP_DIRS+=                          (EXIT trap :304-305 owns it)
  ├─ SB_VER=$( curl "${CURL_OPTS_QUIET[@]}" api.github… | grep | head | sed )
  │        └─ no meter on either stream, in either mode          (B-7 / D-5)
  ├─ semver validation :356-360 ──fail──▶ download_failed / check_network / exit 1
  ├─ SB_URL="https://github.com/…/sing-box-${SB_VER}-linux-${ARCH}.tar.gz"
  ├─ t fetching_item "sing-box v$SB_VER ($ARCH)"         → stdout, both modes   (B-4)
  ├─ curl "${CURL_OPTS_PROGRESS[@]}" "$SB_URL" -o …
  │        ├─ [ -t 2 ] true  → -f -S -L --progress-bar → bar redrawn on stderr  (B-1)
  │        └─ [ -t 2 ] false → -f -s -S -L             → nothing on stderr      (B-3)
  │        └─ non-zero ─────▶ download_failed "$SB_URL" / check_network / exit 1
  ├─ tar -xz …                (unchanged, still unguarded — E-13, out of scope)
  ├─ install -m 755 … "$SB_BIN"
  └─ t step2_done "$(sing-box version | head -1)"        → stdout

nothing below step 2 is reached differently: :443-452 log-sink probe, :454-463 step 6,
:465-492 step 7, :496-497 install_report — untouched, unread, unreferenced by this diff.
```

---

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| A byte/percentage progress meter | curl's own `--progress-bar` | external tool, already a hard dependency (`install.sh:79`, `:111-114`) | **Reuse as-is.** No Bash meter is written (D-3, `.harness/rules/85-design-discipline.md` counter-rule). |
| Bilingual message rendering | `t()` | `install.sh:121-218` | Reuse; add exactly one key to both tables. |
| Download failure reporting | `download_failed` + `check_network` keys | `install.sh:131-132` / `:174-175` | Reuse untouched; no new failure string. |
| Temp-dir lifetime / cleanup | `CLEANUP_DIRS` + `cleanup()` EXIT trap | `install.sh:300-305`, `:350-351` | Reuse; no new temp path is created (BC-13). |
| Outcome + exit-status derivation | `PHASE_*`, `LOG_SINK` probe, `install_report()` | `install.sh:27-29`, `:450-452`, `:223-268` | **Do not touch.** Step 2 is upstream; this diff adds no redirection and assigns no phase (B-10). |
| Visual language for progress | `_fetch_to_temp()`'s TTY-gated redraw | `bin/sc:791-811`, `:1176`, `:1183-1206` | **Reference only — copy the language, share no code.** Bash/curl vs Python/urllib (§4.1 of the requirement, T-02's own §4 item 6). |
| "Is this stream safe for control characters?" | (none in `install.sh` — zero `-t` tests today, grep-verified) | — | **New, and minimal:** one `if [ -t 2 ]`, two arrays. Justified by the duplicated-judgment test, not by depth. |

---

## 8. Verification of the risky claims

I could not execute anything in this stage (read-only tooling, and the local `curl.1` is gzipped), so
every curl-behaviour claim below carries the command that settles it. **C-1 and C-5 are gating: the
developer runs them before writing the edit, and pastes the output into `04_DEVELOPMENT.md`.**

| # | Claim the design rests on | Verification (no root, no host service, local stub only) | Consequence if false |
|---|---|---|---|
| C-1 | curl writes its meter to **stderr**, and keeps writing it when stderr is a plain file (it does not self-gate on `isatty`) | `python3 -m http.server` in a temp dir with an 8 MiB file; `curl --progress-bar -o /dev/null http://127.0.0.1:$P/big 2>meter.err 1>body.out` → `meter.err` non-empty **and** contains `0x0D`; `body.out` empty | D-1 collapses: if the meter were on stdout, the gate must be `[ -t 1 ]`; if curl self-gated, no gate would be needed at all |
| C-2 | `-s` beats `--progress-bar` (they are not additive) | `curl -s --progress-bar -o /dev/null http://127.0.0.1:$P/big 2>x` → `x` is 0 bytes | the quiet array would leak a meter; the design would need `-s` removed everywhere |
| C-3 | dropping `-s` while keeping `-S -f` does not change the failure text | stub returns 500; `curl -f -S -L --progress-bar … 2>err; echo $?` → `22`, `err` ends with `curl: (22) …` — same trailing line as the `-fsSL` run | AC-6's TTY variant needs a different assertion |
| C-4 | `-S` without `-s` is accepted and inert | same run as C-3 exits 22, not 2 (`option unknown`) | drop `-S` from the progress array |
| C-5 | `--progress-bar` exists on the curl 7.29 floor (BC-10) | `grep -n 'progress-bar' src/tool_getparam.c` in the `curl-7.29.0` release tarball, **or** `man curl` on a RHEL/CentOS 7 host | **severe**: unknown option → curl exits 2 → every install on RHEL 7 fails at step 2. This is the highest-consequence claim in the design |
| C-6 | `VAR=$(pipeline)` failing aborts under `set -euo pipefail` (the §11 R-D finding) | `bash -c 'set -euo pipefail; V=$(false \| grep x \| head -1 \| sed s/a/b/); echo reached'` → prints nothing, non-zero exit | R-D is retracted; D-5's third reason stands as written |

My independent finding on **D-1: the analyst is right, and for the right reason.** Both legs matter
and both are checkable by C-1 alone. Leg one — the meter is a stderr artefact; curl's `--stderr`
option exists precisely to redirect "the progress meter and error messages", and `-o -` (body to
stdout) coexists with a meter, which is only possible if they are different streams. Leg two — curl
does **not** suppress the meter when stderr is not a terminal; the only isatty-like behaviour curl
has is disabling the meter when the *response body* would be written to the terminal, which does not
apply here because `-o <file>` is always used. Leg two is what makes the gate *necessary* rather than
cosmetic: without it, `sudo bash install.sh > install.log 2>&1` fills the log with `0x0D`, which is
the exact regression B-3/AC-4 exist to prevent. This also **supersedes `BATCH_PLAN.md:46-47`**, which
proposed `[ -t 1 ]` for the installer; that line was written before the stream question was examined,
and `[ -t 1 ]` would both silence the bar under `| tee` and fail to silence it under `2>file`.

---

## 9. Decisions recorded at this stage

**D-A1 — Two arrays and one `if`, not a helper function.** The dispatch brief anticipated "one
well-named function that all three call". On reading the code the premise does not hold: only *one*
of the three sites varies with TTY-ness (D-4 keeps the loop meter-free, D-5 keeps the API query
meter-free), so a function would have exactly one behavioural caller and would fail the deletion
test. A function that `echo`s flags would also add a subshell, word-splitting on the result, and the
`set -e` return-status trap. What the brief actually asks for — one place that decides — is delivered
by the invariant *"`install.sh` contains exactly one `-t 2`"*, which is grep-provable. Overturn if a
third mode appears (e.g. a `--quiet` installer flag), at which point the block becomes a function.

**D-A2 — The two meter-free sites still cite the policy block.** `:324` and `:352` change from a
literal `-fsSL` to `"${CURL_OPTS_QUIET[@]}"` even though their behaviour is unchanged. Cost: a
reader must look up the array; risk: a quoting mistake (mitigated by R-3's `set -x` argv diff).
Benefit: the flag vocabulary has one definition, so the choice at each site becomes *which policy*
rather than *which letters*, and T-07 — which inherits this code to add restricted-network
behaviour — gets one edit point. This is the "namable future edit" that
`.harness/rules/85-design-discipline.md` requires before accepting a new seam.

**D-A3 — `--progress-bar`, not `-#`.** Same option, and `#` is not a comment when it is not at the
start of a word, so `-#` inside an array is safe — but "safe once you know the rule" is not the same
as legible, and the long form reads as an intent at the call site. No behavioural difference.

**D-A4 — D-4 endorsed (artifact loop gets a name line, no meter).** Endorsed on a design ground the
requirement did not use: giving the loop a meter would create a **second** TTY-varying call site, so
the file would carry either two `-t 2` tests or a per-site policy lookup — the exact duplication this
design removes — and it would buy a byte meter for a 7-line unit file (E-11). The name line also
completes the existing headline at `:315` (`t downloading "$SOURCE_DESC"`), which already promises
"downloading install files" without ever saying which.

**D-A5 — D-5 endorsed (version query stays meter-free), but on two of its three reasons.** The size
argument and the "no destination the user cares about" argument hold. The third reason is factually
wrong — see §11 R-D — but the decision does not depend on it: a meter on a ~2 KB JSON body renders
one instantaneous bar, which is noise, and the boundary-marker role is carried by the notice line.
Additionally, keeping `-s` here is now *protective*: dropping it would put curl's own error text on
stderr immediately before an abort that prints no bilingual message, which reads as a raw tool error
to the user.

**D-A6 — One `t()` key, not two.** See §3.2. Fewer keys is the only lever this task has over the
`set -u` parity hazard that does not change `t()`'s contract.

**D-A7 — `local fmt="$key"` fallback in `t()` declined.** It would convert a loud, immediate abort
into a silent "print the key name" — trading a bug that is impossible to ship unnoticed for one that
is easy to ship unnoticed — while editing a function serving ~45 keys for a reason this task did not
raise. The real structural fix is a committed parity gate wired into `verify_all` B.2/B.3; AC-19
forbids committing it here, and `.harness/rejected-decisions.md#ruleset-unit-tests-in-t02` already
homes that with T-07. Recorded in `.harness/rejected-decisions.md#t-fmt-default-fallback`; the T-07
record gained this row as a re-occurrence.

**D-A8 — AC-9's parity extractor runs at QA time and is not committed.** AC-9 requires an extractor
script; AC-19 restricts the shipping diff; §4 item 9 gives T-07 the committed harness. Resolution:
QA writes the extractor under its temp dir, pastes it into `06_TEST_REPORT.md`, and it ships with
T-07. No contradiction between the ACs once stated.

---

## 10. Test strategy

**Absolute prohibition (AC-20 + `.harness/insight-index.md:13`, which records a run that restarted
the owner's live sing-box):** nothing in this strategy runs `install.sh` end-to-end, reaches
`pkg_install`, calls `systemctl start/stop/restart/enable`, runs `install -m` against a real system
path, writes under `/etc` or `/usr/local`, or imports `bin/sc`. Everything happens inside one
`mktemp -d` with a stub `PATH` prefix.

### Layer S — static, on the repo tree (no execution of installer logic)

| # | Check | Command shape |
|---|---|---|
| S-1 | AC-1 syntax gate | `bash -n install.sh` |
| S-2 | AC-2 | `.harness/scripts/verify_all.sh` before and after; FAIL=0, PASS not lower |
| S-3 | single decision point | `grep -c -- '-t 2' install.sh` = 1; `grep -c -- '-t 1' install.sh` = 0 |
| S-4 | AC-17 option floor | `grep -E -- '--no-progress-meter\|--fail-with-body\|--retry-all-errors' install.sh` → no match |
| S-5 | AC-16/AC-18 | `git diff` contains no `wget`/`pv`/`dd`/`stdbuf`, no `--max-time`/`--connect-timeout`/`--retry`, no new file |
| S-6 | AC-9 parity | extract both `case` blocks, compare key **sets** and per-key `%`-placeholder counts; must be equal |
| S-7 | AC-10/AC-11 (T-01 non-regression, static form) | `git diff -U0` touches **no** line in `27-29`, `223-268`, `443-497`; introduces **zero** new `>`/`>>`/`2>&1`/`\|` tokens; assigns no `PHASE_*` |
| S-8 | AC-19 | `git diff --stat` = `install.sh`, `CHANGELOG.md` |

S-7 replaces a live run of steps 6-7. This is a deliberate substitution and the gate reviewer should
weigh it: AC-10/AC-11 name "diff against pre-change captures", which would require a full install on
a real host — forbidden by AC-20. A diff-shape assertion is strictly cheaper and, for the property in
question ("this diff cannot have perturbed the phase model"), strictly stronger than one sampled run.
If the owner later wants the dynamic form, it belongs in T-07's container.

### Layer H — the extracted-fragment harness (real curl, real bytes, fake world)

Built once, in a temp dir, and used by every dynamic AC:

1. **Stub server.** `python3 -m http.server`-style script serving: `/raw/<5 artifact paths>` (small
   real bodies), `/api/...` (a captured `releases/latest` JSON, ~2 KB), `/gh/...` (an 8 MiB real
   `.tar.gz` containing one `sing-box` file), plus fault routes (`/500`, `/404`, a `302 → 200`
   chain). The tarball route sleeps ~20 ms per 64 KiB chunk → ~2.5 s transfer. This size/throttle is
   not decoration: `.harness/insight-index.md:14` records a T-02 fixture that asserted nothing
   because it fit in one buffer, and curl refreshes its bar on a time tick, so a sub-second transfer
   can legitimately render one state (BC-17). ≥ 8 MiB and ≥ 2 s makes AC-3's "two distinct
   intermediate states" a real assertion.
2. **Fragment extraction, anchored on comments, not line numbers.** `sed -n` from
   `# ----------------- step 2:` to `# ----------------- step 3:` for the tarball fragment, and from
   `CLEANUP_DIRS=()` to the end of the artifact loop for the loop fragment, plus the whole `t()`
   function and the policy block. Assert each extract is non-empty and contains the expected `curl`
   line — a silent empty extract is the failure mode that makes a harness pass vacuously.
3. **The only mutation:** `sed` rewrites `https://api.github.com` → `http://127.0.0.1:$P/api` and
   `https://github.com` → `http://127.0.0.1:$P/gh`; `RAW_BASE` is a variable (`install.sh:13`) so the
   loop needs no mutation at all. `diff` the extracted vs mutated text and assert the hunks are
   exactly those two host rewrites. Rationale: keeping **real curl** is the entire point — a stubbed
   `curl` could not test a curl flag.
4. **Stub `PATH` prefix** containing `install` (copies into the temp tree) and `sing-box` (prints a
   fake version line); `SB_BIN="$TMP/bin/sing-box"`. Real `tar` is used and extracts into the temp
   dir. `systemctl` is never on the path of any fragment executed here.
5. **PTY driver:** a small `python3` `pty.openpty()` runner that can attach a pty to fd 2 only, fd 1
   only, both, or neither — that is exactly BC-1/BC-2/BC-3/BC-4. `script -qec` is the fallback if
   `pty` is unavailable, but it cannot express "stdout tty, stderr file", so prefer the python driver.

| AC | How Layer H discharges it |
|---|---|
| AC-3 | pty on fd 2; capture stderr; assert ≥ 2 distinct increasing states before the final one |
| AC-4 | stderr → file; assert `tr -d -c '\r' < err \| wc -c` = 0, file effectively empty, tarball still extracted |
| AC-5 | non-TTY run; stdout has exactly one line beyond `step2_installing` and `step2_done`, and it contains `$SB_VER` and `$ARCH` |
| AC-6 | non-TTY: byte-diff vs a pre-change extraction of the same fragment (identical). TTY: message present, URL correct, exit 1 (see §5.3 / R-A) |
| AC-7 | `302 → 200` route; file installed into the temp tree |
| AC-8 | run each fragment twice with `LANG_CHOICE=en` and `LANG_CHOICE=zh`; assert no `unbound variable`, and that the notice line is non-empty and differs between the two runs |
| AC-12 | loop fragment, both modes: exactly 5 `↓` lines, in loop order, 0× `0x0D` in the non-TTY capture |
| AC-13 | loop fragment, 404 on the third artifact: `download_failed` names that URL, exit 1 |
| AC-14 | TTY mode, API route: stderr and stdout both meter-free; parsed `SB_VER` equals the pre-change value |
| AC-15 | put the stub `sing-box` on `PATH` **before** running the step-2 fragment: only the "already installed" line, and the server's request log is empty |
| AC-20 | `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` (read-only, outside every fragment) before and after the whole session — must be identical. `.harness/insight-index.md:22`: `is-active` is not a valid witness here |

---

## 11. Findings against the requirement (I cannot edit it)

**R-A — AC-6's "byte-identical" needs a mode.** In TTY mode the pre-change run has no meter and the
post-change run does, so a byte-identical diff is unachievable *by design*. Read as: non-TTY capture
byte-identical; TTY capture asserts message + URL + exit 1. Non-blocking.

**R-B — AC-9 vs AC-19.** AC-9 asks for an extractor script; AC-19 restricts the shipping diff to two
files. Resolved by D-A8 (QA-time script, committed by T-07). Non-blocking.

**R-C — AC-10/AC-11's stated method conflicts with AC-20.** "Diff against pre-change captures" of the
install log and the closing banner implies a real install; AC-20 forbids touching the host. Resolved
by S-7's diff-shape assertions (§10). Non-blocking, but the gate reviewer should confirm the
substitution.

**R-D — a factual error inside D-5's rationale, plus a latent product bug it points at.** D-5's third
reason says the version query's "failure is already diagnosed by the semver validation immediately
after it". Under `set -euo pipefail` (`install.sh:9`) that is false for the common failure modes.
`SB_VER=$(curl … | grep … | head -1 | sed …)` (`install.sh:352-354`): on HTTP 403 (unauthenticated
API rate limit — routine from shared/CGNAT addresses), 404 or a transport error, `-f` makes curl exit
22 and `grep` exit 1; `pipefail` propagates non-zero; the assignment therefore fails and `set -e`
aborts the installer **at line 352**, so `t download_failed "GitHub API (sing-box version)"` and
`t check_network` at `:357-358` never run, `install_report` never runs, and the user sees a bare
abort with no bilingual message. Lines `:356-360` are reachable only when the pipeline exits 0 but
yields a non-semver string. Verification: C-6 in §8 (no network needed).

Handling: **not fixed here.** Fixing it changes step-2 failure behaviour, which AC-6/AC-14 pin as
unchanged, and `.harness/rules/85-design-discipline.md` forbids widening the task. The developer must
leave `:352-360` alone except for the `CURL_OPTS_QUIET` substitution. Recommended follow-up row:
*"`install.sh` version query aborts silently on an API error"* — it is a one-line fix (`|| true` on
the substitution, or an explicit `if ! SB_VER=$(...)`) but it needs its own ACs. PM should file it;
this design will not smuggle it in.

---

## 12. Risks

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **`--progress-bar` absent or renamed on curl 7.29** → unknown option → exit 2 → every RHEL/CentOS 7 install fails at step 2. Highest consequence in the diff, and invisible on any modern dev box. | C-5 in §8 is a **gating** check: verify against the curl 7.29.0 source or a RHEL 7 man page *before* writing the edit, and paste the evidence into `04_DEVELOPMENT.md`. |
| R-2 | **The `set -u` bilingual abort** (`.harness/insight-index.md:10`, E-14) — reachable only by answering `2`, so an English-only run cannot see it. | One key only (§3.2); inserted at the same relative position in both tables; S-6 set+placeholder parity; AC-8 runs both languages. |
| R-3 | **Quoting regression at the two rewritten quiet sites** (D-A2) — `"${arr[@]}"` mis-typed as `${arr[@]}` or `"${arr[*]}"` changes argv silently and only shows up on a URL with a space or on an empty expansion. | Run the extracted fragments under `set -x` pre- and post-change and diff the `+ curl …` trace lines; they must be argv-identical off a TTY. Cheap, decisive. |
| R-4 | **A future edit wraps the script in a redirection**, making the once-computed `CURL_OPTS_PROGRESS` stale. | The comment says "decided once, for every curl in this script"; the S-3 invariant makes a second decision point detectable by grep. |
| R-5 | **Harness vacuity** — an anchored `sed` extract that silently yields nothing, or a fixture too small to force a redraw (the T-02 precedent, `.harness/insight-index.md:14`). | §10 Layer H steps 1-2: assert extracts non-empty and contain the expected `curl` line; ≥ 8 MiB body, ≥ 2 s wall-clock, throttled in 64 KiB chunks. |
| R-6 | **A harness reaching the real host** — the `bin/sc` auto-elevate incident (`.harness/insight-index.md:13`). | Nothing imports `bin/sc`; no fragment reaches step 3+; `SB_BIN` repointed into the temp tree; `install` and `sing-box` stubbed on a `PATH` prefix; AC-20's `MainPID`/`ActiveEnterTimestamp` witness taken around the whole session. |
| R-7 | **BC-5, no `Content-Length`** — with no total, curl's bar has nothing to fill (older curl shows a 0 % bar, newer shows a spinner). | Accepted per BC-5/BC-16/D-9: whatever the tool renders is the contract. GitHub release assets always send `Content-Length`, so this is theoretical; the fault route in the stub server covers it for the "transfer still succeeds" half. |

---

## 13. Migration / rollout

Nothing to migrate. The change is confined to one shell script's runtime behaviour; there is no
persisted state, no version marker, and no compatibility window.

- **Backwards compatibility.** A re-run of `install.sh` is the documented upgrade path
  (`.harness/rules/50-singbox-cli.md`): step 2 short-circuits when `sing-box` is on `PATH`
  (`install.sh:346-349`), so an existing install sees *no* new output at all (B-11/BC-18). Users on
  an older `install.sh` are unaffected; the `curl | bash` one-liner is unchanged.
- **Feature flag: none, deliberately.** The gate is `[ -t 2 ]`, a property of the environment. A
  knob would be a second way to spell the same decision (B-9 forbids a configuration knob).
- **Rollback.** `git revert` of a two-file diff. No cleanup, no data touched.
- **CHANGELOG.** One Chinese entry: the tarball download now shows curl's progress bar on a terminal
  and stays silent when output is captured; each remote artifact and the resolved sing-box
  version/architecture are now named before they are fetched.

---

## 14. Out-of-scope clarifications (design boundaries)

This design does **not** cover, and the developer must not add: `bin/sc` (T-02/T-10) or any shared
code with it; `systemd/` (T-09); step 6's rule-set progress at install time
(`.harness/rejected-decisions.md#ruleset-progress-visible-during-install`); step 1's package-manager
output (`…#installer-package-manager-download-output`); any timeout or retry option; tarball checksum
or signature verification (D-10); the unguarded `tar -xz` at `install.sh:368` (E-13); the silent
abort at `install.sh:352` (§11 R-D — file the row, do not fix here); `sc doctor` (T-05) or
`sc config --show` (T-06); any change to what is downloaded, from where, or in what order; and any
committed test harness (T-07).

---

## 15. Verdict

**READY.**

Four edit sites in one file, ~14 net lines, one new translation key, one new `if`. Every claim about
curl carries a runnable verification in §8, two of which (C-1, C-5) gate the implementation. One
requirement rationale defect (§11 R-D) and three AC interpretations (R-A/R-B/R-C) are recorded for
the gate reviewer; none blocks, and none required editing the requirement.

Riskiest thing handed to the developer: **verify `--progress-bar` on the curl 7.29 floor before
writing the edit** (R-1/C-5). It is the one failure mode that is invisible on a modern machine and
breaks the installer outright on the oldest supported distro.
