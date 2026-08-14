# 02 — Rationale — restricted-network-regression-test (T-07)

> Rationale portion for 02_SOLUTION_DESIGN.md. Non-binding.

## Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| A committed, project-specific verification script that is git-tracked, unignored, Linux-only, has no `.ps1` mirror and is not a shipped artifact | `check-i18n-parity.sh` | `/home/alan/Programs/singbox-cli/.harness/scripts/check-i18n-parity.sh` | **Reuse the precedent, not the code**: same directory, same "extract, don't execute" discipline, same no-mirror convention. This is why the artifact needs no new directory and no change to `.gitignore` or to `docs/dev-map.md`'s "no test directory" sentence. |
| The rule-set source list | `RULESET_BASES` | `/home/alan/Programs/singbox-cli/bin/sc:113-118` | **Reuse as the single source of truth**, read textually (I-6). Hardcoding the four URLs in the test is the T-08 write-vs-read defect Q-7 turned into FR-3. |
| "Is this rule-set usable?" | `srs_reject_reason` / `ruleset_state` | `bin/sc:813-880` | **Not reused, and deliberately not re-implemented.** The artifact never opens a `.srs`: E4 and E6 read the *emitted config* (I-10), which is what `generate_config()` already derived from that judgment. A second usability opinion in the test would be exactly the defect `docs/dev-map.md` forbids. |
| The degradation behaviour under test | `generate_config()` + `_filter_rules()` + `_warn_degraded()` | `bin/sc:1002-1049`, `:1992-2081` | Subject, not dependency. Frozen. |
| The install log, its mode and the two step-6 message forms | the `umask 027` probe and `step6_warn` / `step6_nolog` | `/home/alan/Programs/singbox-cli/install.sh:554-574` | Subject. E3 asserts against these exact two forms; BC-10 is the second one. |
| The closing banner and the exit status | `install_report()` | `install.sh:257-302`, `:614-615` | Subject. E1's assertion and its `pair=` discriminant are the two arms of this one function. |
| A neutralised `bin/sc` import recipe | the `os`-shim recipe | `docs/dev-map.md:114-147` | **Deliberately not used.** Out-of-scope 2 forbids the import; the design needs the *source list*, which is a text fact, not a runtime one. Not importing also removes the whole class of live-service accidents the recipe exists to contain. |
| An extraction idiom for a bash function under test | `sed -n '/^name() {/,/^}/p'` | `docs/dev-map.md:148-151`, `check-i18n-parity.sh:48` | Reused in shape by I-6's `sed` range over `RULESET_BASES = (` … `)`. Same principle: read the file, never run it. |
| An existing harness from T-02 / T-08 | — | none in repo | Q-6 / Q-7 settled this: those files were never committed and do not exist. Nothing to inherit. |
| A place to say "we declined this approach" | `.harness/rejected-decisions.md` | same | Reused (C-3) rather than inventing a design-note file. |

## Coverage — requirement → design element

| requirement | design element |
|---|---|
| FR-1, AC-1 | C-1 at `.harness/scripts/`, mode 0755; no `.gitignore` pattern matches (`test/` is the only directory pattern, `*.log` the only extension one) |
| FR-2, FR-12, BC-4, BC-5, BC-11 | K-3 gates 3-4 + K-12; unmet ⇒ six `UNMET` lines, distinct from `FAIL` by construction |
| FR-3, BC-2, BC-13 | I-6 + I-7, one predicate; self-check runs the same one (I-2) |
| FR-4, E1 | V-12; capture greps for the two banner forms, K-5 forbids order assumptions |
| FR-5, E2 | V-13; pre-install readings taken at gate 4 supply the pair |
| FR-6, E3, BC-10 | V-14; five markers, all from `/var/log/sing-box/install.log` plus the installer capture |
| FR-7, E4, BC-14 | V-15 + I-10; the structural read is node-free by construction — it counts rule-set definitions and references only |
| FR-8, E5 | V-16, ≤10 s settle (K-7) |
| FR-9, E6, BC-9 | V-17; blackout lifted by the I-8 byte restore |
| FR-10, AC-12 | K-11: the fixed six `pair=` values; unproven ⇒ `BLOCKED` |
| FR-11, BC-7, BC-8 | K-3 gates 1-2, I-3, I-4 exit 2/3 |
| FR-13, AC-20 | I-5 + I-4; six lines on every path past I-3, including the refusal |
| FR-14, AC-5 | I-2 + I-7; `--source` is the scratch-list parameter |
| FR-15, AC-14 | C-2, I-11, I-12 |
| FR-16, AC-15 | C-1's I-15 header block |
| BC-1, AC-13 | gate 4's rule-set-directory check ⇒ UNMET before any installer invocation |
| BC-3 | I-9 (resolver side, before the arm) + E3's per-source log assertion (log side); K-9 closes the inherited-variable hole |
| BC-6 | K-6 supplies both answers; K-12 makes a run that still ends early `UNMET` |
| BC-12 | any observation command that yields no value ⇒ that condition `BLOCKED` (I-5), and I-4 makes the run non-zero |
| NFR line cap | K-10 |
| NFR dependencies | K-10 (bash, coreutils, curl, python3, systemd, `getent`) |
| NFR ≤30 s own waiting | K-7 (≤15 s by construction) |
| NFR no credential bytes | K-8 + I-10 |
| NFR English output | K-6, K-13 |
| AC-2 | V-2; the artifact is in no `verify_all` step's file list (`verify_all.sh:63` names `install.sh` and `uninstall.sh` only), so no count can move |
| AC-3, AC-4 | V-3, V-4 — safe on this host because of K-3's gate order |
| AC-16, AC-17, AC-18 | frozen set + V-8, V-9, V-10 |
| AC-19 | RS-2 |

## Smaller alternative rejected

Rule 85 puts the burden of proof on the larger design, so each of the four candidates below is
smaller than what shipped, and each is answered with what the extra code buys — counted as diff
**plus** what a future reader must hold in their head.

### 1. Inject the blackout with `SB_RULES_BASE=http://127.0.0.1:1/` instead of `/etc/hosts`

**Smaller by:** the whole of I-7's host derivation, I-8's backup/append/restore and I-9's proof —
roughly 25 lines, one file the artifact stops writing, and the entire "did the injection land?"
question BC-3 exists to police. It is the obvious cheap trick, and it is why BC-3 is in the contract.

**What the extra code buys, tested rather than asserted:**

- It changes the *question*. `_ruleset_bases()` (`bin/sc:1052-1061`) makes the variable **replace**
  the built-in list, so the run would prove "an unreachable list yields a degraded install" — a
  statement about a list the product never ships. FR-3's claim is about the four shipped sources
  being unreachable, and E3 asserts the log **names each of them**. Under the variable, those four
  URLs appear nowhere in the log, so E3 as written cannot pass; rewriting E3 to accept the injected
  URL would make the test agree with itself and with nothing else.
- It cannot cover `github.com` / `raw.githubusercontent.com` / `api.github.com` at all, which FR-3
  requires in the union.
- Its correctness depends on an item stage 1 put **out of scope**: T-02's BC-25, whether `env_reset`
  strips `SB_RULES_BASE`. `install.sh` invokes `/usr/local/bin/sc` directly as root so the variable
  does survive today, but the test would silently become vacuous the day any sudo/systemd layer is
  introduced between them — the T-08 defect class again.
- The `/etc/hosts` form is also *more* honest about what it costs: exactly one file, restored
  byte-for-byte, inside a VM Q-14 explicitly permits it in.

Filed as a rejected decision (C-3) because it is the approach the next person will propose first.

### 2. No `pair=` field — assert each condition once and be done

**Smaller by:** six fields, the two pre-install readings taken at gate 4, and the BLOCKED-when-
unproven rule — about 12 lines.

**What the extra code buys:** it is the only guard against the failure this task exists to end. Five
harnesses were discarded before T-11 and T-08's committed defect was a guard that could never fire;
a grep against a capture file that was never written returns "absent" just as convincingly as a
correct negative. E1's pair is one extra `grep -c` against the same file; E2's and E5's pairs are
two readings the precondition check already has to take (an install must not already be enabled or
active); E3/E4/E6's pairs are the two arms the run already performs. Total genuinely new work: one
grep and two variables. This is the cheapest possible discharge of FR-10/AC-5/AC-12, and it is a
requirement rather than a preference.

### 3. Put the operator guide in `docs/faq.md` (or a new `docs/testing.md`) instead of the file header

**Smaller by:** nothing in line count — it moves ~20 lines from one file to another; a new
`docs/testing.md` would be strictly larger (a fifth file, plus a dev-map pointer).

**What the in-file placement buys:** the guide and the token cannot drift, because the guide sits
five lines above the `case` that parses the token; and a destructive, host-mutating procedure stays
out of the end-user FAQ, where the neighbouring entries are "SSH broke after installing" and are
read on the machine the user cares about. The person who needs the guide is already holding the
file. `docs/faq.md` was rejected on the safety argument, not on style.

### 4. Report free-form prose instead of six fixed lines

**Smaller by:** the `cond` helper and the six-line count check — about 8 lines.

**What it buys:** FR-13 and AC-20 are stated in terms of one line per condition and an exit status
derived from them; and the count check is what stops the artifact exiting 0 after silently skipping
a condition — the same "absence reads as success" hole as #2.

### What was *not* built, and would have been the real over-build

No fixture framework, no mock or local HTTP server, no fault matrix, no runner, no JSON report, no
`.ps1` mirror, no `verify_all` step, no second scenario, no VM provisioning automation, no
`bin/sc` import harness. The artifact is one file with no state but a `mktemp -d` directory, and the
things it could have grown are enumerated in the design's `## Out of scope` so a later reader can
see they were declined rather than forgotten.

## Risk analysis

| id | risk | mitigation |
|---|---|---|
| R-A | **The artifact is run on a real machine by accident** — the worst outcome in this task, since it installs a VPN and rewrites `/etc/hosts`. | K-3's gate order: the node-store refusal precedes the root check, so any host with an installation refuses before it can even establish it is root; the token is a single long literal that cannot be typed by habit; the I-15 guide's first line says the VM is single-use. AC-3/AC-4 discharge both refusal paths on this very host. |
| R-B | **The blackout does not actually reach `sc`** (a resolver stack that bypasses `/etc/hosts`, a cached answer, an inherited `SB_RULES_BASE`), and the arm reports PASS on a run that was never restricted. | Three independent gates: I-9 proves resolution *before* the installer runs; K-9 rejects an inherited variable; E3 requires the log to name every derived base as failed, which is only true if `sc` really tried and really failed on those exact URLs. Any one of them failing makes the arm UNMET/BLOCKED, never PASS. |
| R-C | **The recovery arm has no reachable source** (the VM's egress is broken, or the TUN plus direct mode does not carry DNS after the install), so E6 cannot be observed. | BC-9 is designed in: all four rule-sets still `failed:` ⇒ `E6 BLOCKED`, and E3/E4's cross-arm pairs are reported unproven (K-11) rather than PASS. The run then exits non-zero, so the outcome is legible instead of optimistic. |
| R-D | **A `set -e` assignment abort inside the artifact** kills the run at an observation, in exactly the trap family this repo has hit repeatedly. | K-1 removes `-e` outright and makes every status explicit; K-2 bans the bare `VAR=$(pipeline)` form and puts every capture file under `mktemp -d`; V-2's `bash -n` is the floor, not the ceiling. |
| R-E | **A reordered merged capture** (`2>&1` with Python 3.6's block-buffered stderr) makes an adjacency- or order-based assertion flap. | K-5: every assertion is a presence test over the whole capture. No assertion reads a line number, a first line, or two markers' relative order. |
| R-F | **The artifact rots**: `install.sh`'s strings change and the greps silently stop matching, so the test passes because it asserts nothing. | Every marker is either a `t()` key's English text (`Ruleset download failed`, `✅ Install complete`, `Install incomplete`) or a `bin/sc` translation key (`ruleset(s) failed to update`, `degraded to no-splitting mode`) — all of which live in files the frozen set protects and which `check-i18n-parity.sh` already watches for parity. The `pair=` discriminants (K-11) are the structural defence: if a marker stops matching, its pair still does, and the condition goes BLOCKED rather than PASS. |
| R-G | **AC-2's counts move** because the new file gets picked up by a check. | Verified against `verify_all.sh`: B.1 syntax-checks a fixed list (`bin/sc`, `install.sh`, `uninstall.sh`, `verify_all.sh:55-66`), B.2 runs `check-i18n-parity.sh install.sh` by name, E.4's `harness-sync --check` covers `.harness/agents/` and `.harness/skills/` only (`harness-sync.sh:28-95`), and the F.* caps do not include `.harness/scripts/` or `rejected-decisions.md`. A.1 explicitly excludes `.harness/*` from the secret scan, so K-8 is a design obligation rather than something A.1 would catch. |
| R-H | **The `[VM]` half is never run**, and the harness joins the five discarded ones. | Q-15 accepts this as the expected outcome for *this pipeline*, and RS-2 forces every `[VM]` criterion to be reported BLOCKED rather than quietly inspected. What keeps it runnable later is that it needs no infrastructure: a systemd VM, a `sing-box` binary, a checkout, one command. |

## Design notes the contract does not need to carry

- **Why `getent hosts` and not `curl`** for I-9: it is the resolver's own answer, needs no network,
  costs nothing when the name is sunk, and it is precisely the layer `/etc/hosts` acts at. A `curl`
  probe would conflate resolution with connectivity and would burn a timeout per host.
- **Why `0.0.0.0`** as the sink: a connect to it is refused immediately, so the installer's 30 s
  download timeout is never paid four times over, and the failure the log records is a transport
  error naming the source — which is what E3 asserts. It also makes the blackout visible in one
  `grep` of `/etc/hosts`.
- **Why the recovery arm restores a backup** rather than deleting its own block: a byte restore is
  two lines and cannot leave a partial edit behind if the run dies between them; a `sed` range
  delete has to be correct about its own markers.
- **Why the `ghfast.top` entry yields one host and not two**: its URL embeds a second `https://…`,
  but the client only ever connects to `ghfast.top`; `raw.githubusercontent.com` is covered anyway
  by FR-3's fixed union. Field 3 of a `/`-split is therefore right for all four bases.
- **Precedence between FR-11 and BC-11**: on a host where a previous run completed, `sc reload`
  has created `/etc/sing-box/nodes.json` (`_init_files()`'s nodes branch), so gate 2 refuses before
  BC-1's rule-set-directory check is reached. Both outcomes are non-zero and neither mutates; the
  BC-1 `UNMET` path stays reachable for the case the requirement describes literally (rule-sets
  present, no node store), which is AC-13's deliberate setup.
