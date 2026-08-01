"""QA loader for bin/sc — stage 6, task sc-doctor.

SAFETY (insight-index.md:13). bin/sc:83-84 auto-elevates at IMPORT time by
os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + argv).  An un-neutralised import does
not fail — it runs the INSTALLED tool against the LIVE service.  This loader:

  1. asserts the re-exec line is present exactly once, replaces it, and asserts it is gone
     BEFORE compile()/exec();
  2. hard-blocks os.execv* process-wide in the harness interpreter;
  3. hard-blocks every service-affecting subprocess argv (systemctl start/stop/restart/
     reload/enable/disable, rc-service, rc-update add/del) process-wide;
  4. forces SYSTEMD = OPENRC = False on the loaded module unless the caller explicitly
     opts out with real_init=True (used only where the test IS about S4).

Every QA script imports this and nothing else loads bin/sc.
"""
import os
import subprocess
import sys
import types
from pathlib import Path

REPO = Path("/home/alan/Programs/singbox-cli")
SRC = REPO / "bin" / "sc"
NEEDLE = 'os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])'

# ---- guard 2: no exec* of another process from this interpreter, ever ----------------
_FORBID_EXEC = "QA GUARD: os.exec* blocked in the QA harness"
for _n in ("execv", "execve", "execvp", "execvpe", "execl", "execle", "execlp", "execlpe"):
    if hasattr(os, _n):
        def _blocked(*a, **k):
            raise RuntimeError(_FORBID_EXEC)
        setattr(os, _n, _blocked)

# ---- guard 3: no service-affecting subprocess ----------------------------------------
_BAD_SYSTEMCTL = {"start", "stop", "restart", "reload", "reload-or-restart", "try-restart",
                  "enable", "disable", "mask", "unmask", "daemon-reload", "kill"}
_real_run = subprocess.run
_real_popen = subprocess.Popen
_real_call = subprocess.call
_real_co = subprocess.check_output


def _vet(cmd):
    if isinstance(cmd, (str, bytes)):
        raise RuntimeError("QA GUARD: shell/string command blocked: %r" % (cmd,))
    argv = [str(x) for x in cmd]
    if not argv:
        return
    exe = os.path.basename(argv[0])
    if exe == "systemctl" and any(a in _BAD_SYSTEMCTL for a in argv[1:]):
        raise RuntimeError("QA GUARD: service-affecting systemctl blocked: %r" % (argv,))
    if exe == "rc-service":
        if any(a in ("start", "stop", "restart") for a in argv[1:]):
            raise RuntimeError("QA GUARD: rc-service mutation blocked: %r" % (argv,))
    if exe == "rc-update" and any(a in ("add", "del") for a in argv[1:]):
        raise RuntimeError("QA GUARD: rc-update mutation blocked: %r" % (argv,))
    if exe in ("sc",) or argv[0].endswith("/usr/local/bin/sc"):
        raise RuntimeError("QA GUARD: installed sc invocation blocked: %r" % (argv,))
    if exe == "sudo":
        raise RuntimeError("QA GUARD: sudo blocked: %r" % (argv,))


def _run(cmd, *a, **k):
    _vet(cmd)
    return _real_run(cmd, *a, **k)


def _popen(cmd, *a, **k):
    _vet(cmd)
    return _real_popen(cmd, *a, **k)


def _callf(cmd, *a, **k):
    _vet(cmd)
    return _real_call(cmd, *a, **k)


def _cof(cmd, *a, **k):
    _vet(cmd)
    return _real_co(cmd, *a, **k)


subprocess.run = _run
subprocess.Popen = _popen
subprocess.call = _callf
subprocess.check_output = _cof


def neutralised_source(text=None):
    """Return bin/sc's source with the auto-elevate removed, asserting both directions."""
    if text is None:
        text = SRC.read_text()
    n = text.count(NEEDLE)
    assert n == 1, "QA GUARD: expected exactly 1 auto-elevate re-exec, found %d" % n
    out = text.replace(NEEDLE, "pass  # <<< NEUTRALISED BY QA HARNESS >>>")
    assert NEEDLE not in out, "QA GUARD: neutralisation did not take"
    assert 'execvp("sudo"' not in out, "QA GUARD: a sudo exec survived"
    return out


def load(text=None, name="sc_uut", real_init=False):
    src = neutralised_source(text)
    mod = types.ModuleType(name)
    mod.__file__ = str(SRC)
    mod.__name__ = name
    exec(compile(src, str(SRC), "exec"), mod.__dict__)
    # post-exec proof the guard held: os.geteuid() != 0 here, so an un-neutralised module
    # would already have exec'd away and this line would be unreachable.
    assert os.geteuid() != 0, "QA GUARD: harness must not run as root"
    if not real_init:
        mod.SYSTEMD = False
        mod.OPENRC = False
    return mod


def head_source():
    return subprocess.check_output(["git", "-C", str(REPO), "show", "HEAD:bin/sc"]).decode()


def repoint(mod, root):
    """Repoint every filesystem path the module reads into a sandbox root."""
    root = Path(root)
    mod.CFG_DIR = root / "etc-sing-box"
    mod.CFG_PATH = mod.CFG_DIR / "config.json"
    mod.NODES_PATH = mod.CFG_DIR / "nodes.json"
    mod.SETTINGS_PATH = mod.CFG_DIR / "settings.json"
    mod.RULES_DIR = mod.CFG_DIR / "rules"
    return mod.CFG_DIR


# ---------------- tiny assertion kit ----------------
class T(object):
    def __init__(self, title):
        self.title = title
        self.p = 0
        self.f = 0
        self.fails = []

    def ok(self, cond, what):
        if cond:
            self.p += 1
        else:
            self.f += 1
            self.fails.append(what)
            sys.stdout.write("    FAIL: %s\n" % what)

    def eq(self, got, want, what):
        self.ok(got == want, "%s  (got %r, want %r)" % (what, got, want))

    def done(self):
        sys.stdout.write("== %s: PASS %d  FAIL %d\n" % (self.title, self.p, self.f))
        return self.f
