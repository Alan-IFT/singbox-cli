# 01 — Requirement Analysis: `install-binary-download-progress`

- **Task ID**: T-08 (pool row T-08, `docs/batches/default/BATCH_PLAN.md:19`)
- **Mode**: `full`
- **Decision mode**: deferred-human (`defer, do not ask`). Standing decision authority granted by the
  owner. Every ambiguity below is **resolved and recorded in §9**, not raised as a blocking question.
  Downstream stages may challenge any §9 decision on evidence.
- **Date**: 2026-08-01

---

## 1. Goal

During `install.sh`, the sing-box release tarball — the only transfer in the installer measured in
megabytes — downloads with no visible progress, so the user cannot tell whether the installer is
working or hung; this task makes that transfer's progress visible on a terminal and keeps installer
output free of terminal control characters when it is not on a terminal.

Owner's words: 「现在安装过程中，看不到每个下载部分的进度条，导致不知道什么时候能完成；这个问题也需要优化」.
The rule-set half of that same request shipped in `bin/sc` under T-02. This row is the `install.sh` half.

---

## 2. Evidence (current behaviour — backward-looking citations)

| # | Fact | Where |
|---|---|---|
| E-1 | Step 2 fetches the tarball with `curl -fsSL "$SB_URL" -o "$SB_TMPDIR/sing-box.tar.gz"`. The `-s` is what suppresses curl's own meter; `-f` fails on HTTP ≥ 400, `-L` follows the GitHub → `objects.githubusercontent.com` redirect, `-S` re-enables error text under `-s`. | `install.sh:362` |
| E-2 | The version query runs inside a **plain global assignment from a command substitution**: `SB_VER=$(curl -fsSL … \| grep '"tag_name"' \| head -1 \| sed …)`. An assignment with no command name completes with the status of its command substitution, and under `pipefail` that is non-zero if any pipeline element is non-zero — so under `set -e` the assignment itself is an abort point. The semver validation that follows is reached **only** when the whole pipeline exits 0. | `install.sh:352-354`, `:356-360`, `:9` |
| E-3 | The `curl \| bash` path fetches five artifacts in a loop (`bin/sc`, `uninstall.sh`, three unit files); any failure prints `download_failed <url>` + `check_network` and exits 1. | `install.sh:317-329` |
| E-4 | `t()` declares `local fmt` with **no default**; the zh table and the en table are two independent `case` blocks. | `install.sh:121-218` (zh `:126-167`, en `:169-210`) |
| E-5 | The script runs under `set -euo pipefail`. | `install.sh:9` |
| E-6 | T-01's outcome model: `PHASE_RULESETS` / `PHASE_CONFIG` / `PHASE_SERVICE`, the `LOG_SINK` probe, `install_report()`, and `install_report \|\| exit 1`. Step 2 runs upstream of all of it and records no phase. | `install.sh:27-29`, `:450-452`, `:223-268`, `:496-497` |
| E-7 | Step 2 short-circuits entirely when `command -v sing-box` succeeds — the download path is reached only on a host without sing-box. | `install.sh:346-349` |
| E-8 | An `EXIT` trap removes `CLEANUP_DIRS`, including `$SB_TMPDIR`, with a bash-4.2-safe empty-array guard. | `install.sh:300-305`, `:350-351` |
| E-9 | T-02's visual language in `bin/sc`: `sys.stdout.isatty()` decides; on a TTY a single line is redrawn with `\r` + `\033[K` showing `{done}/{total} bytes ({pct}%)`; off a TTY exactly one completion line per item and no `\r`. | `bin/sc:1176`, `:791-811`, `:1183-1206` |
| E-10 | Step 6 runs `/usr/local/bin/sc update-rules >>"$LOG_SINK" 2>&1`, so T-02's per-rule-set progress is **not visible during an install** — it lands in `/var/log/sing-box/install.log` or `/dev/null`. | `install.sh:456` |
| E-11 | Sizes of the five loop artifacts: `bin/sc` 1536 lines (~60 KB), `uninstall.sh` 153 lines, unit files 16 / 10 / 7 lines. All are three to four orders of magnitude smaller than the tarball. | `bin/sc`, `uninstall.sh`, `systemd/*` |
| E-12 | Step 1's package installs are deliberately quiet (`-qq`, `-q`, `--noconfirm`, `>/dev/null`) and report through `\|\| return 1`. | `install.sh:82-108`, `:343` |
| E-13 | `tar -xz … -f "$SB_TMPDIR/sing-box.tar.gz"` is unguarded, so a corrupt archive aborts the run through `set -e` with no bilingual message. Pre-existing. | `install.sh:368` |
| E-14 | Insight: a key present in only one language branch aborts the whole installer under `set -u`, and the zh branch is reachable only by answering `2` at the prompt. | `.harness/insight-index.md:10` |
| E-15 | **Consequence of E-2 (verified for this correction; it falsifies D-5's original third reason).** On HTTP 403 — GitHub's unauthenticated rate limit, routine from shared/CGNAT/CI addresses — or 404, `-f` makes curl exit 22 with empty stdout; on a transport/DNS failure curl exits 6. `grep '"tag_name"'` then finds nothing and exits 1, `pipefail` yields 1 for the pipeline, the assignment inherits it, and `set -e` terminates the installer **at the assignment**. Therefore `t download_failed "GitHub API (sing-box version)"` and `t check_network` never print, and `install_report` at `:496` is never reached. The `EXIT` trap still removes `$SB_TMPDIR`. The only thing the user sees is curl's own English one-liner, which `-S` keeps on stderr. Verified by reading `:9`, `:352-354`, `:305`, `:494-497` plus documented assignment-status and `pipefail` semantics; the runnable confirmation is `02_SOLUTION_DESIGN.md` §8 C-6. | `install.sh:9`, `:352-360`, `:305`, `:494-497` |

---

## 3. In-scope behaviours

Each statement is binding and testable.

**B-1 — The tarball transfer shows progress on a terminal.** When the installer's **standard error**
is attached to a terminal, the step-2 tarball transfer displays a continuously updating, single-line
progress indicator produced by the download tool itself, updating in place until the transfer ends.

**B-2 — Standard error is the gate.** The predicate that decides whether the progress indicator is
emitted is the terminal-ness of **standard error** (`[ -t 2 ]`), because the download tool writes its
meter to standard error. Standard output's terminal-ness does not decide it. (Decision D-1.)

**B-3 — Off a terminal the transfer is silent.** When standard error is not a terminal, the step-2
tarball transfer emits no progress indicator, no carriage return (`0x0D`), and no intermediate
transfer state on either stream. This is a correctness requirement: the documented one-liner is
`sudo bash -c "$(curl -fsSL …)"` and runs are captured into log files and CI output.

**B-4 — One quiet line names the artifact, in both modes.** Immediately after the version string
passes validation and before the tarball transfer starts, step 2 prints exactly one additional line
to standard output naming the resolved sing-box version and the target architecture. The line is
identical in TTY and non-TTY mode, is a complete line terminated by a newline, and contains no
carriage return. It is the non-TTY "quiet notice" and the terminal-mode label for the indicator.

**B-5 — Failure handling is unchanged.** For the tarball transfer: an HTTP status ≥ 400, a transport
failure, and a DNS failure each still make the invocation exit non-zero; redirects are still
followed; the existing `download_failed "$SB_URL"` → `check_network` → `exit 1` sequence still runs
with the same URL argument; and the invocation stays inside an `if !` condition so `set -e` does not
abort before the bilingual message prints.

**B-6 — Each remote artifact is individually visible.** In the `curl | bash` path, each of the five
artifacts is announced by its repository-relative path on its own complete line, printed **before**
that artifact's transfer starts, in both TTY and non-TTY mode, with no in-place redraw and no
byte-level meter. (Decision D-4.)

**B-7 — The version query stays meter-free.** The GitHub API version query emits no progress
indicator in either mode and its captured output is unchanged. (Justification and decision: D-5.)

**B-8 — Bilingual parity.** Every message key introduced by this task is defined in **both** the zh
and the en table of `t()`. A key defined in one table only is a defect that aborts the installer
under `set -u` (E-4, E-14).

**B-9 — No new tool, no new dependency, no new file.** The progress display uses only options of the
already-required `curl`, and only options present in curl 7.29 (the oldest curl on a supported
distro). No `wget`, `pv`, `dd`, no helper script, no new file in the repository, no configuration
knob, and no hand-rolled byte/percentage arithmetic in Bash.

**B-10 — T-01's outcome model is untouched.** The phase variables, the log-sink probe, the closing
report and the derived exit status behave exactly as today. Step 2 writes nothing to the install log
and records no phase.

**B-11 — Idempotent re-run unchanged.** When sing-box is already installed, step 2 prints only its
"already installed" line: no quiet notice, no progress indicator, no download.

**B-12 — Environment-independent.** The behaviour above is identical on all six supported package
managers and both init systems, and on both supported architectures; nothing in this task branches
on either.

---

## 4. Out of scope

1. **`bin/sc`** — owned by T-02 / T-10. The visual language is matched; **no code is shared** (Bash/curl
   vs. Python/urllib), as T-02's own requirement already stated.
2. **`systemd/`** — T-09.
3. **Step 6's rule-set progress at install time.** T-02's per-rule-set progress exists but is
   invisible during an install because step 6 is redirected to `$LOG_SINK` (E-10). Deliberately
   **deferred**, not dropped — see D-6; re-homed as a follow-up row and recorded in
   `.harness/rejected-decisions.md`.
4. **Package-manager download output in step 1** (E-12) — see D-7.
5. **Timeouts and retries.** No `--max-time`, `--connect-timeout`, `--retry` or equivalent is added,
   changed or removed anywhere in the installer.
6. **`sc doctor`** (T-05) and **`sc config --show`** (T-06).
7. **Checksum / signature verification of the downloaded tarball.** Not requested here; the installer
   verifies nothing today and still verifies nothing after this task.
8. **Diagnosing a corrupt tarball** (E-13). The unguarded `tar -xz` keeps its current behaviour.
9. **`uninstall.sh`**, `README*.md` structure, and `verify_all` B.2/B.3 wiring (T-07 owns the
   committed harness).
10. **Any change to what is downloaded, from where, or in what order.**
11. **The version query's abort on an API or transport error (E-15)** — a live defect surfaced while
    correcting D-5, deliberately **not** absorbed into this task.
    - *What is wrong*: for every HTTP 403/404 and every transport failure of the GitHub API version
      query, the installer terminates at the assignment with no bilingual diagnosis and no statement
      of outcome. GitHub's unauthenticated rate limit makes 403 a routine result from shared, CGNAT
      and CI addresses, so this is a common path rather than a corner case.
    - *T-01 blast radius*: T-01 established that the installer states its outcome through
      `install_report()` and derives its exit status from the same derivation (`install.sh:494-497`).
      This abort reaches neither. Step 2's *designed* failure path also exits before
      `install_report()`, but it substitutes an explicit bilingual statement (`download_failed` +
      `check_network`); the abort substitutes nothing, so the installer terminates having stated no
      outcome of its own — the property T-01 exists to guarantee. The exit status is 1 in both cases,
      so a caller cannot distinguish them; only the absent message reveals which one happened.
    - *Why not fixed here*: fixing it changes step-2 failure behaviour, which AC-6 and AC-14 pin as
      unchanged, and `.harness/rules/85-design-discipline.md`'s counter-rule forbids widening a task
      past the request it was given. This row makes downloads visible; it does not redesign failure
      reporting. The developer leaves `:352-360` alone apart from the flag substitution.
    - *Enough to open a row from*: the behaviour wanted is that an API or transport failure of the
      version query produces the same class of outcome as a tarball failure — a bilingual statement
      naming what failed and what to check, plus a derived exit status — instead of a bare abort.
      Boundaries for that row to settle: whether the fix keeps the direct `exit 1` at step 2 or routes
      through `install_report()`; whether every other bare `VAR=$(pipeline)` under `set -e` in this
      script carries the same hole; and whether the `curl | bash` artifact path has an equivalent one.
      Recorded in `.harness/rejected-decisions.md#installer-version-query-silent-abort`.

---

## 5. Boundary conditions

| # | Condition | Required behaviour |
|---|---|---|
| BC-1 | stderr is a terminal, stdout is a pipe (`… \| tee install.log`) | Progress indicator shown on the terminal; the log receives the quiet notice and no `0x0D`. |
| BC-2 | stdout and stderr both redirected (`… > install.log 2>&1`) | No indicator; exactly the quiet notice; the file contains no `0x0D`. |
| BC-3 | stdout is a terminal, stderr redirected | No indicator (the redirected stream must stay clean); quiet notice printed. |
| BC-4 | No controlling terminal at all (cron, systemd unit, `nohup`) | Non-TTY path. The pre-existing behaviour of the language prompt's `read -r` failing into its default is unchanged. |
| BC-5 | Response declares no content length / chunked encoding | Indicator renders without a total; the transfer still succeeds and installs. |
| BC-6 | HTTP 404 for the computed tarball URL (version resolved, no asset for this architecture) | Non-zero exit → `download_failed "$SB_URL"` → `check_network` → exit 1, unchanged. |
| BC-7 | HTTP 5xx / connection reset mid-transfer | Same failure path as BC-6; the partially written file is removed by the existing `EXIT` trap (E-8). |
| BC-8 | Redirect chain (GitHub → object store) | `-L` retained; the indicator restarting at a redirect hop is acceptable and not a defect. |
| BC-9 | Version string empty or non-semver | The existing validation fails **before** the quiet notice prints, so no line can name an empty version. |
| BC-10 | curl older than 7.67 (CentOS/RHEL 7 ships 7.29) | Only options available in 7.29 are used. `--no-progress-meter`, `--fail-with-body`, `--retry-all-errors` are forbidden. |
| BC-11 | A new message key added to only one language table | Forbidden — this aborts the installer under `set -u` (E-14). Both tables carry every new key even when the rendered text is identical. |
| BC-12 | Zero-byte or truncated tarball that still returns HTTP 200 | Unchanged behaviour (E-13); this task neither improves nor worsens it. |
| BC-13 | User interrupts (Ctrl-C) mid-transfer | `EXIT` trap removes `$SB_TMPDIR` as today; no new temp path and no new cleanup obligation is introduced. |
| BC-14 | Two installers run concurrently on one host | Unchanged: each has its own `mktemp -d`. Interleaved terminal output is pre-existing and not addressed. |
| BC-15 | The artifact loop stalls on one file | The name line for that artifact is already on screen, so the stalled artifact is identifiable without a meter. |
| BC-16 | Very narrow terminal, unset `TERM`, or a terminal that does not honour `\r` | No width or capability requirement is imposed; the tool's own rendering is accepted as-is. |
| BC-17 | Extremely fast transfer (< 1 s, warm cache) | A single final indicator state is acceptable; no minimum number of redraws is required of the product (only of the test fixture — AC-3). |
| BC-18 | sing-box already installed (E-7) | Download path unreachable; no new output at all. |

---

## 6. Acceptance criteria

| # | Criterion | How verified |
|---|---|---|
| AC-1 | `bash -n install.sh` exits 0. | `verify_all` B.1 |
| AC-2 | `verify_all` reports 0 FAIL and a PASS count no lower than the pre-change baseline on the same tree. | Two runs, baseline first |
| AC-3 | With a local stub server serving a throttled multi-megabyte body and stderr attached to a pseudo-terminal, the captured stderr of step 2 contains at least two distinct intermediate progress states (increasing transferred amount) before the transfer ends. | PTY-backed harness against a stub HTTP server |
| AC-4 | Same scenario with stderr redirected to a file: the file contains **zero** `0x0D` bytes, contains no progress states, and the tarball still installs successfully. | Byte scan of the captured file |
| AC-5 | In the non-TTY run, step 2 emits exactly one line beyond the existing step headline and the existing "Installed: …" line, and that line names the resolved version and the architecture. | Line-count + content assertion on captured stdout |
| AC-6 | Stub returns HTTP 500 for the tarball URL: output contains the bilingual `download_failed` line naming `$SB_URL`, then `check_network`, and the process exits 1. The **byte-identity** clause is asserted on the **non-TTY** capture only; the TTY capture asserts message present, same URL, exit 1. (D-11.) | Non-TTY: byte-diff against a pre-change capture. TTY: content assertion |
| AC-7 | Stub answers 302 → 200: the download succeeds and the binary is installed. | Stub harness |
| AC-8 | A full run answering `1` at the language prompt and a full run answering `2` both complete step 2 with no `unbound variable` error, and every new key renders non-empty prose in the answering language. | Two harness runs; assertion on captured output |
| AC-9 | Static parity check over the whole `t()` function: the set of keys in the zh `case` equals the set in the en `case`. | Extractor script written and run **at QA time from the QA temp directory**, pasted into `06_TEST_REPORT.md`, not committed by this task (D-12); no root, no network |
| AC-10 | T-01 non-regression: the phase model, the closing banner and its message set, and the derived exit status are unperturbed by this diff, on both the success and the failure branch. | Diff-shape assertions on the shipping diff (D-13). **No live install** — AC-20 governs |
| AC-11 | Step 2 contributes nothing to `/var/log/sing-box/install.log`: its content for a given run is what it would have been before this change. | Diff-shape assertions on the shipping diff (D-13). **No live install** — AC-20 governs |
| AC-12 | In the `curl \| bash` path, exactly five artifact name lines are printed, one per artifact, in loop order, in both TTY and non-TTY mode, with zero `0x0D` bytes in the non-TTY capture. | Stub `RAW_BASE` harness |
| AC-13 | Artifact-loop failure path unchanged: a 404 for the third artifact prints `download_failed` naming that artifact's URL, then `check_network`, and exits 1. | Stub harness, diff against pre-change |
| AC-14 | The version query emits no progress indicator on either stream in TTY mode, and the parsed version is unchanged from the pre-change run against the same stub response. | Stub harness, both modes |
| AC-15 | With sing-box already on `PATH`, step 2 prints only the "already installed" line: no quiet notice, no indicator, and no HTTP request is made to the release host. | Stub harness with request log |
| AC-16 | The diff introduces no new external command: no `wget`, `pv`, `dd`, `stdbuf`, `awk`-based meter, or new file. | Diff inspection |
| AC-17 | The diff uses no curl option absent from curl 7.29; specifically `--no-progress-meter`, `--fail-with-body` and `--retry-all-errors` appear nowhere in `install.sh`. | Diff inspection + option-floor grep |
| AC-18 | No timeout or retry option is added, removed or changed anywhere in `install.sh`. | Diff inspection |
| AC-19 | The **shipping** diff — the product code and user-facing documentation this task commits — touches `install.sh` and `CHANGELOG.md` only. Pipeline artifacts (`docs/features/**`, `CONTEXT.md`, `.harness/**`) and QA-time scratch files are not part of the shipping diff. (D-12.) | `git diff --stat`, evaluated over product paths |
| AC-20 | Every verification above ran without installing to the real `/usr/local/bin/sing-box`, without invoking the installed `sc`, and without starting, stopping or restarting the host's sing-box service. | Harness design review + `MainPID` / `ActiveEnterTimestamp` unchanged before/after |

---

## 7. Non-functional requirements

- **No extra network work.** The progress display costs zero additional requests: no `HEAD` probe for
  a content length, no second connection. Transfer time is unchanged within measurement noise.
- **Compatibility floor.** bash 4.2 (CentOS/RHEL 7), curl 7.29, POSIX `test -t`. All six supported
  package managers, both init systems, both architectures.
- **Log hygiene is a correctness property, not cosmetics.** Any stream that is not a terminal must be
  free of `0x0D` and of partial-state redraws, because installer output is routinely captured to
  `/var/log/sing-box/install.log`, to CI logs, and to issue reports.
- **Security.** No change to what is fetched, from where, or with what verification. No new value is
  written to a log or printed that is not printed today, apart from the version/architecture notice,
  which contains no credential.
- **Safety during verification.** Insight `.harness/insight-index.md:13`: `bin/sc`'s import-time
  auto-elevate re-execs the *installed* CLI. This task needs `bin/sc` for nothing; harnesses must
  neither import it nor let `install.sh` reach steps 3-7 against the real filesystem.

---

## 8. Related tasks

- **T-02 `config-degrade-missing-rulesets`** — `docs/features/_archived/config-degrade-missing-rulesets/01_REQUIREMENT_ANALYSIS.md`
  §3.D (B-18/B-19/B-20) is the ruleset half of this same owner request and defines the visual
  language and the non-TTY contract this task matches. Its §4 item 6 hands this row exactly this
  scope with "only the visual language is shared; no code is shared". Its `04_DEVELOPMENT.md`
  §"notes" warns T-08 that a progress fixture smaller than the transfer buffer asserts nothing —
  reflected here in AC-3.
- **T-01 `install-enable-start-split`** — `docs/features/_archived/install-enable-start-split/01_REQUIREMENT_ANALYSIS.md`
  owns the phase model, the `LOG_SINK` probe and `install_report()` that B-10 / AC-10 / AC-11 protect.
  Its harness technique (stubbed `PATH`, captured output diffs) is the model for this task's
  verification.
- **T-10 `ruleset-update-no-needless-restart`** and **T-09 `fix-rules-update-execstart`** — adjacent
  files only (`bin/sc`, `systemd/`); no overlap with this diff.
- **T-07 `restricted-network-regression-test`** — inherits the stub-server harness; the artifact-loop
  name lines (B-6) make its "which fetch hung" assertions expressible.
- `docs/batches/default/BATCH_PLAN.md:19,41-44` — the row and the "progress must degrade off a TTY"
  constraint shared with T-02.

---

## 9. Recorded decisions (in lieu of open questions)

Under deferred-human mode these are resolved, not asked. Each names the alternatives and what would
justify overturning it.

**D-1 — Gate on standard error, not standard output.**
Candidates: (a) `[ -t 1 ]`; (b) `[ -t 2 ]`; (c) both must be terminals.
**Chosen: (b).** curl writes its meter to standard error, so standard error's terminal-ness is the
only predicate that decides whether control characters land in a captured stream. (a) would silence
the meter in the very common `… | tee install.log` case even though the terminal is right there, and
would *fail to* silence it when only stderr is redirected — the exact regression this rule exists to
prevent. (c) is (b) plus a needless extra silence case.

**Confirmed and strengthened at design stage** (`02_SOLUTION_DESIGN.md` §8) — the record now reflects
two legs, not one, and the second is the load-bearing one:
- *Leg 1 — the meter is a stderr artefact.* curl's `--stderr` option exists precisely to redirect
  "the progress meter and error messages", and `-o -` puts the body on stdout while a meter still
  renders, which is only possible if the two are different streams.
- *Leg 2 — curl does not self-gate on `isatty(stderr)`.* Its only isatty-like suppression applies
  when the **response body** would be written to the terminal, which never occurs here because
  `-o <file>` is always used. Leg 2 is what makes `[ -t 2 ]` a **correctness requirement rather than
  cosmetics**: without the gate, `sudo bash install.sh > install.log 2>&1` fills the log with `0x0D`
  — the exact regression B-3 and AC-4 exist to prevent. With leg 2 false, no gate would be needed at
  all; with leg 1 false, the gate would have to be `[ -t 1 ]`.

Both legs are settled by one runnable check (`02_SOLUTION_DESIGN.md` §8 C-1), which gates the
implementation. **This supersedes `docs/batches/default/BATCH_PLAN.md:46-47`**, which proposed
`[ -t 1 ]` for the installer: that line was written before the stream question was examined, and
`[ -t 1 ]` is wrong in both directions — it silences the bar under `… | tee install.log` where a
terminal is present, and fails to silence it under `2>file` where one is not. Overturn only on
evidence that C-1 fails.

**D-2 — Use the tool's single-line bar, not its default multi-column table.**
Candidates: (a) drop `-s` and take curl's default statistics table; (b) the single-line bar (`-#`).
**Chosen: (b).** The default table is a multi-column, multi-line display that looks nothing like
`bin/sc`'s single redrawn line (E-9); the bar is one line redrawn in place, which is the visual
language the two installers are supposed to share. Overturn if the bar proves unavailable or broken
on a supported curl.

**D-3 — Do not hand-roll a meter in Bash.** Candidates: (a) compute bytes/percent in Bash from a
background `stat` loop or `curl -w`; (b) use the downloader's own meter.
**Chosen: (b),** per `.harness/rules/85-design-discipline.md`'s counter-rule: a hand-rolled meter is
new machinery for a requirement the existing tool already satisfies, and it would add a background
process and its cleanup to a script running under `set -euo pipefail`.

**D-4 — The five loop artifacts get a name line, not a byte meter.**
Candidates: (a) a full meter per artifact; (b) one name line per artifact, no meter; (c) leave silent.
**Chosen: (b).** (c) is rejected outright — the owner said 每个下载部分, and this loop is the first
thing a remote install does, so leaving it silent is the same defect in miniature. (a) is rejected
because these artifacts are three to four orders of magnitude smaller than the tarball (E-11): a byte
meter for a 7-line unit file measures connection setup, and five stacked bars make the installer's
first screen unreadable. The uncertainty these five actually create is *which one is stalled against
`raw.githubusercontent.com`*, and a name line printed before the fetch answers exactly that. One
complete line per item is also T-02's non-TTY contract. Overturn if the architect finds the loop can
carry a meter at no readability cost.

**D-5 — The GitHub API version query stays meter-free — the justification the owner asked for.**
Candidates: (a) show a meter; (b) stay silent.
**Chosen: (b) — conclusion unchanged. One of the three reasons originally given was factually wrong
and is retracted here** (found by the architect, `02_SOLUTION_DESIGN.md` §11 R-D; independently
verified against the source for this correction, E-15).

Reasons that hold: (i) the body is a small JSON document whose wall-clock cost is connection setup
rather than transfer, so a meter would render one instantaneous state and display nothing actionable;
(ii) it is consumed inside a command substitution (E-2) rather than written to a file, so there is no
transfer to a destination the user cares about; (iii) the residual concern — "the installer sits
silent while the API query hangs" — is answered by B-4 rather than by a meter: the
version/architecture notice line is a boundary marker, so a stall before it is the API query and a
stall after it is the tarball.

**Retracted:** the claim that the query's "failure is already diagnosed by the semver validation
immediately after it, which prints a bilingual `download_failed`". That is false for every HTTP and
transport failure — the ones a diagnosis is actually for. Under `set -euo pipefail` the assignment at
`:352-354` is itself the abort point, so `:356-360` is unreachable on exactly those failures (E-2,
E-15); the validation catches only a pipeline that exits 0 and yields an empty or non-semver string,
i.e. a well-formed response with an oddly shaped tag.

**The conclusion survives on (i)-(iii).** None of them depends on the failure path, and a meter would
not have improved that path: it would render one instantaneous bar immediately before an unexplained
exit — noise adjacent to a failure, not a diagnosis. The false sentence did, however, conceal a live
product defect. That defect is real, is **not** this task's to fix, and is re-homed as §4 item 11 and
`.harness/rejected-decisions.md#installer-version-query-silent-abort`.

**D-6 — Step 6's rule-set progress stays invisible at install time (deferred, not declined forever).**
Candidates: (a) un-redirect `sc update-rules` so its per-rule-set progress reaches the terminal;
(b) tee it; (c) leave as-is and re-home.
**Chosen: (c).** (a) destroys T-01's design, in which the *cause* of a rule-set failure is captured
into `/var/log/sing-box/install.log` and only a summary is shown; (b) is forbidden by
`.harness/insight-index.md:12` — under `pipefail` a logging fault would flip a healthy phase. It is
also outside this task's stated boundary (`install.sh` only, not the rule-set download path). Real
and worth fixing later: T-02 built per-rule-set progress that no installing user has ever seen.
Re-homed as a follow-up row and recorded in `.harness/rejected-decisions.md`.

**D-7 — Package-manager transfers in step 1 stay quiet.**
Candidates: (a) drop `-qq` / `>/dev/null` so apt/dnf/pacman show their own progress; (b) keep quiet.
**Chosen: (b).** Those bytes are not our transfer: making them visible means removing quiet flags
from six different package managers with six different output volumes and six different error
surfaces, which changes `pkg_install`'s failure reporting (E-12) for a step whose payload is a few
already-cached packages. That is scope this requirement was not given, and it is separable — it can
be its own row if the owner asks.

**D-8 — The non-TTY degradation is one informative line, printed in both modes.**
Candidates: (a) no extra line (the existing step headline suffices); (b) one line naming version and
architecture, printed in both modes; (c) one line saying "progress hidden because output is not a
terminal", printed only off a TTY.
**Chosen: (b).** (a) contradicts the goal's "quiet single-line notice". (c) describes our display
rather than the system, which is noise in a log, and it creates a mode-specific string — two branches
and two translation keys where one suffices. (b) yields one string, one code path, a useful fact in
both modes (the exact version being installed, which the installer never states before the fact
today), and the boundary marker D-5 relies on.

**D-9 — Byte formatting, ETA and transfer rate are whatever the tool prints.** Candidates: (a) require
a specific format; (b) accept the tool's. **Chosen: (b)** — a formatting requirement would force
exactly the hand-rolled meter D-3 forbids. T-02 answered the sibling question the same way (raw bytes,
its §8 Q7).

**D-10 — Tarball checksum verification is not folded in.** Candidates: (a) add checksum/signature
verification while touching this invocation; (b) leave it. **Chosen: (b)** — real gap, unrelated
requirement, and `.harness/rules/85-design-discipline.md` forbids widening a task beyond the owner's
request. Noted in §4 item 7 so it is visible rather than lost.

**D-11 — AC-6's byte-identity is evaluated on the non-TTY capture (answers `02_SOLUTION_DESIGN.md`
§11 R-A).** Confirmed as the architect read it, and the non-TTY capture is the *only* surface on which
the assertion means anything. On a TTY the post-change run emits curl's bar and the pre-change run
cannot, so a byte-identical TTY diff is unachievable by construction — an assertion that can only fail
tests nothing. Off a TTY the two runs execute the **same** flag vector, so byte identity is both
achievable and strong: one comparison pins the failure text, the URL argument, the message order and
the exit status at once. AC-6's property — the tarball failure path is unchanged by this task (B-5) —
is fully carried by the non-TTY byte diff plus the TTY capture's message/URL/exit-1 assertion. One
boundary this does not cross: `t()` renders to **stdout** (`install.sh:212-217`) while curl's bar goes
to stderr, so a per-stream comparison keeps stdout byte-comparable in both modes even though the
combined TTY capture is not.

**D-12 — AC-9 and AC-19 do not conflict (answers §11 R-B).** AC-19 governs the *shipping* diff; AC-9
governs a *verification*, and a verification's tooling is not a shipped artifact. The key-parity
extractor is written at QA time under the QA temp directory, its source and output are pasted into
`06_TEST_REPORT.md`, and it is handed to T-07, which owns the committed harness — the architect's
`02_SOLUTION_DESIGN.md` §9 D-A8, endorsed here, and consistent with
`.harness/rejected-decisions.md#ruleset-unit-tests-in-t02`, whose third re-occurrence this is. The
same reading settles the sibling case raised in `02_SOLUTION_DESIGN.md` §2: stage documents,
`CONTEXT.md` and `.harness/rejected-decisions.md` are the pipeline's own record, not product, so
writing them does not breach AC-19. AC-19 keeps its teeth: no new file under the repository's product
paths, and no second production file edited.

**D-13 — AC-10/AC-11 are discharged by diff-shape assertions (answers §11 R-C).** Confirmed: the
architect's S-7 substitution is acceptable at requirement level, and **AC-20 is non-negotiable** —
`.harness/insight-index.md:13` records a run that re-exec'd the *installed* CLI against the owner's
live service, and "verify by installing" is precisely how that recurs. The "How verified" column of
AC-10/AC-11 named an illustrative method; the binding part is each criterion's property. A diff-shape
assertion is a **stronger** witness than one sampled install, because it establishes the property for
every execution path rather than for the one path that happened to run. It is sound here for a
specific structural reason: step 2 executes upstream of the log-sink probe, so the only way step 2
reaches the install log is a redirection this diff would have to introduce — and S-7 asserts the diff
introduces zero new `>` / `>>` / `2>&1` / `|` tokens, assigns no `PHASE_*`, and touches no line of the
phase, report or tail regions. Also satisfying these criteria: a dynamic run of the same steps inside
the extracted-fragment harness, with the log path and `SB_BIN` repointed into a temp tree. Never
satisfying them: a real install, or any run that reaches `systemctl`, `/etc`, `/usr/local` or `bin/sc`.

---

## 10. Verdict

**READY.**

No open questions remain: every ambiguity is resolved in §9 under the owner's standing decision
authority, and none of them approaches a safety red line. 20 acceptance criteria, 18 boundary
conditions, 12 in-scope behaviours, 13 recorded decisions.

Sharpest risks handed to the architect: the stream-choice argument in D-1 (correctness, not
cosmetics), the curl-7.29 option floor in BC-10, the bilingual `set -u` abort in BC-11/E-14, and
AC-20's requirement that verification never touch the host's real sing-box.

**Correction pass (2026-08-01), after `02_SOLUTION_DESIGN.md` §11.** Scope of the pass: rationale and
interpretation only — no in-scope behaviour, boundary condition or acceptance criterion was added,
removed or re-aimed, and the criteria count is unchanged.
- **R-D accepted.** D-5's third reason was factually wrong; it is retracted and replaced, the
  underlying fact is now evidence E-2/E-15, and **D-5's conclusion survives** on its other reasons.
- **The live defect it concealed is re-homed, not absorbed** — §4 item 11 plus
  `.harness/rejected-decisions.md#installer-version-query-silent-abort`. It is a T-01 blast-radius
  item and it is not fixed by this task.
- **R-A / R-B / R-C answered authoritatively** as D-11 / D-12 / D-13, with AC-6, AC-9, AC-10, AC-11
  and AC-19 reworded so §6 alone can no longer be read two ways.
- **D-1 confirmed and strengthened** on the architect's two-leg finding, superseding
  `docs/batches/default/BATCH_PLAN.md:46-47`'s `[ -t 1 ]`.
