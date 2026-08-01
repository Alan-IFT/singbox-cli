"""AC-8 / AC-9 / AC-10 / AC-11 / AC-17 / AC-21 / AC-22 + BC-1..BC-13.

Hypothesis to falsify for AC-8: "at least one forced probe failure truncates the report" —
i.e. some section label goes missing, or the process dies abnormally.
Seven independent forced failures, one per section, each asserted on ALL SEVEN labels.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q2 AC-8/9/10/11/17/21/22")
SECTIONS = ["sing-box binary", "rule-sets", "configuration", "service", "TUN interface",
            "Clash API", "egress IP"]
ZH = ["sing-box 可执行文件", "规则集", "配置文件", "服务", "TUN 接口", "Clash API", "出口 IP"]

root = F.mkroot("probes")
BIN = root / "fakebin"
BIN.mkdir()
EMPTYBIN = root / "emptybin"
EMPTYBIN.mkdir()
# a fake `ip` that reports the device missing, and one that is simply absent
F.fakebin(BIN, "ip", 'echo "Device \\"sb-tun\\" does not exist." >&2; exit 1')
F.fakebin(BIN, "systemctl", 'case "$1" in is-active) exit 3;; '
                            'is-enabled) echo disabled; exit 1;; esac; exit 0')
F.fakebin(BIN, "sing-box", 'exec /usr/local/bin/sing-box "$@"')

GOODCFG = json.dumps({"log": {"level": "warn"},
                      "inbounds": [], "outbounds": [{"type": "direct", "tag": "direct"}],
                      "route": {"final": "direct"}}, indent=2)


def scenario(name, *, rulesets="good", config=GOODCFG, settings=None, path=None,
             egress=None, clash=None, systemd=False, lang="en", expect_exit=None):
    r = F.mkroot("sc-" + name)
    F.sandbox(r, rulesets=rulesets, config=config,
              settings=settings if settings is not None
              else {"lang": lang, "clash_api_port": 29199})
    cfg = {"mode": "doctor", "root": str(r), "lang": lang, "systemd": systemd,
           "egress": egress if egress is not None else {"value": "203.0.113.7"}}
    if clash is not None:
        cfg["clash"] = clash
    env = {"PATH": path} if path else None
    outf = r / "out.txt"
    rc, out, err = F.run_child(cfg, env=env, stdout_path=str(outf))
    text = out.decode()
    labels = [l for _m, l in F.labels_of(text)]
    want = ZH if lang == "zh" else SECTIONS
    for s in want:
        t.ok(s in labels, "AC-8 %s: section label %r printed" % (name, s))
    t.ok(b"Traceback" not in err, "AC-22 %s: no traceback on stderr (%r)" % (name, err[:120]))
    t.ok(rc in (0, 1, 2), "AC-21 %s: exit status in {0,1,2}, got %d" % (name, rc))
    t.eq(out.count(b"\x0d"), 0, "AC-17 %s: zero 0x0D in redirected file" % name)
    t.eq(out.count(b"\x1b"), 0, "AC-17 %s: zero 0x1B in redirected file" % name)
    if expect_exit is not None:
        t.eq(rc, expect_exit, "AC-21 %s: exit status" % name)
    return r, rc, text, labels


BASE = os.environ["PATH"]
NOSB = str(EMPTYBIN)
FAKE = str(BIN) + ":" + BASE

# --- the seven forced failures -------------------------------------------------------
# 1. S1: binary renamed away (BC-1)
r1, rc1, tx1, lb1 = scenario("S1-no-binary", path=NOSB, expect_exit=1)
t.ok("[PROBLEM] sing-box binary: not found on PATH" in tx1, "BC-1: S1 PROBLEM not-found")
t.ok("[UNKNOWN] sing-box check: no sing-box binary on PATH" in tx1,
     "AC-11/FR-8: missing binary makes S3's check UNKNOWN, not 'config invalid'")
t.ok("[UNKNOWN] configuration" not in tx1, "BC-1: the config file row itself is still OK")

# 2. S2: rules directory emptied (BC-2) and absent (BC-3)
r2, rc2, tx2, lb2 = scenario("S2-empty-rules", rulesets="empty", expect_exit=1)
t.eq(tx2.count(".srs"), 4, "BC-2: four rule-set rows with an empty rules dir")
r2b, rc2b, tx2b, _ = scenario("S2-no-rules-dir", rulesets="nodir", expect_exit=1)
t.eq(tx2b.count(".srs"), 4, "BC-3: four rule-set rows with NO rules dir")
t.ok(not (r2b / "etc-sing-box" / "rules").exists(), "BC-3: doctor did not create the rules dir")

# 3. S3: config removed (BC-6a)
r3, rc3, tx3, lb3 = scenario("S3-no-config", config=None, expect_exit=1)
t.ok("[PROBLEM] configuration: no file at " in tx3, "BC-6a: absent config = PROBLEM 'no file'")
t.ok("sing-box check" not in tx3, "BC-6a: no check row when there is no file")

# 3b. AC-10 invalid config
r3b, rc3b, tx3b, lb3b = scenario("S3-invalid-config", config="{ this is not json ",
                                 expect_exit=1)
t.eq(len([l for l in lb3b if l in SECTIONS]), 7, "AC-10: all seven sections with a bad config")
t.ok("[PROBLEM] sing-box check:" in tx3b, "AC-10: malformed config = PROBLEM with a cause")

# 3c. BC-6b EACCES is never rendered as absence
r3c = F.mkroot("sc-S3-eacces")
cfgd = F.sandbox(r3c, config=GOODCFG, settings={"lang": "en"})
os.chmod(str(cfgd / "config.json"), 0o000)
rc, out, err = F.run_child({"mode": "doctor", "root": str(r3c), "lang": "en",
                            "egress": {"value": "1.2.3.4"}})
tx = out.decode()
t.ok("[UNKNOWN] configuration: cannot read " in tx,
     "BC-6b: EACCES config = UNKNOWN 'cannot read', never absence")
t.ok("no file at" not in tx, "BC-6b: a permission failure is not rendered as absence")
os.chmod(str(cfgd / "config.json"), 0o644)

# 4. S4: service stopped, under a fake systemd (AC-9 — the load-bearing instance)
r4, rc4, tx4, lb4 = scenario("S4-service-down", path=FAKE, systemd=True, expect_exit=1)
t.ok("[PROBLEM] service: not running (via systemd)" in tx4, "AC-9: stopped service = PROBLEM")
t.ok("[PROBLEM] boot autostart: not enabled (disabled)" in tx4,
     "FR-14: 'starts at boot' is a separate fact carrying the state word")
srs_rows = [l for l in lb4 if l.endswith(".srs")]
t.eq(len(srs_rows), 4, "AC-9: a dead service does NOT suppress the four rule-set rows")
t.ok("[OK] rule-sets: 4/4 usable" in tx4, "AC-9: the rule-set summary is still computed")

# 4b. BC-8 neither init system
r4b, rc4b, tx4b, _ = scenario("S4-no-init", systemd=False)
t.ok(tx4b.count("no init system detected (neither systemd nor OpenRC)") == 2,
     "BC-8: both S4 rows UNKNOWN naming that no init system was detected")

# 5. S5: TUN absent (BC-10) and `ip` missing entirely (BC-9)
r5, rc5, tx5, lb5 = scenario("S5-tun-absent", path=FAKE, systemd=True, expect_exit=1)
t.ok("[PROBLEM] TUN interface: sb-tun does not exist" in tx5, "BC-10: missing TUN = PROBLEM")
r5b, rc5b, tx5b, lb5b = scenario("S5-no-ip-tool", path=NOSB)
t.ok("[UNKNOWN] TUN interface: cannot query: " in tx5b,
     "BC-9: a missing `ip` tool = UNKNOWN, distinct from BC-10's PROBLEM")
t.eq(len([l for l in lb5b if l in SECTIONS]), 7, "BC-9: all seven sections still printed")

# 6. S6: port recorded but unreachable (BC-12), and no port recorded (BC-11)
r6, rc6, tx6, lb6 = scenario("S6-port-dead", expect_exit=1)
t.ok("[OK] Clash API: 127.0.0.1:29199" in tx6, "S6: the persisted port is reported")
t.ok("[PROBLEM] Clash API responding: no answer within the 3s timeout" in tx6,
     "BC-12: port persisted + nothing listening = PROBLEM, not UNKNOWN")
r6b, rc6b, tx6b, _ = scenario("S6-no-port", settings={"lang": "en"})
t.ok("[UNKNOWN] Clash API: no port recorded in settings.json" in tx6b, "BC-11: no port = UNKNOWN")
t.ok("[UNKNOWN] Clash API responding: not probed — no port recorded" in tx6b,
     "FR-15: doctor never invents a port to test")

# 7. S7: egress query fails (BC-13)
r7, rc7, tx7, lb7 = scenario("S7-egress-fails", egress={"raise": "urlopen error timed out"},
                             expect_exit=1)
t.ok("[PROBLEM] egress IP: (error: urlopen error timed out)" in tx7,
     "BC-13: a failing egress query = PROBLEM with the cause")

# --- AC-11: three outcome classes only, from a fixed set ------------------------------
marks = set()
for tx in (tx1, tx2, tx3, tx3b, tx4, tx4b, tx5, tx5b, tx6, tx6b, tx7):
    marks |= set(m for m, _l in F.labels_of(tx))
t.eq(sorted(marks), ["OK", "PROBLEM", "UNKNOWN"], "AC-11: exactly three class markers, fixed set")

# --- AC-21: determinism across language / TTY-ness / repetition -----------------------
det = F.mkroot("det")
F.sandbox(det, rulesets="empty", config=GOODCFG, settings={"lang": "en"})
codes = []
for lang in ("en", "zh", "en", "zh"):
    rc, out, err = F.run_child({"mode": "doctor", "root": str(det), "lang": lang,
                                "egress": {"value": "1.2.3.4"}})
    codes.append(rc)
t.eq(len(set(codes)), 1, "AC-21: identical status across languages and repeated runs %s" % codes)
# redirected vs pipe: run_child already pipes; stdout_path writes a real file
rc_file, out_file, _ = F.run_child({"mode": "doctor", "root": str(det), "lang": "en",
                                    "egress": {"value": "1.2.3.4"}},
                                   stdout_path=str(det / "o.txt"))
t.eq(rc_file, codes[0], "AC-21: identical status to a file and to a pipe")

# exit-map coverage: 0 / 1 / 2 all reachable, and only those
allrc = {rc1, rc2, rc3, rc4, rc5b, rc6, rc7, rc_file}
t.ok(allrc <= {0, 1, 2}, "AC-21: at most three distinct statuses %s" % sorted(allrc))
# exit 2 = no PROBLEM but at least one UNKNOWN
r8 = F.mkroot("exit2")
F.sandbox(r8, rulesets="good", config=GOODCFG, settings={"lang": "en"})
rc8, out8, _ = F.run_child({"mode": "doctor", "root": str(r8), "lang": "en",
                            "egress": {"value": "1.2.3.4"}, "systemd": False},
                           env={"PATH": str(BIN) + ":" + BASE})
tx8 = out8.decode()
has_problem = any(m == "PROBLEM" for m, _ in F.labels_of(tx8))
has_unknown = any(m == "UNKNOWN" for m, _ in F.labels_of(tx8))
t.ok(rc8 == 1 if has_problem else (rc8 == 2 if has_unknown else rc8 == 0),
     "AC-21: exit map holds (problem=%s unknown=%s rc=%d)" % (has_problem, has_unknown, rc8))

# a genuinely all-OK run must exit 0 -> stub every environment-dependent probe
r9 = F.mkroot("allok")
F.sandbox(r9, rulesets="good", config=GOODCFG,
          settings={"lang": "en", "clash_api_port": 29199})
F.fakebin(BIN, "systemctl2", "true")
OKBIN = r9 / "okbin"
F.fakebin(OKBIN, "systemctl", 'case "$1" in is-active) exit 0;; is-enabled) echo enabled; '
                              'exit 0;; esac; exit 0')
F.fakebin(OKBIN, "ip", 'echo "sb-tun           UNKNOWN        172.19.0.1/30"')
F.fakebin(OKBIN, "sing-box", 'if [ "$1" = version ]; then echo "sing-box version 1.13.15"; '
                             'else exit 0; fi')
rc9, out9, err9 = F.run_child({"mode": "doctor", "root": str(r9), "lang": "en",
                               "systemd": True, "egress": {"value": "203.0.113.7"},
                               "clash": {"answer": {}}},
                              env={"PATH": str(OKBIN)})
tx9 = out9.decode()
t.ok(all(m == "OK" for m, _ in F.labels_of(tx9)), "AC-21: healthy fixture is all-OK\n%s" % tx9)
t.eq(rc9, 0, "AC-21: an all-OK report exits 0")
t.ok("[OK] Clash API responding: yes" in tx9,
     "R-8: clash_api() returning a falsy {} is read as an answer (`is not None`)")
# AC-24 screen budget, measured on the healthy report
lines = tx9.rstrip("\n").split("\n")
t.ok(len(lines) <= 25, "AC-24: healthy report is %d physical lines (<=25)" % len(lines))
widest = max((len(l), l) for l in lines)
t.ok(widest[0] <= 80, "AC-24: widest healthy row is %d columns (<=80): %r" % widest)
print("HEALTHY REPORT (%d lines, widest %d cols):\n%s" % (len(lines), widest[0], tx9))

# --- BC-7 multi-line checker message --------------------------------------------------
r10 = F.mkroot("bc7")
F.sandbox(r10, config=GOODCFG, settings={"lang": "en"})
MB = r10 / "mb"
F.fakebin(MB, "sing-box", 'if [ "$1" = version ]; then echo v; exit 0; fi; '
                          'i=1; while [ $i -le 9 ]; do echo "line $i"; i=$((i+1)); done; exit 1')
rc10, out10, _ = F.run_child({"mode": "doctor", "root": str(r10), "lang": "en",
                              "egress": {"value": "1.2.3.4"}}, env={"PATH": str(MB)})
tx10 = out10.decode()
quoted = [l for l in tx10.split("\n") if l.startswith("    ")]
t.eq(len([q for q in quoted if q.strip().startswith("line ")]), 5,
     "BC-7: exactly five verbatim lines quoted")
t.ok("line 1" in tx10, "BC-7: the first line is always printed")
t.ok("... 4 more line(s) not shown" in tx10, "BC-7: the elision marker states how many dropped")

# --- BC-4 the odd rule-set shapes -----------------------------------------------------
r11 = F.mkroot("bc4")
c11 = F.sandbox(r11, rulesets={"geosite-cn.srs": b"", "geosite-google.srs": b"<html>err</html>",
                               "geosite-private.srs": F.SRS_GOOD},
                config=GOODCFG, settings={"lang": "en"})
(c11 / "rules" / "geoip-cn.srs").mkdir()          # a directory where a file should be
rc11, out11, _ = F.run_child({"mode": "doctor", "root": str(r11), "lang": "en",
                              "egress": {"value": "1.2.3.4"}})
tx11 = out11.decode()
t.ok("[PROBLEM] geoip-cn.srs: unreadable, size unavailable" in tx11,
     "BC-4: a directory maps to `unreadable`, size not-available (FR-12)")
t.ok("[PROBLEM] geosite-cn.srs: file too small, 0 bytes" in tx11,
     "BC-4/FR-12: a readable EMPTY file reports a real 0 from the read, not not-available")
t.ok("[PROBLEM] geosite-google.srs: not a rule-set file, 16 bytes" in tx11,
     "BC-4: an HTML error page maps to bad-magic with the read length")
t.ok("[OK] geosite-private.srs: usable, 704 bytes" in tx11,
     "FR-11/E-9: a usable row renders through the existing status renderer")

F.cleanup(root, det, r8, r9, r10, r11, r3c)
sys.exit(1 if t.done() else 0)
