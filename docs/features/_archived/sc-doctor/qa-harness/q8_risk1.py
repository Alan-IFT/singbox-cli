"""T-1 / RISK-1 / C-7 — does `sing-box check -c` touch the experimental.cache_file DB?

Hypothesis to falsify: "the external checker opens/creates/updates the cache database it is
told about, so a doctor run is NOT read-only w.r.t. /var/lib/sing-box".

Measured READ-ONLY and on a COPY: a config of generate_config()'s shape whose
experimental.cache_file.path points INSIDE a temp dir the harness owns. The installed
/etc/sing-box/config.json is never passed to the checker (it is root-only anyway) and the
live /var/lib/sing-box/cache.db is only ever fingerprinted, never named to the checker.
"""
import hashlib
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q8 T-1 / RISK-1")
SB = "/usr/local/bin/sing-box"
ver = subprocess.check_output([SB, "version"]).decode().splitlines()[0]
print("checker under test: %s" % ver)


def fp(p):
    if not os.path.exists(p):
        return "ABSENT"
    st = os.stat(p)
    h = hashlib.sha256(open(p, "rb").read()).hexdigest()
    return (st.st_size, st.st_mtime_ns, oct(st.st_mode), h)


def cfg_text(cache_path):
    return json.dumps({
        "log": {"level": "warn"},
        "dns": {"servers": [{"type": "local", "tag": "direct_dns"}], "final": "direct_dns"},
        "inbounds": [{"type": "tun", "tag": "tun-in", "interface_name": "sb-tun",
                      "address": ["172.19.0.1/30"], "mtu": 9000, "auto_route": True,
                      "strict_route": True, "stack": "gvisor"}],
        "outbounds": [{"type": "direct", "tag": "direct"}],
        "route": {"auto_detect_interface": True, "final": "direct"},
        "experimental": {
            "cache_file": {"enabled": True, "path": cache_path, "store_fakeip": False},
            "clash_api": {"external_controller": "127.0.0.1:29199"},
        },
    }, indent=2)


LIVE_CACHE = "/var/lib/sing-box/cache.db"
live0 = fp(LIVE_CACHE)

# --- arm A: the declared cache file does not exist ---
rA = F.mkroot("risk1a")
cacheA = str(rA / "cache.db")
(rA / "config.json").write_text(cfg_text(cacheA))
beforeA = F.snapshot([rA])
p = subprocess.run([SB, "check", "-c", str(rA / "config.json")],
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
afterA = F.snapshot([rA])
print("arm A: rc=%d out=%r" % (p.returncode, p.stdout[:200]))
t.eq(p.returncode, 0, "arm A: the checker accepted the config")
t.ok(not os.path.exists(cacheA), "T-1 arm A: the declared cache file is STILL ABSENT")
t.eq(F.diff_snap(beforeA, afterA), [],
     "T-1 arm A: no file in the config's own directory was created or modified")

# --- arm B: the declared cache file exists with known bytes ---
rB = F.mkroot("risk1b")
cacheB = rB / "cache.db"
cacheB.write_bytes(b"QA-SENTINEL-" + b"\x00" * 4096)
os.utime(str(cacheB), ns=(0, 0))
(rB / "config.json").write_text(cfg_text(str(cacheB)))
b4 = fp(str(cacheB))
beforeB = F.snapshot([rB])
p = subprocess.run([SB, "check", "-c", str(rB / "config.json")],
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
afterB = F.snapshot([rB])
print("arm B: rc=%d out=%r" % (p.returncode, p.stdout[:200]))
t.eq(fp(str(cacheB)), b4, "T-1 arm B: the pre-existing cache file is byte/mtime identical")
t.eq(F.diff_snap(beforeB, afterB), [], "T-1 arm B: nothing else in the directory moved")

# --- arm C: the failing-config path (the one doctor actually quotes) ---
rC = F.mkroot("risk1c")
cacheC = str(rC / "cache.db")
badcfg = json.loads(cfg_text(cacheC))
badcfg["route"]["rule_set"] = [{"tag": "geoip-cn", "type": "local", "format": "binary",
                                "path": str(rC / "missing.srs")}]
(rC / "config.json").write_text(json.dumps(badcfg, indent=2))
beforeC = F.snapshot([rC])
p = subprocess.run([SB, "check", "-c", str(rC / "config.json")],
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
afterC = F.snapshot([rC])
t.ok(p.returncode != 0, "arm C: the checker rejected the broken config")
t.ok(not os.path.exists(cacheC), "T-1 arm C: a FAILING check also creates no cache file")
t.eq(F.diff_snap(beforeC, afterC), [], "T-1 arm C: nothing created or modified")

# --- control: the LIVE cache file, fingerprinted around the whole experiment ---
t.eq(fp(LIVE_CACHE), live0, "T-1 control: /var/lib/sing-box/cache.db untouched throughout")

# --- I-2: can a credential reach doctor's stdout through the quoted checker message? ---
rD = F.mkroot("i2")
cred = json.loads(cfg_text(str(rD / "cache.db")))
cred["outbounds"] = [
    {"type": "vless", "tag": "proxy", "server": "example.com", "server_port": 443,
     "uuid": "11111111-2222-3333-4444-555555555555", "flow": "xtls-rprx-vision",
     "tls": {"enabled": True, "server_name": "sni.example.com"}},
    {"type": "trojan", "tag": "t2", "server": "example.org", "server_port": 443,
     "password": "SUPERSECRETPASSWORD", "tls": {"enabled": True}},
    {"type": "direct", "tag": "direct"},
]
cred["route"]["final"] = "proxy"
# make it fail in three different ways, one per run, and read every message
variants = {
    "missing-ruleset": lambda d: d["route"].__setitem__(
        "rule_set", [{"tag": "geoip-cn", "type": "local", "format": "binary",
                      "path": str(rD / "nope.srs")}]),
    "bad-uuid": lambda d: d["outbounds"][0].__setitem__("uuid", "not-a-uuid"),
    "unknown-field": lambda d: d["outbounds"][1].__setitem__("nosuchfield", "SUPERSECRETPASSWORD"),
    "bad-password-type": lambda d: d["outbounds"][1].__setitem__("password", {"a": 1}),
}
SECRETS = ["11111111-2222-3333-4444-555555555555", "SUPERSECRETPASSWORD"]
for name, mutate in variants.items():
    d = json.loads(json.dumps(cred))
    mutate(d)
    f = rD / ("cfg-%s.json" % name)
    f.write_text(json.dumps(d, indent=2))
    p = subprocess.run([SB, "check", "-c", str(f)],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    msg = p.stdout.decode("utf-8", "replace")
    print("--- I-2 variant %s (rc=%d) ---\n%s" % (name, p.returncode, msg.strip()[:600]))
    if p.returncode == 0:
        continue
    leaked = [s for s in SECRETS if s in msg]
    t.eq(leaked, [], "I-2 %s: no credential value in the checker's message" % name)

F.cleanup(rA, rB, rC, rD)
sys.exit(1 if t.done() else 0)
