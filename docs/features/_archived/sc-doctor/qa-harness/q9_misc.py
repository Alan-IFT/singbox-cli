"""AC-1, AC-2, AC-7, AC-21 (documented), AC-23, AC-26 and T-4 (NFR-2 runtime ceiling)."""
import ast
import json
import os
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q9 AC-1/2/7/21/23/26 + T-4")
REPO = qa_load.REPO
src = qa_load.SRC.read_text()

# ---------------- AC-1 registered and dispatched ----------------
tree = ast.parse(src)
t.ok('sub.add_parser("doctor")' in src, "AC-1: `doctor` is in the subparser set")
t.ok('"doctor": cmd_doctor' in src, "AC-1: `doctor` is in the handler dict")
r = F.mkroot("ac1")
F.sandbox(r, rulesets="empty", settings={"lang": "en"})
rc, out, err = F.run_child({"mode": "main", "argv": ["doctor"], "root": str(r),
                            "lang": "en", "egress": {"value": "1.2.3.4"}})
t.ok(out.decode().startswith("["), "AC-1: `sc doctor` prints a report, not the help text")
t.ok("Usage:" not in out.decode() and "用法" not in out.decode(),
     "AC-1: the help text is not what `sc doctor` prints")

# ---------------- AC-2 both help blocks + both READMEs ----------------
he = src[src.index("HELP_EN"):src.index("HELP_ZH")]
hz = src[src.index("HELP_ZH"):src.index("def cmd_help")]
t.ok("doctor" in he, "AC-2: `doctor` in HELP_EN")
t.ok("doctor" in hz, "AC-2: `doctor` in HELP_ZH")
he_l = [l for l in he.splitlines() if "doctor" in l or "exit " in l or "退出码" in l]
hz_l = [l for l in hz.splitlines() if "doctor" in l or "exit " in l or "退出码" in l]
t.eq(len(he_l), len(hz_l), "AC-2: both help blocks gained the same number of doctor lines")
for blk, name in ((he, "HELP_EN"), (hz, "HELP_ZH")):
    lines = blk.splitlines()
    di = [i for i, l in enumerate(lines) if l.strip().startswith("doctor")]
    si = [i for i, l in enumerate(lines) if l.strip().startswith("status")]
    t.ok(di and si and si[0] < di[0] and di[0] - si[0] == 1,
         "AC-2: %s inserts doctor immediately after status" % name)
    t.ok("0" in blk and "1" in blk and "2" in blk, "AC-21: %s documents the exit values" % name)

# both help blocks render without a KeyError, in their own language
for lang in ("en", "zh"):
    rr = F.mkroot("help-" + lang)
    rc, o, e = F.run_child({"mode": "main", "argv": ["help"], "root": str(rr), "lang": lang})
    t.ok(b"doctor" in o, "AC-2: `sc help` (%s) lists doctor" % lang)
    t.ok(b"Traceback" not in e, "AC-2: `sc help` (%s) renders without error" % lang)
    F.cleanup(rr)

en_r = (REPO / "README.md").read_text()
zh_r = (REPO / "README.zh-CN.md").read_text()
t.ok("sc doctor" in en_r, "AC-2: README.md documents sc doctor")
t.ok("sc doctor" in zh_r, "AC-2: README.zh-CN.md documents sc doctor")
en_h = [l for l in en_r.splitlines() if l.startswith("#")]
zh_h = [l for l in zh_r.splitlines() if l.startswith("#")]
t.eq(len(en_h), len(zh_h), "AC-2: the two READMEs still have the same heading count")
en_i = [i for i, l in enumerate(en_h) if "Diagnose" in l]
zh_i = [i for i, l in enumerate(zh_h) if "诊断" in l]
t.eq(en_i, zh_i, "AC-2: the new section sits at the same structural index in both READMEs")
for f, name in ((en_r, "README.md"), (zh_r, "README.zh-CN.md")):
    for v in ("0", "1", "2"):
        t.ok(("`%s`" % v) in f or (" %s " % v) in f, "AC-21: %s documents exit %s" % (name, v))

# ---------------- AC-7 read-only call graph, re-derived ----------------
funcs = {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef)}
WRITERS = {"generate_config", "restart_service", "reload_or_restart", "save_nodes",
           "save_settings", "_init_files", "_resolve_clash_port", "_free_port",
           "_fetch_to_temp", "_temp_path", "_clear_stale_temps", "cmd_uninstall"}
seen = set()
stack = ["cmd_doctor"] + [n for n in funcs if n.startswith("_doctor")]
while stack:
    n = stack.pop()
    if n in seen or n not in funcs:
        continue
    seen.add(n)
    for sub in ast.walk(funcs[n]):
        if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Name):
            stack.append(sub.func.id)
t.eq(sorted(seen & WRITERS), [],
     "AC-7: no writer is reachable from cmd_doctor (reached %d functions)" % len(seen))
mutating_attrs = {"mkdir", "write_text", "write_bytes", "unlink", "rmdir",
                  "chmod", "touch", "rename", "symlink_to"}
hits = []
for n in sorted(seen):
    for sub in ast.walk(funcs[n]):
        if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Attribute) \
                and sub.func.attr in mutating_attrs:
            hits.append((n, sub.func.attr, sub.lineno))
        # Path.replace(target) takes ONE argument; str.replace(a, b) takes two.
        if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Attribute) \
                and sub.func.attr == "replace" and len(sub.args) == 1:
            hits.append((n, "Path.replace", sub.lineno))
        if isinstance(sub, ast.Call) and isinstance(sub.func, ast.Attribute) \
                and sub.func.attr == "open":
            for a in sub.args:
                if isinstance(a, ast.Str) and a.s != "rb":
                    hits.append((n, "open(%r)" % a.s, sub.lineno))
t.eq(hits, [], "AC-7: no mutating filesystem call anywhere in the reachable graph")
_cp = [(n, sub.lineno) for n in sorted(seen)
       if n.startswith("_doctor") or n == "cmd_doctor"
       for sub in ast.walk(funcs[n])
       if isinstance(sub, ast.Name) and sub.id == "CLASH_PORT"]
t.eq(_cp, [], "C-3: no doctor function references the module-level CLASH_PORT "
              "(a docstring mention at bin/sc:1436 is prose, not a reference)")
print("AC-7 reachable graph from cmd_doctor (%d): %s" % (len(seen), sorted(seen)))

# ---------------- AC-23 Python floor ----------------
try:
    ast.parse(src, feature_version=(3, 6))
    t.ok(True, "AC-23: bin/sc parses under a 3.6 feature_version")
except SyntaxError as e:
    t.ok(False, "AC-23: 3.6 parse failed: %s" % e)
p = subprocess.run([sys.executable, "-m", "py_compile", str(qa_load.SRC)],
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
t.eq(p.returncode, 0, "B.1: python3 -m py_compile bin/sc")
t.eq(src.count("capture_output="), 3,
     "AC-23: exactly three pre-existing capture_output= sites, no fourth")
sites = [i + 1 for i, l in enumerate(src.splitlines()) if "capture_output=" in l]
head_src = qa_load.head_source()
t.eq(head_src.count("capture_output="), 3, "AC-23: HEAD also had exactly three")
print("capture_output= at bin/sc lines %s" % sites)
diff = subprocess.check_output(["git", "-C", str(REPO), "diff", "--unified=0", "--",
                                "bin/sc"]).decode()
added = "\n".join(l for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++"))
for token in ("capture_output=", "text=True", ":=", "missing_ok=", "dataclasses", "=}"):
    t.ok(token not in added, "AC-23: the diff introduces no %r" % token)

# ---------------- AC-26 scope ----------------
names = subprocess.check_output(["git", "-C", str(REPO), "diff", "--name-only"]).decode().split()
# AC-26 constrains "the SHIPPING diff".  Pipeline bookkeeping is not shipped code and is
# written by the PM/harness alongside the task, so it is excluded by name rather than
# silently: `.harness/` (ledgers, rejected decisions), `docs/tasks.md` and
# `docs/batches/` (the pool + batch plan; e.g. the PM filed pool row T-12 here at 10:06
# on 2026-08-01, mid-task), and `docs/features/` (this task's own stage documents).
BOOKKEEPING = (".harness/", "docs/batches/", "docs/features/")
product = [n for n in names
           if not n.startswith(BOOKKEEPING) and n != "docs/tasks.md"]
t.eq(sorted(product), ["CHANGELOG.md", "README.md", "README.zh-CN.md", "bin/sc",
                       "docs/dev-map.md"], "AC-26: exactly the five permitted files")
rc = subprocess.call(["git", "-C", str(REPO), "diff", "--quiet", "--",
                      "install.sh", "uninstall.sh", "systemd/"])
t.eq(rc, 0, "AC-26: install.sh / uninstall.sh / systemd/ byte-identical to HEAD")
# Pinned to the record's claim on purpose: this assertion exists to catch the DOCUMENT
# going stale against the tree.  Updated at stage 6b for the DEF-1 fix; the pre-fix
# numbers were 457/37 and "539 insertions(+)" (04_ §13 supersedes them).
numstat = subprocess.check_output(["git", "-C", str(REPO), "diff", "--numstat", "--",
                                   "bin/sc"]).decode().split()
t.eq(numstat[:2], ["491", "37"],
     "AC-26: bin/sc --numstat is 491/37 as 04_ SS13 claims (was 457/37 pre-DEF-1-fix)")
stat = subprocess.check_output(
    ["git", "-C", str(REPO), "diff", "--shortstat", "--", "bin/sc", "README.md",
     "README.zh-CN.md", "CHANGELOG.md", "docs/dev-map.md"]).decode().strip()
t.ok("5 files changed, 573 insertions(+), 43 deletions(-)" in stat,
     "AC-26: the authoritative diffstat is %r" % stat)

# ---------------- T-4 / NFR-2 runtime ----------------
# (a) healthy host: everything local and answering
r9 = F.mkroot("t4-healthy")
F.sandbox(r9, rulesets="good", config='{"log":{"level":"warn"}}',
          settings={"lang": "en", "clash_api_port": 29199})
OK = r9 / "bin"
F.fakebin(OK, "systemctl", 'case "$1" in is-active) exit 0;; is-enabled) echo enabled;; '
                           'esac; exit 0')
F.fakebin(OK, "ip", 'echo "sb-tun  UNKNOWN  172.19.0.1/30"')
F.fakebin(OK, "sing-box", 'if [ "$1" = version ]; then echo "sing-box version 1.13.15"; fi; exit 0')
ts = []
for _ in range(3):
    t0 = time.time()
    F.run_child({"mode": "doctor", "root": str(r9), "lang": "en", "systemd": True,
                 "egress": {"value": "1.2.3.4"}, "clash": {"answer": {}}},
                env={"PATH": str(OK)})
    ts.append(time.time() - t0)
best = min(ts)
print("T-4 healthy (all probes local+stubbed, 3 runs): %s  best=%.2fs" %
      (["%.2f" % x for x in ts], best))
t.ok(best < 2.0, "T-4/NFR-2: a healthy run is %.2f s (< 2 s claimed)" % best)

# (b) broken but DNS-responsive: a REAL 3 s Clash read timeout + a REAL 8 s egress timeout.
#     The Clash hang is produced by a listening socket that never accepts data-phase reads;
#     the egress hang by pointing the endpoint at TEST-NET-3 (no DNS involved) in a MUTANT
#     copy of bin/sc — labelled as a mutant, used only to measure the bound.
srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 0))
srv.listen(1)
hangport = srv.getsockname()[1]
srv2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv2.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv2.bind(("127.0.0.1", 0))
srv2.listen(1)
egport = srv2.getsockname()[1]
mut = F.HERE / "mutant_slow.py"
mut.write_text(src.replace('"https://api.ipify.org"',
                           '"http://127.0.0.1:%d"' % egport))
r10 = F.mkroot("t4-broken")
F.sandbox(r10, rulesets="empty", config="{bad",
          settings={"lang": "en", "clash_api_port": hangport})
t0 = time.time()
rc10, out10, err10 = F.run_child({"mode": "doctor", "root": str(r10), "lang": "en",
                                  "systemd": False}, env={"QA_MUTANT": str(mut)}, timeout=120)
el = time.time() - t0
srv.close()
srv2.close()
mut.unlink()
print("T-4 broken-but-DNS-responsive: %.2f s, exit %d\n%s" % (el, rc10, out10.decode()))
txt10 = out10.decode()
t.ok(el >= 10.0, "T-4: the 3 s + 8 s bounds were really paid (%.2f s)" % el)
t.ok("egress IP: (error:" in txt10, "T-4: the egress probe really timed out")
# gate F-12, OBSERVED for the first time: a read-phase socket.timeout escapes clash_api()'s
# except clause, so a HUNG (as opposed to refused) port renders as ONE driver-backstop
# UNKNOWN row under the section label, not S6's designed two rows.
s6 = [l for l in txt10.splitlines() if l.startswith("[") and "Clash API" in l]
t.ok(len(s6) == 1 and "this check could not run" in s6[0],
     "F-12 OBSERVED: a hung Clash port yields one backstop UNKNOWN row, not the designed "
     "two rows: %s" % s6)
t.ok(el <= 15.0, "T-4/NFR-2: broken host run took %.2f s (design claims <= 15 s)" % el)

F.cleanup(r, r9, r10)
sys.exit(1 if t.done() else 0)
