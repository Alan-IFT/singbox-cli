# 80 — Delivery policy (auto-commit + push)

> Standing instruction from the project owner, 2026-07-31: "以后都由你来自动提交和推送；我只管提需求."
> Branch target confirmed by the owner the same day: **push directly to `main`**.

## When to read

Read at **delivery time** — after a task reaches `DELIVERED` and `verify_all` is green — and
whenever you are about to run `git commit` or `git push` in this repo.

Read also **when writing an acceptance criterion over the committed diff** (stages 1-2) — for the
process-path list below — and **after `/harness-upgrade`**, for the vendored-script fixes below.

## The policy

The owner has **durably authorized** automatic commit and push. Do not ask for per-task
confirmation; asking again is the defect, not the safeguard.

After each task reaches `DELIVERED` **and** `.harness/scripts/verify_all.sh` returns no FAIL:

1. `git add` only the files that task actually changed — never `git add -A` blindly.
2. Commit to `main` with a Conventional Commits subject in **English** (matching this repo's
   existing history: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
3. `git push origin main`.

`origin` is the **public** repo `github.com/Alan-IFT/singbox-cli`. Every push is immediately
world-visible. That is the owner's accepted trade-off, not a reason to re-confirm.

## Process paths — what the pipeline writes about its own work

Every delivery commit carries some of these. They are **not** product files (`docs/dev-map.md` is:
it documents the code):

- `docs/tasks.md`, `docs/tasks-archive.md` — the task board and its archive
- `docs/features/<slug>/**`, `docs/features/_archived/**` — stage documents, `PM_LOG.md`, insight history
- `docs/batches/**` — the batch loop's plan, log and report
- `.harness/insight-index.md`
- `.harness/rejected-decisions.md`, `.harness/operator-obligations.md`, `CONTEXT.md`

**A criterion over the committed diff enumerates its own product files, cites this list for the
rest, and never re-transcribes it; a path in neither list is a failure of that criterion.**

## Preconditions — all must hold before committing

Skip the commit (and say so in the report) if any fails:

- `verify_all` returns **no FAIL** for the current tree.
- The change is confined to what the task's own `07_DELIVERY.md` claims it touched.
- No secret, credential, private key, or real node share-link (`vless://`, `vmess://`,
  `trojan://`, `ss://`, `hysteria2://`, `tuic://` containing a real host/UUID) is in the diff.
  This repo manages proxy credentials at runtime — a leaked test node is a live disclosure.
- No file under `/etc/sing-box/` or any other absolute system path was captured into the repo.

## Never automatic — always ask first

The blanket authorization covers ordinary commit + push. It does **not** cover:

- `git push --force` / `--force-with-lease`, or any history rewrite on `main`.
- Deleting or renaming remote branches, or pushing tags/releases.
- Any commit whose diff trips a precondition above.
- Reverting or reconciling someone else's commit that appeared on `origin/main`.

If `origin/main` has moved ahead, **rebase or merge and re-run `verify_all`** before pushing;
never force.

## Local fixes to plugin-vendored scripts

`/harness-upgrade` **replaces** each script its `refresh_set` names — `archive-task`, `guard-rm`,
`harness-sync`, `install-hooks`, `migrate-scripts-layout`, the ambient hook pair, in both shells
(the `refresh_set` array in `.harness/scripts/upgrade-project.sh`, and the loop over it that follows)
— with the plugin's current template when the two differ, with no marker preservation and no backup.
`verify_all.{sh,ps1}` is **not** in that set: the `known` array carries the hand-maintained invariant
comment stating the difference, and the verify pass instead splices (`VERIFY-SPLICE`), HALTs on
unmarked custom `B.*` checks (`VERIFY-HALT`) and copies to `"$proj_file.bak-$stamp"` first. Each of
those five names is a token that greps in the arriving text, so a refresh that keeps a mechanism
keeps its anchor and one that removes it makes the grep fail loudly instead of pointing at the wrong
lines. So a note *inside* a `refresh_set` file dies with the fix it describes, and what
arrives is a text of the plugin's choosing, not a revert of the local hunks. **Keep what arrives.**
For each fix below, run its check against the arriving text and take the action for the verdict it
gives, naming the version measured: a verdict is a property of that text, not a standing fact. A check
whose command exits non-zero **did not complete** and yields no verdict — a run that wrote nothing is
never *already provided*. `git log -p -- <path>` holds the pre-replacement text when an action needs it.

| `.harness/scripts/archive-task.sh` fix | observable it restores · how its loss shows | check to run against the arriving text | *already provided* | *lost* |
|---|---|---|---|---|
| rotation decided on the index's **line** count | an archive run leaves `verify_all` F.4 PASS with no hand edit · **loud**: the index passes 30 lines and F.4 WARNs after every archive run | archive a fixture whose index is at the cap with ≥1 harvested insight, then `wc -l` the resulting index | ≤30 → change nothing | >30 → make the rotation decision read `wc -l` of the index — F.4's own measurement, `verify_all.sh:213-219` — instead of whatever it counts, and rotate until the file it writes is ≤30 lines |
| the harvest carries a wrapped bullet whole | a `## Insight` bullet wrapped over several lines reaches the index with its continuation text and its trailing `· evidence: <slug>` tag · **silent**: entries truncate mid-sentence and lose the tag | archive a fixture whose `## Insight` bullet wraps over three lines with the tag on the last, then read what it wrote | continuation text and tag both present → change nothing | truncated or tag missing → restore the join inside the arriving text's own harvest step |

## Reporting

Each commit is reported to the owner as one line — subject, short SHA, files-changed count,
push result — inside the normal stream report. The owner reads results, not diffs, so a
failed or skipped push must be stated explicitly rather than silently retried.
