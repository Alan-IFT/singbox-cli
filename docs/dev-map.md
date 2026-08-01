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
| `# Paths` | `CFG_DIR` / `CFG_PATH` / `NODES_PATH` / `SETTINGS_PATH` / `RULES_DIR`, `CRED_MODE` (THE mode of every credential document, `0o600`), `SB_BIN`, `TUN_IFACE`, Clash-API port range. Only ever referenced *inside* function bodies, so a test harness can repoint them after import. |
| `# Rule-set constants` | `SRS_MAGIC`, `SRS_MIN_BYTES`, `RULESET_FILES` (filename → path relative to a base), `RULESET_BASES` (ordered mirrors), `RULE_ANSWER_KEYS`. |
| `# Auto-elevate` | `os.execvp("sudo", ...)` at **import time** when not root. A harness must neutralise this line to load the file as a module. |
| `# i18n` | `TRANSLATIONS` (English source string → `zh`) and `t()`. |
| `# State files` | `_write_private`, `_init_files`, `load/save_nodes`, `load/save_settings`. `_init_files()` is reachable only from `main()`, so importing touches nothing under `/etc`; its nodes branch is now nothing but a `save_nodes()` call. |
| `# Share-URL parsers` | `parse_vless / vmess / trojan / ss / hy2 / tuic` → dispatched by `parse_share_url`. |
| `# Rule-sets` | The usability model — see "Reusable utilities" below. |
| `# Config generation` | `generate_config()` builds the whole `config.json` literal, filters it by the usable rule-set set, installs it through `_write_private()` (0600 from before its first byte, atomic replace — **not** a post-write `chmod`), then runs `sing-box check`. An `OSError` there is one translated stderr line + `return False`, never a traceback. Also holds the two apply helpers `restart_service()` and `reload_or_restart()`. |
| `# Clash API` | `clash_api(method, path, data=None, port=None)`, `is_running()`. `port=None` means "the port `main()` resolved"; only `sc doctor` passes one explicitly. |
| `# Commands` | One `cmd_<name>(args)` per subcommand. Includes the `# doctor` block: class constants + `_plain()` / `_doctor_run()` / `_doctor_print()`, seven probes returning rows as data, the `DOCTOR_SECTIONS` print order, and `cmd_doctor()` (driver: isolation, streaming, exit status). |
| `HELP_EN` / `HELP_ZH` | Two hand-aligned help blocks; descriptions start at column 30, sub-options at column 32. |
| `main()` | argparse subparsers + a `handlers` dict. **Parses arguments first, then initialises**: `doctor` is the one command that takes the read-only arm (`LANG = _load_lang()` only) and skips `_init_files()` / `_resolve_clash_port()`; every other command — present and future — takes the `else` arm unchanged. Assigns `LANG` and `CLASH_PORT` **after** import. |

## Reusable utilities

| Need | Existing | File | Notes |
|---|---|---|---|
| "Is this rule-set usable?" | `srs_reject_reason(head, size)` | `bin/sc` `# Rule-sets` | The single definition (SRS magic + size floor). Three adapters: `ruleset_state(path)` for a file, `_fetch_to_temp()` for bytes off a socket, `_status_text()` for the screen. Never form a second opinion. |
| One file's on-disk facts | `ruleset_state(path)` → `(status, digest, size)` | same | The ONE reader of a `.srs` on disk, from one chunked read. `digest` is sha256 of the full content and `size` is that read's real byte count (**never `st_size`**), or both `None` — and `size is None` ⟺ `digest is None` ⟺ status ∈ `absent / unreadable` ⟺ no complete read (a readable *empty* file gets a real digest and a real `0`). `sc doctor` prints the size that decided the status, so its report cannot contradict itself. `ruleset_status(path)` is its status-only view; it has no in-tree caller today and is kept as the named per-file adapter. |
| Per-file rule-set state | `ruleset_report()` → `[(tag, filename, status)]`, `usable_tags(report)` | same | Pure query: no network, no service, no config, writes nothing. `status` is a flat `str`: `usable / absent / bad-magic / too-small / unreadable`. Built as `_status_view(ruleset_states())`; `ruleset_states()` is the same list with the digest **and size** appended (5-tuples). `_status_view()` is the shield: it is where a widening of the snapshot tuple stops, which is why `generate_config()` / `usable_tags()` / `_warn_degraded()` destructure 3-tuples and need no edit when it widens. |
| "Did any rule-set's content change?" | `changed_usable_tags(before, after)` | same | Both args are `ruleset_states()` snapshots; returns the sorted tags that are usable *after* and whose bytes really differ. Paired by tag, never by list index. This — not "the download succeeded" — is what `sc update-rules` restarts on. |
| Drop dangling rule-set refs | `_filter_rules(rules, usable)` | same | Called for **both** `dns.rules` and `route.rules` with the same set. Do not add an array-name parameter. |
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

  Then repoint `sc.CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH / RULES_DIR` into a `mkdtemp()`
  root, set `sc.SYSTEMD = sc.OPENRC = False`, `sc.CLASH_PORT = 29090`, `sc.LANG = "en"|"zh"`, and
  `sc.SB_BIN = <stub script>` (a repointable constant — no `PATH` games). Because `bin/sc` resolves
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
