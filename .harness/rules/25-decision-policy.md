# 25 — Decision & escalation policy

## What this is

Controls HOW a decision point is resolved when an AI agent working on this project hits a
choice it would otherwise put to you. A rubric (`.harness/decision-rubric.md`) supplies the
principles the AI decides by; a fixed set of **red lines** always escalates regardless of mode.
This lets you preset your judgment once and **review autonomous calls after the fact** instead of
approving each one up front — "review-after" replacing "decide-before".

Switch modes with **`/harness-decision-mode`** (the interactive switcher) or by editing the
"Active mode" line below.

## When to read this

- **Whenever an agent is about to ask the user / call `AskUserQuestion` / "stop and ask"** —
  load this and `decision-rubric.md` and consult them BEFORE escalating. They do NOT need
  loading every task: the AI-GUIDE index line signals at task start which mode this project runs
  and where the rubric lives, so the full text loads only when a real decision arises.

## Active mode

**Active mode: 1 (human decides — the safe default).**
New projects start here: the AI escalates every judgment call it cannot resolve from an
unambiguous default. Opt into Mode 2 (preset-rubric autonomy) or Mode 3 (your custom rubric)
when you want the AI to decide more on its own — switch with `/harness-decision-mode` (or edit
this line by hand).

## The three modes

- **Mode 1 — human decides (the safe default).** Any point the AI cannot resolve from the
  request, the code, or an unambiguous default goes to the user. (RA "lists every ambiguity";
  agents stop at judgment calls.)
- **Mode 2 — preset-rubric autonomy.** The AI resolves any decision the **Preset rubric**
  (`.harness/decision-rubric.md` → `## Preset rubric (Mode 2)`) clearly covers — **including
  reversible design / implementation trade-offs** — decides, records it, and proceeds. It
  escalates only (a) the red lines below, and (b) decisions the rubric does not cover or that
  carry a major / irreversible trade-off. **Rubric coverage is the control knob:** a richer
  rubric delegates more; a sparse one degrades gracefully toward Mode 1.
- **Mode 3 — user-custom-rubric autonomy.** Identical mechanism to Mode 2, but the AI decides by
  your OWN **Custom rubric** (`.harness/decision-rubric.md` → `## Custom rubric (Mode 3)`) instead
  of the Preset. The three prime principles remain the floor; the red lines and the audit trail
  below apply unchanged. An empty Custom rubric degrades toward Mode 1.

## Red lines — ALWAYS escalate (all three modes; no rubric can override these)

1. **Irreversible / destructive** — deleting or overwriting something not created in this
   task, history rewrite, force-push, dropping or migrating data.
2. **Outward-facing / publishing** — pushing to a shared branch, opening/merging a PR,
   sending a message or email, cutting a release, anything a third party will see.
3. **Scope expansion** beyond what the user asked — new features / tasks the user did not
   request are never invented autonomously.
4. **Conflict with an explicit user constraint** — a CLAUDE.md red line, a stated "don't…",
   or the project's own governance rules.
5. **Security-sensitive** choices (auth, secrets, permissions, crypto, security-surface deps)
   and **cost / quota commitments** (paid services, large compute).
6. A choice the AI assessed and is **genuinely uncertain** about with material downside.

## How an agent applies it (Mode 2 / Mode 3)

At a would-be escalation point:
1. **Red line?** → escalate. Stop.
2. **Does the active rubric clearly cover it?** → decide accordingly, **log the decision**
   (point · options · choice · rubric basis), proceed. Under Mode 2 the active rubric is the
   **Preset** section; under Mode 3 it is the **Custom** section — same rule, different section.
3. **Otherwise** (uncovered, or major / irreversible trade-off) → escalate, and name the
   rubric line that WOULD have let you decide it (so the user can extend the rubric).

## Audit trail (what makes "review-after" safe)

Every autonomous Mode-2 / Mode-3 decision is recorded so the user can spot-check rather than
pre-approve:
- **Pipeline tasks** → one line in the task's `PM_LOG.md`.
- **Direct work** → a short "decisions made" list in the AI's response.

A decision the user later reverses becomes a new rubric line (or a red-line tweak) — the
policy learns.

## Changing the policy

- **Switch the active mode** → run `/harness-decision-mode` (interactive), or edit the
  "Active mode" line above by hand.
- **Tune what's autonomous** → edit `.harness/decision-rubric.md` (no code change — agents read
  it at decision time). Mode 2 reads the **Preset** section; Mode 3 reads the **Custom** section.
  Widen to delegate more; trim to delegate less.
- The **red lines** are deliberately NOT in the rubric — they are a fixed safety floor that
  applies in all three modes.
