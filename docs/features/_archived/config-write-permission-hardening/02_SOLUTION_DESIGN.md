# 02 — Solution Design · T-13 `config-write-permission-hardening`

Mode: **full**. Upstream `01_REQUIREMENT_ANALYSIS.md` verdict is **READY** and binding; nothing
below contradicts it. Deferred-human mode (`defer, do not ask`): every judgment call is resolved
here as a `D-n` with reasoning and an overturn condition. Verdict at §16.

Stage 1's §7 safety constraints are reproduced verbatim in §15 so stages 4 and 6 inherit them.

---

## 1. Architecture summary

`bin/sc` gains **one** new function, `_write_private(path, text)`, which is the only way a
credential document reaches disk: it builds the content in a fresh, exclusively-created object in
the target's own directory, sets that object's mode to exactly `0600` **on the open descriptor
before the first byte is written**, and installs it with `os.replace()`. The write-then-`chmod`
pair disappears from all three of its occurrences (`bin/sc:311-312`, `:323-324`, `:1016-1017`); no
`chmod` runs after content anywhere on these paths. `install.sh` gains one extractable function,
`sweep_credential_modes()`, called between the last install step and `install_report()`, which
states the mode of each credential document under the configuration directory and narrows (never
widens) any found wider than `0600`, without ever being able to abort the run or change the exit
status. Nothing else changes: `settings.json`'s writers, `sc doctor`, the service units, timeouts
and `install_report()`'s derivation are byte-identical.

---

## 2. Affected modules

| File | Change | Size |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | `import tempfile`; `CRED_MODE` constant; new `_write_private()`; 3 call sites rewired; 1 translation key | ≈ +62 / −7 |
| `/home/alan/Programs/singbox-cli/install.sh` | `CRED_DIR` / `CRED_FILES` / `CRED_MODE`; new `sweep_credential_modes()`; 1 call site; 7 keys × 2 languages | ≈ +62 / −0 |
| `/home/alan/Programs/singbox-cli/README.md` | `config.json` mode stated (§13 AC-25) | +2 / −1 |
| `/home/alan/Programs/singbox-cli/README.zh-CN.md` | line-for-line mirror | +2 / −1 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | one zh `### 修复` bullet under `[Unreleased]` | +2 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | 2 rows: `_write_private` utility; `_plain` now has non-doctor callers | +3 |
| `/home/alan/Programs/singbox-cli/CONTEXT.md` | glossary term **credential document** (already written by this stage) | +7 |
| `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | 2 new records + 1 re-occurrence (already written by this stage) | +26 |

**Data model changes: none.** No schema, no new persisted field, no new file. `config.json` and
`nodes.json` keep byte-identical content for identical inputs; only the mode, the creation
mechanism and the failure behaviour change.

---

## 3. The mechanism, and the proof it is the right one

NFR-1 names three facts that must hold at once. The design's claim is that **no single API defeats
all three**, and that each is defeated by a different, nameable element.

### 3.1 The three facts, and what defeats each

| Fact (NFR-1) | Why the naive fix fails | Element that defeats it |
|---|---|---|
| **(a)** a mode argument at creation is masked by umask (BC-2) | `mkstemp`'s `0o600` under umask `0o277` yields `0400`, not `0600` | `os.fchmod(fd, 0o600)` on the descriptor |
| **(b)** a mode argument is ignored entirely for an existing file (BC-3) | `open(target, O_CREAT, 0o600)` on a live `0644` file leaves it `0644` | `O_CREAT\|O_EXCL` on a **new** name + `os.replace()` — the target is never opened for writing, and its inode is discarded, not reused |
| **(c)** a `chmod` after the content is written leaves a window (the defect) | `bin/sc:1016-1017` — bytes land in a `0666 & ~umask` object, then the mode narrows | **ordering**: `fchmod` precedes the first byte; there is no post-write `chmod` at all |

Each element is necessary. Drop the `fchmod` and BC-2 regresses (mode `0400`, not exactly `0600`).
Drop `O_EXCL`/`replace` and BC-3 regresses (the reporter's own host, E-14). Drop the ordering and
the original defect returns. **A design that satisfies only two of the three does not satisfy the
requirement** — stage 1's own words, and the reason the construction is a combination.

### 3.2 What each element is proven on

| Claim | Evidence | Kind |
|---|---|---|
| `mkstemp` passes `0o600` as `open(2)`'s mode argument and issues **no** `chmod` | `/usr/lib/python3.12/tempfile.py:395` — `fd = _os.open(file, flags, 0o600)`; the whole `_mkstemp_inner` is `:382-409` and contains no `chmod`/`fchmod` | source, read this session |
| …so `mkstemp`'s mode is an **upper bound**, not an equality | POSIX `open()`: the new file's permission bits are set to `mode` **except those set in the file mode creation mask**. A mask can only *clear* bits ⇒ result ⊆ `0600` | specification |
| …and the documented contract forbids anything wider | `tempfile.py:481` docstring — "The file is readable and writable only by the creating user ID." | documented contract |
| **Therefore "mkstemp is 0600" is false as stated and true as a bound.** The design does not rely on the equality; it re-establishes it explicitly. | — | conclusion |
| `mkstemp`'s flags include `O_CREAT\|O_EXCL` and `O_NOFOLLOW` where available | `tempfile.py:191-197` | source |
| `mkstemp` re-raises `PermissionError` on POSIX (no silent retry) | `tempfile.py:398-405` — the retry arm is `_os.name == 'nt'` only | source |
| `Path.write_text` is `io.open(path, 'w')`, whose `FileIO` creates with mode `0666` | `/usr/lib/python3.12/pathlib.py:1041-1047` → `:1007-1015` → `io.open`; `0666` is `_io.FileIO`'s fixed mode argument | source + documented |
| `rename(2)` does not touch the inode's `st_mode` | POSIX `rename()`: the new pathname *refers to the same file*; Linux `rename(2)`: "Open file descriptors for oldpath are also unaffected", the target is "atomically replaced". No mode is specified as changing. | specification |
| `rename(2)` replaces a symlink at `newpath` rather than following it | Linux `rename(2)` — `newpath` is not resolved through a final symlink | specification |

**The one claim that is a specification argument rather than a measurement** — `os.replace`
preserving the source's mode — is handed to stage 6 as a *direct* measurement plus a falsifier, so
it is never merely assumed: see §14 V-2.

### 3.3 The `fchmod`-vs-mode-argument window, answered precisely

> *If the design opens a descriptor and adjusts its mode before writing, is there still a window?*

There are two distinct instants, and they are in different places:

```
t0  open(O_CREAT|O_EXCL|O_NOFOLLOW, 0600) on <cfgdir>/config.json.tmp.<pid>.<rand>
    ── the object becomes nameable HERE. Its mode is 0600 & ~umask  ⊆ 0600.
    ── it holds ZERO bytes. Nothing to expose.
t1  fchmod(fd, 0600)                       ── mode is now EXACTLY 0600, still empty.
t2  write() / flush() / fsync()            ── the first credential byte lands, at 0600.
t3  rename(tmp, config.json)               ── the TARGET dirent flips, atomically, from
                                              "old complete document" to "new complete
                                              document, already 0600".
```

So: the interval `[t0, t1)` is a window **on an empty file**, and even that window is at `≤0600`;
the interval `[t1, t2)` has the final mode already in force. At the target path there is no
interval at all — `rename` is a single atomic step, and the inode it publishes was `0600` before
it ever held a byte. **There is no instant at which any object holding a byte of the new content
is readable by group or other.** That is in-scope behaviour 3, satisfied structurally rather than
by timing.

Contrast with HEAD: `write_text` creates the object *at the target path* at `0666 & ~umask`
(`0644` typically), the credential bytes land into it, and only then does `os.chmod` narrow it —
and on an already-`0644` file the exposure covers the entire write, because the mode argument is
ignored for an existing file.

### 3.4 Candidates considered and declined

| Candidate | Why not |
|---|---|
| `os.open(target, O_CREAT, 0o600)` + `fchmod`, no temp | Fails behaviour 4 (not atomic) and behaviour 5 (`O_TRUNC` destroys the previous document before the new one is known to be writable). |
| `umask()` bracket around the write | Process-global and not thread-safe; it changes the mode of *every* file any concurrent code creates; a signal between set and restore leaves the process' umask altered; and it still cannot make an **existing** file `0600` (fact (b)). Recorded in `.harness/rejected-decisions.md` as `umask-bracket-for-credential-writes`. |
| `mkstemp` alone, no `fchmod` | Yields `0400` under umask `0o277` — violates BC-2/AC-2 ("exactly `0600`, not `0400`"). Not a security regression, but the guarantee stops being explicit, which is exactly how it would be lost in a future edit. |
| `chmod` after write (HEAD) | Fact (c). |

---

## 4. `bin/sc` — module decomposition

### 4.1 New constant (section `# Paths`, after `RULES_DIR`, `bin/sc:22`)

```python
# THE mode of every credential document this tool writes. Single definition; the only
# reader today is _write_private(). Precedent for a named single-reader constant:
# SRS_MIN_BYTES (bin/sc:61).
CRED_MODE = 0o600
```

This is also the anchor **T-20** converges on (see §12 D-9).

### 4.2 New function (section `# State files`, immediately above `_init_files()`)

```python
def _write_private(path, text):
    """Install `text` at `path` as a regular file at mode exactly CRED_MODE, atomically.

    Three facts make "0600 at every instant" true and each is carried by a DIFFERENT
    element — none of them is a chmod after the write, which is the window this exists
    to remove:

      * mkstemp creates a NEW object under an unpredictable name in `path`'s own
        directory with O_CREAT|O_EXCL|O_NOFOLLOW and mode 0o600. open(2)'s mode argument
        is masked by the umask, so it is an UPPER bound: the object can appear at 0600 or
        narrower, never wider — and it is empty at that instant.
      * os.fchmod on the still-empty descriptor makes the mode exactly 0600 whatever the
        umask cleared, and it runs BEFORE the first byte, so no content is ever behind a
        wider mode.
      * os.replace() is rename(2): it swaps a directory entry and never touches the
        inode, so the mode travels with the content and the target's PREVIOUS mode is
        irrelevant (an O_CREAT mode argument would have been ignored for an existing
        file). It is atomic, so a concurrent reader sees one whole document; and it
        replaces a symlinked target with this regular file instead of writing through it.

    dir= is load-bearing twice: os.replace across filesystems raises EXDEV, and a default
    TMPDIR would put credential bytes outside the configuration directory.

    Raises OSError — the caller renders it, as _egress_ip() and _fetch_to_temp() do. The
    target is never opened for writing, so every failure leaves the previous document
    byte-identical, and no temporary survives either outcome.
    """
    fd, tmp = tempfile.mkstemp(
        dir=str(path.parent),
        prefix=path.name + ".tmp." + str(os.getpid()) + ".")
    try:
        os.fchmod(fd, CRED_MODE)
        fh = os.fdopen(fd, "w")          # fh owns the fd from here
        fd = -1
        try:
            fh.write(text)
            fh.flush()
            os.fsync(fh.fileno())        # surface ENOSPC BEFORE the replace, never after
        finally:
            fh.close()
        os.replace(tmp, str(path))
        tmp = None
    finally:
        if fd >= 0:
            os.close(fd)
        if tmp is not None:
            try:
                os.unlink(tmp)
            except OSError:
                pass
```

**Binding implementation notes for stage 4** (each prevents a specific regression):

1. `os.fdopen(fd, "w")` — **not** `os.write(fd, text.encode("utf-8"))`. `os.fdopen`'s
   `TextIOWrapper` defaults are byte-identical to `Path.write_text`'s (`pathlib.py:1015` →
   `io.open`, `encoding=None`), and `load_nodes()` reads back with `Path.read_text()`
   (`bin/sc:319`), also locale-encoded. Writing UTF-8 while reading locale would convert a latent
   write-time failure into a read-time one. Encoding is **not** this task's subject (§15 O-2).
2. `fd = -1` immediately after `os.fdopen` succeeds — the descriptor's ownership transfers; the
   `finally` must not double-close it. If `os.fdopen` itself raises, `fd` is still `>= 0` and the
   `finally` closes it.
3. `prefix` carries the pid so a leftover after `SIGKILL` is attributable without a sweeper
   (BC-10, and §12 D-5).
4. No directory `fsync`. BC-10 is process death, for which `rename` is already atomic; power-loss
   durability is not in any AC, and an extra directory descriptor per write is scope nobody asked
   for.

### 4.3 Call sites

| Site | HEAD | New |
|---|---|---|
| `bin/sc:310-312` (`_init_files`) | `NODES_PATH.write_text(json.dumps({...}, indent=2))` + `os.chmod` | `save_nodes({"active": None, "nodes": []})` |
| `bin/sc:322-324` (`save_nodes`) | `write_text` + `os.chmod` | `_write_private(...)` inside `try/except OSError` |
| `bin/sc:1016-1017` (`generate_config`) | `write_text` + `os.chmod` | `_write_private(...)` inside `try/except OSError` |

`_init_files()` delegating to `save_nodes()` is **byte-identical output**:
`json.dumps({"active": None, "nodes": []}, indent=2)` and the same call with
`ensure_ascii=False` produce the same bytes for a pure-ASCII literal. It removes the second
statement of "how the node store is written" — the duplicated-judgment seam rule 85 test 2 names —
and it routes `_init_files`' failure through `save_nodes`' loud handler instead of a traceback.
**`bin/sc:309`'s hard-coded `/var/lib/sing-box` is NOT touched** (§15 O-1, §14 V-6).

```python
def save_nodes(d):
    try:
        _write_private(NODES_PATH, json.dumps(d, indent=2, ensure_ascii=False))
    except OSError as e:
        sys.exit(t("Could not write {path}: {err}",
                   path=NODES_PATH, err=_plain(e.strerror or str(e))))
```

```python
    # generate_config(), replacing bin/sc:1016-1017. Ordering vs `sing-box check` unchanged (NG-9).
    try:
        _write_private(CFG_PATH, json.dumps(config, indent=2, ensure_ascii=False))
    except OSError as e:
        sys.stderr.write("⚠️  " + t("Could not write {path}: {err}",
                                    path=CFG_PATH, err=_plain(e.strerror or str(e))) + "\n")
        return False
```

**Error path, end to end** (in-scope behaviour 5 / AC-8), using no new reporting concept:

```
OSError  ──▶ generate_config() catches ──▶ stderr: "⚠️  " + t(...)  ──▶ return False
                                                                       │
                          reload_or_restart() (bin/sc:1034-1038) ──────┘ returns False
                                                                       │
                          cmd_reload() (bin/sc:1790-1794) ─────────────┘ sys.exit(t("Reload failed"))  ⇒ status 1
```

Reuse, not invention: `⚠️ ` outside `t()` + `sys.stderr.write` is the documented idiom
(`docs/dev-map.md` "Warning to stderr"); `return False` from `generate_config()` is its existing
failure contract (`bin/sc:1021-1024`); `sys.exit(t(...))` inside a non-`cmd_` helper has precedent
at `bin/sc:1075` (`_resolve_node`); `_plain()` is the project's single definition of "foreign text
made output-safe" and `e.strerror` is foreign text.

### 4.4 New translation key (exactly one)

Inserted in `TRANSLATIONS["zh"]`'s `# errors` block, after `"Error: {e}"` (`bin/sc:98`):

```python
"Could not write {path}: {err}": "无法写入 {path}：{err}",
```

Identical placeholder set `{path}`, `{err}`. Contains neither `failed:` nor `失败：`, so the
load-bearing diagnostic grep is not polluted (AC-22, `.harness/insight-index.md`). English comes
from the key itself — `TRANSLATIONS` has no `en` table (`docs/dev-map.md`).

---

## 5. `install.sh` — the closing permission sweep

### 5.1 Placement and the one-place root

Inserted immediately **after** `install_report()`'s closing `}` (`install.sh:288`) — the two
closing-time functions live together, and both anchor at column 0 so each is extractable by the
project's proven `sed` idiom (`check-i18n-parity.sh:48`).

```bash
# ----------------- credential permission sweep -----------------
# THE one place this script names the directory it sweeps and the documents it sweeps.
# Both are referenced ONLY inside sweep_credential_modes(), which is what makes the
# section verifiable against a temp dir: a harness extracts the function, defines these
# three variables itself and never runs the installer (AC-18). Same discipline as
# bin/sc's path constants — "only ever referenced inside function bodies, so a test
# harness can repoint them" (docs/dev-map.md, "Paths" row).
CRED_DIR="/etc/sing-box"
# settings.json is deliberately absent: it carries no credential, and narrowing it is a
# user-visible change nobody asked for (NG-4). rules/*.srs and the directory itself are
# out by the same rule (NG-5, AC-19).
CRED_FILES=(config.json nodes.json)
CRED_MODE=600
```

### 5.2 The function

```bash
# Reports the mode of every credential document and narrows — never widens — any found
# wider than CRED_MODE. Structurally incapable of terminating the installer under
# `set -euo pipefail`: every command whose status can be non-zero sits in an `if`
# condition or a `case`, which are set -e's exempt contexts (docs/dev-map.md; T-11).
# Reads nothing from PHASE_* and writes nothing to it, so install_report()'s derivation
# and the exit status are untouched (DECISION-5, AC-20).
sweep_credential_modes() {
    local f path mode newmode
    t perm_header "$CRED_DIR"
    for f in "${CRED_FILES[@]}"; do
        path="$CRED_DIR/$f"
        # -L before -e: a broken symlink is a symlink, not an absent file. chmod and stat
        # both FOLLOW links, so without this guard a link planted at config.json would
        # aim the installer's chmod at any path on the system (NG-11).
        if [ -L "$path" ];   then t perm_skip   "$path"; continue; fi
        if [ ! -e "$path" ]; then t perm_absent "$path"; continue; fi
        if [ ! -f "$path" ]; then t perm_skip   "$path"; continue; fi
        mode=""
        if ! mode=$(stat -c '%a' "$path" 2>/dev/null); then mode=""; fi
        # Validate BEFORE any arithmetic: $((8#$mode)) on unexpected text is a syntax
        # error, which is non-zero AND prints — the abort class R-3 records for this file.
        case "$mode" in
            [0-7]|[0-7][0-7]|[0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) ;;
            *) t perm_unknown "$path"; continue ;;
        esac
        if [ $((8#$mode & 8#077)) -eq 0 ]; then
            t perm_ok "$path" "$mode"          # 0600 or narrower: no chmod is issued (BC-15)
            continue
        fi
        if ! chmod "$CRED_MODE" "$path" 2>/dev/null; then
            t perm_problem "$path" "$mode" "$CRED_MODE" "$path"
            continue
        fi
        # Re-read rather than assert the intent: the line states what IS, not what we asked for.
        newmode=""
        if ! newmode=$(stat -c '%a' "$path" 2>/dev/null); then newmode=""; fi
        if [ "$newmode" = "$CRED_MODE" ]; then
            t perm_fixed "$path" "$mode" "$newmode"
        else
            t perm_problem "$path" "$mode" "$CRED_MODE" "$path"
        fi
    done
}
```

**Constraints binding on stage 4:** nothing inside the body may start at column 0 (no heredoc with
a column-0 terminator), or the `sed -n '/^sweep_credential_modes() {/,/^}/p'` extraction AC-18
rests on stops being exact. `local` is declared on its own line — never `local mode=$(...)`, whose
status is `local`'s, not the substitution's.

**Portable mode read.** `stat -c '%a'` is GNU coreutils *and* BusyBox (`stat -f %Lp` is the BSD
form). `install.sh` is Linux-only by construction — it dispatches on apt/dnf/yum/pacman/zypper/apk
(`:39`), on systemd/OpenRC (`:61-67`), and downloads `sing-box-…-linux-${ARCH}.tar.gz` (`:396`) —
so both supported `stat` implementations accept `-c`. **Stated assumption, not a hidden one:** a
host with neither GNU nor BusyBox `stat` takes the `perm_unknown` line and the run continues; it
never aborts.

**Directory absent (BC-13):** no special case. `[ -L ]` false, `[ -e ]` false ⇒ each file reports
`perm_absent`, the section prints, the run continues.

### 5.3 Call site

```bash
# Between the last install step and the closing report: the banner stays the final
# output and install_report()'s derivation from PHASE_CONFIG/PHASE_SERVICE is untouched
# (DECISION-5). `|| true` makes "the sweep cannot change the run's outcome" true by
# construction rather than by an audit of every line inside it — the R-3 failure class.
sweep_credential_modes || true

install_report || exit 1      # unchanged (install.sh:532-533)
exit 0
```

Placed after step 7's `if` block (`install.sh:528`) at top level, so it runs on a successful run
and on one where the config phase failed, with the same shape (behaviour 11, AC-14, BC-16).
**Scope of "every run", stated plainly:** the sweep serves exactly the population `install_report()`
serves. The pre-flight `exit 1`s (`:35, :47, :57, :66`) and the download/dependency exits
(`:348, :364, :394, :401`) precede it and already bypass `install_report()` too — that is R-3's
class, deliberately not absorbed here.

### 5.4 New `t()` keys — 7, paired, both tables

Inserted after `step6_nolog)` in **both** `case` blocks, at the same relative position (the
mitigation `rejected-decisions.md § t-fmt-default-fallback` prescribes).

| key | specifiers | en | zh |
|---|---|---|---|
| `perm_header` | 1 | `▶ Checking credential file permissions in %s ...` | `▶ 检查凭据文件权限（%s）...` |
| `perm_ok` | 2 | `  ✔ %s: mode %s — left unchanged` | `  ✔ %s：权限 %s —— 未改动` |
| `perm_absent` | 1 | `  · %s: not present — nothing to check` | `  · %s：不存在 —— 无需检查` |
| `perm_fixed` | 3 | `  ⚠️ %s: mode was %s — narrowed to %s` | `  ⚠️ %s：原权限 %s —— 已收紧为 %s` |
| `perm_problem` | 4 | `  ❌ %s: mode %s could not be narrowed — run: chmod %s %s` | `  ❌ %s：权限 %s 无法收紧 —— 请手动执行：chmod %s %s` |
| `perm_unknown` | 1 | `  ❌ %s: its mode could not be read — check it by hand` | `  ❌ %s：读不到权限 —— 请手动检查` |
| `perm_skip` | 1 | `  ❌ %s: not a regular file — left untouched` | `  ❌ %s：不是普通文件 —— 未改动` |

`perm_problem`'s last two specifiers repeat the mode and the path so the line ends in a runnable
command — NFR-3 wants the user to know what to do, not only what broke.

**AC-21's second clause is already satisfied by the committed gate, not by new work.**
`check-i18n-parity.sh:98-107` (`--- 3b. self-check`) now `die2`s when the two renders are
byte-identical, which is exactly the R-7 blind spot. **`docs/tasks.md` R-7 is stale as of commit
`49506f8`** — reported to the PM, not edited by this stage.

---

## 6. Flow

```
sc add / rm / use / reload / update-rules
  └─ generate_config()                                bin/sc:914
       ├─ load_nodes() … build `config` dict …        unchanged
       ├─ _warn_degraded(report)                      unchanged (NG-9)
       ├─ _write_private(CFG_PATH, json.dumps(...))
       │     ├─ mkstemp(dir=/etc/sing-box,
       │     │          prefix="config.json.tmp.<pid>.")   O_CREAT|O_EXCL|O_NOFOLLOW, ≤0600, empty
       │     ├─ fchmod(fd, 0600)                           EXACTLY 0600, still empty
       │     ├─ write / flush / fsync                      first credential byte, at 0600
       │     ├─ replace(tmp, /etc/sing-box/config.json)    atomic dirent flip; mode rides the inode
       │     └─ finally: unlink(tmp) if it still exists    no temporary survives
       │        └─ OSError ⇒ ⚠️  "Could not write {path}: {err}" on stderr ⇒ return False
       └─ subprocess.run([SB_BIN, "check", ...])       unchanged, still AFTER the write (E-12/NG-9)

install.sh  … step 7 …  ▸ sweep_credential_modes || true  ▸ install_report || exit 1  ▸ exit 0
                          per file: symlink? absent? not regular? mode? ≤0600 → OK
                                                                     wider  → chmod, re-read, state both
```

---

## 7. Reuse audit

| Need | Existing code | File path | Decision |
|---|---|---|---|
| Atomic temp-then-replace | `tmp.replace(target)` | `bin/sc:1632` | **Reuse the call, not the helper** — see §12 D-3 |
| Unique temp name / exclusive creation | `_temp_path()`, `_clear_stale_temps()` | `bin/sc:815-856` | **Not reused** (D-3): rule-set-specific, bound to `RULES_DIR`, and its stale-sweeper is exactly what BC-10/NG-11 do not want in the config directory. `tempfile.mkstemp` supplies uniqueness + `O_EXCL` + `O_NOFOLLOW` with no new logic |
| Warning to stderr | `sys.stderr.write("⚠️  " + t(...) + "\n")` | `bin/sc:1022`, `:800` | Reuse as-is |
| Hard error from a non-`cmd_` helper | `sys.exit(t(...))` | `bin/sc:1075` (`_resolve_node`) | Reuse as-is |
| Foreign text made output-safe | `_plain(text)` | `bin/sc:1236` | Reuse as-is; gains its first non-`doctor` callers (dev-map row updated) |
| Bilingual string | `t()` + `TRANSLATIONS` | `bin/sc:299` | Reuse; 1 new key |
| Generation failure contract | `generate_config() → False` → `reload_or_restart()` → `cmd_reload` non-zero | `bin/sc:1021`, `:1034`, `:1790` | Reuse unchanged — no new error concept |
| A repointable constant a harness can override | module-level constants referenced only inside function bodies | `docs/dev-map.md` "Paths" row | Reuse the **pattern** for `install.sh`'s `CRED_DIR` (AC-18) |
| Extracting a shell function without executing the script | `sed -n '/^t() {/,/^}/p'` | `.harness/scripts/check-i18n-parity.sh:48` | Reuse the idiom for `sweep_credential_modes()` |
| Bilingual parity proof for `install.sh` | `check-i18n-parity.sh`, incl. the new §3b self-check | `.harness/scripts/` | Reuse as-is; AC-21 needs no new tooling |
| Bash abort-safety under `set -euo pipefail` | `if ! SB_VER=$(…)` | `install.sh:384`; `docs/dev-map.md` "Patterns to follow" | Reuse the pattern verbatim |
| Named single-reader constant | `SRS_MIN_BYTES` | `bin/sc:61` | Precedent for `CRED_MODE` |
| Credential-mode statement in prose | "mode 600, root-only" | `README.md:191, :217` + zh mirrors | Extend to `config.json` (AC-25) |

---

## 8. Design decisions

**D-1 — ONE helper, not three inlined patterns, and not a thin wrapper.** Rule 85's two tests both
resolve the same way. *Deletion test:* delete `_write_private` and every one of its callers must
re-implement mkstemp + fchmod + fdopen + flush + fsync + replace + two cleanup arms — ~18 lines
each, and each is an independent chance to get the *ordering* wrong, which is the whole
requirement. Complexity reappears N-fold ⇒ it earned its keep. *Duplicated judgment:* "how a
credential document reaches disk safely" is one judgment; it is written three times at HEAD
(`:311-312`, `:323-324`, `:1016-1017`) and stage 1's DECISION-2 already ruled it is one judgment,
not two. *Depth:* the interface is `(path, text) -> None, raises OSError`; behind it sit umask
independence, previous-mode independence, atomicity, symlink defeat, temp hygiene and ENOSPC
ordering. That is a lot of behaviour behind a two-argument signature — not a pass-through.
*Counter-rule check:* it is one function in an existing section, no new file, no new concept, no
parameters beyond the two the callers already have.
Direct call sites after D-2 are **two** (`save_nodes`, `generate_config`), plus one indirect
(`_init_files` → `save_nodes`) — two adapters, so the seam is real, not hypothetical.

**D-2 — `_init_files()` writes the initial node store through `save_nodes()`.** Byte-identical
output (§4.3), removes the third copy of "how the node store is written", and gives that path the
same loud failure as every other. *Overturned by:* evidence that the initial store must differ
from a saved one — there is none; both are `json.dumps(d, indent=2)` of the same shape.

**D-3 — `_write_private` and the rule-set downloader stay separate.** The rule-set path streams
**unvalidated** bytes off a socket, must be interruptible and re-runnable, needs a cross-run stale
sweeper (`_clear_stale_temps`, `bin/sc:821`) because its directory is scanned, and must **not** be
`0600`-pinned (NG-5). The credential path has its content in memory, needs no validation hook, and
must **not** have a sweeper in its directory (BC-10, NG-11). A shared helper would need a mode
parameter, a streaming-vs-in-memory split and a validate-before-replace hook — three parameters to
serve two callers, i.e. a pass-through with a config object; it fails the deletion test. What they
share is one stdlib call, `replace()`, already shared at the language level. Recorded in
`.harness/rejected-decisions.md` as `shared-atomic-write-helper-with-ruleset-downloader`.

**D-4 — `nodes.json` gets atomicity too; there is no asymmetry to justify.** Stage 1 requires the
mode guarantee for `nodes.json` (behaviour 2) and behaviour 3 for *both* files. For an existing
`0644` `nodes.json`, the only constructions that satisfy behaviour 3 are (i) truncate-then-fchmod
in place — which destroys the previous document before the new one is durable, contradicting
behaviour 5's spirit — or (ii) temp-then-replace. Choosing (ii) makes `nodes.json` atomic as a
**by-product**, exactly as stage 1's DECISION-1 predicted for `config.json`. Deliberately
introducing the asymmetry would cost an extra code path to be *worse*.

**D-5 — No sweeper for leftover credential temporaries.** BC-10 rules a `SIGKILL` leftover litter,
not exposure (it is `0600`). A sweeper cannot distinguish a dead run's temp from a **concurrent**
run's without encoding a pid and re-deriving `_clear_stale_temps`' prefix-coupling seam
(`docs/tasks.md` T-02 note 6). The pid in the prefix makes a leftover attributable at zero cost.
*Overturned by:* an observed host accumulating temporaries.

**D-6 — `settings.json`'s writers are not routed through `_write_private`, with any mode.** Three
reasons. (i) It would **change** the observable mode: today `settings.json` is created at
`0666 & ~umask`, which is `0644` under the common umask but `0666` under umask `0` — pinning any
fixed mode is a user-visible change NG-4 forbids. (ii) It would silently grant atomicity to a file
whose atomicity nobody requested — scope the counter-rule forbids. (iii) The helper's contract is
"credential document"; routing a non-credential file through it makes the name a lie and dilutes
the very judgment (`which files are credential-bearing`) this task exists to state once.
`save_settings` (`bin/sc:331`), `_init_files`' settings branch (`:313-315`) and `install.sh`'s
python heredoc (`:417-431`) stay byte-identical. *Overturned by:* evidence that a field in
`settings.json` is a secret (stage 1's DECISION-2 already weighed and rejected `clash_api_port`).

**D-7 — `CRED_DIR` is a plain variable, not an environment override.** A harness that sources the
extracted function defines the variable itself, so the `${SC_CRED_DIR:-…}` indirection buys
nothing and adds a redirection surface to a root-run `curl | bash` script. This is exactly
`bin/sc`'s own repointable-constant pattern. `install.sh`'s three other `/etc/sing-box` literals
(`:411, :421, :455`) are **not** consolidated — that is a different edit on a different surface
(§15 O-3).

**D-8 — S-2: the committed `bin/sc` test harness is deferred once more, on a NEW and structural
reason, and must be filed as its own row.** The previous three deferrals rested on diff boundaries.
This one rests on a binding criterion of this very task: **AC-23 requires `verify_all` to PASS with
zero delta in PASS/WARN/FAIL/SKIP counts against a pristine `HEAD` clone.** `verify_all.sh:77` is
a hard-coded `step "B.3" "Lint" "SKIP"`; wiring any real test step necessarily moves a count
(SKIP−1/PASS+1, or a new step) and breaks AC-23 as written. Committing a suite **without** wiring
it would be strictly worse — an unrun suite is what `.harness/scripts/baseline.json`'s
`test_count: 0` (R-4) already records. And the honest scope of that work is not "add a tests
directory": it is B.3-or-B.4 in `verify_all.sh` **plus** the `.ps1` mirror (R-6 already records the
two diverging) **plus** `baseline.json` (R-4) — three files this task has no criteria for.
*What is paid down here instead of deferring silently a fourth time:*
 (1) §14 V-1 specifies the **neutralisation recipe** as a design artifact — an `os`-shim in
 `sys.modules` that makes `geteuid()` return `0` **without mutating `bin/sc`'s source**, which is
 the piece every prior task re-invented and the piece the safety incident in
 `.harness/insight-index.md` came from;
 (2) that recipe goes into `docs/dev-map.md` so the next task inherits a design, not a blank page;
 (3) the PM is asked to file the harness as its own numbered row, scoped to the three files above.
*Overturned by:* the gate reading AC-23 as "no regression" rather than "zero delta" — in which case
the harness ships in this task as a new `B.4`, `.ps1` included, and `baseline.json` is populated.
That is the gate's call to make; it is ruled here, not improvised at stage 4. Recorded as a fourth
re-occurrence on the existing `ruleset-unit-tests-in-t02` record, per that file's one-record rule.

**D-9 — S-1: documentation is INSIDE the permitted diff.** The dispatch's "SCOPE BOUNDARY:
`bin/sc` and `install.sh` only" names the surfaces whose **behaviour** changes; `01_REQUIREMENT_ANALYSIS.md`
AC-25 is a binding criterion of an APPROVED document and requires `README.md`, `README.zh-CN.md`
and `CHANGELOG.md` edits, and every prior task shipped a `CHANGELOG.md` entry (T-02, T-08, T-09,
T-10, T-11). Where a dispatch summary and the binding requirement disagree, the requirement wins.

**The exact permitted diff this design authorises** (any file not listed is out):

| # | Absolute path | Why |
|---|---|---|
| 1 | `/home/alan/Programs/singbox-cli/bin/sc` | §4 |
| 2 | `/home/alan/Programs/singbox-cli/install.sh` | §5 |
| 3 | `/home/alan/Programs/singbox-cli/README.md` | AC-25 |
| 4 | `/home/alan/Programs/singbox-cli/README.zh-CN.md` | AC-25, line-for-line mirror |
| 5 | `/home/alan/Programs/singbox-cli/CHANGELOG.md` | AC-25 + project convention |
| 6 | `/home/alan/Programs/singbox-cli/docs/dev-map.md` | its own header mandates it for a new utility; omitting it is what became `docs/tasks.md` T-08 note 4 |
| 7 | `/home/alan/Programs/singbox-cli/CONTEXT.md` | glossary duty — **already written by this stage** |
| 8 | `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | rule 25 duty — **already written by this stage** (note: this file already carried uncommitted changes at task start) |
| 9 | `/home/alan/Programs/singbox-cli/docs/features/config-write-permission-hardening/*` | stage documents |
| 10 | `/home/alan/Programs/singbox-cli/docs/tasks.md` | PM's board — PM only, not the developer |

**Explicitly NOT in the diff:** `uninstall.sh`, `systemd/*`, `docs/architecture.md` (its
`:119` "mode 600" line is about `nodes.json` and stays true), `.harness/scripts/*`,
`.claude/*`, `AI-GUIDE.md`, `.harness/rules/*`.

**D-10 — README edits keep the mirrors line-for-line.** `README.md:190` gains ` (mode 600)` to
match `:191`'s shape; a bullet is added in `## ⚠️ Security notes` after `:217` stating that
`config.json` embeds the same credentials and is written at mode 600, replaced atomically. The zh
mirror takes the same two edits at the same line numbers (`README.zh-CN.md:190`, `:217`).

---

## 9. Risk register

| # | Risk | Mitigation |
|---|---|---|
| R-1 | `os.replace` raises `EXDEV` if the temp is not on the target's filesystem | `dir=str(path.parent)` is mandatory and documented in the docstring; `TMPDIR` is never consulted. Also the AC-12 safety property. |
| R-2 | A "simplification" drops the `fchmod`, silently regressing BC-2 | Docstring names which element carries which fact (§3.1); AC-2 asserts **exactly** `0600` under umask `0o277`, which fails at `0400`. |
| R-3 | A "simplification" writes bytes (`os.write(fd, text.encode())`), changing the encoding and breaking `Path.read_text()` round-trip on non-ASCII node tags | §4.2 note 1 forbids it explicitly; stage 5 must check it. |
| R-4 | Descriptor double-close / leak | The `fd = -1` ownership transfer is spelled out in §4.2 and must survive review verbatim. |
| R-5 | The installer's sweep aborts the run under `set -euo pipefail` — the live R-3 class in this file | Every fallible command inside an `if`/`case`; octal-digit `case` guard **before** any `$(( ))`; `|| true` at the call site; AC-17 proves continuation with `chmod(){ return 1; }`. |
| R-6 | `chmod`/`stat` follow a symlink at `config.json`, aiming the installer at an arbitrary path | `[ -L ]` guard first, then `[ -f ]`; `perm_skip` line. |
| R-7 | A new `install.sh` key present in one table aborts the installer under `set -u` | Paired insertion at the same relative position in both blocks; `verify_all` B.2 renders all 48 keys in both languages and now also proves the two renders differ (`check-i18n-parity.sh:98-107`). |
| R-8 | `save_nodes` now `sys.exit`s where it previously raised — control-flow change inside `generate_config()` (`bin/sc:928`) | At HEAD the same `OSError` also terminated the process (traceback + status 1); the change is traceback → one translated line. Required by NFR-3. Named for stage 5 so it is reviewed, not discovered. |
| R-9 | A test harness importing `bin/sc` re-execs the **installed** `/usr/local/bin/sc` under sudo and restarts the owner's live VPN | §14 V-1's shim + `assert os.geteuid() != 0` + `SYSTEMD = OPENRC = False` + `SB_BIN` repointed to a stub; §15 constraint 2. |
| R-10 | A harness driving `_init_files()` writes to the real `/var/lib/sing-box` (`bin/sc:309`) | §14 V-6: do not drive `_init_files()`; test `save_nodes()`, which is now the whole of its nodes branch. |
| R-11 | `SIGKILL` leaves `config.json.tmp.<pid>.<rand>` in the config directory | Accepted (BC-10): `0600`, pid-tagged, never in the way. D-5. |
| R-12 | A setuid/setgid bit on a credential file is reported but not the cause of narrowing | `& 8#077` deliberately ignores bits 07000; the mode is printed verbatim so a `2600` is visible. Ownership and special bits are DECISION-4 / T-20's. |
| R-13 | AC-8's "exactly one line" is measured on `sc reload`'s whole stderr and fails | §13 AC-8 note: it is measured on `generate_config()`'s own output; `cmd_reload`'s pre-existing `Reload failed` line is what carries the non-zero exit and is unchanged. |

---

## 10. Migration / rollout

- **Backwards compatible; no data migration.** Content shape is unchanged, so an older `sc` reads
  files written by the new one and vice versa. No feature flag: the change is a strict narrowing
  of an unrequested permission and cannot be opted out of here (that is T-14).
- **Legacy hosts (E-14's population)** are reached by the installer: `install.sh` overwrites
  `/usr/local/bin/sc` (`:412`), runs `sc reload` (`:515`) which regenerates `config.json` through
  the new path, and then the sweep states and repairs whatever the run did not.
- **Rollback** is `git revert` of the product diff. No on-disk state must be undone: a `0600`
  `config.json` is readable by the (root) service either way (`systemd/sing-box.service` has no
  `User=`; the OpenRC unit runs under `supervise-daemon` as root), so an older `sc` on a
  narrowed file works unchanged.
- **`sing-box check -c /etc/sing-box/config.json` as a non-root user fails on a `0600` config.**
  That is correct (NG-3) and is now true on hosts where it previously happened to work. The
  README security note (D-10) is where the user is told.

---

## 11. Out-of-scope clarifications

This design does **not** cover, and stage 4 must not build: a permission override mechanism
(T-14); urltest (T-15); DNS (T-16); rule-set staleness (T-19); any `sc doctor` change including a
permission row (T-20, NG-2/AC-24); ownership or `chown` (NG-6); backups/export/snapshots (NG-7);
the mode of `/etc/sing-box/` or `rules/` (NG-5); repairing modes outside `CRED_FILES` (NG-11);
`uninstall.sh`, the service units (NG-10); any timeout (NG-8); the wider `install.sh` silent-abort
class (R-3); `verify_all.ps1`'s B.2 divergence (R-6); the three `capture_output=` Python-floor
violations (AC-26 pins them as untouched).

**D-11 — where T-20's single definition will live (flagged, deliberately not built).** After this
task the statement "which files are credential-bearing and at what mode" exists twice, once per
language: `CRED_MODE` in `bin/sc` (§4.1) and `CRED_DIR`/`CRED_FILES`/`CRED_MODE` in `install.sh`
(§5.1). A cross-language single definition is impossible without a new generated artifact, which
is over-build. T-20's cheap convergence is: add `CREDENTIAL_FILES = (NODES_PATH, CFG_PATH)` in
`bin/sc`'s `# Paths` block **next to `CRED_MODE`**, and have both the doctor probe and any future
repair read that pair. Building it now would ship a constant with no iterating reader — the
counter-rule's speculative generality. `install.sh`'s array then mirrors two `bin/sc` names rather
than an unstated judgment.

---

## 12. Partition assignment

`.harness/agents/` contains **no `dev-*.md`** — `.harness/rules/50-singbox-cli.md` §Partitioning
pins single-developer mode. All ten files in §8 D-9's table go to `harness-kit:developer`.
Dispatch order within the task: `bin/sc` → `install.sh` → docs (the docs describe the code).
No parallelism.

---

## 13. Acceptance-criteria map

| AC | Satisfied by | Discriminating vs HEAD? |
|---|---|---|
| AC-1 | §4.2 `fchmod(CRED_MODE)`; both call sites §4.3 | no — HEAD's `chmod` already ends at 0600 |
| AC-2 | `fchmod` (umask `0o000`/`0o022`/`0o077`); the `0o277` case is the one HEAD passes only by luck of the trailing `chmod` | partly |
| AC-3 | `O_EXCL` on a new name + `os.replace` (fact (b)) | no (end state), **yes** for the mechanism |
| AC-4 | §3.3 timeline: at the suspension point only the temp holds new bytes, at `0600` | **yes** — HEAD has the target itself at `0644` mid-write |
| AC-5 | the target is never opened for writing | **yes** |
| AC-6 | `mkstemp` raises `PermissionError` (`tempfile.py:398-405`) before anything is touched; §4.3 handler | **yes** |
| AC-7 | write→check ordering unchanged (`bin/sc:1019-1024`, NG-9) | no — must stay identical |
| AC-8 | §4.3 error path; `t("Could not write {path}: {err}")` with `e.strerror` | **yes** |
| AC-9 | `mkstemp` names differ per process; `rename` is atomic | **yes** |
| AC-10 | `tmp = None` after `replace`; `finally: unlink` | **yes** |
| AC-11 | fresh unpredictable name + `O_NOFOLLOW`; `rename` replaces the link itself | **yes** — HEAD writes *through* the link |
| AC-12 | `dir=str(path.parent)`; no `TMPDIR`; `_init_files()` not on the path | — |
| AC-13 | §5.3 placement before `install_report` | new |
| AC-14 | §5.3 top-level, unconditional | new |
| AC-15 | `perm_fixed` (3 specifiers, both modes) / `perm_ok` with **no** `chmod` issued | new |
| AC-16 | `perm_absent`; the sweep sets no status variable | new |
| AC-17 | `if ! chmod …` + `perm_problem` + `continue`; `\|\| true` at the call site | new |
| AC-18 | `CRED_DIR` referenced only inside the function; column-0 anchors for `sed` extraction | new |
| AC-19 | `CRED_FILES=(config.json nodes.json)` — the only names the loop can reach | new |
| AC-20 | the sweep reads/writes no `PHASE_*`; `install_report \|\| exit 1` untouched | new |
| AC-21 | 7 paired keys, equal specifier counts; `check-i18n-parity.sh` incl. its §3b self-check | new |
| AC-22 | 1 new `bin/sc` key, identical placeholders, no `failed:` / `失败：` | new |
| AC-23 | no `verify_all` step is added or changed — **and this is why D-8 rules as it does** | — |
| AC-24 | `sc doctor` untouched; `_plain` gains callers but is not modified | — |
| AC-25 | D-10 | new |
| AC-26 | `tempfile.mkstemp(dir=,prefix=)`, `os.fchmod`, `os.fdopen`, `os.fsync`, `os.replace` — all ≤3.3; no third-party import; the three `capture_output=` sites untouched | — |
| AC-27 | `perm_ok` issues no `chmod`; the sweep writes nothing else | new |

**No AC is believed unsatisfiable.** Two require a stated reading, both flagged for the gate:

- **AC-4 / AC-6 — "no file in the fixture directory wider than 0600."** Measured on a run whose
  pre-existing files are absent or already `0600`. A pre-existing `0644` `config.json` (AC-5's own
  fixture) is the *user's* file and holds **none of the new content**, which is precisely what
  behaviour 3 scopes ("every filesystem object that holds any byte of the new content"). After the
  run it is gone, replaced by a `0600` file (AC-3).
- **AC-8 — "exactly one line on stderr."** Measured on `generate_config()`'s own output. The
  fixture must carry four *usable* `.srs` stubs (`b"SRS"` + ≥13 bytes) or `_warn_degraded`
  (`bin/sc:800`) adds its own legitimate line; and `cmd_reload`'s pre-existing `Reload failed`
  line is unchanged behaviour and is what makes the exit non-zero.

---

## 14. Verification strategy — what stage 6 must prove, and the fixture that proves it safely

**V-1 — the import fixture (the piece every prior task re-invented; reusable as designed).**
Load `bin/sc` as a module **without mutating its source** and without ever reaching the
auto-elevate `execvp` at `bin/sc:83-84`:

```
assert os.geteuid() != 0                      # refuse to run as root, loudly
real_os = os; shim = ModuleType("os"); shim.__dict__.update(real_os.__dict__)
shim.geteuid = lambda: 0                      # line 83's branch is simply not taken
sys.modules["os"] = shim
exec(compile(open("bin/sc").read(), "bin/sc", "exec"), sc.__dict__)
sys.modules["os"] = real_os                   # restore immediately
```
Then repoint `sc.CFG_DIR / CFG_PATH / NODES_PATH / SETTINGS_PATH / RULES_DIR` inside a
`mkdtemp()` root, set `sc.SYSTEMD = sc.OPENRC = False`, `sc.CLASH_PORT = 29090`,
`sc.LANG = "en"|"zh"`, and `sc.SB_BIN = <stub script>` (a repointable constant — no `PATH`
games). Because `bin/sc` uses `os` from `sc.__dict__`, monkeypatching `sc.os.replace` patches the
shim only, never the harness's own `os`. This recipe is safer than source surgery: it cannot be
defeated by a refactor of the elevate block, and it fails closed if `geteuid` moves.

**V-2 — prove the two claims this design argues from specification.**
(a) *`os.replace` preserves the source's mode:* write a temp at `0600`, replace onto a target
pre-created at `0644`, `stat` the target ⇒ `0600`. **Falsifier (must also be run):** the same with
the temp at `0644` ⇒ target `0644`, proving the target's own mode is discarded and the source's is
what survives. (b) *`mkstemp`'s mode is umask-masked:* `os.umask(0o277)`, `mkstemp`, `stat` ⇒
`0400`. That measurement is the justification for `fchmod` existing at all; if it ever returns
`0600`, D-1's reasoning is unchanged but R-2 relaxes.

**V-3 — the "never wide" proof (AC-4/AC-5), which is the criterion HEAD fails.** Monkeypatch
`sc.os.replace` with a spy that, at the moment of the call, walks the fixture directory and
records `(name, S_IMODE)` for every regular file, then delegates to the real `os.replace`. Run
under `os.umask(0o000)`. Assert every recorded mode `& 0o077 == 0` and that the temp's recorded
size is non-zero (non-vacuity: the spy must actually have observed a written temp, not an empty
one). Re-run the identical assertion against a pristine `HEAD` copy of `bin/sc` and require it to
**fail** — that is what makes the green non-vacuous.

**V-4 — the installer sweep, without ever executing `install.sh`** (§15 constraint 5):
extract `t()` and `sweep_credential_modes()` with `sed`, source both into a `bash -euo pipefail`
child that defines `LANG_CHOICE`, `CRED_DIR=<fixture>`, `CRED_FILES`, `CRED_MODE`, then
`sweep_credential_modes; echo AFTER`. Fault injection needs no root: define shell functions
`chmod() { return 1; }` (AC-17) and `stat() { return 1; }` (`perm_unknown`) in the child, which
shadow the externals. Fixture files: `0644` (→ repaired), `0600` (→ OK, mtime unchanged),
`0400` (→ OK, **not** widened), missing (→ absent), a symlink (→ skip, and the link's destination
mode unchanged), a directory named `config.json` (→ skip), plus a `0644` `settings.json` and a
`rules/` directory that must appear in neither the output nor any mode change (AC-19). Run the
whole matrix in **both** `LANG_CHOICE` values and diff the two transcripts to show they differ.
Separately, drive the extracted `install_report()` across the four `PHASE_CONFIG`/`PHASE_SERVICE`
combinations at HEAD and at the new revision and require byte-identical output and status (AC-20).

**V-5 — concurrency (AC-9).** Two `multiprocessing` children calling `generate_config()` against
one fixture with distinguishable node lists; assert the result parses, equals one of the two
documents, is `0600`, and that no `*.tmp.*` remains.

**V-6 — safety witnesses, every run.** `os.stat` (read-only) of `/etc/sing-box/config.json`,
`/etc/sing-box/nodes.json` and `/var/lib/sing-box` before and after the whole suite: `st_ino`,
`st_mtime`, `st_mode` identical (AC-12 and §15 constraint 1). Service witness
`systemctl show -p MainPID -p ActiveEnterTimestamp sing-box`, **never `is-active`**, at three
checkpoints. **Never drive `_init_files()`** — `bin/sc:309`'s hard-coded `/var/lib/sing-box` is
not repointable, and its nodes branch is now nothing but a `save_nodes()` call, which V-3's
fixture already covers directly.

**V-7 — `verify_all`** against a pristine **clone** of `HEAD` (never a `git worktree` —
`.harness/insight-index.md`), expecting a zero count delta (AC-23), with B.2 rendering 48 keys.

---

## 15. Safety constraints — inherited verbatim from `01_REQUIREMENT_ANALYSIS.md` §7

1. **Never write, chmod, move or back up anything under `/etc` on this machine.** Every
   verification uses a temp-dir fixture root. `/etc/sing-box/` is the live configuration of the
   owner's running VPN.
2. **Neutralise `bin/sc`'s import-time auto-elevate block in every harness and every throwaway
   script** (the *sudo re-exec* specifically — `cmd_uninstall` legitimately calls
   `os.execvp("bash", …)`). See §14 V-1.
3. **A redirected-paths harness is not automatically safe** — `_init_files()` hard-codes
   `/var/lib/sing-box` (`bin/sc:309`).
4. **Never test against the installed `/usr/local/bin/sc`** — it is an older build.
5. **Never execute `install.sh`.**
6. **Never restart or reload the live service**; witness with
   `systemctl show -p MainPID -p ActiveEnterTimestamp`, never `is-active`.

**Observations re-homed by this stage, not fixed here.** **O-1** `bin/sc:309`'s hard-coded
`/var/lib/sing-box` remains the one non-repointable path (insight-index; blocks testing
`_init_files()`). **O-2** `bin/sc` writes and reads its JSON in the *locale* encoding
(`write_text`/`read_text`), so a non-ASCII node tag under the C locale on a 3.6 interpreter can
raise `UnicodeEncodeError`; fixing it means changing both directions together, out of scope here.
**O-3** `install.sh` names `/etc/sing-box` at `:411, :421, :455` in addition to `CRED_DIR`;
consolidating belongs to R-3's rewrite. **O-4** `docs/tasks.md` R-7 is **stale** — the B.2
blind spot was closed by commit `49506f8`; PM to update the board (this stage may not).
**O-5** `bin/sc:1667` still prints "config regenerated" when the regeneration returned failure
(re-homed by stage 1; unchanged here).

---

## 16. Verdict

**READY.**

The central mechanism question is answered with a named construction and a per-fact attribution
(§3.1), the umask-independence claim is grounded in read source (`tempfile.py:191-197, :395,
:398-405, :481`) rather than asserted, and the one specification-based claim is handed to stage 6
as a measurement with a falsifier (§14 V-2). The helper question is ruled with both rule-85 tests
applied in both directions (D-1, D-3, D-6). The two items the PM routed here are ruled: S-1 in
D-9 with an exact permitted-diff list, S-2 in D-8 on a structural reason with the overturn
condition named for the gate. No safety red line was reached — this stage read only.

**Defect found in the upstream document (reported, not edited):** none that changes a decision.
Two readings of AC-4/AC-6 and AC-8 need the scoping stated in §13; both are consistent with
in-scope behaviours 3 and 5 as written, so no rollback is requested.
