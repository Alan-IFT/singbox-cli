"""Fixture + snapshot helpers for the sc-doctor QA harness."""
import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(os.path.dirname(os.path.abspath(__file__)))
CHILD = HERE / "qa_child.py"
SRS_GOOD = b"SRS" + b"\x03" + b"\x00" * 700          # magic + >= 16 bytes


def mkroot(tag):
    d = Path(tempfile.mkdtemp(prefix="qa-%s-" % tag))
    return d


def sandbox(root, rulesets="good", config=None, settings=None, nodes=True):
    """Build root/etc-sing-box.  rulesets: 'good' | 'empty' | 'nodir' | dict{fname:bytes}"""
    cfg = root / "etc-sing-box"
    cfg.mkdir(parents=True, exist_ok=True)
    names = ["geoip-cn.srs", "geosite-cn.srs", "geosite-google.srs", "geosite-private.srs"]
    if rulesets == "nodir":
        pass
    else:
        rd = cfg / "rules"
        rd.mkdir(exist_ok=True)
        if rulesets == "good":
            for n in names:
                (rd / n).write_bytes(SRS_GOOD)
        elif rulesets == "empty":
            pass
        elif isinstance(rulesets, dict):
            for n, b in rulesets.items():
                (rd / n).write_bytes(b)
    if config is not None:
        (cfg / "config.json").write_text(config)
    if settings is not None:
        (cfg / "settings.json").write_text(json.dumps(settings, indent=2))
    if nodes:
        (cfg / "nodes.json").write_text(json.dumps({"active": None, "nodes": []}))
    return cfg


def broken_config(cfg_dir, rules_dir):
    """A config of generate_config()'s shape whose four local rule-sets are MISSING.

    This is the owner's post-mortem: the config was generated when the .srs files were
    usable, the downloads then timed out and left the directory empty.
    """
    doc = {
        "log": {"level": "warn"},
        "dns": {"servers": [{"type": "local", "tag": "direct_dns"}], "final": "direct_dns"},
        "inbounds": [{"type": "tun", "tag": "tun-in", "interface_name": "sb-tun",
                      "address": ["172.19.0.1/30"], "mtu": 9000, "auto_route": True,
                      "strict_route": True, "stack": "gvisor"}],
        "outbounds": [{"type": "direct", "tag": "direct"}],
        "route": {
            "auto_detect_interface": True,
            "rules": [{"outbound": "direct", "rule_set": ["geoip-cn"]}],
            "rule_set": [
                {"tag": t, "type": "local", "format": "binary",
                 "path": str(Path(rules_dir) / (t + ".srs"))}
                for t in ("geoip-cn", "geosite-cn", "geosite-google", "geosite-private")
            ],
            "final": "direct",
        },
    }
    return json.dumps(doc, indent=2)


def fakebin(d, name, body):
    d = Path(d)
    d.mkdir(parents=True, exist_ok=True)
    p = d / name
    p.write_text("#!/bin/sh\n" + body + "\n")
    p.chmod(0o755)
    return p


def snapshot(paths):
    """existence, size, mtime_ns, mode, sha256 for every path under each root."""
    out = {}
    for rootp in paths:
        rootp = Path(rootp)
        if not rootp.exists():
            out[str(rootp)] = "ABSENT"
            continue
        stack = [rootp]
        while stack:
            p = stack.pop()
            try:
                st = p.lstat()
            except OSError as e:
                out[str(p)] = "STATERR:%s" % e.errno
                continue
            rec = {"size": st.st_size, "mtime_ns": st.st_mtime_ns,
                   "mode": oct(st.st_mode), "ino": st.st_ino}
            if stat.S_ISREG(st.st_mode):
                try:
                    h = hashlib.sha256()
                    with p.open("rb") as fh:
                        for chunk in iter(lambda: fh.read(65536), b""):
                            h.update(chunk)
                    rec["sha256"] = h.hexdigest()
                except OSError as e:
                    rec["sha256"] = "UNREADABLE:%s" % e.errno
            elif stat.S_ISDIR(st.st_mode):
                try:
                    stack.extend(sorted(p.iterdir()))
                except OSError as e:
                    rec["listing"] = "UNREADABLE:%s" % e.errno
            out[str(p)] = rec
    return out


def diff_snap(a, b):
    keys = sorted(set(a) | set(b))
    d = []
    for k in keys:
        if a.get(k) != b.get(k):
            d.append((k, a.get(k), b.get(k)))
    return d


def run_child(cfg, env=None, timeout=90, stdout_path=None):
    """Run one qa_child.py.  Returns (rc, stdout_bytes, stderr_bytes)."""
    f = Path(tempfile.mkstemp(prefix="qacfg-", suffix=".json")[1])
    f.write_text(json.dumps(cfg))
    e = dict(os.environ)
    e["PYTHONDONTWRITEBYTECODE"] = "1"
    if env:
        e.update(env)
    if stdout_path:
        with open(stdout_path, "wb") as fh:
            p = subprocess.Popen([sys.executable, str(CHILD), str(f)],
                                 stdout=fh, stderr=subprocess.PIPE, env=e)
            _, err = p.communicate(timeout=timeout)
        return p.returncode, Path(stdout_path).read_bytes(), err
    p = subprocess.Popen([sys.executable, str(CHILD), str(f)],
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=e)
    out, err = p.communicate(timeout=timeout)
    return p.returncode, out, err


def labels_of(text):
    """The [CLASS] label part of every marked row, in order."""
    rows = []
    for line in text.splitlines():
        if line.startswith("["):
            mark, rest = line[1:].split("] ", 1)
            label = rest.split(": ", 1)[0]
            rows.append((mark, label))
    return rows


def cleanup(*roots):
    for r in roots:
        shutil.rmtree(str(r), ignore_errors=True)
