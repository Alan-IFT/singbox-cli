# 02 — Solution Design — restricted-network-regression-test (T-07)

> Contract portion. Rationale: 02_RATIONALE.md (absent = none written).

- **Task ID**: T-07 · **Mode**: full · **Date**: 2026-08-14 · Upstream verdict read: `READY`.
- `.harness/rules/70-doc-size.md` still defines no `## Stage-doc boundary rule` (R-37, fourth
  occurrence), so this portion carries the architect schema as written. The FR/BC/AC → design
  coverage table, the risk analysis and `## Smaller alternative rejected` (rule 85) are in
  `02_RATIONALE.md`, which the gate reads by default. Routing filed as RS-1.

## Architecture summary

One new executable file, `.harness/scripts/restricted-network-regression.sh`, drives the whole
scenario: it derives the blackout from `bin/sc`'s `RULESET_BASES` textually, sinks those hosts in
`/etc/hosts`, runs `install.sh` from the checkout, and prints six condition lines.

Nothing in the shipped product changes — `install.sh`, `bin/sc`, `uninstall.sh` and `systemd/` are
byte-frozen, and no `verify_all` step, `baseline.json` value or `.gitignore` pattern moves.

The seam is `/etc/hosts` + name resolution: the one place the four shipped sources and the three
GitHub names can be made unreachable without editing a shipped file or replacing `sc`'s source list.

## Change ledger

| id | absolute path | new/edit | what changes | partition |
|---|---|---|---|---|
| C-1 | `/home/alan/Programs/singbox-cli/.harness/scripts/restricted-network-regression.sh` | new | The whole artifact: Chinese operator-guide header + English executable body, mode `0755`, `#!/usr/bin/env bash`. Whole file ≤ 250 lines (K-10). | single |
| C-2 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | edit | Two rows appended to the `## Reusable utilities` table (I-9, I-10). No other line of that file changes — in particular the "no test directory" sentence stays true, because the artifact adds no directory. | single |
| C-3 | `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | edit | One appended record, `## blackout-by-sb-rules-base-env-var` (I-11). | single |
| C-4 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | edit | One appended `## Language` entry, **blackout** (I-12). | single |
| C-5 | `/home/alan/Programs/singbox-cli/docs/features/restricted-network-regression-test/04_DEVELOPMENT.md` | new | Stage-4 document (canonical name). | single |

No other file is touched. A file the developer finds themselves editing that has no row here is a
design defect — stop and report it rather than widening the diff.

## Interfaces

| id | surface | shape (signature / route / table / heading) | invariant |
|---|---|---|---|
| I-1 | mutating invocation | `sudo bash .harness/scripts/restricted-network-regression.sh --i-will-destroy-this-vm` | The single accepted token, spelled exactly once in the file and named verbatim in the usage text. No environment variable, no `-y`, no second spelling. |
| I-2 | self-check invocation | `bash .harness/scripts/restricted-network-regression.sh --self-check [--source FILE]` | Needs no root, no network, writes nothing anywhere. `--source` defaults to `<repo>/bin/sc`; it is the **only** parameter of the derivation and exists so AC-5's uncovered-entry run has a scratch list. |
| I-3 | any other argv (including none) | usage text on stderr naming `--i-will-destroy-this-vm` and `--self-check`; exit `2` | Prints no condition line: nothing was asked, so nothing is claimed. |
| I-4 | exit statuses | `0` all six PASS · `1` any non-PASS condition, or self-check coverage failure · `2` usage · `3` FR-11 refusal | `0` is reachable only from a run whose report holds exactly six lines, all `PASS`. |
| I-5 | condition report | exactly six lines, `E<n> <PASS\|FAIL\|BLOCKED\|UNMET> obs=<observation> pair=<counter-observation>` for `n` = 1…6, in order, on stdout | One line per condition on every path that got past I-3 — including the refusal path (six `UNMET`) and every precondition path. Both fields are values read in **this** run (a mode, an exit status, a matched marker, a count), never a restatement of the assertion. |
| I-6 | `derive_bases FILE` | stdout, one base URL per line: `sed -n '/^RULESET_BASES = (/,/^)/p' FILE` piped to `grep -oE 'https?://[^"]+'` | Textual. Never imports, sources, executes or `python3`-loads the candidate `bin/sc` (out-of-scope 2; the auto-elevate at `bin/sc:124-125` re-execs the **installed** `sc` against the live service). Zero lines out ⇒ BC-13. |
| I-7 | `blackout_set` | the hosts of I-6's bases (field 3 of a `/`-split) ∪ `github.com` `raw.githubusercontent.com` `api.github.com`, deduplicated | A base whose host is empty, an IPv4/IPv6 literal, or `localhost` is **uncoverable**: `/etc/hosts` maps names, not addresses. Uncoverable ⇒ BC-2 (named on stdout, non-zero / UNMET), never a silent skip. This predicate is the single home of FR-3 coverage, BC-2 and BC-13, and the self-check runs exactly it. |
| I-8 | `/etc/hosts` block | lines `# BEGIN singbox-cli-restricted-network-regression` … `# END …`, between them one `0.0.0.0 <host>` line per I-7 host | Appended after `cp /etc/hosts $WORK/hosts.orig`. The blackout is **lifted** by `cp $WORK/hosts.orig /etc/hosts` — a byte restore, not an edit, so E6's "nothing else changed" is exact. `/etc/hosts` is the only host file outside `$WORK` the artifact itself writes. |
| I-9 | injection proof | for every I-7 host: `getent hosts <host>` prints at least one line and **every** first field is `0.0.0.0` | Runs after I-8 and before `install.sh`. Any host failing it ⇒ arm UNMET before the first installer byte. Discharges BC-3's "the injection reached the effective list" from the resolver side; the log-side half is E3's per-source assertion (K-11). |
| I-10 | `cfg_facts` | `python3 - "$CFG" <<'PY' … PY` printing one line `defs=<n> route_refs=<n> dns_refs=<n>` | `defs` = length of `route.rule_set` (absent ⇒ 0); `route_refs`/`dns_refs` = number of elements of `route.rules`/`dns.rules` carrying a `rule_set` key. Prints **counts only** — never a key, a value, a tag or any byte of the document (K-8). Used by E4 and E6 with the same reader. |
| I-11 | `docs/dev-map.md` row | one `## Reusable utilities` row, Need = "Which curl flags the installer uses" | Names `CURL_OPTS_QUIET` / `CURL_OPTS_PROGRESS`, `install.sh`'s `# download flag policy` block, and the three facts that make it a seam: `-s` and `--progress-bar` are not additive so the progress variant **drops** `-s`; `-S` is kept in both; `[ -t 2 ]` — the terminal-ness of **stderr**, not stdout — selects the variant, which is what keeps `0x0D` out of a captured log. Closing rule: a new transfer uses one of the two arrays, never inline flags. |
| I-12 | `docs/dev-map.md` row | one `## Reusable utilities` row, Need = "Does a restricted-network install still end in a working degraded state?" | Names the artifact's path, what it asserts (E1…E6 in one sentence), that it derives the blackout from `RULESET_BASES` textually rather than importing `bin/sc`, and **where it can run**: root on a disposable single-use systemd VM with `/dev/net/tun`, never a workstation; `--self-check` is the only form safe on a developer machine. States that it is deliberately **not** wired into `verify_all` (R-9) and has no `.ps1` mirror, like `check-i18n-parity.sh`. |
| I-13 | `.harness/rejected-decisions.md` record | `## blackout-by-sb-rules-base-env-var` | Decision (declined), a substantive why (it replaces the source list instead of making the shipped one unreachable, so it proves nothing about the four shipped sources and cannot cover the three GitHub names), and the origin (T-07 stage 2, BC-3). |
| I-14 | `CONTEXT.md` entry | `**blackout**:` under `## Language` | 2 sentences: the deliberate, derived unreachability of every shipped rule-set source plus the three GitHub names, injected by name resolution and lifted by restoring one file. `_Avoid_: offline mode, air-gap, network failure, mock` |
| I-15 | operator guide | a Chinese comment block at the top of the artifact, headed `# ===== 受限网络回归测试 · 操作指南（一次性 VM）=====` | Carries: the FR-2 preconditions; how to satisfy them on a disposable VM; the invocation **including the token verbatim**; and the sentence that the VM is single-use and is never reset by the artifact. Chinese per `.harness/rules/00-core.md`; it is the only Chinese in the file. |

## Constraints

**K-1** — The developer writes `set -uo pipefail` and **not** `set -e`: in this artifact a non-zero
status is the datum (`is-enabled` on an absent unit, a failed `sc update-rules`), so `-e` would abort
at the observation it exists to take. Every status that matters is captured explicitly as
`rc=0; cmd >"$f" 2>&1 || rc=$?`, and the four commands that must succeed (`mktemp -d`, the
`/etc/hosts` backup, the block append, the restore) are each followed by `|| die`.

**K-2** — The developer never writes a bare `VAR=$(cmd | grep …)` whose status is consulted, and
never redirects into a path before proving its directory writable; both are the live traps recorded
for this repo. All capture files live under the `mktemp -d` work directory.

**K-3** — The mutating path evaluates its gates in exactly this order, and performs **no** write of
any kind before all four pass: (1) token present, else I-3; (2) node store `/etc/sing-box/nodes.json`
present — `[ -e ]` **or** `[ -L ]`, so an unreadable or dangling one counts as configured — then
refuse, print the path, print six `UNMET` lines, exit `3`; (3) `EUID` is 0; (4) the remaining FR-2
preconditions. Gate 2 precedes gate 3 deliberately: that ordering is what makes AC-4 dischargeable
on a host that carries a live installation without any possibility of mutating it.

**K-4** — Outside `$WORK` and `/etc/hosts`, the artifact writes nothing itself. It never invokes
`uninstall.sh`, never removes or resets `/etc/sing-box`, `/var/lib/sing-box` or any unit, and never
touches firewall, `resolv.conf` or any other network configuration. Whatever `install.sh` and `sc`
write is theirs.

**K-5** — Assertions over captured installer output test **presence** of a marker, never its order,
adjacency or line number: `sys.stderr` is block-buffered on this project's 3.6 floor, so a merged
`2>&1` capture may reorder stdout against stderr.

**K-6** — Prompt answers are supplied as `printf '1\ny\n' |` on the `install.sh` invocation — `1`
selects English, `y` answers the root-install confirmation. Every assertion is therefore against an
English string, and the artifact introduces no Chinese runtime string (so it cannot collide with the
load-bearing `失败：` grep) and prints English only.

**K-7** — The artifact's own waiting totals ≤ 30 s: an E5 settle loop of at most 10 × 1 s and an E6
post-restart witness of at most 5 × 1 s. No other `sleep`. All remaining wall-clock is the
installer's and `sc`'s unchanged timeouts.

**K-8** — The artifact prints no byte of `config.json` or `nodes.json` content: only counts (I-10),
file modes, exit statuses, and the marker strings it matched.

**K-9** — Before running the installer the artifact requires `SB_RULES_BASE` to be unset or empty,
else UNMET: a set value replaces `sc`'s source list (`bin/sc:1052-1061`) and would make the derived
blackout irrelevant to what `sc` actually fetches.

**K-10** — One executable file, whole-file cap **250 lines** including the I-15 guide block; target
≤ 235. No new directory, no second file, no dependency beyond bash, coreutils, curl, python3,
systemd and glibc's `getent` — all already required by `install.sh` on the same host.

**K-11** — FR-10's "unproven" is reported as `BLOCKED`, never as PASS and never as a fifth status:
each condition line carries a `pair=` field holding a value observed in this same run under which
the assertion does not hold, and a condition whose `pair=` value could not be taken is `BLOCKED`
with reason `unproven`. The six pairs are fixed: E1 the failure-banner count from the same capture;
E2 and E5 the pre-install `systemctl is-enabled` / `is-active` readings recorded during gate 4;
E3, E4 and E6 the cross-arm readings (blackout vs. recovery) of the same three observations.

**K-12** — If the captured installer output does not contain the step-6 line (`[6/7]`), the run
reports all six conditions `UNMET` with reason `installer did not reach the rule-set step`. This
single rule discharges BC-6 (a run that ends at a prompt) and every pre-step-6 environmental failure
(no package manager, an unreachable distro mirror), so neither can ever be reported as `FAIL`.

**K-13** — The developer wires nothing into `.harness/scripts/verify_all.sh`, writes no `.ps1`
mirror, and changes no value in `.harness/scripts/baseline.json` (R-9 owns all three).

## Frozen set

| path | why frozen |
|---|---|
| `/home/alan/Programs/singbox-cli/install.sh` | AC-16 byte-identical to `HEAD`; the artifact observes it, never edits it. |
| `/home/alan/Programs/singbox-cli/bin/sc` | AC-16; also the derivation's subject — editing it would invalidate FR-3. |
| `/home/alan/Programs/singbox-cli/uninstall.sh` | AC-16. |
| `/home/alan/Programs/singbox-cli/systemd/*` | AC-16, every file. |
| `/home/alan/Programs/singbox-cli/.harness/scripts/baseline.json` | AC-17, byte-unchanged. |
| `/home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh` / `.ps1` | Out-of-scope 1 (R-9); any edit moves AC-2's counts. |
| `/home/alan/Programs/singbox-cli/.gitignore` | The chosen location needs no ignore change; editing it to accommodate a `test/` placement is exactly what AC-1 is guarding against. |
| `/home/alan/Programs/singbox-cli/README.md`, `README.zh-CN.md`, `CHANGELOG.md` | A maintainer regression harness is not a user-visible change; CHANGELOG is for user-visible changes. |
| `/home/alan/Programs/singbox-cli/.claude/**`, `CLAUDE.md`, `.github/copilot-instructions.md` | Generated / static stubs; project red line. |
| the pipeline host's `/usr/local/bin`, `/etc/sing-box`, `/var/lib/sing-box`, `/etc/hosts`, systemd units, live service | Never written, never `is-active`-probed during this task; witnessed only with `systemctl show -p MainPID -p ActiveEnterTimestamp` (AC-18). |

## Migration & edit sequence

| order | edit ids | precondition | rollback |
|---|---|---|---|
| 1 | C-1 | Repo clean at `HEAD`; no `test/` placement considered (`.gitignore:19`). | `git rm --cached` + delete the file; nothing else references it yet. |
| 2 | C-1 (mode) | File exists. Set mode `0755` at creation (`install -m 755` or `chmod +x`), so `git ls-files -s` records `100755`. | `chmod 644`. |
| 3 | C-2 | C-1 exists, so the row's path claim is true when written. | Revert the two appended rows; the table has no other change. |
| 4 | C-3, C-4 | — | Revert the appended record / entry. |
| 5 | verification | C-1…C-4 in place. `bash -n` on the artifact, then `.harness/scripts/verify_all` compared to `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`. | If any count moved, the cause is an edit outside this ledger — revert it, not the artifact. |

No data migration, no flag, no backwards-compatibility surface: nothing consumes the artifact, and
no shipped file changes. The only host-state change any run makes is inside a disposable VM, where
Q-16 makes the VM itself the rollback.

## Out of scope

1. Everything in the requirement's own out-of-scope list, unchanged — in particular wiring a `verify_all` step, the `.ps1` mirror, `baseline.json`, and importing `bin/sc`.
2. Making the artifact runnable on this pipeline's host: it is designed to refuse there (K-3 gate 2), and that refusal is the only behaviour of it this task observes here.
3. Container, `bwrap`, `nspawn` or VM-image automation for the `[VM]` criteria; the VM is provided by the operator, per the I-15 guide.
4. Any second scenario (partial blackout, one mirror alive, a slow mirror, a truncated body). The artifact tests total blackout and full recovery, and nothing else.
5. Asserting anything about the OpenRC path, a second distribution, or the remote-artifact branch of `install.sh`.
6. Cleaning up, resetting or uninstalling the scenario host after a run.
7. A machine-readable (JSON/TAP) report form; the six lines are the interface.

## Verification plan

| step id | what is run/measured | expected observable | AC |
|---|---|---|---|
| V-1 | `git ls-files .harness/scripts/restricted-network-regression.sh`; `git check-ignore -v` on the same path | listed once, mode `100755`; `check-ignore` prints nothing and exits 1 | AC-1 |
| V-2 | `bash -n` on the artifact; `.harness/scripts/verify_all` | parses; counts exactly `PASS 17 / WARN 0 / FAIL 0 / SKIP 1` | AC-2 |
| V-3 | as an unprivileged user with **no** argument: run it; capture `/etc/hosts` sha256 and `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` before and after | usage on stderr naming `--i-will-destroy-this-vm`, exit 2, no condition line; both witnesses identical | AC-3 |
| V-4 | as an unprivileged user with the token, on this host (which carries `/etc/sing-box/nodes.json`) | refusal naming the node-store path, six `UNMET` lines, exit 3; `/etc/hosts` sha256 unchanged | AC-4, AC-20 (host half) |
| V-5 | `--self-check`; then `--self-check --source <scratch file whose RULESET_BASES block carries one `https://127.0.0.1/geo` entry>` | first: four bases listed, all covered, exit 0. second: exit non-zero, the `127.0.0.1` base named as uncoverable | AC-5 |
| V-6 | read the two new `docs/dev-map.md` rows against I-11 and I-12 | every named element present | AC-14 |
| V-7 | read the artifact's I-15 header block | Chinese; preconditions, VM setup, invocation with the verbatim token, single-use statement | AC-15 |
| V-8 | `git clone` the repo at `HEAD` into an ignored path (`test/…`, never a `git worktree` — a worktree's `.git` file turns A.1/A.2 SKIP and the summary reads falsely 14/4); `sha256sum` `install.sh`, `bin/sc`, `uninstall.sh`, `systemd/*` on both sides | identical per file | AC-16 |
| V-9 | `cmp .harness/scripts/baseline.json` against the clone | identical | AC-17 |
| V-10 | `systemctl show -p MainPID -p ActiveEnterTimestamp sing-box` at task start and at delivery | identical strings; `is-active` never invoked | AC-18 |
| V-11 | read `06_TEST_REPORT.md` against the `[VM]` rows | AC-6…AC-13 each reported `BLOCKED` with its reason; no artifact inspection substituted for a run | AC-19 |
| V-12 | `[VM]` full run: the captured installer output and its exit status | `✅ Install complete` present, `❌` absent, exit 0 → `E1 PASS` | AC-6 |
| V-13 | `[VM]` `systemctl is-enabled sing-box` / `… sing-box-rules-update.timer` / `is-active … .timer` | `enabled`, `enabled`, `active` → `E2 PASS`, paired against the pre-install readings | AC-7 |
| V-14 | `[VM]` `stat -c %a /var/log/sing-box/install.log`; per `.srs` a `failed:` line naming all four derived bases; the `4 ruleset(s) failed to update` line; the `rule-sets unusable` + `degraded to no-splitting mode` warning; the installer capture's step-6 line | `640` and all five markers present (BC-10: if the capture carries the `is not writable` form instead, `E3 FAIL` recording that line) | AC-8 |
| V-15 | `[VM]` `stat -c %a /etc/sing-box/config.json`; `cfg_facts` (I-10); `sing-box check -c /etc/sing-box/config.json` | `600`; `defs=0 route_refs=0 dns_refs=0`; exit 0 → `E4 PASS` | AC-9 |
| V-16 | `[VM]` `systemctl is-active sing-box` within the ≤10 s settle loop | `active` → `E5 PASS`, paired against the pre-install reading | AC-10 |
| V-17 | `[VM]` after the `/etc/hosts` restore: one `sc update-rules`; its exit status and output; `cfg_facts` again; `systemctl show -p MainPID` before/after | exit 0, four `OK (` lines, `defs=4 route_refs≥1 dns_refs≥0` with no dangling reference, MainPID changed → `E6 PASS` (BC-9: all four still `failed:` ⇒ `E6 BLOCKED`) | AC-11 |
| V-18 | `[VM]` read the six `pair=` fields | each names a value from this run under which its assertion does not hold | AC-12 |
| V-19 | `[VM]` a deliberate run with `/etc/sing-box/rules/` pre-populated (and no `nodes.json`) | six `UNMET` lines naming the populated directory; no installer invocation | AC-13 |
| V-20 | `[VM]` the full run's report and exit status | exactly six lines; exit 0 iff all six are `PASS` | AC-20 (VM half) |

## Residuals travelling

| id | statement | must reach <stage/doc> |
|---|---|---|
| RS-1 | The FR/BC/AC coverage table, the risk analysis and `## Smaller alternative rejected` are in `02_RATIONALE.md` because `.harness/rules/70-doc-size.md` still has no `## Stage-doc boundary rule` (R-37, fourth occurrence) and the architect schema admits no section for them. | 03_GATE_REVIEW.md |
| RS-2 | Every `[VM]` criterion (AC-6…AC-13, AC-20's VM half) is `BLOCKED` in this environment with its reason; substituting an artifact inspection for a `[VM]` run is a defect (Q-15, AC-19). | 06_TEST_REPORT.md |
| RS-3 | The AC-16 baseline must be a `git clone`, never a `git worktree`; under a worktree `.git` is a file, A.1/A.2 turn SKIP and the summary falsely reads 14/4. | 06_TEST_REPORT.md |
| RS-4 | `.harness/rejected-decisions.md`'s `ruleset-unit-tests-in-t02` record (deferred *to T-07*) is only partly discharged: T-07 commits the artifact but deliberately leaves the `verify_all` wiring, the `.ps1` mirror and `baseline.json` to R-9, so the record's unblock path stays open. | 07_DELIVERY.md |
| RS-5 | The artifact was never executed end to end during this task; its first real run is the operator's, on a VM. The `[HOST]` steps V-1…V-10 are the whole of the evidence this pipeline can produce. | 07_DELIVERY.md |
| RS-6 | T-02's BC-32 (the degradation warning reaching the install log) is closed **by construction of the test**, not by a run; it becomes closed-in-fact only when a `[VM]` run reports `E3 PASS` (Q-13). | 07_DELIVERY.md |

## Verdict

`READY`
