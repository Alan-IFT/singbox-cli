# 01 — Requirement Analysis — config-degrade-missing-rulesets (T-02)

- **Task ID**: T-02 (pool row T-02; absorbs pool row T-03 `ruleset-mirror-fallback` and the ruleset half of the download-progress request)
- **Mode**: full
- **Date**: 2026-07-31
- **Dispatch context**: deferred-human mode (defer, do not ask)
- **Verdict**: `READY` — 9 deferred decisions recorded in §8, each with a recommended resolution and a stated proceeding assumption. No blocking ambiguity.

---

## 1. Goal

`bin/sc` gains **one** ruleset-resource model — a single judgment of whether a `.srs` rule-set is usable, and a single validated multi-mirror atomic fetch that produces usable files — so that config generation emits only the rule-sets that are actually usable (dropping every rule that references an unusable one, and telling the user in both languages), and so a rule-set that cannot be downloaded degrades routing granularity instead of preventing the service from starting.

**One-line statement of the defect being removed:** an optional routing optimisation (four `.srs` files) is currently a hard start-up dependency of the proxy service.

---

## 2. Background and evidence

> This section is backward-looking EVIDENCE and cites path:line as proof of what exists today.
> Requirement prose (§3, §5, §6) deliberately carries no file/line anchors.

### 2.1 The reported failure

Project owner, Ubuntu, mainland-China network (TLS handshake to GitHub succeeds, large transfers time out), sing-box 1.13.14 pre-installed:

1. All four `.srs` downloads exhausted `timeout=30`, leaving `/etc/sing-box/rules/` empty.
2. `sc reload` regenerated `config.json` still containing four unconditional `type: "local"` rule-set entries.
3. sing-box FATALed in router init: `parse rule-set[0]: open .../geoip-cn.srs: no such file`, so `generate_config()` returned `False` and every later `sc add` repeated the same failure. Nodes were saved; the service never started.

### 2.2 Verified in the current tree (2026-07-31)

| # | Finding | Evidence |
|---|---|---|
| E-1 | `RULESET_URLS` maps filename → one absolute URL; all four are `github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/...`, which 302s to `raw.githubusercontent.com`. Both hops are unreachable on the target network, and this runs at install time before any proxy exists. | `bin/sc:45-50` |
| E-2 | `route.rule_set` is four unconditional entries built from `RULES_DIR`. | `bin/sc:530-539` |
| E-3 | `route.rules` references three of those tags (`geosite-google` → proxy; `geosite-private`, `geoip-cn`, `geosite-cn` → direct). | `bin/sc:522,524,527,528` |
| **E-4** | **`dns.rules` ALSO references rule-set tags** — `geosite-google` → `remote_dns`, `geosite-private` → `direct_dns`, `geosite-cn` → `direct_dns`. The task brief named only `route.rules`. Dropping a `rule_set` definition while leaving a `dns.rules` reference produces an invalid config just as surely as leaving a `route.rules` reference does. | `bin/sc:497,498,501` |
| E-5 | `cmd_update_rules` does `tmp.write_bytes(r.read())` — one blocking read, so progress is structurally impossible — then `tmp.replace(target)`. Temp-then-atomic-replace already exists and is worth keeping. | `bin/sc:810-819` |
| E-6 | The temp file name is a fixed `fname + ".tmp"`, shared by every concurrent invocation. The weekly timer and a manual run can collide. | `bin/sc:809` |
| E-7 | Per-file cause is printed on **stdout** (`print(t("failed: {e}", e=e))`); only the aggregate count goes to stderr via `sys.exit(...)`. Non-zero exit when any file failed. | `bin/sc:817,821` |
| E-8 | `install.sh` runs `sc update-rules >>"$LOG_SINK" 2>&1` — so at install time `sc`'s stdout is a **file, not a TTY**, and the whole ruleset step's output lands in `/var/log/sing-box/install.log`. The installer branches on the exit status. | `install.sh:456-463` |
| E-9 | `install.sh` likewise runs `sc reload >>"$LOG_SINK" 2>&1`, so a degradation warning emitted during install goes to the log, not the terminal. The installer already prints its own bilingual ruleset warning (`step6_warn`). | `install.sh:479`, `install.sh:146,189` |
| **E-10** | **`bin/sc`'s `t()` is NOT the crash-prone `install.sh` one.** It is `TRANSLATIONS.get(LANG, {}).get(s, s)` — a key missing from the `zh` table falls back to the English source string and **does not abort**. `.format(**kwargs)` is called only when kwargs are non-empty, so a missing key degrades to English text, while a *translated* string missing a placeholder the call site supplies is silently lossy, and a translated string containing a placeholder the call site does not supply raises `KeyError`. Bilingual parity is therefore a quality/review requirement in `bin/sc`, not a crash risk — the opposite of `install.sh`. | `bin/sc:60,172-174` |
| E-11 | `cmd_update_rules` restarts the service on success but **never regenerates the config**. Once the config has degraded, a successful re-download alone would restart sing-box with the still-degraded config — the owner's promised "补齐后 … 自动恢复" would be false. | `bin/sc:822-825` |
| E-12 | The documented Python floor (3.6+) is **already violated** by `subprocess.run(capture_output=…)` (3.7+) at two sites and `Path.unlink(missing_ok=True)` (3.8+) at one — the last of which is inside the exact loop this task rewrites. | `bin/sc:553,819,857`; README.md:21 |
| E-13 | `sc` auto-elevates at **import time** (`os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + argv)`), and the installed sudoers rule is a plain `NOPASSWD: /usr/local/bin/sc` with no `env_keep`. Consequence: an environment override set by a non-root caller is stripped by sudo's default `env_reset` across the re-exec, and any test harness must neutralise the elevate block to import the module as a non-root user. | `bin/sc:52-54`; `install.sh:437-441` |
| E-14 | `sub.add_parser("update-rules")` currently takes no arguments; both help blocks (en and zh) document the command in one line each. | `bin/sc:1069,980,1025` |
| E-15 | `verify_all.sh` B.1 runs `python3 -m py_compile bin/sc`; B.2/B.3 are still `SKIP`. F.6 caps an active task doc at 500 lines. | `.harness/scripts/verify_all.sh:52-71,223-231` |

### 2.3 Consequences of E-4, E-11 and E-6 for this requirement

- **E-4** widens the degradation rule: rule-set references must be dropped from **both** `dns.rules` and `route.rules`, not just `route.rules`.
- **E-11** adds a behavior the brief implies but the code does not have: a successful update must make the recovery actually happen.
- **E-6** makes a unique temp name part of the atomic-write requirement rather than an optional nicety.

---

## 3. In-scope behaviors

Numbered, testable, binding. No implementation location is named.

### 3.A The single usability judgment

**B-1 — One definition of "usable", one query.** `sc` has exactly one place that decides whether a rule-set file is usable. A rule-set is **usable** if and only if all of the following hold: the path exists and is a regular file; its first three bytes are the ASCII bytes `S`, `R`, `S`; and its size is at least the minimum-size floor (§8 Q1). Anything else — absent, a directory, unreadable, empty, wrong magic, below the floor — is **unusable**.

**B-2 — The judgment reports a per-file status, not a boolean.** For each of the four known rule-sets the judgment yields one of: `usable`, `absent`, or `invalid` with a machine-distinguishable reason (`bad-magic`, `too-small`, `unreadable`). Both config generation and the downloader consume this one result shape. No second, parallel notion of "present" exists anywhere in `bin/sc`.

**B-3 — The judgment is invocable in isolation.** Computing the per-file status requires neither a generated config, nor a running service, nor network access, nor execution of a command handler, and it does not itself create, modify, or delete any file.

### 3.B Config generation degrades per file

**B-4 — Only usable rule-sets are defined.** The generated configuration's route rule-set definition list contains exactly one entry per **usable** rule-set and no entry for any unusable one. When none is usable, the generated configuration contains no rule-set definition list (or an empty one) and still passes `sing-box check`.

**B-5 — Every dangling reference is dropped, in both rule lists.** A routing rule that references an unusable rule-set tag is omitted from the generated configuration. This applies to the DNS rule list **and** the route rule list (E-4). A rule that references a mix of usable and unusable tags retains only the usable tags, and is omitted entirely if that leaves it with no tags and no other matcher. The generated configuration contains no reference to a tag it does not define.

**B-6 — Degradation is per file, never all-or-nothing.** With exactly one rule-set unusable, only that rule-set's definition and only the rules referencing it are dropped; the other three and every rule referencing only them are emitted unchanged.

**B-7 — Core configuration always survives.** Node outbounds, the selector, the TUN inbound, the DNS server list, the DNS `final`, the route `final`, the Clash API block and the cache-file block are byte-for-byte unaffected by rule-set availability. With zero usable rule-sets the service starts and all traffic reaches the default outbound; only routing granularity is lost.

**B-8 — The user is told, in both languages, every time a degraded config is generated.** Config generation emits a warning naming the number of unusable rule-sets out of the total (real counts, never hard-coded), which ones they are, that the configuration was degraded, and the two commands that recover it (`sc update-rules`, `sc reload`). The wording distinguishes the total-degradation case ("no rule-based splitting at all") from the partial case ("the affected rules were skipped"), because "已降级为无分流模式" is factually wrong when three of four rule-sets are usable. Both an English and a Simplified-Chinese rendering ship. When every rule-set is usable, no warning is emitted and the on-screen output is unchanged from today.

**B-9 — Degradation is not an error.** Config generation returns success and the invoking command reports its own normal result when the only anomaly is one or more unusable rule-sets. `sc add`, `sc rm`, `sc use`, `sc mode`, `sc default-tun` and `sc reload` all complete normally and exit zero on a degraded config.

### 3.C Validated multi-mirror fetch

**B-10 — Filename → relative path, plus an ordered base list.** The download source is expressed as a per-file relative path combined with an ordered list of base URLs. The default order is: (1) `https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo`, (2) `https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo`, (3) `https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo`, (4) `https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo`. Trailing slashes on a base are tolerated and do not produce a doubled separator.

**B-11 — Bases are tried in order until one yields a file that passes validation.** A base that fails for any reason — transport error, non-2xx status, or content that fails validation — causes the next base to be tried for that file. Only after every base has been tried is the file recorded as failed.

**B-12 — Downloaded content is validated before it is installed.** The bytes received are accepted only if they satisfy the B-1 usability rule (SRS magic, minimum size) **and**, when the response declares a content length, the received byte count equals it. Content that fails validation is discarded and the next base is tried; it is never written to the rule-set's real path.

**B-13 — A base that has failed in a run is not retried in that run.** Once a base has failed for one file, the remaining files in the same invocation skip it. This bounds the wall-clock cost of a fully unreachable network to the same order as today's behavior (four sequential per-file timeouts) instead of multiplying it by the number of bases, without changing any timeout constant.

**B-14 — The base list is overridable.** A `--mirror <base-url>` option on `sc update-rules` and an `SB_RULES_BASE` environment variable each replace the default base list. `--mirror` takes precedence over `SB_RULES_BASE`; either accepts one or more base URLs, and an override consisting only of whitespace is treated as absent. An override replaces the built-in list rather than prepending to it (§8 Q3).

**B-15 — Total failure names every base tried.** When a file cannot be obtained, the reported cause enumerates every base URL attempted for it together with that base's failure reason, so a log reader can tell "unreachable network" from "wrong mirror path" from "mirror served an error page". This text keeps the existing stdout/stderr split: per-file causes on stdout, aggregate count on stderr (E-7).

**B-16 — Exit status contract preserved.** `sc update-rules` exits non-zero when at least one rule-set is unusable after all bases have been tried, and zero otherwise. `install.sh` branches on this and must keep working unmodified.

**B-17 — Recovery is automatic after a successful update.** When `sc update-rules` makes at least one rule-set usable that was not usable at the start of the run, it regenerates the configuration from the new usable set and applies it, so the promised "补齐后执行 `sc update-rules` … 自动恢复" is true. It does not create a configuration where none has ever been generated (the fresh-install ordering, E-8), and it does not restart the service in that case.

### 3.D Download progress

**B-18 — Per-file progress on a TTY.** When standard output is a terminal, each file's download displays continuously-updating progress showing the bytes received so far, and the completion percentage whenever the response declares a content length. The final state of each file's line reports the outcome (success with byte count, or the failure cause) exactly as today.

**B-19 — Progress degrades when standard output is not a terminal.** When standard output is not a terminal, the output contains no carriage-return-based redraw and no intermediate progress state: each file produces the same single completion line it produces today. This is a correctness requirement — the weekly timer and `install.sh` both capture this output into a file or the journal (E-8).

**B-20 — Progress requires a chunked read.** The response body is consumed incrementally so that progress reflects real transfer state; the whole-body single-read behavior is removed.

### 3.E Atomicity and hygiene

**B-21 — Temp-then-atomic-replace is preserved and made collision-safe.** Content is written to a temporary path in the same directory and moved into place with an atomic replace only after validation passes. The temporary path is unique per invocation, so two concurrent `sc update-rules` runs (timer plus manual) cannot corrupt each other's transfers; the final file is one complete version or the other, never a blend.

**B-22 — A failure never damages a good file and never leaves debris.** On any failure — transport, validation, disk-full, interrupt — the previously-installed file at the rule-set's real path is left byte-identical, and no temporary or partial file remains for that rule-set. A stale temporary file from an earlier killed run is never treated as a rule-set and is removed when the same rule-set is next fetched.

### 3.F Presentation and packaging

**B-23 — Bilingual parity for every new string.** Every user-facing string this task adds exists in both the English source form and the Simplified-Chinese table, with matching placeholder sets. Verified against `bin/sc`'s own fallback semantics (E-10): a missing key renders English rather than crashing, so parity is enforced by review and by an explicit acceptance criterion, not by a runtime abort.

**B-24 — Help and documentation cover the new surface.** The `--mirror` option and the `SB_RULES_BASE` variable appear in `sc help` in both language blocks, and in `README.md` and `README.zh-CN.md` in matching positions.

**B-25 — Python floor discipline.** Every line this task writes or rewrites uses only syntax and standard-library APIs available in Python 3.6, standard library only, no new dependency. In particular the rewritten download loop no longer uses the 3.8-only `unlink(missing_ok=…)` (E-12).

**B-26 — Diff boundary.** The change is confined to `bin/sc`, `CHANGELOG.md`, `README.md` and `README.zh-CN.md`. `install.sh`, `uninstall.sh` and `systemd/` are byte-identical to `main`.

---

## 4. Out of scope

1. **Any timeout change.** The owner ruled enlargement out explicitly: the local Clash-API timeout (3s), the egress-IP timeout (8s) and the ruleset-download timeout (30s) all keep their current values. The failure was true unreachability, not slowness; multi-source fallback is the fix. B-13 exists precisely so that adding mirrors does not enlarge the effective wall-clock budget.
2. **`install.sh`** — T-01 landed there (commit `493eb6a`) and is delivered. Not touched (B-26).
3. **`systemd/`** — the `ExecStart=/usr/local/bin/proxy` defect is pool row T-09.
4. **`sc doctor`** (T-05) and **`sc config --show`** (T-06). B-2's per-file status is the model T-05 will consume; this task adds no command, no screen and no persisted health state for it.
5. **Restricted-network end-to-end regression** (T-07). Every criterion here is executable with local stubs and fixtures.
6. **Binary-download progress in the installer** (T-08). Only the visual language is shared; no code is shared.
7. **Automatic retry of `sing-box check` with all rule-sets dropped** when a byte-valid rule-set is semantically corrupt (§8 Q5). A check failure surfaces exactly as it does today.
8. **Fixing the two remaining pre-existing Python-floor violations** at sites this task does not rewrite (E-12) — filed as §8 Q9.
9. **Wiring `verify_all` B.2/B.3 to a committed test suite** (§8 Q8) — T-07 owns the harness.
10. **Rule-set content semantics** — no parsing beyond magic/size/length, no format-version negotiation, no schema awareness of what a rule-set contains.
11. **New rule-sets, new tags, or changes to routing policy.** The four rule-sets and the routing rules that reference them stay exactly as they are when everything is usable.
12. **File modes of `.srs` files** — unchanged from today's default.

---

## 5. Boundary conditions

| # | Condition | Required behavior |
|---|---|---|
| BC-1 | Rules directory absent entirely | All four report `absent`; config generated with zero rule-sets; total-degradation warning; service startable. |
| BC-2 | Rule-set file is 0 bytes | `invalid` (`too-small`); dropped; warning counts it. |
| BC-3 | Rule-set path is a directory | `invalid`; no exception escapes; dropped. |
| BC-4 | Rule-set file unreadable (permission, dangling symlink) | `invalid` (`unreadable`); no exception escapes; dropped. |
| BC-5 | Rule-set file is an HTML error page | First bytes are not `SRS` → `invalid` (`bad-magic`); dropped from the config and, during download, never written to the real path. |
| BC-6 | File begins with `SRS` but is below the floor | `invalid` (`too-small`); dropped. |
| BC-7 | All four usable | No warning; generated configuration is semantically identical to today's for the rule-set and rules sections. |
| BC-8 | Exactly one unusable | Only that definition and only the rules referencing it are dropped, in both the DNS and the route rule lists; count reported as `1/4`. |
| BC-9 | All four unusable | Rule-set definition list empty or absent; every referencing rule dropped from both lists; `final` outbound and DNS `final` unchanged; `sing-box check` passes; count reported as `4/4`. |
| BC-10 | Response is a 302 chain | Followed by the HTTP client as today; the final content is what gets validated. |
| BC-11 | Response is 403 / 404 / 5xx | That base fails; next base tried; base marked failed for the rest of the run. |
| BC-12 | DNS failure / connection refused / read timeout mid-transfer | Same as BC-11; partial bytes discarded; previously-good file untouched. |
| BC-13 | Response declares a content length and delivers fewer bytes | Rejected as truncated; next base tried; nothing written to the real path. |
| BC-14 | Response declares no content length | Accepted if magic and floor pass; progress shows bytes only, no percentage. |
| BC-15 | Response is 200 with a zero-length body | Rejected (`too-small`); next base tried. |
| BC-16 | Every base fails for every file | Non-zero exit; stdout carries per-file causes enumerating every base tried; stderr carries the aggregate count; no file on disk changed. |
| BC-17 | A good file already exists and every base fails | Existing file untouched and still `usable`; the config is **not** degraded for that rule-set. |
| BC-18 | Disk full while writing the temporary file | That file fails; temporary removed; real path untouched; the run continues with the remaining files. |
| BC-19 | Two `sc update-rules` run concurrently | Neither corrupts the other's transfer; each rule-set ends as one complete version. |
| BC-20 | Stale temporary file from a killed run | Never counted as a rule-set; removed when that rule-set is next fetched. |
| BC-21 | Standard output is not a terminal | No carriage return anywhere in the output; one completion line per file. |
| BC-22 | `--mirror` and `SB_RULES_BASE` both set | `--mirror` wins; `SB_RULES_BASE` ignored, silently. |
| BC-23 | `SB_RULES_BASE` set to an empty or whitespace-only value | Treated as unset; default list used. |
| BC-24 | Override base is malformed or uses an unsupported scheme | Every file fails against it with a cause naming that base; exit non-zero; no default-list fallback (B-14). |
| BC-25 | `SB_RULES_BASE` set by a non-root caller | Stripped by sudo's `env_reset` across `sc`'s auto-elevation (E-13), so the default list is used. Documented in both READMEs; no code change attempts to defeat sudo's environment policy. |
| BC-26 | `sc update-rules` restores rule-sets on a host with an existing degraded config | Config regenerated from the new usable set and applied (B-17); no second command required. |
| BC-27 | `sc update-rules` succeeds during a fresh install, before any config exists | No config is created and no restart is attempted; the installer's own later config-generation step produces the first config. |
| BC-28 | `sc update-rules` succeeds and the usable set is unchanged | Behavior identical to today (restart only if the service is running). |
| BC-29 | Rule-set replaced while a config is being generated | The atomic replace guarantees the reader sees the complete old or the complete new file, never a blend. |
| BC-30 | Language is `zh` | Every new message renders as Chinese text; no English string leaks into a `zh` run. |
| BC-31 | Language key missing from the `zh` table | Renders the English source string; does not crash (E-10). Prohibited by B-23 and blocked by AC-14. |
| BC-32 | Config generation during install | The degradation warning lands in `/var/log/sing-box/install.log`, not the terminal (E-9); the installer's own bilingual ruleset warning remains the on-screen signal. Not a defect. |

---

## 6. Acceptance criteria

**Verification constraint.** No network-restricted VM, no systemd host and no root test host is assumed. `bin/sc` auto-elevates at import (E-13), so the harness loads the source with the elevation guard neutralised and repoints the config/rules path globals at a temporary directory. Network behavior is exercised against a local stub HTTP server (or `file://` bases) and byte fixtures; no criterion below requires the public internet. Any criterion that cannot be executed is reported **unverified**, never assumed.

**Fixtures required:** a valid minimal `.srs` (bytes `SRS` + payload, at or above the floor), an HTML error page, a zero-byte file, a truncated body served with an over-declared content length, and a real `.srs` sample where one is obtainable.

| # | Criterion | How it is checked |
|---|---|---|
| AC-1 | `python3 -m py_compile bin/sc` succeeds and `bash .harness/scripts/verify_all.sh` ends with `FAIL: 0`. | Direct commands. |
| AC-2 | For each of `absent`, zero-byte, directory, unreadable, HTML page, below-floor, and valid fixtures, the usability query returns the expected status and reason, raises nothing, and modifies no file. | Unit-level call on the loaded module against a fixture directory. |
| AC-3 | With all four fixtures valid, the generated configuration's rule-set definition list has four entries and the DNS and route rule lists are identical to those produced by `main`. | Generate config in the harness; compare JSON to a baseline captured from `main`. |
| AC-4 | With `geosite-google` alone unusable, the generated configuration defines exactly three rule-sets, contains no rule referencing `geosite-google` in **either** the DNS rule list or the route rule list, and retains every rule referencing the other three. | JSON assertion. |
| AC-5 | With all four unusable, the generated configuration contains no rule-set definition (or an empty list), no rule referencing any of the four tags in either rule list, and retains node outbounds, the selector, the TUN inbound, DNS `final`, route `final`, the Clash API block and the cache block byte-identically to the all-usable case. | JSON diff restricted to the rule-set and rules sections. |
| AC-6 | Every rule-set tag referenced anywhere in the generated configuration is also defined in it, for all 16 subsets of usable/unusable. | Property test over all 16 combinations. |
| AC-7 | For all 16 subsets, `sing-box check` accepts the generated configuration. | Executed if a `sing-box` binary is available; otherwise reported **unverified** with the reason. |
| AC-8 | The degradation warning reports the true `n/total`, names the unusable rule-sets, names `sc update-rules` and `sc reload`, and uses distinct wording for the all-unusable and partial cases; no warning is emitted when all four are usable. | Captured-output assertion across the 0-, 1-, 3- and 4-unusable cases. |
| AC-9 | A command that regenerates a degraded config (e.g. adding a node) exits zero and prints its normal result line. | Harness invocation, assert exit status and output. |
| AC-10 | **A base serving an HTML error page (HTTP 200, `text/html`) is rejected: nothing is written to the rule-set's real path, no temporary file survives, and the next base in the list is tried and its valid content installed.** | Stub server: base 1 → HTML, base 2 → valid fixture. Assert final file bytes equal the fixture, assert directory contains no temp file, assert the failure of base 1 appears in the output. |
| AC-11 | Fallback order is honoured: with bases 1 and 2 failing (timeout and 404) and base 3 valid, base 3's content is installed and the output names bases 1 and 2 with distinct causes. | Stub server per base. |
| AC-12 | A base that failed for the first file is not requested again for the remaining files in the same run. | Stub server request log; assert request count per base. |
| AC-13 | When every base fails for every file: exit status non-zero; stdout contains a per-file cause enumerating **every** base tried; stderr contains only the aggregate count; a pre-existing good file on disk is byte-identical afterwards and still reports `usable`. | Stub server returning failures; assert streams separately, assert file hash. |
| AC-14 | Every user-facing string added by this task has both an English source form and a `zh` entry, with identical placeholder sets; every scenario above is re-run under `sc lang zh` and produces non-empty Chinese text with no English leakage and no `KeyError`. | Static extraction of the translation table + a second full pass with `LANG = "zh"`. |
| AC-15 | With standard output redirected to a file, the captured bytes contain no `\r` and exactly one completion line per rule-set. | Harness run with a pipe; byte-level assertion. |
| AC-16 | With standard output attached to a pseudo-terminal and a stub server that delivers a known-size body in several chunks with a declared content length, the captured stream contains at least two intermediate progress states for a file, showing increasing byte counts and a percentage. | PTY-backed harness run. |
| AC-17 | With no declared content length, progress shows byte counts and no percentage, and the download still succeeds. | Stub server without `Content-Length`. |
| AC-18 | A truncated body (declared length greater than delivered bytes) is rejected; the next base is tried; the real path is untouched. | Stub server. |
| AC-19 | Two concurrent runs against a slow stub server leave every rule-set byte-identical to one of the two complete fixtures, with no temp file remaining. | Two subprocesses against the harness copy. |
| AC-20 | A stale temp file placed in the rules directory before a run is absent afterwards and never appears in the usability report. | Fixture + assertion. |
| AC-21 | `--mirror` overrides `SB_RULES_BASE`; either alone replaces the default list; an empty/whitespace override is ignored; a malformed override fails every file with a cause naming it and does not fall back to the default list. | Four harness runs with a request-logging stub. |
| AC-22 | After a run that makes a previously-unusable rule-set usable, the on-disk configuration contains that rule-set and its rules without any further command; when no configuration exists yet, none is created. | Harness: degraded config → run → re-read config JSON; and empty-dir → run → assert no config file. |
| AC-23 | `sc update-rules` exits non-zero when at least one rule-set remains unusable and zero when all are usable. | Harness, both cases. |
| AC-24 | `sc help` documents `--mirror` and `SB_RULES_BASE` in **both** language blocks, and both READMEs document them in matching positions. | Output assertion + diff review. |
| AC-25 | The diff touches only `bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`; `install.sh`, `uninstall.sh` and `systemd/*` are byte-identical to `main`; no timeout constant changed. | `git diff` review. |
| AC-26 | No syntax or standard-library API newer than Python 3.6 appears in added or rewritten lines, and `unlink(missing_ok=` no longer appears in the rewritten download loop. | Static review + grep. |
| AC-27 | Each of the four real rule-sets fetched from the default first base passes validation and its size is at or above the chosen floor. | **Requires network.** Executed where a reachable network exists; otherwise reported **unverified** and the floor decision (§8 Q1) is carried as an explicit residual risk. |

---

## 7. Non-functional requirements

- **Compatibility.** Python 3.6, standard library only, no new dependency, no new file installed at runtime. `install.sh` keeps working against `sc update-rules` unmodified (exit-status and stream contract, B-15/B-16).
- **Performance / time budget.** A fully unreachable network costs no more wall-clock time than today (B-13). Config generation adds at most one `stat` and one three-byte read per rule-set — four of each — on a path already dominated by a subprocess `sing-box check`.
- **Security.** No change to the privilege model, the sudoers scope, `nodes.json` mode 600, or `config.json` mode 600. The mirror override is only effective for a caller who is already root (E-13, BC-25); the tool gains no new way for an unprivileged user to influence what root writes.
- **Observability.** The stdout (per-file cause) / stderr (aggregate) split is preserved verbatim, because `install.sh` and T-01's failure reporting depend on it. Base-by-base causes make a mirror-layout error distinguishable from an unreachable network in `/var/log/sing-box/install.log`.
- **Compatibility of behavior when nothing is wrong.** With all four rule-sets usable and stdout not a terminal, the observable behavior of every command is unchanged from `main`.
- **Do not over-build.** No new file, no new config key, no new persisted state, no plugin surface. One status model, one fetch routine, one warning.

---

## 8. Open questions (deferred-human mode — recorded, not asked)

Each carries a **Recommended** resolution and a proceeding assumption. None makes the requirement unspecifiable.

**Q1 — The minimum-size floor.** The brief says "~512 bytes". (a) 512 bytes as written. (b) A low floor (16 bytes: magic + version + minimal payload), with the SRS magic and the content-length check doing the real work.
**Recommended: (b), 16 bytes.** `geosite-private` is a very small list (localhost, `.local`, `.home.arpa`, …) and its compiled `.srs` plausibly falls **under** 512 bytes; a 512-byte floor would then permanently reject a legitimately-downloaded file and degrade the config forever — a self-inflicted repeat of the bug being fixed. The floor's only real job is excluding empty/stub responses, which 16 bytes does; the magic check rejects HTML pages regardless of size (an error page is far larger than 512 bytes anyway), and the content-length check (B-12) is a far better truncation guard than any floor. **Binding constraint either way: the floor must be strictly below the smallest of the four real rule-sets** (AC-27).
**Proceeding assumption**: (b). If AC-27 can be executed and shows every real rule-set comfortably above 512 bytes, the architect may raise the floor; it must never be raised without that measurement.

**Q2 — Two warning variants or one.** (a) Two messages: the owner's exact "已降级为无分流模式" wording for the all-unusable case, plus a partial-degradation wording. (b) One count-parameterised message for both.
**Recommended: (a).** "已降级为无分流模式" is a true statement at 4/4 and a false one at 1/4, and this task exists because the tool told the user something untrue. Two keys (four table entries) is the whole cost.
**Proceeding assumption**: (a). B-8 and AC-8 are written to (a).

**Q3 — Does an override replace or prepend to the default base list?** (a) Replace. (b) Prepend, keeping the defaults as fallback.
**Recommended: (a) replace.** An explicit `--mirror` is a diagnostic instrument; silently succeeding via jsdelivr after the named mirror failed makes it useless for diagnosis and makes AC-21 untestable. The user who wants both can pass both (B-14 accepts a list).
**Proceeding assumption**: (a). BC-24 and AC-21 are written to (a).

**Q4 — Which stream carries the degradation warning?** (a) stderr, matching the existing `⚠️ Config check failed` warning. (b) stdout, matching `update-rules`' per-file causes.
**Recommended: (a) stderr.** It is a warning, not a result; it keeps `sc add`'s stdout a clean single result line; and `install.sh` captures both streams (E-9), so nothing is lost in the install path. The insight-index rule about causes on stdout is specific to `sc update-rules`' per-file causes, which B-15 preserves unchanged.
**Proceeding assumption**: (a).

**Q5 — Fallback when a byte-valid rule-set is semantically corrupt and `sing-box check` still fails.** (a) No automatic second pass; the check failure surfaces exactly as today. (b) Retry once with all rule-sets dropped.
**Recommended: (a).** (b) would mask unrelated config errors (a bad node) as "rule-set trouble" and silently ship a config with no routing rules for a reason the user never sees. The magic + size + length checks cover the reported failure mode; a semantically-corrupt-but-well-formed `.srs` from an official mirror is not an observed case.
**Proceeding assumption**: (a). Recorded in §4 item 7.

**Q6 — Should a base be marked dead on a *validation* failure as well as a transport failure (B-13)?** (a) Any failure marks the base dead for the run. (b) Only transport failures.
**Recommended: (a).** A base that serves an HTML page or a wrong path layout for one file will do so for all four; distinguishing the two cases adds branching for no observed benefit. This is a deliberate small addition beyond the brief, made specifically to keep the "do not enlarge the time budget" constraint true once four bases exist.
**Proceeding assumption**: (a). B-13, BC-11 and AC-12 are written to (a).

**Q7 — Human-readable byte counts in progress output.** (a) Raw bytes, matching the existing `OK ({size} bytes)`. (b) KB/MB formatting.
**Recommended: (a).** Consistency with the existing completion line, no new formatting helper, no new translated unit strings.
**Proceeding assumption**: (a).

**Q8 — Wire `verify_all` B.2 to a committed test for the new pure functions?** (a) Yes — rule 50 says the first task adding a testable command must replace the matching SKIP, and the usability judgment is genuinely unit-testable. (b) No — keep B.2 `SKIP`; T-07 owns the committed harness.
**Recommended: (b), with a caveat.** The repo has no test directory and T-07 is the row that owns making tests real; creating one here widens the diff past B-26 and pre-empts T-07's design. The caveat: a permanently-SKIPping gate proves nothing, so this task's QA harness is handed to T-07 rather than discarded.
**Proceeding assumption**: (b). If the architect judges a ~20-line committed unit test for the usability judgment to be within scope, (a) is acceptable and AC-2 becomes a gated check.

**Q9 — The pre-existing Python-floor violations (E-12).** `capture_output=` (3.7+) at two sites this task does not rewrite means the documented 3.6+ floor is already false. (a) File a new pool row to either lower the code to 3.6 or raise the documented floor to 3.8 in both READMEs and `CHANGELOG.md`. (b) Fix it inside this task.
**Recommended: (a) file a row.** It is a documentation-versus-code contradiction spanning `bin/sc`, both READMEs and the changelog — unrelated to rule-sets, and folding it in would widen B-26 for no shared seam. This task removes the one violation that happens to sit inside the loop it rewrites (B-25) and adds none.
**Proceeding assumption**: (a). PM to add the row; T-02 proceeds under B-25.

---

## 9. Related work

- `docs/features/_archived/install-enable-start-split/01_REQUIREMENT_ANALYSIS.md` — T-01, delivered. Its §4 items 1-2 hand exactly this scope (config degradation, mirrors, validation, atomic replace, retry policy) to T-02; its Q3 resolution ("a ruleset failure alone is not an install failure") only becomes *true* once this task ships, and its B-12/AC-15 depend on the stdout/stderr split preserved here by B-15.
- `docs/features/_archived/install-enable-start-split/05_CODE_REVIEW.md`, `06_TEST_REPORT.md` — the stub-PATH harness technique reused by §6, and the translation-key parity extractors reusable for AC-14.
- `docs/batches/default/BATCH_PLAN.md:12-13,30-49,79-88` — the consolidation record: T-03 merged into T-02 (one usability judgment, not two), ruleset download progress folded in (same fetch loop), the shared non-TTY constraint with T-08, and the standing ban on enlarging timeouts.
- `docs/tasks.md` — T-01 is the only completed task; no other historical row constrains this one.
- `.harness/rules/50-singbox-cli.md` — bilingual output as a hard requirement, config regenerated not patched, hot-apply over restart, the Python 3.6 floor, and the "first real task replaces the matching SKIP" instruction behind Q8.
- `.harness/rules/85-design-discipline.md` — names T-02/T-03 as its own precedent for the duplicated-judgment test; B-1/B-2 are the single judgment that split would have duplicated. The counter-rule binds §4: no new file, module, or config format.
- `.harness/insight-index.md` — the `sc update-rules` stdout-cause line is honoured by B-15 and Q4; the one-language-key line is `install.sh`-specific and does **not** transfer (E-10 states what `bin/sc` actually does).
- `.harness/rejected-decisions.md` — template only; nothing here re-litigates a prior decline.
- `CONTEXT.md` — unmodified template. This task introduces one term worth recording if the owner adopts the glossary: **usable rule-set** (a `.srs` file that exists, carries the SRS magic and meets the size floor — the single condition config generation and the downloader both consult). _Avoid_: "present", "downloaded", "available".
- Downstream consumers: **T-05 `sc doctor`** reads B-2's per-file status rather than forming a second opinion; **T-07** asserts the combined T-01 + T-02 end state on a restricted network, including AC-27 and the deferred AC-9 from T-01.

---

## Verdict

**READY.**
