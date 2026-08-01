# 05 — Code Review — `sc doctor` (T-05)

> **Transcription note (PM).** The `code-reviewer` agent is provisioned read-only (Read / Glob / Grep)
> by design, so it returned this document as text and the PM wrote it to disk **verbatim**. Content is
> the reviewer's; the PM authored none of it.

Mode: **full** · Stage 5 · Decision mode: **deferred-human (defer, do not ask)**.
Reviewed against the working tree as it stands: `bin/sc` (1946 lines, `grep -c '^'`), `README.md`,
`README.zh-CN.md`, `CHANGELOG.md`, `docs/dev-map.md`; upstream `01_` (READY), `02_` (READY FOR GATE),
`03_` (APPROVED WITH CONDITIONS C-1..C-8), `04_` (READY FOR REVIEW); `.harness/rules/85-design-discipline.md`,
`.harness/rules/50-singbox-cli.md`, `.harness/insight-index.md`. Every `file:line` below was opened and
read. I have Read/Glob/Grep only — **no shell, no `git`, no execution**. §8 states exactly what that
leaves unverified; nothing in §1–§7 is asserted from the developer's record on trust.

---

## 1. Files reviewed

- `/home/alan/Programs/singbox-cli/bin/sc` — read in full
- `/home/alan/Programs/singbox-cli/README.md` (`:94-132`), `/home/alan/Programs/singbox-cli/README.zh-CN.md` (`:94-132`)
- `/home/alan/Programs/singbox-cli/CHANGELOG.md` (`:7`)
- `/home/alan/Programs/singbox-cli/docs/dev-map.md` (`:30`, `:38-41`, `:48-56`, `:89-98`)
- Tests: **none in the repository.** `Glob **/t_*.py` and `**/scratchpad/**` return nothing — the seven
  harnesses of `04_` §7 live in the developer's private scratchpad and are not reviewable artefacts
  (§8, F-4).

---

## 2. Findings

Severity: **BLOCKER** (must fix before merge) · **MAJOR** (should fix before merge) · **MINOR** ·
**INFO**. Owning agent named per finding; routing is the PM's.

### BLOCKER
None.

### MAJOR
None.

### MINOR

- **M-1 [SPEC/EVIDENCE] `04_DEVELOPMENT.md` §5 C-4 — the restated AC-16 method, as recorded, is
  internally inconsistent.** It states `SYSTEMD = OPENRC = False` *and* that "the egress block" and
  "the egress line" are inside the compared capture, with four comparisons over
  egress-succeeds/egress-raises. With both flags false, `is_running()` (`bin/sc:1058-1064`) returns
  `False`, so the gate at `bin/sc:1199` is never taken and **nothing from `:1200` to `:1212` — including
  the egress block E-13 edits — can appear in the capture**. The record must therefore be omitting a
  stub (almost certainly `is_running`), or the one region the diff actually touches inside that gate
  was never compared. The code itself is correct (see §3 AC-16: I proved byte-equality structurally
  and independently), so this is an evidence-record defect, not a behaviour defect. *Owner: developer
  (record) → QA to re-run and state the neutralisation explicitly in `06_TEST_REPORT.md`.*

- **M-2 [MAINT] `bin/sc:1343-1352` — a checker that fails with no output prints a dangling header.**
  When `code != 0` and the merged output is empty or blank-only, `lines` is `[]`, so the report shows
  `[PROBLEM] sing-box check: the checker reported an error:` with nothing quoted beneath it. The class
  and the exit status stay correct, so it cannot mislead a reader about health; it is a rendering wart
  in a rare path. *Owner: developer (optional; does not block).*

- **M-3 [SPEC/RECORD] `04_DEVELOPMENT.md` §3/§4/§9 — three arithmetic slips in the delivery record.**
  (a) `bin/sc | +484/−43 lines, 1536 → 1946` does not close: 1536 − 43 + 484 = 1977 ≠ 1946 (the file
  measures 1946 lines by `grep -c '^'`). (b) §4 E-15 claims the help blocks gained "+3 lines each";
  they gained **5 each** (`bin/sc:1792-1796`, `:1849-1853`) — the property that matters (equal count,
  same relative position after `status`) does hold. (c) §4 E-2 claims "42 zh entries"; I count **41**
  at `bin/sc:172-215` (40 from `02_` §10 plus the drift key). None of these changes any behaviour, but
  the "Files changed" line is the artefact QA and the PM verify scope against, so it must be arithmetically
  true. *Owner: developer (record) / PM to confirm the real `git diff --stat` at delivery.*

### INFO

- **I-1 [LOGIC] `bin/sc:1234-1242` — `_plain()` removes CR and ESC but not LF.** A foreign multi-line
  exception text interpolated into `{e}` (S1/S3/S5 and the driver backstop at `:1493`) would split one
  logical row across physical lines, softening FR-20's one-fact-per-line contract. No observed path
  produces one — `OSError`/`URLError` messages are single-line — and this is exactly the `_plain()`
  the design specified (`02_` §3.6). Stated so nobody later "discovers" it as a bug. *Ruled here.*

- **I-2 [SECURITY / NFR-6] `bin/sc:1343-1351` — S3 quotes the external checker verbatim into an
  artefact designed to be pasted into an issue.** `config.json` holds node UUIDs and passwords. sing-box's
  `check` errors are structural (field paths, file paths — see the AC-4 sample in `02_` §6.2) and do not
  echo values, so the channel is theoretical; but it is the **only** route by which config content can
  reach `sc doctor`'s stdout, and it is unbounded in content (bounded only in line count). Not a defect:
  quoting the checker is what makes AC-4 work. QA should eyeball one real failing-config message before
  the owner is told the report is safe to paste. *Owner: QA (observation, not a change).*

- **I-3 [LOGIC] `bin/sc:250-255` — a non-dict `settings.json` (a JSON list or scalar) makes
  `_saved_clash_port()` raise `AttributeError`**, which surfaces as S6's driver-backstop UNKNOWN row
  rather than a named cause. The report stays complete and the exit status stays correct (FR-9 holds).
  The same shape is pre-existing in the non-doctor path (`bin/sc:273-277`, unchanged in substance from
  HEAD). *Ruled here — not this task's to fix.*

- **I-4 [LOGIC] `bin/sc:1477/:1479` — `sc doctor | head -3` raises `BrokenPipeError` outside the
  per-probe `try`.** Project-wide and pre-existing for every `print`-based subcommand; the documented
  consumers (`> out.txt`, `| grep`) read to EOF and are unaffected. Same neighbourhood as gate F-13.
  *Ruled here.*

- **I-5 [SPEC] `bin/sc:1346` — BC-7's dropped-line count counts non-blank lines**, because blank lines
  are filtered before the 5-line window. The developer flagged this in `04_` §9. BC-7's binding
  clauses ("the first line is always printed", "at most five", "a marker stating how many were dropped")
  all hold; the count is simply over the lines actually eligible for quotation. Reading accepted.
  *Ruled here.*

- **I-6 [SPEC] `bin/sc:1377-1379` — a Chinese-locale `systemctl is-enabled` could put `失败` into S4's
  `{state}`.** Foreign text, outside this task's control; and the load-bearing grep of
  `insight-index.md:16` is applied to captured **`sc update-rules`** output, never to `doctor`'s. No
  string `bin/sc` introduces contains the literal (verified: the only `失败` occurrences are
  `bin/sc:94,102,104,105,115,132,145` — all pre-existing — plus the English code comment at `:171`
  that documents the prohibition). *Ruled here.*

- **I-7 [STANDARDS] `.harness` doc-size WARN persists.** `02_SOLUTION_DESIGN.md` is 858 lines against
  rule 70's 500-line cap, so `verify_all` F.6 stays WARN through this stage. PM-ruled at the gate
  (C-8); this review is kept short so it cannot add a second. *Owner: PM.*

### NIT

- **N-1** `bin/sc:1271` — S1's `path` (from `shutil.which`, i.e. from `PATH`) is the one printed value
  not routed through `_plain()`. A `PATH` entry containing an ESC byte is pathological; under sudo's
  `env_reset` it is `secure_path`. Not worth a change.
- **N-2** `bin/sc:255` — `isinstance(port, int)` accepts `True` (`"clash_api_port": true` would render
  as `127.0.0.1:1`). Pre-existing predicate shape, carried over verbatim from HEAD's `_resolve_clash_port()`.
- **N-3** `bin/sc:1392` — `_plain()` is applied to an already-translated string in the OpenRC arm
  (`state` is `t("not in the default runlevel")`). Harmless; uniform call-site discipline is the reason.

---

## 3. Requirement coverage check

"✅ insp." = verified by me from the source; "✅ exec." = requires execution I do not have (§8).

| AC | Implementation | Status |
|---|---|---|
| AC-1 registered + dispatched | `bin/sc:1904` (`sub.add_parser("doctor")`), `:1934` (`"doctor": cmd_doctor`) | ✅ insp. |
| AC-2 both help blocks + both READMEs | `bin/sc:1792-1796` / `:1849-1853`; `README.md:100,104-132` / `README.zh-CN.md:100,104-132` — same insertion points, same structure | ✅ insp. |
| AC-3 section order S1..S7 | `bin/sc:1458-1466` — the tuple **is** FR-6's table, and `cmd_doctor` (`:1485`) is its only reader | ✅ insp. |
| AC-4 failure chain reads off the screen | order (above) + S2 rows `:1296-1312` above S3's quoted checker message `:1343-1351` above S4 `:1372-1392` | ✅ insp. (rendered run: dev-executed) |
| AC-5 read-only, files | §4's enumeration: the only opens on the graph are `bin/sc:633` (`"rb"`) and `:1322` (`"rb"`); every `mkdir`/`write_text`/`chmod`/`unlink`/`replace` site (`:305-312`, `:321-330`, `:852`, `:877`, `:1014-1015`, `:1560-1600`, `:1667-1717`) is unreachable | ✅ insp. / ✅ exec. (live tree = QA) |
| AC-6 read-only, service | every subprocess is a query (`:1273` `version`, `:1335` `check -c`, `:1377` `is-enabled`, `:1381` `rc-update show`, `:1403` `ip … show`, `is_running()` `:1060`/`:1062`) | ✅ insp. / ✅ exec. |
| AC-7 enumeration in the review | §4 below | ✅ insp. |
| AC-8/9/10 no probe kills the report | `cmd_doctor` `:1486-1493` (`except Exception`, fallback row with `label=None` → section label at `:1497`); all seven section labels are the first row of each probe's list | ✅ insp. / ✅ exec. |
| AC-11 three classes, fixed markers | `:1226-1230`, rendered at `:1479` as `[<mark>] <label>: <value>` | ✅ insp. |
| AC-12 streaming | `print(..., flush=True)` at `:1477` and `:1479`; only the integer `worst` is accumulated | ✅ insp. / ✅ exec. |
| AC-13 rule-set reuse (gate reading C-6) | S2 calls `ruleset_states()` `:1292`; `ruleset_report()` is *defined* as `_status_view(ruleset_states())` `:695`, so deleting either breaks S2 and config generation together | ✅ insp. |
| AC-14 no `st_size` | grep over `bin/sc`: `st_size`/`getsize`/`.stat(` occur **only** in the docstring at `:620`. Size is `ruleset_state()`'s own counter `:639`, returned at `:646`, consumed at `:1296`/`:1308` | ✅ insp. |
| AC-15 single definitions | `sb-tun` only at `:29`; `api.ipify.org` only at `:293`; `clash_api_port` read only at `:254`, written only at `:277` | ✅ insp. |
| AC-16 `sc status` unchanged | See the structural proof below | ✅ insp.; evidence record → M-1 |
| AC-17 non-TTY purity | `_plain()` at 11 call sites (`:1254`, `:1276`, `:1329`, `:1338`, `:1386`, `:1392`, `:1406`, `:1451`, `:1453`, `:1493`, plus `_doctor_run`'s own return); no `\r`/`\x1b` literal anywhere in the doctor block; no TTY branch exists | ✅ insp. / ✅ exec. |
| AC-18 bilingual coverage | 41 keys at `:172-215`; I checked every zh value's placeholder set against its key — `{code}`, `{n}`+`{total}`, `{reason}`+`{size}`, `{path}`, `{path}`+`{e}`, `{n}`, `{init}`, `{state}`, `{e}`, `{iface}` — all equal, so `t()`'s `.format()` (`:299`) cannot `KeyError` | ✅ insp. / ✅ exec. |
| AC-19 no namespaced keys | all 41 are English prose; the only `ls.*` tokens are the pre-existing `:155-159` | ✅ insp. |
| AC-20 no grep-literal collision | no new zh value contains `失败` (see I-6) | ✅ insp. / ✅ exec. |
| AC-21 exit status | `:1226-1230`, `worst = max(...)` `:1499`, `sys.exit(DOCTOR_EXIT[worst])` `:1500`; documented at `:1794-1796`, `:1851-1853`, `README.md:128-132`, `README.zh-CN.md:128-132` | ✅ insp. |
| AC-22 no traceback | `except Exception` `:1488` (not bare, not `BaseException`); residual F-13 unchanged | ✅ insp. / ✅ exec. |
| AC-23 Python 3.6 floor | grep: `capture_output=` at exactly **three** sites — `:1018`, `:1063`, `:1675`, all pre-existing; `text=True` only paired with them; no walrus, no `missing_ok=`, no `dataclasses`, no f-string `=`. `_doctor_run` `:1253` uses `stdout=PIPE, stderr=STDOUT` + `.decode("utf-8","replace")` | ✅ insp. (`py_compile` → §8) |
| AC-24 ≤25 lines / ≤80 cols | healthy = 2+5+2+2+2+2+1 = **16** rows from the probe returns; no padding is computed anywhere (`_doctor_print` `:1476-1479`) | ✅ insp. |
| AC-25 `verify_all` delta | — | ❌ cannot execute (§8) |
| AC-26 scope | the five permitted files carry the change; `install.sh`/`uninstall.sh`/`systemd/` byte-identity | ✅ insp. (five files) / ❌ byte-identity needs `git` (§8) |

**AC-16, the structural proof I owe you.** `cmd_status` now spans `bin/sc:1191-1212` = 22 lines. At HEAD
it spanned `:1092-1114` = 23 lines (architect and gate reviewer both read it there). The design's two
prescribed edits are E-12 (substitute a constant of identical value) and E-13 (collapse
`with urlopen(...) as resp: print(resp.read().decode())` into `print(_egress_ip())`, removing exactly one
physical line). 23 − 1 = 22. Every other statement is present in the same order: header `:1192`,
`SYSTEMD`/`OPENRC` branch `:1193-1196`, TUN header `:1197`, `ip` `:1198`, the `is_running()` gate `:1199`,
node `:1200-1202`, `clash_api("GET","/configs")` `:1203`, mode `:1204-1205`, port `:1206-1207`, egress
header `:1208`, `try` `:1209-1212`. `TUN_IFACE == "sb-tun"` (`:29`) is the literal it replaced;
`_egress_ip()` (`:285-294`) is the two lifted statements with **no `_plain()` inside it** (C-5 honoured,
and `docs/dev-map.md:54` records why). The same two calls raise the same exception types into the same
`except Exception as e: print(t("(error: {e})", e=e))` at `:1211-1212`, and the zh rendering `（错误：{e}）`
(`:110`) is untouched. `sc status` is byte-identical in both languages by construction.

---

## 4. AC-7 — the read-only enumeration, re-derived from the code

Reachable from `cmd_doctor` (`:1482`) through `DOCTOR_SECTIONS` (`:1458-1466`) and nothing else:

| Kind | Operation | Site | Read-only because |
|---|---|---|---|
| subprocess | `sing-box version` | `:1273` | prints a version |
| subprocess | `sing-box check -c /etc/sing-box/config.json` | `:1335` | validates; RISK-1 measured (§8) |
| subprocess | `systemctl is-active --quiet` / `rc-service status` | `:1060` / `:1062` via `:1371` | queries |
| subprocess | `systemctl is-enabled sing-box` | `:1377` | a query |
| subprocess | `rc-update show default` | `:1381` | `show` takes no runlevel-modifying argument |
| subprocess | `ip -br addr show sb-tun` | `:1403` | `show` |
| file | `path.open("rb")` per `.srs` | `:633` via `:675`/`:1292` | read mode; `:628-632` use `exists()`/`is_file()`, **no `mkdir`** |
| file | `CFG_PATH.open("rb")` then close | `:1322` | read mode |
| file | `SETTINGS_PATH.read_text()` | `:326` via `:251` (`_saved_clash_port`) and `:225` (`_load_lang`) | read |
| network | `clash_api("GET","/configs", port=…)` | `:1434` → `:1041-1055` | loopback GET, 3 s, unchanged |
| network | `_egress_ip()` | `:1451` → `:293` | HTTPS GET to the one existing endpoint, 8 s, unchanged |

**Unreachable, verified by exhaustive call-site grep, not by the developer's AST walk:**
`_init_files()` — defined `:304`, called once at `:1929` (the `else` arm only);
`_resolve_clash_port()` — defined `:258`, called once at `:1931` (`else` arm only);
`_free_port()` — defined `:230`, called once at `:269` inside `_resolve_clash_port()`, therefore two
edges away from a path that has no first edge;
`save_settings()` — `:279`, `:1175`, `:1187`, `:1509`, `:1531`, `:1682`, `:1721`, `:1759` (all `cmd_*` or
the resolver); `save_nodes()` — `:926`, `:1125`, `:1148`, `:1162`; `generate_config()` — `:1033`, `:1622`;
`restart_service()` — `:1035`, `:1629`; `reload_or_restart()` — `:1131`, `:1149`, `:1163`, `:1747`;
`_fetch_to_temp()`/`_temp_path()`/`_clear_stale_temps()`/`RULES_DIR.mkdir()` — inside `cmd_update_rules`
only (`:1560-1600`). **No writer is on the graph.** `CLASH_PORT` is read at `:1002` (unreachable),
`:1045` (short-circuited by the explicit `port=` from `:1434`, which `_saved_clash_port()` guarantees is
a truthy int) and `:1207` (unreachable) — **C-3 holds**.

**C-1 verified at source.** `bin/sc:1916` `args = parser.parse_args()`; `:1926-1931` the branch. The
`else` arm's three statements (`:1929-1931`) are textually HEAD's `_init_files()` / `LANG = _load_lang()`
/ `CLASH_PORT = _resolve_clash_port()`, in that order, one indent level deeper; `global LANG, CLASH_PORT`
stays the first line of `main()` (`:1896`). `parse_args()` was **not** moved up. Nothing in the parser
construction (`:1897-1914`) calls `t()` or reads `LANG`/`CLASH_PORT`, so parsing earlier changes no
output: `sc` and `sc help` give `args.cmd is None` → `else` arm → identical behaviour; `sc --help`
(unrecognised under `add_help=False`), an unknown subcommand and a subcommand missing its argument all
still print the same English argparse message and exit 2 — the sole difference being that they no
longer create `/etc/sing-box`, which is `02_` §3.3's stated, strictly-more-conservative consequence.
`sc doctor --help` still prints the subparser help and exits 0, before any init.

**C-2 verified at source.** `bin/sc:273-281`: the first-run branch re-loads with
`except (FileNotFoundError, json.JSONDecodeError, OSError): settings = {}` — the same guard shape as
HEAD's `:199-202` — assigns `settings["clash_api_port"] = port` into the loaded dict, and keeps
`except OSError: pass` around `save_settings`. **No `save_settings()` call anywhere in the file takes a
fresh single-key dict** (all eight sites listed above load-then-mutate). `lang`, `mode`, `default_tun`
and `update_interval` therefore cannot be erased by a port resolution.

**T-10 non-regression (D-2), verified at source — the check I weighted second only to §4.**
`ruleset_state()` returns `(status, digest, size)` at **every** exit: `:630` (both ternary arms),
`:632`, `:645` all `(status, None, None)`; only `:646` carries a real digest and a real size. The
contract `size is None ⇔ digest is None ⇔ no complete read ⇔ status ∈ {absent, unreadable}` holds with
no gap, and the partial `size` accumulated at `:639` is discarded on `OSError` exactly as the partial
digest is. `ruleset_states()` unpacks three at `:675` and appends 5-tuples at `:676`. `_status_view()`
`:686` unpacks five, emits the same 3-tuples — its output shape is unchanged, which is why
`generate_config()` (`:995`), `usable_tags()` (`:731`, called at `:920` and `:1609`), `_warn_degraded()`
(`:784`, called at `:1012`) and `ruleset_status()` (`:660`, `[0]`) needed no edit and got none.
`changed_usable_tags()` pairs **by tag through dicts** — `old = dict((tag, digest) for tag, _fname,
_status, digest, _size in before)` `:713`, `old.get(tag)` `:718` — never by index; the `None` reasoning
at `:718-725` is unmoved. "Exactly one apply per run" is still structural: single
`if changed and CFG_PATH.exists():` `:1616`, single `restart_service()` `:1629`, single run-level
outcome `:1633-1640`. Every consumer's unpacking width matches its producer's tuple width at every one
of the eight call sites. **I find no path by which the widening perturbs the weekly restart decision.**

---

## 5. Design fidelity check

| Design item | Implementation | Status |
|---|---|---|
| E-1 `TUN_IFACE` in `# Paths` | `bin/sc:25-29` with its three consumers named | ✅ |
| E-2 zh entries under a `# doctor` comment | `:170-215`, 41 entries, existing insertion style | ✅ (count → M-3c) |
| E-3 `_saved_clash_port()` split out | `:242-255`; `_resolve_clash_port()` calls it `:266` | ✅ + C-2 |
| E-4 `_egress_ip()` | `:285-294`, byte-faithful, no `_plain` | ✅ |
| E-5 `ruleset_state()` → 3-tuple + contract clause | `:598-646`, contract at `:606-618` | ✅ |
| E-6/E-7 `ruleset_states()` 5-tuples, `_status_view()` absorbs | `:663-677`, `:680-686` | ✅ |
| E-8 `changed_usable_tags()` unpackings only | `:713`, `:715` — no logic line moved | ✅ |
| E-9 `_status_text()` gains `"usable"` | `:742-748`; existing callers (`:787`, `:900`) only pass non-usable statuses | ✅ |
| E-10/E-12/E-13 `TUN_IFACE` ×2, `print(_egress_ip())` | `:969`, `:1198`, `:1210` | ✅ |
| E-11 `clash_api(..., port=None)`, `port or CLASH_PORT` | `:1041-1045`; three existing call sites (`:1127`, `:1203`, `:1511`) unchanged; `timeout=3` at `:1051` untouched | ✅ |
| E-14 the doctor block | `:1215-1500`: constants `:1226-1231`, `_plain` `:1234`, `_doctor_run` `:1245`, `_first_line` `:1257`, seven probes `:1265-1453`, `DOCTOR_SECTIONS` `:1458`, `_doctor_print` `:1469`, `cmd_doctor` `:1482` | ✅ (+ drift b) |
| E-15 help blocks | `:1792-1796` / `:1849-1853`; 5 lines each, after `status`, descriptions at col 30, sub-lines at col 32 | ✅ (record → M-3b) |
| E-16/E-18 subparser + handler | `:1904`, `:1934` | ✅ |
| E-17 (as C-1 restated it) | `:1916` + `:1926-1931` | ✅ |
| D-1 exit map | `:1230` `{OK:0, UNKNOWN:2, PROBLEM:1}`, `max()` accumulator `:1499` | ✅ |
| D-6 row shape, no padding, no TTY gate | `:1476-1479`; quoted lines are the only unmarked rows (`:1348`) | ✅ |
| D-7 isolation + per-row flush | `:1486-1497` | ✅ |
| D-9 order pinned in one place | `:1458-1466`, read only by `:1485` | ✅ |
| §6 S6 `is not None` (R-8) | `:1436` | ✅ |
| §6 S4 init-check first (R-9) | `:1366-1369`, before `is_running()` at `:1371` | ✅ |
| §6 S5 operstate not printed | `:1416` slices `fields[2:]` | ✅ |
| `docs/dev-map.md` (FR-31) | `:30`, `:38-41`, `:48-56`, `:93-98` — all six promised updates present, incl. the two "patterns to avoid" | ✅ |
| `CHANGELOG.md` (FR-30) | `:7`, zh, under `[Unreleased] → 新增` | ✅ |

**No silent design drift found beyond the three the developer declared.**

---

## 6. Rulings on the three declared drifts (PM routed these to me)

**(a) The added key `not in the default runlevel` / `不在 default 运行级别` (`bin/sc:207`, used at
`:1383`) — PROPORTIONATE. Keep. Do not roll back to the architect.**
`02_` §6's S4 row mandates the value `not enabled ({state})` for **both** init systems but supplies a
`{state}` source for systemd only (`is-enabled`'s word). OpenRC's condition — "the service name does
not appear in `rc-update show default`" — has no state word to quote. The three available resolutions
were: interpolate an untranslated English phrase (breaks BC-18/FR-23), interpolate a token (breaks
FR-23's prose rule and AC-19), or add one bilingual, placeholder-free key. The developer took the
smallest one. It introduces no new judgment, no new status vocabulary (FR-11 untouched), carries a zh
entry with an identical (empty) placeholder set, contains no `失败`, and leaves the row shape and the
outcome class exactly as designed. This is filling a hole in the design's value table, not
re-architecting S4. *Owner: developer's call, ratified here.*

**(b) `_first_line(text)` (`bin/sc:1257-1262`), used at `:1278` (S1) and `:1378` (S4) — PROPORTIONATE.
Keep. Do not roll back to the architect.**
Rule 85's counter-rule forbids abstraction for requirements nobody stated; it does not forbid a
four-line helper with **two real call sites today**. The deletion test passes in the form rule 85
prescribes: delete it and the same three-line "first non-blank line" loop is written twice, in two
probes, where a later divergence between them would silently change what S1 and S4 report. It is not
speculative generality — both callers exist in this diff, and both were mandated by `02_` §6 ("first
non-empty output line" for S1; "the tool's first output line" for S4). It forms no judgment, takes no
parameters and has no modes, so gate F-14's constraint on `_doctor_print()` is not weakened by
analogy. This is the *right* fix, not over-build.

**(c) `02_`'s header saying `bin/sc` is 1537 lines at HEAD when the developer measured 1536 — NOT a
drift. No action; nothing to roll back.**
Almost certainly a counting-method artefact, not a wrong anchor: on the current file `grep -c '^'`
returns **1946** while a line-numbered read displays a phantom 1947th (empty) line — the classic
`wc -l` vs. displayed-line-count difference on a newline-terminated file. Two independent readers (the
architect and the gate reviewer, `03_` §preamble) recorded 1537 at HEAD; the developer's 1536 is the
same file counted the other way. No anchor in `02_` §4 is off by one as a *reference* — every anchor is
also named by its function, and all eighteen resolved correctly (§5). Filing this as a design drift
over-weighted it; the arithmetic that genuinely does not close is the developer's own diffstat (M-3a).

---

## 7. Rule-85, both directions (item 12 / AC-26 scope)

*No second opinion.* Rule-set usability → `srs_reject_reason()`/`ruleset_state()` (`doctor` contains no
magic test, no size floor, no `exists()` of its own); status wording → `_status_text()` `:1303`;
running → `is_running()` `:1371`; init detection → `SYSTEMD`/`OPENRC` `:1366`, `:1370` (no second
`shutil.which("systemctl")`); persisted port → `_saved_clash_port()` `:1429`; Clash call →
`clash_api()` `:1434`; egress → `_egress_ip()` `:1451`; TUN name → `TUN_IFACE`; config validity → the
same external checker `generate_config()` calls. The one deliberate *non*-reuse — S4 asking the init
system instead of `settings["default_tun"]` (`:1174`, `:1186`, `:1530`) — is C-8's requirement, is
argued at `bin/sc:1361-1364` and `04_` §5, and is recorded in `docs/dev-map.md:93-95` so a later editor
cannot "fix" it toward the settings key. That is asking the authority, not forming a second opinion,
and I agree with it: a disagreement between intent and authority is precisely what a diagnostic exists
to expose.

*Not over-built.* Beyond `02_` §5.1 the diff adds exactly two things: `_first_line()` (ruled above) and
`DOCTOR_MSG_LINES = 5` (`:1231`), a named constant for a number BC-7 fixes. No new file, module, flag,
`--json`, `--quiet`, per-section selection, remediation advice or config format. `_doctor_print()` still
has one caller and still has neither a parameter nor a mode (gate F-14 respected). Scope: the change is
confined to the five permitted product files as far as Read/Glob can see; `docs/tasks.md` and
`.harness/rejected-decisions.md` are dirty from earlier stages and are declared in `04_` §3 for `07_`.

---

## 8. What I could NOT verify (no execution available — Read/Glob/Grep only)

1. **`git diff` of any kind.** I cannot confirm `install.sh`, `uninstall.sh` and `systemd/` are
   byte-identical to HEAD (AC-26's second clause), nor the `+484/−43` diffstat, nor that `bin/sc`
   contains no incidental edit outside the eighteen I traced. My FR-19/AC-16 proof is structural
   (§3) plus the architect's and the gate reviewer's independent readings of HEAD's `cmd_status`.
2. **`verify_all`** — PASS 16 / WARN 1 / FAIL 0 / SKIP 1 and the zero delta are unverified by me,
   including B.1 (`python3 -m py_compile bin/sc`) and the F.6 WARN's attribution to `02_`.
3. **The 131 harness checks.** `Glob **/t_*.py` and `**/scratchpad/**` return nothing: the seven
   harnesses are not in the repository, so `t_unit / t_doctor / t_status / t_regress / t_updrules /
   t_risk1 / t_s4` and every number in `04_` §7 are outside my reach — including T-9, the executed
   guard for the T-10 restart decision (which I did verify structurally, §4).
4. **The live-service witness** (`MainPID=2500438`, `ActiveEnterTimestamp=Fri 2026-07-31 17:04:23 CST`)
   and the RISK-1/C-7 measurement on sing-box 1.13.15. I did not run any binary and did not touch the
   service. I record that the developer's RISK-1 method — a shape-equivalent config copy with the cache
   path redirected into a temp dir, rather than the installed root-only config — is a *safer* variant of
   `02_` §14 T-1 that still answers T-1's question in both arms; C-7's "cannot measure" trigger is
   therefore not fired. AC-5's live half and AC-6 on the installed command remain QA's.
5. **Anything rendered:** the actual screen output, column widths, the 0.94 s NFR-2 data point, the
   zh run, the `0x0D`/`0x1B` byte counts, and the AC-8 seven forced-failure runs.

I assert none of these as observed.

---

## 9. Axis status

- **Standards-conformance:** 4 findings, worst = **MINOR** (M-2). Bilingual coverage, placeholder
  parity, the `失败` prohibition, the 3.6 floor (three `capture_output=` sites, no fourth — and the
  `_doctor_run` docstring reword at `:1248-1249` is what keeps that grep-count gate reading 3), the
  help-block column convention, the README mirror, the CHANGELOG convention, `docs/dev-map.md`'s
  inventory duty and rule 85 in both directions all hold. No invented rules were applied; every
  preference-only remark is filed as NIT.
- **Spec/design-fidelity:** 3 findings, worst = **MINOR** (M-1). All 26 ACs are addressed; 24 verified
  by inspection here, 2 (AC-25, AC-26's byte-identity clause) unverifiable without execution. All
  eighteen design edits landed; the three declared drifts are ruled proportionate or non-existent;
  no undeclared drift found.

Aggregate = the more severe of the two = **MINOR**. Neither axis carries a BLOCKER or a MAJOR.

---

## 10. Verdict

**APPROVED WITH FOLLOW-UPS:**
1. **M-1 (developer record → QA)** — `06_TEST_REPORT.md` must state the neutralisation that makes the
   egress region reachable with `SYSTEMD = OPENRC = False`, or re-run AC-16 with it stated; as written
   the method's premises contradict its assertions.
2. **M-3 (developer record → PM)** — correct the diffstat, the help-line count and the key count in
   `04_` §3/§4, and confirm the real `git diff --stat` at delivery (AC-26 is verified against that line).
3. **M-2 (developer, optional)** — a non-zero checker with empty output prints a header with nothing
   beneath it (`bin/sc:1343-1352`).
4. **QA** — owns AC-5's live tree, AC-6 on the installed command, AC-25's `verify_all`, T-1 against the
   real installed config as root, T-4's blackholed-network ceiling, and I-2's one-time eyeball of a real
   `sing-box check` failure message before the report is called safe to paste.
5. **PM** — `02_`'s 858 lines keep `verify_all` F.6 at WARN through delivery (gate C-8; predicted).

---

**APPROVED WITH FOLLOW-UPS:** M-1 (AC-16 evidence record incomplete — QA to restate), M-3 (`04_` diffstat/help-line/key-count arithmetic), M-2 (empty checker output prints a dangling header), QA to own AC-5 live / AC-6 installed / AC-25 / T-1-real / T-4 / I-2, PM to carry the predicted F.6 doc-size WARN.

---

## 11. Delta re-review — stage 4b fix-up (addendum)

> **Transcription note (PM).** After this review, the PM ruled M-2 be fixed (overriding "optional") and
> routed a bounded fix-up back to the developer **before** QA, so QA would test final code. The
> code-reviewer then performed a bounded delta re-review of that fix-up only. Its text follows
> verbatim; the PM authored none of it.

Scope: `bin/sc` only (plus `04_DEVELOPMENT.md` as record). Read/Glob/Grep only — no `git`, no execution.

**Shift analysis (the method underneath every claim below).** Every anchor I verified in the prior
review re-resolves at exactly one of two offsets: **+2** for everything before `_doctor_config`'s new
branch (`ruleset_state` 598→600, `ruleset_states` 663→665, `cmd_status` 1191→1193, `DOCTOR_EXIT`
1230→1232, `_plain` 1234→1236, `_doctor_run` 1245→1247, `_first_line` 1257→1259, the three
`capture_output=` sites 1018/1063/1673→1020/1065/1685) and **+10** for everything after
(`DOCTOR_SECTIONS` config row 1461→1471, `_doctor_print` 1469→1479, its body 1476-1479→1486-1489,
`cmd_doctor` 1482→1492, `sys.exit` 1500→1510, help blocks 1792/1849→1802/1859, `add_parser`
1904→1914, handler 1934→1944, EOF 1946→1956). A uniform two-step shift with no intermediate offsets
is strong structural evidence that the **only** insertions are the 2 zh lines and the 8-line branch.
No third edit site exists.

1. **Minimal and confined — yes.** The whole change is `bin/sc:1347-1355`: `lines` hoisted above the
   first `rows.append`, then `if not lines:` → one row → `return rows`. **Non-empty path genuinely
   unchanged**: `lines = [line for line in out.splitlines() if line.strip()]` is pure (no side effect,
   no mutation of `rows`/`out`), so hoisting it above `rows.append` cannot alter the emitted sequence;
   the header row (`:1356`), the `lines[:DOCTOR_MSG_LINES]` window (`:1357-1358`) and the
   `... {n} more line(s) not shown` marker (`:1359-1361`) are textually the same statements in the same
   order. Confirmed structurally; I cannot diff against the pre-fix tree (no `git`).
2. **Class and exit — hold.** `bin/sc:1352` appends `DOCTOR_PROBLEM`; `DOCTOR_EXIT = {OK:0, UNKNOWN:2,
   PROBLEM:1}` (`:1232`) and `worst = max(...)` → `sys.exit(...)` (`:1509-1510`) are untouched. Exit 1.
3. **Row is honest.** `the checker reported an error, no message (exit {code})` — still asserts failure,
   carries the exit code (the only fact the path has), promises nothing it does not deliver, and does
   not end in a colon. Strictly *less* exposed than the quoting path (I-2 unaffected: it quotes nothing).
4. **Key hygiene — clean.** `bin/sc:200-201`: zh entry present, placeholder set exactly `{code}` on both
   sides (so `t()`'s `.format()` at `:299` cannot `KeyError`), readable English prose not a namespaced
   token (AC-19), and the zh value `检查器报告了错误，未输出信息（退出码 {code}）` contains **错误**, not
   `失败` (AC-20 / `insight-index.md:16`). Doctor zh block now `:172-217`, and I counted **42** keys —
   matches the record.
5. **Floor and gates — intact.** `capture_output=` at exactly **three** sites (`:1020`, `:1065`,
   `:1685`), all pre-existing; `_doctor_run` still `stdout=PIPE, stderr=STDOUT` + `.decode`
   (`:1255-1256`). No walrus, no f-string `=`, no `missing_ok=` in the added lines. **No new helper, no
   new constant** (`DOCTOR_MSG_LINES` is the same one). `_doctor_print` (`:1479-1489`) is byte-shape
   identical to the version I reviewed — one caller, no parameter, no mode: **F-14 respected**.
6. **BC-7's other clauses — hold** on the non-empty path: first line always printed, at most 5, marker
   naming the count. I-5's ruling (the count is over non-blank lines) is unchanged and still accepted.
7. **No spill.** `cmd_status` is `:1193-1214` = 22 lines, statement-for-statement the same list I proved
   byte-identical in §3 (header, init branch, TUN header, `ip`, `is_running()` gate, node, `clash_api`,
   mode, port, egress header, `try`/`except`) — AC-16 undisturbed. `ruleset_state()` (`:600-648`)
   returns a 3-tuple at all four exits (`:632`, `:634`, `:647`, `:648`) with the
   `size is None ⇔ digest is None` contract text unmoved — D-2 / T-10's restart decision untouched.
   `_doctor_config` is reachable only from `DOCTOR_SECTIONS` (`:1471`).
8. **`04_`'s numbers now close.** `457+31+31+2+18 = 539` insertions and `37+0+0+0+6 = 43` deletions match
   the summary line; `457+37 = 494` matches `--stat`'s graph column, which makes the stated cause of the
   original slip (`484 = 447+37`) itself arithmetically coherent; `1536 − 37 + 457 = 1956` and the
   file's last content line **is** 1956. Pre-fix `1536 − 37 + 447 = 1946` reconciles with my earlier
   `grep -c '^'` reading of 1946, and `+10 = 8 + 2` is exactly what the shift analysis shows. E-15's
   "+5 lines each" verified at `:1802-1806` and `:1859-1863`. E-2's "41 → 42" verified. **M-1's answer
   contradicts nothing I established**: `is_running = lambda: True` makes the `:1201` gate taken with
   `SYSTEMD = OPENRC = False`, which is precisely the missing premise I named in M-1, and it leaves my
   independent structural proof of AC-16 (§3, which never relied on the harness) standing. The one
   deliberately-uncompared region — the `systemctl status` subprocess at `:1195-1198` — is the region my
   proof also shows the diff does not touch. Consistent.

### New findings (delta)

**NIT** (do not block, no action expected):
- `bin/sc:1345-1346` — the comment "The checker's own words, quoted whole and indented…" now sits above
  the `lines` computation and the silent branch, i.e. two rows earlier than the rows it describes.
- `bin/sc:1354` — `code` is `subprocess.run().returncode`, so a checker killed by a signal renders as
  `exit -11`. Same shape as the pre-existing S1 key `the binary produced no version line (exit {code})`
  (`:192`); not introduced here.
- `04_` §4 E-2's anchor still reads `:170-215` (actual `:170-217` now) and E-16/E-18 read
  `:1917`/`:1946` (actual `:1914`/`:1944`). The §4 "anchor caveat" declares stale anchors and names
  `git diff` as authoritative, but E-2 is one of the two rows claimed re-measured. Record-only.

### Not verifiable (unchanged constraint)

No `git`, so "byte-for-byte" on the non-empty path is a structural argument, not a diff; AC-26's
byte-identity re-check (`git diff --quiet` exit 0) and the corrected `--stat`/`--numstat` output are the
developer's word. The 40 new `t_doctor.py` E2 assertions, the 166-check regression, `verify_all`
16/1/0/1, the rendered 76/41-column widths, the zh render, and "108 zh keys / 66 at HEAD" are all
unexecuted by me; `scratchpad/` still returns nothing to `Glob`, so the harnesses remain outside the
repository.

### Axis status (delta only)

- **Standards-conformance:** clean — 3 NITs, no MINOR or above. Placeholder parity, the `失败`
  prohibition, AC-19 prose keys, the 3.6 floor, F-14 and rule 85 (no new helper, no new constant) all
  hold across the delta.
- **Spec/design-fidelity:** clean — no findings. The delta is declared as `DESIGN DRIFT` #4 in `04_` §9,
  is additive (same class, same exit status, same row shape, no new status vocabulary — FR-11
  untouched), fills a genuine hole in `02_` §6's S3 value table, and touches no other AC. Prior M-2 →
  **closed**; M-3(a/b/c) → **closed and independently re-derived above**; M-1 → **answered, consistent,
  remains QA's to restate in `06_`**.

Aggregate = **NIT**. Neither axis carries a BLOCKER or a MAJOR; the prior verdict's follow-ups 1 (now an
evidence instruction for QA), 4 and 5 remain open as before.

**DELTA APPROVED — prior verdict stands**
