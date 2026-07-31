# 85 — Design discipline (no successive patching)

> Standing directive from the project owner, 2026-07-31: 「优先用好的设计，避免不断的修修补补」
> — prefer a coherent design; avoid a stream of patches.

## When to read

Read at **stage 2 (Solution Architect)** and at **stage 3 (Gate Reviewer)** for every task, and
whenever you are about to split one requirement into several rows or accept a fix that only
holds until the next related change.

## The directive

A requirement often arrives as a **list of symptoms** — a bug report, a review, a failure
post-mortem. Implementing that list item-by-item produces code shaped like the report instead of
code shaped like the problem. Find the missing abstraction behind the symptoms and build that.

Concretely, before accepting a decomposition, apply these tests:

1. **Patch-then-patch seam.** Does task A compute something that only task B consumes? Does A ship
   an intermediate state that is incoherent or dishonest on its own? Then A and B are one task.
   *Precedent: T-01 set `INSTALL_OK` while the closing banner still printed ✅ unconditionally —
   half the design would have shipped an installer that detects its own failure and lies anyway.*
2. **Duplicated judgment.** Do two tasks each need to decide the same thing (is this resource
   usable? did this phase succeed?)? Then that judgment belongs in one place both call.
   *Precedent: T-02 needed "is this ruleset usable?" and T-03 defined what a valid `.srs` is —
   split, T-02 ships `path.exists()` and an HTML error page reads as "present".*
3. **Shape check.** If the module layout mirrors the bug report's section numbers rather than the
   domain, re-derive it from the domain.

## The counter-rule — this is not a license to over-build

"Good design" here means **coherent and honest**, not elaborate. The directive forbids
accumulating band-aids; it does not authorize:

- new files, modules, or config formats when a well-named function and two variables suffice;
- speculative generality for requirements nobody stated;
- widening a task's scope beyond the user's requirement (see `.harness/rules/00-core.md`) —
  consolidation re-homes scope between tasks, it never invents new scope.

A refactor is justified when it removes a seam that would otherwise force a second edit to the
same code. If you cannot name the future edit it prevents, it is not justified.

When the owner's suggested shape is already the right granularity, keep it and say why in
`02_SOLUTION_DESIGN.md`. Agreeing with the user is a valid design conclusion; restating their
patch list without having looked for the seam is not.

## Recording the call

Any consolidation or split decision goes in `02_SOLUTION_DESIGN.md` with the seam it removes, and
in the pool's `## Notes` when it changes the task table. Never silently drop a requested outcome —
re-home it and say where it went.
