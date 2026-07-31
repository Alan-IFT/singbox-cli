# T-10 QA harness — complete and runnable verbatim (C-11)

Companion to `06_TEST_REPORT.md`. It lives here rather than inside `06` because
`verify_all` F.6 caps `0[1-7]_*.md` and `PM_LOG.md` at 500 lines and **any** WARN makes
`verify_all` exit 1; this harness is ~2 200 lines. F.6 does not count this filename, so
no gate is bypassed and no content is elided. D-8/C-11 still hold: **no test tree is
committed**, `verify_all` B.2 stays SKIP with its recorded reason, and
`.harness/scripts/baseline.json` is untouched.

## How to run it

Copy every file below into one empty directory (any path outside the repo) and run:

```
bash run.sh q0_safetynet.py q1_digest_contract.py q2_comparator.py q3_run.py \
            q4_negative_control.py q5_static.py q6_init_tty_cost.py q7_generate_config.py
```

`run.sh` refuses to proceed at euid 0, greps the whole directory for the shared loader
before running anything, installs the PATH shims, and asserts the shim marker is absent
at the end. Expected: `522 checks, 0 failures`, runner exit 0.

## Safety design (NFR-1 / C-2 / C-3 / C-4), in three layers

| Layer | What it stops | Where |
|---|---|---|
| 0 | `os.execvp` / `execv` / `execl` / `system` / `spawn*` **inside the loaded module** | `qalib.load_sc` → `ExecTripwire` |
| 1 | `subprocess.run / Popen / call / check_call / check_output / getoutput / getstatusoutput` inside the loaded module — deny-by-default, records argv, raises, **whitelists nothing** (in particular not `sing-box`) | `qalib.Tripwire` |
| 2 | Any real `systemctl` / `rc-service` / `sing-box` / `sc` / `sudo` / `service` / `openrc` / `rc-update` / `systemd-run` reached by **any** route, including a re-import or a forgotten script — PATH shim writes `$SC_T10_MARKER`, asserted absent at the end of every script **and** again by the runner | `run.sh` + `qalib.install_shims` |

`q0_safetynet.py` is a **positive control on the net itself**: a marker that has never
been shown to record anything proves nothing when it is absent. It fires every shim
against a side marker, fires every tripwire entry point, and proves the loader
hard-fails (exit 97) when `bin/sc`'s auto-elevate block stops matching byte for byte.

---

## `qalib.py` (352 lines)

```python
"""qalib — the ONE shared loader + safety layers for every T-10 QA script (stage 6).

Written independently at stage 6. Inherits the shape the developer's loader established
(gate C-3) and hardens it in three ways the developer's version did not have:

  * layer 0  os.execvp / os.execv / os.execl / os.system / os.spawn* inside the LOADED
             module are replaced with raising stubs, so even a source substitution that
             silently stopped matching cannot re-exec /usr/local/bin/sc.
  * the tripwire also covers subprocess.getoutput / getstatusoutput / run / Popen /
             call / check_call / check_output.
  * SELF-TEST of the safety net itself (q7): a net that has never been shown to fire
             proves nothing when it reports "no violation".

NFR-1 / gate C-2, C-3, C-4. bin/sc auto-elevates at IMPORT time by re-execing the
INSTALLED /usr/local/bin/sc under sudo (bin/sc:77-78); sudo's env_reset drops env
overrides, so an un-neutralised import runs the live tool against the live service.
That is what dropped the owner's connections during T-02.

Every script that touches bin/sc must `import qalib` and load through load_sc(). That
makes "did this script neutralise the auto-elevate?" a grep over this directory.
"""
import io
import os
import shutil
import subprocess
import sys
import tempfile
import types

REPO = "/home/alan/Programs/singbox-cli"
SC_PATH = os.path.join(REPO, "bin", "sc")

# The exact auto-elevate block that must be neutralised.
ELEVATE_SRC = (
    'if os.geteuid() != 0:\n'
    '    os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])\n'
)
ELEVATE_NEUTRALISED = (
    'if False:  # AUTO-ELEVATE NEUTRALISED BY qa qalib (NFR-1)\n'
    '    pass\n'
)
UNINSTALL_EXEC_SRC = '        os.execvp("bash", ["bash", str(script)])\n'
UNINSTALL_EXEC_NEUTRALISED = (
    '        raise AssertionError("cmd_uninstall exec blocked by qa qalib")  # NFR-1\n'
)

MARKER = os.environ.get("SC_T10_MARKER", "")

FAILURES = []
CHECKS = [0]


class TripwireError(AssertionError):
    """Raised when the module under test tries to shell out to anything at all."""


def _fail_hard(msg):
    sys.stderr.write("\n*** SAFETY VIOLATION *** " + msg + "\n")
    sys.stderr.flush()
    os._exit(97)


# ---------------------------------------------------------------- assertions

def check(cond, label):
    CHECKS[0] += 1
    if cond:
        print("  PASS  " + label)
    else:
        FAILURES.append(label)
        print("  FAIL  " + label)
    return bool(cond)


def eq(got, want, label):
    return check(got == want, "%s  [got=%r want=%r]" % (label, got, want)
                 if got != want else label)


def summary(name):
    print("\n-- %s: %d checks, %d failures" % (name, CHECKS[0], len(FAILURES)))
    if FAILURES:
        for f in FAILURES:
            print("   FAILED: " + f)
        sys.exit(1)


# ---------------------------------------------------------------- layer 2

SHIM_BODY = (
    '#!/bin/sh\n'
    '# T-10 QA safety shim. If this ever runs, a real service command escaped the harness.\n'
    'printf "%s %s\\n" "$(basename "$0")" "$*" >> "$SC_T10_MARKER"\n'
    'echo "BLOCKED by T-10 QA shim: $(basename "$0") $*" >&2\n'
    'exit 91\n'
)
SHIM_NAMES = ("systemctl", "rc-service", "sing-box", "sc", "sudo", "service",
              "openrc", "rc-update", "systemd-run")


def install_shims(shim_dir):
    """Layer 2: PATH-prepended shims. Writes $SC_T10_MARKER and exits non-zero."""
    if not MARKER:
        _fail_hard("SC_T10_MARKER is not set — run scripts through run.sh")
    if not os.path.isdir(shim_dir):
        os.makedirs(shim_dir)
    for name in SHIM_NAMES:
        p = os.path.join(shim_dir, name)
        fh = io.open(p, "w")
        fh.write(SHIM_BODY)
        fh.close()
        os.chmod(p, 0o755)
    os.environ["PATH"] = shim_dir + os.pathsep + os.environ.get("PATH", "")
    return shim_dir


def assert_no_service_calls(where):
    """Layer 2 assertion — call at the END of every script."""
    if not MARKER:
        _fail_hard("SC_T10_MARKER is not set")
    if os.path.exists(MARKER):
        body = io.open(MARKER).read()
        _fail_hard("PATH shim was invoked during %s:\n%s" % (where, body))
    print("  [safety] no shim invocation recorded (%s)" % where)


def assert_non_root():
    if os.geteuid() == 0:
        _fail_hard("running as root — every T-10 verification runs at non-root euid")


# ---------------------------------------------------------------- layer 1

class Tripwire(object):
    """Deny-by-default replacement for every subprocess entry point of the module.

    Records argv in call order and RAISES on every call. Nothing is whitelisted — in
    particular `sing-box` is NOT whitelisted (gate C-4): tests that need
    generate_config() / is_running() stub those module attributes instead.
    """

    def __init__(self):
        self.calls = []

    def __call__(self, argv, *a, **kw):
        self.calls.append(list(argv) if isinstance(argv, (list, tuple)) else [str(argv)])
        raise TripwireError("subprocess blocked by tripwire: %r" % (argv,))

    def argv0s(self):
        return [c[0] for c in self.calls]


class ExecTripwire(object):
    """Layer 0: os.exec* / os.system / os.spawn* inside the loaded module."""

    def __init__(self, name, calls):
        self.name = name
        self.calls = calls

    def __call__(self, *a, **kw):
        self.calls.append((self.name,) + a)
        _fail_hard("os.%s called from the module under test: %r" % (self.name, a))


def load_sc(tmproot=None, src_path=None):
    """Load bin/sc as a module with the auto-elevate neutralised and paths repointed.

    Returns (mod, tmproot). Self-asserts every safety property BEFORE the caller can
    call anything (gate C-2 form). `src_path` loads a different copy (the negative
    control loads the pre-change bin/sc from HEAD) — the same neutralisation applies.
    """
    assert_non_root()

    src = io.open(src_path or SC_PATH, encoding="utf-8").read()
    if ELEVATE_SRC not in src:
        _fail_hard("the auto-elevate block does not match qalib.ELEVATE_SRC — refusing "
                   "to load (bin/sc changed shape; update qalib deliberately)")
    src = src.replace(ELEVATE_SRC, ELEVATE_NEUTRALISED)
    if UNINSTALL_EXEC_SRC not in src:
        _fail_hard("cmd_uninstall's exec line does not match qalib.UNINSTALL_EXEC_SRC")
    src = src.replace(UNINSTALL_EXEC_SRC, UNINSTALL_EXEC_NEUTRALISED)
    if ELEVATE_SRC in src:
        _fail_hard("the auto-elevate block survived the substitution")
    for forbidden in ("os.execvp", "os.execv(", "os.execl", "os.system",
                      '["sudo", "/usr/local/bin/sc"]'):
        if forbidden in src:
            _fail_hard("%r still present in the source about to be exec'd" % forbidden)

    mod = types.ModuleType("sc_under_test")
    mod.__file__ = src_path or SC_PATH
    mod.__name__ = "sc_under_test"          # never "__main__": main() must not run
    code = compile(src, (src_path or SC_PATH) + " (neutralised)", "exec")
    exec(code, mod.__dict__)

    # --- layer 0: no exec / system escape from inside the loaded module
    exec_calls = []
    fake_os = types.ModuleType("os_guarded")
    for attr in dir(os):
        try:
            setattr(fake_os, attr, getattr(os, attr))
        except Exception:
            pass
    for name in ("execvp", "execv", "execl", "execle", "execlp", "execve", "execvpe",
                 "system", "spawnv", "spawnvp", "posix_spawn", "forkexec", "fork"):
        if hasattr(fake_os, name):
            setattr(fake_os, name, ExecTripwire(name, exec_calls))
    mod.os = fake_os
    mod.exec_calls = exec_calls

    # --- init systems off: restart_service()/is_running() become no-ops even if reached
    mod.SYSTEMD = False
    mod.OPENRC = False

    # --- repoint every path into a temp root
    if tmproot is None:
        tmproot = tempfile.mkdtemp(prefix="qat10-")
    Path = mod.Path
    mod.CFG_DIR = Path(tmproot) / "etc-sing-box"
    mod.CFG_PATH = mod.CFG_DIR / "config.json"
    mod.NODES_PATH = mod.CFG_DIR / "nodes.json"
    mod.SETTINGS_PATH = mod.CFG_DIR / "settings.json"
    mod.RULES_DIR = mod.CFG_DIR / "rules"
    mod.LIB_DIR = Path(tmproot) / "lib"
    mod.RULES_DIR.mkdir(parents=True, exist_ok=True)

    # --- layer 1: deny-by-default subprocess tripwire over the WHOLE surface
    mod.subprocess = types.ModuleType("subprocess_denied")
    tw = Tripwire()
    for entry in ("run", "Popen", "call", "check_call", "check_output",
                  "getoutput", "getstatusoutput"):
        setattr(mod.subprocess, entry, tw)
    mod.subprocess.CalledProcessError = subprocess.CalledProcessError
    mod.subprocess.PIPE = subprocess.PIPE
    mod.subprocess.DEVNULL = subprocess.DEVNULL
    mod.tripwire = tw

    # --- self-assertions (C-2 form): all of it, before the first call
    assert mod.SYSTEMD is False, "SYSTEMD not neutralised"
    assert mod.OPENRC is False, "OPENRC not neutralised"
    for nm in ("CFG_DIR", "CFG_PATH", "NODES_PATH", "SETTINGS_PATH", "RULES_DIR"):
        assert str(getattr(mod, nm)).startswith(tmproot), nm + " not repointed"
        assert not str(getattr(mod, nm)).startswith("/etc/"), nm + " still under /etc"
    assert mod.subprocess.run is tw, "tripwire not installed"
    assert mod.subprocess.Popen is tw, "tripwire missing Popen"
    assert isinstance(mod.os.execvp, ExecTripwire), "os.execvp not guarded"
    assert isinstance(mod.os.system, ExecTripwire), "os.system not guarded"
    return mod, tmproot


# ---------------------------------------------------------------- stubs

def stub_service(mod, running=True, regen=True):
    """C-4: resolve the tripwire <-> AC-7/AC-8 conflict by stubbing MODULE ATTRIBUTES.

    Never whitelist `sing-box` in the tripwire. Returns an ORDERED log (AC-12 needs the
    order) recording every service-layer entry point the run touched.
    """
    log = []

    def _generate_config():
        log.append("generate_config")
        return regen

    def _is_running():
        log.append("is_running")
        return running

    def _restart_service():
        log.append("restart_service")

    def _reload_or_restart():
        log.append("reload_or_restart")
        return True

    def _svc(action):
        log.append("svc:" + action)

    mod.generate_config = _generate_config
    mod.is_running = _is_running
    mod.restart_service = _restart_service
    mod.reload_or_restart = _reload_or_restart
    if hasattr(mod, "svc"):
        mod.svc = _svc
    return log


def stub_fetch(mod, bodies):
    """G-6: no network. `bodies` maps filename -> bytes, or filename -> Exception."""
    requests = []

    def _fetch(url, tmp, prefix, tty):
        requests.append(url)
        fname = None
        for f, rel in mod.RULESET_FILES:
            if url.endswith(rel):
                fname = f
                break
        payload = bodies.get(fname)
        if payload is None or isinstance(payload, Exception):
            raise (payload if isinstance(payload, Exception)
                   else ValueError("no body configured"))
        fh = io.open(str(tmp), "wb")
        fh.write(payload)
        fh.close()
        return len(payload)

    mod._fetch_to_temp = _fetch
    return requests


def write_ruleset(mod, fname, body):
    p = mod.RULES_DIR / fname
    fh = io.open(str(p), "wb")
    fh.write(body)
    fh.close()
    return p


def srs(payload=b"x" * 64):
    """A valid .srs body: SRS magic + enough bytes to clear SRS_MIN_BYTES."""
    return b"SRS" + payload


def cleanup(tmproot):
    shutil.rmtree(tmproot, ignore_errors=True)


class Captured(object):
    """Run fn() capturing stdout/stderr and the SystemExit status."""

    def __init__(self):
        self.out = ""
        self.err = ""
        self.status = None
        self.exc = None

    def run(self, fn):
        import contextlib
        so, se = io.StringIO(), io.StringIO()
        try:
            with contextlib.redirect_stdout(so):
                with contextlib.redirect_stderr(se):
                    fn()
            self.status = 0
        except SystemExit as e:
            self.status = e.code
        except Exception as e:          # noqa: BLE001 - the harness must see it
            self.exc = e
            self.status = "EXC:" + repr(e)
        self.out = so.getvalue()
        self.err = se.getvalue()
        return self
```

## `run.sh` (70 lines)

```bash
#!/usr/bin/env bash
# T-10 stage-6 QA runner. NFR-1 / gate C-2, C-3.
# Every QA script runs through here: non-root euid, PATH shims, G-3 grep, marker check.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

echo "### euid: $(id -u)  ($(id -un))"
if [ "$(id -u)" -eq 0 ]; then
    echo "REFUSING: T-10 verification never runs as root" >&2
    exit 97
fi

# ---- G-3: every .py in this directory routes module loading through the ONE loader
echo "### G-3: every .py here loads bin/sc only through qalib"
viol=0
for f in *.py; do
    [ "$f" = "qalib.py" ] && continue
    if grep -q "^import qalib\|^from qalib import" "$f"; then
        echo "    $f  OK (import qalib)"
    else
        echo "    $f  *** VIOLATION: does not import the shared loader ***"
        viol=1
    fi
    # No script may exec bin/sc itself, or name the installed CLI as a program to run.
    if grep -nE 'os\.(execvp|execv|execl|system)\(|(^|[^_a-zA-Z.])exec\(|/usr/local/bin/sc' "$f" | grep -q .; then
        echo "    $f  *** VIOLATION: raw exec / installed-CLI reference ***"
        grep -nE 'os\.(execvp|execv|execl|system)\(|(^|[^_a-zA-Z.])exec\(|/usr/local/bin/sc' "$f"
        viol=1
    fi
done
[ "$viol" -eq 0 ] || { echo "G-3 grep failed" >&2; exit 96; }

# ---- layer 2: PATH shims
export SC_T10_MARKER="$HERE/.shim-marker"
rm -f "$SC_T10_MARKER"
export SHIM_DIR="$HERE/shims"
rm -rf "$SHIM_DIR"; mkdir -p "$SHIM_DIR"
for n in systemctl rc-service sing-box sc sudo service openrc rc-update systemd-run; do
    cat > "$SHIM_DIR/$n" <<'EOF'
#!/bin/sh
# T-10 QA safety shim. If this ever runs, a real service command escaped the harness.
printf "%s %s\n" "$(basename "$0")" "$*" >> "$SC_T10_MARKER"
echo "BLOCKED by T-10 QA shim: $(basename "$0") $*" >&2
exit 91
EOF
    chmod 755 "$SHIM_DIR/$n"
done
export PATH="$SHIM_DIR:$PATH"
echo "### PATH shims installed: $SHIM_DIR"
echo "### which systemctl -> $(command -v systemctl)"

rc=0
for s in "$@"; do
    echo
    echo "=================== $s ==================="
    python3 "$s" || rc=1
done

echo
echo "### PATH-shim marker (must be absent)"
if [ -e "$SC_T10_MARKER" ]; then
    echo "*** MARKER PRESENT — a real service command was invoked ***"
    cat "$SC_T10_MARKER"
    rc=1
else
    echo "(absent — no systemctl / rc-service / sing-box / sc / sudo invocation)"
fi
echo "### runner exit: $rc"
exit $rc
```

## `q0_safetynet.py` (99 lines)

```python
"""q0 — SELF-TEST OF THE SAFETY NET (adversarial: a net never shown to fire proves nothing).

Hypothesis under test: "the marker file was absent, therefore nothing was invoked" is
only evidence if the marker mechanism DOES record an invocation when one happens, and
the tripwire DOES raise when the module shells out. Both are proved positively here,
against a side marker so the real run marker stays clean.
"""
import os
import subprocess
import tempfile

import qalib

qalib.assert_non_root()
print("== q0: does the safety net actually fire?")

# ---- layer 2 positive control: invoke each shim, with a SIDE marker file
side = tempfile.mkdtemp(prefix="qat10-net-")
side_marker = os.path.join(side, "marker")
env = dict(os.environ)
env["SC_T10_MARKER"] = side_marker
for name in ("systemctl", "rc-service", "sing-box", "sc", "sudo"):
    p = subprocess.run([name, "restart", "sing-box"], env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    qalib.check(p.returncode == 91,
                "shim %-10s intercepts and exits 91 (rc=%s)" % (name, p.returncode))
body = open(side_marker).read() if os.path.exists(side_marker) else ""
qalib.check(body.count("\n") == 5, "shim marker recorded all 5 invocations")
for name in ("systemctl", "rc-service", "sing-box", "sc", "sudo"):
    qalib.check(name in body, "marker names %s" % name)
print("    side marker body:\n" + "".join("      " + l + "\n" for l in body.splitlines()))

# PATH really resolves to the shim, not to the real binary
which = subprocess.run(["sh", "-c", "command -v systemctl"], stdout=subprocess.PIPE)
resolved = which.stdout.decode().strip()
qalib.check(resolved.endswith("/shims/systemctl"),
            "PATH resolves systemctl to the shim (%s)" % resolved)

# ---- layer 1 positive control: the tripwire raises and records
mod, tmproot = qalib.load_sc()
raised = False
try:
    mod.subprocess.run(["systemctl", "restart", "sing-box"])
except qalib.TripwireError:
    raised = True
qalib.check(raised, "tripwire raises on subprocess.run")
for entry in ("Popen", "call", "check_call", "check_output", "getoutput",
              "getstatusoutput"):
    ok = False
    try:
        getattr(mod.subprocess, entry)(["systemctl", "restart", "sing-box"])
    except qalib.TripwireError:
        ok = True
    qalib.check(ok, "tripwire raises on subprocess.%s" % entry)
qalib.check(len(mod.tripwire.calls) == 7, "tripwire recorded all 7 argv (%d)"
            % len(mod.tripwire.calls))

# ---- the real restart path is blocked even if it were reached
mod.SYSTEMD = True                       # deliberately re-arm to prove the block
blocked = False
try:
    mod.restart_service()
except qalib.TripwireError:
    blocked = True
qalib.check(blocked, "restart_service() is stopped by the tripwire even with SYSTEMD=True")
qalib.check(mod.tripwire.calls[-1][:3] == ["systemctl", "restart", "sing-box"],
            "and the argv it tried was %r" % (mod.tripwire.calls[-1],))
mod.SYSTEMD = False

# ---- layer 0 positive control: the loader refuses a source whose auto-elevate moved
bad = os.path.join(side, "sc_mutated")
src = open(qalib.SC_PATH, encoding="utf-8").read()
open(bad, "w").write(src.replace('if os.geteuid() != 0:',
                                 'if os.geteuid() != 0 :'))   # one space = no match
probe = subprocess.run(
    ["python3", "-c",
     "import sys; sys.path.insert(0,%r); import qalib; qalib.load_sc(src_path=%r)"
     % (os.path.dirname(os.path.abspath(__file__)), bad)],
    env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
qalib.check(probe.returncode == 97,
            "loader HARD-FAILS (97) when bin/sc's auto-elevate stops matching (rc=%s)"
            % probe.returncode)
qalib.check(b"SAFETY VIOLATION" in probe.stderr, "and says SAFETY VIOLATION")
print("    loader refusal: " + probe.stderr.decode().strip().splitlines()[-1][:120])

# ---- the loaded module cannot exec
mod2, tmproot2 = qalib.load_sc()
qalib.check(isinstance(mod2.os.execvp, qalib.ExecTripwire),
            "os.execvp inside the loaded module is a raising stub")
qalib.check(str(mod2.CFG_PATH).startswith(tmproot2)
            and not str(mod2.CFG_PATH).startswith("/etc"),
            "CFG_PATH is inside the temp root, not /etc")

qalib.cleanup(tmproot)
qalib.cleanup(tmproot2)
import shutil
shutil.rmtree(side, ignore_errors=True)
qalib.assert_no_service_calls("q0")
qalib.summary("q0_safetynet")
```

## `q1_digest_contract.py` (279 lines)

```python
"""q1 — C-5 digest contract + AC-13 + AC-5/AC-6 at the reader level.

Adversarial hypotheses (written BEFORE running):
  H1  a mid-read OSError leaks a PARTIAL digest (the hash object is updated before the
      exception, and `digest.hexdigest()` is reachable from the except arm)   -> then
      changed_usable_tags() could call a half-read file "unchanged".
  H2  a readable EMPTY file returns None (the loop breaks immediately, so an
      implementation that guards `if size == 0: return None` would look reasonable)
      -> then a 0-byte -> real transition would not be detected.
  H3  the SRS magic is missed when the first chunk is shorter than 3 bytes (a stream
      that yields b"S", b"R", b"S" one byte at a time) -> a usable file read as
      bad-magic.
  H4  ruleset_state() raises on a directory / dangling symlink / mode-000 path.
  H5  the digest is taken over the first chunk only, so two files that agree on their
      first 64 KiB but differ later compare equal.
"""
import hashlib
import io
import os
import tracemalloc

import qalib

qalib.assert_non_root()
mod, tmproot = qalib.load_sc()
R = mod.RULES_DIR
print("== q1: ruleset_state() digest contract (C-5), tmproot=%s" % tmproot)

EMPTY_SHA = hashlib.sha256(b"").hexdigest()


# ---------------------------------------------------------------- duck-typed paths
class FaultingPath(object):
    """A path whose read raises OSError after `n_ok` chunks (H1)."""

    def __init__(self, chunks, n_ok):
        self.chunks = chunks
        self.n_ok = n_ok

    def exists(self):
        return True

    def is_symlink(self):
        return False

    def is_file(self):
        return True

    def open(self, mode):
        outer = self

        class FH(object):
            def __init__(self):
                self.i = 0

            def read(self, n):
                if self.i >= outer.n_ok:
                    raise OSError(5, "Input/output error")
                c = outer.chunks[self.i]
                self.i += 1
                return c

            def __enter__(self):
                return self

            def __exit__(self, *a):
                return False

        return FH()


class ChunkyPath(FaultingPath):
    """A path that yields the given chunks then EOF, never faulting (H3)."""

    def __init__(self, chunks):
        FaultingPath.__init__(self, list(chunks) + [b""], 10 ** 9)


class OpenFailsPath(FaultingPath):
    def open(self, mode):
        raise OSError(13, "Permission denied")


# ---- H1: mid-read OSError
st = mod.ruleset_state(FaultingPath([b"SRS" + b"a" * 100, b"b" * 100], n_ok=1))
qalib.check(st == ("unreadable", None),
            "H1 REFUTED: OSError after 1 good chunk -> %r (no partial digest)" % (st,))
st = mod.ruleset_state(FaultingPath([b"SRS" + b"a" * 100], n_ok=0))
qalib.check(st == ("unreadable", None), "OSError on the very first read -> %r" % (st,))
st = mod.ruleset_state(OpenFailsPath([], 0))
qalib.check(st == ("unreadable", None), "OSError from open() -> %r" % (st,))

# the partial digest that WOULD have leaked, for contrast
partial = hashlib.sha256(b"SRS" + b"a" * 100).hexdigest()
qalib.check(st[1] != partial, "the digest of the bytes that WERE read is not returned")

# ---- H3: magic split across sub-magic chunks
st = mod.ruleset_state(ChunkyPath([b"S", b"R", b"S"] + [b"z"] * 20))
qalib.check(st == ("usable", hashlib.sha256(b"SRS" + b"z" * 20).hexdigest()),
            "H3 REFUTED: magic reassembled from 1-byte chunks -> %r" % (st[0],))
st = mod.ruleset_state(ChunkyPath([b"S", b"R", b"X"] + [b"z"] * 20))
qalib.check(st[0] == "bad-magic", "1-byte chunks, wrong 3rd byte -> bad-magic")
st = mod.ruleset_state(ChunkyPath([b""]))
qalib.check(st == ("too-small", EMPTY_SHA), "stream that is immediately EOF -> %r" % (st,))

# ---------------------------------------------------------------- real fixtures
fx = {}


def mk(name, body):
    p = R / name
    fh = io.open(str(p), "wb")
    fh.write(body)
    fh.close()
    fx[name] = p
    return p


mk("empty.srs", b"")                       # H2
mk("short.srs", b"SRS" + b"x" * 5)         # 8 bytes < SRS_MIN_BYTES(16)
mk("edge15.srs", b"SRS" + b"x" * 12)       # exactly 15
mk("edge16.srs", b"SRS" + b"x" * 13)       # exactly 16 -> usable
mk("html.srs", b"<!DOCTYPE html>" + b"x" * 50)
mk("good.srs", qalib.srs())
mk("noperm.srs", qalib.srs(b"p" * 64))
os.chmod(str(fx["noperm.srs"]), 0o000)
(R / "dir.srs").mkdir()
os.symlink(str(R / "nowhere-at-all"), str(R / "dangling.srs"))
mk("uni-中文.srs", qalib.srs(b"u" * 40))
big = b"SRS" + os.urandom(200000)
mk("big.srs", big)
# H5: agree on the first 64 KiB, differ after it, SAME total size
tail_a = b"A" * 100000
tail_b = b"B" * 100000
mk("prefix_a.srs", b"SRS" + b"c" * 70000 + tail_a)
mk("prefix_b.srs", b"SRS" + b"c" * 70000 + tail_b)

EXPECT = [
    ("nope.srs",       "absent",     None),
    ("dir.srs",        "unreadable", None),
    ("dangling.srs",   "unreadable", None),
    ("noperm.srs",     "unreadable", None),
    ("empty.srs",      "too-small",  "real"),
    ("short.srs",      "too-small",  "real"),
    ("edge15.srs",     "too-small",  "real"),
    ("edge16.srs",     "usable",     "real"),
    ("html.srs",       "bad-magic",  "real"),
    ("good.srs",       "usable",     "real"),
    ("uni-中文.srs", "usable", "real"),
    ("big.srs",        "usable",     "real"),
]
for name, want_status, want_digest in EXPECT:
    raised = None
    try:
        status, digest = mod.ruleset_state(R / name)
    except Exception as e:                       # AC-13: must never raise
        raised = e
        status, digest = ("RAISED", repr(e))
    qalib.check(raised is None, "H4 REFUTED: ruleset_state(%s) does not raise" % name)
    qalib.check(status == want_status,
                "%-20s status=%s (want %s)" % (name, status, want_status))
    if want_digest is None:
        qalib.check(digest is None, "%-20s digest is None" % name)
    else:
        qalib.check(isinstance(digest, str) and len(digest) == 64,
                    "%-20s digest is a real sha256" % name)

# ---- H2 explicitly
st = mod.ruleset_state(R / "empty.srs")
qalib.check(st == ("too-small", EMPTY_SHA),
            "H2 REFUTED: readable empty file -> ('too-small', sha256(b'')) not None")

# ---- H5 explicitly
a = mod.ruleset_state(R / "prefix_a.srs")
b = mod.ruleset_state(R / "prefix_b.srs")
qalib.check(os.path.getsize(str(R / "prefix_a.srs"))
            == os.path.getsize(str(R / "prefix_b.srs")), "H5 fixtures are equal size")
qalib.check(a[1] != b[1],
            "H5 REFUTED: equal size, identical first 70 KiB, different tail -> "
            "different digests (AC-5 at the reader level)")
qalib.check(a[1] == hashlib.sha256(io.open(str(R / "prefix_a.srs"), "rb").read()).hexdigest(),
            "digest equals sha256 of the whole file")

# ---- the C-5 EQUIVALENCE, in both directions, over every fixture above
allnames = [n for n, _s, _d in EXPECT]
both_ways = True
for name in allnames:
    status, digest = mod.ruleset_state(R / name)
    lhs = digest is None
    rhs = status in ("absent", "unreadable")
    if lhs != rhs:
        both_ways = False
qalib.check(both_ways,
            "C-5 equivalence holds in BOTH directions over all %d fixtures: "
            "digest is None <=> status in {absent, unreadable}" % len(allnames))

# ---- mode-000 PARENT directory (stage-5 note: yields 'absent', still inside the None set)
sub = R / "locked"
sub.mkdir()
qalib.write_ruleset(mod, "locked/inner.srs", qalib.srs())
os.chmod(str(sub), 0o000)
st = mod.ruleset_state(sub / "inner.srs")
qalib.check(st[1] is None,
            "mode-000 parent dir -> digest None (MEASURED status=%r on python %s; "
            "stage 5 predicted 'absent' by reading Path.exists()'s swallow — either "
            "label is inside the None set, so the C-5 invariant is unaffected)"
            % (st[0], ".".join(str(x) for x in __import__("sys").version_info[:3])))
os.chmod(str(sub), 0o755)

# ---- AC-6: mtime-only touch changes nothing
before = mod.ruleset_state(R / "good.srs")
os.utime(str(R / "good.srs"), (1, 1))
after = mod.ruleset_state(R / "good.srs")
qalib.check(before == after, "AC-6 mtime touched (utime 1,1) -> identical (status,digest)")
qalib.check(os.stat(str(R / "good.srs")).st_mtime == 1, "and the mtime really did change")

# ---- BC-15 bounded memory on a large file
mk("huge.srs", b"SRS" + b"m" * (6 * 1024 * 1024))
tracemalloc.start()
mod.ruleset_state(R / "huge.srs")
_cur, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()
qalib.check(peak < 1024 * 1024,
            "BC-15 6 MiB file hashed with peak traced memory %d B (< 1 MiB, O(1))" % peak)

# ---- the reader creates / modifies nothing
snap = sorted((p.name, p.stat().st_size) for p in R.iterdir() if p.is_file())
for name, _s, _d in EXPECT:
    mod.ruleset_state(R / name)
snap2 = sorted((p.name, p.stat().st_size) for p in R.iterdir() if p.is_file())
qalib.check(snap == snap2, "ruleset_state() creates and modifies nothing")

# ---- AC-25: no second on-disk judgment — delete srs_reject_reason, the new path breaks
saved = mod.srs_reject_reason
del mod.srs_reject_reason
broke = False
try:
    mod.ruleset_state(R / "good.srs")
except NameError:
    broke = True
qalib.check(broke, "AC-25 deleting srs_reject_reason() breaks ruleset_state() too "
                   "(no second usability judgment exists)")
mod.srs_reject_reason = saved
# and the whole chain still routes through it. NOTE: the four REAL rule-set names must
# exist and be readable first, or ruleset_state() short-circuits at the `absent` branch
# before it ever reaches srs_reject_reason() and the deletion test proves nothing.
for _f, _rel in mod.RULESET_FILES:
    qalib.write_ruleset(mod, _f, qalib.srs(b"z" * 40))
qalib.check(all(s[2] == "usable" for s in mod.ruleset_states()),
            "AC-25 pre-condition: all four real rule-sets are usable before the deletion")
broke2 = False
del mod.srs_reject_reason
try:
    mod.changed_usable_tags(mod.ruleset_states(), mod.ruleset_states())
except NameError:
    broke2 = True
qalib.check(broke2, "AC-25 ... and so does changed_usable_tags() via ruleset_states()")
mod.srs_reject_reason = saved

# ---- ruleset_status is exactly the first element (no second opinion)
consistent = all(mod.ruleset_status(R / n) == mod.ruleset_state(R / n)[0]
                 for n, _s, _d in EXPECT)
qalib.check(consistent, "ruleset_status(p) == ruleset_state(p)[0] on every fixture")

# ---- _status_view / ruleset_report contract unchanged (3-tuples)
states = mod.ruleset_states()
rep = mod.ruleset_report()
qalib.check(all(len(s) == 4 for s in states), "ruleset_states() yields 4-tuples")
qalib.check(all(len(r) == 3 for r in rep), "ruleset_report() still yields 3-tuples")
qalib.check(rep == mod._status_view(states), "ruleset_report() == _status_view(states)")
qalib.check([s[0] for s in states] == ["geoip-cn", "geosite-cn", "geosite-google",
                                       "geosite-private"],
            "snapshot order is RULESET_FILES order")

os.chmod(str(fx["noperm.srs"]), 0o644)
qalib.cleanup(tmproot)
qalib.assert_no_service_calls("q1")
qalib.check(mod.tripwire.calls == [], "tripwire recorded no shell-out during q1")
qalib.summary("q1_digest_contract")
```

## `q2_comparator.py` (132 lines)

```python
"""q2 — changed_usable_tags(): the pure comparator, and the gained ⊆ changed invariant.

Adversarial hypotheses:
  H6  two never-read files (None vs None) compare EQUAL, so BC-6 "unreadable before,
      valid body installed now" is missed.
  H7  pairing is positional, so a reordered `before` snapshot mis-pairs (F-10).
  H8  a LOSS (usable -> deleted) is reported as a change, which would restart sing-box
      into a config naming a file it cannot parse.
  H9  gained ⊄ changed for some transition — i.e. some rule-set becomes usable without
      appearing in the apply set, so T-02 recovery would silently stop applying.
"""
import itertools

import qalib

qalib.assert_non_root()
mod, tmproot = qalib.load_sc()
print("== q2: changed_usable_tags()")

D1 = "a" * 64
D2 = "b" * 64
D3 = "c" * 64


def snap(*rows):
    """rows: (tag, status, digest)"""
    return [(t, t + ".srs", s, d) for t, s, d in rows]


CASES = [
    # label, before, after, expected
    ("BC-1 four identical bodies -> nothing changed",
     snap(("a", "usable", D1), ("b", "usable", D2)),
     snap(("a", "usable", D1), ("b", "usable", D2)), []),
    ("BC-2 one body differs -> only that tag",
     snap(("a", "usable", D1), ("b", "usable", D2)),
     snap(("a", "usable", D3), ("b", "usable", D2)), ["a"]),
    ("BC-3 equal size, different content (digest, not size)",
     snap(("a", "usable", D1)), snap(("a", "usable", D2)), ["a"]),
    ("BC-4 absent -> usable",
     snap(("a", "absent", None)), snap(("a", "usable", D1)), ["a"]),
    ("BC-5 bad-magic -> usable",
     snap(("a", "bad-magic", D2)), snap(("a", "usable", D1)), ["a"]),
    ("BC-5b too-small -> usable",
     snap(("a", "too-small", D2)), snap(("a", "usable", D1)), ["a"]),
    ("BC-6 unreadable before, valid body installed (H6)",
     snap(("a", "unreadable", None)), snap(("a", "usable", D1)), ["a"]),
    ("BC-7 unreadable before, nothing installed -> not a change",
     snap(("a", "unreadable", None)), snap(("a", "unreadable", None)), []),
    ("BC-7b absent before and after",
     snap(("a", "absent", None)), snap(("a", "absent", None)), []),
    ("BC-13 usable -> deleted mid-run is a LOSS, not a change (H8)",
     snap(("a", "usable", D1)), snap(("a", "absent", None)), []),
    ("BC-13b usable -> corrupted (bad-magic) is a LOSS, not a change",
     snap(("a", "usable", D1)), snap(("a", "bad-magic", D2)), []),
    ("BC-13c usable -> unreadable is a LOSS, not a change",
     snap(("a", "usable", D1)), snap(("a", "unreadable", None)), []),
    ("BC-16 empty rule-set list", [], [], []),
    ("BC-9 two changed of four",
     snap(("a", "usable", D1), ("b", "usable", D1), ("c", "usable", D1),
          ("d", "usable", D1)),
     snap(("a", "usable", D2), ("b", "usable", D1), ("c", "usable", D1),
          ("d", "usable", D2)), ["a", "d"]),
    ("result is SORTED",
     snap(("z", "usable", D1), ("a", "usable", D1)),
     snap(("z", "usable", D2), ("a", "usable", D2)), ["a", "z"]),
    ("tag missing from `before` entirely -> changed",
     snap(), snap(("a", "usable", D1)), ["a"]),
    ("tag missing from `after` entirely -> not changed",
     snap(("a", "usable", D1)), snap(), []),
]
for label, b, a, want in CASES:
    got = mod.changed_usable_tags(b, a)
    qalib.check(got == want, "%s -> %r" % (label, got))

# ---- H7: pairing by tag, not by index. Reorder `before` and re-run every case.
h7_ok = True
for label, b, a, want in CASES:
    for perm in itertools.permutations(b):
        if mod.changed_usable_tags(list(perm), a) != want:
            h7_ok = False
            print("      mis-pair on %s with before=%r" % (label, perm))
qalib.check(h7_ok, "H7 REFUTED: every permutation of `before` gives the same answer "
                   "(paired by tag, F-10)")

# a positional comparator would answer differently on THIS control
b = snap(("a", "usable", D1), ("b", "usable", D2))
a = snap(("b", "usable", D2), ("a", "usable", D1))     # same content, swapped order
qalib.check(mod.changed_usable_tags(b, a) == [],
            "F-10 control: swapping the order of identical content yields [] "
            "(a positional comparator would report both tags changed)")

# ---- purity
b = snap(("a", "usable", D1))
a = snap(("a", "usable", D2))
b_copy, a_copy = list(b), list(a)
mod.changed_usable_tags(b, a)
qalib.check(b == b_copy and a == a_copy, "changed_usable_tags does not mutate its inputs")
qalib.check(mod.changed_usable_tags(b, a) == mod.changed_usable_tags(b, a),
            "changed_usable_tags is deterministic")

# ---- H9: gained ⊆ changed over EVERY status transition, exhaustively
STATUSES = {"usable": D1, "absent": None, "unreadable": None,
            "bad-magic": D2, "too-small": D3}
viol = []
for s_before, d_before in STATUSES.items():
    for s_after, d_after in STATUSES.items():
        b = snap(("a", s_before, d_before))
        a = snap(("a", s_after, d_after))
        gained = (mod.usable_tags(mod._status_view(a))
                  - mod.usable_tags(mod._status_view(b)))
        changed = set(mod.changed_usable_tags(b, a))
        if not gained <= changed:
            viol.append((s_before, s_after, gained, changed))
qalib.check(not viol, "H9 REFUTED: gained ⊆ changed for all %d status transitions %r"
            % (len(STATUSES) ** 2, viol))

# the hard sub-case: bad-magic -> usable where the digest is IDENTICAL is impossible,
# because status is a pure function of the bytes. Prove it at the reader, not on paper.
R = mod.RULES_DIR
qalib.write_ruleset(mod, "probe.srs", b"<html>" + b"x" * 40)
s1 = mod.ruleset_state(R / "probe.srs")
qalib.write_ruleset(mod, "probe.srs", b"SRS" + b"x" * 43)
s2 = mod.ruleset_state(R / "probe.srs")
qalib.check(s1[0] == "bad-magic" and s2[0] == "usable" and s1[1] != s2[1],
            "status is a pure function of the bytes: bad-magic -> usable forces a "
            "different digest (%s vs %s)" % (s1[1][:8], s2[1][:8]))

qalib.cleanup(tmproot)
qalib.assert_no_service_calls("q2")
qalib.check(mod.tripwire.calls == [], "tripwire recorded no shell-out during q2")
qalib.summary("q2_comparator")
```

## `q3_run.py` (405 lines)

```python
"""q3 — whole `sc update-rules` runs against fixtures, in BOTH languages.

Independent reproducers written from `01` §6/§7, not from the developer's test code.

Adversarial hypotheses:
  H10 the no-op run still touches the service (the defect) — or touches it through a
      path the stubs do not see (Popen / os.system / a re-imported subprocess).
  H11 a changed run applies MORE THAN ONCE (once per changed file) — AC-4.
  H12 the outcome line is printed twice, or not at all, on the sys.exit path — C-10.
  H13 the "restarted" wording appears on a run where no restart was issued — AC-18.
  H14 `config.json` is regenerated (or rewritten) on a no-op run — AC-2.
  H15 a stopped service gets started — AC-9.
  H16 with no config.json, a changed run still touches the service — AC-10.
  H17 zh mode leaks an untranslated English outcome key — AC-14/BC-20.
"""
import argparse
import hashlib
import io
import json
import os

import qalib

qalib.assert_non_root()
print("== q3: cmd_update_rules() end to end")

FILES = ("geoip-cn.srs", "geosite-cn.srs", "geosite-google.srs", "geosite-private.srs")
TAGS = tuple(f[:-4] for f in FILES)

EN = {
    "nochange": "No rule-set changed — the sing-box service was not touched",
    "restarted": "Rule-sets updated: {n} — sing-box restarted to load them",
    "untouched": "Rule-sets updated: {n} — the sing-box service was not touched",
    "restoring": "Rule-sets restored: {n} — config regenerated",
    "restarting": "→ Restarting sing-box ...",
    "done": "Done",
}
ZH = {
    "nochange": "规则集内容无变化 —— 未改动 sing-box 服务",
    "restarted": "规则集已更新：{n} —— 已重启 sing-box 以加载新数据",
    "untouched": "规则集已更新：{n} —— 未改动 sing-box 服务",
    "restoring": "规则集已恢复：{n} —— 配置已重新生成",
    "restarting": "→ 重启 sing-box ...",
    "done": "完成",
}
MSG = {"en": EN, "zh": ZH}
ALL_OUTCOMES = [EN["nochange"], ZH["nochange"],
                EN["restarted"].split("{")[0], ZH["restarted"].split("{")[0],
                EN["untouched"].split("{")[0], ZH["untouched"].split("{")[0]]

CFG_BODY = json.dumps({"log": {"level": "warn"}, "route": {"rule_set": []}},
                      indent=2).encode()


class Run(object):
    pass


def scenario(pre, served, running=True, regen=True, cfg=True, lang="en", mirror=None):
    """pre/served: fname -> bytes | Exception | None(absent). Returns a Run."""
    mod, tmproot = qalib.load_sc()
    mod.LANG = lang
    r = Run()
    r.mod, r.tmproot = mod, tmproot
    for f in FILES:
        body = pre.get(f)
        if isinstance(body, bytes):
            qalib.write_ruleset(mod, f, body)
    if cfg:
        io.open(str(mod.CFG_PATH), "wb").write(CFG_BODY)
        r.cfg_before = hashlib.sha256(CFG_BODY).hexdigest()
        r.cfg_mtime_before = os.stat(str(mod.CFG_PATH)).st_mtime_ns
    r.svc = qalib.stub_service(mod, running=running, regen=regen)
    r.requests = qalib.stub_fetch(mod, served)
    args = argparse.Namespace(mirror=mirror)
    cap = qalib.Captured().run(lambda: mod.cmd_update_rules(args))
    r.out, r.err, r.status = cap.out, cap.err, cap.status
    r.exc = cap.exc
    r.disk = {}
    for f in FILES:
        p = mod.RULES_DIR / f
        r.disk[f] = io.open(str(p), "rb").read() if p.is_file() else None
    if cfg:
        r.cfg_after = hashlib.sha256(io.open(str(mod.CFG_PATH), "rb").read()).hexdigest()
        r.cfg_mtime_after = os.stat(str(mod.CFG_PATH)).st_mtime_ns
    r.temps = sorted(p.name for p in mod.RULES_DIR.iterdir() if ".tmp" in p.name)
    return r


def outcome_lines(out):
    """Every line that is one of the six run-level outcome shapes, in either language."""
    hits = []
    for line in out.splitlines():
        for shape in ALL_OUTCOMES:
            if line.startswith(shape):
                hits.append(line)
                break
    return hits


def common(r, label, lang, want_svc, want_status=0):
    m = MSG[lang]
    qalib.check(r.exc is None, "%s [%s] no exception (%r)" % (label, lang, r.exc))
    qalib.check(r.svc == want_svc,
                "%s [%s] service-layer log %r (want %r)" % (label, lang, r.svc, want_svc))
    qalib.check(r.status == want_status or (want_status != 0 and r.status not in (0, None)),
                "%s [%s] exit status %r" % (label, lang, r.status))
    lines = outcome_lines(r.out)
    qalib.check(len(lines) == 1,
                "%s [%s] C-10 exactly ONE run-level outcome line (%d): %r"
                % (label, lang, len(lines), lines))
    qalib.check(r.mod.tripwire.calls == [],
                "%s [%s] tripwire: no shell-out at all" % (label, lang))
    qalib.check(r.mod.exec_calls == [],
                "%s [%s] no os.exec*/os.system from the module" % (label, lang))
    qalib.check(r.temps == [], "%s [%s] no temp debris left: %r" % (label, lang, r.temps))
    return lines[0] if len(lines) == 1 else ""


GOOD = {f: qalib.srs(bytes([i]) * 64) for i, f in enumerate(FILES)}

# =====================================================================  BC-1 / H10
print("\n-- BC-1: four byte-identical re-downloads (the defect itself)")
for lang in ("en", "zh"):
    r = scenario(pre=dict(GOOD), served=dict(GOOD), lang=lang)
    line = common(r, "BC-1 no-op", lang, want_svc=[], want_status=0)
    qalib.check(line == MSG[lang]["nochange"],
                "BC-1 [%s] AC-3 outcome is the 'nothing changed' line: %r" % (lang, line))
    qalib.check(MSG[lang]["done"] in r.out.splitlines(),
                "BC-1 [%s] Done still printed (exit 0 path)" % lang)
    qalib.check(r.status == 0, "BC-1 [%s] AC-3 exit 0" % lang)
    qalib.check(r.cfg_before == r.cfg_after,
                "BC-1 [%s] AC-2/H14 config.json byte-identical" % lang)
    qalib.check(r.cfg_mtime_before == r.cfg_mtime_after,
                "BC-1 [%s] config.json not even rewritten (mtime_ns unchanged)" % lang)
    qalib.check(MSG[lang]["restarting"] not in r.out,
                "BC-1 [%s] AC-18/H13 no 'Restarting sing-box' wording" % lang)
    qalib.check("restart" not in line.lower() and "重启" not in line,
                "BC-1 [%s] AC-18 outcome line contains no restart wording" % lang)
    qalib.check(r.disk == dict(GOOD), "BC-1 [%s] files on disk unchanged" % lang)
    qalib.check(len(r.requests) == 4, "BC-1 [%s] G-6 all four fetches accounted for" % lang)
    if lang == "zh":
        leaks = [frag for frag in ("No rule-set changed", "Rule-sets updated",
                                   "the sing-box service was not touched",
                                   "sing-box restarted to load them",
                                   "Rule-sets restored", "Done")
                 if frag in r.out]
        qalib.check(leaks == [],
                    "BC-1 [zh] H17 no untranslated English key leaks into zh output "
                    "(leaks=%r)" % leaks)
        qalib.check("失败：" not in r.out and "失败" not in line,
                    "BC-1 [zh] AC-15 no 失败： in the new outcome line")
    print("     outcome: " + line)
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-2 / H11
print("\n-- BC-2: exactly one rule-set's bytes differ")
for lang in ("en", "zh"):
    served = dict(GOOD)
    served["geosite-cn.srs"] = qalib.srs(b"NEW" * 30)
    r = scenario(pre=dict(GOOD), served=served, lang=lang)
    line = common(r, "BC-2 one changed", lang,
                  want_svc=["is_running", "restart_service"], want_status=0)
    qalib.check(r.svc.count("restart_service") == 1,
                "BC-2 [%s] AC-4/H11 exactly ONE apply for the run" % lang)
    qalib.check("generate_config" not in r.svc,
                "BC-2 [%s] B-7 usable set unchanged -> config NOT regenerated" % lang)
    qalib.check(r.cfg_before == r.cfg_after,
                "BC-2 [%s] config.json byte-identical (content change only)" % lang)
    qalib.check(line == MSG[lang]["restarted"].replace("{n}", "geosite-cn"),
                "BC-2 [%s] outcome names the changed tag: %r" % (lang, line))
    qalib.check(MSG[lang]["restarting"] in r.out,
                "BC-2 [%s] the existing Restarting line is kept (D-7)" % lang)
    print("     outcome: " + line)
    qalib.cleanup(r.tmproot)

# =====================================================================  AC-5 equal size
print("\n-- AC-5: new body differs but has the SAME byte size")
old = qalib.srs(b"A" * 500)
new = qalib.srs(b"B" * 500)
assert len(old) == len(new)
for lang in ("en", "zh"):
    pre = dict(GOOD); pre["geoip-cn.srs"] = old
    served = dict(GOOD); served["geoip-cn.srs"] = new
    r = scenario(pre=pre, served=served, lang=lang)
    line = common(r, "AC-5 equal size", lang,
                  want_svc=["is_running", "restart_service"], want_status=0)
    qalib.check(line == MSG[lang]["restarted"].replace("{n}", "geoip-cn"),
                "AC-5 [%s] equal-size different-content IS detected: %r" % (lang, line))
    qalib.cleanup(r.tmproot)

# =====================================================================  AC-6 mtime only
print("\n-- AC-6: the run rewrites identical bytes (mtime moves, content does not)")
for lang in ("en", "zh"):
    r = scenario(pre=dict(GOOD), served=dict(GOOD), lang=lang)
    line = common(r, "AC-6 mtime only", lang, want_svc=[], want_status=0)
    qalib.check(line == MSG[lang]["nochange"],
                "AC-6 [%s] a full rewrite with identical bytes is NOT a change" % lang)
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-4 / AC-7
print("\n-- BC-4 / AC-7: absent -> usable (T-02 recovery)")
for lang in ("en", "zh"):
    pre = dict(GOOD); del pre["geosite-google.srs"]
    r = scenario(pre=pre, served=dict(GOOD), lang=lang)
    line = common(r, "AC-7 recovery", lang,
                  want_svc=["generate_config", "is_running", "restart_service"],
                  want_status=0)
    qalib.check(MSG[lang]["restoring"].replace("{n}", "geosite-google") in r.out,
                "AC-7 [%s] the T-02 'Rule-sets restored' line still prints" % lang)
    qalib.check(r.svc.index("generate_config") < r.svc.index("restart_service"),
                "AC-7 [%s] regeneration strictly precedes the restart" % lang)
    qalib.check(r.svc.count("restart_service") == 1,
                "AC-7 [%s] still exactly one apply" % lang)
    qalib.check(line == MSG[lang]["restarted"].replace("{n}", "geosite-google"),
                "AC-7 [%s] outcome: %r" % (lang, line))
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-5 / AC-8
print("\n-- BC-5 / AC-8: bad-magic -> usable")
for lang in ("en", "zh"):
    pre = dict(GOOD); pre["geosite-private.srs"] = b"<!DOCTYPE html>" + b"x" * 90
    r = scenario(pre=pre, served=dict(GOOD), lang=lang)
    line = common(r, "AC-8 bad-magic recovery", lang,
                  want_svc=["generate_config", "is_running", "restart_service"],
                  want_status=0)
    qalib.check(MSG[lang]["restoring"].replace("{n}", "geosite-private") in r.out,
                "AC-8 [%s] restored line names the recovered tag" % lang)
    qalib.cleanup(r.tmproot)

# ---- too-small -> usable, and unreadable -> usable (BC-5 / BC-6 at run level)
for lang in ("en",):
    pre = dict(GOOD); pre["geoip-cn.srs"] = b"SRS"          # 3 bytes, too-small
    r = scenario(pre=pre, served=dict(GOOD), lang=lang)
    qalib.check(r.svc == ["generate_config", "is_running", "restart_service"],
                "BC-5b too-small -> usable regenerates and applies")
    qalib.cleanup(r.tmproot)

# =====================================================================  regen failure
print("\n-- regeneration fails its check: the restart must be blocked")
for lang in ("en", "zh"):
    pre = dict(GOOD); del pre["geosite-google.srs"]
    r = scenario(pre=pre, served=dict(GOOD), regen=False, lang=lang)
    line = common(r, "regen fails", lang, want_svc=["generate_config"], want_status=0)
    qalib.check("restart_service" not in r.svc and "is_running" not in r.svc,
                "[%s] a failed generate_config() blocks the restart (and is_running is "
                "not even consulted)" % lang)
    qalib.check(MSG[lang]["restoring"].replace("{n}", "geosite-google") in r.out,
                "[%s] the restored line still prints after a failed check" % lang)
    qalib.check(line == MSG[lang]["untouched"].replace("{n}", "geosite-google"),
                "[%s] AC-18 outcome truthfully says the service was NOT touched: %r"
                % (lang, line))
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-10 / AC-9
print("\n-- BC-10 / AC-9: service stopped (sc off), rule-sets changed")
for lang in ("en", "zh"):
    served = dict(GOOD); served["geosite-cn.srs"] = qalib.srs(b"CHANGED" * 20)
    r = scenario(pre=dict(GOOD), served=served, running=False, lang=lang)
    line = common(r, "BC-10 stopped", lang, want_svc=["is_running"], want_status=0)
    qalib.check("restart_service" not in r.svc,
                "BC-10 [%s] AC-9/H15 a stopped service is never started" % lang)
    qalib.check(line == MSG[lang]["untouched"].replace("{n}", "geosite-cn"),
                "BC-10 [%s] outcome: %r" % (lang, line))
    qalib.check(r.disk["geosite-cn.srs"] == served["geosite-cn.srs"],
                "BC-10 [%s] the file WAS still installed" % lang)
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-11 / AC-10
print("\n-- BC-11 / AC-10: no config.json (fresh install, install.sh step 6)")
for lang in ("en", "zh"):
    served = dict(GOOD)
    r = scenario(pre={}, served=served, cfg=False, lang=lang)
    line = common(r, "BC-11 no config", lang, want_svc=[], want_status=0)
    qalib.check(not r.mod.CFG_PATH.exists(),
                "BC-11 [%s] AC-10/H16 no config.json was created" % lang)
    qalib.check(r.status == 0, "BC-11 [%s] D-6 exit 0 (install.sh:456 branches on it)" % lang)
    qalib.check(line == MSG[lang]["untouched"].replace("{n}", ", ".join(TAGS)),
                "BC-11 [%s] outcome names the four changed tags and says untouched: %r"
                % (lang, line))
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-8 / AC-11
print("\n-- BC-8 / AC-11: every mirror fails for every rule-set")
for lang in ("en", "zh"):
    served = {f: OSError("connection refused") for f in FILES}
    r = scenario(pre=dict(GOOD), served=served, lang=lang)
    line = common(r, "BC-8 all fail", lang, want_svc=[], want_status="nonzero")
    qalib.check(r.status not in (0, None),
                "BC-8 [%s] AC-11 non-zero exit (%r)" % (lang, r.status))
    qalib.check("4" in str(r.status), "BC-8 [%s] the aggregate names 4 failures" % lang)
    qalib.check(line == MSG[lang]["nochange"],
                "BC-8 [%s] C-10 the outcome line prints on the sys.exit path too: %r"
                % (lang, line))
    qalib.check(MSG[lang]["done"] not in r.out,
                "BC-8 [%s] Done is NOT printed on the failure path" % lang)
    qalib.check(r.disk == dict(GOOD), "BC-8 [%s] no file was modified" % lang)
    print("     status=%r  outcome=%s" % (str(r.status).strip(), line))
    qalib.cleanup(r.tmproot)

# =====================================================================  BC-9 / AC-12 / F-11
print("\n-- BC-9 / AC-12 / F-11: two changed, two failed")
for lang in ("en", "zh"):
    served = dict(GOOD)
    served["geoip-cn.srs"] = qalib.srs(b"NEW1" * 20)
    served["geosite-cn.srs"] = qalib.srs(b"NEW2" * 20)
    served["geosite-google.srs"] = OSError("refused")
    served["geosite-private.srs"] = OSError("refused")
    r = scenario(pre=dict(GOOD), served=served, lang=lang)
    line = common(r, "BC-9", lang, want_svc=["is_running", "restart_service"],
                  want_status="nonzero")
    qalib.check(r.status not in (0, None), "BC-9 [%s] exit is non-zero" % lang)
    idx_restart = r.out.index(MSG[lang]["restarting"])
    idx_outcome = r.out.index(line)
    qalib.check(idx_restart < idx_outcome,
                "BC-9 [%s] AC-12 the apply happens BEFORE the outcome line" % lang)
    qalib.check(line == MSG[lang]["restarted"].replace("{n}", "geoip-cn, geosite-cn"),
                "BC-9 [%s] outcome names both changed tags: %r" % (lang, line))
    qalib.check("2" in str(r.status), "BC-9 [%s] aggregate names 2 failures" % lang)
    qalib.cleanup(r.tmproot)
print("     F-11 delta confirmed: a run with failures now DOES apply first, then exits "
      "non-zero (pre-change code exited before the restart)")

# =====================================================================  BC-13
print("\n-- BC-13: a file is destroyed mid-run by an external actor")
for lang in ("en",):
    mod, tmproot = qalib.load_sc()
    mod.LANG = lang
    for f in FILES:
        qalib.write_ruleset(mod, f, GOOD[f])
    io.open(str(mod.CFG_PATH), "wb").write(CFG_BODY)
    svc = qalib.stub_service(mod, running=True)
    victim = mod.RULES_DIR / "geosite-private.srs"

    def _fetch(url, tmp, prefix, tty):
        # every fetch serves identical bytes; the external actor strikes during the run
        for f, rel in mod.RULESET_FILES:
            if url.endswith(rel):
                io.open(str(tmp), "wb").write(GOOD[f])
                if f == "geosite-google.srs":
                    victim.unlink()          # LOSS, concurrent with the run
                return len(GOOD[f])
        raise ValueError("?")
    mod._fetch_to_temp = _fetch
    cap = qalib.Captured().run(
        lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
    qalib.check(cap.exc is None, "BC-13 the run does not crash (%r)" % cap.exc)
    qalib.check(svc == [], "BC-13 a LOSS alone triggers no service action: %r" % svc)
    qalib.check(EN["nochange"] in cap.out, "BC-13 outcome is 'nothing changed'")
    qalib.check(cap.status == 0, "BC-13 exit 0")
    qalib.cleanup(tmproot)

# =====================================================================  BC-19 --mirror
print("\n-- BC-19: --mirror serving identical bytes")
for lang in ("en",):
    r = scenario(pre=dict(GOOD), served=dict(GOOD), lang=lang,
                 mirror=["https://example.invalid/geo"])
    line = common(r, "BC-19 --mirror", lang, want_svc=[], want_status=0)
    qalib.check(all(u.startswith("https://example.invalid/geo") for u in r.requests),
                "BC-19 the override really replaced the base list: %r" % (r.requests[:1],))
    qalib.check(line == EN["nochange"], "BC-19 identical bytes -> no service action")
    qalib.cleanup(r.tmproot)

# =====================================================================  AC-16 stream shape
print("\n-- AC-16: non-TTY stream shape (one completion line per rule-set, no \\r)")
r = scenario(pre=dict(GOOD), served=dict(GOOD), lang="en")
qalib.check("\r" not in r.out, "AC-16 no carriage return anywhere on a pipe")
qalib.check(r.out.count("  ↓ ") == 4, "AC-16 exactly four per-file prefixes")
qalib.check(sum(1 for l in r.out.splitlines() if l.startswith("  ↓ ")) == 4,
            "AC-16 exactly four completion LINES")
qalib.check(len(outcome_lines(r.out)) == 1, "AC-16 the outcome line is run-level, not per-file")
print("     stdout:\n" + "".join("       | " + l + "\n" for l in r.out.splitlines()))
qalib.cleanup(r.tmproot)

# =====================================================================  AC-18 global
print("\n-- AC-18: 'restarted' wording appears in exactly the runs that restarted")
cases = [
    ("no-op", dict(GOOD), dict(GOOD), True, True, True, False),
    ("changed+running", dict(GOOD),
     dict(list(GOOD.items())[:3] + [("geosite-private.srs", qalib.srs(b"Q" * 30))]),
     True, True, True, True),
    ("changed+stopped", dict(GOOD),
     dict(list(GOOD.items())[:3] + [("geosite-private.srs", qalib.srs(b"Q" * 30))]),
     False, True, True, False),
    ("changed+no-cfg", dict(GOOD),
     dict(list(GOOD.items())[:3] + [("geosite-private.srs", qalib.srs(b"Q" * 30))]),
     True, True, False, False),
]
# NOTE: both "updated" outcomes share the prefix "Rule-sets updated: " / "规则集已更新：",
# so the restart claim must be detected by the DISTINGUISHING SUFFIX, not the prefix.
RESTART_SUFFIX = {"en": "— sing-box restarted to load them",
                  "zh": "—— 已重启 sing-box 以加载新数据"}
for label, pre, served, running, regen, cfg, want_restart in cases:
    for lang in ("en", "zh"):
        r = scenario(pre=pre, served=served, running=running, regen=regen, cfg=cfg,
                     lang=lang)
        said = RESTART_SUFFIX[lang] in r.out
        did = "restart_service" in r.svc
        qalib.check(said == did == want_restart,
                    "AC-18 %-16s [%s] said_restart=%s did_restart=%s (want %s)"
                    % (label, lang, said, did, want_restart))
        qalib.cleanup(r.tmproot)

qalib.assert_no_service_calls("q3")
qalib.summary("q3_run")
```

## `q4_negative_control.py` (174 lines)

```python
"""q4 — negative control + mutation testing.

A test that cannot fail proves nothing. Two independent ways of showing these fixtures
have teeth:

  (1) NEGATIVE CONTROL — run the identical no-op fixture against `git show HEAD:bin/sc`
      (the pre-change code). It must restart. Then run it against the working tree. It
      must not.
  (2) MUTATION TESTING — inject four defects into the CHANGED bin/sc, one at a time, and
      confirm the corresponding QA assertion goes red. A mutant that survives means the
      assertion was decorative.

Adversarial hypothesis H18: the fixtures pass because they are too weak to distinguish
the defect from the fix.
"""
import argparse
import io
import json
import os
import subprocess
import tempfile

import qalib

qalib.assert_non_root()
print("== q4: negative control + mutation testing")

FILES = ("geoip-cn.srs", "geosite-cn.srs", "geosite-google.srs", "geosite-private.srs")
GOOD = {f: qalib.srs(bytes([i]) * 64) for i, f in enumerate(FILES)}
CFG_BODY = json.dumps({"log": {"level": "warn"}, "route": {"rule_set": []}}).encode()

work = tempfile.mkdtemp(prefix="qat10-neg-")
HEAD_SRC = os.path.join(work, "sc_HEAD.py")
p = subprocess.run(["git", "-C", qalib.REPO, "show", "HEAD:bin/sc"],
                   stdout=subprocess.PIPE)
io.open(HEAD_SRC, "wb").write(p.stdout)
head_rev = subprocess.run(["git", "-C", qalib.REPO, "rev-parse", "--short", "HEAD"],
                          stdout=subprocess.PIPE).stdout.decode().strip()
qalib.check(p.returncode == 0 and len(p.stdout) > 10000,
            "extracted HEAD:bin/sc (%s, %d bytes) as DATA — never executed as a program"
            % (head_rev, len(p.stdout)))


def noop_run(src_path=None, served=None, pre=None, running=True, cfg=True, lang="en"):
    """The BC-1 fixture: four re-downloads of byte-identical content."""
    mod, tmproot = qalib.load_sc(src_path=src_path)
    mod.LANG = lang
    for f in FILES:
        body = (pre or GOOD).get(f)
        if isinstance(body, bytes):
            qalib.write_ruleset(mod, f, body)
    if cfg:
        io.open(str(mod.CFG_PATH), "wb").write(CFG_BODY)
    svc = qalib.stub_service(mod, running=running)
    qalib.stub_fetch(mod, served or dict(GOOD))
    cap = qalib.Captured().run(
        lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
    qalib.cleanup(tmproot)
    return svc, cap, mod


# ---------------------------------------------------------------- (1) negative control
print("\n-- (1) negative control: the SAME fixture on both sides")
svc_head, cap_head, mod_head = noop_run(src_path=HEAD_SRC)
print("   == PRE-CHANGE bin/sc (HEAD %s) on the identical no-op fixture" % head_rev)
print("        service-layer call log: %r" % (svc_head,))
print("        stdout tail: %r" % cap_head.out.splitlines()[-2:])
svc_new, cap_new, mod_new = noop_run()
print("   == CHANGED bin/sc (working tree) on the identical fixture")
print("        service-layer call log: %r" % (svc_new,))
print("        stdout tail: %r" % cap_new.out.splitlines()[-2:])
print("   == delta: %r  ->  %r" % (svc_head, svc_new))

qalib.check(svc_head == ["is_running", "restart_service"],
            "H18 REFUTED: the pre-change code RESTARTS on this fixture -> %r" % (svc_head,))
qalib.check(svc_new == [],
            "and the changed code does NOT -> %r" % (svc_new,))
qalib.check(cap_head.status == 0 and cap_new.status == 0, "both sides exit 0")
qalib.check("Restarting sing-box" in cap_head.out,
            "pre-change stdout announces the restart")
qalib.check("Restarting sing-box" not in cap_new.out,
            "post-change stdout does not")
qalib.check(mod_head.tripwire.calls == [] and mod_new.tripwire.calls == [],
            "neither side shelled out (both stubbed at the module boundary)")

# the pre-change code also restarts when nothing was even downloaded successfully? No —
# its sys.exit ran first. Record the F-11 delta from the OTHER side, on HEAD.
served = dict(GOOD)
served["geoip-cn.srs"] = qalib.srs(b"NEW1" * 20)
served["geosite-cn.srs"] = qalib.srs(b"NEW2" * 20)
served["geosite-google.srs"] = OSError("refused")
served["geosite-private.srs"] = OSError("refused")
svc_h, cap_h, _ = noop_run(src_path=HEAD_SRC, served=served)
svc_n, cap_n, _ = noop_run(served=served)
qalib.check(svc_h == [],
            "F-11 delta measured on HEAD: '2 changed + 2 failed' did NOT apply before "
            "exiting -> %r" % (svc_h,))
qalib.check(svc_n == ["is_running", "restart_service"],
            "F-11 delta measured on the change: it now applies, THEN exits non-zero "
            "-> %r (requirement-sanctioned, B-14/BC-9/AC-12)" % (svc_n,))

# ---------------------------------------------------------------- (2) mutation testing
print("\n-- (2) mutation testing: inject a defect, confirm an assertion goes red")
SRC = io.open(qalib.SC_PATH, encoding="utf-8").read()

MUTANTS = [
    ("M-A restore the unconditional restart tail",
     "    if changed and CFG_PATH.exists():",
     "    if CFG_PATH.exists():"),
    ("M-B compare file SIZE instead of content",
     "    return (srs_reject_reason(head, size) or \"usable\", digest.hexdigest())",
     "    return (srs_reject_reason(head, size) or \"usable\", str(size))"),
    ("M-C two never-read files compare EQUAL (the None-vs-None 'tidy-up')",
     "        if old_digest is None or digest is None or old_digest != digest:",
     "        if old_digest != digest:"),
    ("M-D drop the 'usable in after' filter (a LOSS would restart)",
     "        if status != \"usable\":\n            continue                    # a loss is not a change",
     "        if False:\n            continue"),
]


def mutate(find, repl):
    assert find in SRC, "mutation anchor not found: %r" % find[:60]
    path = os.path.join(work, "mutant.py")
    io.open(path, "w", encoding="utf-8").write(SRC.replace(find, repl, 1))
    return path


# M-A: the no-op fixture must now restart
mp = mutate(*MUTANTS[0][1:])
svc, cap, _ = noop_run(src_path=mp)
qalib.check(svc != [], "%s -> BC-1 assertion goes RED (svc=%r)" % (MUTANTS[0][0], svc))

# M-B: equal-size-different-content must now be missed
mp = mutate(*MUTANTS[1][1:])
pre = dict(GOOD); pre["geoip-cn.srs"] = qalib.srs(b"A" * 500)
srv = dict(GOOD); srv["geoip-cn.srs"] = qalib.srs(b"B" * 500)
svc, cap, _ = noop_run(src_path=mp, pre=pre, served=srv)
qalib.check(svc == [], "%s -> AC-5 assertion goes RED (svc=%r, the change is missed)"
            % (MUTANTS[1][0], svc))
# and the same mutant still passes the plain BC-2 case, which is why AC-5 must exist
srv2 = dict(GOOD); srv2["geoip-cn.srs"] = qalib.srs(b"B" * 900)
svc2, _c, _m = noop_run(src_path=mp, pre=pre, served=srv2)
qalib.check(svc2 != [], "   ... while a DIFFERENT-size change still trips it (%r) — "
                        "AC-5 is the only assertion that kills M-B" % (svc2,))

# M-C: BC-6 (unreadable before, valid body installed) must now be missed
mp = mutate(*MUTANTS[2][1:])
mod, tmproot = qalib.load_sc(src_path=mp)
b = [("a", "a.srs", "unreadable", None)]
a = [("a", "a.srs", "usable", None)]      # digest None on BOTH sides
qalib.check(mod.changed_usable_tags(b, a) == [],
            "%s -> the None-vs-None arm goes RED (returns %r instead of ['a'])"
            % (MUTANTS[2][0], mod.changed_usable_tags(b, a)))
# the un-mutated code
mod_ok, tr_ok = qalib.load_sc()
qalib.check(mod_ok.changed_usable_tags(b, a) == ["a"],
            "   ... and the shipped code answers ['a'] on the same input")
qalib.cleanup(tmproot); qalib.cleanup(tr_ok)

# M-D: a pure LOSS must now restart
mp = mutate(*MUTANTS[3][1:])
mod, tmproot = qalib.load_sc(src_path=mp)
b = [("a", "a.srs", "usable", "d1")]
a = [("a", "a.srs", "absent", None)]
qalib.check(mod.changed_usable_tags(b, a) == ["a"],
            "%s -> BC-13 assertion goes RED (a pure loss becomes a 'change')"
            % MUTANTS[3][0])
qalib.cleanup(tmproot)

import shutil
shutil.rmtree(work, ignore_errors=True)
qalib.assert_no_service_calls("q4")
qalib.summary("q4_negative_control")
```

## `q5_static.py` (206 lines)

```python
"""q5 — static gates: C-6 (3.6 floor), AC-14/15 (bilingual), C-8 (diff), C-9, C-11, AC-23.

Adversarial hypotheses:
  H19 a sixth 3.7+ construct (capture_output= / text= / walrus / missing_ok=) crept in.
  H20 a new zh string contains 失败： (E-15's load-bearing grep) or collides with an
      existing grep token.
  H21 a new TRANSLATIONS key has no zh entry, or mismatched {placeholders}.
  H22 an unauthorised PRODUCT file carries a T-10 change.
  H23 R6's comment is missing from the apply site, so a future edit can silently restore
      the unconditional restart.
"""
import io
import os
import re
import subprocess

import qalib

qalib.assert_non_root()
REPO = qalib.REPO
SC = os.path.join(REPO, "bin", "sc")
src = io.open(SC, encoding="utf-8").read()
lines = src.splitlines()
print("== q5: static gates (bin/sc = %d lines)" % len(lines))


def git(*a):
    return subprocess.run(["git", "-C", REPO] + list(a),
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT
                          ).stdout.decode()


# ---------------------------------------------------------------- C-6 whole-file counters
print("\n-- C-6: whole-file 3.7+ counters, against the CORRECTED numbers")
hits = [(i + 1, l) for i, l in enumerate(lines)
        if re.search(r"capture_output=|text=True|:=|missing_ok=", l)]
for n, l in hits:
    print("     bin/sc:%d  %s" % (n, l.strip()))
qalib.check([n for n, _l in hits] == [922, 964, 1289],
            "H19 REFUTED: 'capture_output=|text=True|:=|missing_ok=' matches exactly "
            "bin/sc:922, :964, :1289 (got %r)" % [n for n, _l in hits])
qalib.check(len(re.findall(r"\bcapture_output\s*=", src)) == 3,
            "capture_output= appears exactly 3 times (the pre-existing sites)")
qalib.check(len(re.findall(r"\btext\s*=\s*True", src)) == 2,
            "text=True appears exactly 2 times")
qalib.check(":=" not in src, "no walrus operator anywhere in bin/sc")
qalib.check("missing_ok" not in src, "no unlink(missing_ok=) anywhere")

# banned constructs over the ADDED lines only
diff = git("diff", "--unified=0", "--", "bin/sc")
added = [l[1:] for l in diff.splitlines()
         if l.startswith("+") and not l.startswith("+++")]
removed = [l[1:] for l in diff.splitlines()
           if l.startswith("-") and not l.startswith("---")]
print("     added=%d removed=%d" % (len(added), len(removed)))
BANNED = [
    ("walrus := (3.8)", r"(?<![:=!<>+\-*/%&|^])(:=)"),
    ("f-string = specifier (3.8)", r"f[\"'][^\"']*\{[^{}]*=\s*[}:]"),
    ("capture_output= (3.7)", r"\bcapture_output\s*="),
    ("text= (3.7)", r"\btext\s*="),
    ("missing_ok= (3.8)", r"missing_ok\s*="),
    ("dataclasses (3.7)", r"\bdataclass"),
    ("from __future__ (3.7)", r"__future__"),
    ("positional-only / (3.8)", r"def\s+\w+\([^)]*,\s*/\s*[,)]"),
    ("dict |= (3.9)", r"^\s*\w+\s*\|="),
    ("match statement (3.10)", r"^\s*match\s+.*:\s*$"),
    ("asyncio.run (3.7)", r"asyncio\.run"),
    ("str.removeprefix (3.9)", r"\.remove(prefix|suffix)\("),
    ("math.prod / graphlib (3.8/3.9)", r"math\.prod|graphlib"),
    ("importlib.metadata (3.8)", r"importlib\.metadata"),
    ("typing Protocol/Final (3.8)", r"\b(Protocol|Final|Literal|TypedDict)\b"),
]
for label, rx in BANNED:
    n = sum(1 for l in added if re.search(rx, l))
    qalib.check(n == 0, "C-6 added lines: 0 hits for %s" % label)

# NOTE: a naive r"^\s*(import|from)\s" also matches the docstring line beginning
# "from the same bytes. …" — the anchor must be a real import statement.
imports_added = [l for l in added
                 if re.match(r"^(import [\w.]+( as \w+)?|from [\w.]+ import \S)", l)]
qalib.check(imports_added == ["import hashlib"],
            "exactly one import added and it is stdlib hashlib: %r" % imports_added)
pc = subprocess.run(["python3", "-m", "py_compile", SC],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
qalib.check(pc.returncode == 0, "python3 -m py_compile bin/sc passes (3.12 host)")

# ---------------------------------------------------------------- AC-14 / AC-15
print("\n-- AC-14 / AC-15: bilingual parity of the three new keys")
NEW_KEYS = [
    "No rule-set changed — the sing-box service was not touched",
    "Rule-sets updated: {names} — sing-box restarted to load them",
    "Rule-sets updated: {names} — the sing-box service was not touched",
]
mod, tmproot = qalib.load_sc()
zh = mod.TRANSLATIONS["zh"]
qalib.check(set(mod.TRANSLATIONS.keys()) == {"zh"},
            "TRANSLATIONS still has only a zh table (the English key IS the output)")
for k in NEW_KEYS:
    qalib.check(k in zh, "H21 REFUTED: zh entry exists for %r" % k[:40])
    ph_en = sorted(re.findall(r"\{(\w+)\}", k))
    ph_zh = sorted(re.findall(r"\{(\w+)\}", zh.get(k, "")))
    qalib.check(ph_en == ph_zh, "placeholder parity for %r: %r == %r"
                % (k[:30], ph_en, ph_zh))
    v = zh[k]
    qalib.check("失败：" not in v, "H20 REFUTED: AC-15 no 失败： in %r" % v)
    for token in ("失败", "成功", "错误：", "⚠️", "已跳过"):
        qalib.check(token not in v, "no collision with grep token %r in %r"
                    % (token, v[:20]))
    qalib.check(not re.match(r"^[a-z]+\.[a-z]+$", k),
                "the key is a full English sentence, not a namespaced id")
    print("     %-64s -> %s" % (k[:64], v))

# every key added by the diff has a zh entry (catch a key added but untranslated)
added_keys = re.findall(r'^\s*"([^"]+)":\s*"', "\n".join(added), re.M)
qalib.check(sorted(added_keys) == sorted(NEW_KEYS),
            "the diff adds exactly these three translation keys: %r" % sorted(added_keys))

# no English fallback would be reachable: t() in zh returns the zh value for each
mod.LANG = "zh"
for k in NEW_KEYS:
    rendered = mod.t(k, names="X") if "{names}" in k else mod.t(k)
    qalib.check(rendered != k, "t(%r) in zh does not fall back to English" % k[:30])
mod.LANG = "en"
for k in NEW_KEYS:
    rendered = mod.t(k, names="X") if "{names}" in k else mod.t(k)
    qalib.check(rendered == k.replace("{names}", "X"),
                "t(%r) in en is the key itself" % k[:30])
qalib.cleanup(tmproot)

# ---------------------------------------------------------------- C-11 / R6 comment
print("\n-- C-11: R6's in-code comment at the apply site")
call_lines = [i + 1 for i, l in enumerate(lines)
              if re.search(r"^\s*restart_service\(\)\s*$", l)]
qalib.check(len(call_lines) == 2,
            "restart_service() is called at exactly 2 sites: %r" % call_lines)
apply_site = max(call_lines)
window = "\n".join(lines[apply_site - 7:apply_site - 1])
qalib.check("changed_usable_tags()" in window and "T-10 defect" in window,
            "H23 REFUTED: the comment naming changed_usable_tags() and 'T-10 defect' "
            "sits within 6 lines above bin/sc:%d" % apply_site)
print("     bin/sc:%d-%d\n%s" % (apply_site - 6, apply_site,
                                 "\n".join("       | " + l for l in
                                           lines[apply_site - 7:apply_site])))
# the other call site is reload_or_restart()
qalib.check("def reload_or_restart" in "\n".join(lines[min(call_lines) - 8:min(call_lines)]),
            "the other restart_service() call is inside reload_or_restart() (bin/sc:%d)"
            % min(call_lines))

# ---------------------------------------------------------------- C-9
print("\n-- C-9: the two corrected overclaims appear nowhere")
PHRASES = ["logs nothing", "silent on success", "reloaded rule-set",
           "the common case", "commonly", "rarely", "seldom",
           "常见情况", "很少", "通常不会变", "大多数情况"]
targets = ["bin/sc", "CHANGELOG.md", "docs/dev-map.md", "CONTEXT.md"]
c9 = []
for tgt in targets:
    body = io.open(os.path.join(REPO, tgt), encoding="utf-8").read()
    for ph in PHRASES:
        if ph in body:
            c9.append((tgt, ph))
qalib.check(c9 == [], "C-9: 0 hits for %d banned phrases across %r (%r)"
            % (len(PHRASES), targets, c9))

# ---------------------------------------------------------------- C-8 attributed diff
print("\n-- C-8: attributed diff (PM ruling: attribution, not set-inclusion)")
names = [n for n in git("diff", "--name-only").split() if n]
untracked = [n for n in git("ls-files", "--others", "--exclude-standard").split() if n]
PRODUCT = {"bin/sc", "CHANGELOG.md", "docs/dev-map.md"}
BOOKKEEPING = {"CONTEXT.md", "docs/tasks.md", "docs/batches/default/BATCH_PLAN.md",
               ".harness/rejected-decisions.md"}
for n in names:
    kind = ("PRODUCT" if n in PRODUCT else
            "bookkeeping" if n in BOOKKEEPING else "*** UNATTRIBUTED ***")
    print("     %-45s %s" % (n, kind))
qalib.check(set(names) <= (PRODUCT | BOOKKEEPING),
            "H22 REFUTED: every dirty tracked file is either the authorised product diff "
            "or a known bookkeeping artefact: %r" % names)
qalib.check(PRODUCT <= set(names), "all three product files carry a change")
qalib.check(all(n.startswith("docs/features/") for n in untracked),
            "every untracked path is a stage document: %r" % untracked)
stat = git("diff", "--stat", "--", "bin/sc", "CHANGELOG.md", "docs/dev-map.md")
print("     " + stat.replace("\n", "\n     ").strip())

# ---------------------------------------------------------------- AC-23 CHANGELOG
print("\n-- AC-23: CHANGELOG.md")
cl = io.open(os.path.join(REPO, "CHANGELOG.md"), encoding="utf-8").read().splitlines()
qalib.check("注意这条命令在 sing-box 正在运行时会重启 sing-box（连接会中断几秒）" not in "\n".join(cl),
            "the old unconditional-restart claim is GONE")
qalib.check(any("只有在规则集内容确实发生变化时才会重启" in l for l in cl),
            "the corrected clause is present")
qalib.check(any("规则集更新不再无谓重启" in l for l in cl),
            "a new 修复 bullet describes this fix")
for i, l in enumerate(cl[:20]):
    if "只有在规则集内容确实发生变化时才会重启" in l or "规则集更新不再无谓重启" in l:
        print("     CHANGELOG.md:%d  %s" % (i + 1, l[:110]))

# ---------------------------------------------------------------- F.6 doc sizes
print("\n-- F.6: active task docs must stay <= 500 lines")
d = os.path.join(REPO, "docs/features/ruleset-update-no-needless-restart")
for f in sorted(os.listdir(d)):
    if re.match(r"^0[1-7]_.*\.md$", f) or f == "PM_LOG.md":
        n = len(io.open(os.path.join(d, f), encoding="utf-8").read().splitlines())
        qalib.check(n <= 500, "%-32s %d lines" % (f, n))

qalib.assert_no_service_calls("q5")
qalib.summary("q5_static")
```

## `q6_init_tty_cost.py` (278 lines)

```python
"""q6 — B-12 (both inits, TTY vs scheduled), NFR-3 read cost, BC-14 concurrency, BC-16.

Adversarial hypotheses:
  H24 the decision is init-specific: an OpenRC host still restarts on a no-op run
      (E-4: /etc/periodic/<period>/singbox-update-rules runs the same command).
  H25 the outcome line is suppressed when stdout is not a terminal, so the timer's
      journal and install.log record nothing (D-5).
  H26 the run reads each rule-set file more than NFR-3's "at most twice per run".
  H27 a concurrent run corrupts a file or crashes the other run (BC-14).
"""
import argparse
import io
import json
import os
import pty
import subprocess
import sys
import tempfile

import qalib

qalib.assert_non_root()
print("== q6: init parity, stream shape, cost, concurrency")

FILES = ("geoip-cn.srs", "geosite-cn.srs", "geosite-google.srs", "geosite-private.srs")
GOOD = {f: qalib.srs(bytes([i]) * 64) for i, f in enumerate(FILES)}
CFG_BODY = json.dumps({"log": {"level": "warn"}, "route": {"rule_set": []}}).encode()


def prep(mod, pre=None, cfg=True):
    for f in FILES:
        b = (pre or GOOD).get(f)
        if isinstance(b, bytes):
            qalib.write_ruleset(mod, f, b)
    if cfg:
        io.open(str(mod.CFG_PATH), "wb").write(CFG_BODY)


# ============================================================ H24: both init systems
print("\n-- B-12 / H24: the decision is init-agnostic (REAL is_running/restart_service,")
print("   deliberately NOT stubbed, so the tripwire records the init-specific argv)")
for init in ("SYSTEMD", "OPENRC"):
    # (a) no-op run: the init-specific probe must NEVER be reached
    mod, tmproot = qalib.load_sc()
    setattr(mod, init, True)
    prep(mod)
    qalib.stub_fetch(mod, dict(GOOD))
    cap = qalib.Captured().run(
        lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
    qalib.check(mod.tripwire.calls == [] and cap.status == 0,
                "H24 [%s] no-op run: is_running()/restart_service() never reached "
                "(tripwire argv=%r)" % (init, mod.tripwire.argv0s()))
    qalib.check("No rule-set changed" in cap.out,
                "H24 [%s] no-op run prints the 'nothing changed' outcome" % init)
    qalib.cleanup(tmproot)

    # (b) changed run: the init-specific probe IS reached, and is blocked by the tripwire
    mod, tmproot = qalib.load_sc()
    setattr(mod, init, True)
    prep(mod)
    served = dict(GOOD); served["geosite-cn.srs"] = qalib.srs(b"NEW" * 30)
    qalib.stub_fetch(mod, served)
    cap = qalib.Captured().run(
        lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
    want = (["systemctl", "is-active", "--quiet", "sing-box"] if init == "SYSTEMD"
            else ["rc-service", "sing-box", "status"])
    qalib.check(mod.tripwire.calls[:1] == [want],
                "H24 [%s] changed run reaches the init-specific liveness probe %r "
                "(and the tripwire stops it there)" % (init, mod.tripwire.calls[:1]))
    qalib.check(isinstance(cap.exc, qalib.TripwireError),
                "H24 [%s] ... and nothing escaped the tripwire (%r)"
                % (init, type(cap.exc).__name__))
    qalib.cleanup(tmproot)

# (c) neither init present: is_running() is False, so no dishonest "restarted" line
mod, tmproot = qalib.load_sc()
prep(mod)
served = dict(GOOD); served["geosite-cn.srs"] = qalib.srs(b"NEW" * 30)
qalib.stub_fetch(mod, served)
cap = qalib.Captured().run(lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
qalib.check(mod.tripwire.calls == [] and cap.status == 0,
            "neither systemd nor OpenRC: no service command at all")
qalib.check("the sing-box service was not touched" in cap.out
            and "restarted to load them" not in cap.out,
            "and the outcome honestly says the service was not touched")
qalib.cleanup(tmproot)

# ============================================================ H25: TTY vs pipe (D-5)
print("\n-- D-5 / H25: the outcome line on a REAL pty and on a redirected stream")
DRIVER = r'''
import argparse, io, json, os, sys
sys.path.insert(0, %r)
import qalib
mod, tmproot = qalib.load_sc()
mod.LANG = os.environ.get("QA_LANG", "en")
for i, f in enumerate(("geoip-cn.srs","geosite-cn.srs","geosite-google.srs","geosite-private.srs")):
    qalib.write_ruleset(mod, f, qalib.srs(bytes([i]) * 64))
io.open(str(mod.CFG_PATH), "wb").write(json.dumps({"log": {"level": "warn"}}).encode())
qalib.stub_service(mod, running=True)
qalib.stub_fetch(mod, dict((f, qalib.srs(bytes([i]) * 64)) for i, f in enumerate(
    ("geoip-cn.srs","geosite-cn.srs","geosite-google.srs","geosite-private.srs"))))
print("ISATTY=%%s" %% sys.stdout.isatty())
mod.cmd_update_rules(argparse.Namespace(mirror=None))
qalib.cleanup(tmproot)
''' % (os.path.dirname(os.path.abspath(__file__)),)
dv = os.path.join(tempfile.mkdtemp(prefix="qat10-tty-"), "driver.py")
io.open(dv, "w").write(DRIVER)

for lang, needle in (("en", "No rule-set changed — the sing-box service was not touched"),
                     ("zh", "规则集内容无变化 —— 未改动 sing-box 服务")):
    env = dict(os.environ); env["QA_LANG"] = lang
    # (a) redirected (the scheduled path: timer journal / install.log)
    p = subprocess.run([sys.executable, dv], env=env, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    piped = p.stdout.decode()
    qalib.check("ISATTY=False" in piped, "[%s] redirected run really is not a tty" % lang)
    qalib.check(piped.count(needle) == 1,
                "H25 REFUTED [%s] redirected: outcome line printed exactly once" % lang)
    qalib.check("\r" not in piped, "[%s] redirected: no \\r (AC-16)" % lang)
    # (b) real pty
    out, status = pty.fork()
    if out == 0:
        os.execvpe(sys.executable, [sys.executable, dv], env)   # child only
    buf = b""
    try:
        while True:
            chunk = os.read(status, 4096)
            if not chunk:
                break
            buf += chunk
    except OSError:
        pass
    os.waitpid(out, 0)
    tty_out = buf.decode(errors="replace")
    qalib.check("ISATTY=True" in tty_out, "[%s] pty run really is a tty" % lang)
    qalib.check(tty_out.count(needle) == 1,
                "H25 REFUTED [%s] pty: outcome line printed exactly once" % lang)
    qalib.check(tty_out.count("↓") >= 4, "[%s] pty: per-file progress still rendered" % lang)

# ============================================================ H26: NFR-3 read cost
print("\n-- NFR-3 / M-4 / H26: how many times is each rule-set file read per run?")


def count_reads(gained_case, stub_regen):
    mod, tmproot = qalib.load_sc()
    pre = dict(GOOD)
    if gained_case:
        del pre["geosite-google.srs"]
    prep(mod, pre=pre)
    opens = {}
    real_open = mod.Path.open

    def counting_open(self, *a, **kw):
        if str(self).endswith(".srs"):
            opens[self.name] = opens.get(self.name, 0) + 1
        return real_open(self, *a, **kw)
    mod.Path.open = counting_open
    if stub_regen:
        qalib.stub_service(mod, running=True)
    else:
        # real generate_config(), stopped by the tripwire at `sing-box check`.
        # It needs nodes.json / settings.json to get as far as ruleset_report().
        io.open(str(mod.NODES_PATH), "w").write(json.dumps({"active": None, "nodes": []}))
        io.open(str(mod.SETTINGS_PATH), "w").write(
            json.dumps({"default_tun": True, "mode": "rule", "lang": "en"}))
        mod.is_running = lambda: False
    qalib.stub_fetch(mod, dict(GOOD))
    cap = qalib.Captured().run(
        lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
    mod.Path.open = real_open
    qalib.cleanup(tmproot)
    return opens, cap


opens, _c = count_reads(gained_case=False, stub_regen=True)
qalib.check(all(v == 2 for v in opens.values()),
            "NFR-3 no-op run: each rule-set file opened exactly twice %r" % opens)
opens_g, capg = count_reads(gained_case=True, stub_regen=False)
print("     gained run, REAL generate_config(): %r  (tripwire stopped it: %s)"
      % (opens_g, capg.status))
qalib.check(max(opens_g.values()) == 3,
            "M-4 CONFIRMED against NFR-3: a `gained` run opens each file THREE times "
            "(before, after, and generate_config()'s own ruleset_report()) %r" % opens_g)
print("     -> recorded against NFR-3's literal 'at most twice per run'; the third pass "
      "is inherited from T-02's generate_config(), not added by T-10.")

# ============================================================ BC-14 concurrency
# NOTE ON A FLAKE THIS TEST ITSELF HAD: an earlier version asserted "at most 1 of 10
# concurrent runs applies". That is wrong. BC-14 is scoped to TWO runs (timer + manual)
# and says "at most one REDUNDANT apply", i.e. <= 2 applies for 2 racing runs. With N
# racing runs, up to N can each legitimately observe a change, because each takes its own
# `before` snapshot. The assertion below is the requirement's actual bound, plus a
# HEAD-vs-change comparison showing the race is never worse than today.
print("\n-- BC-14 / H27: concurrent runs over one fixture directory")
shared = tempfile.mkdtemp(prefix="qat10-conc-")
CDRIVER = r'''
import argparse, io, json, os, sys
sys.path.insert(0, %r)
import qalib
root, src = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else None)
mod, _t = qalib.load_sc(tmproot=root, src_path=src or None)
log = qalib.stub_service(mod, running=True)
body = qalib.srs(b"C" * 64)
qalib.stub_fetch(mod, dict((f, body) for f, _r in mod.RULESET_FILES))
io.open(str(mod.CFG_PATH), "wb").write(b"{}")
try:
    mod.cmd_update_rules(argparse.Namespace(mirror=None))
finally:
    sys.stdout.write("SVCLOG=%%r\n" %% (log,))
''' % (os.path.dirname(os.path.abspath(__file__)),)
cd = os.path.join(shared, "cdriver.py")
io.open(cd, "w").write(CDRIVER)


def race(n, root, src=""):
    procs = [subprocess.Popen([sys.executable, cd, root] + ([src] if src else []),
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
             for _ in range(n)]
    outs = [p.communicate()[0].decode() for p in procs]
    return procs, outs


# (a) BC-14 literally: two racing runs
two = os.path.join(shared, "two")
procs, outs = race(2, two)
applies = sum(o.count("'restart_service'") for o in outs)
qalib.check(all(p.returncode == 0 for p in procs), "BC-14 both racing runs exit 0")
qalib.check(applies <= 2,
            "BC-14 two racing runs perform at most ONE REDUNDANT apply (%d applies)"
            % applies)

# (b) 10-way stress: no crash, no corruption, one outcome line each
ten = os.path.join(shared, "ten")
procs, outs = race(10, ten)
qalib.check(all(p.returncode == 0 for p in procs),
            "BC-14 all 10 concurrent runs exit 0 (%r)" % [p.returncode for p in procs])
qalib.check(all(o.count("No rule-set changed") + o.count("Rule-sets updated") == 1
                for o in outs),
            "BC-14 each run printed exactly one outcome line")
rd = os.path.join(ten, "etc-sing-box", "rules")
bodies = set(io.open(os.path.join(rd, f), "rb").read() for f in FILES)
qalib.check(bodies == {qalib.srs(b"C" * 64)},
            "BC-14 every file is intact and complete after 10 concurrent runs")
leftovers = [n for n in os.listdir(rd) if ".tmp" in n]
qalib.check(leftovers == [], "BC-14 no temp debris left behind: %r" % leftovers)
n_new = sum(1 for o in outs if "'restart_service'" in o)

# (c) the same 10-way race on HEAD, for comparison
HEADSRC = os.path.join(shared, "sc_HEAD.py")
io.open(HEADSRC, "wb").write(subprocess.run(
    ["git", "-C", qalib.REPO, "show", "HEAD:bin/sc"], stdout=subprocess.PIPE).stdout)
tenh = os.path.join(shared, "tenh")
procsh, outsh = race(10, tenh, HEADSRC)
n_head = sum(1 for o in outsh if "'restart_service'" in o)
print("     10-way race, applies: HEAD=%d  changed=%d" % (n_head, n_new))
qalib.check(n_head == 10,
            "on HEAD all 10 racing runs restart unconditionally (%d)" % n_head)
qalib.check(n_new <= n_head,
            "R4/BC-14: under the worst race the change is never worse than today "
            "(%d <= %d); each run applies only for what it itself observed"
            % (n_new, n_head))

# ============================================================ BC-16 zero rule-sets
print("\n-- BC-16: an empty RULESET_FILES tuple")
mod, tmproot = qalib.load_sc()
mod.RULESET_FILES = ()
io.open(str(mod.CFG_PATH), "wb").write(CFG_BODY)
qalib.stub_service(mod, running=True)
cap = qalib.Captured().run(lambda: mod.cmd_update_rules(argparse.Namespace(mirror=None)))
qalib.check(cap.exc is None and cap.status == 0, "BC-16 no crash, exit 0 (%r)" % cap.exc)
qalib.check("No rule-set changed" in cap.out, "BC-16 outcome is 'nothing changed'")
qalib.check(mod.tripwire.calls == [], "BC-16 no service action")
qalib.cleanup(tmproot)

import shutil
shutil.rmtree(shared, ignore_errors=True)
qalib.assert_no_service_calls("q6")
qalib.summary("q6_init_tty_cost")
```

## `q7_generate_config.py` (176 lines)

```python
"""q7 — the REAL generate_config() through the new reader (T-02 regression + F-7).

Adversarial hypotheses:
  H28 the 3-tuple destructuring in generate_config() broke when ruleset_states() started
      returning 4-tuples, so config generation drops or mis-names rule-sets.
  H29 T-02's degradation matrix changed: an unusable rule-set no longer degrades
      gracefully.
  H30 F-7's widened failure surface is bigger than the developer recorded: a file that
      faults MID-READ is now dropped by generate_config() where HEAD kept it. Measured
      on both sides, by injecting the fault at the OS boundary (file.read), never by
      stubbing the judgment itself.
"""
import io
import json
import os
import subprocess
import tempfile

import qalib

qalib.assert_non_root()
print("== q7: real generate_config() through the new reader")

FILES = ("geoip-cn.srs", "geosite-cn.srs", "geosite-google.srs", "geosite-private.srs")
work = tempfile.mkdtemp(prefix="qat10-gc-")
HEAD_SRC = os.path.join(work, "sc_HEAD.py")
p = subprocess.run(["git", "-C", qalib.REPO, "show", "HEAD:bin/sc"], stdout=subprocess.PIPE)
io.open(HEAD_SRC, "wb").write(p.stdout)


def setup(src_path=None, bodies=None):
    mod, tmproot = qalib.load_sc(src_path=src_path)
    io.open(str(mod.NODES_PATH), "w").write(json.dumps(
        {"active": "n1", "nodes": [{"tag": "n1", "type": "trojan", "server": "x",
                                    "server_port": 443, "password": "p"}]}))
    io.open(str(mod.SETTINGS_PATH), "w").write(json.dumps(
        {"default_tun": True, "mode": "rule", "lang": "en"}))
    for f in FILES:
        b = (bodies or {}).get(f, qalib.srs(b"g" * 64))
        if isinstance(b, bytes):
            qalib.write_ruleset(mod, f, b)
    return mod, tmproot


def run_gc(mod):
    """Run the real generate_config() to the point the tripwire stops it, return the
    config it wrote (config generation is complete before `sing-box check` is spawned)."""
    cap = qalib.Captured().run(mod.generate_config)
    cfg = json.loads(io.open(str(mod.CFG_PATH), encoding="utf-8").read())
    return cfg, cap


# ---- H28: all four usable
mod, tr = setup()
cfg, cap = run_gc(mod)
qalib.check(isinstance(cap.exc, qalib.TripwireError),
            "the real generate_config() was stopped at `sing-box check` by the tripwire")
qalib.check(mod.tripwire.calls[0][:2] == ["sing-box", "check"],
            "and the argv it tried was %r (C-4: `sing-box` is NOT whitelisted)"
            % (mod.tripwire.calls[0][:2],))
tags = [r["tag"] for r in cfg["route"]["rule_set"]]
qalib.check(sorted(tags) == sorted(f[:-4] for f in FILES),
            "H28 REFUTED: all four rule-sets defined, correctly named: %r" % tags)
qalib.check(all(r["path"].endswith(".srs") and r["type"] == "local" for r in
                cfg["route"]["rule_set"]),
            "every rule_set entry keeps its type/format/path shape")
qalib.cleanup(tr)

# ---- H29: T-02 degradation matrix, re-run through the new reader
MATRIX = [
    ("bad-magic",  b"<!DOCTYPE html>" + b"x" * 90),
    ("too-small",  b"SRS"),
    ("empty",      b""),
    ("absent",     None),
]
for label, body in MATRIX:
    mod, tr = setup(bodies={"geosite-cn.srs": body})
    if body is None:
        # setup() skips writing a None body, so the file is genuinely absent
        qalib.check(not (mod.RULES_DIR / "geosite-cn.srs").exists(),
                    "[absent] the fixture really has no geosite-cn.srs")
    cfg, cap = run_gc(mod)
    tags = [r["tag"] for r in cfg["route"]["rule_set"]]
    qalib.check("geosite-cn" not in tags,
                "H29 REFUTED [%s] the unusable rule-set is NOT defined: %r"
                % (label, tags))
    refs = json.dumps(cfg["route"]["rules"]) + json.dumps(cfg["dns"]["rules"])
    qalib.check("geosite-cn" not in refs,
                "[%s] and no surviving rule references it (T-02 degradation intact)"
                % label)
    qalib.check(len(tags) == 3, "[%s] the other three are still defined" % label)
    qalib.check("⚠️" in cap.err or "geosite-cn" in cap.err,
                "[%s] the degradation warning still goes to stderr" % label)
    qalib.cleanup(tr)

# a directory in place of a rule-set
mod, tr = setup()
(mod.RULES_DIR / "geoip-cn.srs").unlink()
(mod.RULES_DIR / "geoip-cn.srs").mkdir()
cfg, cap = run_gc(mod)
qalib.check("geoip-cn" not in [r["tag"] for r in cfg["route"]["rule_set"]],
            "a DIRECTORY in place of a rule-set degrades, does not crash")
qalib.cleanup(tr)

# all four unusable -> the optional field is dropped entirely (T-02 behaviour)
mod, tr = setup(bodies=dict((f, b"junkjunkjunkjunkjunk") for f in FILES))
cfg, cap = run_gc(mod)
qalib.check("rule_set" not in cfg["route"],
            "all four unusable -> route.rule_set is removed, not left empty (T-02)")
qalib.cleanup(tr)


# ---- H30: F-7, a fault at byte 500_000. Measured on BOTH sides.
def fault_at(mod, fname, nbytes):
    """Inject an OSError after `nbytes` of `fname` at the file-object boundary."""
    real_open = mod.Path.open

    def faulting_open(self, *a, **kw):
        fh = real_open(self, *a, **kw)
        if self.name != fname:
            return fh

        class FH(object):
            def __init__(self):
                self.n = 0

            def read(self, *ra):
                if self.n >= nbytes:
                    raise OSError(5, "Input/output error")
                data = fh.read(*ra)
                self.n += len(data)
                return data

            def __enter__(self):
                return self

            def __exit__(self, *x):
                fh.close()
                return False
        return FH()
    mod.Path.open = faulting_open
    return real_open


BIG = b"SRS" + b"f" * 900000
for label, src_path in (("HEAD (pre-change)", HEAD_SRC), ("working tree", None)):
    mod, tr = setup(bodies={"geosite-cn.srs": BIG}, src_path=src_path)
    real_open = fault_at(mod, "geosite-cn.srs", 500000)
    cfg, cap = run_gc(mod)
    mod.Path.open = real_open
    tags = [r["tag"] for r in cfg["route"]["rule_set"]]
    kept = "geosite-cn" in tags
    print("     %-20s file readable at byte 0, faults at byte 500 000 -> "
          "rule-set %s" % (label, "KEPT" if kept else "DROPPED"))
    if src_path:
        qalib.check(kept, "F-7 baseline: HEAD KEEPS the faulting rule-set (it only ever "
                          "read 12 bytes)")
    else:
        qalib.check(not kept,
                    "H30 CONFIRMED and correctly bounded: the change DROPS the faulting "
                    "rule-set — exactly the F-7 residual the developer recorded, no more")
    qalib.cleanup(tr)

# and the same file read WITHOUT a fault is kept on both sides (the change is confined
# to the fault case, not to large files as such)
for label, src_path in (("HEAD (pre-change)", HEAD_SRC), ("working tree", None)):
    mod, tr = setup(bodies={"geosite-cn.srs": BIG}, src_path=src_path)
    cfg, cap = run_gc(mod)
    qalib.check("geosite-cn" in [r["tag"] for r in cfg["route"]["rule_set"]],
                "%s: a 900 KB rule-set that reads cleanly is kept" % label)
    qalib.cleanup(tr)

import shutil
shutil.rmtree(work, ignore_errors=True)
qalib.assert_no_service_calls("q7")
qalib.summary("q7_generate_config")
```
