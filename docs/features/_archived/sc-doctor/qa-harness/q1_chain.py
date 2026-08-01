"""AC-3 / AC-4 — the owner's failure chain, rendered, in both languages.

Hypothesis to falsify: "the rendered screen does not let a reader name the root cause in
causal order" — specifically, that the config-check row appears above the rule-set rows,
or that the checker's message does not name the rule-set problem.

Fixture: rules dir EMPTY, config.json referencing the four missing local rule-sets,
service absent (no init system), TUN absent, no Clash port recorded, egress stubbed.
The sing-box checker is the REAL /usr/local/bin/sing-box 1.13.15 run on a temp-dir config.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q1 AC-3/AC-4 failure chain")
root = F.mkroot("chain")
cfgdir = F.sandbox(root, rulesets="empty",
                   settings={"lang": "en", "mode": "rule", "default_tun": True})
rules = cfgdir / "rules"
(cfgdir / "config.json").write_text(F.broken_config(cfgdir, rules))

snap_before = F.snapshot([root])

reports = {}
for lang in ("en", "zh"):
    rc, out, err = F.run_child({
        "mode": "doctor", "root": str(root), "lang": lang,
        "systemd": False, "openrc": False,
        "egress": {"value": "203.0.113.7"},
    })
    reports[lang] = out.decode()
    t.eq(rc, 1, "%s: exit status is 1 (at least one PROBLEM)" % lang)
    t.eq(err, b"", "%s: stderr empty (no traceback)" % lang)
    t.ok(b"Traceback" not in err, "%s: no traceback" % lang)

snap_after = F.snapshot([root])
t.eq(F.diff_snap(snap_before, snap_after), [], "AC-5(sandbox): fixture unchanged by two runs")

en = reports["en"]
rows = F.labels_of(en)
labels = [l for _m, l in rows]

# (a) the seven section labels appear in FR-6 order, (b) exactly once each
order = ["sing-box binary", "rule-sets", "configuration", "service", "TUN interface",
         "Clash API", "egress IP"]
idx = {}
for name in order:
    hits = [i for i, l in enumerate(labels) if l == name]
    t.eq(len(hits), 1, "AC-3: section label %r appears exactly once" % name)
    if hits:
        idx[name] = hits[0]
t.ok(all(idx.get(order[i], -1) < idx.get(order[i + 1], -1) for i in range(len(order) - 1)),
     "AC-3: seven section labels in S1..S7 order  %s" % [idx.get(o) for o in order])

# FR-7's dependency relation X -> Y : X's label precedes Y's
for x, y in [("sing-box binary", "configuration"), ("rule-sets", "configuration"),
             ("sing-box binary", "service"), ("configuration", "service"),
             ("service", "TUN interface"), ("service", "Clash API"),
             ("TUN interface", "egress IP"), ("Clash API", "egress IP")]:
    t.ok(idx.get(x, 1 << 30) < idx.get(y, -1), "FR-7: %r precedes %r" % (x, y))

# AC-4's three required facts, in order
srs = [i for i, (m, l) in enumerate(rows) if l.endswith(".srs")]
t.eq(len(srs), 4, "AC-4: four rule-set rows printed")
t.ok(all(rows[i][0] == "PROBLEM" for i in srs), "AC-4: all four rule-set rows are PROBLEM")
chk = [i for i, (m, l) in enumerate(rows) if l == "sing-box check"]
t.eq(len(chk), 1, "AC-4: exactly one sing-box check row")
t.ok(chk and srs and max(srs) < chk[0], "AC-4: rule-set rows precede the config check")
t.ok(rows[chk[0]][0] == "PROBLEM" if chk else False, "AC-4: config check is PROBLEM")
t.ok("no such file or directory" in en and ".srs" in en,
     "AC-4: the quoted checker message names the missing rule-set file")
svc = [i for i, (m, l) in enumerate(rows) if l == "service"]
t.ok(svc and chk and chk[0] < svc[0], "AC-4: config check precedes the service rows")

# non-TTY purity on both languages (AC-17 for this scenario)
for lang, text in reports.items():
    b = text.encode()
    t.eq(b.count(b"\x0d"), 0, "AC-17 %s: zero 0x0D" % lang)
    t.eq(b.count(b"\x1b"), 0, "AC-17 %s: zero 0x1B" % lang)

print("\n########## RENDERED REPORT — en ##########")
sys.stdout.write(reports["en"])
print("########## RENDERED REPORT — zh ##########")
sys.stdout.write(reports["zh"])
print("########## END ##########\n")

# --- NON-VACUITY: mutate the product so the causal order is wrong, expect RED ----------
import qa_load  # noqa: E402
src = qa_load.SRC.read_text()
bad = src.replace(
    '    ("rule-sets", _doctor_rulesets),\n    ("configuration", _doctor_config),',
    '    ("configuration", _doctor_config),\n    ("rule-sets", _doctor_rulesets),')
t.ok(bad != src, "non-vacuity: mutation applied to DOCTOR_SECTIONS")
mut = F.HERE / "mutant_sc.py"
mut.write_text(bad)
os.environ["QA_MUTANT"] = str(mut)
rc, out, err = F.run_child({"mode": "doctor", "root": str(root), "lang": "en",
                            "egress": {"value": "203.0.113.7"}},
                           env={"QA_MUTANT": str(mut)})
ml = [l for _m, l in F.labels_of(out.decode())]
mi = {n: (ml.index(n) if n in ml else -1) for n in ("rule-sets", "configuration")}
t.ok(mi["configuration"] < mi["rule-sets"],
     "non-vacuity: with S2/S3 transposed the order assertion WOULD fail (got %s)" % mi)
mut.unlink()

F.cleanup(root)
sys.exit(1 if t.done() else 0)
