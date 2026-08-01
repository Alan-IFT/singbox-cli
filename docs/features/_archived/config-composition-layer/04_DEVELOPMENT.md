# 04 — Development Record · T-14 `config-composition-layer`

Mode: **full** · Stage 4 · Decision authority: **deferred-human, defer-do-not-ask**. Upstream
`01` READY, `02` READY, `03` **APPROVED FOR DEVELOPMENT with 8 conditions** — all eight discharged
in §7. Implementation follows `02` exactly; every judgment call is recorded in §8. No design gap
was found, so no `BLOCKED ON DESIGN`.

---

## 1. Summary

`generate_config()` now **composes** `config.json` instead of *being* it: a module-level
`CONFIG_BASE` dict literal (moved out of the function as a pure text move), one computed overlay
`_runtime_overlay()`, and the user-owned `/etc/sing-box/override.json` applied last — all three
through the single `_merge()`. A drift record (`/etc/sing-box/.config.sha256`, a sha256 digest,
never a copy) makes "this file was hand-edited" a statement `sc` can make before it overwrites it.
**Zero content change**: with no override present the emitted bytes, stderr, return value and
`nodes.json` are identical to the pre-change build over 148 differential runs.

## 2. Build order actually followed (the gate made it non-negotiable)

1. **Baseline pinned from the working tree, before the first edit.**
   `cp bin/sc <scratch>/sc_baseline.py`, sha256
   `674be9f1e8256c6e75b8aa8cd5eed84167b15f4bb4b43bf787c1266c63e9d1e9`.
   `git diff --stat -- bin/sc` at that moment: **empty** — the working tree equalled `HEAD`
   (`f642ca7`). The PM's snapshot showing `M bin/sc` was stale; the dirty files were
   `CONTEXT.md`, `.harness/rejected-decisions.md`, `docs/tasks.md` (stage-2 artifacts). Recorded
   per condition 2; the copy — not `git show` — is what the differential ran against.
2. **Differential harness built and PROVEN to fail** (§4) before a single line of `bin/sc` moved.
3. **Literal moved**, then everything else.

## 3. Files changed

| File | Change |
|---|---|
| `bin/sc` | `copy` + `stat` imports; `OVERRIDE_PATH` / `STATE_PATH` in `# Paths`; 17 `t()` keys; new `# Config composition` section (`OverrideError`, `DIRECTIVES`, `_directive_list`, `OVERRIDE_MAX_BYTES`, `CONFIG_BASE`, `_dig`, `_directive_of`, `_anchor_index`, `_apply_directive`, `_merge`, `_load_override`, `_compose`, `_runtime_overlay`); drift trio `_config_digest` / `_record_generated` / `_warn_drift`; rewritten `generate_config()`; one `except OverrideError` handler in `main()` |
| `README.md` | 2 file-locations rows + new `## 🛠 Custom configuration (override.json)` section after `## 📂 File locations` |
| `README.zh-CN.md` | line-for-line mirror (both files 286 lines; heading and code-fence line numbers verified identical) |
| `docs/dev-map.md` | `# Paths` row (7 constants + the `TUN_IFACE` exception), new `# Config composition` section row, updated `# Config generation` row, 6 new reusable-utility rows, updated `_filter_rules` row, enlarged harness repoint list, one new "Patterns to follow" bullet |
| `docs/tasks.md` | open row R-12 extended with the second unwind (condition 8 — done here, not left to PM) |

Not touched: `install.sh`, `uninstall.sh`, `systemd/`, any timeout, `CHANGELOG.md` (delivery).

## 4. AC-4 — the non-vacuity proof, recorded

Three mutants of the **baseline** were generated (`make_mutants.py`), each breaking exactly one of
the four compared facts. The harness was run against each *before* `bin/sc` was touched:

```
=== mutant_m1 ===   "level": "warn"  ->  "level": "warns"     (one character, an emitted VALUE)
compared 148 differential runs (74 points x 2 languages)
RESULT: FAIL — 148 mismatch(es)
  subset00/a-no-nodes [en]                 config
      line 3 baseline :     "level": "warn",
      line 3 candidate:     "level": "warns",

=== mutant_m2 ===   dns."final" and dns."independent_cache" SWAPPED  (R-1's exact failure mode:
                                                                      same content, new key order)
compared 148 differential runs (74 points x 2 languages)
RESULT: FAIL — 148 mismatch(es)
  subset00/a-no-nodes [en]                 config
      line 108 baseline :     "final": "remote_dns",
      line 108 candidate:     "independent_cache": true,

=== mutant_m3 ===   "⚠️  " -> "⚠️ " in _warn_degraded  (stderr only; document untouched)
compared 148 differential runs (74 points x 2 languages)
RESULT: FAIL — 130 mismatch(es)
  subset01/a-no-nodes [en]                 stderr
      baseline : '⚠️  1/4 rule-sets unusable (geosite-private (missing)) — …'
      candidate: '⚠️ 1/4 rule-sets unusable (geosite-private (missing)) — …'
```

M3 fails on 130 of 148 rather than all 148 because the 18 all-usable runs emit no warning at all —
which is itself the right shape. **A key reorder that changes no value is caught (M2).** That is
the one failure R-1 named as hardest to spot by eye.

## 5. The 64-run differential — result

```
$ python3 t14_diff.py --baseline sc_baseline.py --candidate /home/alan/Programs/singbox-cli/bin/sc
compared 148 differential runs (74 points x 2 languages)
RESULT: PASS — byte-identical config, stderr, return value and nodes.json
```

74 points = 16 rule-set subsets × 4 node/active states (**64**, AC-1) + 10 extras: non-ASCII node
tag, non-ASCII tag with a stale `active`, one run each for `absent` / `bad-magic` / `too-small` /
`unreadable`, a mixed-status run, `CLASH_PORT=29137`, a `RULES_DIR` outside the config root, and a
three-consecutive-calls run (AC-11). Each point runs in **both** `en` and `zh` and compares config
bytes, stderr, the boolean return and `nodes.json` bytes, plus the fixture file list (the candidate
may add exactly `.config.sha256` and nothing else).

**The literal move, verified as a pure text move.** `diff` of the baseline's dedented
`config = {…}` against the candidate's `CONFIG_BASE = {…}` reports exactly four hunks: the name,
and the three position-holding placeholders. Nothing else moved, was re-typed or was re-indented:

```
1c1
< config = {
---
> CONFIG_BASE = {
38c38
<     "outbounds": [selector] + nodes + [{"type": "direct", "tag": "direct"}],
---
>     "outbounds": [],        # placeholder — _runtime_overlay() $replaces it
57,61c57
<         "rule_set": [ … comprehension over report … ],
---
>         "rule_set": [],     # placeholder — _runtime_overlay() $replaces it
67c63
<         "clash_api": {"external_controller": f"127.0.0.1:{CLASH_PORT}"},
---
>         "clash_api": {"external_controller": ""},    # placeholder — set per run
```

The move was performed by a script (`splice.py`) that extracts the block between anchors, dedents
it by exactly four columns with a per-line assertion, and applies three uniqueness-asserted
substitutions. **The literal was never re-typed by hand** — that was the whole point.

## 6. Everything the differential cannot see — 91 checks, 0 failed

`t14_semantics.py` drives the candidate only, in the same fixture envelope. Full output is 91
`ok` lines; the coverage map:

| ACs | Checks |
|---|---|
| AC-5 / AC-6 / AC-7 / AC-8 / AC-10 | `CONFIG_BASE` is a module-level data object; no literal left in `generate_config`; exactly one `_merge`; **the deletion test** (`_compose([override])` with the run-time overlay's call site removed still merges); `_filter_rules(rules, usable)` unchanged with exactly two call sites; no writer of `config.json` besides `_write_private`; no non-stdlib import |
| AC-13…AC-19 | deep merge keeps siblings *and* position (`log` = `{level, timestamp}`, in that order; top-level key order unchanged); `$replace`; `$prepend` / `$append` with base order intact; `$after` / `$before` anchored on `clash_mode: Direct` (the T-16/T-17 shape) with every other element's relative order preserved; two overlays composing at their own anchors; an inserted value carrying a nested `rule_set`, `domain_suffix` **and a literal `$append` key** emitted verbatim; bare array rejected over an existing array / accepted at an absent key |
| BC-7 / T-1 | `{}`, whitespace-only and zero-byte overrides each produce bytes identical to *absent*; `[]`, `null`, `0`, `"{"` stay malformed (both edges, as the gate's T-1 ruling required) |
| AC-20 / AC-21 | 25 error cases (BC-8…BC-14 + the shape assertion + 3 hostile-key cases), each driven through `main()`'s `reload` handler: `config.json` byte-identical afterwards, `SystemExit` with a **string** (exit 1), the message naming `OVERRIDE_PATH` *and* the specific problem, one physical line with no `\n` / `\r` / ESC, and `restart_service` never called |
| AC-22…AC-25 | drift line appears exactly once, names both paths, precedes the replacement, and clears on the next run; silent when unchanged; silent when there is no record, and the record is created; record is `^[0-9a-f]{64}\n$` at mode `0600` and contains no credential bytes |
| AC-26 | one `cmd_doctor` run on a fixture with a hand-modified `config.json`, a malformed `override.json` and no drift record → the tree is **byte-and-mode identical** afterwards, a report was produced, and no drift record was created |
| AC-27 / AC-28 | AST-extracted `t()` keys: 17 new, all present in the `zh` table, placeholder sets equal, no `失败：`, no namespaced key, all English prose, all render in both languages, and no *pre-existing* key regressed out of the table |

Rendered output, both languages (paths substituted for readability):

```
en  Cannot use /etc/sing-box/override.json: at dns.rules: unknown directive $patch — use one of
    $prepend, $append, $replace, $before, $after
en  Cannot use /etc/sing-box/override.json: at route.rules: $before matched 7 elements, but
    exactly one is required — match: {"outbound": "direct"}
en  ⚠️  /etc/sing-box/config.json was modified outside sc — those changes are about to be
    replaced; put them in /etc/sing-box/override.json to keep them.
zh  无法使用 /etc/sing-box/override.json：在 dns.rules：未知指令 $patch —— 请使用
    $prepend, $append, $replace, $before, $after 之一
zh  ⚠️  /etc/sing-box/config.json 曾被 sc 以外的方式修改，这些改动即将被覆盖；如需保留，
    请写入 /etc/sing-box/override.json。
```

(Each is **one** physical line in reality; wrapped here only for the page.)

## 7. Per-condition discharge (C-1 … C-8)

**C-1 — no live-host action.** `/usr/local/bin/sc` was never invoked; `sing-box` was never
stopped, started, reloaded or restarted; nothing was written under `/etc`. Every harness loads the
module through the `docs/dev-map.md` recipe **verbatim**, keeps `assert os.geteuid() != 0`
(uid 1000 throughout — which is what makes the mode-`000` `unreadable` fixture produce `unreadable`
rather than silently degrading to `usable`), sets `SYSTEMD = OPENRC = False`, `SB_BIN = /bin/true`,
and **asserts all seven repointed path constants resolve inside a harness-owned `mkdtemp()` root**
plus a second assertion that no temp root is under `/etc`. Neither assertion was weakened.
`_init_files()` is never *driven*; it is replaced by a no-op counter for the two `main()` drives,
so its hard-coded `/var/lib/sing-box` is never reached. Service witness at four checkpoints —
before the first edit, mid-implementation, after `verify_all`, and final:

```
MainPID=2887037
ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST     (all four, identical to the stated baseline)
```

`/etc/sing-box/` after all work: `config.json` mtime `2026-08-01 10:06:40` (unchanged, from before
this task), **no `override.json`, no `.config.sha256`**.

**C-2 — baseline pinned from the working tree.** §2. `git diff --stat -- bin/sc` was empty at pin
time and is recorded as such. For AC-30 a **clone** was used, never a worktree:
`git clone <repo> pristine && git checkout f642ca7` → `.git` is a *directory*, so A.1/A.2 are real
PASSes. Pristine result: **PASS 17 / WARN 0 / FAIL 0 / SKIP 1** — exactly the profile the PM
stated, confirming the clone was valid.

**C-3 — fixture freshness.** Chosen: **a fresh fixture, wiped and re-seeded from scratch, at the
same path**, for the baseline run and again for the candidate run of every point. The path string
had to be reused because it is *emitted* (`route.rule_set[].path`), so two different `mkdtemp()`
names produce a spurious 148/148 config mismatch — measured, not assumed (that was the harness's
first red). `wipe()` removes everything including `.config.sha256`, so no candidate run ever sees a
stale record, and `02` §11 item 7's "only extra artifact" assertion is retained unchanged.

**C-4 — AC-26 driven.** §6, row AC-26. Snapshot compares bytes *and* mode for every path under the
fixture root. `_egress_ip` is stubbed to raise so the run stays offline; that touches no write
path. Result: identical tree, report produced, no drift record created.

**C-5 — `docs/dev-map.md` records the `TUN_IFACE` exception.** The `# Paths` row now names all
seven constants and states: *"`TUN_IFACE` is the exception and no longer obeys that contract:
`CONFIG_BASE` captures it at import time … a harness that repoints it after import silently gets
the old device name. Repoint it before loading the module, or not at all."* The "Patterns to avoid"
recipe repeats it and now demands the seven-path in-temp-root assertion by name.

**C-6 — `{directives}` renders readably.** `_directive_list()` returns
`", ".join(DIRECTIVES)`; keys 9 and 10 receive `directives=_directive_list()`. Asserted in the
harness: the message contains `$prepend, $append, $replace, $before, $after` and no `('`.

**C-7 — newlines collapsed at the single render site.** `main()`:
`sys.exit(_plain(t("Cannot use {path}: {problem}", …).replace("\n", " ")))` — collapse first, then
one `_plain()` over the whole assembled sentence. Three hostile-key cases are in the harness (a key
containing `\n`; a key containing `\r` + a CSI sequence; an anchor value containing `\n`), each
asserting the emitted line has no `\n`, no `\r` and no ESC.

**C-8 — R-12 updated.** Done here in `docs/tasks.md` (not deferred to the PM). The row now names
`generate_config()`'s `OverrideError` as a second unwind past `cmd_update_rules`' run-level outcome
block, records the gate's ship-as-designed ruling and that the six-line stash was explicitly not
required.

## 8. Judgment calls made under the standing grant

1. **Fresh fixture = wipe-and-re-seed at a stable path** (C-3). The alternative the gate offered
   (a new `mkdtemp()` per point) is *wrong here* for a reason neither document anticipated: the
   root path is emitted inside the document being compared. Recorded rather than silently fixed.
2. **`_directive_of` rejects "two directives in one object" through key 11**, not a new key.
   `02` §5.3 states key 11 "also covers two directives in one object"; the message reads correctly
   for both shapes and no 18th key was added.
3. **`_merge` classifies its own root**, so a top-level `$…` is rejected with `at = the top level`
   (key 16) via key 12. The re-classification on each recursive call is a cheap no-op (the parent
   already proved the value is a plain object) and keeps the rule in exactly one place.
4. **`STATE_PATH.read_text()` catches `(OSError, ValueError)`**, not `OSError` alone: a corrupted
   record with invalid UTF-8 raises `UnicodeDecodeError` (a `ValueError`), which must degrade to
   "unknown", not to a traceback. `02` §5.6 says "unreadable/absent/empty → return silently"; this
   is that sentence made true.
5. **`t()` keys are written as implicit string concatenation across source lines** where they are
   long. The parser folds them, so the key is one string — the AST parity check in the harness
   confirms each folded key is present in the `zh` table verbatim.
6. **The `zh` fixture pins `settings.json`'s `lang`, not just `sc.LANG`.** Found while producing
   the sample output: `main()` reassigns `LANG` from `settings.json` via `_load_lang()`, so a
   harness that only sets `sc.LANG` renders **English** on every path driven through `main()`. My
   first 25 zh assertions were therefore vacuous — they passed because "no newline, no `失败：`" is
   also true of English. Fixed by pinning both and by strengthening the assertion to
   `startswith("无法使用 ")`. This is the one place my own harness was quietly wrong, and it is
   worth a QA note: **any bin/sc test that drives `main()` must set the language in the fixture's
   `settings.json`.**
7. **`README` sections were written as a strict line-for-line mirror** and verified mechanically
   (equal totals, identical heading line numbers, identical code-fence line numbers) rather than by
   eye.

## 9. `verify_all` result

| | PASS | WARN | FAIL | SKIP |
|---|---|---|---|---|
| Baseline (working tree, before any edit) | 16 | 1 | 0 | 1 |
| Pristine clone at `f642ca7` (AC-30 oracle) | 17 | 0 | 0 | 1 |
| **After changes** | **16** | **1** | **0** | **1** |

**Delta: 0 new FAIL, 0 new WARN.** The single WARN is F.6 (`Active task docs <=500 lines each`),
caused by `01_REQUIREMENT_ANALYSIS.md` (539L) and `02_SOLUTION_DESIGN.md` (637L) — it was already
WARNing before I touched anything, was predicted by the gate (§5), and clears on `archive-task`.
B.1 (`python3 -m py_compile bin/sc`) was run after **every** edit, not once at the end, and passes.
B.2 is unchanged (`install.sh` untouched); the 17 new `bin/sc` keys are not in its scope, and
`02` §11 item 11's scripted parity assertion — written and run — is their only coverage.

`git diff --stat` (permitted scope only):

```
 README.md       |  51 +++++
 README.zh-CN.md |  51 +++++
 bin/sc          | 593 +++++++++++++++++++++++++++++++++++++++++++++++---------
 docs/dev-map.md |  28 ++-
 docs/tasks.md   |  10 +-
 5 files changed, 638 insertions(+), 95 deletions(-)
```

(`CONTEXT.md` and `.harness/rejected-decisions.md` also show as modified in `git status` — those
are stage-2's own edits, not mine.)

**Doc size:** this record is over rule 70's 500-line cap because the gate requires the differential
harness pasted verbatim and runnable. F.6 already WARNs from `01`/`02` and clears on archive, so
this adds no new signal — flagged as the gate permitted, not hidden.

## 10. Design drift

**None.** Every element of `02` §§4–9 is implemented as designed, including the discretionary A-7
(`_filter_rules` receives `defined`) that the gate ruled in, and T-1 / T-2 / T-3 as ruled. Two
additions that are elaborations rather than deviations, both listed in §8: `_directive_list()` (a
one-line helper that exists solely to satisfy condition 6 — `02` §8 did not name it) and the
`ValueError` in `_warn_drift`'s except clause (§8 item 4). Neither changes an interface or an
emitted byte.

## 11. Open issues for review

1. **R-4 confirmed, deliberately not fixed** (the gate ruled it out of scope). `_write_private()`
   at `bin/sc:381` still does `os.fdopen(fd, "w")` with no `encoding=`, so under a non-UTF-8 locale
   a non-ASCII node tag raises `UnicodeEncodeError`. `save_nodes()` has the identical exposure. The
   drift record is immune (`_config_digest()` hashes the file's bytes). **Needs a new pool row.**
2. **`ruleset_status()` still has no in-tree caller**; unchanged by this task, noted only because a
   reviewer scanning the rule-set section will see it.
3. **The `sc add` shape is unchanged and slightly odd** (gate F-11): with a malformed override,
   `sc add` persists the node and then exits 1 with the override message. This is what `A-5`
   specifies and matches today's `sing-box check`-failure behaviour; recorded, not fixed.
4. **`_dig` has exactly one caller** (gate F-10, permitted). It must not grow a second parameter.

## 12. Dev-map updates

`docs/dev-map.md`: `# Paths` row rewritten (7 constants + the `TUN_IFACE` import-capture
exception); new `# Config composition` section row; `# Config generation` row updated; six new
"Reusable utilities" rows (`_merge`, `_directive_of`, `CONFIG_BASE`/`_compose`, `_runtime_overlay`,
`_load_override`, the drift trio) and the `_filter_rules` row amended for the `defined` set; the
harness repoint list enlarged to seven constants with the in-temp-root assertion made mandatory and
`TUN_IFACE` excluded; one new "Patterns to follow" bullet ("a change to the emitted config goes in
`CONFIG_BASE` or in an overlay — never back into `generate_config()` as a literal").

## 13. Insight to surface

- A differential harness for `generate_config()` must run baseline and candidate at the **same**
  fixture path, because the fixture root is emitted verbatim inside `route.rule_set[].path` — two
  `mkdtemp()` roots produce a 100 % config mismatch that looks like a refactor bug · evidence:
  `config-composition-layer`, `bin/sc` `_runtime_overlay` `path: str(RULES_DIR / fname)`
- Any `bin/sc` test that drives `main()` must set the language in the fixture's `settings.json`:
  `main()` reassigns `LANG` from `_load_lang()` after import, so setting `sc.LANG` alone makes every
  Chinese assertion vacuous while still passing · evidence: `config-composition-layer`, `bin/sc:2464`

## 14. The differential harness, verbatim and runnable

QA rebuilds rather than inherits, but must be able to reproduce this. Save as `t14_diff.py`
alongside a copy of the pre-change `bin/sc`, then:

```
python3 t14_diff.py --baseline sc_baseline.py --candidate /home/alan/Programs/singbox-cli/bin/sc
```

The companion `t14_semantics.py` (§6) imports `load_module`, `mkroot`, `repoint`, `seed`, `wipe`,
`node`, `BODIES` and `RULESET_FILENAMES` from this file, so this listing is the load-bearing half.

```python
#!/usr/bin/env python3
"""T-14 AC-1 differential harness — baseline `bin/sc` vs candidate `bin/sc`.

Throwaway (O-8 / open row R-9). Run:

    python3 t14_diff.py --baseline <path> --candidate <path>

Compares, per differential point, in BOTH LANG="en" and LANG="zh":
  * config.json bytes           (AC-1)
  * captured stderr             (AC-3)
  * generate_config()'s return  (AC-3)
  * nodes.json bytes            (AC-12)
  * the set of files in the fixture root, candidate may add exactly .config.sha256 (item 7)

Closure: 16 rule-set usability subsets x 4 node/active states = 64 points, plus the
extras of 02 §11 item 8 (non-ASCII tag, one run per non-usable status, non-default
CLASH_PORT, non-default RULES_DIR) and AC-11 (three consecutive calls).

SAFETY (NFR-1, gate condition 1): the module is loaded through the docs/dev-map.md
"Patterns to avoid" recipe verbatim; every path constant is repointed into a mkdtemp()
root and ASSERTED to be inside one; _init_files() is never driven; SYSTEMD = OPENRC =
False; SB_BIN is /bin/true. Nothing under /etc is touched.
"""
import argparse
import contextlib
import io
import itertools
import json
import os
import shutil
import stat
import sys
import tempfile
import types
from pathlib import Path

REAL_OS = os
TMP_ROOTS = []          # every mkdtemp() this harness owns; the repoint assertion's allow-list


# ---------------------------------------------------------------- module loading

def load_module(src_path):
    """docs/dev-map.md 'Patterns to avoid' recipe, verbatim. Do not re-invent."""
    assert os.geteuid() != 0                       # refuse to run as root, loudly
    sc = types.ModuleType("sc")
    shim = types.ModuleType("os"); shim.__dict__.update(os.__dict__)
    shim.geteuid = lambda: 0                       # the elevate branch is simply not taken
    sys.modules["os"] = shim
    try:
        exec(compile(open(src_path).read(), src_path, "exec"), sc.__dict__)
    finally:
        sys.modules["os"] = REAL_OS                # restore IMMEDIATELY, in a finally
    sc.SYSTEMD = sc.OPENRC = False
    sc.SB_BIN = "/bin/true"
    return sc


def mkroot(prefix="t14-"):
    root = Path(tempfile.mkdtemp(prefix=prefix))
    TMP_ROOTS.append(root.resolve())
    return root


REPOINTED = ("CFG_DIR", "CFG_PATH", "NODES_PATH", "SETTINGS_PATH", "RULES_DIR",
             "OVERRIDE_PATH", "STATE_PATH")


def repoint(sc, root, rules_dir=None, clash_port=29090, lang="en"):
    """Repoint every path constant into harness-owned temp space, then PROVE it.

    The assertion — not vigilance — is what stops a forgotten constant writing under /etc
    (02 §11 item 2; gate condition 1: it may not be weakened)."""
    root = Path(root)
    sc.CFG_DIR = root
    sc.CFG_PATH = root / "config.json"
    sc.NODES_PATH = root / "nodes.json"
    sc.SETTINGS_PATH = root / "settings.json"
    sc.RULES_DIR = Path(rules_dir) if rules_dir is not None else root / "rules"
    # Candidate-only constants; setting them on the baseline is a harmless no-op.
    sc.OVERRIDE_PATH = root / "override.json"
    sc.STATE_PATH = root / ".config.sha256"
    sc.SYSTEMD = sc.OPENRC = False
    sc.SB_BIN = "/bin/true"
    sc.CLASH_PORT = clash_port
    sc.LANG = lang
    for name in REPOINTED:
        p = Path(str(getattr(sc, name))).resolve()
        assert any(p == r or r in p.parents for r in TMP_ROOTS), \
            "REPOINT LEAK: %s -> %s is outside every harness temp root" % (name, p)
    # Belt and braces: no harness temp root may live under a system config dir.
    for r in TMP_ROOTS:
        assert not str(r).startswith("/etc"), "temp root under /etc: %s" % r


# ---------------------------------------------------------------- fixtures

USABLE_BODY = b"SRS" + b"x" * 32          # magic ok, >= SRS_MIN_BYTES
BODIES = {
    "usable":     USABLE_BODY,
    "bad-magic":  b"XXX" + b"x" * 32,
    "too-small":  b"SRS",
    "unreadable": USABLE_BODY,            # written, then chmod 000 (needs non-root)
    "absent":     None,
}
RULESET_FILENAMES = ("geoip-cn.srs", "geosite-cn.srs",
                     "geosite-google.srs", "geosite-private.srs")


def node(tag, port):
    return {
        "type": "vless", "tag": tag, "server": "example.com", "server_port": port,
        "uuid": "11111111-2222-3333-4444-555555555555", "flow": "xtls-rprx-vision",
        "packet_encoding": "xudp",
        "tls": {"enabled": True, "server_name": "example.com", "utls": {
            "enabled": True, "fingerprint": "chrome"}},
    }


NODE_STATES = {
    # name: (nodes, active)
    "a-no-nodes":      ([], None),
    "b-one-node":      ([node("n1", 443)], "n1"),
    "c-three-nodes":   ([node("n1", 443), node("n2", 8443), node("n3", 2087)], "n2"),
    "d-stale-active":  ([node("n1", 443), node("n2", 8443), node("n3", 2087)], "gone"),
}


def wipe(root):
    """Empty a directory without removing it — the path string is load-bearing (it is
    emitted inside route.rule_set[].path), so baseline and candidate must run at the
    SAME path, each on a fixture with no residue of the other (gate condition 3: this
    is 'a fresh fixture root per differential point', reusing the name only)."""
    for p in sorted(Path(root).rglob("*"), reverse=True):
        try:
            os.chmod(str(p), 0o700)
        except OSError:
            pass
        if p.is_dir() and not p.is_symlink():
            p.rmdir()
        else:
            p.unlink()


def seed(root, rules_dir, statuses, nodes, active):
    """Lay a fresh fixture down inside an existing, empty root.

    statuses -- dict filename -> status string for the four rule-sets."""
    root = Path(root)
    rules_dir = Path(rules_dir)
    rules_dir.mkdir(parents=True, exist_ok=True)
    for fname in RULESET_FILENAMES:
        body = BODIES[statuses[fname]]
        if body is None:
            continue
        p = rules_dir / fname
        p.write_bytes(body)
        if statuses[fname] == "unreadable":
            os.chmod(str(p), 0o000)
    (root / "nodes.json").write_text(
        json.dumps({"active": active, "nodes": nodes}, indent=2, ensure_ascii=False))
    (root / "settings.json").write_text(
        json.dumps({"default_tun": True, "mode": "rule", "lang": "en"}, indent=2))


def tree(root):
    out = {}
    for p in sorted(Path(root).rglob("*")):
        rel = str(p.relative_to(root))
        if p.is_dir():
            out[rel + "/"] = None
        else:
            try:
                out[rel] = p.read_bytes()
            except OSError:
                out[rel] = "<unreadable>"
    return out


# ---------------------------------------------------------------- one run

def run(sc, root, rules_dir, lang, clash_port, calls=1):
    repoint(sc, root, rules_dir=rules_dir, clash_port=clash_port, lang=lang)
    results = []
    for _ in range(calls):
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            rv = sc.generate_config()
        cfg = (Path(root) / "config.json")
        results.append({
            "rv": rv,
            "stderr": err.getvalue(),
            "config": cfg.read_bytes() if cfg.exists() else None,
            "nodes": (Path(root) / "nodes.json").read_bytes(),
            "names": sorted(n for n in tree(root)),
        })
    return results


def compare(label, base_res, cand_res, failures):
    b, c = base_res[0], cand_res[0]
    for field in ("rv", "stderr", "config", "nodes"):
        if b[field] != c[field]:
            failures.append((label, field, b[field], c[field]))
    extra = set(c["names"]) - set(b["names"])
    missing = set(b["names"]) - set(c["names"])
    if extra - {".config.sha256"} or missing:
        failures.append((label, "tree", sorted(missing), sorted(extra)))


# ---------------------------------------------------------------- the closure

def subsets():
    """16 rule-set usability subsets, in a stable order."""
    for bits in itertools.product((True, False), repeat=4):
        yield dict(zip(RULESET_FILENAMES,
                       ["usable" if b else "absent" for b in bits]))


def points():
    """(label, statuses, nodes, active, clash_port, rules_dir_outside, calls)"""
    for i, st in enumerate(subsets()):
        for sname, (nodes, active) in NODE_STATES.items():
            yield ("subset%02d/%s" % (i, sname), st, nodes, active, 29090, False, 1)
    # --- extras, layered on state (c) --------------------------------------
    c_nodes, c_active = NODE_STATES["c-three-nodes"]
    all_usable = dict.fromkeys(RULESET_FILENAMES, "usable")
    # BC-4: non-ASCII node tag, emitted verbatim under ensure_ascii=False
    nz = [node("香港-01 ✈", 443), node("n2", 8443), node("测试节点", 2087)]
    yield ("extra/non-ascii-tags", all_usable, nz, "测试节点", 29090, False, 1)
    yield ("extra/non-ascii-stale-active", all_usable, nz, "缺失", 29090, False, 1)
    # BC-6: one run per non-usable status (all four files at that status)
    for status in ("absent", "bad-magic", "too-small", "unreadable"):
        yield ("extra/all-%s" % status, dict.fromkeys(RULESET_FILENAMES, status),
               c_nodes, c_active, 29090, False, 1)
    # BC-6 mixed: each file at a different non-usable status
    mixed = dict(zip(RULESET_FILENAMES,
                     ["absent", "bad-magic", "too-small", "unreadable"]))
    yield ("extra/mixed-statuses", mixed, c_nodes, c_active, 29090, False, 1)
    # non-default CLASH_PORT
    yield ("extra/clash-port-29137", all_usable, c_nodes, c_active, 29137, False, 1)
    # non-default RULES_DIR (a second temp dir holding the .srs fixtures)
    yield ("extra/rules-dir-elsewhere", all_usable, c_nodes, c_active, 29090, True, 1)
    # AC-11: three consecutive generate_config() calls in one process
    yield ("extra/three-calls", all_usable, c_nodes, c_active, 29090, False, 3)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline", required=True)
    ap.add_argument("--candidate", required=True)
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    base = load_module(args.baseline)
    cand = load_module(args.candidate)

    failures = []
    n = 0
    root = mkroot()
    outside_dir = mkroot("t14-rules-")
    for label, statuses, nodes, active, port, outside, calls in points():
        for lang in ("en", "zh"):
            rules_dir = outside_dir if outside else root / "rules"
            wipe(root); wipe(outside_dir)
            seed(root, rules_dir, statuses, nodes, active)
            bres = run(base, root, rules_dir, lang, port, calls)
            wipe(root); wipe(outside_dir)          # no residue of the baseline run,
            seed(root, rules_dir, statuses, nodes, active)   # STATE_PATH included
            cres = run(cand, root, rules_dir, lang, port, calls)
            compare("%s [%s]" % (label, lang), bres, cres, failures)
            if calls > 1:                                    # AC-11
                for m, res in (("baseline", bres), ("candidate", cres)):
                    first = res[0]["config"]
                    for k, r in enumerate(res[1:], start=2):
                        if r["config"] != first:
                            failures.append(("%s [%s] %s call#%d" % (label, lang, m),
                                             "AC-11 repeat", first, r["config"]))
            n += 1
            if args.verbose:
                print("  ok %s [%s]" % (label, lang))
    wipe(root); wipe(outside_dir)
    shutil.rmtree(str(root), ignore_errors=True)
    shutil.rmtree(str(outside_dir), ignore_errors=True)

    print("compared %d differential runs (%d points x 2 languages)" % (n, n // 2))
    if not failures:
        print("RESULT: PASS — byte-identical config, stderr, return value and nodes.json")
        return 0
    print("RESULT: FAIL — %d mismatch(es)" % len(failures))
    for label, field, b, c in failures[:8]:
        print("  %-40s %s" % (label, field))
        if field in ("config", "AC-11 repeat") and b is not None and c is not None:
            bl = b.decode("utf-8", "replace").splitlines()
            cl = c.decode("utf-8", "replace").splitlines()
            for i, (x, y) in enumerate(zip(bl, cl)):
                if x != y:
                    print("      line %d baseline : %s" % (i + 1, x))
                    print("      line %d candidate: %s" % (i + 1, y))
                    break
            else:
                print("      length %d vs %d" % (len(bl), len(cl)))
        else:
            print("      baseline : %r" % (b,))
            print("      candidate: %r" % (c,))
    if len(failures) > 8:
        print("  ... %d more" % (len(failures) - 8))
    return 1


if __name__ == "__main__":
    sys.exit(main())
```

The AC-4 mutant generator (run against the **baseline**, before any edit):

```python
#!/usr/bin/env python3
import pathlib
src = pathlib.Path("sc_baseline.py").read_text()
m1 = src.replace('"log": {"level": "warn", "timestamp": True},',
                 '"log": {"level": "warns", "timestamp": True},', 1)
assert m1 != src
pathlib.Path("mutant_m1.py").write_text(m1)
old = '            "final": "remote_dns",\n            "independent_cache": True,\n'
new = '            "independent_cache": True,\n            "final": "remote_dns",\n'
assert old in src
pathlib.Path("mutant_m2.py").write_text(src.replace(old, new, 1))
m3 = src.replace('sys.stderr.write("⚠️  " + msg + "\\n")',
                 'sys.stderr.write("⚠️ " + msg + "\\n")', 1)
assert m3 != src
pathlib.Path("mutant_m3.py").write_text(m3)
```

## 15. Verdict

**READY FOR REVIEW.**

AC-1 green over 148 runs from a harness demonstrated to fail on a value change, a **key reorder**
and a stderr change. 91 further checks cover AC-5…AC-8, AC-10…AC-28 and BC-7's both edges.
`verify_all`: 0 new FAIL, 0 new WARN against both the working-tree baseline and a pristine clone.
All eight gate conditions discharged, the service untouched at four checkpoints, nothing written
under `/etc`. Not committed, not pushed.

## 16. Stage 4′ — in-stage return (stage-5 MINOR-2, [DOC])

Numbered 16, not 15: the PM's brief called this §15 but that slot is the Verdict above, and a
duplicate heading would break the doc's outline. Content is exactly the requested record.

**Defect as the reviewer stated it.** `README.md:207` / `README.zh-CN.md:207` claimed `sc reload`,
`sc use`, `sc add`, `sc rm`, `sc mode` and `sc update-rules` "all rewrite it from scratch". Two of
the six are wrong, and `sc mode` is the one `01_REQUIREMENT_ANALYSIS.md` §5 relies on to keep AC-1's
input closure finite — so the README contradicted this task's own requirement document.

**What the functions actually do** (verified by reading `bin/sc`, not taken on trust):

| Command | Regenerates? | Evidence |
|---|---|---|
| `sc reload` / `sc add` / `sc rm` | always | `bin/sc:2263`, `:1624`, `:1638` → `reload_or_restart()` → `generate_config()` (`bin/sc:1507-1511`) |
| `sc use` | only on the fallback arm | `bin/sc:1597-1607` — hot-applies via `clash_api("PUT", "/proxies/proxy")` and **returns**; reaches `reload_or_restart()` only if the service is down or the PUT returns `None` |
| `sc update-rules` | only on recovery | `bin/sc:2131-2140` — `generate_config()` runs only when `gained` is non-empty (a rule-set came back); a plain byte-change restarts without regenerating, and an unchanged run touches nothing |
| `sc mode` | **never** | `bin/sc:2020-2029` — persists `settings["mode"]` and PATCHes `/configs`; no `generate_config()` call on any path |

Reviewer's reading confirmed on both counts. `sc update-rules` turned out to be conditional too,
which the review did not flag; the replacement text is worded to cover that without asserting it.

**Replacement text.** `sc mode` is dropped from the list (its presence was the factual error, and
naming it merely to exempt it would start the truth table rule 85's counter-rule forbids); the
always/maybe split carries `sc use` and `sc update-rules` honestly in one clause. The paragraph's
practical point is untouched and in fact tightened — "survives every command above" became
"survives every regeneration", which no longer depends on the list being exhaustive.

- EN: "`config.json` is **generated**: `sc reload`, `sc add` and `sc rm` rewrite it from scratch
  every time, and `sc use` and `sc update-rules` may do so as well, so anything you hand-edit there
  is discarded without a word. …so it survives every regeneration and survives re-running
  `install.sh`."
- ZH: "`config.json` 是**生成物**：`sc reload`、`sc add`、`sc rm` 每次都会把它整份重写，`sc use` 和
  `sc update-rules` 也可能重写，所以你在那里手改的内容会被悄无声息地丢掉。…因此它能挺过每一次重新
  生成，也能挺过重新执行 `install.sh`。"

**Mirror verified mechanically**, not by eye — one line replaced by one line in each file, then:
`wc -l` → 286/286; `diff <(grep -n '^#' A | cut -d: -f1) <(grep -n '^#' B | cut -d: -f1)` empty, same
for `^```' ` → headings still at 184/205/254/284, fences at 213/215 and 233/246; a per-line class
skeleton (heading/fence/table/quote/blank/prose) diffed between the two files yields **only `c`
hunks** (translated heading text at identical line numbers) and **no `a`/`d` hunk**, which is the
property that proves no line was inserted or deleted; the fenced JSON blocks diff byte-identical.

**`verify_all`:** PASS 16 / WARN 1 / FAIL 0 / SKIP 1 — unchanged from the stage-4 baseline, the WARN
being the pre-existing F.6 doc-size. No new FAIL, no new WARN.

Documentation only: `bin/sc` untouched, so the 148-run differential does not need re-running.
Service untouched (`MainPID=2887037`, unchanged). Not committed, not pushed.

**READY FOR RE-REVIEW.**

## 17. Stage 4″ — scoped return (stage-6 MAJOR D-1 → BC-27 / AC-31 / D-17)

`06` MAJOR **D-1**: a dangling symlink at `override.json` was silently treated as **absent** —
`rv=True`, `stderr=''`, `config.json` replaced, `exit=0`, and no drift warning either. `01` §12
(Addendum A) rules it **malformed** (**BC-27**, **D-17**) and pins the guarantee in **AC-31**. The
analyst named the developer with no design change required.

### 17.1 The change — two hunks, both inside the not-found arm

`bin/sc:1281-1301`, `_load_override()`'s `except FileNotFoundError:` arm only:

```python
    except FileNotFoundError:
        if os.path.islink(str(OVERRIDE_PATH)):
            raise OverrideError(t("a symbolic link whose target {target} does not exist",
                                  target=os.path.realpath(str(OVERRIDE_PATH))))
        return None
```

plus one `zh` key pair (`bin/sc:245-246`).

**The delta is 19 added lines, 0 removed** — corrected here, stage 4‴, against stage-5′ **NIT-B**;
this paragraph previously said "one `zh` entry … and four comment lines", which undercounts by 15.
Counted line by line in the working tree: **17 inside `_load_override`** — one blank plus a 4-line
docstring paragraph (`:1280-1284`), and 12 lines in the arm (`:1289-1300`), being **9 comment lines**
(`:1289-1295` and `:1297-1298`) and **3 code lines** (the `if` at `:1296`, the two-line `raise` at
`:1299-1300`) — **plus the 2-line `zh` pair** (`:245-246`). 17 + 2 = 19, which is exactly the +19
shift `05` §12.1 measured on every anchor below the arm, and +2 on every anchor between the `zh`
table and the arm. Every added line is a comment, a docstring line or the `if`/`raise` quoted above —
nothing is hidden, and the cited range `:1281-1301` does contain them all — but the old number was
simply wrong, and a delta review that trusted it instead of the file would have mis-scoped its read.

**Nothing else moved**: the
stat-before-open ordering (BC-9's FIFO guard) is byte-identical, every other arm is untouched,
`_filter_rules` / `_merge` / `CONFIG_BASE` / `generate_config()` / the drift trio / the READMEs /
`docs/dev-map.md` are untouched.

Three judgments inside the mandate:

- **`os.path.islink`, not `os.readlink`/`lstat`.** It is an `lstat` that never raises and never
  follows, so it is false both for a path with no entry at all *and* for a broken **parent**
  component — BC-27's final-component-only boundary is a property of the primitive, not of a
  second test I would have to keep true.
- **`os.path.realpath`, not `os.readlink` — and the reason is chain resolution, nothing else.**
  `readlink` returns only the *immediate* target, so for a chain `a → b → c` it would name `b`, an
  intermediate link, rather than `c`, the component that is actually missing. Naming the wrong file
  in a message whose whole purpose is "here is the target you must fix" is worse than naming none.
  `realpath` walks the chain to that component, and it is non-strict by default on the 3.6 floor
  (`strict=` is 3.10+, and passing it would be a `TypeError` there), so an unresolvable path is
  *returned* rather than raised.

  **Corrected here, stage 4‴, against stage-5′ NIT-A.** An earlier version of this bullet also
  claimed `readlink` "*can* raise … `realpath` … swallows its own errors". **That second half is
  false**, and I verified it by reading `posixpath` source rather than taking it from the review:

  - CPython **3.8.2** (`~/.local/share/uv/python/cpython-3.8.2-linux-x86_64-gnu/lib/python3.8/
    posixpath.py:425` then `:439`): `_joinrealpath` does `if not islink(newpath): … continue` and
    then, three lines later, an **unguarded** `os.readlink(newpath)`. This is the ≤3.9 shape. **I did
    not read 3.6 source itself** — no 3.6 interpreter exists on this host; 3.8.2 is the nearest ≤3.9
    interpreter available and is on the same side of the 3.10 rewrite.
  - This host's Python is **3.12.3**, *not* the 3.6 floor. Its `/usr/lib/python3.12/posixpath.py`
    shows what the 3.10 rewrite actually guarded: the *stat* (`:475-480`, `try: os.lstat(newpath)` /
    `except ignored_error`) — while `os.readlink(newpath)` at `:499` is **still unguarded**.

  So `realpath` carries exactly the TOCTOU window I used to reject `readlink`: if the link is
  unlinked between the `islink`/`lstat` and the `readlink`, an `OSError` escapes `main()`'s
  `OverrideError`-only handler as a traceback. **This is not a defect.** It is the same class as the
  pre-existing `os.stat`-then-`open` window already accepted as `05` §6's `[SEC]` NIT, and it needs
  the same premise to fire — a concurrent mutation of `/etc/sing-box`, which is root-owned and not
  world-writable, so an unprivileged user cannot reach it. The choice of `realpath` **stands**
  (`05` §12.2 item 3 says so explicitly); it rests on chain resolution, which is the half of the
  argument that is sound, and not on any "cannot raise" property, which neither function has.

  **The same overstatement was also in the code comment at `bin/sc:1297-1298`** ("unlike readlink it
  cannot raise"). Stage 4‴ left it there and filed it for T-20; **stage 4⁗ rewrote it** on the PM's
  override — see §17.7. The comment now carries the chain-resolution rationale and no "cannot raise"
  claim.
- **Naming the target is optional under BC-27; it is included** because the recovery action ("that
  file is gone / that path is a typo") is not derivable from the override path alone.

Rendered, one physical line, no `\n` / `\r` / ESC (`main()`'s single `OverrideError` site supplies
`Cannot use {path}: ` and the `_plain()` + newline collapse):

```
en  Cannot use /etc/sing-box/override.json: a symbolic link whose target /home/u/dotfiles/sb.json does not exist
zh  无法使用 /etc/sing-box/override.json：是一个符号链接，但其目标 /home/u/dotfiles/sb.json 不存在
```

AC-27/AC-28: one key pair, identical placeholder set `{target}`, readable English prose as the key
(no `en` table exists), not namespaced, no `失败：` in the `zh` value.

### 17.2 DESIGN DRIFT — `02` §5.4, requirement-driven

`02` §5.4's pseudo-code line `os.stat(OVERRIDE_PATH)  FileNotFoundError -> None (absent)` is
**superseded** by BC-27/D-17 and is now, for the symlink case only, `-> OverrideError`. `02` retains
the old line because downstream cannot edit upstream (`.harness/rules/00-core.md`); recording it
here is the standing mechanism, per `01` §12.3. Nothing else in `02` §5.4 changes — the step order,
its opening paragraph's error channel (this is its ninth member), and D-14's accepted case in its
closing sentence all stand as written.

### 17.3 Verification — re-run, not asserted

| Gate | Result |
|---|---|
| `t14_diff.py` (§14, this document) vs `git show HEAD:bin/sc` | **PASS — 148 runs** (74 points × 2 langs), byte-identical config, stderr, return value, `nodes.json` |
| `qa_diff.py` + `qa_common.py`, extracted verbatim from `06` §13 | **PASS — 164 runs** (82 points × 2 langs). The oracle is identical: `git diff f642ca7 HEAD -- bin/sc` is empty |
| `qa_errors.py` (`06` §13, unmodified) | **95 ok, 1 FAILED** — the one FAIL is the deep-nesting `RecursionError`, i.e. `06` MINOR-A, out of scope as **R-15**. Identical to QA's own run. Its `DANGLING SYMLINK` note now reads `exit='Cannot use …' config.json replaced=False`, and `D-14 a symlink resolving to a REGULAR file is accepted` is still `ok` |
| `bc27_test.py` (new, 26 assertions) | **26 ok, 0 FAILED** — detail below |
| `bash .harness/scripts/verify_all.sh` | **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — identical to the pre-change run in this session; the WARN is the pre-existing F.6 doc-size |

**The 164-run differential was neither relaxed nor re-baselined** — the harness is the one `06`
published, run against the same pre-change oracle.

`bc27_test.py` (fixture layer = `qa_common.py`, so the dev-map recipe verbatim, the `geteuid`
assertion and the all-seven-paths-inside-temp-root assertion are the ones already reviewed):

- **BC-27/AC-31, × {en, zh} × {direct, chained, relative-target} dangling link** — exit is a message
  string (⇒ status 1), `config.json` byte-identical to a hand-written sentinel, `restart_service`
  called **0** times (AC-21), nothing on stderr, one physical line, names the override path **and**
  the missing target, no `失败：`, drift record neither created nor changed. The chain case proves
  `realpath` names the end of the chain; the relative case proves it resolves against the link's own
  directory.
- **AC-31 clause 2, × {en, zh}** — with no entry at all, `_load_override()` returns `None` with
  **empty stdout and empty stderr**, and `generate_config()`'s return value, stderr and
  `config.json` bytes equal the **pre-change build's** on the same fixture. This is the AC-1
  property measured at the one arm the fix touches, in addition to the two whole-closure gates.
- **D-14, × {en, zh}** — a symlink resolving to a regular file with a valid override still exits 0
  and still applies (`log.level == "debug"`, `log.timestamp` preserved).
- **The boundary the analyst narrowed, × {en, zh} × {dangling directory link, no directory at all}**
  — a broken **parent** component stays **absent**: silent `None`, no raise, and `sc reload` exits 0.

**One parent flavour behaves differently, and it is pre-existing (`05` §12.4 observation).** BC-27's
"a missing or broken parent directory component remains absent" holds for the two shapes tested above
(no parent, dangling parent link — `os.stat` raises `FileNotFoundError`, `islink` is `False`, silent
`None`). A parent component that is a **regular file** instead raises `NotADirectoryError`, which is
an `OSError` but not a `FileNotFoundError`, so it never enters the amended arm at all: it lands in
the untouched `except OSError` (`bin/sc:1302`) and is reported as malformed —
`Cannot use …: cannot be read (Not a directory)`. **Unchanged by this delta** (that arm has not been
edited since stage 4) and fail-safe in direction: loud, no write, exit 1, never a silent discard, so
AC-31's operative clause is still satisfied. Recorded here so it is not later misread as a BC-27
regression.

**Non-vacuity** (the same discipline as §4). `mutant_nofix.py` = the working tree's `bin/sc` with
only the five-line `islink` block deleted: **14 ok, 12 FAILED**, the 12 being exactly the dangling
assertions, and they reproduce the MAJOR verbatim — `exit was 0`, `config.json was modified`,
`restart_service called 1 times`, `drift record changed`. Every other assertion (AC-31 clause 2,
D-14, both parent-boundary cases) stayed green on the mutant, which is what shows the fix is
confined to the arm it claims.

### 17.4 Safety

Nothing under `/etc` written, `/usr/local/bin/sc` never invoked, `_init_files()` never driven,
`SYSTEMD = OPENRC = False`, `SB_BIN=/bin/true`, `lang` pinned in each fixture's `settings.json` so
the `zh` assertions are real. Service witness at every checkpoint —
start, `qa_errors` start/end, `bc27_test` start/end, and after `verify_all`:

```
MainPID=2887037   ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
```

identical to the T-14 baseline at all six readings.

### 17.5 Out of scope, left where the analyst filed them

`06` MINOR-A (deep nesting ⇒ `RecursionError`) and `05` MINOR-1 (non-object element ⇒
`AttributeError`) are **R-15**; `06` MINOR-B (a bare object replacing an array) is **R-16**. Both
rows are in `docs/tasks.md`; neither was touched. No dev-map update — no file was added, moved or
removed.

### 17.6 Stage 4‴ — record correction only (stage-5′ NIT-A, NIT-B)

`05` §12.7 returned the BC-27 fix **APPROVED — 0 CRITICAL, 0 MAJOR, 0 MINOR, 2 NIT**, both `[DOC]`
against this document's own §17.1 prose. **No code changed in this pass** — `bin/sc` is byte-identical
to the state stage 5′ reviewed, so neither the 164-run differential nor `qa_errors.py` nor
`bc27_test.py` was re-run and none of them can have moved.

- **NIT-A** — the `realpath` rationale is rewritten above: it now rests on chain resolution, and the
  "cannot raise" claim is retracted with the `posixpath` source that disproves it (3.8.2 `:425,439`;
  3.12.3 `:475-480,499`). The choice of `realpath` is unchanged and remains correct.
- **NIT-B** — the added-line count is corrected from "one `zh` entry … and four comment lines" to the
  measured **19 lines (17 + the 2-line `zh` pair)**.
- The `ENOTDIR` parent flavour from `05` §12.4's observation is folded into §17.3.

**Carried forward, deliberately not fixed here:** the code comment at `bin/sc:1297-1298` repeats the
retracted "cannot raise" claim. It is a comment, it misstates nothing the code *does*, and fixing it
would reopen two green gates for zero behavioural gain — so it is left for the next task that edits
`_load_override()` (T-20 owns override permissions and is the natural site). **→ Overruled by the PM
and closed in stage 4⁗ instead; see §17.7.** (The note the PM asked for is a subsection of its own
rather than a paragraph appended here, because this section's heading says "record correction only"
and stage 4⁗ does change code — a note filed under a heading that denies it is the same kind of
residue the change itself removes.)

`bash .harness/scripts/verify_all.sh` re-run after this edit: **PASS 16 / WARN 1 / FAIL 0 / SKIP 1**,
identical to §17.3. Service witness unchanged, `MainPID=2887037`,
`ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`. Nothing under `/etc` written, `bin/sc` never
executed in this pass.

Not committed, not pushed.

**READY FOR RE-REVIEW.**

### 17.7 Stage 4⁗ — the comment §17.6 carried forward, closed here (PM override)

**The PM overruled §17.6's deferral, and the deciding reason is one I could not weigh:** T-14 is
being delivered now rather than continuing into T-20, so "the next task that edits
`_load_override()`" was never going to arrive before the false claim shipped. Two further reasons
stand on their own — a knowingly false statement in source is worse than one in a stage document,
because the comment is what gets read at the point of change; and retracting a claim in §17.1 while
leaving the claim itself in the code is exactly the residue
`.harness/rules/85-design-discipline.md` exists to prevent. The gates below were **re-run, not
reopened**; a comment provably cannot change emitted bytes, but "it's only a comment" is how a
byte-identity gate gets skipped.

The one hunk, `bin/sc` (line numbers below the arm shift +1, to `:1300-1302` for the `raise` and
`return None`):

```diff
-            # realpath, not readlink: it resolves a CHAIN of links down to the component
-            # that is actually missing, and unlike readlink it cannot raise.
+            # realpath, not readlink: readlink names only the IMMEDIATE target, so on a
+            # chain a -> b -> c it names b, not the component that is actually missing.
+            # Neither is raise-free: racing either needs write access to root-owned /etc.
```

**+3 / −2, and all five lines are comments.** What survives is the rationale that is sound —
`readlink` returns only the immediate target, so on `a → b → c` it names `b`, an intermediate link,
never the component actually missing, while `realpath` walks the chain to it. What is gone is the
"cannot raise" claim: per §17.1's verification, `os.readlink` is unguarded inside
`posixpath._joinrealpath` on 3.8.2 **and still unguarded at `:499` on this host's 3.12.3** (the 3.10
rewrite guarded the `lstat`, not the `readlink`). The one-line TOCTOU remark that replaces it states
the accurate thing and the reason it is accepted in the same breath: firing it needs a concurrent
mutation of root-owned, non-world-writable `/etc/sing-box`, the same class as the pre-existing
`os.stat`-then-`open` window (`05` §6 `[SEC]`). `os.path.islink`'s "It never raises" at `:1293` is a
different claim about a different function and is **true** — `islink` swallows its `lstat` error —
so it stands untouched.

| Gate | Result |
|---|---|
| `python3 -m py_compile bin/sc` | **OK** |
| Non-comment **token stream** of `bin/sc`, pre-4⁗ vs post | **identical — 11 778 tokens both sides** (`tokenize`, dropping `COMMENT`/`NL`/`NEWLINE`/`INDENT`/`DEDENT`). This is the machine check behind "no executable line changed"; `diff` alone only shows the `if`/`raise`/`return` as unchanged context |
| `qa_diff.py` + `qa_common.py` vs pristine `f642ca7` clone | **PASS — 164 runs** (82 points × 2 langs), byte-identical config, stderr of every call, return of every call, `nodes.json`. **Unrelaxed**: both files were re-extracted from `06` §13 in this pass and `diff` clean against the stage-4″ extraction; the oracle `pristine/bin/sc` hashes `674be9f1…` = `git show f642ca7:bin/sc` |
| `bash .harness/scripts/verify_all.sh` | **PASS 16 / WARN 1 / FAIL 0 / SKIP 1** — unchanged; the WARN is the pre-existing F.6 doc-size |

Whole-task `bin/sc` delta is now **+526 / −87 over 18 hunks** (was +525 / −87; the extra line is the
third comment line above). No other file changed in this pass; no dev-map update — nothing was
added, moved or removed. `qa_errors.py` / `bc27_test.py` were **not** re-run: no executable byte
moved, and the 164-run differential already covers the closure end to end.

**Safety.** `assert os.geteuid() != 0` and the all-seven-paths-inside-`PARENT` assertion in
`qa_common.py` are the reviewed ones, unmodified; neutralisation recipe verbatim. Nothing under
`/etc` written, `/usr/local/bin/sc` never invoked, `_init_files()` never driven, the service never
touched. Witness before the differential and after `verify_all`, both readings:

```
MainPID=2887037   ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST
```

Not committed, not pushed.

**READY FOR RE-REVIEW.**
