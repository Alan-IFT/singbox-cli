# AI-native init/adopt — canonical drafting prompt

> Shipped as a reference. The `/harness-init` skill's step 5b and `/harness-adopt`'s
> step 4b quote from this file when asking the orchestrator model to draft
> `.harness/rules/50-<project-slug>.md` and optional partition agents.
> The leading `_` keeps this file out of the lexical `00-…99-` rule namespace; it is
> documentation, not a runtime rule fragment.
>
> Tag this file with `_` prefix (not numeric) so AI-GUIDE.md's "when to read" index
> ignores it and `verify_all` E.4b does not require it to be indexed.

## Inputs the skill provides

```
PROJECT_NAME: <slug — sanitized basename of cwd; matches /^[a-z0-9][a-z0-9-]{0,40}$/>
PROJECT_TYPE: <fullstack | backend | generic>
STACK:        <user's Q2 free-text stack description>
TOP_LEVEL:    <up to 100 newline-separated names from Glob(*) in the target dir>
MANIFESTS:    <name + first 50 KB body of each readable manifest, separated by --- markers;
               candidate manifests: package.json, pyproject.toml, requirements.txt,
               go.mod, Cargo.toml, pom.xml, README.md>
RESERVED_NAMES: pm-orchestrator, requirement-analyst, solution-architect, gate-reviewer,
                developer, code-reviewer, qa-tester
```

## Output contract

Return **a single JSON object** with this shape (no surrounding prose, no Markdown
fence, just the JSON):

```json
{
  "rule_md": "<markdown body of .harness/rules/50-<PROJECT_NAME>.md>",
  "partition_agents": [
    { "name": "dev-<slug>", "body": "<full .harness/agents/dev-<slug>.md body>" }
  ]
}
```

`partition_agents` MAY be `[]` for small/single-developer projects. That is the
expected outcome for `PROJECT_TYPE=generic` with a flat top-level.

## Four invariants the `rule_md` body MUST satisfy

If you cannot satisfy all four, the skill drops your output and falls back to the
static `50-<PROJECT_TYPE>.md` stub. Do not try to be clever; the safe default beats
a malformed customization.

1. **Required section headings, in order, all present** (verify_all D.3 checks this
   per-section):
   - `## When to read`
   - `## Build / test / verify`
   - `## Project structure`
   - `## Stack-specific conventions`
   - `## Partitioning`
   - `## Stack-specific verify_all checks`
2. **Zero `{{...}}` literals**. The skill runs AFTER placeholder substitution.
   Anything that looks like `{` `{PROJECT_NAME}` `}` (double-brace placeholder) in your output is a leaked
   placeholder and will trigger D.2 FAIL on the user's first verify_all run.
   Write the substituted value directly (e.g. the actual project slug).
3. **Line count ≤200**. The doc-size rule (`.harness/rules/70-doc-size.md`) caps
   rule fragments at 200 lines. Exceeding this triggers `verify_all` I.2 WARN.
4. **No partition-agent name in `RESERVED_NAMES`**. The seven pipeline-agent
   names are reserved. If you propose `dev-developer` or `dev-pm`, the skill
   silently drops that partition. Use stack-specific names instead:
   `dev-payments`, `dev-ingest`, `dev-mobile-ios`, `dev-realtime`, …

## Source citation rule (every non-template section MUST have ≥1 annotation)

Every `## ` or `### ` section whose body is NOT just the placeholder skeleton
MUST contain at least one `<!-- source: <tag> -->` HTML comment. Allowed `<tag>`
values:

- `user-q2` — claim derived from the user's free-text stack string
- `top-level-glob` — claim derived from the enumerated top-level filenames
- `package.json`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `go.mod`,
  `pom.xml`, `README.md` — claim derived from the named manifest's contents

Any other tag = AI invention = D.3 FAIL. If a section's claim has no source,
either omit the section's bullets and use a placeholder (`<your build command>`),
or pick the tag that most honestly explains where the bullet came from.

## The "don't guess" rule (NFR-Safety-2)

Hallucinated build commands are the #1 risk this prompt exists to mitigate.

**If you do not know a value** — for example, the project has no manifest and the
user's Q2 said only "Rust CLI tool" — write the **placeholder** that the static
stub would have used, NOT a guess. Examples:

- Don't write `cargo make build` because Rust projects "usually" use cargo-make.
  Write `<your build command>` and a `<!-- source: user-q2 -->` annotation.
- Don't write `pnpm test` because the lockfile name hints at pnpm. Write
  `<your test command>` unless `package.json` explicitly has `"packageManager":
  "pnpm@..."`.
- Don't propose a `dev-realtime` partition because "real-time apps usually need
  one". Only propose a partition when `TOP_LEVEL` shows a directory whose name
  matches that scope (e.g. `apps/realtime/`).

The user can always edit the file after init. A correct-but-empty section is
strictly better than a wrong-but-confident section.

## Body skeleton (use this as the structural template)

```markdown
# 50 — Project-specific rules (<PROJECT_NAME>)

> Generated <TODAY> by AI customization step. Provenance via `<!-- source: ... -->` comments.

## When to read

<!-- source: user-q2 -->
- When touching code in this project.
- <one bullet per claim you derive from the inputs>

## Build / test / verify

<!-- source: <package.json | Cargo.toml | pyproject.toml | user-q2> -->
- Build:   `<command or placeholder>`
- Test:    `<command or placeholder>`
- Lint / typecheck: `<command or placeholder>`

## Project structure

<!-- source: top-level-glob -->
- `<top-level dir>/` — <role>
- ...

## Stack-specific conventions

<!-- source: user-q2 -->
- <convention 1>
- ...

## Partitioning

<!-- source: top-level-glob -->
- <"Single developer" OR list of dev-<slug> partitions matching top-level dirs>

## Stack-specific verify_all checks

<!-- source: <package.json | user-q2> -->
- (optional bullets — leave empty for greenfield projects)
```

## Partition-agent body shape (when proposing one)

```markdown
---
name: dev-<slug>
description: Partition developer for the <slug> area of <PROJECT_NAME>. Owns
  paths under <owned-path-glob>. Reports to PM Orchestrator.
tools: Read, Write, Edit, Glob, Grep, Bash, PowerShell, TodoWrite
---

# dev-<slug>

Owned paths: `<glob>`

## When to dispatch
- Tasks touching files under the owned-path glob above.

## Boundaries
- Never edit files outside owned paths without an Architect-issued cross-partition
  dispatch. Surface those cases back to PM Orchestrator.
```

## Failure modes the skill detects (don't trigger these)

| Detector | Trigger | Outcome |
|---|---|---|
| JSON parse | Output is not valid JSON | Fall back to static stub |
| Heading regex | Any of the six `## ` headings missing or out of order | Fall back |
| Placeholder regex `\{\{[A-Z_]+\}\}` | Any `{{...}}` literal in `rule_md` | Fall back |
| Reserved-name set | Any `partition_agents[i].name` in `RESERVED_NAMES` | Silently drop that partition; others continue |
| Line count >200 | `rule_md` exceeds 200 lines | Write the file; emit a one-time WARN telling the user verify_all I.2 will WARN |
| Re-Read byte mismatch | After Write, `Get-Content -Raw` differs from string written | Retry once; on second mismatch, fall back |
| Slug regex fail | `PROJECT_NAME` does not match `^[a-z0-9][a-z0-9-]{0,40}$` | Skill sanitizes (lowercase, replace non-matching with `-`, trim to 40, strip leading digit-only); if still empty, fall back |
