# 80 — Delivery policy (auto-commit + push)

> Standing instruction from the project owner, 2026-07-31: "以后都由你来自动提交和推送；我只管提需求."
> Branch target confirmed by the owner the same day: **push directly to `main`**.

## When to read

Read at **delivery time** — after a task reaches `DELIVERED` and `verify_all` is green — and
whenever you are about to run `git commit` or `git push` in this repo.

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

## Reporting

Each commit is reported to the owner as one line — subject, short SHA, files-changed count,
push result — inside the normal stream report. The owner reads results, not diffs, so a
failed or skipped push must be stated explicitly rather than silently retried.
