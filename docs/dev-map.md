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
B.1 syntax-checks `bin/sc`, `install.sh`, `uninstall.sh`; B.2/B.3 are still `SKIP`.

## `bin/sc` internal sections (in file order)

| Section | What lives there |
|---|---|
| `# Paths` | `CFG_DIR` / `CFG_PATH` / `NODES_PATH` / `SETTINGS_PATH` / `RULES_DIR`, `SB_BIN`, Clash-API port range. Only ever referenced *inside* function bodies, so a test harness can repoint them after import. |
| `# Rule-set constants` | `SRS_MAGIC`, `SRS_MIN_BYTES`, `RULESET_FILES` (filename → path relative to a base), `RULESET_BASES` (ordered mirrors), `RULE_ANSWER_KEYS`. |
| `# Auto-elevate` | `os.execvp("sudo", ...)` at **import time** when not root. A harness must neutralise this line to load the file as a module. |
| `# i18n` | `TRANSLATIONS` (English source string → `zh`) and `t()`. |
| `# State files` | `_init_files`, `load/save_nodes`, `load/save_settings`. `_init_files()` is reachable only from `main()`, so importing touches nothing under `/etc`. |
| `# Share-URL parsers` | `parse_vless / vmess / trojan / ss / hy2 / tuic` → dispatched by `parse_share_url`. |
| `# Rule-sets` | The usability model — see "Reusable utilities" below. |
| `# Config generation` | `generate_config()` builds the whole `config.json` literal, filters it by the usable rule-set set, writes 0600, then runs `sing-box check`. Also holds the two apply helpers `restart_service()` and `reload_or_restart()`. |
| `# Clash API` | `clash_api()`, `is_running()`. |
| `# Commands` | One `cmd_<name>(args)` per subcommand. |
| `HELP_EN` / `HELP_ZH` | Two hand-aligned help blocks; descriptions start at column 30, sub-options at column 32. |
| `main()` | argparse subparsers + a `handlers` dict. Assigns `LANG` and `CLASH_PORT` **after** import. |

## Reusable utilities

| Need | Existing | File | Notes |
|---|---|---|---|
| "Is this rule-set usable?" | `srs_reject_reason(head, size)` | `bin/sc` `# Rule-sets` | The single definition (SRS magic + size floor). Three adapters: `ruleset_state(path)` for a file, `_fetch_to_temp()` for bytes off a socket, `_status_text()` for the screen. Never form a second opinion. |
| One file's on-disk facts | `ruleset_state(path)` → `(status, digest)` | same | The ONE reader of a `.srs` on disk, from one chunked read. `digest` is sha256 of the full content, or `None` — and `digest is None` ⟺ status ∈ `absent / unreadable` ⟺ no complete read (a readable *empty* file gets a real digest). `ruleset_status(path)` is its status-only view; it has no in-tree caller today and is kept as the named per-file adapter. |
| Per-file rule-set state | `ruleset_report()` → `[(tag, filename, status)]`, `usable_tags(report)` | same | Pure query: no network, no service, no config, writes nothing. `status` is a flat `str`: `usable / absent / bad-magic / too-small / unreadable`. Built as `_status_view(ruleset_states())`; `ruleset_states()` is the same list with the digest appended (4-tuples). |
| "Did any rule-set's content change?" | `changed_usable_tags(before, after)` | same | Both args are `ruleset_states()` snapshots; returns the sorted tags that are usable *after* and whose bytes really differ. Paired by tag, never by list index. This — not "the download succeeded" — is what `sc update-rules` restarts on. |
| Drop dangling rule-set refs | `_filter_rules(rules, usable)` | same | Called for **both** `dns.rules` and `route.rules` with the same set. Do not add an array-name parameter. |
| Validated multi-mirror fetch | `_ruleset_bases()`, `_temp_path()`, `_clear_stale_temps()`, `_fetch_to_temp()` | same | Chunked read, progress on a TTY only, atomic temp-then-replace, per-run dead-base marking. |
| Bilingual output | `t(s, **kwargs)` + `TRANSLATIONS` | `bin/sc` `# i18n` | `TRANSLATIONS` has **no `en` table** — `t()` returns the key itself in English. |
| Warning to stderr | `sys.stderr.write("⚠️  " + t(...) + "\n")` | `generate_config`, `_warn_degraded` | The `⚠️` prefix stays outside `t()`. |
| Apply a config change | `generate_config()` → `restart_service()` / `reload_or_restart()` / `clash_api()` | `bin/sc` | Node and mode switches go through the Clash API; structural changes need a restart. |

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

## Patterns to avoid

- Don't add a second notion of "the rule-set is there" (`path.exists()`, a `downloaded` flag, …).
- Don't reference a rule-set tag in `dns.rules` or `route.rules` without routing that array through
  `_filter_rules`.
- Don't split `bin/sc` into modules or add a config format for something a constant can express.
- Don't let a test harness import `bin/sc` without neutralising the auto-elevate line and setting
  `SYSTEMD = OPENRC = False` — otherwise it restarts the developer's real sing-box service.
