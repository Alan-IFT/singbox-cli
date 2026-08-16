# 50 — Project-specific rules (singbox-cli)

> Generated 2026-07-31 by the AI customization step. Every non-skeleton claim carries an
> HTML source comment naming where it came from. Correct anything that drifts.

## When to read

<!-- source: user-q2 -->
<!-- source: top-level-glob -->

- When touching any code in this repo: the `sc` CLI (`bin/sc`), the installer
  (`install.sh`), the uninstaller (`uninstall.sh`), or the service units (`systemd/`).
- Skip for typo fixes, comment cleanup, or edits confined to `docs/`.
- Read together with `.harness/rules/75-safety-hook.md` — this project's code writes to
  system paths (`/etc`, `/usr/local/bin`, `/etc/sudoers.d`) and runs as root.

## Build / test / verify

<!-- source: top-level-glob -->
<!-- source: README.md -->

There is **no compile step and no dependency manifest** — the top level carries no
`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, or `go.mod`, and the
committed tests live in `.harness/scripts/`. `bin/sc` is a single Python 3 file run
directly; `install.sh` and `uninstall.sh` are Bash scripts run with `sudo bash`.

- Build: **none** — nothing is compiled. `install.sh` copies `bin/sc` to `/usr/local/bin/`
  and downloads the sing-box binary from GitHub Releases.
- Test: `python3 .harness/scripts/check-sc-contracts.py` — the committed contract assertions over
  `bin/sc`, wired as `verify_all` B.4 against `.harness/scripts/baseline.json`'s floor.
- Lint / typecheck: `<your linter>` — no lint config is committed. If you add one, wire it
  into `verify_all` section B at the same time.

`.harness/scripts/verify_all.sh` **B.1 is a real gate**, not a SKIP: it runs
`python3 -m py_compile bin/sc` plus `bash -n` on `install.sh` and `uninstall.sh`, and it
fails the run on a parse error. **B.2 is a real gate too since T-11**: it runs
`.harness/scripts/check-i18n-parity.sh install.sh`, which renders every `t()` key in both
languages and fails the run on a key-set or `printf`-specifier mismatch. **B.4 and B.5 are
real gates since T-28**: B.4 runs `check-sc-contracts.py` and fails below `baseline.json`'s
`test_count`; B.5 runs `restricted-network-regression.sh --self-check`. **B.3 (lint) is
still SKIP** — the first task that adds a lint config must replace that SKIP, because a
permanently SKIPping check proves nothing.

Do not repeat the claim that "all B.* checks are SKIP" — it was true only before B.1 was
wired, and it has already propagated into task documents once.

Minimum manual verification for any change, until B.3 is real (it is the run's one SKIP):

<!-- source: README.md -->

- The B.1 syntax gate is the floor, not the ceiling — it proves the files parse, nothing
  about behaviour.
- `install.sh` must stay **idempotent**: re-running it overwrites `sc` and the service
  units but must leave `/etc/sing-box/nodes.json` and `/etc/sing-box/settings.json`
  untouched. Any change to the installer must preserve this.
- Both languages must be exercised — `sc lang en` and `sc lang zh` — for any change that
  touches user-facing strings.

## Project structure

<!-- source: top-level-glob -->
<!-- source: README.md -->

- `bin/sc` — the entire CLI, a single Python 3 script (`#!/usr/bin/env python3`).
  Installed to `/usr/local/bin/sc`.
- `install.sh` — Bash installer. Detects the package manager, downloads the sing-box
  binary, installs `sc`, writes the service unit, configures password-less sudo, downloads
  rulesets, starts the service. Also served over `curl | bash` from the repo's raw URL, so
  it must remain a **single self-contained file**.
- `uninstall.sh` — Bash uninstaller. Installed to `/usr/local/lib/singbox-cli/`.
- `systemd/` — unit files: `sing-box.service`, `sing-box-rules-update.service`,
  `sing-box-rules-update.timer`.
- `docs/` — `architecture.md`, `faq.md`. Human-facing.
- `README.md` + `README.zh-CN.md` — bilingual, kept in sync.
- `CHANGELOG.md` — user-visible changes.

Runtime paths the code owns (not in the repo):

<!-- source: README.md -->

- `/etc/sing-box/config.json` — auto-generated, never hand-edited.
- `/etc/sing-box/nodes.json` — node credentials, **mode 600, root-only**.
- `/etc/sing-box/settings.json` — user settings incl. CLI language.
- `/etc/sing-box/rules/*.srs` — rulesets.
- `/etc/sudoers.d/sc` — NOPASSWD scoped to `/usr/local/bin/sc`.

## Stack-specific conventions

<!-- source: README.md -->
<!-- source: user-q2 -->

- **Multi-distro first.** Supported package managers: apt, dnf, yum, pacman, zypper, apk.
  Supported init systems: systemd **and** OpenRC (Alpine). Any new install/uninstall step
  must handle both init systems or explicitly branch and skip.
- **Architecture support:** amd64 (x86_64) and arm64 (aarch64). Binary-download logic must
  map both.
- **Bilingual output is a hard requirement.** Every user-facing string ships in English and
  Simplified Chinese; the active language lives in `/etc/sing-box/settings.json` and is
  switched with `sc lang en|zh`. Adding a message in one language only is a defect.
- **Config is regenerated, never patched.** `sc` edits `nodes.json` / `settings.json`, then
  regenerates `config.json` from them.
- **Hot-apply over restart.** Node and route-mode switches go through sing-box's Clash API
  with no service restart. Prefer the API path over `systemctl restart`.
- **Idempotent installer.** Re-running `install.sh` is the documented upgrade path; it must
  never destroy user data.
- **Python 3.6+ compatibility.** README states 3.6+ as the requirement because that is what
  the older supported distros ship. Do not use syntax newer than 3.6 in `bin/sc` without
  changing that documented floor in README.md and README.zh-CN.md.
- **Least privilege.** `sc` runs under NOPASSWD sudo scoped to itself and is root-owned;
  never widen the sudoers entry, and never relax `nodes.json` from mode 600.

## Partitioning

<!-- source: top-level-glob -->

**Single developer.** The repo is flat and small — one CLI file, two shell scripts, three
unit files. Partition agents would add coordination cost with no benefit, so all code tasks
go to the plugin-provided `harness-kit:developer`.

Revisit only if `bin/sc` is split into a real package. A natural future split would follow
the top-level layout (CLI vs. installer/packaging), not invented scopes. To add partitions
later, create `.harness/agents/dev-<name>.md` with explicit owned-path globs, run
`.harness/scripts/harness-sync.sh`, and update the Agents section of `AI-GUIDE.md`.

## Stack-specific verify_all checks

<!-- source: top-level-glob -->
<!-- source: README.md -->

Candidates to add to `.harness/scripts/verify_all.sh` as the project grows — none are wired
yet, so add them deliberately rather than assuming they run:

- Syntax gates (cheap, no new dependency): `python3 -m py_compile bin/sc`,
  `bash -n install.sh`, `bash -n uninstall.sh`.
- Bilingual parity: assert every user-facing string in `bin/sc` has both an `en` and a `zh`
  entry, so a one-language message cannot ship.
- README parity: assert `README.md` and `README.zh-CN.md` have matching section structure.
- Installer idempotency: a container-based re-run of `install.sh` asserting `nodes.json`
  and `settings.json` survive.
- Systemd unit lint: `systemd-analyze verify systemd/*.service` where systemd is available.
