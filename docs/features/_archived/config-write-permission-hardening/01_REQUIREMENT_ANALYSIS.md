# 01 — Requirement Analysis · T-13 `config-write-permission-hardening`

Mode: **full**. Deferred-human mode: standing decision authority granted; every judgment call
below is resolved as a `DECISION-n` with its reasoning and what would overturn it. No blocking
question is emitted. Verdict at §9.

---

## 0. Evidence — what the current source actually does

Backward-looking citations, path:line, gathered read-only. No shell was available to this stage,
so nothing here rests on a command I ran against the live system; where a fact needed the
filesystem it was obtained by a content probe that returns counts, never bytes (see E-8).

| # | Finding | Evidence |
|---|---|---|
| E-1 | There is **exactly one** write path to `config.json` in the whole repo, and it *is* followed by a chmod to 0600. | `bin/sc:1016-1017` — `CFG_PATH.write_text(...)` then `os.chmod(CFG_PATH, 0o600)`. `CFG_PATH` appears at `bin/sc:19, 1016, 1017, 1019, 1358, 1362, 1365, 1366, 1371, 1660`; `1016` is the only write. No other file in the repo writes `config.json`. |
| E-2 | `config.json` is credential-bearing to exactly the same degree as `nodes.json`. | `bin/sc:975` — `"outbounds": [selector] + nodes + [...]` embeds the node dicts verbatim; those dicts carry `uuid` (`:409, :432, :546`), `password` (`:468, :504, :516, :528, :547`) and the reality `public_key` / `short_id` (`:394, :397`). |
| E-3 | **Correction to the brief:** there is no reality *private* key anywhere in this tool. It is a client; only `pbk` (public key) and `short_id` are parsed and emitted. | `bin/sc:391-397`. The credential set to protect is: VLESS/TUIC UUIDs, trojan/ss/hy2/tuic passwords, reality public key + short id, server hostnames and ports. |
| E-4 | `nodes.json` has the **identical** write-then-chmod shape, in two places, and it is the primary credential store. | `bin/sc:311-312` (`_init_files()` creates it, then chmods) and `bin/sc:323-324` (`save_nodes()` writes, then chmods). Documented as "mode 600, root-only" at `README.md:191, :217`, `README.zh-CN.md:191, :217`, `docs/architecture.md:119`. |
| E-5 | `settings.json` is written with **no** chmod at all, in three places. It is **not** credential-bearing. | `bin/sc:313-315`, `bin/sc:331-332`, `install.sh:417-431`. Content on this host is `default_tun` / `mode` / `lang` / `clash_api_port` (E-8). |
| E-6 | **No backup path exists.** The tool never writes a `.bak`, a `.old`, a timestamped copy, or any second copy of a credential-bearing file. | Repo-wide search for `\.bak|backup` outside `docs/features/_archived/`: the only shipped-code hit is `README.md:230` ("Node import/export (JSON backup)" — an unchecked roadmap box). Every other hit is `.harness/scripts/*` (harness tooling, not shipped; it backs up `.claude/settings.json` and harness scripts, never a credential file). `uninstall.sh` contains no `cp` / `mv` / `tar` at all. The `/usr/local/bin/sc.bak-2026-08-01-1006` named in `docs/batches/default/BATCH_PLAN.md:126` was made by a human at a shell, not by this tool. |
| E-7 | The complete inventory of files `bin/sc` writes: `nodes.json`, `settings.json`, `config.json`, a systemd `override.conf` (`:1712`), an OpenRC periodic script (`:1760`), and the rule-set download temporaries (`:879`, `:1632`). Only the first and third are credential-bearing. | grep of every `write_text` / `open(` / `replace(` in `bin/sc`. |
| E-8 | On this host, `/etc/sing-box/config.json` and `/etc/sing-box/nodes.json` are **not readable by the unprivileged user**, while `/etc/sing-box/settings.json` **is** (6 lines matched, showing `mode`/`lang`/`clash_api_port`). | Content-count probe (no bytes of the credential files were read or could be read). This corroborates the owner's `-rw-------` claim for `config.json`, refutes it for nothing, and proves two further things: the directory `/etc/sing-box/` is traversable and readable by any local user, so a 0644 file inside it really is world-readable; and `settings.json` really is world-readable today. |
| E-9 | `sc doctor` does **not** report file permissions. Its seven sections are binary / rule-sets / configuration / service / TUN / Clash API / egress IP; the configuration probe opens the file only to learn whether it is readable and never inspects the mode. `st_mode` and `import stat` appear nowhere in `bin/sc`. | `bin/sc:1502-1510` (`DOCTOR_SECTIONS`), `bin/sc:1351-1366` (`_doctor_config`). |
| E-10 | `install.sh` today performs no permission check over `/etc/sing-box/`. It creates the directory at the ambient umask (`install.sh:411`), sets modes only for artifacts it installs (`install.sh:405, 412, 413, 442-444, 468, 476`), and ends with `install_report \|\| exit 1` (`install.sh:532-533`). It already uses a `umask` subshell once, for the install log (`install.sh:486`). | as cited. |
| E-11 | The project's existing atomic-write pattern is `tmp.replace(target)` at `bin/sc:1632`, used for rule-sets only. **`config.json` is not written atomically today** — `write_text` truncates the live file in place. | `bin/sc:1016` vs `bin/sc:1632`. |
| E-12 | `generate_config()` writes the config **before** running `sing-box check`, and a failing check does not roll the file back. | `bin/sc:1016-1024`. |
| E-13 | `install.sh` runs under `set -euo pipefail` (`install.sh:9`), so any un-guarded `chmod` that fails terminates the run with no stated outcome — the failure class recorded as open row R-3 in `docs/tasks.md`. | as cited. |

### E-14 — Adjudication of the disputed root cause

The reporter's stated cause ("the tool never sets permissions when regenerating") is **false**
for current source: E-1 shows one write path and a chmod on the next line. The owner is
**right about the code and right about this host** (E-1, E-8).

Both framings are nevertheless imprecise, and the precise version matters for the design:

- `Path.write_text` opens with `O_WRONLY|O_CREAT|O_TRUNC` and a mode argument of `0o666`. The
  mode argument **applies only when the file is created**. Therefore the exposure window is at
  **first creation** (0666 & ~umask = 0644 typically), not at every regeneration; a regeneration
  over an existing 0600 file never re-widens it.
- Conversely, on a file that is *already* 0644, `write_text` does not widen anything — but the
  chmod on the following line **does narrow it to 0600**. So a host with an `sc` at or after the
  chmod's introduction self-heals its `config.json` mode on the very first regeneration, and
  `install.sh` step 7 runs `sc reload` on every install and upgrade (`install.sh:515`).

The consequence is that the reporter's `-rw-r--r--` has exactly one surviving explanation of
substance: **that host was running an `sc` build older than the one that introduced the chmod**
(asserted upstream as commit `41ffd08`; I could not verify that sha — this stage has no shell —
and no conclusion here depends on the sha). Version skew of exactly this kind is live on this
very machine: the installed `/usr/local/bin/sc` is an older build than the repo's `bin/sc`
(`docs/tasks.md` T-05 row; `docs/batches/default/BATCH_PLAN.md:121-129`). The remaining
explanations are a chmod that failed (impossible to do silently — the OSError would propagate and
kill the command) or an observation taken inside the sub-millisecond creation window (not
plausible for a human running `ls`).

**This is precisely why surface 3 matters**: the code fix alone reaches a legacy host only when
that host's `sc` is replaced *and* a regeneration runs. The installer is the one moment both
happen, and the one place that can also state what it found.

---

## 1. Goal

Guarantee that no file this tool creates ever holds credential bytes at a mode wider than `0600`
at any instant, including the interval between creating a file and adjusting its mode, and have
`install.sh` state the mode of every credential-bearing file under the configuration directory
before it prints its closing banner.

---

## 2. In-scope behaviors

Scope is `bin/sc` and `install.sh` only.

**Surface 1 — credential file writes in `bin/sc`**

1. Writing the generated configuration leaves `/etc/sing-box/config.json` at mode exactly `0600`,
   with no group and no other permission bit, whatever the process umask is and whatever mode the
   file had beforehand.
2. Writing the node store leaves `/etc/sing-box/nodes.json` at mode exactly `0600` under the same
   two independences. This holds for both of its writers — first creation and every save.
3. At every instant during a write of either file, every filesystem object that holds any byte of
   the new content has mode `0600` or narrower. There is no instant at which any such object is
   readable by group or other.
4. Replacement of `/etc/sing-box/config.json` is atomic: at every instant the path either does not
   exist or names a complete document. A reader that opens the path concurrently with a
   regeneration observes either the whole previous document or the whole new one, never a
   truncated or partially written one.
5. When installing new content fails for an operating-system reason (no space, read-only
   filesystem, permission denied, target is a directory), the previous content of the target is
   left byte-identical, no partially written object survives, and the command reports the failure
   in the active language on stderr, naming the path and the operating-system cause, with no
   Python traceback reaching the user. `sc reload` exits non-zero on that path.
6. A successful write leaves no temporary object of its own behind in the configuration directory.
7. Two concurrent regenerations leave `config.json` equal to one of the two complete documents
   produced, at mode `0600`, and leave nothing behind at a wider mode.
8. `settings.json` is written unchanged (see NG-4).

**Surface 2 — backups**

9. **No backup path exists in the shipped code (E-6), and none is created by this task.** The
   requirement is restated as a standing invariant rather than a feature: *every* object this tool
   creates that holds credential bytes — including any temporary, intermediate or future backup
   copy — is subject to behaviours 3 and 5 above. Today that invariant binds exactly the
   temporaries introduced by behaviour 4.

**Surface 3 — `install.sh` closing permission check**

10. After the last install step and before the closing report, `install.sh` prints a permission
    section: one line per credential-bearing file under the configuration directory
    (`config.json`, `nodes.json`), naming the path and its mode.
11. The section runs on every run, including runs where an earlier step failed.
12. A file found wider than `0600` is narrowed to `0600`, and its line says so, naming both the
    mode it had and the mode it now has. A file at `0600` or narrower is left untouched and
    reported as such. No file's mode is ever widened by the installer (DECISION-3).
13. A credential-bearing file that does not exist is reported as absent, is not created, and does
    not make the section report a problem.
14. When a mode cannot be changed, the section prints a problem line naming the file and the mode
    it still has, and the run continues to its closing report; the sweep never terminates the
    installer (E-13).
15. The closing banner produced by `install_report()` remains the last output of the run, and the
    installer's exit status is derived exactly as it is today (DECISION-5).
16. Every string the section prints exists in both language tables of `install.sh`'s `t()`.

---

## 3. Out of scope (non-goals)

- **NG-1** A user-facing permission override / configuration-customisation mechanism — that is T-14.
- **NG-2** urltest group (T-15), DNS changes (T-16), rule-set staleness (T-19), any extension of
  `sc doctor` (T-20). In particular, **no permission row is added to `sc doctor`**: E-9 establishes
  it has none today, so per the scope boundary it is left alone for T-20.
- **NG-3** Making `sing-box check -c /etc/sing-box/config.json` succeed for a non-root user. A
  0600 config denying that is correct behaviour, not a defect (owner through-line: a generated
  artifact leaves room for the user, but not by publishing credentials).
- **NG-4** Changing `settings.json`'s mode. It is world-readable today (E-5, E-8) and carries no
  credential (DECISION-2).
- **NG-5** Changing the mode of `/etc/sing-box/` itself or of `/etc/sing-box/rules/`.
- **NG-6** Ownership: no `chown`, and no uid/gid reporting. Mode only (DECISION-4).
- **NG-7** Introducing any backup, export or snapshot feature (E-6).
- **NG-8** Any timeout change.
- **NG-9** Changing *when* the config is written relative to `sing-box check`, or making a failed
  check roll the file back. E-12's ordering is preserved verbatim.
- **NG-10** Any change to `uninstall.sh`, the service units, or `sc doctor`.
- **NG-11** Repairing modes of files outside the enumerated credential-bearing set, anywhere on
  the system.

---

## 4. Boundary conditions

| # | Condition | Required behaviour |
|---|---|---|
| BC-1 | umask `0o000` | Final mode is exactly `0600`. (A mode argument alone would give `0666`-derived results only if the object is created; see BC-3.) |
| BC-2 | umask `0o277` | Final mode is exactly `0600`, not `0400`. A mode argument passed at creation is **masked** by umask, so a design that only passes a mode cannot satisfy this; the requirement is on the guaranteed end state, not on any chosen API. |
| BC-3 | Target already exists at `0644` / `0664` / `0666` | Final mode is exactly `0600` and the content is the new content. Note that an `O_CREAT` mode argument is **ignored entirely** for an existing file, so a design based only on creation mode would *regress* this case — which is exactly the reporter's host (E-14). |
| BC-4 | Target already exists at `0400` or `0000`, owned by root | The write succeeds (root ignores the mode) and the final mode is exactly `0600`. |
| BC-5 | Target does not exist; configuration directory does not exist | The command fails loudly per in-scope behaviour 5. Creating the directory is `_init_files()`'s job and is unchanged. |
| BC-6 | Empty node list | The configuration is still generated and still ends at `0600`. The mode never depends on whether the document happens to contain a credential. |
| BC-7 | Target path is a symlink | After the write, the credential bytes are at the target path in a regular file at `0600`, and no credential byte is written through the link to its destination (DECISION-6). |
| BC-8 | Target path is a directory | Loud failure per behaviour 5; nothing is written. |
| BC-9 | Disk full mid-write / read-only filesystem | Previous content byte-identical; loud failure; no leftover at a wider mode. |
| BC-10 | Process killed (SIGKILL) mid-write | Previous content byte-identical. Any temporary object left behind is at `0600`, so it is litter, never an exposure. No sweeper for foreign leftovers is required (NG-11). |
| BC-11 | Two `sc` processes regenerate concurrently (realistic: the weekly `sing-box-rules-update.timer` and a user command) | Behaviour 7. Neither may observe or produce a wider mode. |
| BC-12 | Very large configuration (hundreds of nodes) | No size limit is introduced; the atomic path must tolerate a document large enough that two copies exist transiently. |
| BC-13 | `install.sh` sweep: configuration directory absent | Each credential-bearing file is reported absent (behaviour 13); the section prints and the run continues. |
| BC-14 | `install.sh` sweep: file present but `chmod` fails | Behaviour 14. Under `set -euo pipefail` the failure must not abort the run (E-13). |
| BC-15 | `install.sh` sweep: file already `0600` | Reported OK; no `chmod` is issued and no mode changes. Re-running the installer must remain idempotent for the sweep as for everything else. |
| BC-16 | `install.sh` sweep on a host where step 7 failed | The section still runs and still reports (behaviour 11); it does not change which banner `install_report()` selects. |

---

## 5. Acceptance criteria

All criteria are checkable by an agent with a temp-dir fixture root and **no root**. Module-level
path constants in `bin/sc` are only referenced inside function bodies (`docs/dev-map.md` "Paths"
row), so a harness repoints them after import; the auto-elevate block must be neutralised first
(§7). `generate_config()` does not call `_init_files()`, so the hard-coded `/var/lib/sing-box`
(`bin/sc:309`) is not on the path under test — but any harness that drives another command must
still account for it.

**`bin/sc` — surfaces 1 and 2**

- **AC-1** With the fixture configuration directory empty, generating the configuration produces
  `config.json` at mode exactly `0600`. Saving the node store from empty produces `nodes.json` at
  mode exactly `0600`.
- **AC-2** AC-1 holds identically under each of umask `0o000`, `0o022`, `0o077`, `0o277`.
- **AC-3** With `config.json` pre-created at each of `0644`, `0664`, `0666`, one generation leaves
  mode exactly `0600` **and** the newly generated content. Same for `nodes.json` and one save.
- **AC-4** With the write suspended at the last instant before the new content becomes visible at
  the target path, and running under umask `0o000`: every regular file in the fixture
  configuration directory has mode `0600` or narrower, and no file there carries any group or
  other bit. This is the criterion that distinguishes "narrow at the end" from "never wide".
- **AC-5** At the suspension point of AC-4, with a pre-existing `config.json` in place, that
  pre-existing file is byte-identical to its pre-run content.
- **AC-6** With the target directory made unwritable (or an OSError injected at the install step),
  the pre-existing `config.json` is byte-identical to its pre-run content, nothing in the
  directory has a mode wider than `0600`, and AC-8's message is produced.
- **AC-7** When `sing-box check` (a stub binary in the fixture) exits non-zero, `config.json`
  contains the newly generated content and is at mode `0600`, and generation reports failure —
  i.e. E-12's behaviour is unchanged.
- **AC-8** The failure of AC-6 prints exactly one line on stderr, in the active language, naming
  the path and the operating-system cause; stderr contains no `Traceback`; `sc reload` exits
  non-zero.
- **AC-9** Two generations driven concurrently against one fixture leave `config.json` parseable
  and equal to one of the two documents, at mode `0600`, with no leftover at a wider mode.
- **AC-10** After a successful generation, the set of files in the fixture configuration directory
  equals the set that existed before plus `config.json` — no temporary survives.
- **AC-11** With `config.json` pre-created as a symlink to another path inside the fixture: after
  generation, `config.json` is a regular file at `0600` containing the new document, and the link
  destination's content is byte-identical to its pre-run content.
- **AC-12** Over a full generation driven in the fixture, no file outside the fixture root is
  created or modified. (This is both a correctness and a safety criterion — §7.)

**`install.sh` — surface 3**

- **AC-13** The permission section prints one line per credential-bearing file, each naming the
  path and the mode, after the last install step and before the closing banner; the banner remains
  the final output.
- **AC-14** The section prints on a run where the config phase failed and on a run where it
  succeeded, with the same shape.
- **AC-15** A fixture file at `0644` is reported as repaired, its line names both the old and the
  new mode, and its mode afterwards is `0600`. A fixture file at `0600` is reported OK, and its
  mode and mtime are unchanged. A fixture file at `0400` is reported OK and is **not** widened.
- **AC-16** A missing credential-bearing file yields an "absent" line, no file is created, and the
  section does not classify the run as having a permission problem.
- **AC-17** With the mode change forced to fail, the section prints a problem line naming the file
  and its current mode, and execution continues past the section (proved by observing output
  emitted after it) rather than terminating under `set -euo pipefail`.
- **AC-18** The whole section is exercisable against a temp-dir fixture root by an unprivileged
  user without touching `/etc`: the root it sweeps is expressed in one place and can be redirected
  for verification. (Testability requirement; the mechanism is stage 2's.)
- **AC-19** `settings.json`, `rules/*.srs` and the configuration directory itself are neither
  reported nor modified by the section.
- **AC-20** The installer's exit status and the banner selection are byte-for-byte the function of
  `PHASE_CONFIG` / `PHASE_SERVICE` they are today, for both a passing and a failing sweep.

**Bilingual parity**

- **AC-21** Every new `install.sh` string has a key in **both** `case` blocks with the same
  `printf` specifier set; `.harness/scripts/check-i18n-parity.sh install.sh` exits 0; and, as a
  guard against the known B.2 blind spot (`docs/tasks.md` R-7 — a broken `LANG_CHOICE` dispatch
  makes the gate render the **en** table twice and still print `OK`), the two renderings of at
  least one new key are shown to differ from each other.
- **AC-22** Every new `bin/sc` user-facing string is an English sentence used as the translation
  key, with a `zh` entry carrying the identical placeholder set; no new string contains `failed:`
  or `失败：` (`.harness/insight-index.md` — that literal is a load-bearing diagnostic grep meaning
  "this file was not updated"). Both `sc lang en` and `sc lang zh` render every new string.

**Non-regression**

- **AC-23** `.harness/scripts/verify_all` PASSes with zero delta in PASS/WARN/FAIL/SKIP counts
  against a pristine **clone** of `HEAD` (never a `git worktree` — `.harness/insight-index.md`).
- **AC-24** `sc doctor`'s output is unchanged in both languages: same seven sections, same rows,
  no permission row (NG-2).
- **AC-25** `README.md` and `README.zh-CN.md` state `config.json`'s mode alongside the existing
  `nodes.json` mode-600 statements (`README.md:191, :217` and mirrors), and `CHANGELOG.md` gains a
  zh entry. The two READMEs stay line-for-line mirrors.
- **AC-26** No syntax or standard-library API newer than Python 3.6 is introduced in `bin/sc`, and
  no third-party import. Pre-existing `capture_output=` violations are not touched
  (`docs/dev-map.md` "Patterns to follow").
- **AC-27** `install.sh` remains idempotent: a second run leaves `nodes.json` and `settings.json`
  content untouched, and the sweep is a no-op on the second run (BC-15).

---

## 6. Non-functional requirements

- **NFR-1 (security, the whole point).** The guarantee is on the **end state at every instant**,
  not on any API. Three facts a design must satisfy simultaneously: a mode argument at creation is
  masked by umask (BC-2); a mode argument is ignored for an existing file (BC-3); and a chmod
  applied after content is written leaves a window (the defect). A design that satisfies only two
  of the three does not satisfy the requirement.
- **NFR-2 (atomicity is not traded away).** In-scope behaviour 4 is additive: `config.json` is not
  atomic today (E-11), and the project already owns the pattern at `bin/sc:1632`. Restrictive mode
  and atomic replacement must both hold; a design achieving one at the other's expense is
  rejected (DECISION-1).
- **NFR-3 (loud failure).** Owner through-line. Every failure on these paths states, in the active
  language, what failed and on which path. Silence, a bare traceback, and a silently-repaired
  problem are all defects.
- **NFR-4 (compatibility).** Python 3.6+, standard library only, in `bin/sc`. Bash under
  `set -euo pipefail`, single self-contained file, in `install.sh` (it is served over
  `curl | bash`). Both systemd and OpenRC hosts; the sweep must not assume systemd.
- **NFR-5 (performance).** Non-material. The added work is at most one extra file creation and one
  rename per regeneration, and a handful of `stat`s per install.

---

## 7. Safety constraints — binding on every downstream stage

Stated here so the constraint is inherited rather than rediscovered.

1. **Never write, chmod, move or back up anything under `/etc` on this machine.** Every
   verification uses a temp-dir fixture root. `/etc/sing-box/` is the live configuration of the
   owner's running VPN.
2. **Neutralise `bin/sc`'s import-time auto-elevate block in every harness and every throwaway
   script.** `.harness/insight-index.md` records a real incident: a test script that imported
   `bin/sc` re-exec'd the **installed** `/usr/local/bin/sc` under sudo and restarted the owner's
   live sing-box, and sudo's `env_reset` silently dropped the environment override that was
   supposed to redirect paths. Neutralise the *sudo re-exec* specifically — `cmd_uninstall`
   legitimately calls `os.execvp("bash", …)` (`docs/dev-map.md`).
3. **A redirected-paths harness is not automatically safe.** `_init_files()` hard-codes
   `/var/lib/sing-box` (`bin/sc:309`) while every other path is a repointable module-level
   constant. `generate_config()` does not reach it; any harness driving another command does.
4. **Never test against the installed `/usr/local/bin/sc`** — it is an older build that diverges
   from the repo (E-14).
5. **Never execute `install.sh`.** Precedent: T-11 verified installer changes without ever running
   the script (`docs/tasks.md` T-11 row). Hence AC-18.
6. **Never restart or reload the live service.** If a service state must be witnessed, use
   `systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active`
   (`.harness/insight-index.md`).

---

## 8. Decisions taken under standing authority

Each records the candidates, the chosen answer, the reasoning, and what would overturn it.

**DECISION-1 — Atomic replacement of `config.json` is in scope.**
Candidates: (a) mode only, keep the in-place truncating write; (b) mode **and** atomic
replacement. **Chosen: (b).** E-11 shows atomicity does not exist for `config.json` today, so
"preserve it where it exists" does not settle the question. The dispatch is explicit that the file
must be both atomically replaced and never world-readable. Two independent supports: the only
construction that satisfies BC-2 *and* BC-3 *and* behaviour 3 at once is "build the content in a
fresh object that is restrictive from creation, then install it at the target", which produces
atomicity as a by-product rather than as extra scope; and the project already owns this pattern at
`bin/sc:1632`, so this is reuse, not invention. *Overturned by:* a design that meets NFR-1 in full
without a second object, at lower risk.

**DECISION-2 — `nodes.json` is in scope; `settings.json` is not.**
Candidates: (a) `config.json` only, as the brief names; (b) `config.json` + `nodes.json`;
(c) every file under `/etc/sing-box/`. **Chosen: (b).** `nodes.json` has the byte-identical
write-then-chmod shape in two places (E-4) and is the *primary* credential store — fixing
`config.json` alone ships the identical hole in the more sensitive file and guarantees a second
edit to the same code, which is exactly the patch-then-patch seam `.harness/rules/85-design-discipline.md`
forbids, and "write a credential-bearing document safely" is one judgment, not two. `settings.json`
is excluded because it carries no credential (E-5) and narrowing it is a user-visible change
nobody asked for. *Note for the pool, not a requirement:* `settings.json` being world-readable
discloses `clash_api_port`, and the Clash API listens on loopback with no secret
(`bin/sc:1004`) — but the port is discoverable by `ss -ltnp` regardless, so its mode is not the
control. Re-homed as an observation, not fixed here. *Overturned by:* evidence that a documented
workflow reads `settings.json` as a non-root user (which would also make narrowing it a breaking
change), or evidence that some field in it is a secret.

**DECISION-3 — The installer's sweep repairs by narrowing, and says exactly what it did.**
Candidates: (a) report only; (b) repair silently; (c) repair by narrowing only, printing one line
per file naming old and new mode, and reporting loudly anything it could not repair.
**Chosen: (c).** (b) is excluded outright — silently changing permissions on a user's system is
itself a decision, and the owner's through-line is that failures are loud. Between (a) and (c):
report-only leaves a known, named credential exposure in place on a run that then prints
"✅ Install complete", which is the kind of banner/reality disagreement T-01 exists to prevent;
and per E-14 the legacy host is *the* population this surface exists for, so a sweep that cannot
repair it does not close the case the report opened. The installer already runs as root and
already sets modes on files it owns (`install.sh:405, 412, 442-444, 468, 476`), so narrowing a
credential file it created is within its established remit rather than a new power. "Narrowing
only" is what keeps this from being the silent-widening hazard: the sweep can only ever remove
access. *Overturned by:* a user workflow that depends on a wider `config.json` — which is T-14's
subject, and T-14 is where such an intent should be expressed, not in a hand-chmod that an
installer run silently undoes.

**DECISION-4 — Mode only; no ownership check, no `chown`.**
Candidates: (a) mode only; (b) mode + report owner; (c) mode + `chown root:root`. **Chosen: (a).**
Every writer of these files runs as root, so a non-root owner is not producible by any of the
tool's own paths; acting on ownership means the installer taking a second kind of authority over
files it did not create. Re-homed to T-20's permission audit, which is the row that owns a full
audit. *Overturned by:* an observed host where a credential file is owned by a non-root user.

**DECISION-5 — The sweep does not change the installer's exit status or banner.**
Candidates: (a) a permission problem makes the install report failure; (b) the sweep reports
independently and leaves `install_report()`'s derivation untouched. **Chosen: (b).**
`install_report()` derives banner and status from `PHASE_CONFIG` / `PHASE_SERVICE` and nothing
else (`install.sh:243-246`), and that single derivation is T-01's central guarantee; folding a
permission finding into it would make the banner say "the service is not running" when the service
is running fine. The sweep's loudness is carried by its own lines (behaviours 12 and 14), which is
what NFR-3 asks for. *Overturned by:* an owner ruling that an unrepairable credential exposure
should fail the install outright.

**DECISION-6 — Replacing a symlinked target with a regular file is acceptable.**
Candidates: (a) preserve symlink semantics by writing through the link; (b) install a regular file
at the target path. **Chosen: (b).** A symlinked `config.json` is not a documented setup, writing
through a link is the shape that lets a pre-planted link redirect credential bytes, and (b) is the
natural consequence of DECISION-1's mechanism-independent phrasing. *Overturned by:* evidence of a
user setup that symlinks `config.json`.

**DECISION-7 — `sc doctor` is not touched.**
E-9 settles the scope boundary's conditional: `sc doctor` has no permission reporting today, so
there is nothing to reuse and nothing to duplicate; per the boundary it is left to T-20.
*Seam flagged for stage 2, not a requirement:* after this task, `install.sh` will hold the only
statement of "which files are credential-bearing and what mode they must have", and T-20 will want
the same statement inside `sc doctor`. That is a future duplicated judgment under rule 85. It is
**deliberately not built now** — inventing a shared mechanism for a requirement nobody has stated
is the counter-rule's over-build. Stage 2 should note where the single definition would live so
T-20 can converge on it cheaply. *Overturned by:* stage 2 finding a single-definition form that
adds no file, no new concept and no scope.

**DECISION-8 — No committed test suite in this task; the harness is pasted into `06_TEST_REPORT.md`.**
Candidates: (a) commit the project's first Python test harness for `bin/sc` and wire it into
`verify_all` B.3; (b) build a throwaway harness and paste it, as every prior task has.
**Chosen: (b) — and this is the weakest decision in this document.** It is the **fourth**
occurrence of `.harness/rejected-decisions.md` § `ruleset-unit-tests-in-t02`, whose own text says
"the next one should probably widen its own diff instead". The reasoning for deferring once more:
the fixture this task needs (repointed path constants, a neutralised auto-elevate block, a stubbed
`sing-box`) *is* the project's first `bin/sc` test harness, i.e. a genuine design; doing that
design inside a security fix couples two unrelated risks, and the safety incident in
`.harness/insight-index.md` is a direct warning about getting that harness wrong. *Overturned by:*
the gate reviewer ruling that a committed harness is cheap enough here — in which case it should
be ruled at stage 2/3, not smuggled in at stage 4.

---

## 9. Related tasks

- **T-05 `sc-doctor`** (`docs/features/_archived/sc-doctor/`) — establishes the reporting idiom and
  the "never form a second opinion" discipline. E-9 settles that it does not report permissions.
- **T-02 `config-degrade-missing-rulesets`** (`docs/features/_archived/config-degrade-missing-rulesets/`)
  — owns `generate_config()` and the atomic temp-then-replace pattern (`bin/sc:1632`) this task
  reuses. Its degradation logic must not change.
- **T-11 `install-version-query-abort`** (`docs/features/_archived/install-version-query-abort/`) —
  owns `install.sh` failure reporting, the "the installer always states its outcome" contract, and
  the `verify_all` B.2 parity gate that now gates this task's new strings (including its blind spot,
  R-7).
- **T-08 `install-binary-download-progress`** — `install.sh` diff discipline precedent; verified
  installer behaviour without ever running the installer.
- **T-01 `install-enable-start-split`** — `install_report()`'s single derivation, which DECISION-5
  preserves.
- **Open rows this task deliberately does not absorb:** R-3 (the wider `install.sh` silent-abort
  class), R-5 (`fail_download()` helper), R-6 (`verify_all.ps1` B.2 divergence), R-7 (B.2 blind
  spot). All in `docs/tasks.md`.
- **Observations re-homed by this stage, not fixed here:** `settings.json`'s world-readable mode
  (DECISION-2); `bin/sc:1667` prints "config regenerated" unconditionally even when the
  regeneration it just ran returned failure (an honesty defect on T-02/T-10's surface, not this
  one).

---

## 10. Verdict

**READY.**

No blocking question remains: every ambiguity in the dispatch was resolved as DECISION-1…8 under
standing authority, each with the reasoning and the condition that would overturn it. No safety
red line was reached — this stage read only, and §7 carries the constraints forward.

Two findings that change the brief's framing, stated plainly for the record: the reporter's root
cause is **false** for current code and the owner is **right**, but the exposure window is at first
**creation** only (not at every regeneration) and a legacy 0644 file self-heals on the first
regeneration by any current build — which narrows the reporter's observation to a version-skew
explanation and makes surface 3 the part that actually reaches that host (E-14). And the credential
set contains no reality *private* key; this is a client (E-3). One scope change was made on
evidence: `nodes.json` carries the identical defect and is in scope (DECISION-2).
