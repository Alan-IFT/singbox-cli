# 02 — Solution Design — ruleset-update-no-needless-restart (T-10)

- **Task ID**: T-10 · **Mode**: full · **Date**: 2026-07-31 · **Deferred-human mode**: `defer, do not ask`
- **Upstream**: `docs/features/ruleset-update-no-needless-restart/01_REQUIREMENT_ANALYSIS.md` — verdict `READY`
- **Verdict**: `READY`
- **Rev. 2 (gate C-1)**: compacted (cite, don't paste); accuracy fixes §2.2 F-4(c)/F-1 and §2.3 frequency; gate
  C-5 + F-10 folded into §4. **No decision, boundary answer, risk, gate or ordering step was dropped.**
- **Partition assignment**: omitted — `.harness/agents/dev-*.md` does not exist (single-developer
  project, `.harness/rules/50-singbox-cli.md` §Partitioning). Confirmed by glob, not assumed.
- Repo root for every relative path below: `/home/alan/Programs/singbox-cli`.

## 1. Architecture summary

`sc update-rules` stops treating "the run finished" as "something changed". The single on-disk rule-set
observation T-02 built (`bin/sc:492-546`) is deepened by one field: `ruleset_state(path)` returns
**`(status, digest)`** from **one** read, so the run's before/after snapshots answer two questions — *which
rule-sets became usable* (`gained`, drives config regeneration) and *which usable rule-sets' bytes really changed*
(drives the apply) — from the same bytes, with no second opinion of what is on disk. `ruleset_report()` keeps its
exact T-02 contract as the status-only view of that snapshot, so `generate_config()`, `usable_tags()` and
`_warn_degraded()` are untouched. `cmd_update_rules()` loses its unconditional
`if not applied and is_running(): restart_service()` tail (`bin/sc:1141-1143`) and gains **one** apply decision
for the whole run, guarded by the change set, plus exactly one truthful run-level outcome line in both languages.
No new file, module or dependency outside the stdlib (`hashlib`); no timeout constant, download loop, stream
split, exit-status contract or generated-config change.

## 2. D-1 closed with evidence — is a non-disruptive apply available?

Requirement §10 D-1 / B-4 binds this stage to *establish* the answer, not to inherit T-02's E-7.

### 2.1 Method and its limits (stated so the conclusion can be audited)

No shell this session: `sing-box version` could not be run and the Clash API could not be queried, not even
read-only. Evidence is (i) static `rg` probes of the **installed** `/usr/local/bin/sing-box` (a Go binary keeps
string literals and pclntab file names under `-s -w`), (ii) repo files, (iii) reasoning, **labelled as such**
wherever it appears. A matching probe is positive evidence; a non-matching one is weak (the guessed literal may be
wrong) and is reported as such. Every probe was independently re-run and confirmed by the gate
(`03_GATE_REVIEW.md:36-46`).

### 2.2 Findings

**F-1 — the sing-box version is not pinned.** `install.sh:352-357` resolves `tag_name` from `.../releases/latest`
**at install time**, so hosts installed on different days run different versions. This host is **≥ 1.12**
(`anytls` 30 lines, `tailscale` 257); the exact version could not be extracted (`constant.Version=`, `-ldflags` →
no match; the release build carries no readable build-settings blob). **Deliberately not load-bearing** (gate F-4
ruling): "a capability of one version is unsound for the fleet" holds only for capabilities that *cannot be probed
at run time*, and both `sing-box version` and Clash `/version` are probeable per host. Context only — the reasons
the design rests on are the three in §2.3.

**F-2 — the Clash API cannot apply changed rule-set data. T-02's E-7 is CONFIRMED, not inherited.** `sc`'s client
(`bin/sc:850-861`) is used for `PUT /proxies/proxy` (`bin/sc:933`) and mode switching only. The binary has the
route `/providers/rules` (1 match) but **neither** `ruleCount` (0) **nor** `vehicleType` (0) — the two payload
fields a Clash-Meta rule-provider response is made of — and no "…not a remote rule-set…"-shaped update error. Read
together: a dashboard-compatibility stub, not an update channel for a `type: local` rule-set; no endpoint makes a
changed `.srs` effective.

**F-3 — SIGHUP reload exists but is neither connection-preserving nor portable; rejected.**
`systemd/sing-box.service:10` ships `ExecReload=/bin/kill -HUP $MAINPID`; the binary carries
`cmd/sing-box/cmd_run.go` and the literal `reload service`. *Reasoning (not measured):* that branch closes the
running box instance and creates a new one in-process, so inbounds, outbounds and every established connection go
down exactly as in a restart — only the process spawn is saved. Independently it fails **B-12**: the OpenRC
service (`install.sh:412-431`) defines no `reload()`, and `sc` does not know `$MAINPID`. Rejected — no benefit, less portable.

**F-4 — sing-box itself watches local rule-set files, but that cannot be *this run's* evidence.** The binary
contains the watcher: pclntab `route/rule/rule_set_local.go`, the log literals `watch rule-set file`
(watcher-start failure) and `reload rule-set ` (reload-callback failure), and `github.com/sagernet/fswatch` over
`fsnotify` (39 lines). So on *this* host a replaced `.srs` is very likely picked up in place, and *by reasoning*
at no cost to connections: a rule-set is consulted while a connection is being routed, so swapping matcher data
affects future matches only. Four things could **not** be established. **(a)** Whether the watcher survives our
**atomic rename-over-replace** (`bin/sc:1107` `tmp.replace(target)`) — inode vs. directory entry, which the
strings do not reveal; **load-bearing, §2.3(3)**. **(b)** Whether the watcher actually started in the *running*
process — its failure path is warn-level and non-fatal, so a host where it failed is externally
indistinguishable. **(c)** Whether any success line belongs to the **local-file** path: `reloaded rule-set` is
absent (0 matches), **but `updated rule-set ` and `rule-set updated` are each present (1 match each)**, alongside
`route/rule/rule_set_remote.go` — so a success literal *does* exist in this binary; what strings alone cannot
establish is that it is emitted on the local-file path. *(Corrected: rev. 1's "no evidence channel at all" was
overstated — gate F-4 ruling. The corrected statement is weaker, which is exactly why §2.3 rests on three other
grounds.)* **(d)** Whether other hosts' versions have it (F-1 — context only).

### 2.3 Conclusion (adopted)

**B-4 resolves to (a): restart, honestly reported — but only when a rule-set's installed bytes really changed.**
B-4/B-5 permit a non-disruptive mechanism only when *the run has evidence that it succeeded*. F-2 and F-3 remove
the first two candidates outright. The watcher (F-4) is unusable as the third on three grounds, none of which
depends on what the binary is able to print:

1. **Our own config closes the log channel.** `generate_config()` emits `"log": {"level": "warn"}` (`bin/sc:746`),
   so any Info-level success line is never written on this project's hosts — independent of binary capability.
2. **B-12 forbids a systemd-only oracle.** Reading a journal has no OpenRC counterpart, and `sc` contains no
   log-reading code at all.
3. **F-4(a) is independently fatal.** Whether fswatch survives `tmp.replace(target)` (inode vs. dirent) is
   undetermined, so even a perfect oracle would not tell us the right thing happened for *our* write pattern.

Claiming "applied without restarting" on the strength of a watcher we cannot observe would be exactly the
forbidden D-1 candidate (c). **AC-19 is therefore not-applicable for this task, for the reason recorded here**
(requirement §7 anticipates this wording); AC-18's "the restarted wording is absent from every run in which no
restart was issued" still applies in full and replaces it. **The design is robust to the one fact it could not
verify:** if the watcher works our restart is redundant but correct, if it does not our restart is the only thing
that makes the new rules effective — neither branch makes the shipped output dishonest.

**Frequency is deliberately not part of the argument.** `.harness/insight-index.md:15` establishes that the four
mirrors serve content byte-identical **to each other** at one instant; it does **not** establish week-over-week
stability of the upstream MetaCubeX rule-sets. This design therefore claims nothing about how often a run is a
no-op, and needs nothing: a write-based signal ("the request returned 200", mtime, "a file was replaced") is wrong
on **every** successful run regardless of frequency, and a content-based signal is right on every run regardless of
frequency. If real changes are frequent, no decision changes — only the value of the deferred watcher work goes up.

**Follow-up (not this task, no scope taken).** If the project ever pins a minimum sing-box version in
`install.sh`, "do nothing and let the watcher reload" becomes decidable and would remove the remaining restarts.
Needs (i) a version floor and (ii) one observed rename-replace experiment on a **disposable** host (never the live
one — NFR-1). Recorded as a `deferred` decline (`.harness/rejected-decisions.md` →
`trust-singbox-fswatch-ruleset-reload`) and suggested to PM as a pool row.

## 3. Affected modules

| Path | Change |
|---|---|
| `bin/sc` | Only production file touched. `import hashlib` (`:3-14`); `# Rule-sets` section — `ruleset_status` body becomes `ruleset_state` + three small functions (`:512-546`); `cmd_update_rules` apply tail (`:1082`, `:1127-1144`); `TRANSLATIONS["zh"]` (`:84-162`), 3 keys. |
| `CHANGELOG.md` | `:15` corrected (E-10 / B-16 / D-9) + one new `### 修复` bullet. |
| **Not touched** | `install.sh`, `uninstall.sh`, `systemd/*`, `README*.md`, `docs/*`, `CONTEXT.md`, `.harness/scripts/*`, every timeout constant, the download loop (`bin/sc:1085-1125`), `generate_config()`, `_filter_rules()`, `restart_service()`, `is_running()`, `clash_api()`. |

Pipeline bookkeeping written by the stages themselves (`docs/features/**`, `.harness/rejected-decisions.md`) is
outside AC-22's **product** diff — T-02 precedent (`_archived/config-degrade-missing-rulesets/02_SOLUTION_DESIGN.md:40-41`).
QA asserts the product diff is `bin/sc` + `CHANGELOG.md`; gate C-8 widens it by exactly one file, `docs/dev-map.md`
(R10). `CONTEXT.md` is deliberately **not** edited: the design does not narrow the glossary's **content-changed**,
it *composes* it — the apply trigger is "content-changed **and** usable after the run", named explicitly in the
code and in §4.4 rather than silently redefining a glossary term.

## 4. Module decomposition

All of it lives in the existing `# ============ Rule-sets ============` section of `bin/sc` (`:492`). No new file,
no new section, no class. Signatures are contracts.

### 4.1 `ruleset_state(path) -> (status, digest)` *(new; takes over `ruleset_status`'s body)*

`status` — exactly one of `"usable" | "absent" | "bad-magic" | "too-small" | "unreadable"`, decided by
`srs_reject_reason()` and by nothing else (the single judgment, B-15). `digest` — sha256 hex of the file's **full**
content, or `None` (contract below). Never raises, never writes; reads in 65536-byte chunks, so memory is O(1) in
file size (BC-15). **Digest contract — binding (gate C-5); the §4.4 invariant depends on it.** State it in the
docstring *and* honour it in the body. Equivalence to preserve: **`digest is None` ⟺ no complete read happened ⟺
`status ∈ {"absent", "unreadable"}`.**

| Situation | Returned |
|---|---|
| file read to EOF with no error | `(status, "<sha256 hex>")` — a REAL digest **always**, including a readable **empty** file: `("too-small", sha256(b"").hexdigest())`, because zero bytes *were* read successfully |
| `OSError` at any point, before or after N bytes | `("unreadable", None)` — **never** a partial digest, which would be a content claim about bytes never fully read |
| absent / directory / dangling symlink / non-regular / EPERM | `("absent", None)` or `("unreadable", None)`, per today's existing branches |

`None` is not a content value — two `None`s are **not** "the same content" (§4.4 relies on `None != None`; do not
"fix" that into equality, it would break BC-6). Body = today's `ruleset_status` (`bin/sc:512-528`) with the
`open()` extended from "read the magic" to "stream the whole file", accumulating `head` (first `len(SRS_MAGIC)`
bytes — reuse the exact accumulation at `bin/sc:693-695`), `size` (the real byte count, replacing `st_size` —
equal in every normal case, strictly more truthful) and a `hashlib.sha256()`. Same `try/except OSError →
"unreadable"`, same symlink / non-regular-file branches, same closing `srs_reject_reason(head, size) or "usable"`.
**No walrus** (3.8; floor 3.6): use the `while True: … if not chunk: break` shape of `bin/sc:687-695`.

### 4.2 The three thin views *(one new, two rewired)*

| Function | Contract |
|---|---|
| `ruleset_status(path)` | Status-only view — `ruleset_state(path)[0]`. The per-file adapter `docs/dev-map.md:46` names. Retained deliberately (§9 R10, D-A-2). |
| `ruleset_states()` | `[(tag, filename, status, digest), …]` for every known rule-set, in `RULESET_FILES` order. **THE snapshot**: `cmd_update_rules` takes exactly one before the run and one after it. |
| `_status_view(states)` | `[(tag, filename, status), …]` projection of a `ruleset_states()` result. |
| `ruleset_report()` | **UNCHANGED CONTRACT** — `[(tag, filename, status), …]`; now `_status_view(ruleset_states())`. |

`usable_tags(report)` (`bin/sc:544-546`) is **unchanged** and still takes 3-tuples, as does `generate_config()`,
which destructures them at `bin/sc:804` — hence `_status_view`, whose three call sites (`ruleset_report` + the two
snapshots in `cmd_update_rules`) earn it. `ruleset_status()` keeps zero in-tree callers after this change.

### 4.3 Why the digest lives inside the existing query (D-2, rule 85)

D-2 asked whether `gained` and content-change are one concept or two. **Adopted: two facts, one query** — stage
1's shape, kept, because they drive different consequences (`gained` changes what `config.json` *contains*; a
content change does not touch the config at all) but are both pure functions of the *same bytes we are already
reading*. A separate `ruleset_digest(path)` would be a second reader with its own symlink / EPERM /
non-regular-file handling — the duplicated-judgment failure rule 85 test 2 names, and the "second notion of what
is on disk" B-15 forbids. **Deletion test:** delete `ruleset_state` and the file-shape handling reappears in two
places with two chances to disagree about the same file.

### 4.4 `changed_usable_tags(before, after)` — the apply set *(new, pure)*

Both arguments are `ruleset_states()` results. Returns the **sorted list of tags** that are `usable` in `after`
**and** whose digest differs from that tag's digest in `before`; empty when no rule-set's content changed. Pure:
no I/O, no globals. **Pair by tag, never by list index (gate F-10):** build `{tag: (status, digest)}` dicts from
both snapshots and compare per tag (a tag absent from either dict = `(absent, None)`); positional pairing happens
to work today because both snapshots iterate `RULESET_FILES`, and becomes a silent mis-pairing the moment that
tuple changes. **The `usable in after` half is not decoration:** a rule-set corrupted or deleted mid-run by an
external actor is a LOSS, not a change, and restarting *for it* would make sing-box re-read a file it cannot parse
— the T-02 start-up failure, re-created. Whatever we restart **for**, we restart only for a file sing-box will
actually load. (Precise scope of that claim: §9 R9.)

Boundary-condition trace (requirement §6): BC-1 identical bytes → empty ✓ · BC-2 one differs → that tag ✓ · BC-3
equal size, different content → digest differs ✓ · BC-4/BC-5 absent/bad → usable → digest `None`/old vs new ✓ ·
BC-6 unreadable before, installed now → `None` vs digest ✓ · BC-7 unreadable before, nothing installed → `None` vs
`None`, and not usable after → excluded ✓ · BC-13 deleted mid-run → not usable after → excluded ✓ · BC-15 →
chunked, O(1) memory ✓ · BC-16 empty rule-set list → empty ✓ · AC-6 mtime touched only → same digest → excluded ✓.

**Invariant (AC-7/AC-8 depend on it): `gained ⊆ changed_usable_tags(before, after)`.** A gained tag is usable in
`after` (so its digest is not `None`, by C-5); in `before` it was not usable, so either it was unreadable/absent
(`digest is None`, differs) or it was readable with a different status — and status is a pure function of the
bytes, so equal bytes would have given an equal status. Hence its digest differs. *Consequence:* one apply covers
recovery and content change; AC-4's "exactly one apply action per run" is structural, not a discipline. **The
invariant is only as strong as the C-5 contract**: an implementation that returns `None` for a readable empty
file, or a partial digest after a mid-read `OSError`, breaks it.

## 5. Data model

No database, no persisted state, no new settings key, no config-shape change. In-memory only:

| Before | After |
|---|---|
| `ruleset_status(path) -> str` | `ruleset_state(path) -> (str, str_or_None)`; `ruleset_status` becomes its first element |
| `before = usable_tags(ruleset_report())` — a `set` (`bin/sc:1082`) | `before = ruleset_states()` — a list of 4-tuples; the usable set is derived from it |
| second `ruleset_report()` at `bin/sc:1127` | `after = ruleset_states()` — same count of disk passes as today (two), each now carrying both facts (NFR-3 ✓) |

**Digest choice (D-3 → (a)).** `hashlib.sha256`, chunked at 65536 bytes (the chunk size `_fetch_to_temp` already
uses, `bin/sc:688`). Over (b) "keep the pre-run bytes in memory": equal in correctness, worse in memory — BC-15
explicitly asks that memory not scale with file size. Over md5: `hashlib.md5` raises under a FIPS-enabled OpenSSL;
sha256 never does. (c) mtime/size is forbidden by B-1 and already recorded as declined
(`.harness/rejected-decisions.md` → `mtime-or-size-as-a-ruleset-change-signal`). **New dependency:** `hashlib` —
stdlib, Python 3.6 ✓, no wheel, no network, no new privilege; the only import added.

## 6. Contracts

### 6.1 CLI surface

Unchanged: `sc update-rules [--mirror URL]…`, same arguments, same help text, same `SB_RULES_BASE` handling.
**Exit status unchanged** (D-6 → 0 on a no-op run): non-zero iff at least one rule-set failed to update, via the
existing `sys.exit` (`bin/sc:1140`), which `install.sh:456` branches on.

### 6.2 Stream contract (preserved verbatim)

| Stream | Content |
|---|---|
| stdout | `  ↓ <file> … ` prefix, TTY redraws, one completion line per rule-set, `Rule-sets restored…`, `→ Restarting sing-box ...`, **the new run-level outcome line**, `Done` |
| stderr | aggregate `{n} ruleset(s) failed to update`, degradation warning, `⚠️ Config check failed` |

The outcome line is a **run-level** line (like `Done`), so T-02's B-19/AC-15 "exactly one completion line per
rule-set, no `\r` on a pipe" is untouched, and T-01's install-log consumer sees the same per-file shape. D-5
adopted: it prints on the scheduled/non-TTY path too — the timer journal and `/var/log/sing-box/install.log` are
the only record a scheduled run leaves.

### 6.3 The run-level outcome (B-10) — a closed set of three

Printed **exactly once per run**, unconditionally, immediately before the `if failed: sys.exit(…)` line, so a run
that ends non-zero still states what it did to the service (BC-8/BC-9).

| Case | Line |
|---|---|
| nothing changed | `No rule-set changed — the sing-box service was not touched` |
| changed + restart issued | `Rule-sets updated: {names} — sing-box restarted to load them` |
| changed, service not touched (stopped / no `config.json` / regeneration failed its check) | `Rule-sets updated: {names} — the sing-box service was not touched` |

`{names}` is the comma-joined `changed_usable_tags` result (tags, matching the existing `Rule-sets restored:
{names}` style). The third wording is true in all three of its sub-cases: it claims only that the **service** was
not touched — a failed regeneration did write `config.json` and already said so on stderr via `generate_config()`.
**D-7 adopted:** the existing `→ Restarting sing-box ...` key stays, with its existing leading `"\n"`
(`bin/sc:1136`, `:1142`) — the known stray-blank-line follow-up is neither fixed nor worsened here; it is now
printed from **one** site instead of two.

### 6.4 New `TRANSLATIONS["zh"]` keys (B-11 / AC-14 / AC-15)

Placeholder sets identical in both languages. `TRANSLATIONS` has no `en` table, so the English key *is* the
English output — full sentences, never namespaced (`ls.idx` is a defect, not a pattern).

| English key | zh |
|---|---|
| `"No rule-set changed — the sing-box service was not touched"` | `"规则集内容无变化 —— 未改动 sing-box 服务"` |
| `"Rule-sets updated: {names} — sing-box restarted to load them"` | `"规则集已更新：{names} —— 已重启 sing-box 以加载新数据"` |
| `"Rule-sets updated: {names} — the sing-box service was not touched"` | `"规则集已更新：{names} —— 未改动 sing-box 服务"` |

**zh collision audit (the T-02 R10 discipline, mandatory):** none of the three contains `失败：` (E-15, the
load-bearing "this file was not updated" grep), nor `失败`, nor `成功` (which would make a run-level line match the
`OK ({size} bytes)` → `成功（… 字节）` per-file grep), nor `错误：`, nor `⚠️`. `更新` is shared with `"{n} 个规则集更新失败"`
(stderr) and `"规则集自动更新…"`, but the distinguishing prefixes `规则集已更新：` and `规则集更新失败` do not collide under any
grep a human would write. `规则集已恢复：` (T-02) stays distinct. `未改动` is new and unique. Gate re-ran it
independently: CLEAN (`03_GATE_REVIEW.md:163`). Reused unchanged: `"Rule-sets restored: {names} — config
regenerated"`, `"→ Restarting sing-box ..."`, `"Done"`, `"OK ({size} bytes)"`, `"failed: {e}"`,
`"{n} ruleset(s) failed to update"`.

### 6.5 `CHANGELOG.md` (B-16 / D-9) — exact edits, do not improvise

1. **Correct `CHANGELOG.md:15`.** Replace the clause
   `注意这条命令在 sing-box 正在运行时会重启 sing-box（连接会中断几秒）` with
   `注意这条命令只有在规则集内容确实发生变化时才会重启 sing-box（那几秒连接会中断）；内容没变时不会碰服务`.
   Nothing else on that line changes. (`CHANGELOG.md:11`, T-02's entry, stays true — no edit owed.)
2. **Add this bullet under `## [Unreleased]` → `### 修复`**, one physical line like its neighbours (gate-checked
   against C-9: it claims nothing about how often rule-sets change):

```
- **规则集更新不再无谓重启**：以前 `sc update-rules` 只要跑完就重启 sing-box —— 每周定时任务把四个文件重新下载一遍、内容一个字节都没变，也照样重启，把所有连接（包括远程管理自己的 SSH）断掉几秒。现在每次运行会在下载前后各观察一次磁盘上的规则集，只有当某个规则集的内容真的发生变化（按完整内容比对，不看修改时间、不看文件大小、不看「请求成功了」）时才会重启，并在输出里点名是哪几个规则集变了；内容没变就完全不碰服务。规则集从不可用变为可用时，仍然会重新生成配置并（在服务正在运行时）重启，行为与之前一致。每次运行的最后一行都会如实说明这次到底动没动服务。
```

## 7. Flow — `cmd_update_rules(args)` (`bin/sc:1078-1144`)

```
bases = _ruleset_bases(...); tty = sys.stdout.isatty()      # unchanged
before = ruleset_states()                        # was: usable_tags(ruleset_report())
for fname, relpath in RULESET_FILES: ...         # ── DOWNLOAD LOOP bin/sc:1085-1125: NOT TOUCHED ──
after   = ruleset_states()                       # was: ruleset_report()
gained  = sorted(usable_tags(_status_view(after)) - usable_tags(_status_view(before)))
changed = changed_usable_tags(before, after)     # gained ⊆ changed (§4.4)
restarted = False
if changed and CFG_PATH.exists():                # B-9/BC-11: no config ⇒ never touch the service
    regen_ok = True
    if gained:                                   # B-6: T-02's recovery, unchanged in effect
        regen_ok = generate_config()             # REGENERATED, never patched
        print(t("Rule-sets restored: {names} — config regenerated", names=", ".join(gained)))
    if regen_ok and is_running():                # B-8/BC-10: never starts a stopped service
        print("\n" + t("→ Restarting sing-box ..."))
        restart_service()                        # R6 comment lives here (§9)
        restarted = True
print(<one of the three outcome lines, §6.3>)    # ALWAYS, exactly once, before the exit
if failed:
    sys.exit("\n" + t("{n} ruleset(s) failed to update", n=len(failed)))   # stderr, non-zero
print(t("Done"))
```

Diff reading: `bin/sc:1141-1143` (the unconditional tail) **disappears**; the recovery block at `:1129-1138` is
re-homed under `if changed and CFG_PATH.exists()` with its two inner conditions intact; `:1085-1125` is
byte-identical. **Ordering guarantees:** apply strictly before the non-zero exit (B-14/AC-12, T-02's ordering,
preserved) · config regeneration strictly before the restart · `regen_ok` false ⇒ no restart (a failed
`sing-box check` must never be loaded — today's `if ok and is_running()`, kept) · `is_running()` consulted once,
only after we know something changed. **Delta the developer must record** (gate C-7/F-11): today `sys.exit`
(`bin/sc:1140`) runs *before* the unconditional restart, so a run with any failure never restarts; under B-14's
required ordering "2 changed + 2 failed" now restarts — requirement-sanctioned, and strictly narrower than today
on successful runs.

| Run | changed | gained | config.json | service | Result |
|---|---|---|---|---|---|
| BC-1 weekly no-op (the defect) | ∅ | ∅ | yes | running | nothing at all; outcome (a); exit 0 |
| BC-2 one body differs | {t} | ∅ | yes | running | restart ×1; outcome (b) |
| BC-4/BC-5 recovery | {t} | {t} | yes | running | regenerate + restart ×1; restored line + outcome (b) |
| BC-10 `sc off` | {t} | any | yes | stopped | files installed, no start; outcome (c) |
| BC-11 fresh install (`install.sh:456`) | {…} | {…} | **no** | any | no config, no service action; outcome (c); exit 0 |
| BC-8 all mirrors fail | ∅ | ∅ | yes | running | no service action; outcome (a); existing causes; exit ≠ 0 |
| BC-9 2 changed, 2 failed | {a,b} | ∅ | yes | running | restart, outcome (b), *then* exit ≠ 0 |
| BC-13 file deleted mid-run | ∅ | ∅ | yes | running | no service action (loss ≠ change, D-4/§5.6) |
| BC-19 `--mirror`, identical bytes | ∅ | ∅ | yes | running | no service action |

**B-12 (init systems, interactive vs scheduled).** The new logic is init-agnostic — it consults `is_running()` /
`restart_service()`, which already branch on `SYSTEMD` / `OPENRC` (`bin/sc:834-838`, `:864-870`), so the OpenRC
periodic script (`bin/sc:1217`) behaves identically. Nothing in the new code reads `isatty()`.

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| "Is this rule-set usable?" | `srs_reject_reason(head, size)` | `bin/sc:497-509` | Reuse as the **only** judgment; `ruleset_state` calls it (B-15) |
| One file's on-disk facts | `ruleset_status(path)` | `bin/sc:512-528` | **Extend in place** into `ruleset_state` (same read now also hashes); name kept as the status-only view |
| Ordered per-rule-set report | `ruleset_report()` | `bin/sc:531-541` | Contract unchanged; reimplemented as `_status_view(ruleset_states())` |
| Usable tag set | `usable_tags(report)` | `bin/sc:544-546` | Reuse **unchanged** (3-tuples) |
| Recovery: regenerate + apply | `generate_config()`, `gained` block | `bin/sc:721-831`, `:1129-1138` | Reuse; re-homed under the single apply block, effect identical (B-6) |
| Restart the service | `restart_service()` | `bin/sc:834-838` | Reuse as-is, one call site |
| Service liveness | `is_running()` | `bin/sc:864-870` | Reuse as-is |
| Hot-apply channel | `clash_api()` | `bin/sc:850-861` | **Evaluated and not used** — F-2: no endpoint applies a local `.srs` |
| In-process reload | `ExecReload=/bin/kill -HUP` | `systemd/sing-box.service:10` | **Evaluated and not used** — F-3: not connection-preserving, absent on OpenRC |
| Download / validate / install | `_fetch_to_temp`, `_temp_path`, `_clear_stale_temps`, `_ruleset_bases` | `bin/sc:610-716` | Untouched |
| Chunked read + `head` accumulation | `r.read(65536)` loop | `bin/sc:687-695` | Reuse the idiom and the chunk size; no new constant |
| Bilingual output | `t()` + `TRANSLATIONS` | `bin/sc:84-162`, `:211-213` | Reuse; 3 new keys |
| Exit-status contract | `sys.exit(t("{n} ruleset(s) failed…"))` | `bin/sc:1140` | Reuse verbatim (`install.sh:456` depends on it) |
| Content fingerprint | (none — nothing in the repo compares file contents) | — | New: `hashlib.sha256`, stdlib, chunked (§5) |
| Harness recipe (module load, stubs, fixtures) | T-02 QA harness | `docs/features/_archived/config-degrade-missing-rulesets/06_TEST_REPORT.md` §1, §10 | Reuse and extend (§11) |

## 9. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | **Verification drops the owner's live connections** (NFR-1 — happened in T-02 via a scratch script, E-14). This task is *about* restart behaviour, so the same slip restarts the real service. | §11's gate conditions G-1…G-7 **as strengthened by gate C-2/C-3/C-4**: auto-elevate neutralised in the harness **and every scratch script**, two-layer subprocess denial, process-identity witness, never `/usr/local/bin/sc`. Non-negotiable; carried verbatim into the developer and QA dispatch prompts. |
| R2 | Hashing moves into `ruleset_report()`, so every `generate_config()` (i.e. `sc add / rm / use / mode / reload`) now reads ~2 MB instead of 12 bytes. | Chunked, O(1) memory, ~milliseconds — and `generate_config()` already spawns `sing-box check` (`bin/sc:826`), two orders of magnitude more. Accepted deliberately: one reader beats two cheap-but-divergent ones. If it ever matters, the split goes back *inside* `ruleset_state`, not into a second function. Second-order cost the developer must record (gate C-7/F-7): a file readable at byte 0 but faulting at byte 500 000 is `usable` today and `unreadable` after this change, so `generate_config()` would drop it — more truthful, but a behaviour change on a T-02-owned path. |
| R3 | The new code under-reports a change (bug in the comparator) ⇒ silent staleness: sing-box keeps the old rules with no message. | `changed_usable_tags` is pure and fully table-tested (AC-5, AC-6, AC-13, BC-3/6/7/13); the digest is over the full content, so the only way to miss a change is identical bytes, which *is* "unchanged". F-4's watcher is a second, unrelied-on safety net. |
| R4 | Concurrent runs (timer + manual, BC-14) each observe a different `after`. | Each run reports what it itself observed; worst case is one redundant restart, which is today's behaviour. Temps are already pid-scoped (`bin/sc:622-625`). No crash, no corrupt file. |
| R5 | The outcome line says "restarted" although `restart_service()` runs with `check=False` (`bin/sc:836-838`) and never learns whether the daemon came back. | The line is printed only **after** the call returns, and it claims a restart was *issued* — which is true. Widening `restart_service()`'s contract would change `reload_or_restart()` too and is out of scope; flagged to PM as a pool-row candidate. |
| R6 | A future edit re-introduces the unconditional restart; `verify_all` B.1 is a syntax gate and would not notice (D-8). | Two mitigations inside this task's diff boundary: (i) a load-bearing comment at the apply block naming the defect (`the restart is conditional on changed_usable_tags(); an unconditional restart here is the T-10 defect`), (ii) the whole harness pasted into `06_TEST_REPORT.md` and handed to T-07. §11 states the position; gate C-11 makes both checkable. |
| R7 | A new zh string collides with a load-bearing grep token (T-02's A-2 defect, E-15). | §6.4 audit of all three keys against `失败：` / `失败` / `成功` / `错误：` / `⚠️`; AC-14/AC-15 assert it mechanically; gate re-ran it CLEAN. |
| R8 | Fleet version drift (F-1) makes a version-dependent design wrong on some hosts. | The design depends on **no** sing-box capability beyond "a restart re-reads the rule-set files", true of every version. (F-1 is context, not a load-bearing reason — §2.2.) |
| R9 | An external actor corrupts a rule-set mid-run; a naive "bytes differ ⇒ restart" would make sing-box re-read an unparseable file, re-creating T-02's start-up failure. | The `usable in after` half of `changed_usable_tags` (§4.4) — it prevents a restart **caused by** the loss, matching D-4. **It does not prevent a restart *during* a loss**: if A is lost externally while B changes, the run restarts for B into a `config.json` that still names A (gate F-4). Today's code restarts unconditionally in that situation, so this is no regression on successful runs; the developer records it as a residual (C-7) and PM decides whether it becomes a pool row. |
| R10 | `ruleset_status()` is left with no in-tree caller (dead-code smell). | Kept as a 2-line documented view because `docs/dev-map.md:46` names it as the per-file adapter and T-05 (`sc doctor`) is expected to call it. Gate C-8 widens the diff by that one doc, so the developer makes the keep/delete call **on merit** and records it in `04`; if deleted, `dev-map.md:46-47` is updated in the same commit. |

## 10. Migration / rollout

1. **Backwards compatibility.** No persisted state, no settings key, no config-shape change, no file-mode change,
   no new privilege, no new network endpoint (NFR-5). Upgrade is an `install.sh` re-run or an `sc` replacement.
2. **First run after the upgrade.** Rule-sets already current ⇒ no restart, outcome (a), exit 0 (also
   `install.sh` step 6 on a re-install, BC-12; step 7's `sc reload` is unchanged and still applies the config as
   today). Upstream data really changed ⇒ exactly one restart, as before, now with the changed tags named.
3. **No feature flag.** A `--no-restart` / `--force` flag is explicitly out of scope (§5.7); gating the fix would
   keep the defect reachable.
4. **Rollback.** Restore the previous `bin/sc` and the old unconditional restart returns; nothing on disk was
   migrated, so there is nothing to undo — digests are computed per run, never persisted.
5. **Implementation order** (one commit): `import hashlib` → `ruleset_state` (+ `ruleset_status` view) →
   `ruleset_states`/`_status_view`/`ruleset_report` rewiring → `changed_usable_tags` → `cmd_update_rules` apply
   block → 3 translation keys → `CHANGELOG.md`. `python3 -m py_compile bin/sc` after each step;
   `bash .harness/scripts/verify_all.sh` at the end (AC-20: no new WARN/FAIL against a pristine `HEAD` baseline).
   `py_compile` alone cannot see a 3.7+ construct on a 3.12 host — gate C-6 additionally requires
   banned-construct regexes (`:=`, f-string `=`, new `capture_output=` / `text=`) over the added lines.

## 11. Test strategy — binding gate conditions (NFR-1) and the D-8 position

Fixtures and stubs only; nothing here is advisory. **G-2, G-3 and G-4 are strengthened by gate conditions C-2,
C-3, C-4 (`03_GATE_REVIEW.md:190-192`), which bind in addition to the text below — implement the strengthened form.**

- **G-1 Module load.** Read `bin/sc` as text, blank the auto-elevate `os.execvp` line (`bin/sc:77-78`), `exec` it
  into a namespace, then set `SYSTEMD = OPENRC = False` and repoint `CFG_DIR / CFG_PATH / NODES_PATH /
  SETTINGS_PATH / RULES_DIR` into a temp directory — **before** calling anything, and self-assert all of it
  (C-2's form). T-02 recipe: `_archived/config-degrade-missing-rulesets/06_TEST_REPORT.md` §1.
- **G-2 Subprocess tripwire.** Replace the module's `subprocess.run` with a deny-by-default fake that records argv
  and raises on any call — **plus** T-02's second layer, PATH-prepended `systemctl` / `rc-service` shims writing a
  marker file asserted absent at the end of every script (C-3; one layer alone misses `Popen` / `check_call` /
  `os.system` / `os.execvp` / re-imports). Assertion oracle for AC-1/4/9/12/18. The G-2 ↔ AC-7/AC-8 conflict is
  resolved by stubbing `mod.generate_config` / `mod.is_running`, **never** by whitelisting `sing-box` (C-4).
- **G-3 Scratch scripts are in scope** — the actual T-02 gap. Every throwaway script touching `bin/sc` performs
  G-1 **and** G-2 via **one shared loader**, so the check is a grep over the scratch directory rather than a
  promise; every command runs at non-root euid, `id -u` quoted (C-3). `06` lists every script executed.
- **G-4 Live-service witness.** `systemctl is-active sing-box` before and after the whole run, both readings
  quoted (AC-24) — **and**, because `is-active` reads `active` on both sides of a restart,
  `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp` (OpenRC: pidfile contents) before and after,
  quoted and asserted **identical** (C-2). No step runs `systemctl restart|start|stop`, `rc-service sing-box …`,
  `systemctl start sing-box-rules-update.service`, or `/usr/local/bin/sc`.
- **G-5 Nothing under `/etc/sing-box/**` is written**: assert every written path is under the temp fixture root,
  and observationally quote `ls -la --time-style=full-iso /etc/sing-box{,/rules}` before and after, plus an empty
  `find /etc/sing-box -newermt <stage-start>` at the end.
- **G-6 No network.** Mirrors are loopback `http.server` stubs or a stubbed `_fetch_to_temp`; the stub's request
  log must account for every fetch. No test contacts a real base.
- **G-7 Both languages.** Every assertion over the outcome lines runs twice (`LANG = "en"`, `LANG = "zh"`);
  `LANG` is module state assigned in `main()` (`bin/sc:164`).

Fixture map: AC-1/2/3 ← four identical bodies · AC-4 ← one differing body, tripwire call count == 1 · AC-5 ←
equal-size different-content bodies · AC-6 ← `os.utime` only · AC-7/AC-8 ← absent→usable and bad-magic→usable
(T-02 regressions, re-run unchanged) · AC-9 ← `is_running` stub False · AC-10 ← no `config.json` · AC-11 ←
unreachable bases · AC-12 ← ordered tripwire log · AC-13 ← direct `ruleset_state()` calls on missing / directory /
dangling-symlink / chmod-000 / 0-byte / short-file fixtures (C-5) · AC-14/AC-15 ← key extractor over
`TRANSLATIONS["zh"]` · AC-16/AC-17 ← T-02 pipe and `pty` fixtures · AC-18 ← stdout cross-checked against the
tripwire log (exactly one outcome line on both exit paths, both languages — C-10) · AC-25 ← delete
`srs_reject_reason` and assert the new path breaks too.

**D-8 — committed test tree: stage 1's (b).** R6's risk is real and I do not minimise it: a syntax-only gate cannot
notice the unconditional restart coming back. But AC-22 fixes the shipping diff at `bin/sc` + `CHANGELOG.md`, and a
stage-2 design that contradicts a requirement AC must return `BLOCKED`, not quietly widen it. So: adopt (b),
mitigate with R6's in-code comment plus the pasted harness. The gate reviewer — the one actor entitled to widen
AC-22 — **upheld** this (`03_GATE_REVIEW.md:65-74`) in exchange for C-11: the harness in `06` must be complete and
runnable verbatim (whole files, loader included, no elisions), and R6's comment must be present at the apply site.
Recorded against the existing `ruleset-unit-tests-in-t02` decline; no second record opened.

## 12. Decision record

| # | Question | Adopted | Basis |
|---|---|---|---|
| D-1 | Restart or hot-apply? | **Restart**, only on real change; AC-19 not-applicable with the reason in §2.3 | §2 evidence (F-2, F-3, F-4a) + §2.3's three grounds; B-4's evidence rule |
| D-2 | One concept or two? | **Two facts, one query** — `(status, digest)` from one read | rule 85 test 2; B-15 |
| D-3 | Change signal | **sha256 of the full content**, chunked | BC-15 bounded memory; FIPS-safe |
| D-4 | Regenerate on loss? | **No** (T-02's asymmetry kept), and loss additionally excluded from the apply set | §5.6; R9 |
| D-5 | Outcome line on the non-TTY path? | **Always** | NFR-4; a silent scheduled run is indistinguishable from a broken one |
| D-6 | Exit status on a no-op | **0** | `install.sh:456` |
| D-7 | Keep `→ Restarting sing-box ...`? | **Keep**, now from one site | minimal diff; T-02 fixtures |
| D-8 | Commit a test tree? | **No** (mitigated; gate upheld, C-11 attached) | §11 |
| D-9 | `CHANGELOG.md` in scope? | **Yes**, two edits, specified in §6.5 | honest reporting outranks diff size |
| A-1 | Name for the apply set | `changed_usable_tags`, not `changed_tags` | the name must state both conditions; keeps CONTEXT.md's `content-changed` un-narrowed |
| A-2 | Keep `ruleset_status()`? | **Keep** as a 2-line view; gate C-8 lets the developer re-decide on merit | R10; `docs/dev-map.md:46` |

**Consolidation record (rule 85).** No split, no merge, no new task. The seam this design removes: without folding
the digest into `ruleset_state`, T-10 would ship a *second* reader of the same four files with its own
symlink/EPERM/regular-file handling, and the next task that changes what counts as a rule-set (T-05 `sc doctor`)
would have to edit both and reconcile them. The counter-rule binds too: this adds **two functions and one tuple
field**, not a module, class, config key or dependency beyond `hashlib`; `_status_view` exists only because three
call sites need the same projection. **Rejected-decisions:** one new `deferred` record,
`trust-singbox-fswatch-ruleset-reload` (§2.3), amended in rev. 2 with the corrected F-4(c) statement and the three
real grounds; `mtime-or-size-as-a-ruleset-change-signal` read, honoured, its E-13 frequency wording corrected the
same way; `ruleset-unit-tests-in-t02` honoured, not re-litigated.

## 13. Out of scope for this design

- Everything in requirement §5: `install.sh` / `uninstall.sh` / `systemd/*` / `/etc/periodic/*`; the mirror list,
  fallback, validation, size floor, `--mirror` / `SB_RULES_BASE`, progress rendering, temp naming, stale-temp
  cleanup; every timeout constant; `sc doctor` (T-05), `sc config --show` (T-06), the committed harness (T-07);
  regenerating on *loss*; a `--force`/`--no-restart` flag or an "apply now" subcommand; changing the cadence.
- The six T-02 follow-up rows (`docs/tasks.md`): the `capture_output=` 3.7+ sites, the missing `en` table /
  `ls.idx`, the `--mirror` scheme allow-list, D-4 local-disk-fault attribution, the stray blank line before
  `→ Restarting sing-box ...`, the `_temp_path` prefix coupling — none fixed, none worsened.
- `README.md` / `README.zh-CN.md`: re-checked (gate confirmed) — they promise hot node switching (true, unchanged)
  and that rule-sets "come back automatically" after `sc update-rules` (true, B-6 preserved); neither claims an
  unconditional restart, so neither needs an edit.
- Making `restart_service()` report the init system's exit status (R5) — PM pool-row candidate; skipping the
  restart when *another* rule-set was lost mid-run (R9's residual, gate F-4) — no AC asks for it and today's code
  restarts anyway, so it is recorded, not designed; and relying on sing-box's own rule-set file watcher (§2.3) —
  deferred with a written unblock path.

## Verdict

**READY.** No gap was found in `01_REQUIREMENT_ANALYSIS.md`; nothing here contradicts it. D-1 is closed with
evidence rather than judgment (§2), including what could not be verified and why the design does not depend on it.
B-15 is honoured — the digest is a second *fact* from the one existing on-disk query, never a second *opinion*.
NFR-1 is carried into §9 R1 and §11 as binding gate conditions and must be restated verbatim in the developer and
QA dispatch prompts. The product diff stays `bin/sc` + `CHANGELOG.md` (+ `docs/dev-map.md` under gate C-8); the
Python 3.6 floor and the stdlib-only rule hold (`hashlib`). **Next:** Developer — implement §10.5 in order under
C-1…C-11; QA executes §11 with G-1…G-7 (as strengthened by C-2/C-3/C-4) as pass/fail conditions, not advice.
