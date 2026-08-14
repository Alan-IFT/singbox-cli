# 01 — Requirement Analysis (explore mode) — T-21 ruleset-source-strategy-from-v2rayn

> Contract portion. Rationale: 01_RATIONALE.md (absent = none written).

Mode is `explore`. This document poses a question; it does not specify a feature. The deliverable
of the task is a decision-grade `findings.md`, not code.

## Question

Measured against v2rayN — which this project is the headless equivalent of (`CONTEXT.md` §Project
intent) — does singbox-cli's rule-set **source strategy** change, given that it already ships
ordered multi-base fallback, SRS-magic + size validation, atomic replace and per-run dead-base
marking (delivered by T-02)? Three sub-questions each end in their own verdict: (Q1) GitHub
Releases assets as an additional base, (Q2) a mirror repository this project controls, (Q3)
user-selectable rule **source sets** rather than only base ordering. A fourth point rides along
and must be settled by measurement: whether rule-set downloads travel through the local proxy or
direct.

## Success criteria

The exploration has an answer when all of the following hold of `findings.md`:

**SC-1** — Q1, Q2 and Q3 each carry one explicit verdict: `adopt` / `decline` /
`defer-with-trigger`. A `defer` names the observable condition that reopens it. A survey that
describes options without choosing among them fails this task.

**SC-2** — Each verdict names the first-hand evidence it rests on and states its **ongoing
maintenance cost** as recurring work with an owner (for example: a mirror somebody keeps in sync
forever; a naming-compatibility surface across source sets that name their files differently).
Cost counts as size under `.harness/rules/85-design-discipline.md` §"Less is more"; each `adopt`
verdict names the smaller alternative it beat and what the extra machinery buys.

**SC-3** — "Do nothing — the current base list and fallback order are better than the proposal" is
an admissible verdict for any of the three, and reaching it on all three is a complete, successful
outcome.

**SC-4** — Every premise inside the three questions is verified first-hand before anything is
reasoned from it, including whether GitHub Releases assets exist **for the rule-set sources this
project actually consumes** (a claim about a third party's repository, not about this repo), under
what asset names, and whether they carry `.srs` at all. A premise that fails verification is
recorded as refuted, with the observation that refuted it, and the question resting on it is
re-posed or closed. Five consecutive tasks in this batch found their own goal sentence partly
false against current code; a premise repeated from `BATCH_PLAN.md` §Notes "v2rayN研究 2026-08-01"
is not thereby verified.

**SC-5** — The proxy-vs-direct point is settled by measurement taken on this host, both arms
measured under the same conditions, with the failure behaviour of each arm recorded alongside its
success timing. Timing claims state **total wall clock per attempt**: per the insight index
(2026-08-14), `urlopen(timeout=N)` bounds each socket operation and never the call's wall clock,
so "it gives up after N seconds" is not admissible evidence unless observed.

**SC-6** — Every measurement is read-only with respect to the live system: nothing under
`/etc/sing-box/`, nothing under `/var/lib/sing-box`, no service action. Per the insight index
(2026-08-01), a redirected-paths harness is **not** sufficient on its own — `_init_files()`
hard-codes the rule-set state directory as a literal, so a probe that drives a non-doctor command
writes to the real path regardless of repointing. A probe either exercises the fetch path without
driving such a command, or runs entirely outside `bin/sc`.

**SC-7** — Any code change implied by a verdict is filed as a new task row in
`docs/batches/default/BATCH_PLAN.md`, never built inside this task.

## Candidates to investigate

**C-1 — GitHub Releases assets as an additional base.** Premises to verify first: that a Releases
asset path serving this project's rule-set files exists upstream; that its CDN differs in reach
from `raw.githubusercontent.com` from a restricted network; that a `latest` asset is versioned in
a way the existing validation still accepts.

**C-2 — A mirror repository this project controls.** Premises to verify first: what keeps such a
mirror current, who runs it, and what a stale or unattended mirror does to a user compared with a
third-party path that fails loudly.

**C-3 — Selectable rule source sets (a rule-source profile).** Premises to verify first: whether
the candidate source sets publish the same rule-set names this project references by tag; what a
mismatch does to config generation's degrade path; how a profile composes with the existing
config-composition layer and its user override rather than duplicating it.

**C-4 — Download egress: proxy vs direct.** Premises to verify first: what the current fetch path
does today with respect to proxy environment and the tunnel; and whether "direct" is even
available on a pure-TUN host, where the tunnel already captures egress. v2rayN downloading through
its own local socks5 proxy is evidence about v2rayN, not about this host.

**C-5 — The null candidate: keep the current base list and order unchanged.** Carried as a real
candidate against C-1..C-4, not as the residue of rejecting them.

## Out of scope

1. Shipping any code, unit file, or configuration change from this task.
2. Redesigning the download, validation, atomic-replace or dead-base-marking behaviour T-02 shipped.
3. Any write to `/etc/sing-box/`, `/var/lib/sing-box`, or the running service.
4. Copying v2rayN's download implementation, which is thinner than this project's (`CONTEXT.md` §Project intent).

## Verdict

READY
