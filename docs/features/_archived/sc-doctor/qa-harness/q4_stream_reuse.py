"""AC-12 (streaming), AC-13/C-6 (deletion test), AC-14 (no st_size), AC-15 (single defs).

AC-12 hypothesis: "the report sits in the block buffer until exit, so an interrupted run
shows nothing". Independent reproducer: the PARENT reads the capture file while the child
is still blocked in S7, then SIGINTs it. The developer's version had the child inspect its
own file; this one observes from outside the process under test.

AC-13 hypothesis: "S2 has an independent path to rule-set facts, so deleting the state
machinery leaves doctor working".  C-6 records that AC-13's illustrative wording ("the
rule-set report function") is read as the state/report MACHINERY: satisfying it literally
(taking status from ruleset_report() and size from ruleset_states()) forces two reads per
file, which violates FR-12 and admits a self-contradicting report under BC-15.
"""
import ast
import os
import signal
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q4 AC-12/13/14/15")

# ---------------- AC-12 streaming ----------------
root = F.mkroot("stream")
F.sandbox(root, rulesets="empty", config="{bad", settings={"lang": "en"})
outf = root / "stream.txt"
import json  # noqa: E402
cfgf = root / "cfg.json"
cfgf.write_text(json.dumps({"mode": "doctor", "root": str(root), "lang": "en",
                            "systemd": False, "sleep_s7": 20,
                            "egress": {"value": "203.0.113.7"}}))
with open(str(outf), "wb") as fh:
    p = subprocess.Popen([sys.executable, str(F.CHILD), str(cfgf)],
                         stdout=fh, stderr=subprocess.PIPE)
    deadline = time.time() + 15
    seen = ""
    while time.time() < deadline:
        seen = outf.read_text()
        if "Clash API responding" in seen:
            break
        time.sleep(0.2)
    mid = outf.read_text()
    p.send_signal(signal.SIGINT)
    try:
        _, err = p.communicate(timeout=15)
    except subprocess.TimeoutExpired:
        p.kill()
        _, err = p.communicate()
final = outf.read_text()
mid_labels = [l for _m, l in F.labels_of(mid)]
for s in ("sing-box binary", "rule-sets", "configuration", "service", "TUN interface",
          "Clash API"):
    t.ok(s in mid_labels, "AC-12: %r already on stdout while S7 is still blocked" % s)
t.ok("egress IP" not in mid_labels, "AC-12: S7 had not printed yet (the run really was mid-flight)")
t.eq(final, mid, "AC-12: the interrupted run left exactly S1..S6 on stdout")
t.ok(p.returncode != 0, "AC-12: the interrupt terminated the run (rc=%s)" % p.returncode)

# ---------------- AC-13 / C-6 deletion test ----------------
mod = qa_load.load()
qa_load.repoint(mod, root)
mod.LANG = "en"
t.ok(len(mod._doctor_rulesets()) == 5, "AC-13 control: S2 works with the machinery present")
t.ok(len(mod.ruleset_report()) == 4, "AC-13 control: ruleset_report() works too")

m1 = qa_load.load(name="del_states")
qa_load.repoint(m1, root)
del m1.__dict__["ruleset_states"]
try:
    m1._doctor_rulesets()
    t.ok(False, "AC-13: deleting ruleset_states() must break S2")
except NameError as e:
    t.ok("ruleset_states" in str(e), "AC-13: deleting ruleset_states() breaks doctor's S2 (%s)" % e)
try:
    m1.ruleset_report()
    t.ok(False, "AC-13: deleting ruleset_states() must break ruleset_report() too")
except NameError:
    t.ok(True, "AC-13: it breaks ruleset_report()/generate_config() at the same moment — "
               "one reader, no alternative path")

m2 = qa_load.load(name="del_state")
qa_load.repoint(m2, root)
del m2.__dict__["ruleset_state"]
try:
    m2._doctor_rulesets()
    t.ok(False, "AC-13: deleting ruleset_state() must break S2")
except NameError:
    t.ok(True, "AC-13: deleting ruleset_state() also breaks S2 — no second reader exists")

# ---------------- AC-14 no st_size, by inspection and behaviourally ----------------
src = qa_load.SRC.read_text()
tree = ast.parse(src)
funcs = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
DOCTOR = [n for n in funcs if n.startswith("_doctor") or n == "cmd_doctor"] + \
         ["ruleset_state", "ruleset_states", "_status_view", "srs_reject_reason",
          "_status_text", "_plain", "_first_line", "_saved_clash_port", "_egress_ip",
          "is_running", "clash_api", "load_settings"]
bad = []
for name in DOCTOR:
    node = funcs.get(name)
    if node is None:
        continue
    for sub in ast.walk(node):
        if isinstance(sub, ast.Attribute) and sub.attr in ("st_size", "getsize", "stat"):
            bad.append((name, sub.attr, sub.lineno))
        if isinstance(sub, ast.Name) and sub.id in ("getsize",):
            bad.append((name, sub.id, sub.lineno))
t.eq(bad, [], "AC-14: no stat/st_size/getsize anywhere in doctor's reachable call graph")

# behavioural: a rule-set whose apparent length (st_size) and read length differ
r14 = F.mkroot("stsize")
c14 = F.sandbox(r14, rulesets="empty", settings={"lang": "en"})
link = c14 / "rules" / "geoip-cn.srs"
os.symlink("/proc/version", str(link))
apparent = os.stat(str(link)).st_size
real = len(open("/proc/version", "rb").read())
t.ok(apparent != real, "AC-14 precondition: st_size=%d differs from read length=%d"
     % (apparent, real))
rc, out, _ = F.run_child({"mode": "doctor", "root": str(r14), "lang": "en",
                          "egress": {"value": "1.2.3.4"}})
tx = out.decode()
t.ok("geoip-cn.srs: not a rule-set file, %d bytes" % real in tx,
     "AC-14: the printed size is the READ length (%d), not st_size (%d)\n%s"
     % (real, apparent, [l for l in tx.splitlines() if "geoip-cn" in l]))
t.ok(("geoip-cn.srs: not a rule-set file, %d bytes" % apparent) not in tx,
     "AC-14 non-vacuity: st_size (%d) is NOT what gets printed" % apparent)

# ---------------- AC-15 single definitions ----------------
for literal, want in (('"sb-tun"', 1), ('"https://api.ipify.org"', 1)):
    n = src.count(literal)
    t.eq(n, want, "AC-15: %s occurs %d time(s) in bin/sc" % (literal, want))
_code = [ln for ln in src.splitlines() if 'clash_api_port' in ln and not ln.strip().startswith('THE')]
t.eq(len(_code), 2, "AC-15: clash_api_port appears on exactly 2 code lines (1 read, 1 write): %s" % _code)
t.eq(src.count('settings["clash_api_port"] = port'), 1,
     "AC-15: exactly one WRITER of settings['clash_api_port']")
t.eq(src.count('settings.get("clash_api_port")'), 1,
     "AC-15: exactly one READER of settings['clash_api_port']")
t.eq(len([1 for ln in src.splitlines() if "TUN_IFACE" in ln and "=" in ln.split("#")[0]
          and ln.split("#")[0].strip().startswith("TUN_IFACE")]), 1,
     "AC-15: TUN_IFACE is defined once")
t.eq(src.count("TUN_IFACE"), 1 + 6, "AC-15: TUN_IFACE definition + its references (%d)"
     % src.count("TUN_IFACE"))

F.cleanup(root, r14)
sys.exit(1 if t.done() else 0)
