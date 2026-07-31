# 01 — Requirement Analysis · T-11 `install-version-query-abort`

- Mode: **full** · Decision mode: **deferred-human** (`defer, do not ask`)
- Stage 1 (Requirement Analyst), 2026-08-01
- Upstream inputs (read-only): `docs/features/install-version-query-abort/PM_LOG.md`,
  `.harness/insight-index.md`, `docs/tasks.md`, `.harness/rejected-decisions.md`,
  `.harness/rules/50-singbox-cli.md`, `.harness/rules/85-design-discipline.md`,
  `docs/dev-map.md`, `CONTEXT.md`, `docs/spec/README.md` (index only — no feature SPEC exists
  for this row).

---

## 0. One thing stage 2 must do before designing (read this first)

This stage had **no shell-execution tool** — only file read / search / write. The brief required the
`set -e` assignment semantics to be established *empirically*. I could not execute anything, so §2.2
states the rule from the Bash Reference Manual's two governing sentences, derives a **falsifiable
prediction for each of seven cases**, and hands over a ready-to-run experiment. **AC-1 makes running
it a binding, blocking obligation on stage 2**, with an explicit stop rule if any prediction fails.
Nothing else in this document is unexecuted: every source claim below was read out of the working
tree at HEAD `22502f9`.

---

## 1. Goal

Make `install.sh`'s sing-box version query reach its own failure handling instead of terminating the
script at the assignment, so that every way the query can fail ends in a localized statement of what
failed and a derived non-zero exit status rather than in a run that states no outcome at all.

---

## 2. Evidence — verified against the source, not taken on trust

All anchors are **backward-looking evidence** at HEAD `22502f9`, per `.harness/rules/05-insight-index.md`.
Requirement prose in §3-§7 deliberately carries no path:line anchors.

### 2.1 The defect exists as described

`install.sh:9` is `set -euo pipefail`. `install.sh:373-375`:

```bash
SB_VER=$(curl "${CURL_OPTS_QUIET[@]}" "https://api.github.com/repos/${SB_REPO}/releases/latest" \
    | grep '"tag_name"' | head -1 \
    | sed 's/.*"v\([^"]*\)".*/\1/')
```

followed at `install.sh:376-381` by the validation and handler it was written to reach:

```bash
    # Validate that we got a semver-like string (e.g. "1.10.0")
    if [ -z "$SB_VER" ] || ! echo "$SB_VER" | grep -qE '^[0-9]+\.[0-9]+'; then
        t download_failed "GitHub API (sing-box version)"
        t check_network
        exit 1
    fi
```

`CURL_OPTS_QUIET` is `(-f -s -S -L)` (`install.sh:128`) — the `-f` is load-bearing here: it turns an
HTTP 403/404/5xx into a curl **failure** rather than a body on stdout.

Three distinct upstream conditions therefore make the pipeline non-zero, and under `pipefail` the
whole pipeline is non-zero, and under `set -e` a bare assignment from that pipeline terminates the
script **at line 373**:

| # | Condition | curl | grep | Pipeline | What the user sees today |
|---|---|---|---|---|---|
| a | DNS / connect / TLS failure | 6 / 7 / 35 | 1 | non-zero | one raw English curl line on stderr (kept by `-S`), then nothing |
| b | HTTP 403 (unauthenticated rate limit), 404, 5xx | 22 | 1 | non-zero | one raw English curl line, then nothing |
| c | HTTP 2xx whose body has no `tag_name` line (captive portal / proxy interstitial / empty body) | 0 | 1 | non-zero | **absolutely nothing** |

Condition (c) is the sharpest: curl succeeded, so `-S` prints nothing, `grep` exits 1 silently, and
the installer dies mute. Conditions (a) and (b) are not much better — a raw `curl: (22) …` line is
not a **stated outcome** (`CONTEXT.md`): not localized, does not name the installer's step, offers no
next action.

Only a **fourth** class actually reaches the handler at `:377`: a pipeline that exits 0 and yields an
empty or non-semver string. That is the narrowest of the four and the least likely.

`install.sh:377`'s `[ -z "$SB_VER" ]` is therefore, today, a test for a case that can barely occur,
guarding a handler that the common cases cannot reach.

### 2.2 The shell rule — stated, predicted, and handed to stage 2 to execute

Two sentences of the Bash Reference Manual govern this jointly:

1. **`set -e`** — "Exit immediately if a pipeline, which may consist of a single simple command, a
   list, or a compound command returns a non-zero status." The listed exemptions are: a command in
   the list following `while`/`until`; a command in the test following `if`/`elif`; any command in a
   `&&`/`||` list **except the last**; any command in a pipeline **but the last**; and a command whose
   status is inverted with `!`.
2. **Simple-command exit status** — "the exit status of a simple command that consists only of
   variable assignments and redirections is the exit status of the last command substitution
   performed."

`SB_VER=$(…)` at top level is a simple command consisting only of an assignment, in none of the
exempt contexts. Its status **is** the pipeline's status. Conclusion: **a bare `VAR=$(pipeline)` at
top level is NOT exempt — it aborts.**

The exemption that is easy to confuse this with is **`local VAR=$(…)`** (also `declare`, `export`,
`readonly`): those are *builtin commands with arguments*, so the simple command's status is the
builtin's (0), and `set -e` does not fire. `install.sh` does not use that form for `SB_VER`, so the
exemption does not apply. Getting this backwards in either direction invalidates the task, which is
why AC-1 exists.

**Experiment E-0 — stage 2 must run this verbatim in a temp directory and paste the transcript.**
It touches nothing outside the shell, needs no root, no network, and no fixture:

```bash
b() { bash -c "$1"; echo "  -> exit $?"; }

echo "E1 bare assignment, failing command"
b 'set -euo pipefail; V=$(false); echo "REACHED handler"'
#  predict: no REACHED, exit 1        (the defect's mechanism)

echo "E2 bare assignment, failing PIPELINE (grep finds nothing)"
b 'set -euo pipefail; V=$(printf "x\n" | grep zzz | head -1); echo "REACHED handler"'
#  predict: no REACHED, exit 1        (condition (c) above)

echo "E3 same, WITHOUT pipefail"
b 'set -eu; V=$(printf "x\n" | grep zzz | head -1); echo "REACHED handler"'
#  predict: REACHED, exit 0           (proves pipefail is load-bearing, not incidental)

echo "E4 assignment inside an if condition"
b 'set -euo pipefail; if ! V=$(false); then echo "REACHED handler"; fi; echo done'
#  predict: REACHED, done, exit 0     (an exempt context exists)

echo "E5 local masks the status - the real exemption"
b 'set -euo pipefail; f() { local V=$(false); echo "REACHED after local"; }; f'
#  predict: REACHED after local, exit 0

echo "E6 substitution as an ARGUMENT to a command"
b 'set -euo pipefail; printf "[%s]\n" "$(printf "x\n" | grep zzz | head -1)"; echo REACHED'
#  predict: [], REACHED, exit 0       (clears install.sh:368 and :392)

echo "E7 assignment whose list ends in || true"
b 'set -euo pipefail; V=$(false || true); echo "REACHED, V=[$V]"'
#  predict: REACHED, V=[], exit 0     (clears install.sh:39, :61, :62)
```

**Stop rule.** If E1 or E2 prints `REACHED`, the premise of this task is false: stage 2 must stop,
say so, and return to stage 1 rather than designing around a defect that does not exist. If E5, E6
or E7 contradicts its prediction, §2.3's sweep verdicts are wrong and must be re-derived before the
design fixes anything.

### 2.3 Sibling sweep — every command substitution in `install.sh`, with a verdict

The file contains **11** command substitutions in code (`install.sh:5` is a comment in the header
one-liner and is not code). This list is exhaustive.

| Line | Site | Status forced to 0? | Verdict |
|---|---|---|---|
| 39 | `PKG_MGR=$(type -P apt-get \|\| … \|\| true)` | **Yes** — list ends in `true` | **Not the defect.** Handler at `:40-48` is reachable; an empty `PKG_MGR` is exactly what it tests for. Clears via E7. |
| 51 | `case "$(uname -m)" in` | n/a | **Not the defect.** The substitution's status is not the `case`'s status; a failed `uname` yields an empty word which falls to `*)` at `:54-57` and exits with a bilingual message. |
| 61 | `IS_SYSTEMD=$(type -P systemctl \|\| true)` | **Yes** | **Not the defect.** Handler at `:63-67` reachable. |
| 62 | `IS_OPENRC=$(type -P rc-service \|\| true)` | **Yes** | **Not the defect.** Same handler. |
| 307 | `INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null \|\| echo "")}"` | **Yes** — inner list ends in `echo` | **Not the defect.** Handler at `:308-315` reachable. |
| 318 | `SCRIPT_DIR="$(cd … && pwd \|\| echo "")"` | **Yes** | **Not the defect.** Handler is the `-n "$SCRIPT_DIR"` test at `:327`. |
| 332 | `ARTIFACT_DIR="$(mktemp -d -t singbox-cli-install.XXXXXX)"` | **No** | **Same mechanism, different feature — report only (D-3).** A failing `mktemp` aborts here, but there is **no handler below it to resurrect** and `mktemp` writes its own diagnosis to stderr. Failure domain is the local temp filesystem, not the network. Re-homed as open row R-1. |
| 368 | `t step2_already "$(sing-box version \| head -1)"` | n/a | **Not an abort** (substitution status discarded — E6), but a **different latent defect**: a `sing-box` that exits non-zero yields `▶ [2/7] sing-box already installed: ` with an empty version, and the installer continues. Report only; re-homed as open row R-2. |
| 371 | `SB_TMPDIR="$(mktemp -d)"` | **No** | Same as `:332`. Report only (D-3), re-homed as R-1. |
| **373** | **`SB_VER=$(curl … \| grep … \| sed …)`** | **No** | **THE DEFECT. In scope.** Handler at `:377-381` is unreachable for conditions (a)(b)(c) of §2.1. |
| 392 | `t step2_done "$(sing-box version \| head -1)"` | n/a | Same as `:368`. Report only; R-2. |

Note the brief's pointer to `install.sh:347` does not land on a substitution at HEAD — the two
`sing-box version | head -1` sites are `:368` and `:392`. Both were examined; verdicts above.

**A wider class exists and is deliberately NOT claimed fixed.** `install.sh` also contains bare
non-assignment commands whose failure aborts the run with no stated outcome — the `python3` heredoc
at `:403-417`, `tar -xz` at `:390`, `install -m 755` at `:391`/`:398`/`:399`, `visudo -c` at `:463`,
`chmod` at `:462`. T-01's "the installer always states its outcome" guarantee is therefore **not**
globally true, and will still not be after this task. §6's acceptance criteria are scoped to the
version-query path precisely so this document does not overclaim. Re-homed as open row R-3.

### 2.4 The reporting route is a genuine fork — with one hard constraint

Step 2 runs **before** the phases `install_report()` reads become meaningful: `PHASE_RULESETS` /
`PHASE_CONFIG` / `PHASE_SERVICE` are still at their pessimistic defaults (`install.sh:27-29`), and
`/usr/local/bin/sc` is not installed until step 3 (`install.sh:398`).

Routing this failure through `install_report()` **as that function stands today** would print
statements that are false of what happened. Verified at `install.sh:260-286`: with `PHASE_CONFIG`
still `failed`, the function prints `fail_config` — "Config generation failed: sing-box did not pass
the config check" — which is untrue when the run never reached config generation; and it prints
`fail_rules` / `fail_reload`, instructing the user to run `sc update-rules` and `sc reload`, which on
a fresh install do not exist yet. This is not an argument against routing through `install_report()`;
it is a constraint on **any** route (see B-4). The architect owns the mechanism.

### 2.5 Bilingual state at HEAD

`t()` is `install.sh:139-238`. The zh table is `install.sh:145-185`, the en table `install.sh:189-229`
— **41 keys each, same keys, same order**, and the `%`-specifier counts agree on every key I checked
by hand (`download_failed` 1/1, `check_network` 0/0, `step2_already` 1/1, `fail_status` 1/1,
`step6_warn` 1/1, `step6_nolog` 1/1, `fail_nolog` 1/1). Parity holds today and is **not committed as
a check** — see D-2.

`local fmt` at `install.sh:141` has no default, so a key present in only one table makes `printf`
dereference an unset variable under `set -u` and abort the whole installer
(`.harness/insight-index.md:10`). The zh table is reachable only by answering `2` at the prompt
(`install.sh:290-305`), so an English-only run cannot detect a parity break.

---

## 3. In-scope behaviors

Numbered, binding, mechanism-free.

**B-1.** For every failure mode of the sing-box version query, `install.sh` prints a **stated
outcome** (`CONTEXT.md`) in the language the user selected at the language prompt, and terminates
with exit status **1**.

**B-2.** The failure modes B-1 covers are exactly these five, and each is individually satisfied:
1. curl transport failure (name resolution, connect, TLS);
2. HTTP response with a non-2xx status (403 unauthenticated rate limit, 404, 5xx);
3. HTTP 2xx whose body contains no release-tag field;
4. HTTP 2xx from which an **empty** version string is extracted;
5. HTTP 2xx from which a **non-semver-like** version string is extracted (no leading `<digits>.<digits>`).

**B-3.** No failure mode in B-2 terminates the script at the assignment: for each of the five, the
line that decides the outcome executes, and the statement required by B-1 is emitted.

**B-4.** The statement emitted under B-1 is **true of what happened**. It names the sing-box version
query against the GitHub API as the thing that failed, and it states a next action. It does **not**
assert that configuration generation ran, that the sing-box configuration check failed, that the
service failed to start, or that rule-sets are missing; and it does **not** instruct the user to run
a command that this run has not yet installed.

**B-5.** The success path is unchanged. Given a well-formed latest-release response, the extracted
version, the constructed tarball URL, the download, the extraction, the installation of the binary
and every line printed to stdout are identical to HEAD's.

**B-6.** Determining that the version query succeeded does not depend on whether an upstream element
of the extraction was terminated early by a downstream reader closing the pipe. A well-formed
response yields the version deterministically.

**B-7.** Every user-facing string on the changed path — whether reused or newly introduced — is
defined in **both** the zh and the en table of `install.sh`'s translation function, with the same set
and count of `printf` conversion specifiers in both.

**B-8.** A committed, automated check asserts key-set and per-key conversion-specifier parity between
the two language tables of `install.sh`'s translation function, and this check runs as a
non-`SKIP` step of `.harness/scripts/verify_all.sh`, failing the run when parity is broken. Its input
is `install.sh`; it does not scan the rest of the repository. (Scope decision D-2.)

**B-9.** A run that terminates on the version-query failure path leaves `/etc/sing-box/nodes.json`
and `/etc/sing-box/settings.json` exactly as it found them, and creates no file under
`/etc/sing-box/`. Re-running the installer after such a failure remains the documented, non-destructive
upgrade path.

**B-10.** On the remote `curl | bash` path, a run that terminates on the version-query failure path
still removes the temporary directories it created, and the caller observes exit status 1.

**B-11.** `install.sh` remains a single self-contained file with no new runtime dependency: it invokes
no external command it does not already invoke at HEAD.

**B-12.** `02_SOLUTION_DESIGN.md` carries the sibling sweep of §2.3 forward as a table with one row
per command substitution in `install.sh` and a verdict per row, so that a site is never dropped
silently. Sites re-homed rather than fixed appear in `docs/tasks.md`.

---

## 4. Out of scope

**O-1.** `bin/sc` (T-02 / T-10), `systemd/` (T-09), `uninstall.sh`. Not read for edit, not edited.

**O-2.** The curl flag policy at `install.sh:116-132` (T-08, commit `9184171`) — **consumed, never
modified**. No curl option is added, removed or changed anywhere in the file.

**O-3.** Retry, backoff, or any change to timeouts. A rate-limited API is not made less rate-limited
by retrying, and nobody asked for a retry policy.

**O-4.** Authenticating the GitHub API call (a token, `GITHUB_TOKEN`, `.netrc`). This is the obvious
"fix" for the 403 and it is declined here: it is a security-surface and credential-handling decision
in a script that runs as root and is served over `curl | bash`, and it is not this row's request.
Recorded as D-5.

**O-5.** `sc doctor` (T-05) and `sc config --show` (T-06).

**O-6.** Pinning a minimum sing-box version, changing which release is installed, or changing the
architecture mapping.

**O-7.** The wider "any bare command failing aborts without a statement" class (§2.3 last paragraph)
— the `python3` heredoc, `tar`, `install -m`, `visudo`, `chmod`. Reported as R-3, not fixed.

**O-8.** The unguarded `mktemp -d` assignments (R-1) and the empty-version display defect at the two
`sing-box version` sites (R-2). Reported, re-homed, not fixed.

**O-9.** Extending the key-parity check of B-8 to `bin/sc`'s translation table. `bin/sc` is out of
scope by O-1, and it has a different shape (no `en` table at all — `docs/dev-map.md:52`).

**O-10.** Any change to `install_report()`'s behavior for a run that reaches step 7. If the design
routes the step-2 failure through that function, the function's output for a completed run is
unchanged.

---

## 5. Boundary conditions

**BC-1 — Empty 200 body.** Zero-byte response with HTTP 200: no tag field, extraction yields nothing.
Must produce B-1's statement, not an abort.

**BC-2 — Rate limit (the routine case).** HTTP 403 with a JSON body. Under the existing `-f`, curl
fails and the body never reaches the extractor. Must produce B-1's statement.

**BC-3 — Interstitial 200.** HTTP 200 returning HTML (captive portal, corporate proxy). This is the
mode that today produces **no output whatsoever**; it must produce B-1's statement.

**BC-4 — Tag without a leading `v`.** The extraction at HEAD strips a leading `v`; a tag lacking it
passes through unchanged. If the result is still semver-like the run proceeds (unchanged from HEAD);
if not, it is failure mode B-2.5.

**BC-5 — Pipe-closed-early nondeterminism.** With `pipefail` set, an element of the extraction that
is terminated by a downstream reader closing the pipe contributes a non-zero status to the pipeline.
The design must not let a *successful* fetch be classified as a failure by this route (B-6).

**BC-6 — `set -u`.** Every variable the design introduces is assigned before it is read, on both the
success and the failure path. An unset-variable dereference under `set -u` is itself an abort with no
stated outcome — the same class of defect this task removes.

**BC-7 — bash 4.2 floor.** RHEL/CentOS 7 ships bash 4.2, and `install.sh:321-324` already documents
and works around a 4.2/4.4 difference (expanding an empty array under `set -u`). No construct
requiring bash ≥ 4.4 is introduced.

**BC-8 — curl 7.29 floor.** No option outside curl 7.29's set is used (T-08's settled constraint;
`docs/tasks.md` T-08 row).

**BC-9 — Already-installed short-circuit.** When `sing-box` is already on `PATH`, step 2 takes the
other branch and performs **no** HTTP request at all. This fix changes nothing on that branch, and it
therefore affects fresh installs (and hosts where the binary was removed) only.

**BC-10 — Language always known.** The version query runs strictly after the language prompt, so a
localized statement is always possible on this path; there is no "before the language is chosen"
case to handle.

**BC-11 — Both language branches.** The zh table is reachable only by answering `2`. A verification
that exercises English only proves nothing about the zh path (`.harness/insight-index.md:10`).

**BC-12 — Non-TTY output contract.** The version query uses the quiet curl option set, so no carriage
return or partial redraw can enter a captured log on this path; that remains true after the change.

**BC-13 — Log sink not yet open.** The install log probe runs after step 5, so step 2 has no log to
write to. The statement required by B-1 goes to the terminal; nothing on this path may assume a
writable `/var/log/sing-box/install.log` or reference it as holding the cause.

**BC-14 — Concurrency.** Two concurrent installer runs are not a supported scenario and no new shared
state is introduced, so no new concurrency hazard arises. Stated so the omission is deliberate.

**BC-15 — Maximum size.** The latest-release JSON is ~1.6 KB (T-08's Q-2). Nothing on this path
buffers an unbounded body to disk; a large or unbounded body is bounded by the same behavior as HEAD.

**BC-16 — verify_all summary shifts.** Wiring B-8's check into `verify_all.sh` changes the run
summary (a step that is `SKIP` at HEAD becomes a real check). A delta against a pristine baseline
must be read as this expected flip and nothing else. Per `.harness/insight-index.md:26`, the pristine
baseline is a **clone**, never a `git worktree`.

---

## 6. Acceptance criteria

Each is verifiable by an agent that **cannot** run the installer end to end. The witness is stated.
None is of the self-violating form "no occurrence of `<literal>` anywhere in the repository"
(`.harness/insight-index.md:19`) — every literal-level criterion below is scoped to `install.sh`.

| # | Criterion | Witness |
|---|---|---|
| **AC-1** | Experiment E-0 (§2.2) is executed verbatim and its transcript pasted into `02_SOLUTION_DESIGN.md`. All seven predictions match. If E1 or E2 contradicts its prediction, the task returns to stage 1 instead of proceeding. | `bash -c` invocations in a temp directory. No root, no network, no writes outside the temp dir. |
| **AC-2** | `bash -n install.sh` exits 0. | Direct command. |
| **AC-3** | `.harness/scripts/verify_all.sh` reports 0 FAIL, and the PASS/WARN/SKIP delta against a pristine-HEAD **clone** is exactly the B-8 flip described in BC-16 — no other step changes state. | Two runs, changed tree and clone, both summaries pasted. |
| **AC-4** | For each of the five failure modes in B-2, a driver exercising the version-query logic **in isolation** (the relevant fragment extracted into a temp directory, or the endpoint pointed at a local fixture — never the installer itself) shows: the localized statement required by B-1 and B-4 on the terminal, and exit status 1. Five separate results, none inferred from another. | Fragment-level harness in a temp dir; a local fixture server or a stubbed `curl` on `PATH`. No root, no package manager, no writes outside the temp dir. |
| **AC-5** | AC-4 is run for **both** `en` and `zh`, and in `zh` every asserted line is non-empty and contains no `unbound variable`. Ten results total. | Same harness with the language selection forced both ways (BC-11). |
| **AC-6** | Given a fixture returning a real latest-release JSON, the isolated driver extracts the same version string HEAD extracts and prints the same pre-download notice line, byte for byte. | Same harness, success fixture, byte comparison against the HEAD fragment run on the same fixture. |
| **AC-7** | The B-8 parity check passes on `install.sh` as shipped, **and fails** on a copy of `install.sh` in a temp directory with one key deleted from exactly one language table. Both key-set and specifier-count mismatches are separately shown to fail. | Run the committed check against the real file and against two mutated temp copies. Mutations never touch the working tree. |
| **AC-8** | The two language tables of `install.sh`'s translation function hold the same key set and the same per-key conversion-specifier counts after the change. | The B-8 check's own output on `install.sh` (this is AC-7's PASS leg, restated as the product property it guarantees). |
| **AC-9** | The diff introduces, removes or alters **no** curl option in `install.sh`, and adds no timeout, retry or backoff option anywhere. | `git diff install.sh` inspected line by line; the `CURL_OPTS_*` definitions are byte-identical to HEAD. |
| **AC-10** | The diff invokes no external command that HEAD's `install.sh` does not already invoke, and adds no new file to the installed footprint. | Command inventory of HEAD's `install.sh` vs the changed file, compared as sets. |
| **AC-11** | T-01's machinery is intact: the three phase variables' names and pessimistic defaults, `install_report()`'s success condition, and the closing `install_report || exit 1` are unchanged — except for whatever the design deliberately adds to route step 2, which is stated and justified in `02_SOLUTION_DESIGN.md`. `install_report()`'s output for a run that reaches step 7 is unchanged. | `git diff install.sh` inspected; the report function's success and failure branches diffed against HEAD. |
| **AC-12** | The shipping diff is confined to: `install.sh`, `CHANGELOG.md`, the B-8 check script, `.harness/scripts/verify_all.sh`, `docs/tasks.md`, `docs/dev-map.md`, `CONTEXT.md` (stage 1 added two glossary terms), and `docs/features/install-version-query-abort/`. Nothing else. | `git status --porcelain` and `git diff --stat`. |
| **AC-13** | `02_SOLUTION_DESIGN.md` contains the §2.3 sweep table with one row per command substitution in `install.sh` and a verdict per row; the row count equals the number of such substitutions in the changed file. | Count the substitutions in the changed `install.sh`; compare to the table's row count. |
| **AC-14** | The live sing-box service was never touched during the whole task. | `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` identical at task start, after development, and after QA (`.harness/insight-index.md:22` — `is-active` is **not** a valid witness). |
| **AC-15** | Nothing was written under `/etc`, `/usr/local`, or `/etc/sudoers.d` and no package manager ran at any point in the task. | Explicit statement per stage plus a listing of the paths each stage wrote. |

---

## 7. Non-functional requirements

Only the material ones.

- **NFR-1 — Compatibility floors, unchanged:** bash 4.2 (BC-7), curl 7.29 (BC-8), the six supported
  package managers and both init systems. This change is init-system-agnostic — step 2 runs before
  any service work — and must stay that way.
- **NFR-2 — Single self-contained file.** `install.sh` is served over `curl | bash`
  (`.harness/rules/50-singbox-cli.md`); nothing may be split out of it.
- **NFR-3 — Idempotency.** Re-running the installer stays the documented upgrade path and must not
  destroy user data (B-9).
- **NFR-4 — Security.** No credential, token or `.netrc` is introduced (O-4). Nothing on this path
  writes a file, widens a sudoers entry, or changes a mode. The installer runs as root; the failure
  path must remain a pure print-and-exit.
- **NFR-5 — Performance.** Not material. The path adds no request and no wait; the response is ~1.6 KB.
- **NFR-6 — Honest reporting.** B-4 is an NFR as much as a behavior: T-01 exists because a banner
  that disagrees with reality is worse than no banner.

---

## 8. Related tasks

| Task | Doc | Why it binds this one |
|---|---|---|
| **T-08** `install-binary-download-progress` | `/home/alan/Programs/singbox-cli/docs/features/_archived/install-binary-download-progress/` | **Origin of this row.** Found the defect at stage 2 (`02_SOLUTION_DESIGN.md` §11 R-D), verified at stage 1' (`01_REQUIREMENT_ANALYSIS.md` §4 item 11 / E-15 / §9 D-5), filed it in `.harness/rejected-decisions.md` under `installer-version-query-silent-abort` with an explicit unblock path this document follows. Owns the curl flag policy (O-2), the curl 7.29 floor (BC-8), the release-JSON size (BC-15), and the key-parity extractor definition reused by B-8 (`02_SOLUTION_DESIGN.md` §S-6: key sets **and** per-key `%`-placeholder counts). |
| **T-01** `install-enable-start-split` | `/home/alan/Programs/singbox-cli/docs/features/install-enable-start-split/` | Built the phase variables, `install_report()` and the derived exit status — the guarantee this task's defect bypasses. AC-11 protects it. |
| **T-10** `ruleset-update-no-needless-restart` | `/home/alan/Programs/singbox-cli/docs/features/_archived/ruleset-update-no-needless-restart/` | Boundary only (`bin/sc`). Supplies AC-14's witness: `systemctl is-active` cannot detect a restart. |
| **T-02** `config-degrade-missing-rulesets` | `/home/alan/Programs/singbox-cli/docs/features/config-degrade-missing-rulesets/` | Boundary only. Supplies the live-restart incident behind the safety rule (`.harness/insight-index.md:13`). |
| **T-09** `fix-rules-update-execstart` | `/home/alan/Programs/singbox-cli/docs/features/fix-rules-update-execstart/` | Boundary only (`systemd/`). Supplies the self-violating-criterion trap (`.harness/insight-index.md:19`) avoided in §6. |

Standing declines consulted in `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md`:
`installer-version-query-silent-abort` (this row's own deferral — now unblocked),
`ruleset-unit-tests-in-t02` (the parity-gate deferral resolved as D-2),
`t-fmt-default-fallback` (do **not** re-propose a `local fmt` default — declined, and D-2 is the
structural answer it names).

---

## 9. Open questions — resolved under deferred-human authority

Decision mode is **deferred-human**: the owner granted standing authority (「你来决策就行」). Each
question below is stated, resolved on evidence, and recorded so stage 2, stage 3 or the owner can
overturn it. The labelled `Recommended:` line is the resolution the pipeline adopts unless overridden.

### D-1 — Which failure modes must reach a stated outcome?

Candidates: (a) only the transport/HTTP failures named in the T-08 filing; (b) all five modes of
B-2, including the two the current handler already catches.

**Resolution: (b).** Splitting them would leave two code paths deciding the same thing — "is this
version string usable?" — which `.harness/rules/85-design-discipline.md` test 2 names as one task,
not two. The existing handler's intent is preserved, not replaced.
**Recommended:** (b).

### D-2 — Does the committed bilingual key-parity gate belong in T-11?

This is `docs/tasks.md` "Open rows surfaced by T-08" row #2, deferred four tasks running.
Candidates: (a) re-home again to T-07; (b) commit an `install.sh`-scoped parity check in this task.

**Resolution: (b) — in scope, as B-8, bounded exactly as B-8 and O-9 state it.** Four reasons, in
order of weight:

1. **It is this task's own verification instrument, not a general test project.** B-7 requires
   bilingual parity for every string on the changed path, and `.harness/insight-index.md:10` says an
   English-only run cannot detect a break. Because §2.4 leaves the reporting route open, the design
   may or may not add keys — the check makes both branches safe, and it is the only *mechanical*
   witness available to an agent that cannot answer `2` at an interactive prompt. Rule 85's test
   ("name the future edit it prevents") is met by a present, not speculative, need.
2. **The written unblock instruction points here.** `.harness/rejected-decisions.md:57-73` says the
   next task "should probably widen its own diff instead"; T-08 could not because its AC-19 pinned
   the diff. T-11 has no such pin. This is **re-homing already-filed scope**, which rule 85 §"Recording
   the call" explicitly contemplates — not inventing new scope, so red line 3 of
   `.harness/rules/25-decision-policy.md` is not engaged.
3. **`.harness/rules/50-singbox-cli.md` already asks for it** ("bilingual parity: assert every
   user-facing string … so a one-language message cannot ship") and states that a permanently
   `SKIP`ping check proves nothing.
4. **It is cheap and self-contained** — one script reading one file, no new dependency, reusing
   T-08's already-specified S-6 semantics.

Costs accepted and bounded: it flips a `verify_all` step from `SKIP` (BC-16 makes the summary shift
expected rather than a regression), and it touches `.harness/scripts/`, which T-07 otherwise owns —
so B-8 is deliberately narrow (`install.sh` only, O-9), leaving T-07's harness charter intact.

**Overturn cheaply if:** stage 2 finds the check cannot be written without a fragile parser of the two
`case` blocks. In that case defer again *and say so in `.harness/rejected-decisions.md`* — a fifth
silent deferral is what this decision forbids, not a fifth reasoned one.
**Recommended:** (b).

### D-3 — Are the unguarded `mktemp -d` assignments in scope?

Candidates: (a) fix them with the version query (same mechanism); (b) report and re-home.

**Resolution: (b), re-homed as R-1.** They share the *mechanism* but not the *judgment*: no handler
below them is made unreachable (there is none), `mktemp` writes its own diagnosis, and the failure
domain is the local temp filesystem rather than the network. Rule 85's two seam tests both come back
negative — neither computes a value the other consumes, and neither needs the other's judgment. If
stage 2's chosen shape happens to cover them at zero cost, stage 2 states that and the extra coverage
is welcome; any user-facing string it adds still obeys B-7. It is not required.
**Recommended:** (b).

### D-4 — Does the fix introduce a new message key, or reuse `download_failed` / `check_network`?

Candidates: (a) reuse the two existing keys unchanged; (b) add a version-query-specific key.

**Resolution: (a) is the default; (b) is permitted where B-4 requires it.** Reuse keeps the parity
surface at zero and preserves the message the failure path was written to print. But B-4 is the
binding constraint, not key economy: if the route stage 2 chooses would otherwise print something
untrue (§2.4), a new key is the correct answer and B-7/B-8 make it safe. Stated as a default rather
than a prohibition because mandating key reuse would be mandating mechanism.
**Recommended:** (a) unless B-4 forces (b); state which in `02_SOLUTION_DESIGN.md`.

### D-5 — Authenticate the GitHub API call to dodge the 403?

Candidates: (a) accept a `GITHUB_TOKEN` / `.netrc`; (b) decline.

**Resolution: (b), declined.** It is the obvious fix and the wrong one for this row: it puts
credential handling into a root script served over `curl | bash`, it is a security-surface decision
(red line 5), and the rate limit is not what this task is about — the task is that a failure states
nothing. An authenticated call still fails on DNS, on 5xx, and behind a captive portal. Append this
to `.harness/rejected-decisions.md` at delivery.
**Recommended:** (b).

### D-6 — Should the exit status stay 1, or become a distinct code?

Candidates: (a) exit 1, matching both today's diagnosed step-2 path and `install_report`'s failure
status; (b) a distinct code so automation can tell this failure apart.

**Resolution: (a).** A distinct code is a new public contract nobody requested, and holding the
status at 1 makes the criterion **route-neutral**: a direct `exit 1` and an `install_report || exit 1`
route produce the same observable status, so B-1 can be judged without knowing which the architect
picked. That neutrality is the point.
**Recommended:** (a).

### D-7 — Does this task claim "the installer always states its outcome"?

Candidates: (a) yes — it completes T-01's guarantee; (b) no — it closes the version-query hole only.

**Resolution: (b).** §2.3's last paragraph found at least six bare commands whose failure still
aborts with no stated outcome. Claiming (a) would put a false sentence in `CHANGELOG.md` and in the
delivery note, and would let a later task believe a property that does not hold. R-3 carries the rest.
**Recommended:** (b).

### Re-homed rows for `docs/tasks.md` (PM to number)

- **R-1** — Unguarded `mktemp -d` assignments in `install.sh` abort the run with only `mktemp`'s raw
  English line. Low frequency, real. (D-3.)
- **R-2** — The two `sing-box version | head -1` substitutions print an empty version and continue if
  `sing-box` exits non-zero; the substitution's status is discarded, so this is a display defect, not
  an abort. Affects the already-installed and just-installed notices.
- **R-3** — The wider class: bare `python3` heredoc, `tar`, `install -m`, `visudo`, `chmod` failures
  abort `install.sh` with no stated outcome. T-01's guarantee is not global and this task does not
  make it so (D-7). This row is the one that would.
- **R-4** — Depending on D-2's outcome at stage 2: if the parity check ships, `.harness/scripts/baseline.json`
  still reads `test_count: 0` and can finally be populated; if it does not ship, `rejected-decisions.md`
  gains a fifth, *reasoned*, deferral.

---

## 10. Verdict

No ambiguity remains unresolved: every judgment call is recorded in §9 under standing authority, and
no safety red line is engaged. The one obligation this stage could not discharge itself — the shell
semantics experiment, because stage 1 had no shell-execution tool — is carried forward as **AC-1**
with per-case predictions and an explicit stop rule, so it is auditable rather than assumed.

**READY FOR DESIGN**
