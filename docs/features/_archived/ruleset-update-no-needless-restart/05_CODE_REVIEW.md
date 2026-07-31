# Code Review — T-10 `ruleset-update-no-needless-restart`

- **Task**: T-10 · **Mode**: full · **Stage**: 5 · **Date**: 2026-07-31 · **Deferred-human**: `defer, do not ask`
- **Upstream read**: `01` (25 ACs) · `02` rev. 2 (495 lines) · `03` (C-1…C-11 binding, §5 Q1-Q8) · `04` (437 lines)
- **Tooling limit, stated up front**: this review ran with **Read / Glob / Grep only**. Nothing was executed — no `git`, no `python3`, no `verify_all`, no shell. Every claim below is from reading the files in the working tree. Where a condition is only checkable by running a command (C-8's `git diff --name-only`, C-2's witness, `verify_all`'s counts), I say so and hand it to QA rather than asserting it.
- Repo root for every relative path: `/home/alan/Programs/singbox-cli`.

> Transcription note (PM): the code-reviewer agent runs Read/Glob/Grep-only and could not write
> this file. The content below is its deliverable verbatim; the PM transcribed it without editing
> findings, rulings or the verdict.

## Files reviewed

- `bin/sc` — `:1-30` (imports), `:50-65` (rule-set constants), `:130-166` (`TRANSLATIONS["zh"]`), `:496-641` (the whole `# Rule-sets` section), `:686-702` (`_warn_degraded`), `:705-790` (`_ruleset_bases` / `_temp_path` / `_clear_stale_temps` / `_fetch_to_temp` chunk loop), `:816-926` (`generate_config`), `:929-940` (`restart_service` / `reload_or_restart`), `:945-965` (`clash_api` / `is_running`), `:1173-1257` (`cmd_update_rules`), `:1259` (next `def`), `:1525-1537` (tail)
- `CHANGELOG.md:1-30`
- `docs/dev-map.md:30-69`
- `CONTEXT.md:14-35` (boundary check)
- `README.md` / `README.zh-CN.md` — `update-rules` occurrences only (`:106-118`, `:167`), boundary check
- `install.sh:448-467` (the exit-status consumer, D-6/BC-11/BC-12)
- `.harness/rules/50-singbox-cli.md`, `.harness/rules/85-design-discipline.md`, `.harness/insight-index.md`, `.harness/scripts/verify_all.sh:210-244`
- No committed tests exist (D-8/C-11 upheld, B.2 SKIP). The scratch harness in `<scratchpad>/t10/` is outside the repo and is QA's material via `06`; I reviewed its *description* in `04` §C-3/C-4, not its source.
- **Safety**: nothing was executed; `<scratchpad>/main_sc.py` was neither read as reference nor run.

## Findings

### CRITICAL

None.

### MAJOR

None.

### MINOR

**M-1 — [DOC/MAINT] `04_DEVELOPMENT.md` mixes pre-change and post-change line numbers without labelling them, and three post-change citations are simply wrong.**

- `04:244-246` (C-6): "the five pre-existing sites at `bin/sc:827`, `:869`, `:1176` — **now `:892`, `:934`, `:1271`**". Actual post-change locations are **`bin/sc:922`, `:964`, `:1289`**.
- `04:196` (C-4): "the 3-tuple destructuring at `bin/sc:804` (**now `:874`**)". Actual: **`bin/sc:899`** (`for tag, fname, status in report if status == "usable"`). `:874` is inside the DNS/inbound literal.
- `04:37` (files-changed table, "not touched" row): cites `:721-731` for `generate_config()` / `restart_service()` / `is_running()` / `_filter_rules()` / `_warn_degraded()` / `clash_api()`. `:721-731` is the *pre-change* `generate_config` range; post-change those functions are at `:816-926`, `:929-933`, `:959-965`, `:665-683`, `:686-702`, `:945-956`. (`:639-641` and `:899` in the same row are correct.)

Why it matters, and why it is only MINOR: the **substance** is right and I re-verified it independently. Grepping `capture_output=|text=True|:=|missing_ok=` over `bin/sc` returns exactly three lines — `:922`, `:964`, `:1289` — i.e. `capture_output=` ×3 and `text=True` ×2 = the five pre-existing 3.7+ sites, **no sixth was added** (C-6 ✓). But `06` will inherit these citations and QA will chase them; a line reference that is wrong by 30 lines reads like "a site moved", which is exactly the alarm C-6 exists to raise. Fix the numbers in `04` before QA transcribes.

**M-2 — [STYLE] `bin/sc:1258` — the diff eats a blank line at the seam where the old unconditional tail was deleted.**
`print(t("Done"))` at `:1257`, one blank line at `:1258`, `def cmd_update_interval(args):` at `:1259`. Every other top-level `def cmd_*` in the file is preceded by **two** blank lines (20 of them; the single exception, `cmd_ls:1004`, follows the `# ============ Commands ============` banner). PEP 8 E302. `verify_all` B.3 (lint) is SKIP, so no gate catches it, and `04` does not record it. Cosmetic, but it is *inside this change's hunk* and it makes the file inconsistent with itself.

**M-3 — [PERF] The read is now unbounded in file size on a hot path; `04`'s C-7(iii) records the fault half of that surface but not the size half.**
`ruleset_state()` (`bin/sc:546-555`) streams to EOF, and `ruleset_report()` → `ruleset_states()` → `ruleset_state()` runs inside `generate_config()` (`bin/sc:823`), i.e. on every `sc add / rm / use / mode / default-tun / reload`. F-7/C-7(iii) correctly records the *fault* case (readable at byte 0, faulting at byte 500 000 ⇒ `usable` → `unreadable`). The *size* case is not recorded: a 100 MB regular file at `/etc/sing-box/rules/geoip-cn.srs` — disk corruption, a botched `cp`, a wrong URL written by hand — previously cost 12 bytes plus one `stat`; it now costs a full 100 MB sha256 on every one of those commands. Real rule-sets are ~480 KB total (`04:285`), so this is a robustness edge, not a regression on the happy path; `/etc/sing-box/rules` is root-owned, so it is not a privilege-boundary issue.
Positive note in the same breath: `if not path.is_file()` at `:544` means a fifo or a `/dev/zero` symlink can **never** make the reader spin forever — the unbounded case is confined to genuinely large *regular* files. **Follow-up row candidate; do not fix here** — a size cap would change what `srs_reject_reason()` means and is a design decision, not a review demand.

**M-4 — [REQ] NFR-3's literal wording is not met on the recovery path.**
`01` NFR-3: "It reads each managed rule-set file **at most twice per run** (once before, once after)". On a `gained` run the files are read **three** times: `before = ruleset_states()` (`:1177`), `after = ruleset_states()` (`:1222`), and `generate_config()`'s own `ruleset_report()` (`:823`) inside the apply block. `02` §5 says "same count of disk passes as today (two)" — true of the *snapshots*, and the third pass is inherited from T-02, not introduced here; what *is* new is that all three passes are full-content reads instead of 12-byte peeks. No AC asserts the count, and NFR-3's real intent (no network, no new timeout, bounded chunks, memory O(1)) is met — `:548` chunks at 65536 with the `while True: … if not chunk: break` shape. **Note for QA to record in `06`**, not a defect to fix.

**M-5 — [SCOPE] C-8's mechanical check cannot pass as literally written, because a fourth tracked file is dirty — and it is not the developer's.**
`CONTEXT.md:26-31` carries T-10's `content-changed` glossary entry ("A rule-set whose installed bytes differ at the end of a run from the bytes installed at its start… Every gained rule-set is content-changed; the converse is false"). `01` §3 **mandates** that entry ("used with these exact meanings throughout; added to `CONTEXT.md`"); `02` §3 correspondingly says the *design* does not edit `CONTEXT.md` and lists it under "Not touched". mtime ordering places `CONTEXT.md`'s last write between `01_REQUIREMENT_ANALYSIS.md` and `03_GATE_REVIEW.md` — i.e. **stage 1**, before development. HEAD is `22502f9` (the Clash-port fix), which predates the task, so `CONTEXT.md` is dirty relative to HEAD.
I could not run `git diff --name-only` (Read/Glob/Grep only), so I cannot enumerate the real list; on the evidence it will contain at least `CONTEXT.md` plus the bookkeeping files `02` §3 exempts by T-02 precedent (`docs/features/**`, `.harness/rejected-decisions.md`, `docs/tasks.md`, `docs/batches/default/BATCH_PLAN.md`).
**C-8's substance is satisfied**: no unauthorised *product* file carries a T-10 change. I re-read `README.md` / `README.zh-CN.md` (`:106-118`, `:167` — no unconditional-restart claim, unmodified, B-16/AC-23 owe them nothing), `install.sh:448-467` (untouched; `:456` still branches on the exit status), and `systemd/*` is not referenced anywhere in the change.
**Route: PM ruling before the commit, not a developer change. Do NOT revert the `CONTEXT.md` glossary entry — `01` §3 requires it.** QA should run C-8 as an *attributed* list ("file → stage that wrote it") rather than a set-inclusion test, or the condition will fail for a reason that has nothing to do with the code.

### NIT

**N-1 — [MAINT] `bin/sc:561-573` `ruleset_status()` is caller-less, and `04`'s defence of it overreaches by one clause.**
I do **not** overturn the keep decision — gate Q5 explicitly delegated it to the developer on merit, the rubric applied in `04:372-381` is the right rubric, the function is one line of body delegating to a function that *is* exercised (so it cannot drift semantically), `docs/dev-map.md:47` names it, and T-05 (`sc doctor`) is a filed row that plausibly calls it. The overreach: `04:381` says "It is covered by `t1_state.py` assertions, so it is **not untested dead code**." Under D-8 no test is committed, so from the repository's point of view it is precisely an uncovered, caller-less function; what actually protects it is its one-line delegation, not a test. Say that instead. If T-05 lands without calling it, delete it then (two lines, as `04` says).

**N-2 — [MAINT] `bin/sc:628` `old.get(tag)` conflates "tag absent from `before`" with "digest is `None`".**
Both map to `None` and both are correct: the two snapshots come from one `RULESET_FILES` (`:60-65`) inside one process, so the tag sets are identical, and the docstring at `:614-616` says so. No action; recorded because a future `RULESET_FILES` change is the scenario F-10 was written for and this is the one place the two failure modes are indistinguishable at the call site.

## The central invariant — read in code, not in the docstring (C-5)

`gained ⊆ changed` is the structural claim behind AC-4 ("exactly one apply per run"). It rests on C-5. **The implementation honours it. Verified branch by branch at `bin/sc:537-558`:**

| Path in `ruleset_state()` | Line | Returned | `digest is None`? | Status in `{absent, unreadable}`? |
|---|---|---|---|---|
| `not path.exists()`, symlink | `:541-543` | `("unreadable", None)` | yes | yes ✓ |
| `not path.exists()`, no symlink | `:541-543` | `("absent", None)` | yes | yes ✓ |
| `not path.is_file()` (dir, fifo, device) | `:544-545` | `("unreadable", None)` | yes | yes ✓ |
| **`OSError` anywhere in the stream** | `:556-557` | `("unreadable", None)` | yes | yes ✓ |
| loop ran to EOF | `:558` | `(srs_reject_reason(head, size) or "usable", digest.hexdigest())` | **no, always real** | status ∈ `{usable, bad-magic, too-small}` ✓ |

The two failure modes the gate named are both closed **in the body**, not only in the docstring:

1. **No partial digest.** `digest` is a local `hashlib.sha256()` object (`:539`); the only expression that turns it into a value is `digest.hexdigest()` at `:558`, which is *after* the `with` block and *outside* the `try`'s failure route. `except OSError: return ("unreadable", None)` at `:556-557` returns before any hex value can be produced. A file that faults after N bytes therefore yields `None`, never a digest of N bytes. ✓
2. **A readable empty file gets a REAL digest.** `head = b""`, `size = 0`, the first `fh.read(65536)` returns `b""`, `break` at `:549-550`, fall through to `:558`: `srs_reject_reason(b"", 0)` → `"too-small"` (size floor checked first, `:509-510`), paired with `sha256(b"").hexdigest()`. Not `None`. ✓

The equivalence is bidirectional in the code: `None` is returned only by branches whose status is `absent`/`unreadable`, and those statuses are returned only by `None` branches — `srs_reject_reason()` (`:501-513`) can only ever produce `too-small`/`bad-magic`/`None`, so the EOF return can never manufacture an `absent` or `unreadable`. With that, the §4.4 proof stands as written: a `gained` tag is `usable` in `after` (real digest); in `before` it was `absent`/`unreadable` (`None`, differs) or `bad-magic`/`too-small` (real digest, and since status is a pure function of `(head, size)`, equal bytes would force equal status — contrapositive gives different digests). ✓

Chmod-000 side note I checked because it is the fixture most likely to be mis-implemented: `Path.exists()` swallows `OSError` and returns `False`, so a mode-000 **parent directory** yields `("absent", None)` rather than `("unreadable", None)`. The *status label* is arguably less truthful there, but both members are inside the `None` set, so **the invariant is unaffected** — and this is pre-existing behaviour, unchanged by T-10. Not a finding; noted so QA does not read `absent` on that fixture as a defect.

## T-02 recovery preservation (自动恢复) — F-14 re-verified in the new code

`bin/sc:1230-1244`, read line by line against `02` §7:

```
if changed and CFG_PATH.exists():          # :1230  outer guard, strictly weaker than the old
    regen_ok = True                        # :1231  `if gained and CFG_PATH.exists()` (gained ⊆ changed)
    if gained:                             # :1232
        regen_ok = generate_config()       # :1236  REGENERATED, never patched
        print(t("Rule-sets restored: ...")) # :1237  the restored line, still printed when stopped
    if regen_ok and is_running():          # :1238  failed check still blocks the restart
        print("\n" + t("→ Restarting ...")) # :1239  D-7's stray "\n" kept, now from ONE site
        # R6 comment                        # :1240-1242
        restart_service()                  # :1243  the single apply call site in the file
        restarted = True                   # :1244
# outcome line                              # :1247-1254  ALWAYS, exactly once
if failed: sys.exit(...)                    # :1255-1256  apply strictly precedes the non-zero exit
print(t("Done"))                            # :1257
```

Inner order is **verbatim**: `generate_config()` → restored line → `if regen_ok and is_running()` → restart. `regen_ok = False` ⇒ no restart, and the restored line still prints (a stopped service or a failed check does not swallow it). The apply block sits above `sys.exit` (B-14/BC-9/AC-12) ✓. `is_running()` is consulted once, only after something changed ✓. `restart_service()` appears exactly once in the file outside `reload_or_restart()` (grep-verified), so AC-4's "one apply per run" is structural, not disciplinary ✓.

One honest edge I checked because the outcome line makes a stronger claim than the old code did: on a host with neither systemd nor OpenRC, `restart_service()` (`:929-933`) is a silent no-op — but `is_running()` (`:959-965`) returns `False` in that case, so `restarted` stays `False` and the run prints outcome (c). No dishonest "restarted" line is reachable. ✓ (R5's separate residual — `check=False`, so "restarted" means "issued" — is unchanged and already recorded.)

## C-9, C-11, C-6, F-10, bilingual parity — mechanical checks I could run

| Check | Method | Result |
|---|---|---|
| **C-11** — R6's comment at the apply site | read `bin/sc:1240-1242` | ✓ present, immediately above `restart_service()` at `:1243`, naming **both** `changed_usable_tags()` and "the T-10 defect", and stating the harm (every live connection, a remote admin's own SSH, weekly, for four unchanged files) |
| **C-9(i)** — "sing-box logs nothing on a successful reload" | grep `logs nothing\|silent on success\|reloaded rule-set` over `bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`, `CONTEXT.md`, `04` | ✓ 0 hits |
| **C-9(ii)** — "identical bytes is the common case" | grep `common case\|rarely\|常见\|很少` over the same set | ✓ 0 hits as a claim. `bin/sc:1228` says "a run that re-fetched four byte-identical files touches nothing at all" — a conditional about a scenario, no frequency claim. The `CHANGELOG.md:16` bullet likewise claims only "只有当…内容真的发生变化…才会重启". `04:294` and `PM_LOG:24` name the phrases only to record that they were excluded |
| **C-6** — 3.6 floor | grep `capture_output=\|text=True\|:=\|missing_ok=` over `bin/sc` | ✓ 3 lines (`:922`, `:964`, `:1289`) = the 5 pre-existing sites, **no sixth**. No walrus. No f-string in any added line (the only `f"…"` in `cmd_update_rules` is the pre-existing prefix at `:1183`). Only import added is `hashlib` (`:5`), stdlib |
| **F-10** — pair by tag | read `bin/sc:623-635` | ✓ `old = dict((tag, digest) for tag, _fname, _status, digest in before)` then `old.get(tag)` per `after` row. No index arithmetic anywhere |
| **Exit 0 on a no-op** | read `bin/sc:1247-1257` + `install.sh:456` | ✓ a no-op run reaches `print(t("Done"))` with no `sys.exit`; `install.sh:456` still branches on the status |
| **AC-15 / E-15** — no `失败：` in new zh | grep `失败` over `bin/sc` | ✓ 7 hits, all pre-existing keys (`:89`, `:97`, `:99`, `:100`, `:110`, `:127`, `:140`). None of `:143-145` |
| **AC-14 / bilingual parity** | read `bin/sc:143-145` | ✓ 3 keys, placeholder sets identical (`{names}` on the two "updated" lines, none on the "no rule-set changed" line). `TRANSLATIONS` still has no `en` table (`:84`), so the **key is the English output** — and all three keys read as full English prose sentences, not namespaced identifiers (`ls.idx` at `:150` remains the pre-existing defect, not copied). Em-dash style (`—` / `——`) matches the neighbouring `Rule-sets restored:` key at `:142` |
| **65536 / no new constant** | grep `65536` | ✓ two sites: `:548` (new) and `:783` (`_fetch_to_temp`), same literal, same `while True: … if not chunk: break` shape, same `head` accumulation idiom |
| **Doc sizes (F.6 ≤500)** | line counts | `01` 372 · `02` 495 · `03` 208 · `04` 437 — all under cap. This `05` is sized to stay under it |

Not checkable without a shell, handed to QA: C-2's `MainPID` / `ActiveEnterTimestamp` witness, C-3's shim marker and euid, `verify_all`'s 16/0/0/2, the 350 assertions, and C-8's `git diff --name-only`.

## Requirement coverage check (all 25 ACs)

| AC | Implementation | Status |
|---|---|---|
| AC-1 no restart/reload/start/stop on identical bytes | `bin/sc:1224` `changed` empty ⇒ `:1230` guard false; old unconditional tail deleted | ✅ (QA re-runs the stub log) |
| AC-2 `config.json` byte-identical | `generate_config()` reachable only via `:1232 if gained:` inside `:1230` | ✅ |
| AC-3 exit 0 + "nothing changed" once | `:1247-1248`, `:1257` | ✅ |
| AC-4 exactly one apply per run | one `restart_service()` call site, `:1243`, not in a loop | ✅ structural |
| AC-5 equal size, different content | digest over full content, `:551`; `size` no longer `st_size` | ✅ |
| AC-6 mtime ignored | no `st_mtime`/`utime` anywhere in `ruleset_state` | ✅ |
| AC-7 absent → usable regenerates + applies + restored line | `:1232-1237` under a guard weaker than the old one (`gained ⊆ changed`) | ✅ |
| AC-8 bad-magic → usable, as AC-7 | same path; `bad-magic` is not `usable`, so it is in `gained` | ✅ |
| AC-9 stopped service is never started | `:1238 if regen_ok and is_running()` | ✅ |
| AC-10 no `config.json` ⇒ nothing | `:1230 and CFG_PATH.exists()` | ✅ |
| AC-11 all mirrors fail ⇒ no service action, non-zero + aggregate on stderr | `changed` empty; `:1255-1256` `sys.exit` unchanged | ✅ |
| AC-12 apply **before** the non-zero exit | `:1243` above `:1255` | ✅ (see F-11 residual) |
| AC-13 pre-state observation never raises | `:540-557` — every branch returns; `except OSError` is the only escape | ✅ |
| AC-14 every added key has a `zh` entry | `bin/sc:143-145` | ✅ |
| AC-15 no `失败：` in added zh | grep, above | ✅ |
| AC-16 non-TTY one line per rule-set, no `\r` | download loop `:1180-1220` untouched; outcome line is run-level | ✅ |
| AC-17 TTY redraw + per-file causes unchanged | `_fetch_to_temp` and the `causes`/`tried` lists untouched | ✅ |
| AC-18 outcome states what happened; "restarted" absent when none issued | `restarted` set only at `:1244`, after the call; `:1249-1254` | ✅ |
| AC-19 non-disruptive fallback | **not applicable**, reason recorded in `02` §2.3 (B-4 → restart) | ✅ n/a, by design |
| AC-20 `verify_all` no new WARN/FAIL vs pristine HEAD | `04:57-72` reports 16/0/0/2 both sides | ⚠️ QA re-runs (I cannot execute) |
| AC-21 no syntax newer than 3.6, stdlib only | grep, above; `import hashlib` `:5` | ✅ (citation numbers wrong in `04` — M-1) |
| AC-22 diff = `bin/sc` + `CHANGELOG.md` (+ `docs/dev-map.md`, C-8) | product files verified; see **M-5** for `CONTEXT.md` | ⚠️ PM ruling |
| AC-23 `CHANGELOG.md:15` corrected + new entry | `:15` clause replaced verbatim per `02` §6.5; `:16` new bullet, one physical line | ✅ |
| AC-24 `is-active` same before/after, both readings stated | `04:80-93` (plus C-2's MainPID/timestamp witness) | ⚠️ QA re-verifies |
| AC-25 no second on-disk judgment | `changed_usable_tags` → `ruleset_states` → `ruleset_state` → `srs_reject_reason`; deleting `srs_reject_reason` breaks the new path | ✅ |

**No AC is unimplemented.** Three are QA-owned (AC-20, AC-24) or PM-owned (AC-22) by construction, not missing.

## Design fidelity check

| `02` item | Implementation | Status |
|---|---|---|
| §4.1 `ruleset_state(path) -> (status, digest)`, contract in docstring **and** body | `bin/sc:516-558`; docstring `:517-535`, contract honoured branch-by-branch | ✅ C-5 met |
| §4.1 chunked at 65536, `head` accumulation, real byte count replaces `st_size`, no walrus | `:546-555` | ✅ |
| §4.2 `ruleset_status` = `ruleset_state(path)[0]`, docstring says why it has no caller | `:561-572` | ✅ (see N-1) |
| §4.2 `ruleset_states()` 4-tuples in `RULESET_FILES` order | `:575-588` | ✅ |
| §4.2 `_status_view(states)`, three call sites | `:591-596`; used at `:605`, `:1223` ×2 | ✅ |
| §4.2 `ruleset_report()` contract unchanged | `:599-605`; `generate_config():899` and `usable_tags():641` still destructure 3-tuples | ✅ |
| §4.4 `changed_usable_tags` sorted, pure, by tag, `usable in after` filter | `:608-636` | ✅ |
| §4.4 `None != None` semantics | `:634` spells the `None` arms out instead of relying on `!=` | ✅ **inside** the design — disclosed in `04:357-363`, identical results, strictly more explicit; the added comment at `:629-633` states the arm is unreachable and why it exists. Not drift |
| §5 `before = ruleset_states()` replaces `usable_tags(ruleset_report())` | `:1177` | ✅ |
| §6.1 exit status unchanged, `install.sh:456` consumer | `:1255-1256`, `install.sh:456` | ✅ |
| §6.2 stream contract preserved; outcome is a run-level line on stdout | download loop untouched `:1180-1220`; `:1247-1254` | ✅ |
| §6.3 three outcomes, exactly once, immediately before the exit | `:1247-1256` | ✅ |
| §6.4 three zh keys, placeholder parity, collision audit | `:143-145` | ✅ |
| §6.5 `CHANGELOG.md` two edits, verbatim, one physical line | `CHANGELOG.md:15`, `:16` | ✅ |
| §7 flow, statement for statement, incl. `restarted` flag | `:1222-1257` | ✅ |
| §9 R6 comment at the apply site (C-11) | `:1240-1242` | ✅ |
| §6.3/D-7 keep `→ Restarting sing-box ...` with its stray `"\n"`, now one site | `:1239` | ✅ neither fixed nor worsened |
| §3 "not touched": `install.sh`, `systemd/*`, `README*`, `_filter_rules`, `restart_service`, `is_running`, `clash_api`, download loop, timeouts | re-read each | ✅ |
| C-8 dev-map scope: rows `:46-47`, "only for accuracy of its rule-set rows" | `docs/dev-map.md:46` edited (adapter renamed to `ruleset_state(path)`), `:47` **added** (`ruleset_state` → `(status, digest)` + the C-5 equivalence + why `ruleset_status` is kept), `:48` edited (`_status_view(ruleset_states())`), `:49` **added** (`changed_usable_tags`) | ✅ **ruled inside the grant** — see below |
| §10.5 implementation order | single final state; unverifiable post-hoc, no evidence of a skipped step (`py_compile` is B.1 PASS) | ➖ not checkable at stage 5 |

**C-8 dev-map ruling (the developer explicitly asked for it, `04:364-368`).** The two added rows stay **inside** the grant. Three reasons: (1) C-8's stated purpose is *accuracy of the rule-set rows*, and the accurate shape of a table titled "Reusable utilities — what to call so you do not build a second one" is one row naming the single reader and one naming the single comparator; cramming both into row 46 would have been less accurate, not more compliant. (2) The edit is confined to the same contiguous table region (`:46-49`); no new section, no new table, no other part of `dev-map.md` mentions any T-10 symbol (grep-verified), and the pre-existing `capture_output=` bullet at `:63-64` is untouched and still says "three sites" — which is still true. (3) The developer disclosed the boundary call in `04` instead of letting it pass silently, which is the behaviour C-8's "or state in `04` why" clause is asking for. The one honest caveat: row `:49` (`changed_usable_tags`) is a *new utility*, marginally beyond a literal reading of "rows `:46-47`". I am recording that I extended the reading rather than pretending the text covered it — a reviewer who disagrees has a defensible position, but the cost of the alternative (a next task writing a second content comparator) is exactly the seam rule 85 test 2 exists to prevent.

## C-7 residuals — all three present, in the developer's own words

| Residual | Where in `04` | Verdict |
|---|---|---|
| (i) F-11 — BC-9 ordering delta: "2 changed + 2 failed" now restarts where today's `sys.exit` short-circuits | `04:252-261` | ✅ Own words, correctly bounded ("the **one** case where the hazard in (ii) is genuinely new rather than inherited"), and it names the requirement that sanctions it (B-14/BC-9) |
| (ii) F-4 — lost-rule-set hazard, correcting R9's absolute wording | `04:263-274` | ✅ Own words. Correctly separates "restart **caused by** a loss" from "restart **during** a loss", names the T-02 FATAL and `Restart=on-failure` looping, states it is not a regression except in case (i), declines to widen per gate Q6, and hands PM the cheap future shape ("skip the restart when the usable set *shrank*") — both snapshots already carry what that needs |
| (iii) F-7 — widened `generate_config()` failure surface on a path `02` §3 calls "not touched" | `04:276-287` | ✅ Own words, with the cost measured (~480 KB, µs against the `sing-box check` subprocess). **Incomplete in one respect — the size half is missing; see M-3** |

## Axis status

- **Standards-conformance**: **4 findings, worst = MINOR** — M-1 (doc-citation accuracy), M-2 (blank-line convention, PEP 8 E302), M-5 (C-8 boundary, owner = PM not developer), N-1 (caller-less function + one overreaching claim). Repo conventions otherwise held: 3.6 floor (rule 50 `:102-104`), stdlib only, bilingual parity as a hard requirement (rule 50 `:93-95`), "config is regenerated, never patched" (`:1236`), dev-map obligation discharged, insight bullet written as one physical line (`04:425`, per `.harness/insight-index.md:21`), no new file/module/class/config key (rule 85 counter-rule), and the `# Rule-sets` header's "adding a second notion of usability anywhere else is a defect" is respected — the digest is a second *fact* from the one query, never a second *opinion*.
- **Spec/design-fidelity**: **2 findings, worst = MINOR** — M-3 (a real behaviour surface `02` §9 R2 / C-7(iii) under-describes), M-4 (NFR-3's literal count). Every §4 signature, §6 string, §7 ordering guarantee and §10.5 artefact is present as specified; the one deliberate deviation (the explicit `None` arms) is disclosed, semantically identical, and better. No silent drift found.
- Aggregate = the more severe of the two = **MINOR**.

## Routing

**Must fix before QA** (both are document edits; neither touches `bin/sc`):
1. **M-1** — correct the three stale/wrong line citations in `04` (`:196`, `:244-246`, `:37`) so `06` does not inherit them.
2. **M-5** — PM ruling on the `CONTEXT.md` boundary, and reformulate C-8's check for QA as an attributed file list. Do not revert the glossary entry.

**Note for QA to verify** (I could not execute anything):
3. C-2's `MainPID` / `ActiveEnterTimestamp` pair, C-3's shim marker + `id -u`, `verify_all` 16/0/0/2 with zero delta, the 350 assertions and the negative control. Re-run the C-6 whole-file counters against the **corrected** numbers `bin/sc:922`, `:964`, `:1289`.
4. **M-4** — record the third full read on the recovery path in `06` against NFR-3.
5. `04:381`'s "not untested dead code" claim (N-1) — restate as "protected by delegation, not by a committed test", since D-8 means no test ships.

**Follow-up row candidates** (do not fix in T-10):
6. **M-3** — unbounded-size read on the `generate_config()` hot path (sibling of F-7, different half).
7. **M-2** — the `bin/sc:1258` blank line; fold into whichever task first wires `verify_all` B.3 (lint), or fix opportunistically at commit time.
8. Already on record, unchanged by this review: R9's residual (C-7 ii), R5's "issued vs. succeeded", D-7's stray blank line, and `ruleset_status()`'s fate at T-05.

## Verdict

**APPROVED** — 0 CRITICAL, 0 MAJOR, 5 MINOR, 2 NIT.

The defect is genuinely gone and gone *structurally*: `bin/sc` now contains exactly one `restart_service()` call site outside `reload_or_restart()`, it sits under `if changed and CFG_PATH.exists()`, and `changed` is computed from sha256 over full file content taken from the same single on-disk query that decides usability. The C-5 contract — the one place this could have been implemented wrongly — is honoured in the **body**, not merely asserted in the docstring: no partial digest can escape the `except OSError`, and a readable empty file gets `sha256(b"")`. T-02's recovery survives with its inner order verbatim and still precedes the non-zero exit. Nothing in the five MINOR findings changes behaviour; two are document corrections, one is a blank line, one is a PM boundary ruling on a file the developer never touched, and one is a follow-up row.

Neither `ROLLBACK TO DEVELOPER` nor `ROLLBACK TO SOLUTION-ARCHITECT` is warranted: no finding requires re-deciding a behaviour or a structure, and no shipped code change is requested. `BLOCKED: NEEDS-HUMAN` is **not** raised — no safety red line was reached; this review executed nothing.

**Next:** PM — rule on M-5, have the developer correct M-1 in `04`, then QA executes `02` §11 G-1…G-7 as strengthened by C-2/C-3/C-4, with the notes above.
