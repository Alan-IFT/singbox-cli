"""T-10 non-regression, C-2 (settings merge), C-1 (every other subcommand still initialises).

T-10 hypothesis (the serious one): "widening ruleset_state() to (status, digest, size)
perturbed cmd_update_rules' restart decision — so the owner's service is restarted every
Monday for four unchanged files".
Reproducer: cmd_update_rules driven against offline file:// mirrors in a sandbox, with
restart_service()/reload_or_restart()/generate_config() replaced by COUNTERS (they are
never allowed to run), run twice against identical mirror content.
The real `sc update-rules` is never invoked, and the QA loader blocks every
service-affecting subprocess process-wide.
"""
import json
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q7 T-10 / C-1 / C-2")


def witness():
    return subprocess.check_output(
        ["systemctl", "show", "sing-box", "-p", "MainPID", "-p",
         "ActiveEnterTimestamp"]).decode().strip()


w0 = witness()

# ---------------- changed_usable_tags(): pairs BY TAG, never by index ----------------
mod = qa_load.load()
mod.LANG = "en"
D = lambda n: "d" * 63 + str(n)  # noqa: E731


def st(pairs):
    """pairs: [(tag, status, digest, size)] -> ruleset_states()-shaped 5-tuples"""
    return [(tag, tag + ".srs", status, digest, size) for tag, status, digest, size in pairs]


before = st([("a", "usable", D(1), 10), ("b", "usable", D(2), 20),
             ("c", "usable", D(3), 30), ("d", "usable", D(4), 40)])
same = st([("a", "usable", D(1), 10), ("b", "usable", D(2), 20),
           ("c", "usable", D(3), 30), ("d", "usable", D(4), 40)])
t.eq(mod.changed_usable_tags(before, same), [],
     "T-10: four byte-identical rule-sets ⇒ empty apply set (no restart)")

# the index-vs-tag discriminator: same content, different ORDER in `before`
shuffled = st([("d", "usable", D(4), 40), ("c", "usable", D(3), 30),
               ("b", "usable", D(2), 20), ("a", "usable", D(1), 10)])
t.eq(mod.changed_usable_tags(shuffled, same), [],
     "T-10: pairing is BY TAG — reordering `before` changes nothing (index pairing "
     "would report all four changed)")
t.eq(mod.changed_usable_tags(before, st([("a", "usable", D(9), 11)] + [
        ("b", "usable", D(2), 20), ("c", "usable", D(3), 30), ("d", "usable", D(4), 40)])),
     ["a"], "T-10: exactly the rule-set whose bytes changed is in the apply set")
t.eq(mod.changed_usable_tags(before, st([("a", "absent", None, None)] + [
        ("b", "usable", D(2), 20), ("c", "usable", D(3), 30), ("d", "usable", D(4), 40)])),
     [], "T-10: a LOSS is not a change (never restart to load a file sing-box cannot read)")
t.eq(mod.changed_usable_tags(st([("a", "unreadable", None, None)]),
                            st([("a", "usable", D(1), 5)])),
     ["a"], "T-10: None is not a content value — a never-read file differs from every digest")
# the size column must be inert
t.eq(mod.changed_usable_tags(before, st([("a", "usable", D(1), 999999)] + [
        ("b", "usable", D(2), 20), ("c", "usable", D(3), 30), ("d", "usable", D(4), 40)])),
     [], "D-2: the new size column does NOT participate in the apply decision")

# tuple shapes the widening must not have broken
sv = mod._status_view(before)
t.eq(sv, [("a", "a.srs", "usable"), ("b", "b.srs", "usable"),
          ("c", "c.srs", "usable"), ("d", "d.srs", "usable")],
     "E-7: _status_view() still projects 3-tuples for generate_config()/usable_tags()")
t.eq(mod.usable_tags(sv), {"a", "b", "c", "d"}, "usable_tags() still consumes 3-tuples")

# ---------------- cmd_update_rules end to end, offline, twice ----------------
root = F.mkroot("updrules")
cfg = F.sandbox(root, rulesets="empty", config='{"log":{"level":"warn"}}',
                settings={"lang": "en"})
mirror = root / "mirror"
for sub in ("geoip", "geosite"):
    (mirror / sub).mkdir(parents=True)
bodies = {"geoip/cn.srs": b"SRS\x03" + b"A" * 900,
          "geosite/cn.srs": b"SRS\x03" + b"B" * 900,
          "geosite/google.srs": b"SRS\x03" + b"C" * 900,
          "geosite/private.srs": b"SRS\x03" + b"D" * 900}
for rel, b in bodies.items():
    (mirror / rel).write_bytes(b)

RUNNER = F.HERE / "q7_child.py"
RUNNER.write_text('''
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_load
cfg = json.loads(open(sys.argv[1]).read())
mod = qa_load.load()
qa_load.repoint(mod, cfg["root"])
mod.LANG = "en"
mod.SYSTEMD = False; mod.OPENRC = False
mod.RULESET_BASES = ("file://" + cfg["mirror"],)
counts = {"restart": 0, "reload": 0, "generate": 0}
def _no(name):
    def f(*a, **k):
        counts[name] += 1
        return True
    return f
mod.restart_service = _no("restart")
mod.reload_or_restart = _no("reload")
mod.generate_config = _no("generate")
mod.is_running = lambda: True
class A(object): mirror = None
try:
    mod.cmd_update_rules(A())
except SystemExit as e:
    sys.stderr.write("exit:%r\\n" % (e.code,))
sys.stderr.write("COUNTS:" + json.dumps(counts) + "\\n")
''')


def upd(tag):
    cf = root / ("uc-%s.json" % tag)
    cf.write_text(json.dumps({"root": str(root), "mirror": str(mirror)}))
    p = subprocess.Popen([sys.executable, str(RUNNER), str(cf)],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate(timeout=120)
    counts = json.loads(err.decode().split("COUNTS:")[1].splitlines()[0])
    return out.decode(), err.decode(), counts


o1, e1, c1 = upd("run1")
o2, e2, c2 = upd("run2")
print("---- update-rules run 1 ----\n%s---- run 2 ----\n%s----" % (o1, o2))
t.eq(c1["restart"], 1, "T-10 run 1: four newly-installed rule-sets ⇒ exactly ONE apply")
t.eq(c1["reload"], 0, "T-10 run 1: reload_or_restart() is not the apply path")
t.ok("Rule-sets updated:" in o1, "T-10 run 1: run-level outcome states the update")
t.eq(c2["restart"], 0, "T-10 run 2: identical mirror content ⇒ NO restart")
t.ok("No rule-set changed — the sing-box service was not touched" in o2,
     "T-10 run 2: the run-level outcome is 'nothing changed'")
t.eq(witness(), w0, "T-10: MainPID/ActiveEnterTimestamp unchanged across both runs")

# non-vacuity: change one mirror body -> exactly one apply, naming exactly that tag
(mirror / "geosite/google.srs").write_bytes(b"SRS\x03" + b"Z" * 900)
o3, e3, c3 = upd("run3")
t.eq(c3["restart"], 1, "non-vacuity: one changed body ⇒ exactly one apply")
t.ok("Rule-sets updated: geosite-google" in o3,
     "non-vacuity: the apply set names exactly the changed tag (%s)"
     % [l for l in o3.splitlines() if "Rule-sets" in l])
t.eq(witness(), w0, "T-10: witness unchanged after the third run")

# ---------------- C-2: a first-run port resolution must not erase settings ----------
r2 = F.mkroot("c2")
c2dir = F.sandbox(r2, rulesets="empty",
                  settings={"lang": "zh", "mode": "global", "default_tun": False,
                            "update_interval": "weekly"})
m2 = qa_load.load(name="c2mod")
qa_load.repoint(m2, r2)
port = m2._resolve_clash_port()
st2 = json.loads((c2dir / "settings.json").read_text())
t.eq(st2.get("lang"), "zh", "C-2: `lang` survives a first-run Clash-port resolution")
t.eq(st2.get("mode"), "global", "C-2: `mode` survives")
t.eq(st2.get("default_tun"), False, "C-2: `default_tun` survives")
t.eq(st2.get("update_interval"), "weekly", "C-2: `update_interval` survives")
t.eq(st2.get("clash_api_port"), port, "C-2: the resolved port was added")
# non-vacuity: the naive repair the gate forbade really does destroy them
m2.save_settings({"clash_api_port": port})
st3 = json.loads((c2dir / "settings.json").read_text())
t.eq(sorted(st3), ["clash_api_port"],
     "non-vacuity: save_settings() with a fresh single-key dict DOES erase the others")
# _saved_clash_port() never writes and returns None on every malformed shape
r3 = F.mkroot("c2b")
m3 = qa_load.load(name="c2bmod")
qa_load.repoint(m3, r3)
t.eq(m3._saved_clash_port(), None, "C-3: no settings file ⇒ None")
t.ok(not (r3 / "etc-sing-box").exists(), "C-3: _saved_clash_port() created nothing")
d3 = F.sandbox(r3, rulesets="empty", settings={"lang": "en"})
t.eq(m3._saved_clash_port(), None, "C-3: no key ⇒ None")
(d3 / "settings.json").write_text("{ not json")
t.eq(m3._saved_clash_port(), None, "C-3: malformed JSON ⇒ None")
(d3 / "settings.json").write_text(json.dumps({"clash_api_port": 99999}))
t.eq(m3._saved_clash_port(), None, "C-3: out-of-range port ⇒ None")

# ---------------- C-1 / RISK-2: every other subcommand still initialises ----------
GOODCFG = '{"log": {"level": "warn"}}'
for cmdname, argv in [("lang", ["lang", "en"]), ("mode", ["mode", "global"]),
                      ("status", ["status"]), ("ls", ["ls"]), ("now", ["now"]),
                      ("help", ["help"]), ("bare", [])]:
    rr = F.mkroot("c1-" + cmdname)
    rc, out, err = F.run_child({"mode": "main", "argv": argv, "root": str(rr),
                                "lang": "en", "systemd": False,
                                "egress": {"value": "1.2.3.4"}}, timeout=60)
    e = rr / "etc-sing-box"
    t.ok(e.exists(), "C-1 `sc %s`: the tree is still created" % " ".join(argv))
    t.ok((e / "nodes.json").exists(), "C-1 `sc %s`: nodes.json still written" % cmdname)
    if (e / "nodes.json").exists():
        t.eq(oct(os.stat(str(e / "nodes.json")).st_mode & 0o777), "0o600",
             "C-1 `sc %s`: nodes.json is mode 0600" % cmdname)
    if (e / "settings.json").exists():
        s = json.loads((e / "settings.json").read_text())
        t.ok("clash_api_port" in s, "C-1 `sc %s`: a Clash port is still persisted" % cmdname)
    t.ok(b"Traceback" not in err, "C-1 `sc %s`: no traceback" % cmdname)
    shutil.rmtree(str(rr), ignore_errors=True)

t.eq(witness(), w0, "witness unchanged at the end of q7")
RUNNER.unlink()
F.cleanup(root, r2, r3)
sys.exit(1 if t.done() else 0)
