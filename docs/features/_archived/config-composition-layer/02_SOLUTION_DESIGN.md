# 02 — Solution Design · T-14 `config-composition-layer`

Mode: **full** · Stage 2 · Decision authority: **deferred-human, defer-do-not-ask**
(`.harness/rules/25-decision-policy.md`). Upstream `01_REQUIREMENT_ANALYSIS.md` verdict is
**READY**; this design references its numbered items (AC-n / BC-n / B-n / D-n) instead of
restating them. Every judgment call is resolved here and listed in §14.

---

## 1. Architecture summary

`generate_config()` stops *being* the configuration and starts *composing* it. A module-level
data object `CONFIG_BASE` holds every key/value that does not depend on run-time state, at its
emitted position. One computed overlay (`_runtime_overlay()`) carries everything that does —
node outbounds, the `proxy` selector, the trailing `direct`, `route.rule_set`, the Clash API
address — and one user-owned overlay (`/etc/sing-box/override.json`) is applied last. All
overlays go through a single merge function `_merge()`: objects merge by depth, arrays only
under an explicit directive. The degradation step, `_write_private()` and `sing-box check` keep
their present shape and order; two new stderr statements (drift, malformed override) and one new
internal artifact (the drift record, a sha256 digest) are added. Nothing about the *emitted
content* changes — with no override present the bytes are identical, which is the gate (AC-1).

## 2. Affected files

| File | Change |
|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | all code changes (single file, AC-7) |
| `/home/alan/Programs/singbox-cli/README.md` | new "Custom configuration" section + 2 file-locations rows (AC-29) |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | line-for-line mirror of the above (B-17) |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | its own header mandates an update when modules/utilities change: new `bin/sc` sections, new reusable-utility rows, and the enlarged harness repoint list (§11). **This is an addition to the PM's stated diff boundary** — flagged for the gate; it is documentation, not code. |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | one glossary entry, **drift record** (added by this stage, already done) |
| `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | one record, `override-as-confd-fragment-directory` (added by this stage, already done) |

Not touched: `install.sh`, `uninstall.sh`, `systemd/` (O-2). `CHANGELOG.md` at delivery per
project convention; no AC depends on it.

## 3. D-16 — the user override's location and shape (the decision handed to me)

**Decided: a single file, `/etc/sing-box/override.json`.** Rejected: a `conf.d/*.json` fragment
directory (record appended to `.harness/rejected-decisions.md` as
`override-as-confd-fragment-directory`).

Against rule 85's counter-rule — *does the extra surface serve one of the five nameable
consumers?* — the answer is **none of them**:

- **T-15 / T-16 / T-17** ship their overlays as code *inside `bin/sc`* (D-11 fixes the base
  template's location for the same reason: `install.sh` fetches an enumerated artifact list,
  `install.sh:412-417`, and is out of scope). They never write a file under `/etc/sing-box`, so a
  fragment directory buys them nothing.
- **T-21** (rule-source profiles) is a *selection* problem — which mirror set / which rule sources
  — whose natural home is a key in `settings.json` selecting among overlays inside `bin/sc`,
  matching `docs/dev-map.md`'s "Don't add a config format for something a constant can express".
  Even if T-21 wanted a shipped fragment, it cannot install one: `install.sh` is out of scope here
  and `sc` never writes the override (B-9), so a directory would ship empty on every host.
- **User customization** is served *worse* by a directory: `sc` may not create it (B-9), so the
  user must `mkdir` before their first customization, and "is there an override?" becomes a
  directory scan with per-entry malformed-ness (BC-8…BC-10 × N) instead of one `stat`.

Only one adapter exists at this seam, so the seam is hypothetical, not real. The reversal is
cheap and localized if a real second consumer ever appears: `_load_override()` is the single
function that turns a *location* into overlay documents, and `_compose()` already takes a **list**
of overlays — a directory variant changes that one function's body and nothing else.

D-16's four binding constraints, discharged:

1. **Deterministic documented ordering** — exactly one document, applied after all internal
   overlays and last of all (D-10). Stated in both READMEs.
2. **Empty ≡ absent** — `{}` merges to a no-op structurally; whitespace-only/zero-byte content is
   treated as absent (§14 T-1).
3. **One merge implementation** — `_merge()`; the run-time overlay uses it on every single run
   (§5.2), so the shipped path exercises it 64 times in AC-1 alone.
4. **Named in both READMEs and in the drift message** — §8 (t-key 2) and §9.

## 4. New module-level constants and their placement in `bin/sc`

| Name | Value | Section |
|---|---|---|
| `OVERRIDE_PATH` | `CFG_DIR / "override.json"` | `# Paths` |
| `STATE_PATH` | `CFG_DIR / ".config.sha256"` | `# Paths` |
| `OVERRIDE_MAX_BYTES` | `1024 * 1024` | `# Config composition` |
| `DIRECTIVES` | `("$prepend", "$append", "$replace", "$before", "$after")` | `# Config composition` |
| `CONFIG_BASE` | the base template (§5.1) | `# Config composition` |

Both paths go in `# Paths` because that section's stated contract is "only ever referenced
*inside* function bodies, so a test harness can repoint them after import"
(`docs/dev-map.md`). Both **must be added to the harness repoint list** (§11).

The drift record lives under `CFG_DIR`, not `/var/lib/sing-box`: `_init_files()` hard-codes
`/var/lib/sing-box` as a `Path` literal (`.harness/insight-index.md`), so it is the one directory
a redirected-paths harness cannot repoint — a record there could not be tested without writing to
the developer's real `/var/lib`, which NFR-1 forbids. `uninstall.sh` removes `/etc/sing-box/`
wholesale, so the record leaves no residue either way.

One new section header, `# ============ Config composition ============`, is inserted between
`# Rule-sets` and `# Config generation` and holds `OverrideError`, `DIRECTIVES`,
`OVERRIDE_MAX_BYTES`, `CONFIG_BASE`, `_merge`, `_apply_directive`, `_anchor_index`,
`_load_override`, `_compose`, `_runtime_overlay`, `_dig`. The drift helpers stay in
`# Config generation`, immediately above `generate_config()`.

Two new stdlib imports, justified: **`copy`** (`copy.deepcopy` is the named operation that gives
each call a private document — see §5.1) and **`stat`** (`stat.S_ISREG` is BC-9's regular-file
guard, the load-bearing FIFO check). `hashlib` and `json` are already imported.

## 5. Module decomposition

### 5.1 `CONFIG_BASE` — the base template (decision 1)

**Representation: a module-level Python dict literal**, deep-copied per call.

```python
CONFIG_BASE = {
    "log": {...},
    "dns": {...},                                    # verbatim from today's literal
    "inbounds": [{"type": "tun", "tag": "tun-in", "interface_name": TUN_IFACE, ...}],
    "outbounds": [],                                 # placeholder, position-holding
    "route": {"default_domain_resolver": ..., "auto_detect_interface": True,
              "rules": [...], "rule_set": [], "final": "proxy"},   # rule_set: placeholder
    "experimental": {"cache_file": {...},
                     "clash_api": {"external_controller": ""}},    # placeholder
}
```

Argued against the three forces that bear on it:

- **BC-20 / AC-11 (repeated calls; `_filter_rules` mutates surviving rules in place).**
  `_compose()` starts from `copy.deepcopy(CONFIG_BASE)`, so the module-level object is never
  reachable from the document that `_filter_rules` and `del` mutate. `deepcopy` — rather than
  `json.loads(json.dumps(...))` — because it is the named operation a reader expects, it does not
  quietly normalise a mistake in the literal (a tuple would survive as a tuple and be caught), and
  it costs one stdlib import against a JSON round-trip on every call.
- **BC-23 (insertion order; a reorder fails the gate).** A dict literal's key order *is* the source
  order, so the diff is a pure move of today's literal to module level — a reviewer can verify key
  order by eye. `deepcopy` preserves insertion order. Crucially, every run-time value is written to
  a key that **already exists** in the base, and assigning to an existing key preserves its position
  in a CPython dict — that single fact is what makes the composed byte order identical.
- **AC-5 (no longer a single expression inside `generate_config()`; a named module-level *data*
  object).** Satisfied literally. This also **excludes a builder function** (a function is not a data
  object) and excludes an embedded JSON string: a JSON string cannot reference `TUN_IFACE`, and
  `TUN_IFACE` is THE single definition of this project's device name with three consumers
  (`docs/dev-map.md`) — inlining `"sb-tun"` into a JSON blob would break the "renaming stays one
  edit" property, and reaching it with placeholder substitution is the templating engine NFR-2
  forbids. Import-time capture of `TUN_IFACE` is correct precisely because it is a compile-time
  constant; `RULES_DIR` and `CLASH_PORT` are **not** (a harness repoints the first, `main()` assigns
  the second after import), which is why exactly those two are read at call time by §5.2.

The three placeholder values (`[]`, `[]`, `""`) can never be emitted: `_runtime_overlay()` sets all
three unconditionally on every call, over every input state AC-1 enumerates.

### 5.2 `_runtime_overlay(nodes, active, report)` → dict (decision 2)

The single carrier of B-3's run-time content, expressed as an overlay so the shipped path uses the
merge on every run (D-10's concern about untested machinery).

```python
def _runtime_overlay(nodes, active, report):
    node_tags = [n["tag"] for n in nodes]
    return {
        "outbounds": {"$replace":
            [{"type": "selector", "tag": "proxy", "outbounds": node_tags + ["direct"],
              "default": active or "direct", "interrupt_exist_connections": True}]
            + nodes + [{"type": "direct", "tag": "direct"}]},
        "route": {"rule_set": {"$replace": [
            {"tag": tag, "type": "local", "format": "binary",
             "path": str(RULES_DIR / fname)}
            for tag, fname, status in report if status == "usable"]}},
        "experimental": {"clash_api": {"external_controller": f"127.0.0.1:{CLASH_PORT}"}},
    }
```

Why this produces today's byte order: `outbounds` and `route.rule_set` are `$replace`d, which
assigns to an existing key (position preserved) a list built in exactly today's order;
`experimental.clash_api.external_controller` reaches its slot by depth-merge over an existing
scalar key. The selector's own nested `"outbounds"` array is *inside* a directive payload, so it is
deep-copied verbatim and never re-interpreted (B-7, structurally — §5.3).

`TUN_IFACE` is deliberately **not** here: it is not run-time state, and the base can name the
constant directly. `nodes` reach the document through `deepcopy` inside the merge, so BC-21
(`nodes.json` unchanged) is a structural property, not a promise.

### 5.3 `_merge(target, overlay, at="")` — THE merge implementation (decision 3)

Signature: mutates `target` (an object) in place; `at` is the dotted location used in error
messages; raises `OverrideError` (a plain `Exception` subclass — not `ValueError`, so an unrelated
`ValueError` from a bug is never rendered as a user error). Returns nothing.

Per key/value of `overlay`, with `where = at + "." + key` (or `key` at the top level):

| overlay value | target value | action |
|---|---|---|
| directive object | list | apply the directive (below) |
| directive object | absent, or not a list | error — key 12 (BC-13) |
| plain object | object | recurse `_merge(target[key], value, where)` (B-4) |
| plain object | absent, or not an object | `target[key] = deepcopy(value)` |
| array | list | **error — key 9** (BC-11 / D-5), naming the directives |
| array | absent, or not a list | `target[key] = deepcopy(value)` (D-6) |
| scalar (incl. `null`) | anything | `target[key] = value` |

A dict value is classified once, by `_directive_of(obj, where)`: collect keys starting with `$`;
none → plain object; some but not all keys → error 11 (B-5's reservation, which also covers two
directives in one object); one directive not in `DIRECTIVES` → error 10 (BC-14); otherwise the
`(name, payload)` pair. The same classifier runs on the override document's own root, so a
top-level `$…` key is rejected with `at = "the top level"`.

Directives (`_apply_directive(current, name, payload, where)` → new list):

| Directive | Payload | Result |
|---|---|---|
| `$replace` | array | `deepcopy(payload)` |
| `$prepend` | array | `deepcopy(payload) + current` |
| `$append` | array | `current + deepcopy(payload)` |
| `$before` | `{"match": {…}, "values": […]}` | insert at the anchor index |
| `$after` | same | insert at anchor index + 1 |

`_anchor_index(current, match, name, where)`: an element matches when it is an object and every
key/value of `match` equals the element's (subset equality, `==` on values, so
`{"rule_set": ["geosite-google"]}` matches by full list equality). Zero or more than one match →
error 15 naming the count and the anchor rendered as compact JSON (BC-12/D-7). Non-array payload →
error 13; a `$before`/`$after` payload that is not an object with exactly `match` and `values` →
error 14.

**Why B-7/D-9 falls out of the structure rather than being a remembered rule:** directive
classification happens in exactly one place — on a value being merged *into* `target` — and
`_apply_directive` deep-copies payload elements straight into the result list. There is **no edge
in the call graph from `_apply_directive` back to `_merge`**. An inserted element therefore cannot
be scanned for directives, whatever it contains. The same absence of an edge is why AC-18 holds
for nested arrays inside an inserted rule.

**Deep-copy discipline:** every value taken from an overlay is deep-copied in. Consequences that
are otherwise separate promises: no overlay is mutated by composition (BC-20), `_filter_rules`'
in-place edits cannot reach `CONFIG_BASE` or `nodes_data` (BC-21), and a second `generate_config()`
call in one process starts from identical inputs (AC-11).

**One directive per object.** Rejected: several directive keys in one object with a fixed
application order — it does not enable the case that would motivate it (two anchored insertions
into the same array, which JSON's unique keys forbid anyway) and adds an order to remember. Also
rejected: a *list* of `{match, values}` pairs as the `$before`/`$after` payload — speculative
generality with no named consumer, and it stays available as a strictly widening change later
(today's single object can be accepted as a one-element list without breaking any existing file).

### 5.4 `_load_override()` → dict | None

Reads `OVERRIDE_PATH`; never creates, writes or deletes it (B-9). Raises `OverrideError` carrying
an already-translated *problem sentence*.

```
os.stat(OVERRIDE_PATH)          FileNotFoundError -> None (absent)
                                other OSError     -> error 6 (BC-10)
not stat.S_ISREG(st.st_mode) -> error 5           (BC-9; stat() does not block on a FIFO,
                                                   open() would — this is the guard)
read at most OVERRIDE_MAX_BYTES + 1 bytes, binary
  more than the cap           -> error 8          (BC-8; capping the read, not trusting
                                                   st_size, closes the grow-after-stat race)
  OSError                     -> error 6
decode utf-8                    UnicodeDecodeError-> error 7 (BC-8)
text.strip() == ""           -> None              (empty ≡ absent, §14 T-1)
json.loads                      ValueError        -> error 3 (BC-8)
not isinstance(doc, dict)    -> error 4           (BC-8)
-> doc
```

A symlink resolving to a regular file is accepted (D-14): `os.stat` follows links, `S_ISREG` is
evaluated on the target.

### 5.5 `_compose(overlays)` → dict

```python
def _compose(overlays):
    doc = copy.deepcopy(CONFIG_BASE)
    for overlay in overlays:
        _merge(doc, overlay)
    return doc
```

AC-6's deletion test: delete the `_runtime_overlay(...)` element from the caller's list and the
override still composes through the same `_merge`. Deleting `_compose` itself would push the
deep-copy-then-loop into every future caller — it earns its keep by locality, not by size.

### 5.6 Drift: `_config_digest()`, `_record_generated()`, `_warn_drift()` (decision 5)

**What is stored: a digest, never a copy.** `STATE_PATH` holds the lowercase sha256 hex of
`config.json`'s bytes plus a newline — 65 bytes. AC-25 is satisfied by construction (no credential
bytes), and it is nevertheless installed through `_write_private()` at `0600`, which costs nothing
and removes the argument entirely. Rejected: storing a copy of the last generated document — it is
a second credential document on disk, which NFR-4/D-3 forbid and which T-13 deliberately did not
build.

```python
def _config_digest():
    """sha256 of config.json as it is ON DISK, or None when it cannot be read.
    THE single definition for drift purposes: the record writer and the drift check both
    call it, so they cannot form two opinions (rule 85, duplicated judgment)."""
```

- `_record_generated()` — called immediately after a successful `_write_private(CFG_PATH, …)` and
  only then (B-13). Hashing the file rather than the in-memory text makes the record
  locale-independent (see risk R-4) and makes "recorded == on disk" true by construction. An
  `OSError` writing the record is swallowed (precedent: `_resolve_clash_port()`'s
  `except OSError: pass`); the realistic causes (ENOSPC, EROFS) would already have failed the
  `config.json` write one line earlier.
- `_warn_drift()` — reads `STATE_PATH`; unreadable/absent/empty → return silently (BC-16, D-4);
  `_config_digest()` is `None` → return silently (BC-17); equal → return silently (AC-23);
  otherwise one stderr line (key 2) naming `CFG_PATH` **and** `OVERRIDE_PATH`. Writes nothing,
  reads `config.json` into memory only, never logs its content (NFR-4).

`sc doctor` calls none of these (O-6/BC-26); T-20 consumes `STATE_PATH` later.

### 5.7 `_dig(doc, "a.b.c")` → value | None

The value at a dotted path, `None` if any step is missing or not an object. Used once, for the
shape assertion in §6.

## 6. `generate_config()` — the new body and its ordering (decision 4)

I chose the **observable order the requirement pins** (AC-9), with two additions that are not in
its sequence, plus one internal reordering *before* the pinned sequence begins.

```python
def generate_config():
    override = _load_override()               # (1) FIRST — D-2. May raise OverrideError.
    nodes_data = load_nodes()                 # (2) unchanged
    nodes = nodes_data["nodes"]; active = nodes_data.get("active")
    report = ruleset_report()                 # (3) unchanged (the ONE rule-set query)
    node_tags = [n["tag"] for n in nodes]
    if active not in node_tags:               # (4) BC-3 — unchanged, still before the document
        active = node_tags[0] if node_tags else None
        nodes_data["active"] = active; save_nodes(nodes_data)

    overlays = [_runtime_overlay(nodes, active, report)]
    if override is not None:
        overlays.append(override)             # (5) D-10 — last, through the same _merge
    config = _compose(overlays)               # may raise OverrideError

    for at in ("dns.rules", "route.rules", "route.rule_set"):   # (6) shape assertion
        if not isinstance(_dig(config, at), list):
            raise OverrideError(t("at {at}: this must stay an array", at=at))

    defined = set(d.get("tag") for d in config["route"]["rule_set"] if isinstance(d, dict))
    if not config["route"]["rule_set"]:       # (7) degradation — T-02's block, unchanged
        del config["route"]["rule_set"]
    config["dns"]["rules"] = _filter_rules(config["dns"]["rules"], defined)
    config["route"]["rules"] = _filter_rules(config["route"]["rules"], defined)
    _warn_degraded(report)                    # (8) unchanged
    _warn_drift()                             # (9) NEW — stderr only, before the write (AC-22)
    text = json.dumps(config, indent=2, ensure_ascii=False)
    try:
        _write_private(CFG_PATH, text)        # (10) unchanged, still the only writer (AC-10)
    except OSError as e:
        ...unchanged...; return False
    _record_generated()                       # (11) NEW — B-13, only after a successful install
    r = subprocess.run([SB_BIN, "check", ...])# (12) unchanged (BC-24)
```

Notes on the choices:

- **(1) before everything.** D-2 wants the override parsed before anything is written; putting it
  first means the BC-8/BC-9/BC-10 class of failure costs the user nothing at all — not even the
  `nodes.json` active-rewrite. §14 T-2 covers the residue: a *merge-time* error (BC-11…BC-14) still
  occurs after step (4), because BC-3 pins that side effect's ordering and I preserved it literally.
  This is admissible under AC-20, whose own wording scopes "no write" to `config.json`.
- **(6) is not schema validation** (O-9). It names exactly the three paths the block below indexes
  into; without it a user override that turns `route` into a scalar produces a Python traceback
  instead of a sentence. It cannot fire with no override present, so AC-1 is unaffected.
- **`defined` instead of `usable`.** `usable_tags(report)` was the argument to both `_filter_rules`
  calls; the composed document's own `route.rule_set` tags are used instead. With no override the
  two sets are **equal by construction** (the overlay builds `route.rule_set` from exactly the
  usable entries of the same `report`), so AC-1 is unaffected — and a user who defines their own
  rule-set no longer has every rule referencing it silently deleted, which is precisely the
  "an overlay that silently does nothing" failure BC-12 calls intolerable. `_filter_rules` keeps its
  single definition, both call sites and no array-name parameter (AC-8). **Discretionary**: if the
  gate judges this outside T-14, the reversal is one token (`defined` → `usable_tags(report)`).
- **(9) after `_warn_degraded`**, immediately before the write, so the statement sits next to the
  action it warns about. AC-9's pinned sequence is untouched; the drift line is an addition to it,
  not a reordering of it.
- **No `try` around `_compose`.** After T-14 the run-time overlay cannot raise: its three directives
  are all `$replace` against arrays `CONFIG_BASE` guarantees, over all 64 AC-1 states. The single
  rendering site (§7) therefore names the override path truthfully. A future task that adds a
  shipped content overlay must extend AC-1 accordingly — recorded as risk R-3.

## 7. The failure path of a malformed override (decision 7)

`OverrideError` propagates out of `generate_config()` uncaught and is rendered in **one place**, a
new handler in `main()` around the existing dispatch line:

```python
    try:
        handlers.get(args.cmd, cmd_help)(args)
    except OverrideError as e:
        sys.exit(t("Cannot use {path}: {problem}", path=OVERRIDE_PATH,
                   problem=_plain(str(e))))
```

- **Where it aborts:** before `_write_private()` in every case, so `config.json` is byte-identical
  afterwards (AC-20) and no *service-affecting action* occurs — `restart_service()` is reachable
  only from `reload_or_restart()` **after** `generate_config()` returns, and it never returns
  (AC-21). `sc use`'s hot-apply path (`is_running()` + a successful Clash API PUT) never calls
  `generate_config()` at all, so it is unaffected — QA must exercise AC-20/AC-21 through
  `sc reload`, or with the service stopped.
- **What the command returns:** `sys.exit(str)` prints the line on stderr and exits **1** for
  *every* invoking command uniformly — including `sc add` and `sc rm`, which today swallow a false
  return from `reload_or_restart()` and exit 0. Rejected: returning `False` — it fails AC-20 for
  three commands, and fixing that per-command would rewrite three commands' contracts, i.e. scope.
  Precedent for exiting from below a command: `save_nodes()` (`bin/sc:386`), which
  `generate_config()` already calls.
- **`_plain()` is applied once**, here, over the whole assembled sentence — which is what makes
  NFR-7 (no CR, no ESC) true for every user-supplied fragment inside it (a key name, an anchor, an
  OS message) without a `_plain()` call at each raise site.
- **`install.sh` step 7** consequently sets `PHASE_CONFIG=failed` and the installer reports a
  failed install pointing at `sc reload` (BC-19) — no installer change.

## 8. New `t()` keys (decision 6)

English key = the English rendering (`bin/sc` has no `en` table, AC-28). No new `zh` value contains
`失败：` (AC-27). Placeholder sets are identical in both columns.

| # | key (English) | `zh` |
|---|---|---|
| 1 | `Cannot use {path}: {problem}` | `无法使用 {path}：{problem}` |
| 2 | `{path} was modified outside sc — those changes are about to be replaced; put them in {override} to keep them.` | `{path} 曾被 sc 以外的方式修改，这些改动即将被覆盖；如需保留，请写入 {override}。` |
| 3 | `not valid JSON ({err})` | `不是有效的 JSON（{err}）` |
| 4 | `the top level must be a JSON object` | `顶层必须是一个 JSON 对象` |
| 5 | `not a regular file` | `不是普通文件` |
| 6 | `cannot be read ({err})` | `无法读取（{err}）` |
| 7 | `not valid UTF-8 text` | `不是有效的 UTF-8 文本` |
| 8 | `larger than {n} bytes` | `超过 {n} 字节` |
| 9 | `at {at}: an existing array must be changed with one of {directives}` | `在 {at}：修改已有数组必须使用 {directives} 之一` |
| 10 | `at {at}: unknown directive {name} — use one of {directives}` | `在 {at}：未知指令 {name} —— 请使用 {directives} 之一` |
| 11 | `at {at}: {name} cannot be combined with other keys in the same object` | `在 {at}：{name} 不能与同一对象中的其他键并存` |
| 12 | `at {at}: {name} can only be applied to an array that already exists` | `在 {at}：{name} 只能作用于已存在的数组` |
| 13 | `at {at}: the value of {name} must be an array` | `在 {at}：{name} 的值必须是数组` |
| 14 | `at {at}: {name} needs an object with "match" and "values"` | `在 {at}：{name} 需要一个含 "match" 与 "values" 的对象` |
| 15 | `at {at}: {name} matched {count} elements, but exactly one is required — match: {anchor}` | `在 {at}：{name} 匹配到 {count} 个元素，但必须恰好匹配 1 个 —— match：{anchor}` |
| 16 | `the top level` | `顶层` |
| 17 | `at {at}: this must stay an array` | `在 {at}：这里必须仍然是数组` |

Key 2 is one physical line (NFR-7). Key 1 carries the `⚠️`-less shape of `sys.exit` messages
(precedent: `save_nodes`, `cmd_reload`); key 2 is a warning and keeps the
`"⚠️  " + t(...) + "\n"` shape (`docs/dev-map.md`).

## 9. The user-facing contract (both READMEs, AC-29)

New section **"🛠 Custom configuration (`override.json`)"**, inserted immediately after
`## 📂 File locations` in `README.md` (line 202 today) and at the mirrored position in
`README.zh-CN.md`, containing: the path; "`sc` never creates, writes or deletes it, and it survives
`sc reload` / `use` / `add` / `rm` / `mode` / `update-rules` and re-running `install.sh`"; the
object-merge rule; the five directives with one worked `$after` example on `dns.rules`; the
"applied last" ordering; and BC-15's honest warning that removing
`experimental.clash_api.external_controller` or the `proxy` outbound tag breaks `sc use` /
`sc status` while still passing `sing-box check`. Two rows added to the file-locations table:

| User override (optional, yours) | `/etc/sing-box/override.json` |
| Drift record (internal) | `/etc/sing-box/.config.sha256` |

## 10. Reuse audit

| Need | Existing code | File | Decision |
|---|---|---|---|
| Install a document at 0600, atomically | `_write_private(path, text)` | `bin/sc` `# State files` | Reuse as-is for `config.json` (unchanged) **and** for the drift record; no second write path (AC-10, B-15) |
| Drop dangling rule-set references | `_filter_rules(rules, usable)` | `bin/sc` `# Rule-sets` | Reuse unchanged, both call sites, no new parameter (AC-8) |
| Degradation warning | `_warn_degraded(report)` | same | Reuse unchanged, same position |
| Rule-set usability | `ruleset_report()` / `usable_tags()` | same | Reuse unchanged; the overlay consumes the same single `report` |
| Foreign text made output-safe | `_plain(text)` | `bin/sc` `# doctor` | Reuse — one call at the single render site (§7) |
| Bilingual output | `t()` + `TRANSLATIONS["zh"]` | `bin/sc` `# i18n` | Extend with 17 keys (§8) |
| Warning to stderr | `"⚠️  " + t(...) + "\n"` | `generate_config`, `_warn_degraded` | Reuse the shape for the drift line |
| Terminate with one translated line | `sys.exit(t(...))` in `save_nodes` | `bin/sc` | Reuse the pattern for a malformed override |
| Content-equality of a file | `hashlib.sha256` over a full read, as in `ruleset_state()` | `bin/sc` `# Rule-sets` | Same *technique*, separate function: `ruleset_state()` answers "is this rule-set usable", a judgment `_config_digest()` must not re-form (`docs/dev-map.md`: never a second opinion) |
| Best-effort persistence of a derived value | `_resolve_clash_port()`'s `except OSError: pass` | `bin/sc` | Reuse the pattern for `_record_generated()` |
| A shared `sing-box check` wrapper / a shared atomic-write helper | — | `.harness/rejected-decisions.md` | Already declined; not re-litigated |
| Deep merge / JSON patch | (none found — the repo has no merge of any kind) | — | New, justified by the five nameable edits |

## 11. Testability — how AC-1's 64-run differential is driven

The developer builds this **first**; it is a throwaway (O-8, open row R-9), pasted into the stage
documents rather than committed.

1. **Two modules in one process.** Baseline = `git show <start-commit>:bin/sc` written to a temp
   file; candidate = the working tree's `bin/sc`. Each is loaded with the neutralisation recipe in
   `docs/dev-map.md` "Patterns to avoid" **verbatim** (the `os` shim whose `geteuid` returns 0,
   restored in a `finally`). Do not invent another.
2. **Repoint list — now seven paths.** `CFG_DIR`, `CFG_PATH`, `NODES_PATH`, `SETTINGS_PATH`,
   `RULES_DIR`, **`OVERRIDE_PATH`**, **`STATE_PATH`** into a `mkdtemp()` root, plus
   `SYSTEMD = OPENRC = False`, `CLASH_PORT`, `LANG`, `SB_BIN`. The candidate module has two path
   constants the baseline does not; setting them on the baseline is a harmless no-op.
   **The harness must assert that every repointed path is inside the temp root** — that assertion,
   not vigilance, is what stops a forgotten constant from touching `/etc`.
3. **`SB_BIN = "/bin/true"`** (and `/bin/false` for the check-failure case): a stub with no fixture
   file, exercising the real `subprocess.run(..., capture_output=True, text=True)` call.
4. **Never call `_init_files()`** — it hard-codes `/var/lib/sing-box` (insight-index). Seed
   `nodes.json` by writing the file directly.
5. **The 64 points:** 16 rule-set subsets × 4 node/active states. Rule-set fixtures:
   usable = `b"SRS" + b"x" * 32`; `bad-magic` = 32 bytes not starting with `SRS`; `too-small` =
   `b"SRS"`; `absent` = no file; `unreadable` = mode `000` — **producible only because the recipe
   asserts the harness is not root**, which is a second reason not to weaken that assert.
6. **Compared per point:** `CFG_PATH.read_bytes()`, captured stderr, the boolean return (AC-3), and
   `nodes.json`'s bytes (AC-12) — in both `LANG = "en"` and `"zh"`. Capture stderr with
   `contextlib.redirect_stderr` (the code resolves `sys.stderr` at call time).
7. **Tree comparison is scoped.** The candidate additionally writes `STATE_PATH`; assert that this
   is the *only* extra artifact rather than diffing the trees wholesale.
8. **Extras** layered on state (c): non-ASCII node tag (BC-4); one run per non-usable status
   (BC-6); a non-default `CLASH_PORT`; a non-default `RULES_DIR` (a second temp dir holding the
   `.srs` fixtures) — `ruleset_states()` reads `RULES_DIR` at call time, so repointing works.
9. **AC-11:** three consecutive `generate_config()` calls on one fixture, all three byte-compared.
10. **AC-4 non-vacuity:** re-run the whole differential against a *copy* of the candidate with a
    one-character edit (e.g. `"level": "warn"` → `"warns"`), record that it FAILS, and keep the
    output in the stage documents.
11. **Bilingual parity for the 17 new keys** (AC-27/AC-28): assert each key is present in
    `TRANSLATIONS["zh"]`, that `set(re.findall(r"{(\w+)}", key))` equals the same set for the `zh`
    value, and that no new `zh` value contains `失败：`. This is the check that catches
    insight-index's "a call site naming a key absent from both tables is invisible" class.
12. **Override semantics (AC-13…AC-21)** are exercised on the candidate only, with an override file
    planted in the fixture root; AC-17 is driven by composing two synthetic overlays through
    `_compose` directly.

## 12. Safety — binds stages 4 and 6 (NFR-1)

- `bin/sc` auto-elevates **at import time** by re-exec'ing the **installed** `/usr/local/bin/sc`
  under `sudo`, and `sudo`'s `env_reset` drops environment overrides. An un-neutralised import runs
  the *installed older* tool against the owner's *live* service. Use the recipe in
  `docs/dev-map.md`; do not invent another.
- **Never write under `/etc` on this machine.** Never use `/usr/local/bin/sc` as an oracle (AC-2).
- Service witness at every checkpoint: `systemctl show sing-box -p MainPID -p ActiveEnterTimestamp`
  — never `is-active` (insight-index). Baseline to report identical: `MainPID=2887037`,
  `ActiveEnterTimestamp=Sat 2026-08-01 10:06:40 CST`.
- Every fixture root is a `mkdtemp()`; `SYSTEMD = OPENRC = False` before any command is driven.

## 13. Risks and mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | **Key order silently changes** during the literal's move to module level (a re-indent that reorders, a "tidy" alphabetisation). This is the single most likely way to fail AC-1 and the hardest to spot by eye. | Build the differential **before** touching the literal; move the literal as a pure text move with no re-typing; AC-4's non-vacuity proof establishes the harness would notice. |
| R-2 | **A run-time value lands at the wrong position** because its key is absent from `CONFIG_BASE` and the merge appends it. | The three placeholders are mandatory and are listed in §5.1; the failure is loud in the differential on run #1, not subtle. |
| R-3 | A future task adds a shipped content overlay that can raise, and the error message falsely names the override file (§6). | Stated in code as a comment at the single rendering site; T-15/T-16/T-17 inherit AC-1 and must extend it. |
| R-4 | **Pre-existing, not introduced:** `_write_private()` writes through `os.fdopen(fd, "w")` with no `encoding=`, so on a non-UTF-8 locale (`LANG=C` under `sudo`) a non-ASCII node tag raises `UnicodeEncodeError` — BC-4's own case. The drift record is immune because `_config_digest()` hashes the file's bytes, not the in-memory text. | **Do not fix here** (outside T-14's boundary, and it changes `_write_private`'s behaviour). Report it for a new pool row; note that the harness runs under a UTF-8 locale, so AC-1 will not surface it. |
| R-5 | `_filter_rules` mutates surviving rules in place; a shallow copy of `CONFIG_BASE` anywhere in the chain would corrupt the template for the *second* call in the same process. | `copy.deepcopy` at exactly two places (§5.1, §5.3) and AC-11's three-call check. |
| R-6 | A user override that is *valid* but removes what `sc` depends on (BC-15) leaves `sc use` / `sc status` broken with a config that passes `sing-box check`. | Not prevented (a "what `sc` depends on" schema serves none of the five); stated in both READMEs. |
| R-7 | 17 new `t()` keys land with a missing or mis-placeholdered `zh` entry; `bin/sc` has no automated parity gate (B.2 covers `install.sh` only). | §11 item 11 — a scripted parity assertion over the new keys, run by the developer and by QA. |
| R-8 | `sc update-rules` reaching a malformed override aborts before T-10's "exactly one truthful run-level outcome" line. | Accepted and documented (§14 T-3), with the 6-line alternative specified there. |

## 14. Decisions taken under standing authority

**D-16** (§3) — single `/etc/sing-box/override.json`; `conf.d/` directory rejected and recorded.

**A-1 Base template = module-level Python dict literal + `copy.deepcopy` per call.** Rejected:
builder function (AC-5 wants a data object), embedded JSON string (cannot name `TUN_IFACE`; needs
substitution), `json.loads(json.dumps())` copy (normalises mistakes away). §5.1.

**A-2 Run-time content travels as one computed overlay with `$replace`,** not direct assignment.
Rejected: direct assignment — it leaves the merge with zero shipped consumers in T-14 (D-10's
"untested machinery" concern); the overlay makes AC-1's 64 runs a 64-run test of the merge. §5.2.

**A-3 One directive per object; `$before`/`$after` payload is `{match, values}`.** Rejected:
multiple directives with a fixed order; a list of anchors. §5.3.

**A-4 A directive at a key that does not exist in the target is an error** (not "create the
array"). A misspelt path is the most likely user error, and silently creating it reproduces the
"overlay that silently does nothing" failure BC-12 forbids; D-6 already gives a way to create a
key (a plain array). §5.3 table.

**A-5 `OverrideError` is a direct `Exception` subclass, rendered in one place in `main()`,
terminating via `sys.exit` with exit status 1.** Rejected: `return False` (fails AC-20 for
`sc add` / `sc rm` / `sc update-rules`); subclassing `ValueError` (an unrelated `except ValueError`
could swallow it). §7.

**A-6 The drift record is a sha256 digest of the file on disk, at `CFG_DIR/.config.sha256`, written
through `_write_private()` at 0600.** Rejected: a copy of the document (a second credential
document); `/var/lib/sing-box` (untestable — hard-coded `Path` literal in `_init_files()`); hashing
the in-memory text (locale-dependent, R-4). §5.6.

**A-7 `_filter_rules` is called with the tags the composed document defines, not with
`usable_tags(report)`.** Equal by construction with no override, so AC-1 is unaffected; serves
"user customization" directly. Marked **discretionary** — one-token reversal. §6.

### Tensions resolved (flagged for the gate reviewer)

**T-1 — whitespace-only / zero-byte override is treated as *absent*, not malformed.** BC-7 (and
D-16's binding constraint) say empty is identical to absent; BC-8 says "not valid JSON" is
malformed, and a zero-byte file is not valid JSON. I resolved it toward BC-7 for this one narrowly
defined case: `touch override.json` expresses "no override yet", cannot mask a typo (a typo is not
whitespace), and the alternative makes an empty file break `sc reload` and fail an install (BC-19).
Everything non-whitespace that is not a JSON object stays malformed. **Reversal cost: delete one
`if not text.strip(): return None` branch.**

**T-2 — a merge-time error (BC-11…BC-14) aborts *after* the `nodes.json` active-rewrite.** D-2 says
"parsed and merged before anything is written"; BC-3 says the `save_nodes()` side effect and its
ordering are preserved. Both cannot hold literally. I kept BC-3 literal and moved only the
*parse* to the top of the function, so the common failure class (BC-8/BC-9/BC-10) costs nothing at
all. The residue is idempotent (the rewrite stores the value the next successful run would store),
is not a *service-affecting action*, and does not touch `config.json` — which is what AC-20 pins.

**T-3 — `sc update-rules` + malformed override skips T-10's run-level outcome line.** Any abort
mechanism has this property, because the abort unwinds past `cmd_update_rules`' summary block. Not
mitigated: the six lines of exception-stashing needed to print the summary first would complicate
the one command least likely to reach the path (it requires a rule-set to have *gained* usability
while the user's override is broken). If the gate wants it: stash the exception in a local inside
the `if gained:` arm, set `regen_ok = False`, print the outcome block, then `raise` it.

## 15. Out-of-scope clarifications

This design does **not** cover, by construction: any change to the emitted configuration's content
(O-1, D-12 — zero shipped content overlays); a deletion directive (O-4); the override file's mode,
ownership or credential audit (O-5 → T-20); surfacing drift in `sc doctor` (O-6 → T-20, which reads
`STATE_PATH`); backup/restore of a drifted `config.json` (O-7); a committed harness (O-8 → R-9);
schema validation beyond `sing-box check` (O-9 — the §6 shape assertion names exactly three paths
and is not a schema); `install.sh` / `systemd/` (O-2); timeouts (O-3); and R-4's `_write_private`
encoding defect, which is reported, not fixed.

## 16. Verdict

**READY.**

The design meets AC-1 by construction (the base template is a pure move; every run-time value is
written to a key that already exists at its emitted position; the document is deep-copied per
call), keeps `_write_private()` the only writer of `config.json`, keeps `_filter_rules` a single
definition with two call sites and no new parameter, adds no dependency beyond two stdlib imports,
adds no file format beyond JSON, and ships zero content change. Every element of the design is
attributable to one of the five nameable consumers:

| Element | Serves |
|---|---|
| `CONFIG_BASE` as data | T-15, T-16, T-17, T-21 (all four edit it) |
| `_merge` object depth-merge | T-15, T-16, T-17, T-21, user customization |
| `$replace` | the run-time overlay (every run), T-21, user customization |
| `$prepend` / `$append` | T-15 (outbounds), T-17, user customization |
| `$before` / `$after` + anchors | T-16, T-17 (D-7's exact motivation), user customization |
| `_load_override` + `OVERRIDE_PATH` | user customization |
| Drift record + statement | user customization (the change survives) and T-20 (consumer) |
| `defined` instead of `usable` | user customization (a user-defined rule-set is not deleted) |

Nothing in the design serves none of the five. Cut during design and not present: a deletion
directive, multi-directive objects, an anchor list, a fragment directory, a `conf.d` ordering rule,
a schema of "what `sc` depends on", and a backup path.

**For the gate reviewer:** three tensions are flagged in §14 (T-1, T-2, T-3) and one element is
marked discretionary (A-7). Each names its reversal cost, so any of them can be ruled against
without re-architecting.

**For the developer:** build §11 first. No structural choice that cannot satisfy AC-1 is
admissible, and AC-4's non-vacuity proof is what makes the 64 green runs mean anything.
