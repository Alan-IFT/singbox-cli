"""Non-vacuity for the remaining load-bearing assertions, plus stability (10 repeats).

Every mutation below is applied to a COPY of bin/sc loaded through the QA loader; the
working tree is never edited. A green assertion that cannot be made red proves nothing.
"""
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q10 non-vacuity + stability")
src = qa_load.SRC.read_text()
GOODCFG = '{"log": {"level": "warn"}, "outbounds": [{"type":"direct","tag":"direct"}], ' \
          '"route": {"final": "direct"}}'
SECTIONS = ["sing-box binary", "rule-sets", "configuration", "service", "TUN interface",
            "Clash API", "egress IP"]


def run(root, mutant=None, **extra):
    cfg = {"mode": "doctor", "root": str(root), "lang": "en",
           "egress": {"value": "203.0.113.7"}}
    cfg.update(extra)
    env = {"QA_MUTANT": str(mutant)} if mutant else None
    return F.run_child(cfg, env=env)


TUNANCHOR = '''    try:
        code, out = _doctor_run(["ip", "-br", "addr", "show", TUN_IFACE])'''


def mutate(name, a, b, count=1):
    assert src.count(a) == count, "%s: anchor appears %d times" % (name, src.count(a))
    p = F.HERE / ("mut_%s.py" % name)
    p.write_text(src.replace(a, b))
    return p


root = F.mkroot("vac")
F.sandbox(root, rulesets="empty", config=GOODCFG, settings={"lang": "en"})

# --- 1. AC-8 isolation: without the driver's except, one failing probe kills the report
m = mutate("noiso",
           "        try:\n            rows = probe()\n        except Exception as e:",
           "        if True:\n            rows = probe()\n        elif False:\n"
           "            e = None")
mb = F.mkroot("vac-iso")
F.sandbox(mb, rulesets="empty", config=GOODCFG, settings={"lang": "en"})
# force an unexpected exception inside S5 by removing _first_line's guard? simpler: make
# _doctor_tun raise by deleting TUN_IFACE's definition in the same mutant
BOOM = TUNANCHOR.replace("    try:", '    raise ValueError("QA boom")\n    try:')
m2 = F.HERE / "mut_noiso2.py"
m2.write_text(m.read_text().replace(TUNANCHOR, BOOM))
assert m2.read_text() != m.read_text()
rc_ok, out_ok, _ = run(mb)                       # control: unmutated
rc_bad, out_bad, err_bad = run(mb, mutant=m2)
t.eq(len([l for _x, l in F.labels_of(out_ok.decode()) if l in SECTIONS]), 7,
     "control: the unmutated build prints all seven sections")
t.ok(len([l for _x, l in F.labels_of(out_bad.decode()) if l in SECTIONS]) < 7,
     "non-vacuity AC-8: removing the driver's `except Exception` DOES truncate the report "
     "(%d/7 sections, stderr has traceback=%s)"
     % (len([l for _x, l in F.labels_of(out_bad.decode()) if l in SECTIONS]),
        b"Traceback" in err_bad))
# and with isolation present the same broken probe costs only its own section
m3 = mutate("tunboom", TUNANCHOR, BOOM)
rc3, out3, err3 = run(mb, mutant=m3)
t.eq(len([l for _x, l in F.labels_of(out3.decode()) if l in SECTIONS]), 7,
     "AC-8/FR-9: with isolation, an unexpected exception inside one probe costs only that "
     "section — all seven labels still print")
t.ok(b"Traceback" not in err3, "AC-22: and still no traceback")
t.ok("this check could not run:" in out3.decode(),
     "FR-9: the failed probe becomes one UNKNOWN row naming the cause")

# --- 2. AC-17: without _plain(), the checker's ESC bytes reach the report
ESCBIN = root / "escbin"
F.fakebin(ESCBIN, "sing-box",
          'if [ "$1" = version ]; then printf "v1\\r\\n"; exit 0; fi; '
          'printf "\\033[31mFATAL\\033[0m boom\\r\\n"; exit 1')
rc_c, out_c, _ = F.run_child({"mode": "doctor", "root": str(root), "lang": "en",
                              "egress": {"value": "1.2.3.4"}}, env={"PATH": str(ESCBIN)})
t.eq(out_c.count(b"\x1b"), 0, "AC-17: a checker emitting real ESC/CR still yields zero 0x1B")
t.eq(out_c.count(b"\x0d"), 0, "AC-17: ... and zero 0x0D")
m4 = mutate("noplain",
            '    return r.returncode, _plain(r.stdout.decode("utf-8", "replace"))',
            '    return r.returncode, r.stdout.decode("utf-8", "replace")')
rc_m, out_m, _ = F.run_child({"mode": "doctor", "root": str(root), "lang": "en",
                              "egress": {"value": "1.2.3.4"}},
                             env={"PATH": str(ESCBIN), "QA_MUTANT": str(m4)})
t.ok(out_m.count(b"\x1b") > 0,
     "non-vacuity AC-17: without _plain() the report DOES carry 0x1B (%d) — the assertion "
     "can fail. (A bare CR is additionally neutralised by splitlines(), so _plain()'s CR "
     "removal is what stops a CR from splitting one logical row across two physical lines.)"
     % out_m.count(b"\x1b"))

# --- 3. AC-5 read-only: if doctor took main()'s else arm it would create the tree
fresh = F.mkroot("vac-fresh")
rcf, outf, _ = F.run_child({"mode": "main", "argv": ["doctor"], "root": str(fresh),
                            "lang": "en", "egress": {"value": "1.2.3.4"}})
t.eq(os.listdir(str(fresh)), [], "AC-5: `sc doctor` created nothing")
m5 = mutate("initdoctor", '    if args.cmd == "doctor":', '    if args.cmd == "__never__":')
fresh2 = F.mkroot("vac-fresh2")
rcf2, outf2, _ = F.run_child({"mode": "main", "argv": ["doctor"], "root": str(fresh2),
                              "lang": "en", "egress": {"value": "1.2.3.4"}},
                             env={"QA_MUTANT": str(m5)})
t.ok(os.listdir(str(fresh2)) != [],
     "non-vacuity AC-5: routing doctor through the else arm DOES create the tree (%s) — "
     "so the read-only assertion can fail" % os.listdir(str(fresh2)))

# --- 4. AC-14: a mutant that prints st_size instead of the read length
m6 = mutate("stsize", '    return (srs_reject_reason(head, size) or "usable", '
                      'digest.hexdigest(), size)',
            '    return (srs_reject_reason(head, size) or "usable", digest.hexdigest(), '
            'path.stat().st_size)')
r14 = F.mkroot("vac-stsize")
c14 = F.sandbox(r14, rulesets="empty", settings={"lang": "en"})
os.symlink("/proc/version", str(c14 / "rules" / "geoip-cn.srs"))
real = len(open("/proc/version", "rb").read())
rc_a, out_a, _ = run(r14)
rc_b, out_b, _ = run(r14, mutant=m6)
t.ok(("%d bytes" % real) in out_a.decode(), "AC-14: the shipped build prints the read length")
t.ok("0 bytes" in out_b.decode() and ("%d bytes" % real) not in out_b.decode(),
     "non-vacuity AC-14: an st_size mutant prints 0 — the assertion can fail")

# --- 5. stability: ten repeats of the same fixture must be byte-identical -------------
stab = F.mkroot("stab")
F.sandbox(stab, rulesets="empty", config=GOODCFG, settings={"lang": "en"})
digs = set()
codes = set()
for i in range(10):
    rc, out, err = run(stab)
    digs.add(hashlib.sha256(out).hexdigest())
    codes.add(rc)
    if err:
        t.ok(False, "stability run %d wrote to stderr: %r" % (i, err[:120]))
t.eq(len(digs), 1, "stability: 10 identical runs produced 1 distinct report (%d)" % len(digs))
t.eq(len(codes), 1, "stability: 10 identical runs produced 1 distinct exit status %s" % codes)

# --- 6. BC-16 two concurrent doctor runs -------------------------------------------
import subprocess  # noqa: E402
import json  # noqa: E402
cf = stab / "cc.json"
cf.write_text(json.dumps({"mode": "doctor", "root": str(stab), "lang": "en",
                          "egress": {"value": "203.0.113.7"}}))
ps = [subprocess.Popen([sys.executable, str(F.CHILD), str(cf)],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE) for _ in range(2)]
outs = [p.communicate(timeout=90) for p in ps]
t.eq(outs[0][0], outs[1][0], "BC-16: two concurrent doctor runs produce identical reports")
t.eq(ps[0].returncode, ps[1].returncode, "BC-16: ... and identical exit statuses")

for f in F.HERE.glob("mut_*.py"):
    f.unlink()
F.cleanup(root, mb, fresh, fresh2, r14, stab)
sys.exit(1 if t.done() else 0)
