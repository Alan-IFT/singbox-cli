# 02 — Solution Design — config-degrade-missing-rulesets (T-02)

- **Task ID**: T-02 (absorbs pool row T-03 `ruleset-mirror-fallback` + the ruleset half of the download-progress request)
- **Mode**: full · **Date**: 2026-07-31 · **Upstream**: `01_REQUIREMENT_ANALYSIS.md` verdict `READY`
- **Verdict**: `READY` (amended: A-1, A-2)
- **Amendment A-2** · 2026-07-31 · code review MINOR (`05_CODE_REVIEW.md` § `Delta review — D-1 / Amendment A-1`): A-1's **zh** rendering put `失败：` — the substring `t("failed: {e}")` produces at `bin/sc:126`, which in an `install.log` reads "this file was not updated" — onto a **success** line, defeating in Chinese exactly the collision `.harness/rejected-decisions.md:44-45` (A-1's own record) says A-1 avoids. The English key already honours it. Changed **only**: §5.4 (the zh side of one key, `前序镜像失败：` → `前序镜像未成功：`, plus the rule that produced the miss) and §9 (new R10, carrying the collision audit of all 12 new zh strings). English key text, placeholder set (`{causes}` in both languages), key count, output shape, streams, `tried`/`causes` split, dead-skip exclusion, the single `print` and the completion line are all **unchanged** — A-1 stands in full. The developer implemented §5.4 character-for-character and is not at fault; the defect was in this document. Code sites: `bin/sc:140` (one token) and the string as quoted in `CHANGELOG.md:7`. Re-run: **AC-14**, plus the zh pass of AC-10 / AC-11 / AC-18 (rendered text changes, shape does not).
- **Amendment A-1** · 2026-07-31 · rollback from QA, defect **D-1** (`06_TEST_REPORT.md` §6): a per-base failure was discarded whenever a later base succeeded, because §6.2's pseudocode dropped `causes` on `break`. Changed **only**: §5.3 (one new output line), §5.4 (one new key), §6.2 (pseudocode revised **in place** + rationale and the re-run list), §9 R4/R8, §10.2. §3.2's B-2 table and §13's bullets were condensed to prose to stay inside the 500-line cap — no design content retracted. Everything else stands as approved in `03_GATE_REVIEW.md`.
- **Partition assignment**: omitted — `.harness/agents/dev-*.md` does not exist (single-developer project, `.harness/rules/50-singbox-cli.md` §Partitioning).

---

## 1. Architecture summary

`bin/sc` gains one rule-set model and nothing else: two module constants (`SRS_MAGIC`,
`SRS_MIN_BYTES`) and one pure predicate `srs_reject_reason(head, size)` that is the **single**
definition of "is this rule-set usable?". Everything else consults it. `ruleset_status(path)`
applies it to a file on disk; `_fetch_to_temp(...)` applies it to bytes coming off a socket before
they are ever installed; `_status_text(status)` renders its verdict bilingually for both consumers.
`RULESET_URLS` (filename → one absolute URL) becomes `RULESET_FILES` (filename → relative path) plus
an ordered `RULESET_BASES` list, so the same relative path is tried against four mirrors. Config
generation asks `ruleset_report()` once, builds `route.rule_set` **only** from usable tags, and runs
both `dns.rules` and `route.rules` through one `_filter_rules()` — the same set object decides
definition and reference, so a dangling reference is structurally impossible in either array.
`cmd_update_rules` becomes a thin orchestrator over that model and, when a rule-set that was unusable
at the start of the run becomes usable, regenerates the config (never patches it) so the promised
"补齐后自动恢复" is finally true. No new file, module, config key, dependency or timeout change.

---

## 2. Affected modules

| Path | Change |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | Only production file touched. Constants block (`:45-50`), new `# ==== Rule-sets ====` section inserted before `# ==== Config generation ====` (`:453`), `generate_config()` (`:455-557`), `cmd_update_rules()` (`:804-825`), `TRANSLATIONS` (`:60-123`), `HELP_EN`/`HELP_ZH` (`:980`, `:1025`), argparse (`:1069`). |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | User-visible entry. |
| `/home/alan/Programs/singbox-cli/README.md` `:103-111` | `--mirror` + `SB_RULES_BASE` in the "Ruleset update" block. |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` `:103-111` | Same, matching position. |
| **Not touched** | `install.sh`, `uninstall.sh`, `systemd/*`, `.harness/scripts/verify_all.sh`, `CONTEXT.md` (see §11). |

Harness bookkeeping written by the pipeline itself (`docs/features/**`, `.harness/rejected-decisions.md`)
is outside AC-25's product diff — QA must not read its own artifacts as a diff violation.

---

## 3. Module decomposition

All nine functions live in one new section `# ============ Rule-sets ============`, inserted between
the share-URL parsers and `# ============ Config generation ============` (before current `bin/sc:453`).
Names are final; signatures are contracts.

### 3.1 Constants (replace `bin/sc:45-50`)

```python
SRS_MAGIC = b"SRS"
# Floor only has to exclude empty / stub bodies: the magic check rejects error pages and the
# Content-Length equality check catches truncation. It MUST stay strictly below the smallest
# real rule-set (geosite-private is a handful of suffixes) — a floor that rejects a correctly
# downloaded file would re-create the very bug this task removes. See design §7 Q1 / AC-27.
SRS_MIN_BYTES = 16

RULESET_FILES = (                          # (installed filename, path relative to a base)
    ("geoip-cn.srs",        "geoip/cn.srs"),
    ("geosite-cn.srs",      "geosite/cn.srs"),
    ("geosite-google.srs",  "geosite/google.srs"),
    ("geosite-private.srs", "geosite/private.srs"),
)
RULESET_BASES = (
    "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo",
    "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo",
    "https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo",
    "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo",
)
# Keys of a routing rule that answer rather than match. A rule whose only matcher was a
# rule_set reference is dropped once that reference is gone (B-5).
RULE_ANSWER_KEYS = frozenset(("outbound", "server", "action", "rcode"))
```

A **tuple of pairs**, not a dict: `RULESET_FILES` order is the emission order of `route.rule_set`
and it must equal today's order for AC-3; tuples make that guaranteed rather than
CPython-3.6-dict-ordering-dependent.

### 3.2 The judgment (the abstraction this task exists to create)

```python
def srs_reject_reason(head, size):
    """The one definition of an unusable rule-set body.

    head -- first bytes of the body (may be shorter than SRS_MAGIC or empty)
    size -- total byte count of the body
    Returns None when the body is usable, else "too-small" or "bad-magic".
    Pure: no I/O, no globals beyond the two constants above.
    """
```
Order is fixed: `size < SRS_MIN_BYTES` → `"too-small"` **first** (so a 0-byte file reports
`too-small`, BC-2/BC-15), then magic → `"bad-magic"` (BC-5), else `None`.

```python
def ruleset_status(path):
    """Usability of one rule-set file. Never raises, never writes.

    Returns exactly one of:
      "usable" | "absent" | "bad-magic" | "too-small" | "unreadable"
    """
```
Body: `path.exists()` false → `"absent"`, unless `path.is_symlink()` (dangling symlink) → `"unreadable"`
(BC-4); `not path.is_file()` → `"unreadable"` (BC-3, directory); read `st_size` and the first
`len(SRS_MAGIC)` bytes inside one `try/except OSError → "unreadable"`; return
`srs_reject_reason(head, size) or "usable"`.

**Refinement vs. B-2 (flagged for GR, approved).** B-2 asks for a state plus a machine-distinguishable
reason; this returns **one flat token** carrying both — `usable` → usable, `absent` → absent, and
`bad-magic` / `too-small` / `unreadable` → invalid with the token itself as the reason — because four
call sites only ever test `== "usable"` and one formats it. `state` stays a pure function of the token,
so `sc doctor` (T-05) loses nothing. *(Table condensed to prose under Amendment A-1; nothing retracted.)*

```python
def ruleset_report():
    """[(tag, filename, status), ...] for every known rule-set, in RULESET_FILES order.

    tag is the filename without ".srs" — the exact tag the config uses. Pure query:
    no network, no service, no config, creates/modifies/deletes nothing (B-3).
    """

def usable_tags(report):
    """set of tags whose status is "usable"."""   # 3 call sites: generate_config, before/after

def _status_text(status):
    """Bilingual phrase for a non-usable status: t("missing") / t("not a rule-set file")
    / t("file too small") / t("unreadable")."""
```
**Trap for the developer:** this must be a function, not a module-level dict of `t(...)` values —
`LANG` is assigned in `main()` *after* import, so any `t()` evaluated at import time freezes English.

### 3.3 Config-side consumers

```python
def _filter_rules(rules, usable):
    """Return the rules that survive, with every reference to a rule-set outside
    `usable` removed. Mutates surviving rules in place (JSON key order preserved).

    Per rule: keep only usable tags; a rule that keeps all of them is untouched; a rule
    left with no tag is dropped unless it carries a matcher other than rule_set, in which
    case rule_set is deleted and the rule kept. Called for BOTH dns.rules and route.rules.
    """

def _warn_degraded(report):
    """Emit the bilingual degradation warning on stderr (Q4). No-op when nothing is
    unusable. Two wordings: all-unusable vs partial (Q2)."""
```
`_filter_rules` is the seam that makes finding #1 structural: it keys off the presence of a
`rule_set` key, not off which array the rule came from, so `dns.rules` (`bin/sc:497,498,501`) and
`route.rules` (`:522,524,527,528`) get one identical judgment. The "no other matcher" branch is
dead for today's config (every rule-set rule is `{action-key, rule_set}` only) — it exists because
B-5 states it, and it degrades toward `final` rather than toward a broadened match.

### 3.4 Download-side consumers

```python
def _ruleset_bases(mirror_values):
    """Effective base list. --mirror (repeatable, whitespace-splittable) beats
    SB_RULES_BASE; either REPLACES the built-in list (Q3); a whitespace-only override
    counts as absent (BC-23); falls back to list(RULESET_BASES)."""

def _clear_stale_temps(fname):
    """Remove this rule-set's leftover temp files from earlier runs. A temp whose pid
    suffix belongs to a live process (a concurrent `sc update-rules`) is left alone."""

def _fetch_to_temp(url, tmp, prefix, tty):
    """Stream `url` into `tmp` in 65536-byte chunks, drawing progress when tty, and
    validate the body. Returns the byte count.

    Raises on transport failure, on got != a declared Content-Length, or on any
    srs_reject_reason() rejection (message already bilingual). On a TTY the cursor is
    left at the end of a freshly redrawn `prefix` with no newline whether it returns or
    raises, so the caller prints its completion line identically in both modes.
    Never touches the rule-set's real path; the caller owns `tmp`'s removal.
    """
```
`timeout=30` is carried over verbatim from `bin/sc:812` — same value, new location.

---

## 4. Data-model changes

No database, no persisted state, no new settings key. The only structural change is in-memory:

| Before | After |
|---|---|
| `RULESET_URLS: Dict[str, str]` — filename → one absolute GitHub URL (`bin/sc:45-50`) | `RULESET_FILES: Tuple[Tuple[str, str], ...]` — filename → path relative to a base, **plus** `RULESET_BASES: Tuple[str, ...]` — ordered mirrors |
| `route.rule_set` — 4 unconditional literal entries (`bin/sc:530-539`) | list comprehension over `RULESET_FILES` filtered by `usable`; the key is **deleted** when the list is empty (an absent optional field is safer for `sing-box check` than `[]`, B-4 permits either) |
| temp file `fname + ".tmp"` (`bin/sc:809`) | `fname + ".tmp." + str(os.getpid())` — unique per invocation (E-6, B-21) |

---

## 5. Contracts

### 5.1 CLI surface

- `sc update-rules [--mirror URL]...` — `p.add_argument("--mirror", action="append", default=None)`
  at `bin/sc:1069`. Repeatable; each value is additionally split on whitespace, so
  `--mirror "a b"` and `--mirror a --mirror b` are equivalent.
- Environment: `SB_RULES_BASE="<url> [url...]"`. Documented with the sudo caveat (BC-25): a
  non-root caller's value is stripped by `env_reset` across `sc`'s auto-elevation
  (`bin/sc:52-54`, `install.sh:437-441`), so it only takes effect for a root caller; `--mirror` is
  the portable form.
- Exit status: unchanged — non-zero iff at least one rule-set is still unusable after all bases
  (B-16; `install.sh:456` branches on it).

### 5.2 Stream contract (preserved verbatim — insight-index)

| Stream | Content |
|---|---|
| stdout | `  ↓ <file> ... ` prefix, TTY progress redraws, per-file completion (`OK (n bytes)` — with A-1's `; fell back after: <causes>` note when an earlier base failed — / `failed: <cause>`), `→ Restarting sing-box ...`, `Rule-sets restored...`, `Done` |
| stderr | aggregate `{n} ruleset(s) failed to update` (via `sys.exit`), degradation warning, `⚠️ Config check failed` |

T-01's install-log reporting depends on the per-file **cause** staying on stdout; the composed
multi-base cause replaces `str(e)` inside the same `t("failed: {e}")` line and stays on stdout.

### 5.3 Output formats

Non-TTY (BC-21/AC-15) — byte-identical shape to today, exactly one line per file, **no `\r` anywhere**:

```
  ↓ geoip-cn.srs ... OK (152342 bytes)
  ↓ geosite-cn.srs ... failed: https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo -> <urlopen error timed out>; https://testingcf.jsdelivr.net/... -> HTTP Error 404: Not Found; https://ghfast.top/... -> not a rule-set file; https://raw.githubusercontent.com/... -> skipped (this source already failed in this run)
  ↓ geosite-google.srs ... OK (7916 bytes); fell back after: https://cdn.jsdelivr.net/gh/... -> not a rule-set file
```

The failure cause (line 2) is **one line**, bases joined by `"; "` as `"<base> -> <reason>"`, and it always
lists **every** base in the effective list — a base skipped by dead-marking carries the skipped
reason rather than being omitted (B-15/AC-13 literal). *Architect refinement:* the enumeration is
one long line rather than indented sub-lines, so AC-15's "exactly one completion line per rule-set"
stays literally true and `install.log` stays greppable.

**A-1 — line 3 is new.** A file served by base *k* > 1 carries, appended by the **same `print`** to the same
completion line, the causes of the bases actually contacted and rejected **for that file**. A base skipped by
dead-marking contributes nothing to it — it already spoke once, on the file where it really failed — and the
list is empty whenever base 1 works, so an all-usable run's bytes are unchanged. Rationale: §6.2.

TTY (B-18/AC-16), same line rewritten per chunk, erased with `\r` + `\033[K`:

```
  ↓ geoip-cn.srs ... 65536/152342 bytes (43%)
  ↓ geoip-cn.srs ... 131072/152342 bytes (86%)
  ↓ geoip-cn.srs ... OK (152342 bytes)
```
Without a declared length: `  ↓ geoip-cn.srs ... 65536 bytes` (no percentage, BC-14/AC-17). Raw
byte counts, no KB/MB (Q7). One redraw per chunk, **no time-based throttle** — a throttle would let
a fast local stub server produce zero intermediate states and make AC-16 unpassable.

### 5.4 New `TRANSLATIONS` keys (English source string → `zh`)

Placeholder sets are identical in both languages (B-23/AC-14). The `⚠️` prefix stays **outside** `t()`,
matching `bin/sc:555`. **A-2 rule:** no string that can land on a *success* line may contain `失败：` — the
zh rendering of `failed: {e}` (`bin/sc:126`), which greps as "this file was not updated". Audit: §9 R10.

| English key | zh |
|---|---|
| `` "{n}/{total} rule-sets unusable ({names}) — degraded to no-splitting mode: all traffic uses the default outbound. Run `sc update-rules` (or `sc reload` once the files are in place) to restore." `` | `` "{n}/{total} 个规则集不可用（{names}）—— 已降级为无分流模式：所有流量走默认出站。补齐后执行 `sc update-rules`（或 `sc reload`）即可自动恢复。" `` |
| `` "{n}/{total} rule-sets unusable ({names}) — the rules referencing them were skipped; the remaining rule-sets still apply. Run `sc update-rules` (or `sc reload` once the files are in place) to restore." `` | `` "{n}/{total} 个规则集不可用（{names}）—— 已跳过引用它们的分流规则，其余规则集仍然生效。补齐后执行 `sc update-rules`（或 `sc reload`）即可自动恢复。" `` |
| `"missing"` | `"缺失"` |
| `"not a rule-set file"` | `"不是规则集文件"` |
| `"file too small"` | `"文件过小"` |
| `"unreadable"` | `"无法读取"` |
| `"{done}/{total} bytes ({pct}%)"` | `"{done}/{total} 字节（{pct}%）"` |
| `"{done} bytes"` | `"{done} 字节"` |
| `"truncated: got {got} of {declared} bytes"` | `"传输不完整：收到 {got}/{declared} 字节"` |
| `"skipped (this source already failed in this run)"` | `"已跳过（该源在本次运行中已失败）"` |
| `"; fell back after: {causes}"` *(A-1; leading `; ` is intentional — it is appended to `OK (...)`)* | `"；已回退，前序镜像未成功：{causes}"` *(A-2 — was `前序镜像失败：`)* |
| `"Rule-sets restored: {names} — config regenerated"` | `"规则集已恢复：{names} —— 配置已重新生成"` |

Reused unchanged: `"OK ({size} bytes)"`, `"failed: {e}"`, `"→ Restarting sing-box ..."`, `"Done"`, `"{n} ruleset(s) failed to update"`.

**Do not invent namespaced keys** (`ruleset.absent`-style). `t()` returns the key itself when the language
table lacks it and `TRANSLATIONS` has no `en` table — that is why `bin/sc:642` literally prints `ls.idx` as an
English column header today (pre-existing defect, out of scope; PM: worth a pool row). Every key must be readable English.

### 5.5 Help text (both blocks, B-24)

`HELP_EN` (`bin/sc:980`) and `HELP_ZH` (`:1025`) replace the one-line `update-rules` entry with the
command plus two continuation lines naming `--mirror` (repeatable) and `SB_RULES_BASE`, in the
`update-interval` indentation style. Both READMEs get one matching line in the "Ruleset update" /
"规则集更新" code block plus the sudo caveat sentence.

---

## 6. Flow

### 6.1 `generate_config()` (`bin/sc:455`)

```
load nodes ─► build the config literal exactly as today (dns.servers, dns.rules ×8, inbounds,
              outbounds, route.rules ×12, experimental — all unchanged, B-7)
   │
   ├─ report = ruleset_report(); usable = usable_tags(report)   ◄── the ONE query (B-1/B-3)
   ├─ route["rule_set"]  = [defs for usable tags only]  (empty ⇒ key deleted)
   ├─ dns["rules"]       = _filter_rules(dns.rules,   usable)   ─┐ same set, same function,
   ├─ route["rules"]     = _filter_rules(route.rules, usable)   ─┘ two call sites
   ├─ _warn_degraded(report) ─► stderr, bilingual, only when something is unusable
   └─ write config.json (0600) ─► `sing-box check` ─► True (degradation is NOT an error, B-9)
```
One `usable` set drives definitions and both reference arrays: a tag can never be referenced
without being defined (AC-6, all 16 subsets).

### 6.2 `cmd_update_rules(args)` (`bin/sc:804`)

```
bases   = _ruleset_bases(args.mirror)        # --mirror > SB_RULES_BASE > built-ins
tty     = sys.stdout.isatty()
before  = usable_tags(ruleset_report())      # for B-17
dead    = set()                              # per-run dead bases (B-13, Q6)

for fname, relpath in RULESET_FILES:
    print("  ↓ {fname} ... ", end="", flush=True)
    _clear_stale_temps(fname)                       # BC-20
    causes = []   # EVERY base in list order, incl. dead-skips -> the total-failure line (B-15/AC-13)
    tried  = []   # ONLY bases contacted and rejected for THIS file -> the completion-line note (A-1)
    for base in bases:
        if base in dead:
            causes.append(base + " -> " + t("skipped ...")); continue    # NOT appended to `tried`
        url = base.rstrip("/") + "/" + relpath      # B-10 trailing-slash tolerance
        try:  got = _fetch_to_temp(url, tmp, prefix, tty)   # streams + validates
              tmp.replace(target)                   # atomic, only after validation (B-12/B-21)
              note = t("; fell back after: {causes}", causes="; ".join(tried)) if tried else ""
              print(t("OK ({size} bytes)", size=got) + note)   # ONE print, ONE line (A-1, AC-15)
              break
        except Exception as e:
              entry = base + " -> " + str(e)
              dead.add(base); causes.append(entry); tried.append(entry); unlink tmp   # B-22
    else:  # every base exhausted
        failed.append(fname); print(t("failed: {e}", e="; ".join(causes)))   # B-15, stdout, UNCHANGED

after  = usable_tags(ruleset_report())
gained = sorted(after - before)
if gained and CFG_PATH.exists():             # B-17 / BC-26; BC-27 keeps the fresh install clean
    ok = generate_config()                   # REGENERATED, never patched (rule 50)
    print(t("Rule-sets restored: {names} ...", names=", ".join(gained)))
    if ok and is_running(): print("→ Restarting sing-box ..."); restart_service()
    applied = True
if failed: sys.exit("\n" + t("{n} ruleset(s) failed to update", n=len(failed)))   # stderr, non-zero
if not applied and is_running(): print("→ Restarting ..."); restart_service()     # BC-28, as today
print(t("Done"))
```

**Amendment A-1 — a failed base must stay visible when a later base succeeds.** The loop previously dropped `causes` on `break`, so a rejected mirror was reported **only** on total failure (QA D-1: AC-10's "assert the failure of base 1 appears in the output" and AC-11's "the output names bases 1 and 2 with distinct causes" were unsatisfiable *by design*). That is gate F-7's blind spot exactly — on the target network a later mirror usually *does* work, so a mirror-path typo or a silently-broken base ships invisible in `/var/log/sing-box/install.log`, and the §7 Observability NFR holds only on total failure. Fix: `tried`, rendered onto the same completion line. **Rejected shapes:** a second `↳ base -> reason` line (B-19/AC-15 fix the non-TTY stream at one line per rule-set, and the timer / `install.log` consumer reads that shape); stderr (the insight-index keeps `update-rules`' per-file causes on stdout and T-01 depends on it); reusing the existing `failed: {e}` key instead of adding one (free, but it would make a *successful* line match the `failed:` / `失败：` grep that today means "this file was not updated" — **A-2**: the *new* key's zh rendering has to honour that promise too, see §5.4 and §9 R10). `tried` excludes dead-skips, so files 2-4 of a run whose base 1 died stay exactly as clean as today, and it is empty when base 1 works, so the happy path is byte-identical. No timeout, stream, exit-status or config-side behaviour moves.

**Re-run after implementation:** AC-10, AC-11 (the defect itself); AC-12, AC-18, AC-21, AC-23 (multi-base runs whose expected output now carries the note — AC-18's truncated body is among D-1's 9 swallowed causes); AC-13, AC-15, AC-16, AC-17 (shapes that must **not** move: the total-failure line, one completion line and no `\r` on a pipe, the TTY redraw, no `%` without a declared length); AC-14 (one new key, both languages); AC-3 plus §10.2's "unchanged when nothing is wrong" clause as the regression guard. Unaffected: AC-1..AC-9, AC-19, AC-20, AC-22, AC-24..AC-27.

**Finding #2 resolved.** Recovery runs *before* the non-zero exit, so a partial recovery
(3 of 4 files restored) still regenerates. `CFG_PATH.exists()` is the fresh-install guard: at
`install.sh:456` no config exists yet, so nothing is created and nothing is started (BC-27);
`install.sh:479`'s later `sc reload` produces the first config. A stopped service is **not**
started by a recovery (`generate_config()` only), preserving `sc off` semantics.
**Hot-apply is not available here** (rule 50 prefers it): the Clash API (`bin/sc:576`) can switch
proxy and mode only; a changed `route.rule_set` is structural, so `restart_service()` is the
minimum that applies it. `sc reload` (`bin/sc:928` → `reload_or_restart` → `generate_config`) needs
no change — it picks up newly-present rule-sets automatically once the judgment is inside
`generate_config()`; the design verified that path rather than assuming it.

**Finding #4 resolved — time budget.** `dead` is populated on *any* failure (Q6: transport,
non-2xx, or validation). Worst case on a fully unreachable network: file 1 pays up to 4 × 30 s while
marking all four bases dead; files 2-4 pay 0 s. Total ≈ 120 s — identical to today's 4 × 30 s, with
no timeout constant touched (`bin/sc:583`, `:742`, `:812` untouched in value).

---

## 7. Deferred decisions (§8 Q1-Q9) — resolution

| Q | Decision | Note |
|---|---|---|
| Q1 floor | **16 bytes** (analyst (b)) | Adopted. Binding constraint recorded in the constant's comment: the floor must stay strictly below the smallest real rule-set; `geosite-private.srs` is a handful of suffixes and may well be under 512 B, and a floor that rejects a good file re-creates this exact bug. Magic + Content-Length equality do the real work. Raising it requires AC-27 measurement first. |
| Q2 warning | **Two wordings** (a) | Adopted; "已降级为无分流模式" is only used at n == total. |
| Q3 override | **Replace** (a) | Adopted; `--mirror` is a diagnostic instrument, silent fallback would make it useless. |
| Q4 stream | **stderr** (a) | Adopted; keeps `sc add`'s stdout a single result line. The insight-index stdout rule is about `update-rules` per-file causes, preserved in §5.2. |
| Q5 check retry | **No second pass** (a) | Adopted; a retry would mask unrelated config errors. |
| Q6 dead on validation | **Any failure marks dead** (a) | Adopted; it is what keeps the time budget flat (§6.2). |
| Q7 byte units | **Raw bytes** (a) | Adopted; consistent with `OK ({size} bytes)`. |
| Q8 verify_all B.2 | **Keep SKIP** (b) | Adopted. QA's harness lives in the scratchpad and is pasted into `06_TEST_REPORT.md` for T-07; committing a test tree here would break AC-25's diff assertion and pre-empt T-07. |
| Q9 3.7+ sites | **File a row** (a) | Adopted; this task removes only `unlink(missing_ok=)` at `bin/sc:819` (inside the rewritten loop) and adds no new violation. `:553`/`:857` untouched. |

**Architect refinements** (beyond the analyst's recommendations, flagged for GR): flat status token
(§3.2); single-line multi-base failure cause (§5.3); `\033[K` erase instead of space padding
(§9 R4); pid-liveness rule for stale temps (§9 R5). None contradicts a numbered behavior.

---

## 8. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Bilingual rendering | `t()` + `TRANSLATIONS` | `/home/alan/Programs/singbox-cli/bin/sc:60,172` | Reuse as-is; add 11 keys |
| Warning to stderr with ⚠️ | `sys.stderr.write("⚠️  " + t(...))` | `bin/sc:555` | Reuse the exact pattern |
| Atomic install of a file | `tmp.replace(target)` | `bin/sc:814` | Reuse; only the temp **name** changes (E-6) |
| HTTP fetch | `urllib.request.urlopen(url, timeout=30)` | `bin/sc:812` | Reuse; body read becomes chunked (B-20), timeout value unchanged |
| Regenerate + apply config | `generate_config()`, `reload_or_restart()`, `restart_service()`, `is_running()` | `bin/sc:455,567,560,590` | Reuse in the recovery path; no new apply mechanism |
| Config check | `subprocess.run([SB_BIN,"check",...])` | `bin/sc:552` | Untouched (its `capture_output=` 3.7+ violation is Q9's row, not ours) |
| Completion-line format | `"  ↓ {f} ... "` + `OK ({size} bytes)` / `failed: {e}` | `bin/sc:811,815,817` | Reuse verbatim so non-TTY output is unchanged |
| Exit-status contract | `sys.exit(t("{n} ruleset(s) failed to update"))` | `bin/sc:821` | Reuse verbatim (`install.sh:456` depends on it) |
| Stub-PATH test technique | T-01's harness | `docs/features/_archived/install-enable-start-split/06_TEST_REPORT.md` | Reuse for `sing-box check` stubbing |
| "is this rule-set usable?" | **(none — `path.exists()` was the only notion, and only implicitly via sing-box's own failure)** | — | New predicate justified: three consumers, one definition (rule 85 test 2) |
| Multi-mirror fetch | (none) | — | New; it is the same fetch loop, not a second one |

---

## 9. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | A 16-byte floor accepts a tiny non-rule-set stub | Magic check rejects error pages; Content-Length equality rejects truncation; `sing-box check` is the final gate. The opposite error (512 B rejecting a legitimate `geosite-private.srs`) is *permanent* and self-inflicted, so the asymmetry decides it. Residual risk carried until AC-27 runs on a networked host. |
| R2 | `sing-box check` might reject a `route` block with **no** `rule_set` key | `rule_set` is an optional field, so omission is the safest form; AC-7 exercises all 16 subsets. If a sing-box build ever rejects it, the one-line fallback is emitting `[]` (B-4 permits both). QA reports **unverified** where no `sing-box` binary exists. |
| R3 | Dead-base marking abandons a base that failed transiently for file 1 | Scope is one run only; the weekly timer and any manual re-run start with a clean slate, and `--mirror` forces a specific base. The alternative (retry every base per file) multiplies the wall-clock budget by 4, which the owner ruled out. |
| R4 | TTY redraw leaves debris when a shorter line replaces a longer one — worse with CJK double-width text, where character-count padding under-erases | Erase with `"\r" + line + "\033[K"` (and `"\r" + prefix + "\033[K"` on exit) instead of space padding: correct for any width, never wraps. Only ever emitted when `sys.stdout.isatty()`. **A-1:** the completion line may now be long enough to wrap on a TTY, which is harmless — it is terminated by `\n` before the next file's prefix is drawn, so no redraw ever has to erase a wrapped line. |
| R5 | Stale-temp cleanup (BC-20) could delete a **concurrent** run's in-flight temp (BC-19) | Temps carry a pid suffix; `_clear_stale_temps` skips any suffix whose process is still alive (`os.kill(pid, 0)` → `ProcessLookupError` means gone). Both boundary conditions hold simultaneously. |
| R6 | Recovery regenerating the config could start a service the user deliberately stopped | Recovery calls `generate_config()` alone and only adds `restart_service()` when `is_running()`; and it does nothing at all unless `CFG_PATH.exists()`. |
| R7 | A translated string with a placeholder the call site does not supply raises `KeyError` (E-10) | Every new key's placeholder set is listed in §5.4 and re-checked by AC-14's extractor; the zh strings use full-width parentheses, never `{}`. |
| R8 | The long single-line failure cause could be read as noise in `install.log` | It replaces `{e}` inside the existing `failed: {e}` line, so T-01's reader sees the same line shape; base URLs make "wrong mirror path" distinguishable from "unreachable network", which is the point of B-15. **A-1:** the fallback note on a *success* line has the same exposure and the same answer — it reuses the `causes` strings that already flow into the failure line (no new sanitisation, no `\r`), it is bounded by `len(bases) - 1` entries per file and by one real cause per base per run, and it is absent whenever base 1 works. |
| R9 | Developer copies the `ls.idx` namespaced-key style into new strings | §5.4 states the rule explicitly and AC-14 catches it (an English run would print the key). |
| R10 | **(A-2)** A zh rendering carries a token another line's zh rendering owns, so a human grepping `install.log` misreads it — realised by A-1: `失败：` on a *success* line | Rule in §5.4. Fix: `未成功`, chosen over `报错` because it is true for **every** cause kind (transport error, non-2xx, truncation, rejected body) while `报错` would be false for the three where the mirror answered fine and *we* rejected the body; it shares `成功` only with the `OK ({size} bytes)` text it is appended to, so no line that did not already match a `成功` grep starts matching one. **Audit of the other 11 new keys** (done under A-2, so this does not recur): `"skipped (this source already failed in this run)"` → `已跳过（…已失败）` carries `失败` without the colon, but it reaches output **only** through `causes`, which is rendered only inside the `失败：` total-failure line — §6.2's "dead-skips never enter `tried`" is the invariant that keeps it there, so moving a dead-skip into `tried` would re-open this defect in colon-less form; the two progress keys share `字节` with `成功（… 字节）` but are TTY-only and never reach a log file; the two degradation warnings share `不可用` with `"(unavailable)"` (`bin/sc:103`) yet both mean "something is wrong" and they go to stderr from a different command; `缺失` / `不是规则集文件` / `文件过小` / `无法读取` / `传输不完整：` / `规则集已恢复：` touch none of `失败` / `成功` / `错误：` / `⚠️`. No automated consumer greps the log (`install.sh:456` branches on exit status), so this is a legibility contract, not a machine contract — which is why it is MINOR, not a stream-contract break. |

---

## 10. Migration / rollout

1. **Backwards compatibility.** No persisted state changes: upgrade is an `install.sh` re-run or an
   `sc` file replacement, downgrade the reverse with no cleanup. Existing `rules/*.srs` are re-judged,
   not re-downloaded; a legacy `geoip-cn.srs.tmp` (old fixed name, `bin/sc:809`) is removed on that
   rule-set's next fetch by `_clear_stale_temps`.
2. **Behavior when nothing is wrong** (the common upgrade case): all four usable, base 1 answering,
   stdout not a TTY → output and generated JSON unchanged from `main` (AC-3, NFR). A-1 adds nothing to
   this case: `tried` is empty, so the note is the empty string and the four `OK` lines are byte-identical.
3. **No feature flag.** The degradation path *is* the failure path; gating it would keep the bug
   reachable. `--mirror` / `SB_RULES_BASE` default to today's intent (GitHub is still base 4).
4. **Rollback.** Restore the previous `bin/sc`; a config generated while degraded stays valid (strict
   subset) and the old code's `sc reload` re-adds the four unconditional entries — the old failure
   mode returns, nothing is corrupted.
5. **Implementation order** (one commit is fine): constants → judgment functions → `generate_config`
   wiring → `cmd_update_rules` rewrite → strings/help/README/CHANGELOG. `python3 -m py_compile bin/sc`
   after each step; `bash .harness/scripts/verify_all.sh` at the end.

---

## 11. Out of scope for this design

- Everything in requirement §4 (timeouts, `install.sh`, `systemd/`, `sc doctor`, `sc config --show`,
  restricted-network E2E, installer binary progress, `sing-box check` retry, rule-set semantics, new
  rule-sets, `.srs` file modes).
- **`CONTEXT.md` is deliberately not edited** (still an unmodified template, and AC-25 fixes the
  product diff to four files). The term is defined here and in the code comment instead —
  **usable rule-set**: a `.srs` file that exists, carries the `SRS` magic and meets `SRS_MIN_BYTES`;
  the single condition config generation and the downloader both consult. _Avoid_: "present",
  "downloaded", "available". If the owner adopts the glossary, it moves there verbatim.
- The `t('ls.idx')` English-header defect (`bin/sc:642,107-111`) and the two 3.7+ API sites
  (`bin/sc:553,857`) — both belong to other rows.
- Wiring `verify_all` B.2/B.3 (Q8 → T-07).

---

## 12. Consolidation record (rule 85)

**Call: keep T-02 and T-03 merged, and build the abstraction rather than the symptom list.**

- **Seam removed.** Split, T-02 would have shipped `path.exists()` as "is this rule-set usable?"
  while T-03 separately defined what a valid `.srs` is — an HTML error page would read as "present",
  the config would keep its entry, and sing-box would FATAL exactly as today. That is rule 85's
  test 2, which names this very pair as its precedent. The future edit it prevents: adding the
  download validator later would have forced a second edit to `generate_config()` to reconcile them.
- **Where the counter-rule binds.** No new file, module, package or config format. The whole model
  is **two module-level constants** (`SRS_MAGIC`, `SRS_MIN_BYTES`) and **one pure predicate**
  (`srs_reject_reason`), with thin named adapters around it (`ruleset_status` for a path,
  `_fetch_to_temp` for a socket, `_status_text` for the screen). The one new section in `bin/sc` is a
  section header, not a module. `_filter_rules` exists because the same judgment is needed at two
  call sites (`dns.rules`, `route.rules`) — two adapters, so a real seam.
- **Deletion test.** Delete `srs_reject_reason` and the magic/floor logic reappears in three places
  (config generation, download validation, whatever `sc doctor` grows) with three chances to disagree.
- **Third consumer.** Progress display is not a fourth notion: it is the same chunked fetch loop
  (`_fetch_to_temp`) that performs the validation, which is why B-20 and B-12 landed in one function.
- **Nothing dropped.** T-03's mirror fallback is §3.4 + §6.2; the download-progress request is §5.3.
  `BATCH_PLAN.md` `## Notes` already records the merge (lines 12-13, 30-49, 79-88) and no task-table
  change results from this design, so nothing further is written there.
- **Rejected-decisions.** Three deliberate declines recorded in `.harness/rejected-decisions.md`:
  `srs-size-floor-512-bytes`, `config-check-retry-without-rulesets`, `ruleset-unit-tests-in-t02`.

---

## 13. Test strategy note (for QA — no network-restricted VM required)

Executed in full by QA. `06_TEST_REPORT.md` §1 and §10 now carry the authoritative recipe — module loading
via `exec` with the single `os.execvp` line neutralised plus repointed path globals, the 8 disk fixtures, the
16-mask config assertions, threaded `http.server` bases, `pty.openpty()` vs a plain pipe, the `LANG = "zh"`
second pass, and the fact that a `urllib` transport cause is untranslatable by design — and hand QA's
`<scratchpad>/qa/` harness (8 files, 563 assertions) forward to T-07. *(Bullets condensed under Amendment
A-1 to stay inside the 500-line cap; nothing retracted, nothing weakened.)*

---

## Verdict

**READY (amended, A-1 + A-2).** No gap in `01_REQUIREMENT_ANALYSIS.md` — QA's D-1 and the review's zh-collision MINOR are both defects in *this* document, not in the requirement, and are fixed above; all nine deferred decisions still stand. The design stays confined to `bin/sc` plus the changelog and the two READMEs, changes no timeout constant, adds no file, module or dependency (one translation key), keeps the stdout/stderr split and the non-TTY one-line-per-rule-set contract, and stays within the Python 3.6 floor. A-2 is a one-token zh edit: no English output, no placeholder, no shape, no stream and no exit status moves.
**Next: the developer applies A-2 at `bin/sc:140` (`前序镜像失败：` → `前序镜像未成功：`) and in the `CHANGELOG.md:7` quotation, then re-runs AC-14 (the placeholder/zh-coverage extractor) plus the zh pass of AC-10 / AC-11 / AC-18, and re-asserts AC-3 and AC-15 as the unchanged-shape guard. A-1's own re-run list (§6.2) is otherwise unaffected.**
