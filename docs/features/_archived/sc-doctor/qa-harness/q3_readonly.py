"""AC-5 (files) and AC-6 (service) — read-only, measured on the LIVE tree.

Hypothesis to falsify: "a doctor run leaves a trace" — a new file, a changed mtime, a
changed inode, a bumped cache.db, or a bounced service.

Three parts:
  A. the REAL /etc/sing-box + /var/lib/sing-box, snapshotted around a real doctor run
     (non-root: see the report's 'unverified' list for what that costs);
  B. the fresh-host half — a redirected root where nothing exists; it must still not exist;
  C. the MainPID / ActiveEnterTimestamp witness around part A.
`systemctl is-active` is never used as evidence (insight-index.md:22).
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q3 AC-5/AC-6 read-only")
LIVE = ["/etc/sing-box", "/var/lib/sing-box"]


def witness():
    return subprocess.check_output(
        ["systemctl", "show", "sing-box", "-p", "MainPID", "-p", "ActiveEnterTimestamp"]
    ).decode().strip()


# ---------- C(before) + A ----------
w0 = witness()
print("WITNESS BEFORE:\n%s" % w0)
before = F.snapshot(LIVE)
print("live paths snapshotted: %d" % len(before))

rc, out, err = F.run_child({"mode": "doctor", "root": None, "lang": "en",
                            "systemd": True, "openrc": False}, timeout=120)
after = F.snapshot(LIVE)
w1 = witness()
print("WITNESS AFTER:\n%s" % w1)
print("---- LIVE-TREE doctor report (non-root), exit %d ----\n%s----" % (rc, out.decode()))
if err:
    print("stderr: %r" % err[:400])

d = F.diff_snap(before, after)
t.eq(d, [], "AC-5(live): /etc/sing-box + /var/lib/sing-box byte/mtime/mode/inode identical")
t.eq(w1, w0, "AC-6: MainPID + ActiveEnterTimestamp identical across a real doctor run")
t.ok(b"Traceback" not in err, "AC-22(live): no traceback")
t.eq(len([l for _m, l in F.labels_of(out.decode())
          if l in ("sing-box binary", "rule-sets", "configuration", "service",
                   "TUN interface", "Clash API", "egress IP")]), 7,
     "AC-8(live): all seven sections on the real host")

# ---------- B: the fresh-host half ----------
root = F.mkroot("fresh")
cfgdir = root / "etc-sing-box"
t.ok(not cfgdir.exists(), "fresh-host precondition: the redirected /etc/sing-box is absent")
b0 = F.snapshot([root])
rc2, out2, err2 = F.run_child({"mode": "main", "argv": ["doctor"], "root": str(root),
                               "lang": "en", "systemd": True,
                               "egress": {"value": "203.0.113.7"}}, timeout=60)
b1 = F.snapshot([root])
print("---- FRESH-HOST report via main(), exit %d ----\n%s----" % (rc2, out2.decode()))
t.ok(not cfgdir.exists(), "AC-5(fresh): /etc/sing-box still does not exist after `sc doctor`")
t.ok(not (cfgdir / "rules").exists(), "AC-5(fresh): the rules dir was not created")
t.ok(not (cfgdir / "nodes.json").exists(), "AC-5(fresh): nodes.json was not created")
t.ok(not (cfgdir / "settings.json").exists(), "AC-5(fresh): settings.json was not created")
t.eq(sorted(os.listdir(str(root))), [], "AC-5(fresh): the sandbox root is still empty")
t.eq(F.diff_snap(b0, b1), [], "AC-5(fresh): snapshot identical")
_fresh_labels = [l for _m, l in F.labels_of(out2.decode())]
t.eq(len([l for l in _fresh_labels
          if l in ("sing-box binary", "rule-sets", "configuration", "service",
                   "TUN interface", "Clash API", "egress IP")]), 7,
     "FR-5: a complete seven-section report on a host with nothing installed "
     "(%d rows total)" % len(_fresh_labels))

# non-vacuity: the SAME fresh-host assertion must go red for a non-doctor command
root2 = F.mkroot("fresh-ctl")
rc3, out3, err3 = F.run_child({"mode": "main", "argv": ["mode", "global"], "root": str(root2),
                               "lang": "en", "systemd": False}, timeout=60)
created = sorted(os.listdir(str(root2)))
t.ok(created != [], "non-vacuity: `sc mode global` DOES create the tree (%s) — so the "
                    "fresh-host assertion can fail" % created)
t.ok((root2 / "etc-sing-box" / "nodes.json").exists(),
     "C-1/T-6: a non-doctor command still runs _init_files()")
t.eq(oct(os.stat(str(root2 / "etc-sing-box" / "nodes.json")).st_mode & 0o777), "0o600",
     "C-1/T-6: nodes.json is still mode 0600")
st = json.loads((root2 / "etc-sing-box" / "settings.json").read_text())
t.ok("clash_api_port" in st, "C-1/T-6: _resolve_clash_port() still persists a port")

w2 = witness()
t.eq(w2, w0, "AC-6: witness still unchanged at the end of q3")
print("WITNESS END:\n%s" % w2)

F.cleanup(root, root2)
sys.exit(1 if t.done() else 0)
