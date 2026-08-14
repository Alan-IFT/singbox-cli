# Dev Map — singbox-cli

> Project structure and conventions navigation. **Update this whenever you add / move / remove a module.**
>
> The developer agent reads this before writing code, so it doesn't reinvent existing patterns.

## Folder layout

```
singbox-cli/
├── bin/sc              ← the ENTIRE CLI: one Python 3 file, no package, no imports
│                         beyond the stdlib. Installed to /usr/local/bin/sc.
├── install.sh          ← self-contained Bash installer (also served over `curl | bash`)
├── uninstall.sh        ← Bash uninstaller, installed to /usr/local/lib/singbox-cli/
├── systemd/            ← sing-box.service, sing-box-rules-update.{service,timer}
├── README.md           ← English; README.zh-CN.md is its line-for-line mirror
├── CHANGELOG.md        ← user-visible changes (written in Chinese)
├── docs/               ← architecture.md, faq.md, features/, this map, task board
└── .harness/           ← pipeline rules, scripts, insight index (not shipped)
```

There is **no build step, no dependency manifest and no test directory.** `.harness/scripts/verify_all.sh`
B.1 syntax-checks `bin/sc`, `install.sh`, `uninstall.sh`; B.2 runs the `install.sh` bilingual
key-parity check (T-11); B.3 (lint) is still `SKIP`.

## `bin/sc` internal sections (in file order)

| Section | What lives there |
|---|---|
| `# Paths` | `CFG_DIR` / `CFG_PATH` / `NODES_PATH` / `SETTINGS_PATH` / `RULES_DIR` / `OVERRIDE_PATH` (the user's own fragment) / `STATE_PATH` (the drift record, `.config.sha256`), `CRED_MODE` (THE mode of every credential document, `0o600`), `SB_BIN`, `TUN_IFACE`, `AUTO_TAG` (THE tag of the auto-select group — one definition, no consumer spells the literal, language-neutral so `sc lang` cannot move it) and `RESERVED_TAGS` (built from it: the tags `sc` emits itself and no node may carry), `IF_INET6_PATH` (THE one source of the host's IPv6 address state), Clash-API port range. The **eight path constants** are only ever referenced *inside* function bodies, so a test harness can repoint them after import. **`TUN_IFACE` is the exception and no longer obeys that contract**: `CONFIG_BASE` captures it at *import* time (it is a compile-time constant, and the base template names it directly rather than through a placeholder), so a harness that repoints it after import silently gets the old device name in the emitted config. Repoint it before loading the module, or not at all. |
| `# Rule-set constants` | `SRS_MAGIC`, `SRS_MIN_BYTES`, `RULESET_FILES` (filename → path relative to a base), `RULESET_BASES` (ordered mirrors), `RULE_ANSWER_KEYS`. |
| `# Auto-elevate` | `os.execvp("sudo", ...)` at **import time** when not root. A harness must neutralise this line to load the file as a module. |
| `# i18n` | `TRANSLATIONS` (English source string → `zh`) and `t()`. |
| `# State files` | `_write_private`, `_init_files`, `load/save_nodes`, `load/save_settings`. `_init_files()` is reachable only from `main()`, so importing touches nothing under `/etc`; its nodes branch is now nothing but a `save_nodes()` call. |
| `# Share-URL parsers` | `parse_vless / vmess / trojan / ss / hy2 / tuic` → dispatched by `parse_share_url`. |
| `# Rule-sets` | The usability model — see "Reusable utilities" below. |
| `# Config composition` | The layer `config.json` is built *from*: `OverrideError`, `DIRECTIVES` / `_directive_list()`, `OVERRIDE_MAX_BYTES`, `CONFIG_BASE` (the base template — a module-level dict literal whose key order IS emission order), `_dig`, `_directive_of`, `_anchor_index`, `_apply_directive`, `_merge`, `_load_override`, `_compose`, `_auto_group_emitted`, `_valid_selection`, `_ipv6_setting`, `_global_ipv6_iface`, `ipv6_decision`, `_dns_overlay`, `TELEMETRY_NAMES`, `_telemetry_setting`, `_telemetry_overlay`, `_runtime_overlay`. See "Reusable utilities" below. |
| `# Config generation` | `generate_config()` **composes** `config.json` in two steps — `_compose([_runtime_overlay(), _dns_overlay(), _telemetry_overlay()])` for the three overlays `sc` itself authors, then one `_merge()` of the user's `override.json` over the result, so the user's document is still applied LAST and still through the one merge. Overlay order inside that list is not load-bearing (a `$prepend` at index 0 and an object-anchored `$before` commute, because the anchor is resolved by content) but is kept so source order matches emitted order. The split buys provenance, not bytes: each of the two failure sources has its own code site, and the sites that handle the USER's document (the load, that merge, and the three-key array guard) set `OverrideError.path = OVERRIDE_PATH` — the class default `None` renders against `CFG_PATH`, so a fault in an overlay `sc` wrote is never reported as a fault in the user's file. It then filters the document by the rule-set tags the composed document defines, warns about drift, installs it through `_write_private()` (0600 from before its first byte, atomic replace — **not** a post-write `chmod`), records the digest, then runs `sing-box check`. An `OSError` there is one translated stderr line + `return False`, never a traceback. Also holds the drift trio `_config_digest()` / `_record_generated()` / `_warn_drift()` and the two apply helpers `restart_service()` and `reload_or_restart()`. |
| `# Clash API` | `clash_api(method, path, data=None, port=None)` — **total over the three exception families its own body raises** (`OSError`, `ValueError`, `http.client.HTTPException`): a JSON object or `None`, and never another type. Those three families, never their leaves (timeout, refusal, bad status, bad bytes, bad JSON, short body) and never a bare `Exception` — a leaf enumeration is the shape that needs re-patching every time a sibling escapes. One residue is deliberate: a pathological body from a process on this host's own loopback can still raise `RecursionError` / `MemoryError`, and no size or depth cap is bought for a threat model that is already lost. An empty 2xx body is `{}` (so a `204` reads as success); a body that is not a JSON object is `None`. Callers therefore add no `try`/`except` — adding one is the defect, not the fix. `is_running()`, `stored_delays(port=None)`. `port=None` means "the port `main()` resolved"; only `sc doctor` passes one explicitly. |
| `# Commands` | One `cmd_<name>(args)` per subcommand, `cmd_ipv6()` (`sc ipv6 on\|off\|auto\|show`, the one surface of `ipv6_decision()`) and `cmd_telemetry()` + `_telemetry_meaning()` (`sc telemetry block\|allow\|show`, the one surface of `_telemetry_setting()` and of `TELEMETRY_NAMES`) included. Includes the `# doctor` block: class constants + `_plain()` / `_doctor_run()` / `_doctor_print()`, seven probes returning rows as data, the `DOCTOR_SECTIONS` print order, and `cmd_doctor()` (driver: isolation, streaming, exit status). |
| `HELP_EN` / `HELP_ZH` | Two hand-aligned help blocks; descriptions start at column 30, sub-options at column 32. |
| `main()` | argparse subparsers + a `handlers` dict. **Parses arguments first, then initialises**: `doctor` is the one command that takes the read-only arm (`LANG = _load_lang()` only) and skips `_init_files()` / `_resolve_clash_port()`; every other command — present and future — takes the `else` arm unchanged. Assigns `LANG` and `CLASH_PORT` **after** import. |

## Reusable utilities

| Need | Existing | File | Notes |
|---|---|---|---|
| "Is this rule-set usable?" | `srs_reject_reason(head, size)` | `bin/sc` `# Rule-sets` | The single definition (SRS magic + size floor). Three adapters: `ruleset_state(path)` for a file, `_fetch_to_temp()` for bytes off a socket, `_status_text()` for the screen. Never form a second opinion. |
| One file's on-disk facts | `ruleset_state(path)` → `(status, digest, size, mtime)` | same | The ONE reader of a `.srs` on disk, from one chunked read. `digest` is sha256 of the full content, `size` is that read's real byte count (**never `st_size`**) and `mtime` is `st_mtime` from an `os.fstat()` on that **same open handle** (never a second `stat()` of the path — it can describe a different file, since `sc update-rules` replaces the inode), or all three `None` — and `size is None` ⟺ `digest is None` ⟺ `mtime is None` ⟺ status ∈ `absent / unreadable` ⟺ no complete read (a readable *empty* file gets a real digest, a real `0` and a real timestamp). `sc doctor` prints the size that decided the status, so its report cannot contradict itself. `ruleset_status(path)` is its status-only view; it has no in-tree caller today and is kept as the named per-file adapter. |
| "How old is this rule-set file?" | `_age_text(mtime)` | `bin/sc` `# Rule-sets`, beside `_status_text()` | THE one age renderer, over `ruleset_state()`'s `mtime` and nothing else: one deterministic vocabulary (`{n} days/hours/minutes/seconds ago`, largest unit only, floor-divided) plus the word form `last update unknown` when no complete read happened — a missing timestamp is never a number, never `0`, never an epoch date, and a clock ahead of the file renders `0 seconds ago` rather than a negative duration. Takes no command-specific argument, so `sc status` and any later screen call it unchanged instead of deriving an age a second way. Must stay a function (`LANG` is assigned in `main()`, after import). It carries **no** staleness threshold and no fresh/stale verdict — the age is a fact; any future verdict must be a function of this one. |
| Per-file rule-set state | `ruleset_report()` → `[(tag, filename, status)]`, `usable_tags(report)` | same | Pure query: no network, no service, no config, writes nothing. `status` is a flat `str`: `usable / absent / bad-magic / too-small / unreadable`. Built as `_status_view(ruleset_states())`; `ruleset_states()` is the same list with the digest, size **and mtime** appended (6-tuples). `_status_view()` is the shield: it is where a widening of the snapshot tuple stops, which is why the three sites that destructure the 3-tuple — `_runtime_overlay()` (`bin/sc:1815`), `usable_tags()` (`:905`) and `_warn_degraded()` (`:976`) — need no edit when it widens. `generate_config()` destructures nothing: it only passes `report` through to them. |
| "Did any rule-set's content change?" | `changed_usable_tags(before, after)` | same | Both args are `ruleset_states()` snapshots; returns the sorted tags that are usable *after* and whose bytes really differ. Paired by tag, never by list index. This — not "the download succeeded" — is what `sc update-rules` restarts on. |
| Drop dangling rule-set refs | `_filter_rules(rules, usable)` | same | Called for **both** `dns.rules` and `route.rules` with the same set. Do not add an array-name parameter. Since T-14 the set is the tags the *composed document* defines, not `usable_tags(report)` — identical by construction with no override, and it is what stops a user-defined rule-set having every rule referencing it deleted. It is computed **before** the empty-`route.rule_set` deletion. |
| Apply a configuration fragment | `_merge(target, overlay, at="")` | `bin/sc` `# Config composition` | THE merge: objects by depth, arrays only under a directive from `DIRECTIVES`. The run-time overlay, any future shipped overlay and the user's `override.json` all go through it — a second one would be a second opinion about what "apply a fragment" means. Errors are `OverrideError` carrying an already-translated sentence. |
| "Is this value a directive?" | `_directive_of(value, where)` | same | The ONE place a `$…` key is recognised, and it runs only on a value being merged *into* the document. `_apply_directive()` has **no edge back to `_merge()`**, which is why an element inserted into an array is copied verbatim and its nested keys are never interpreted. Do not add that edge. |
| The base of the emitted config | `CONFIG_BASE` + `_compose(overlays)` | same | `_compose` deep-copies `CONFIG_BASE` per call; `_filter_rules` mutates surviving rules in place and `generate_config` deletes a key, so anything short of a deep copy corrupts the template for the *second* call in one process. Key order in the literal is emission order — never alphabetise or re-indent it into a different shape. **Two `dns.rules` elements are PUBLISHED anchors** that both READMEs tell users to write into their own `override.json`: `{"server": "hosts_dns"}` (T-17's three recipes — add / except / combined, `README*.md:191,209,226`) and `{"clash_mode": "Direct"}` (the Custom-configuration example, `README*.md:384`, since T-14). `{"clash_mode": "Global"}` is **not** one of them — it is `_telemetry_overlay()`'s own internal anchor, resolved before the user's document is merged, so changing it breaks only this repo. Each published anchor must keep matching **exactly one** element in every settings and rule-set state — `_anchor_index()` errors on zero or several, so changing or duplicating either breaks `sc reload` on a user's host, not just ours. An anchor that exists in only *some* states is the defect T-17's gate caught: `{"rcode": "NXDOMAIN"}` was the original published anchor and it exists only under `telemetry: block`. |
| "Does this host suppress AAAA, and why?" | `ipv6_decision()` → `(setting, suppress, sentence)` | `bin/sc` `# Config composition` | THE definition of the effective IPv6 decision, over `_ipv6_setting()` (the single reader of `settings["ipv6"]`; absent ⇒ `auto`) and `_global_ipv6_iface()` (the single predicate: a `2000::/3` address on a device that is neither `lo` nor `TUN_IFACE` — "any IPv6 address" is WRONG here, a host running this project always carries a link-local address on `sb-tun`). Exactly two callers, `_dns_overlay()` and `cmd_ipv6()`; neither re-derives any part of it, so the emitted document and what `sc ipv6` says about it cannot become two opinions. Detection failure ⇒ do **not** suppress, plus one stderr line: suppressing on a host that can use IPv6 makes IPv6-only destinations unreachable, while the converse only costs latency the user already has. Reads at most two files; writes nothing. |
| "Which telemetry names does this project reject, and is rejection on?" | `TELEMETRY_NAMES` + `_telemetry_setting()` | `bin/sc` `# Config composition` | `TELEMETRY_NAMES` is THE list (a tuple, like `RULESET_FILES`: its order IS the emitted `domain_suffix` order); `_telemetry_setting()` is THE reader of `settings["telemetry"]` — absent ⇒ `block`, an unrecognised value ⇒ `block` plus one stderr line. Exactly two consumers each, `_telemetry_overlay()` and `cmd_telemetry()`; neither re-derives either, so the emitted document and what `sc telemetry` says cannot become two opinions. There is deliberately **no** `telemetry_decision()` sibling — unlike IPv6 there is no host-derived input, so the setting *is* the decision. Its guard tuple is `_ipv6_setting()`'s and inherits the same hole: a **non-UTF-8** `settings.json` raises `UnicodeDecodeError`, which is a `ValueError`, not an `OSError` (R-25's family owns it). Reads one file; writes nothing. |
| The telemetry half of the emitted document | `_telemetry_overlay()` | same | The ONE place the list reaches `config.json`: `$before {"clash_mode": "Global"}` on `dns.rules`, i.e. **after** the `hosts_dns` rule and **before** both mode rules — `sc`'s own DoH bootstrap keeps answering (extending the list cannot break it) while the rejection stays mode-independent (measured: placed after the `clash_mode` rules a listed name returns `NOERROR` with a record and is recorded upstream in both `global` and `direct`). Exactly three keys, `action` / `rcode` / `domain_suffix`: **`answer` is omitted** (a non-empty one emits a self-contradictory `NXDOMAIN` *with* a record and still passes `check`), and `rcode` is written explicitly and **uppercase** (omitted means `NOERROR`; lowercase is a hard `check` failure). No `rule_set` key, so `_filter_rules()` keeps it on a degraded host. Under `allow` it returns `{}`, which `_merge()` no-ops by iteration — so `generate_config()` needs no branch. |
| The IPv6 half of the emitted document | `_dns_overlay()` | same | The ONE place the decision reaches `config.json`: `$prepend` of a single `predefined` rule onto `dns.rules`. **Index 0 is the contract**, not a detail — it is the only position ahead of both `clash_mode` rules, which is what makes suppression mode-independent (measured: at HEAD the same rule sat at index 3 and types 64/65 were *not* suppressed in `direct` mode). It carries no `rule_set` key so `_filter_rules()` keeps it on a degraded host. A sibling of `_runtime_overlay()`, never an extension of it: different input, different failure mode, and `_runtime_overlay()` is frozen by T-15's differential. |
| Run-time content of the config | `_runtime_overlay(nodes, active, report)` | same | Node outbounds, the `proxy` selector, the auto-select group, the trailing `direct`, `route.rule_set` and the Clash API address, as one overlay. Reads `RULES_DIR` and `CLASH_PORT` **at call time** (a harness repoints the first, `main()` assigns the second after import); `TUN_IFACE` is in `CONFIG_BASE` instead. Every value lands on a key the base already has, which is what preserves its emitted position. **It `$replace`s the whole `outbounds` array**, so a *second* shipped overlay (T-16 / T-17) cannot add an outbound by re-stating that array — it must compose into this same `$replace` payload, because the additive route would need a directive `_merge()` does not have (R-16 is open and unclaimed). |
| "Is the auto-select group in the document, and is this selection valid?" | `_auto_group_emitted(node_tags)` / `_valid_selection(active, node_tags)` + `AUTO_TAG` / `RESERVED_TAGS` | `bin/sc` `# Config composition` (constants in `# Paths`) | `_auto_group_emitted()` is THE condition "the `urltest` group is emitted": at least one node **and** no node already tagged `AUTO_TAG` (that host would get two outbounds with one tag and fail `sing-box check`). `_valid_selection()` is THE judge of `nodes.json`'s `active`, total over `None` / a node tag / `AUTO_TAG` / a hand-edited string, and its result is always an outbound the same run defines. All three places `sc` picks on the user's behalf call it — `generate_config()`'s stale repair, `cmd_add` onto an empty list, `cmd_rm` of the active node — so none of them can form a second opinion; a selection the user made is never overridden. Pure: no file, no print. |
| Per-outbound stored delay | `stored_delays(port=None)` → `(delays, current)` | `bin/sc` `# Clash API` | THE reader of "what delay does the running sing-box report". Reads a **stored** url-test history (`GET /proxies`) — it measures nothing, and a never-probed outbound simply has no entry. Guarded by `is_running()` **inside** the function, so every caller inherits "stopped host ⇒ no request, no wait"; at most one `GET`, never a `PUT`/`PATCH`/`DELETE`; prints nothing; takes no `sc ls`-specific argument so `sc doctor` can call it unchanged. Every shape check is an `isinstance` test with no `try`/`except` — a malformed body yields *absence*, never a traceback and never a fabricated number (`bool` is excluded explicitly: it is an `int` in Python). |
| The user's own config fragment | `_load_override()` + `OVERRIDE_PATH` | same | Reads, never creates/writes/deletes. `os.stat` **before** any `open()` — `stat()` does not block on a FIFO and `open()` would. Whitespace-only / zero-byte counts as absent; every other non-object content is malformed. |
| "Was config.json changed behind our back?" | `_config_digest()` / `_record_generated()` / `_warn_drift()` | `bin/sc` `# Config generation` | `_config_digest()` hashes the file **on disk**, so the record and the check cannot form two opinions and the record is locale-independent. `_record_generated()` runs only after a successful `_write_private()`. No record ⇒ *unknown* ⇒ silence, which is what keeps the upgrade path quiet on existing hosts. Never stores a copy of the document — a digest holds no credential bytes. |
| Validated multi-mirror fetch | `_ruleset_bases()`, `_temp_path()`, `_clear_stale_temps()`, `_fetch_to_temp()` | same | Chunked read, progress on a TTY only, atomic temp-then-replace, per-run dead-base marking. |
| This project's TUN device name | `TUN_IFACE` | `bin/sc` `# Paths` | The single definition. `generate_config()`'s `interface_name`, `sc status`'s `ip addr show` and `sc doctor`'s S5 all consume it; renaming the device stays one edit. |
| The public egress address | `_egress_ip()` | `bin/sc` (next to `_resolve_clash_port`) | The single query: endpoint literal + the 8 s timeout + decode, in one place. Raises on failure; **byte-faithful on purpose** — `sc status` prints its value verbatim, so scrubbing belongs at the *caller* (`_plain()`), never inside it. `sc status` and `sc doctor` can therefore never report different addresses. |
| The persisted Clash API port | `_saved_clash_port()` | same | The single **reader** of `settings["clash_api_port"]`: reads, never probes, never writes. `_resolve_clash_port()` is the single **writer** and calls it first. `sc doctor` uses only the reader — probing would return a port free by construction and then report it unreachable. |
| Write a credential document | `_write_private(path, text)` | `bin/sc` `# State files` | THE only way `config.json` / `nodes.json` reach disk. `mkstemp(dir=path.parent)` → `fchmod(fd, CRED_MODE)` **while the object is still empty** → write/flush/fsync → `os.replace`. Each element carries a different guarantee and none is optional: the `fchmod` is what makes the mode *exactly* 0600 (umask masks `mkstemp`'s mode argument — at umask `0o277` it alone yields **0400**); the fresh `O_EXCL` name + `replace` is what makes the target's *previous* mode irrelevant and defeats a symlinked target; the ordering is what removes the write-then-`chmod` window. Never add a `chmod` after the content. `dir=` is mandatory (`EXDEV`; and `TMPDIR` would put credential bytes outside the config dir). Raises `OSError`; the caller renders it. **Not** for `settings.json` — it carries no credential and pinning its mode is a user-visible change nobody asked for. |
| Foreign text made output-safe | `_plain(text)` | `bin/sc` `# doctor` | CR + ESC removed, trailing whitespace stripped. Applied at the call sites to every tool's output and every `{e}`, which is what makes "a redirected report contains no `\r` and no ESC" a property of the code. Since T-13 it has callers outside `# doctor` (`save_nodes`, `generate_config` render `e.strerror` through it), so it is a general utility that merely *lives* in the doctor block. |
| Credential-mode sweep in the installer | `sweep_credential_modes()` + `CRED_DIR` / `CRED_FILES` / `CRED_MODE` | `install.sh`, right after `install_report()` | Called as `sweep_credential_modes \|\| true` between step 7 and `install_report`. States each credential document's mode and narrows — **never** widens — anything wider than 600. Reads/writes no `PHASE_*`, so the banner and exit status are untouched. The three variables are referenced only inside the function so a harness can repoint them; both functions anchor at column 0 so `sed -n '/^sweep_credential_modes() {/,/^}/p'` extracts them without executing the installer. The `[ -L ]` guard is first because `chmod` **follows** a symlink while GNU `stat` does **not** — without it the sweep reads the link's own 777 and chmods the link's destination. |
| Bilingual output | `t(s, **kwargs)` + `TRANSLATIONS` | `bin/sc` `# i18n` | `TRANSLATIONS` has **no `en` table** — `t()` returns the key itself in English. |
| Warning to stderr | `sys.stderr.write("⚠️  " + t(...) + "\n")` | `generate_config`, `_warn_degraded` | The `⚠️` prefix stays outside `t()`. |
| Apply a config change | `generate_config()` → `restart_service()` / `reload_or_restart()` / `clash_api()` | `bin/sc` | Node and mode switches go through the Clash API; structural changes need a restart. |
| Bilingual parity proof for `install.sh` | `check-i18n-parity.sh [FILE]` | `.harness/scripts/` | `t()` key + `printf`-specifier parity for `install.sh`; extracts the function and renders every key under `set -u`; wired as `verify_all` B.2. Exit 0 parity holds / 1 broken / 2 cannot decide — **2 is a failure for the caller, never a pass**. Does not cover `bin/sc` (no `en` table, different shape). |

## Patterns to follow

- **Config is regenerated, never patched.** Change `nodes.json` / `settings.json`, then call `generate_config()`.
- **A change to the emitted config goes in `CONFIG_BASE` or in an overlay — never back into
  `generate_config()` as a literal.** The user's `override.json` is the last overlay and goes
  through the same `_merge()`; there is exactly one merge implementation and it stays that way.
- **Every user-facing string is an English sentence used as the translation key**, with a `zh` entry
  carrying the *same* placeholder set. Namespaced keys (`ls.idx`) print literally in English — a
  pre-existing defect, not a pattern to copy.
- **Python 3.6 syntax floor, standard library only** (README states 3.6+). No walrus, no `dataclasses`,
  no `capture_output=`, no `unlink(missing_ok=)`. Known pre-existing violations: `capture_output=`
  at three sites in `bin/sc` — filed as its own pool row, do not fix opportunistically.
- **Fixed timeouts are owner-directed:** Clash API 3 s, egress IP 8 s, ruleset download 30 s. Fix
  reachability with mirrors, not with longer waits.
- **stdout carries results and per-file causes; stderr carries aggregates and warnings.**
  `install.sh` and the install log depend on this split for `sc update-rules`.
- **Non-TTY output must contain no `\r`** and must keep one completion line per item: the installer
  and the OpenRC periodic script capture it into a file.
- **In `install.sh`, never write a bare `VAR=$(pipeline)` under `set -euo pipefail`** when a handler
  below is supposed to see the failure — the assignment carries the pipeline's status and aborts the
  script *at that line*. Put it in an `if` condition, and keep **every element of the pipeline
  reading to EOF** (no `head`, no `grep -m1`, no `sed …q`), or `pipefail` will report a successful
  fetch as a failed one. See `install.sh` step 2's version query.

## Patterns to avoid

- Don't add a second notion of "the rule-set is there" (`path.exists()`, a `downloaded` flag, …).
- Don't reference a rule-set tag in `dns.rules` or `route.rules` without routing that array through
  `_filter_rules`.
- Don't split `bin/sc` into modules or add a config format for something a constant can express.
- Don't let a test harness import `bin/sc` without neutralising the auto-elevate line and setting
  `SYSTEMD = OPENRC = False` — otherwise it restarts the developer's real sing-box service.
  (Neutralise the *sudo re-exec* specifically: `cmd_uninstall` legitimately calls `os.execvp("bash", …)`,
  so a blanket "no `os.execvp`" guard refuses to load a healthy file.)
  **The recipe — use this one, do not re-invent it** (T-13; it neutralises the re-exec *without*
  mutating `bin/sc`'s source, so a refactor of the elevate block cannot defeat it, and it fails
  closed if `geteuid` moves):

  ```python
  assert os.geteuid() != 0                       # refuse to run as root, loudly
  sc = types.ModuleType("sc")
  shim = types.ModuleType("os"); shim.__dict__.update(os.__dict__)
  shim.geteuid = lambda: 0                       # the elevate branch is simply not taken
  sys.modules["os"] = shim
  try:
      exec(compile(open("bin/sc").read(), "bin/sc", "exec"), sc.__dict__)
  finally:
      sys.modules["os"] = os                     # restore IMMEDIATELY, in a finally
  ```

  Then repoint all **eight** path constants —
  `sc.CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH / RULES_DIR / OVERRIDE_PATH / STATE_PATH /
  IF_INET6_PATH` —
  into a `mkdtemp()` root, set `sc.SYSTEMD = sc.OPENRC = False`, `sc.CLASH_PORT = 29090`,
  `sc.LANG = "en"|"zh"`, and
  `sc.SB_BIN = <stub script>` (a repointable constant — no `PATH` games). **Assert that every one of
  the eight resolves inside the temp root** — that assertion, not vigilance, is what stops a
  forgotten constant writing under `/etc`; three of them (`OVERRIDE_PATH`, `STATE_PATH`,
  `IF_INET6_PATH`) were added after the recipe was first written, and `IF_INET6_PATH` is the one
  that is not under `/etc/sing-box` at all — without repointing it the host's real IPv6 state
  decides what the fixture emits. `TUN_IFACE` is *not* repointable after import (see `# Paths`).
  Because `bin/sc` resolves
  `os` from `sc.__dict__`, monkeypatching `sc.os.replace` patches the shim only, never the harness's
  own `os` — restore it in a `finally` regardless. **Never drive `_init_files()`**: one of its
  `mkdir` calls hard-codes `/var/lib/sing-box` as a `Path` literal — the only directory in the
  function not built from a repointable constant — so it writes to the real `/var/lib` even in a
  fully redirected fixture; its nodes branch is now just a `save_nodes()` call, which a fixture
  covers directly.
- Don't verify `install.sh` by running it. Extract the function under test with
  `sed -n '/^name() {/,/^}/p'`, source it into a `bash -uo pipefail -c` child alongside the
  extracted `t()`, and shadow externals (`chmod() { return 1; }`, `stat() { return 1; }`) to inject
  faults without root. Precedent: `.harness/scripts/check-i18n-parity.sh:48`, T-08, T-11, T-13.
- Don't give `sc doctor` a second opinion about anything the codebase already decides — it consumes
  `ruleset_states()` / `_status_text()` / `is_running()` / `clash_api()` / `_saved_clash_port()` /
  `_egress_ip()` / `SYSTEMD` / `OPENRC`, and it must stay that way.
- Don't add a per-subcommand "read-only" flag or a `READ_ONLY_COMMANDS` set. `main()` names the one
  read-only command positively, so a *new* command inherits today's initialising behaviour by
  default; a flag each subcommand must set inverts that failure direction.
