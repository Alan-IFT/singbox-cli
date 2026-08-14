# 85 — Design discipline (no successive patching)

> Standing directive from the project owner, 2026-07-31: 「优先用好的设计，避免不断的修修补补」
> — prefer a coherent design; avoid a stream of patches.
>
> **Restated a third time 2026-08-14, with an added clause: 「以少就是多（更少的代码或实现能达到
> 同样的目的）为原则进行决策」** — less is more: between two designs that achieve the same stated
> purpose, the one with less code and less machinery wins. Promoted from a per-task intervention
> into this rule because the owner has now stated it three times.

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

## Less is more — the tie-break, and the burden of proof

Between two designs that satisfy the same stated requirement, **take the smaller one**: fewer
lines, fewer files, fewer new concepts, fewer moving parts to keep correct later. This is a
tie-break with teeth — it does not merely settle ties, it puts the **burden of proof on the larger
design**. Stage 2 must state the smaller alternative it rejected and what the extra code buys;
stage 3 must test that answer rather than accept it.

Apply it concretely:

- Prefer **data over machinery**. A list, a dict entry, or a table row that an existing mechanism
  already consumes beats a new function; a new function beats a new module.
- Prefer **reusing an existing seam** over adding a parallel one. If a judgment already has one
  home, call it — a second opinion of the same fact is the defect, not the feature.
- Prefer **deleting** to adding. A change that removes a special case while satisfying the
  requirement is strictly better than one that adds a guard for it.
- **Not every stated symptom needs its own code.** Two symptoms with one cause get one fix.
- Count the cost honestly: a design's size is its diff **plus** what every future reader and every
  future task must now hold in their head.

The two rules compose and do not conflict: 「避免修修补补」 forbids accumulating band-aids,
「少就是多」 forbids paying for coherence with bulk. A design that needs a lot of code to be
coherent is usually still the wrong abstraction — look again.

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
