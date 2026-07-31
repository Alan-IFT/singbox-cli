# 75 — Destructive-command safety hook

## What this is

A `PreToolUse` hook in `.claude/settings.json` that runs
`.harness/scripts/guard-rm.{ps1,sh}` before every Claude Code Bash tool call. The guard
blocks the call when any destructive verb targets a path that resolves outside
the nearest `.git/` ancestor of the current working directory.

The hook is auto-installed by `/harness-init` and `/harness-adopt` (with a
merge prompt). It is **always on** by default; the documented disable path is
one line (see below).

## When to read this

- When running, observing, or disabling the destructive-command guardrail.
- When a tool call was unexpectedly BLOCKED and you need to understand why.
- Before editing the `PreToolUse` block in `.claude/settings.json`.

## Trigger verbs

| Family | Verbs (first token after optional `sudo`) |
|---|---|
| POSIX `rm` family | `rm`, `rmdir`, `unlink`, `shred`, `srm` |
| Windows / pwsh | `Remove-Item`, `del`, `erase`, `Clear-RecycleBin` |
| `find` deletion | `find … -delete` (`-delete` anywhere among the args) |
| Nested pwsh | `pwsh -c "<cmd>"`, `pwsh -Command "<cmd>"`, `powershell -c …` — the quoted command is re-tokenized and the same rules apply (max recursion depth 2; deeper nesting → BLOCK with parse-failure message) |

Everything else (`mv`, `cp`, `>` redirection, `git`, build tools, …) is **not**
guarded by this hook. It only catches destructive verbs.

## Path resolution rules

- **Absolute paths**: used as-is.
- **Relative paths**: joined to the Bash tool's cwd, then `..` / `.` collapsed.
- **Tilde** (`~`, `~/foo`): expanded to `$HOME` / `$env:USERPROFILE`.
- **Symlinks**: leaf-only — the link path as written is checked; the link
  target is NOT followed. This matches the user mental model (you wrote a path
  inside the repo, you meant to delete that path) and avoids surprising blocks
  on legitimate symlink grooming.
- **Globs** (`/tmp/*.log`): literal — the guard does not expand them. The
  literal prefix is what gets checked, so `/tmp/*.log` resolves under `/tmp/`
  and is outside-root.
- `$repoRoot` is the **nearest** `.git/` ancestor of `cwd` (walked manually —
  the guard never spawns `git` itself, to stay under the 50 ms wall-clock
  budget). If no `.git/` ancestor exists, the guard exits 0 with a stderr
  WARN line and the tool call proceeds — "refuse to protect loudly" beats
  false-blocking CI scratch shells.

## Override (per-call escape hatch)

Set the environment variable `HARNESS_ALLOW_OUTSIDE_RM=1` for a single call.

Bash:

```
HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf /tmp/some-thing
```

PowerShell:

```
$env:HARNESS_ALLOW_OUTSIDE_RM=1; Remove-Item -Recurse C:\some\external\path
```

When the override is active, the guard emits a single stderr INFO line
(`override active …`) and exits 0 without parsing. Claude Code records the
INFO line in the tool transcript so the override is auditable.

The override is intentionally **per-call and visible**. It cannot be persisted
in any committed file — `.claude/settings.json` does not accept it, and the
verify_all release check would catch any tracked file that hard-codes it.

## Fully disable

Edit `.claude/settings.json` and remove the `hooks.PreToolUse` array (or just
the matcher==="Bash" entry pointing at `guard-rm`). To re-enable, re-run
`/harness-adopt` (it merges the PreToolUse block back in) or copy from
`skills/harness-init/templates/common/.claude/settings.json.tmpl`.

## Failure modes

| Failure | What happens | Fix |
|---|---|---|
| Guard script missing on disk | PreToolUse hook itself fails → Claude Code blocks the call with the hook error in the transcript | Reinstall: `/harness-adopt`, or copy `.harness/scripts/guard-rm.{ps1,sh}` from the harness-kit templates |
| Parse failure on nested pwsh / unbalanced quotes | BLOCK with explicit "could not parse …" message | Re-issue without the nested quoting, or use override if you know the command is safe |
| `.git/` not found anywhere up the cwd chain | WARN to stderr, exit 0 (tool call proceeds) | Make sure you're in a real project, or initialize git |
| Performance over 50 ms | Not a failure, but log it | The guard is straight-line code and avoids spawning subprocesses; if you see slow blocks, file an issue with timings |

## Boundaries

- **In-project deletions are allowed.** `rm -rf node_modules`, `rm -rf .next/`,
  `rm -rf build/` from inside the repo are fine — by design. The guard's scope
  is "rm OUTSIDE the project root".
- **Out of scope (v0.15)**: `mv` / `cp` / redirect-overwrite (`> file`) —
  common-legit and not addressed here. Re-evaluate only if an incident occurs.
- **Out of scope**: tool calls issued by Write/Edit, Cursor, Copilot, or any
  AI tool other than Claude Code. PreToolUse only governs Claude Code's tool
  calls. For other tools the policy is documented best-practice; the
  `Bash(rm -rf /:*)` deny line in `.claude/settings.json` and the git
  pre-commit hook provide a partial backstop.
- **Subdirectory of another git repo**: `$repoRoot` is the **nearest** `.git/`
  ancestor. If you run inside a nested clone, the guard scopes to the inner
  repo, not the outer monorepo. Move out, or set the override for that session.
