# 01 — Rationale — restricted-network-regression-test (T-07)

> Rationale portion for 01_REQUIREMENT_ANALYSIS.md. Non-binding.

## 1. The goal sentence, clause by clause — all four need correction

> "Add a repeatable restricted-network regression test that blocks `github.com` /
> `raw.githubusercontent.com` in a container or VM, runs the full one-liner install, and asserts
> the five expected end-state conditions from the failure report."

### 1.1 "blocks `github.com` / `raw.githubusercontent.com`" — insufficient by two hosts

EVIDENCE. `bin/sc:113-118` ships four rule-set sources, in order:

```
https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
```

Only the fourth is `raw.githubusercontent.com`; `bin/sc:3258-3284` tries them in order and breaks
on the first that yields a validated body. Blocking the two named hosts therefore leaves bases 1,
2 and 3 answering, `sc update-rules` succeeds, `PHASE_RULESETS` is `ok`, and the whole degraded
end state never occurs — the test would assert a healthy install and prove nothing. T-21 measured
these bases at **24/24 HTTP 200** with byte-identical content and recorded that they span **three**
failure domains (`.harness/insight-index.md`, 2026-08-14: bases 1+2 are one Cloudflare edge, base 3
`ghfast.top`, base 4 Fastly). The blackout has to be the union of all of them, which is why FR-3
derives it from the shipped list rather than naming hosts.

### 1.2 "in a container or VM" — VM only, and not for the reason the environment survey gives

The environment survey rules out every container runtime here (docker needs sudo; podman /
nspawn / qemu / vagrant absent; LXD uninitialised and must not be triggered; `bwrap
--unshare-net` fails loopback with EPERM). But the stronger reason is in the scenario itself:
E1 and E5 both depend on `systemctl start sing-box` succeeding (`install.sh:593-595`), and
`systemd/sing-box.service:9` runs `sing-box run` against a config whose inbound is a TUN device.
That needs systemd as PID 1 and `/dev/net/tun`. A plain container satisfies neither, so
"container" would have to mean a privileged, systemd-in-container image — machinery this task
will not fund. Hence BC-5 and Q-5.

### 1.3 "runs the full one-liner install" — impossible under its own premise

EVIDENCE. The one-liner in `install.sh:5` is
`sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/…/install.sh)"` — it fetches the
script from the host the goal sentence blocks. Even granting a pre-staged script, the
remote-artifact branch at `install.sh:406-426` fetches five files from `$RAW_BASE` and does
`exit 1` on the first failure (`:420-424`), so under the blackout the installer never reaches
step 1. `RAW_BASE` is a plain assignment at `install.sh:13` with no `${…:-}` override, so a test
cannot redirect it without editing the file — which out-of-scope item 5 forbids.

What remains executable is the **local-checkout branch** (`install.sh:402-405`, taken when
`$SCRIPT_DIR/bin/sc` exists). That is the path the artifact drives, and the coverage limit is
stated rather than hidden: the remote-artifact fetch loop is not exercised by this test.

### 1.4 "the five expected end-state conditions from the failure report" — superseded

The 2026-07-31 post-mortem is **not in the repository**. `docs/spec/` holds only its own README;
no archived stage document quotes a section 四. The only recorded restatements are:

- `docs/features/_archived/install-enable-start-split/01_REQUIREMENT_ANALYSIS.md:285` (AC-9) —
  "on a host that cannot reach GitHub, the one-liner install leaves `systemctl is-enabled
  sing-box sing-box-rules-update.timer` reporting `enabled` for both units, **prints the failure
  banner, and exits non-zero**";
- `docs/batches/default/BATCH_PLAN.md:192-193` — "T-07 depends on T-01/T-02 because it asserts
  their combined end state".

Re-derived first-hand against `install.sh` and `bin/sc` at HEAD:

| AC-9 clause | still true? | why |
|---|---|---|
| both units `enabled` | **yes, unchanged** | `install.sh:581-586` registers both before config generation, each `\|\| true`. |
| prints the failure banner | **NO — refuted** | see below. |
| exits non-zero | **NO — refuted** | same cause. |

The refutation chain, all at HEAD:

1. `install.sh:567` runs `sc update-rules`; with every base dead, `cmd_update_rules`
   (`bin/sc:3281-3284`) prints one `failed: …` line per rule-set naming every base, writes the
   aggregate to stderr (`:3327`) and exits 1 (`:3329`). `PHASE_RULESETS` stays `failed` and
   `install.sh:570-573` prints the step-6 warning naming `/var/log/sing-box/install.log`. **This
   half of the report still holds.**
2. `install.sh:590` runs `sc reload`. T-02 made `generate_config()` degrade per file:
   `bin/sc:2058-2063` computes the defined tag set, deletes an empty `route.rule_set`, and runs
   `_filter_rules()` over **both** `dns.rules` and `route.rules`; `_warn_degraded()`
   (`bin/sc:1039-1043`) emits the "4/4 rule-sets unusable … degraded to no-splitting mode"
   warning; `sing-box check` then passes (T-02 proved all 16 usable/unusable subsets accepted by
   real sing-box 1.13.15). So `PHASE_CONFIG` becomes `ok`.
3. `install.sh:593-595` starts the service, `PHASE_SERVICE` becomes `started`.
4. `install_report()` (`install.sh:260-273`) takes its success arm on
   `PHASE_CONFIG=ok && PHASE_SERVICE=started`, prints `✅ Install complete` and returns 0;
   `install.sh:614-615` exits 0.

So the very AC this task exists to discharge is now **wrong in two of its three clauses**, and a
regression test written to it would fail on correct code. This is the sixth consecutive batch row
whose stated premise did not survive stage 1.

Also worth recording: the founding failure's own precondition ("sing-box 1.13.14 pre-installed")
is load-bearing. Without it, `install.sh:445-477` needs `api.github.com` and then
`github.com/…/releases/download/…`, and a GitHub blackout aborts the run at step 2 with
`t download_failed` + `exit 1` — the run never reaches steps 6-7 and none of E1 … E5 is
observable. Hence FR-2's precondition and BC-4.

### 1.5 What the current five (six) conditions are, and where each comes from

| id | condition | owner task | how it changed |
|---|---|---|---|
| E1 | success banner, exit 0 | T-01 + T-02 | **inverted** from AC-9 by T-02's degradation |
| E2 | both units enabled, timer started | T-01 (B-1/B-2, code-review SPEC-1) | unchanged |
| E3 | causes preserved in `install.log` at 0640 | T-01 (B-12 … B-15) + T-02 (BC-32) | unchanged; BC-32 was T-02's honestly-unverified item |
| E4 | degraded config at 0600, accepted by the checker | T-02 + T-13 (`_write_private`) | the document is degraded since T-02; 0600 at *every instant* since T-13 (write-then-`chmod` before it) |
| E5 | service active | T-01 | unchanged in intent; now reachable, which it was not before T-02 |
| E6 | recovery restores all four and restarts | T-02 (`gained` → regenerate) + T-10 (restart only on real change) | new; did not exist in the report |

E6 is added for one reason and it is not completeness: it is the cheapest possible non-vacuity
control (§3).

## 2. Related historical work

- `docs/features/_archived/install-enable-start-split/` (T-01) — AC-9's text, and four coverage
  limits its stages restated verbatim; `06_TEST_REPORT.md:324` states AC-9 unverified and deferred
  here.
- `docs/features/_archived/config-degrade-missing-rulesets/` (T-02) — the degradation that
  inverted E1, and `07_DELIVERY.md:81-88` listing the four honestly-unverified items.
- `docs/tasks-archive.md` § "Still-open rows rotated for space (NOT closed)" — the
  "Follow-up rows surfaced by T-02" block, the "Carried to T-07" block, the T-08 block (items 1-3)
  and T-11's R-1 … R-8, all read for this task.
- `docs/tasks.md` R-4 / R-9 (committed harness, `baseline.json`), R-31 / R-41 / R-47 / R-52 (the
  four prior BLOCKED-not-substituted precedents this task's AC-19 continues).
- `.harness/rejected-decisions.md` § `ruleset-unit-tests-in-t02` — four prior deferrals of a
  committed suite, and the unblock path this task deliberately does **not** take.

## 3. Non-vacuity: why the recovery arm is the control

T-08 caught six vacuous greens, one of which had already produced a false PASS, and its item 1
records that AC-3's non-vacuity rested on a server throttle with **no guard**. The generic fix —
a mutation harness, a fixture matrix, a negative-control runner — is exactly the machinery rule 85
forbids and exactly what this project has thrown away five times.

The smaller construction: run the same assertion set twice against states that must differ.
The blackout arm requires "no rule-set defined, no rule referencing one, causes in the log"; the
recovery arm requires "all four defined and referenced, service restarted". Each is the other's
counter-observation for the rule-set-dependent conditions, at the cost of one extra command
(`sc update-rules`) rather than a second framework. That is FR-10 and AC-12.

Two vacuity traps found while writing this, both now boundary conditions:

- **BC-1.** If the operator satisfies FR-2's "sing-box already installed" precondition by running
  a normal, open-network `install.sh` first, `/etc/sing-box/rules/` ends up **populated**. The
  blackout arm then fails its downloads but keeps four usable rule-sets, so E4 asserts against a
  healthy config and reports a false FAIL (not even a false PASS — worse, an unexplained one).
  The arm must assert its own starting emptiness.
- **BC-3.** If the blackout is implemented as `SB_RULES_BASE` (which `_ruleset_bases()`,
  `bin/sc:1052-1061`, honours and which **replaces** the built-in list), the injection is silent
  when it does not arrive. T-02's BC-25 is precisely this: sudo's `env_reset` strips it. Inside
  `install.sh` the variable does survive — the installer is already root, so `bin/sc`'s
  import-time elevate at `:124-125` is not taken and no `sudo` intervenes — but "does survive"
  must be *observed*, not reasoned, or the arm silently degrades to a normal install.

## 4. The two inherited T-08 defects — ruled on individually

Both were filed as defects "in the harness T-07 inherits". Neither file exists:

- `gate_checks.sh` / `server.py` / `control.json` / `faults.json` appear nowhere in the tree
  (the only `.sh`/`.py` under `test/` are T-01's `test/step7/` and T-20's `test/t20/`, and
  `.gitignore:19` ignores `test/` wholesale, so neither was ever committed).
- T-02's 846-assertion harness lived in `<scratchpad>/qa/` — 11 files, recommended for handover in
  `06_TEST_REPORT.md:362-379` but never pasted and never committed. The scratchpad is
  session-scoped and gone.

So "fix them" is unsatisfiable and "rebuild them" would author the sixth discarded harness for a
subject (in-process `bin/sc` download-path testing) that is **not** this row's — it is R-9's.
What survives is the two lessons, and both are now binding requirements rather than TODOs:

1. *One name for the fault state.* The write-vs-read filename mismatch is a second opinion about
   the same fact. FR-3 makes the shipped source list the single source of truth for what must be
   blocked, and BC-2/BC-13 make a mismatch abort instead of passing.
2. *Non-vacuity needs an explicit guard.* AC-5 requires the coverage check to be demonstrated
   **failing** against a doctored source list, which is the guard T-08 recorded as absent.

## 5. Where this can run, and what that costs

Nothing in E1 … E6 is observable in this pipeline's environment: the scenario needs root, systemd
as PID 1, `/dev/net/tun`, writes to `/usr/local/bin`, `/etc/sing-box`, `/var/log/sing-box` and a
started service — the exact mutations every row in this batch has been forbidden from making, on a
host running the owner's live VPN. No agent here holds an interactive sudo credential (R-31, R-41,
R-47, R-52 — four precedents, none substituted).

The honest split is therefore built into the AC table rather than discovered at stage 6. Five
criteria are dischargeable **here** by running the artifact's refusal and self-check paths
(AC-3 … AC-5, AC-20's partial) plus the structural set (AC-1, AC-2, AC-14 … AC-19); eight require
the VM. FR-14's self-check exists for exactly this reason: without it, **zero** lines of the
artifact would ever have been executed before the owner boots a VM, and "it parses" would be the
whole of the evidence. That is the one place this document deliberately buys a small amount of
code, and rule 85's burden of proof is met by naming what it buys.

## 6. Candidates considered and rejected

**Q-2 (what end state to assert).** Candidates: (a) assert AC-9 verbatim; (b) assert AC-9 but
treat the banner mismatch as a known-fail; (c) re-derive. (a) fails on correct code; (b) ships a
test with a permanent expected-failure, which is a green nobody reads. (c) selected.

**Q-3 (blackout scope).** Candidates: (a) the two named hosts; (b) a hardcoded list of the four
bases; (c) derive from the shipped list. (a) refuted in §1.1. (b) is the T-08 defect shape — a
second copy of a fact that lives in `bin/sc`, silently stale the day a base is added or changed
(R-53 already proposes changing base 2). (c) selected, with BC-2 as its guard.

**Q-4 (how to invoke the installer).** Candidates: (a) the true one-liner; (b) serve `RAW_BASE`
from a local HTTPS mirror inside the VM (`/etc/hosts` + a private CA); (c) local checkout. (b) is
the largest option by an order of magnitude — a CA, a TLS server, five staged artifacts — for the
sole gain of exercising a fetch loop whose failure path is a bare `exit 1`. (c) selected; the
coverage limit is stated.

**Q-6/Q-7 (harness inheritance).** Candidates: (a) rebuild T-02's harness from its report's prose;
(b) inherit nothing and rebuild small; (c) inherit nothing, and convert the two recorded defects
into requirements. (a) is a different subject and R-9's scope. (c) selected.

**Q-9 (`baseline.json`).** Candidates: (a) set `test_count` to the artifact's condition count;
(b) leave at 0. Nothing reads the file — `verify_all.{sh,ps1}` never mention it; only
`upgrade-project.*` and `migrate-scripts-layout.*` name it, and only as a file to relocate. A
non-zero count would therefore change no gate while asserting that N tests run, when in this
environment none does. (b) selected.

**Q-16 (cleanup).** Candidates: (a) uninstall between arms so the artifact is re-runnable;
(b) single-use VM. (a) makes the artifact a *destructive* tool by design — it would have to run
`uninstall.sh`, which removes `/etc/sing-box`, `/var/lib/sing-box`, `/var/log/sing-box`, the units
and the sudoers file — and every safety guard would then be the only thing standing between that
code path and a real host. (b) selected: the artifact contains no removal of anything.

**Report language.** Candidates: Chinese (human consumer) or English (tool consumer). `verify_all`
and `check-i18n-parity.sh` both print English, and this artifact's output is read alongside
theirs; the human-facing guide carries the Chinese. Split per `.harness/rules/00-core.md`'s
consumer rule.

## 7. Proposed `CONTEXT.md` glossary entries (not written — this task may edit only its two docs)

- **restricted-network scenario**: the fixed conditions of FR-2 — a disposable systemd host, root,
  `sing-box` present, no configured installation, every rule-set source unreachable, `install.sh`
  from a checkout. _Avoid_: offline install, no-network test, China test.
- **blackout arm / recovery arm**: the two halves of one regression run — the first with every
  rule-set source unreachable, the second with the blackout lifted. Each is the other's control.
  _Avoid_: negative test, happy path.
- **vacuous green**: an assertion that reports PASS without the observation it names ever having
  been able to fail. _Avoid_: false positive, flaky pass.

## 8. Residual risks this document does not close

- The artifact's correctness beyond its refusal and self-check paths is unobserved until a VM
  exists. AC-19 forces that to be reported, not papered over.
- E5 is the weakest condition: a service that starts and then exits within the settle window would
  read as active. Narrowing it (a second read, or a `MainPID` comparison) is a stage-2 call; the
  requirement as written asks for the state after a bounded window and for the observation to be
  printed alongside the verdict.
- If the owner's VM sits behind the same restricted network as the failure report's hosts, the
  recovery arm may be unable to fetch. BC-9 makes that `BLOCKED` and marks every non-vacuity claim
  that depended on it unproven — it must not read as PASS.
