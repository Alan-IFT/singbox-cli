"""AC-16 / C-4 / code-review M-1 — `sc status` byte-identical in both languages.

Hypothesis to falsify: "E-12 (sb-tun -> TUN_IFACE) or E-13 (inlined urlopen -> _egress_ip())
changed a byte of `sc status`'s output".

METHOD, stated in full because C-4 requires the comparison to be falsifiable.
HEAD:bin/sc and the working tree are each run in their OWN child process (so no module
object is shared and the urlopen stub cannot leak between them), each loaded through the
QA loader, which asserts the import-time sudo re-exec is gone before executing the module.
Capture is at fd level, so the real `ip -br addr show sb-tun` subprocess output is inside
the compared bytes.

The five replaced module attributes (this is M-1's omission, stated):
    SYSTEMD = False ; OPENRC = False   -> the `systemctl status` subprocess does not run
    is_running = lambda: True          -> WITHOUT THIS the gate at bin/sc:1201 is never
                                          taken and the ONLY region E-13 edits would be
                                          outside the capture; this is the stub the
                                          developer's record dropped
    load_nodes  = lambda: {...}        -> /etc/sing-box/nodes.json is root-only
    clash_api   = lambda *a, **k: {...}-> no live Clash call
    CLASH_PORT  = 29099                -> constant
    urlopen     = stub                 -> deterministic egress value / deterministic raise

REGIONS COMPARED:   the `=== Service status ===` header, the `=== TUN interface ===`
header AND the real `ip` output beneath it, `=== Current node ===`, `=== Route mode ===`,
`=== Clash API ===`, `=== Egress IP ===` and the egress value or its `(error: …)` arm —
i.e. every line cmd_status can emit except one.
REGION EXCLUDED:    the `systemctl status --no-pager -n 5` / `rc-service status` subprocess
output (bin/sc:1195-1198). It prints a live PID, an elapsed time and five journal lines, so
two captures of even *unmodified* code differ; it is also the one region the diff provably
does not touch (identical bytes at HEAD and in the tree).
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q6 AC-16 sc status")
root = F.mkroot("status")
F.sandbox(root, rulesets="good", settings={"lang": "en", "clash_api_port": 29099})

# the excluded region is byte-identical between the two revisions, so excluding it is safe
head_src = qa_load.head_source()
tree_src = qa_load.SRC.read_text()
EXCL = ('    if SYSTEMD:\n'
        '        subprocess.run(["systemctl", "status", "--no-pager", "-n", "5", SERVICE])\n'
        '    elif OPENRC:\n'
        '        subprocess.run(["rc-service", SERVICE, "status"])\n')
t.ok(EXCL in head_src and EXCL in tree_src,
     "AC-16: the excluded systemctl-status region is byte-identical at HEAD and in the tree")

RUNNER = F.HERE / "q6_child.py"
RUNNER.write_text('''
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_load, urllib.request
cfg = json.loads(open(sys.argv[1]).read())
src = qa_load.head_source() if cfg["rev"] == "head" else qa_load.SRC.read_text()
if cfg.get("perturb"):
    a, b = cfg["perturb"]
    assert src.count(a) >= 1, "perturbation anchor missing"
    src = src.replace(a, b)
mod = qa_load.load(text=src, name="rev_" + cfg["rev"])
qa_load.repoint(mod, cfg["root"])
mod.SYSTEMD = False
mod.OPENRC = False
mod.LANG = cfg["lang"]
mod.CLASH_PORT = 29099
mod.is_running = lambda: True
mod.load_nodes = lambda: {"active": "LosAngeles-US", "nodes": [1]}
mod.clash_api = lambda *a, **k: {"mode": "rule"}
class _R(object):
    def __enter__(self): return self
    def __exit__(self, *a): return False
    def read(self): return b"203.0.113.7"
def _open(*a, **k):
    if cfg["egress"] == "raise":
        raise OSError("urlopen error timed out")
    return _R()
urllib.request.urlopen = _open
mod.urllib.request.urlopen = _open
mod.cmd_status(None)
''')


def capture(rev, lang, egress, perturb=None):
    import json
    cf = root / ("c-%s-%s-%s.json" % (rev, lang, egress))
    cf.write_text(json.dumps({"rev": rev, "lang": lang, "egress": egress,
                              "root": str(root), "perturb": perturb}))
    of = root / ("o-%s-%s-%s-%s.txt" % (rev, lang, egress, bool(perturb)))
    with open(str(of), "wb") as fh:
        p = subprocess.Popen([sys.executable, str(RUNNER), str(cf)],
                             stdout=fh, stderr=subprocess.PIPE)
        _, err = p.communicate(timeout=60)
    assert p.returncode == 0, (rev, lang, egress, err[-400:])
    return of.read_bytes()


samples = {}
for lang in ("en", "zh"):
    for egress in ("ok", "raise"):
        h = capture("head", lang, egress)
        w = capture("tree", lang, egress)
        samples[(lang, egress)] = w
        t.eq(w, h, "AC-16: sc status byte-identical, lang=%s egress=%s" % (lang, egress))

s = samples[("en", "ok")].decode()
t.ok("sb-tun" in s, "AC-16: the compared capture really contains the real `ip` output")
t.ok("203.0.113.7" in s, "AC-16: the compared capture really contains the egress value "
                         "(so E-13's region was inside it)")
t.ok("=== Current node ===" in s and "LosAngeles-US" in s,
     "AC-16: the is_running() gate was taken — the whole :1201-1214 region is compared")
t.ok("(error: urlopen error timed out)" in samples[("en", "raise")].decode(),
     "AC-16: the egress failure arm is also compared")
t.ok("=== 服务状态 ===" in samples[("zh", "ok")].decode(),
     "AC-16: the zh capture really rendered in Chinese")
print("---- compared `sc status` capture (en, egress ok) ----")
print(s + "----")

# ---- NEGATIVE CONTROL: "identical" must be able to be false ----
h = capture("head", "en", "ok")
w = capture("tree", "en", "ok", perturb=['TUN_IFACE = "sb-tun"', 'TUN_IFACE = "lo"'])
t.ok(w != h, "non-vacuity: perturbing TUN_IFACE to 'lo' makes the captures DIFFER")
w2 = capture("tree", "en", "ok", perturb=['        return resp.read().decode()',
                                          '        return resp.read().decode() + "!"'])
t.ok(w2 != h, "non-vacuity: perturbing _egress_ip()'s return makes the captures DIFFER")

RUNNER.unlink()
F.cleanup(root)
sys.exit(1 if t.done() else 0)
