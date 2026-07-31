# Development Record — config-degrade-missing-rulesets (T-02)

- **Task**: T-02 · **Mode**: full · **Date**: 2026-07-31 · deferred-human (no questions asked)
- **Upstream**: `03_GATE_REVIEW.md` = `APPROVED FOR DEVELOPMENT` (9 WARN conditions; F-1…F-5 binding on dev)
- **Verdict**: `READY FOR REVIEW`

---

## Summary

`bin/sc` now carries one rule-set model: two constants (`SRS_MAGIC`, `SRS_MIN_BYTES`) and one pure
predicate `srs_reject_reason(head, size)` that is the single definition of "is this rule-set usable?",
with three adapters — a path adapter (`ruleset_status`), a socket adapter (`_fetch_to_temp`) and a
screen adapter (`_status_text`). `generate_config()` asks `ruleset_report()` **once** and lets that
one `usable` set drive both the `route.rule_set` definition list and — through a single
`_filter_rules()` called twice — `dns.rules` **and** `route.rules`, so a dangling tag reference is
structurally impossible. `cmd_update_rules` became a thin orchestrator over the same model: an
ordered mirror list, chunked reads with TTY progress, validation before the atomic replace,
per-run dead-base marking, pid-unique temp files, and a recovery path that regenerates the config
when a rule-set that was unusable at the start of the run becomes usable.

No new file, module, config key, dependency or command. No timeout constant changed.

---

## Files changed

- **`bin/sc`** — the only production file:
  - `:45-50` `RULESET_URLS` (filename → one absolute GitHub URL) replaced by a `# Rule-set constants`
    block: `SRS_MAGIC`, `SRS_MIN_BYTES = 16` (with the "never raise it unmeasured" constraint in the
    comment), `RULESET_FILES` (tuple of `(filename, path-relative-to-a-base)` pairs — a tuple, so the
    emission order of `route.rule_set` cannot depend on dict ordering), `RULESET_BASES` (four ordered
    mirrors) and `RULE_ANSWER_KEYS`.
  - `TRANSLATIONS["zh"]` — 11 new entries (the exact English source strings from design §5.4, all
    readable English prose, no namespaced keys).
  - New `# ============ Rule-sets ============` section inserted between the share-link parsers and
    `# Config generation`: `srs_reject_reason`, `ruleset_status`, `ruleset_report`, `usable_tags`,
    `_status_text`, `_filter_rules`, `_warn_degraded`, `_ruleset_bases`, `_temp_path`,
    `_clear_stale_temps`, `_fetch_to_temp`.
  - `generate_config()` — computes `report`/`usable` before the config literal; `route.rule_set` is
    now a comprehension over the report (the four hard-coded entries are gone, the shape and key
    order of each entry are unchanged); after the literal, an empty `rule_set` key is deleted and
    both rule arrays are passed through `_filter_rules`; `_warn_degraded(report)` writes the
    bilingual warning to stderr. Still returns `True` when the only anomaly is an unusable rule-set.
  - `cmd_update_rules(args)` — rewritten per design §6.2 (see "verify_all result" and the notes below).
  - `HELP_EN` / `HELP_ZH` — the one-line `update-rules` entry became the command plus continuation
    lines documenting `--mirror` (repeatable, whitespace-splittable) and `SB_RULES_BASE` with the
    sudo `env_reset` caveat, in the existing `update-interval` indentation style (description column
    30, sub-options column 32).
  - `main()` — `sub.add_parser("update-rules")` now takes `--mirror` (`action="append"`, `default=None`).
- **`CHANGELOG.md`** — `[Unreleased]`: a new `### 新增` entry (multi-mirror fallback, download
  validation, progress, unique temp names, `--mirror` / `SB_RULES_BASE`) and a `### 修复` entry (a
  missing rule-set no longer prevents the service from starting).
- **`README.md`** `### Ruleset update` — `sc update-rules --mirror <base-url>` in the code block plus
  three paragraphs: mirror order + validation, `--mirror`/`SB_RULES_BASE` semantics with the sudo
  caveat, and the degradation promise.
- **`README.zh-CN.md`** `### 规则集更新` — the same content in the matching position.
- **`docs/dev-map.md`** — filled in from the template (see "Dev-map updates").

**Untouched, verified by `git status`:** `install.sh`, `uninstall.sh`, `systemd/*`,
`.harness/scripts/verify_all.sh`, `CONTEXT.md`. (`docs/tasks.md` and
`.harness/rejected-decisions.md` were modified by earlier pipeline stages, not by me.)

---

## verify_all result

Command: `bash .harness/scripts/verify_all.sh`

| | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| Baseline (before any edit) | 16 | 0 | 0 | 2 | 0 |
| After changes | 16 | 0 | 0 | 2 | 0 |

**Delta: 0 new failures, 0 new warnings, baseline preserved.** `B.1` (`python3 -m py_compile bin/sc`,
`bash -n install.sh`, `bash -n uninstall.sh`) still PASSes. `B.2`/`B.3` remain `SKIP` — deliberate,
per design Q8 (T-07 owns the committed harness); I did not wire them, and I did not delete or weaken
any check.

**Correction to the gate review's prediction:** GR §4 Trivia expected `F.6` to WARN because
`02_SOLUTION_DESIGN.md` is "501 lines" and expected the run to exit 1. It does not. `wc -l` counts
newlines and that file's last line has no trailing newline, so it measures **500** — exactly at the
cap, `F.6` PASSes and the run exits 0. Nothing was edited upstream to achieve this. This document is
kept under 500 lines for the same reason.

### Developer verification beyond the gate

`verify_all` only syntax-checks, so I wrote a throwaway harness at
`<scratchpad>/check.py` (session-scoped; not committed, per Q8) implementing design §13's loading
recipe — read `bin/sc`, replace the single `os.execvp("sudo", …)` line with `pass`,
`exec(compile(...))` into a fresh module, repoint `CFG_DIR`/`CFG_PATH`/`NODES_PATH`/
`SETTINGS_PATH`/`RULES_DIR` at a tmpdir, set `LANG`.

**F-3 satisfied:** the harness sets `mod.SYSTEMD = mod.OPENRC = False` immediately after exec, so
`is_running()` and `restart_service()` are inert. No `systemctl` or `rc-service` call was made at any
point; this box's real sing-box service was never touched.

**225 assertions, all passing.** What they cover (mapped to the ACs QA will re-run independently):

| Area | Result |
|---|---|
| AC-2 — `ruleset_status` over valid / 0-byte / HTML / below-floor / directory / dangling-symlink / mode-000 / absent fixtures | expected token for each, nothing raised, directory listing unchanged before/after |
| AC-3 — all four usable | generated `config.json` **byte-identical** to the same function loaded from `git show main:bin/sc`, and stderr empty |
| AC-4/AC-5/AC-6 — all 16 usable/unusable subsets | defined set == usable set; referenced tags ⊆ defined tags in `dns.rules ∪ route.rules` for every subset; `route.rule_set` key deleted exactly when empty; `log`/`inbounds`/`outbounds`/`experimental`/DNS-final/route-final byte-identical across all 16 |
| AC-7 — **real `sing-box check`** (`/usr/local/bin/sing-box`, v1.13.15) over all 16 subsets with the **real** downloaded rule-sets | **all 16 accepted**, including mask 0 (no `rule_set` key at all) → design risk **R2 is closed, not deferred** |
| AC-8 — warning | fires iff degraded; real `n/4` counts; `no-splitting` wording only at 4/4; names every unusable rule-set as `tag (status phrase)`; contains both `sc update-rules` and `sc reload` |
| AC-9 — degradation is not an error | `generate_config()` returns `True` for all 16 subsets |
| AC-10/AC-11/AC-13 — mirror fallback | HTML-200 base rejected and base 2 installed instead; total failure enumerates **every** base on one stdout line with distinct causes; a pre-existing good file byte-identical afterwards |
| AC-12 — dead-base marking | stub request log: a base that failed for file 1 receives exactly 1 request for the whole run; the surviving base receives 4 |
| AC-15 — non-TTY | captured stdout contains **no `\r`** and exactly 4 completion lines |
| AC-16/AC-17 — TTY | `pty.openpty()` capture shows `\r` redraws, `\033[K` erases, ≥2 increasing intermediate states with a percentage (200 000-byte body), the completion line unchanged; no percentage when no length is declared |
| AC-18 — truncation | over-declared `Content-Length` rejected, next base tried, real path untouched |
| AC-19 — concurrency | two real subprocesses updating the same directory: both exit 0, all four files complete and hash-identical, **zero** temp debris |
| AC-20 — stale temps | legacy `<name>.tmp`, dead-pid `.tmp.999999` and non-integer `.tmp.notanint` all removed; a live pid's temp left alone; no temp ever appears in `ruleset_report()` |
| AC-21 — overrides | `--mirror` beats `SB_RULES_BASE` (the env base receives 0 requests); either alone replaces the built-in list; whitespace-only override ignored; whitespace-splitting and trailing-slash tolerance |
| AC-22/AC-23 — recovery + exit status | degraded config + working mirror → `config.json` regenerated with all four rule-sets and `Rule-sets restored:` on stdout, no further command; empty config dir → **no** config created, no restart, quiet; exit 0 all-usable / 1 when any remains unusable |
| AC-14/BC-30 — `LANG = "zh"` pass | both warning wordings, `_status_text` phrases, progress/success/failure/skipped/restored strings all render Chinese; no English leakage in either stream. Separately, a static AST extractor confirms **all 62** `t()` keys in `bin/sc` have a `zh` entry with an identical placeholder set *and* a matching call-site kwarg set (so no `KeyError` and no silent loss — design R7) |
| F-1 | a fake response object returning **one byte per `read()`** still yields the full body, still rejects an HTML page as `bad-magic` |
| F-4 | `Content-Length: nonsense` and an absent header both take the "no declared length" path and succeed |

**AC-27 and F-7 are no longer unverified.** This box has network. I fetched
`geosite/private.srs` from **each of the four bases by hand** — all four returned HTTP 200 with the
identical 696-byte body and the `SRS` magic (`535253`), so no base has a path-layout typo, and
`ghfast.top`'s prefix form works. A real end-to-end `cmd_update_rules` against the default list
installed all four:

| file | bytes |
|---|---|
| `geoip-cn.srs` | 21 899 |
| `geosite-cn.srs` | 450 045 |
| `geosite-google.srs` | 7 916 |
| **`geosite-private.srs`** | **696** ← the smallest |

`SRS_MIN_BYTES = 16` is therefore ~43× below the smallest real rule-set. (Note for the record: 512
would *narrowly* have worked — 696 > 512 — so the analyst's hazard was real but not realised. The
asymmetry argument stands and the floor stays at 16; the measurement is now on file, so a future
task no longer has to reason about it blind.)

**No `Accept-Encoding` header was added (F-6).** `_fetch_to_temp` calls
`urllib.request.urlopen(url, timeout=30)` with a plain URL string and adds no headers at all.

---

## Design drift

Two deviations, both mechanical. Nothing behavioural differs from `02_SOLUTION_DESIGN.md`.

1. **`DESIGN DRIFT` (minor) — one extra 3-line helper, `_temp_path(fname)`.** Design §4 specifies the
   temp name as `fname + ".tmp." + str(os.getpid())` but leaves it inline in §6.2, while §3.4's
   `_clear_stale_temps` needs to construct the same prefix. Rather than write the expression twice
   (which is exactly the duplicated-judgment smell rule 85 forbids), the name is built in one place.
   No new concept, no new constant, 3 lines.
2. **`DESIGN DRIFT` (cosmetic) — `route.rule_set` is a comprehension over `report`, not over
   `RULESET_FILES`.** Design §4 says "list comprehension over `RULESET_FILES` filtered by `usable`".
   `report` is produced from `RULESET_FILES` in the same order and already carries `(tag, filename,
   status)`, so iterating it avoids recomputing the tag and avoids a second membership test. Emission
   order and each entry's key order are unchanged — proven by the byte-identical comparison against
   `main` in AC-3.

Everything else follows the design literally, including the two pre-answered judgment calls:
`route.rule_set` is **deleted** rather than emitted as `[]` when empty (GR §5; now confirmed
acceptable by a real `sing-box check`), and `{names}` renders as `tag (status phrase)` per **F-2**.

### The five binding gate conditions

- **F-1** — `head = (head + chunk)[:len(SRS_MAGIC)]` guarded by `if len(head) < len(SRS_MAGIC)`, i.e.
  accumulated across chunks, never snapshotted from the first `read()`. Tested with a 1-byte-per-read
  response.
- **F-2** — implemented as pre-answered; `_status_text` therefore has a consumer on the config side.
- **F-3** — harness sets `SYSTEMD = OPENRC = False`; no service was touched (see above).
- **F-4** — `int(r.headers.get("Content-Length"))` wrapped in `except (TypeError, ValueError)` →
  `declared = None`; a negative value is also treated as absent. An unparseable header takes the
  BC-14 path and does **not** mark a base dead.
- **F-5** — `_clear_stale_temps` treats an absent suffix (the legacy fixed `<name>.tmp` from the old
  `bin/sc:809`), a non-integer suffix and a non-positive suffix as **stale** and unlinks them; only a
  positive pid that `os.kill(pid, 0)` reports as live is spared. `PermissionError` (a live process
  owned by someone else) also counts as live. All three stale shapes tested.

---

## Open issues for review

1. **Progress granularity is bounded by the chunk size, not by the network.**
   `http.client.HTTPResponse.read(n)` blocks until it has `n` bytes (or EOF), so the 64 KiB loop
   emits exactly **one** redraw for any body under 64 KiB, regardless of how the server chunks it.
   Real rule-sets are 8 KB–450 KB, so `geosite-private.srs` (696 B) and `geosite-google.srs` (7.9 KB)
   will show only their final 100 % state on a TTY. That satisfies B-18 (the line still updates and
   the final state reports the outcome) but **QA must size AC-16's fixture above 64 KiB** or the
   "at least two intermediate states" assertion is unpassable for reasons unrelated to the code. This
   also matters for T-08 (installer binary progress), which shares the visual language.
2. **`install.sh` re-run now restarts sing-box twice** — F-8, expected and recorded, not a defect.
   Step 6's `sc update-rules` regenerates + restarts (the config exists on a re-run), then step 7's
   `sc reload` regenerates + restarts again. Both land in `LOG_SINK`. Fresh installs are unaffected
   (no config yet → the recovery block is skipped entirely; verified).
3. **PID reuse remains a residual** (F-5b, accepted at the gate): on a busy host a recycled pid can
   make one stale `.tmp.N` file un-cleanable. The load-bearing half is structural — `ruleset_report()`
   iterates `RULESET_FILES`, so a `.tmp.*` file can never be mistaken for a rule-set (asserted).
4. **`ghfast.top` content-encoding signature** (F-6): if a proxying mirror ever returns gzip, the body
   fails the magic check for all four files and that base is marked dead with cause
   `not a rule-set file`. Diagnosable, handled gracefully, worth knowing when reading a bug report
   that says "not a rule-set file from every mirror".
5. **Pre-existing, deliberately not fixed:** `capture_output=` (3.7+) still at `bin/sc:822`, `:864`,
   `:1159` — **three** sites, not the two E-12 claims (GR V-2). None is inside a line this task wrote
   or rewrote; the one 3.8-ism that *was* inside the rewritten loop (`unlink(missing_ok=True)`) is
   gone. PM's Q9 pool row must list all three. Likewise the `t("ls.idx")` English-header defect
   (`bin/sc` `ls` table) is untouched and belongs to its own row.

---

## Dev-map updates

`docs/dev-map.md` was an unfilled template with no mention of `bin/sc`. Rewritten with:

- **Folder layout** — real tree (`bin/sc` as the entire CLI, `install.sh` self-contained for
  `curl | bash`, `systemd/`, the mirrored READMEs), plus "no build step, no manifest, no test dir".
- **`bin/sc` internal sections table** — the in-file section order and what lives in each, including
  the two facts a harness author needs: the path globals are only referenced inside function bodies,
  and `_init_files()` is reachable only from `main()`, so importing touches nothing under `/etc`.
- **Reusable utilities table** — the new rule-set model (`srs_reject_reason` + its three adapters,
  `ruleset_report`/`usable_tags`, `_filter_rules`, the fetch helpers), `t()`/`TRANSLATIONS`, the
  `⚠️`-to-stderr pattern, and the apply mechanisms.
- **Patterns to follow** — config regenerated not patched; English-sentence translation keys with
  matching placeholders (and why `ls.idx` is not a pattern to copy); the Python 3.6 floor with its
  three known violations; the three owner-fixed timeouts; the stdout/stderr split; the no-`\r`
  non-TTY rule.
- **Patterns to avoid** — no second notion of "the rule-set is there"; no rule-set tag reference that
  bypasses `_filter_rules`; no splitting `bin/sc` into modules; never import `bin/sc` in a harness
  without neutralising auto-elevate **and** setting `SYSTEMD = OPENRC = False`.

---

## Insight to surface

- `http.client.HTTPResponse.read(n)` blocks until it has `n` bytes, so a chunked-download progress
  loop redraws once per chunk size — not once per network packet — and a body smaller than the chunk
  size produces exactly one (100 %) redraw regardless of how the server writes it · evidence: PTY
  capture in T-02 dev verification, 404-byte body → 1 state vs 200 000-byte body → 4 states.
- All four `.srs` mirrors (jsDelivr, testingcf, ghfast, raw.githubusercontent) serve byte-identical
  content, and the smallest real rule-set is `geosite-private.srs` at **696 bytes** · evidence:
  per-base manual fetch 2026-07-31, `bin/sc` `SRS_MIN_BYTES` comment.
- `sing-box` 1.13.15 accepts a `route` block with **no** `rule_set` key at all, so omitting the
  optional field is safe and `[]` is not needed · evidence: real `sing-box check` over all 16
  usable/unusable subsets, T-02.

---

## Verdict

**READY FOR REVIEW**

---
---

# Fix pass — D-1 / Amendment A-1

> Appended 2026-07-31 after `ROLLBACK: developer` from QA (`06_TEST_REPORT.md` §6, D-1 MAJOR).
> Authoritative spec for this pass: `02_SOLUTION_DESIGN.md` **Amendment A-1** (revised §6.2, §5.3,
> §5.4, §9 R4/R8, §10.2). Everything above this line describes the first pass and is unchanged.

## Summary

The download loop now keeps **two** lists. `causes` is untouched — every base in list order,
dead-skips included, feeding the total-failure line (B-15/AC-13 literal does not move). The new
`tried` holds only the bases actually contacted and rejected **for this file**, and is rendered onto
the **same** completion line by the **same** `print`, so a broken mirror is visible even when a later
base succeeds. Two small previously-flagged items were fixed alongside: the `_filter_rules`
other-matcher comment now warns about AND-semantics broadening, and two stale symbol/section names in
`docs/dev-map.md` were corrected.

## Files changed (this pass)

- `bin/sc` — `cmd_update_rules()`: added `tried`; the success branch composes
  `t("; fell back after: {causes}", causes="; ".join(tried))` (empty string when `tried` is empty)
  and appends it to the existing `t("OK ({size} bytes)")` inside one `print`. The `except` branch
  builds `entry` once and appends it to **both** lists. `dead`-skips append to `causes` only.
- `bin/sc` — `TRANSLATIONS["zh"]`: one new key,
  `"; fell back after: {causes}"` → `"；已回退，前序镜像未成功：{causes}"` (placeholder set identical,
  leading `; ` intentional — it is concatenated onto `OK (...)`).
- `bin/sc` — `_filter_rules()`: comment only. Now states that sing-box ANDs a rule's matchers, so
  dropping `rule_set` from a rule that carries another matcher leaves a rule matching **more** than
  before, that the branch is dead against today's config, and that a future mixed-matcher rule would
  be silently broadened. **Behaviour unchanged** (B-5 mandates it; QA D-3 asked only for the comment).
- `CHANGELOG.md` — one clause in the existing multi-mirror bullet describing the new fallback note
  and stating that it is absent when base 1 works.
- `docs/dev-map.md` — `# Share-link parsers` → `# Share-URL parsers`, dispatcher named
  `parse_share_url` (not `parse_link`, `bin/sc:474`); `restart_service()` / `reload_or_restart()`
  moved from the `# Clash API` row to `# Config generation` (`bin/sc:829,836`), leaving
  `clash_api()` / `is_running()` under `# Clash API`.

Not touched, deliberately: `--mirror` sudo/scheme hardening (D-2), the `capture_output=` / `text=`
floor violations, the `_temp_path` prefix coupling, D-4 and D-5 — PM filed those as separate rows.

## verify_all result

| | PASS | WARN | FAIL | SKIP | exit |
|---|---|---|---|---|---|
| Baseline (this pass, pre-edit) | 16 | 0 | 0 | 2 | 0 |
| After the fix | 16 | 0 | 0 | 2 | 0 |

**Delta: 0.** No FAIL, no new WARN, no test removed. `B.2`/`B.3` remain `SKIP` (Q8). `F.6` still PASS
with this appended section (`04_DEVELOPMENT.md` stays under the 500-line cap).

## Re-run of the ACs §6.2 lists

Driven by a fresh in-process reproducer (`<scratchpad>/fixlib.py` + `driver.py`, threaded
`http.server` stubs, real pipe for the non-TTY runs, `pty.openpty()` for the TTY run). QA's own
harness is the authoritative one and should be re-run at stage 7.

| AC | Result |
|---|---|
| AC-10 (base 1 = HTML 200, base 2 = valid) | **FIXED.** `↓ geoip-cn.srs ... OK (164 bytes); fell back after: http://…/geo -> not a rule-set file`; files 2-4 plain `OK`, base 1 hit **once** |
| AC-11 (refused → 404 → valid) | **FIXED.** Both failing bases named on the completion line with distinct causes (`<urlopen error [Errno 111] Connection refused>`; `HTTP Error 404: Not Found`) |
| AC-18 (over-declared `Content-Length`, then a good base) | Cause now visible: `…OK (164 bytes); fell back after: … -> truncated: got 164 of 5164 bytes` |
| AC-12 / AC-21 / AC-23 | Dead-marking, hit counts (1 for a failed base, 4 for the good one) and exit status unchanged |
| AC-13 (all bases fail) | **Unchanged**, verified: `failed: <b1> -> not a rule-set file; <b2> -> HTTP Error 404…` on stdout, dead-skip text on files 2-4, aggregate `4 ruleset(s) failed to update` alone on stderr, exit 1 |
| AC-15 | Exactly 4 `↓` lines per run, `b"\r" not in` and `b"\x1b" not in` the piped stdout in all 5 scenarios |
| AC-16 / AC-17 | TTY run under `pty`: redraws still present, completion line carries the note and is terminated before the next prefix is drawn (§9 R4's wrap note) |
| AC-14 | AST extractor re-run over `bin/sc`: **68** `t()` call sites, **63** distinct keys, **63** zh entries, 0 placeholder mismatches, 0 kwarg gaps, 0 orphan keys, 0 keys without a zh entry. zh run rendered `成功（164 字节）；已回退，前序镜像未成功：… -> 不是规则集文件` |
| AC-3 | All-usable config compared byte-for-byte against `git show main:bin/sc`'s `generate_config()` with a normalised `RULES_DIR`: **identical**, 5167 bytes. Happy-path stdout is still four plain `OK` lines — `tried` is empty, so the note is `""` |
| AC-25 / AC-26 | Product diff still exactly `bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`; the added lines contain no `capture_output=`, `text=True`, `missing_ok=`, walrus, dataclass, f-string `=` or dict-merge; no timeout constant touched (3 / 8 / 30) |

## Design drift (if any)

None. A-1 was implemented as written — two lists, dead-skips excluded from `tried`, one `print`, the
key text and both translations exactly as §5.4 specifies.

One in-scope addition A-1 does not mention: the **CHANGELOG clause**. A-1 changes user-visible output,
`CHANGELOG.md` is inside the design's own §2 file list and AC-25's diff scope, and the existing bullet
would otherwise describe an output shape that no longer matches. Flagging it so the reviewer sees it
rather than discovers it: `DESIGN DRIFT (documentation only, no behaviour)`.

## Open issues for review

- D-4 (a local `OSError` on temp creation is reported as a mirror failure, with the temp path in the
  message) now also reaches the **success** line via `tried` when a later base works. Same text, one
  more place it can appear. Out of scope by instruction; the D-4 row should account for it.
- The note's length is bounded by `len(bases) - 1` entries and by one real cause per base per run, so
  the worst case with the four built-in bases is three causes on one line. Acceptable per §9 R8, but
  it is the longest line `install.log` will carry on a success.

## Dev-map updates

Corrections only, no new module (three lines edited in the `bin/sc` internal sections table):

- `| # Share-URL parsers | parse_vless / vmess / trojan / ss / hy2 / tuic → dispatched by parse_share_url. |`
- `| # Config generation | … Also holds the two apply helpers restart_service() and reload_or_restart(). |`
- `| # Clash API | clash_api(), is_running(). |`

## Insight to surface

- A per-item "one line of output" contract silently deletes information whenever the loop that
  produces it can `break` early — the failure text has to be carried to the surviving line, not
  emitted where it is discovered · evidence: `bin/sc` `cmd_update_rules`, D-1 in
  `06_TEST_REPORT.md` §6 (four clean `OK` lines and an empty stderr while a mirror was broken).

## Fix pass — A-2 (2026-07-31)

Scope: one token, applied exactly as `02_SOLUTION_DESIGN.md` §5.4 / §9 R10 now specify. Nothing else
in the implementation moved — no new key, no shape change, still two lists (`causes` / `tried`),
dead-skips still excluded from `tried`, one `print`, same completion line, no timeout constant touched.

- `bin/sc:140` — zh value of `"; fell back after: {causes}"`: `…前序镜像失败：{causes}` →
  `…前序镜像未成功：{causes}`. **The English key is unchanged** (the key *is* the English string) and the
  placeholder set is `{causes}` in both languages.
- `CHANGELOG.md:7` — the quoted sample string updated to the shipping text.
- This document, §"Files changed (this pass)" and the AC-14 row above — the two places that quoted the
  old zh string now quote what ships. Earlier sections are otherwise left as written.

Re-verification (all runs against a patched sandbox copy of `bin/sc`: `CFG_DIR` moved to a temp dir,
auto-elevate neutralised, `systemctl` shimmed to "not running", local HTTP mirrors):

| Check | Result |
|---|---|
| AC-14 (AST extractor over `bin/sc`) | **68** `t()` call sites, **63** distinct keys, **63** zh entries, 0 placeholder mismatches, 0 kwarg gaps, 0 orphan zh keys, 0 keys without a zh entry — identical to the pre-A-2 numbers |
| A-2 core assertion | zh fallback-**success** output contains no `失败：` anywhere; the note renders as `成功（164 字节）；已回退，前序镜像未成功：<base> -> 不是规则集文件` |
| AC-10 zh | Failing base + cause on the same success line; note on file 1 only (dead-skips stay out of `tried`); exit 0 |
| AC-11 zh | Both failed bases named with distinct causes (`不是规则集文件`; `HTTP Error 404: Not Found`) on one success line, still free of `失败：` |
| AC-18 zh | `…成功（164 字节）；已回退，前序镜像未成功：… -> 传输不完整：收到 164/5164 字节` |
| AC-13 zh (total failure, unchanged) | All four lines still `失败：…`, dead-skip text on files 2-4, aggregate `4 个规则集更新失败` alone on stderr, exit 1 — so `失败：` now marks *only* "this file was not updated", which is R10's contract |
| AC-15 | Exactly 4 `↓` lines per run, no `\r`, no `\x1b` in the piped stdout, in every scenario |
| en pass | `OK (164 bytes); fell back after: <base> -> not a rule-set file` — byte-identical to the pre-A-2 English output |
| AC-25 / AC-26 | Product diff still exactly `bin/sc`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`; no timeout constant (3 / 8 / 30) touched |

`verify_all` (`bash .harness/scripts/verify_all.sh`), baseline taken before the edit and re-run after:
**PASS 16 / WARN 0 / FAIL 0 / SKIP 2** both times — delta 0.

No deferred pool item was taken on in this pass (`--mirror` sudo/scheme hardening, `capture_output=` /
`text=`, `_temp_path` coupling, D-4, D-5 all untouched).

### Note for the reviewer (process, not code)

While building the sandbox for the zh re-run, a first attempt ran a patched copy of `bin/sc` **without**
neutralising the auto-elevate block at `bin/sc:77-78`, which is `os.execvp("sudo", ["sudo",
"/usr/local/bin/sc"] + sys.argv[1:])`. That re-exec (a) ignores the file actually being run and starts
the **installed** `/usr/local/bin/sc`, and (b) drops the environment, so `SB_RULES_BASE` did not reach
the elevated process. Effect: one real `sc update-rules` ran on this machine against the built-in
mirrors and restarted `sing-box`. Idempotent maintenance, no data touched; the service was re-checked
as `active` / `enabled` and all four rule-sets are present and fresh. No repository file was affected.
All results in the table above come from the corrected sandbox. This is *also* live evidence for the
already-deferred `--mirror` / sudo hardening row: an unprivileged `SB_RULES_BASE=… sc update-rules`
silently uses the built-in bases, because the variable does not survive the sudo re-exec.

## Verdict

**READY FOR REVIEW**
