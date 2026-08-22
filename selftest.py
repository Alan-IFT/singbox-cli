#!/usr/bin/env python3
"""selftest.py — run it: `python3 selftest.py`. Exits 0 when everything holds.

WHAT THIS IS, AND WHAT IT DELIBERATELY IS NOT
---------------------------------------------
One file, the standard library, no framework, no fixtures directory, no plugins, no
configuration: a test collector is not what this project is short of. Every test below
is a plain function named `t_*`; the runner at the bottom finds them by name, gives each
a fresh temporary directory, captures its output and prints it only if it fails. That
runner is 20 lines, and it is the entire harness.

IT RUNS AS A NORMAL USER, and that is the property everything else rests on: `bin/sc` is
loaded as a MODULE and its eight path constants are repointed into a temp directory, so
no test touches /etc, /var or any service. t_import_is_inert is what keeps this true —
it fails the moment anything is added to `bin/sc`'s module body that ACTS.

Two capabilities are used when the host has them and reported as skipped when it does
not: the `sing-box` binary (used to prove the emitted document is one sing-box accepts)
and a real set of `.srs` rule-sets under /etc/sing-box/rules. Nothing is faked in their
place — a synthesized rule-set body is not one sing-box can load, and a test that
asserted otherwise would be asserting the fake. (The DOWNLOADER is a different question:
its validator is srs_reject_reason, not sing-box, so t_update_rules serves it bytes from
a throwaway loopback server and never asks sing-box to load them.)
"""
import ast
import contextlib
import http.server
import importlib.machinery
import importlib.util
import io
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import threading
import traceback
from pathlib import Path

# The suite imports bin/sc and compiles nothing else; without this every run drops a
# 191 KB .pyc into bin/__pycache__/. A test suite may not leave anything in the tree.
sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
SC_SRC = HERE / "bin" / "sc"
REAL_RULES = Path("/etc/sing-box/rules")
HAVE_SINGBOX = shutil.which("sing-box") is not None
HAVE_RULES = REAL_RULES.is_dir()
SKIPPED = []


def load_sc():
    """`bin/sc` as an imported module. Not a subprocess: the point is to call its
    functions directly, which is exactly what a module-level side effect would deny."""
    loader = importlib.machinery.SourceFileLoader("sc", str(SC_SRC))
    spec = importlib.util.spec_from_loader("sc", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


try:
    SC = load_sc()
except BaseException:
    traceback.print_exc()
    sys.exit("bin/sc could not be imported — no test below it can run")


def sandbox(tmp, rulesets=True):
    """Repoint every path constant at `tmp`. THE list — a constant reachable only through
    a function body is repointable, and each of these is, by construction in bin/sc."""
    SC.CFG_DIR = tmp
    SC.CFG_PATH = tmp / "config.json"
    SC.NODES_PATH = tmp / "nodes.json"
    SC.SETTINGS_PATH = tmp / "settings.json"
    SC.OVERRIDE_PATH = tmp / "override.json"
    SC.STATE_PATH = tmp / ".config.sha256"
    SC.RULES_DIR = tmp / "rules"
    SC.TIMER_DROPIN_DIR = tmp / "timer.d"
    if rulesets and HAVE_RULES:
        shutil.copytree(str(REAL_RULES), str(SC.RULES_DIR))
    else:
        SC.RULES_DIR.mkdir()
    return tmp


@contextlib.contextmanager
def local_source(bodies, seen=None):
    """A throwaway HTTP source on loopback: yields its base URL.

    `bodies` maps a URL path (query string included) to the bytes served, or to a
    (declared_length, bytes) pair when the point is a Content-Length that does not match
    what arrives. A path that is absent is a 404. `seen`, when given, is a list every
    requested path is appended to — which is how the Clash API test asserts the REQUEST
    sc made and not merely what it did with the answer. This is the only thing in the
    suite that opens a port, and it is bound to 127.0.0.1 on an ephemeral number for the
    duration of one test.
    """
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            if seen is not None:
                seen.append(self.path)
            body = bodies.get(self.path)
            if body is None:
                self.send_error(404)
                return
            declared, payload = body if isinstance(body, tuple) else (len(body), body)
            self.send_response(200)
            self.send_header("Content-Length", str(declared))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *args):
            pass                                    # the suite owns its own output

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        yield "http://127.0.0.1:%d" % server.server_address[1]
    finally:
        server.shutdown()
        server.server_close()


def dead_base():
    """A base URL nothing listens on — refused at once, never a 30 s timeout."""
    with __import__("socket").socket() as probe:
        probe.bind(("127.0.0.1", 0))
        return "http://127.0.0.1:%d" % probe.getsockname()[1]


# A share link whose reality key is real base64: `sing-box check` decodes it, so a
# placeholder here would fail the very check this suite exists to make.
VLESS = ("vless://11111111-2222-3333-4444-555555555555@node.example:443"
         "?security=reality&pbk=jNXHt1yRo0vDuchQlIP6Z0ZvjT3KtzVI-T4E7RoLJS0"
         "&fp=chrome&flow=xtls-rprx-vision#JP-1")


def seed(tmp, links=(VLESS,)):
    """A sandbox carrying settings, nodes and (where the host has them) rule-sets."""
    sandbox(tmp)
    SC.save_settings({"lang": "en", "default_tun": True})
    nodes = [SC.parse_share_url(u) for u in links]
    SC.save_nodes({"active": None, "nodes": nodes})
    return nodes


# ---------------------------------------------------------------- the contracts

def t_shell_scripts_parse(tmp):
    """`bash -n` on both scripts — the only gate they have.

    bin/sc needs none here: importing it at the top of this file is strictly stronger
    than py_compile, and a syntax error there ends the run with a stated outcome before
    any test is collected.
    """
    for script in ("install.sh", "uninstall.sh"):
        subprocess.run(["bash", "-n", str(HERE / script)], check=True)


def t_import_is_inert(tmp):
    """Importing bin/sc must DO nothing — the property this whole file rests on.

    Enforced against the module body itself, not against a symptom: every top-level
    statement must be a definition, an import, a constant or the __main__ guard. The
    auto-elevate `os.execvp` used to sit here, so importing the file re-exec'd the
    IMPORTING process under sudo; a test that merely ran and passed could not tell you
    that had come back, because the harness would have been the thing sudo replaced.
    """
    tree = ast.parse(SC_SRC.read_text(encoding="utf-8"))
    allowed = (ast.Import, ast.ImportFrom, ast.Assign, ast.AnnAssign,
               ast.FunctionDef, ast.ClassDef)
    for node in tree.body:
        if isinstance(node, allowed):
            continue
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant):
            continue                                    # the module docstring
        if (isinstance(node, ast.If) and isinstance(node.test, ast.Compare)
                and isinstance(node.test.left, ast.Name)
                and node.test.left.id == "__name__"):
            continue                                    # the __main__ guard
        raise AssertionError(
            "bin/sc line %d: a module-level %s ACTS at import time"
            % (node.lineno, type(node).__name__))


def t_share_links(tmp):
    """One assertion per scheme, plus the three userinfo rules nothing else states."""
    def parse(url):
        return SC.parse_share_url(url)

    v = parse(VLESS)
    assert v["type"] == "vless" and v["server"] == "node.example" and v["server_port"] == 443
    assert v["uuid"] == "11111111-2222-3333-4444-555555555555"
    assert v["tag"] == "JP-1" and v["flow"] == "xtls-rprx-vision"
    assert v["tls"]["reality"]["enabled"] and v["tls"]["utls"]["fingerprint"] == "chrome"

    # userinfo: it ends at the LAST "@", splits at the FIRST colon, and is
    # percent-decoded exactly once — a password holding both characters proves all three.
    tr = parse("trojan://p%40ss%3Aword@h.example:8443?sni=x#T")
    assert tr["password"] == "p@ss:word", tr["password"]
    # A RAW "@" in the password: the userinfo ends at the LAST one, so this is the only
    # shape that tells rpartition from partition. Percent-encoded, both agree.
    assert parse("trojan://p@ss@h.example:443#T")["password"] == "p@ss"
    assert parse("trojan://p@ss@h.example:443#T")["server"] == "h.example"
    assert tr["server"] == "h.example" and tr["tls"]["server_name"] == "x"

    ss = parse("ss://YWVzLTI1Ni1nY206c2VjcmV0@h.example:8388#S")
    assert ss["method"] == "aes-256-gcm" and ss["password"] == "secret"

    hy = parse("hysteria2://pw@h.example:443?obfs=salamander&obfs-password=o#H")
    assert hy["password"] == "pw" and hy["obfs"] == {"type": "salamander", "password": "o"}

    tu = parse("tuic://uuid-x:pw@h.example:443?congestion_control=bbr#U")
    assert tu["uuid"] == "uuid-x" and tu["password"] == "pw"
    assert tu["congestion_control"] == "bbr"

    import base64
    vm = "vmess://" + base64.urlsafe_b64encode(json.dumps(
        {"add": "h.example", "port": "443", "id": "u", "ps": "V", "net": "ws",
         "path": "/p", "host": "cdn.example", "tls": "tls"}).encode()).decode()
    m = parse(vm)
    assert m["transport"] == {"type": "ws", "path": "/p", "headers": {"Host": "cdn.example"}}
    assert m["tls"]["server_name"] == "cdn.example"

    for bad in ("http://x", "vless-ish://x", ""):
        try:
            parse(bad)
        except ValueError:
            continue
        raise AssertionError("accepted %r" % bad)


def t_state_files_are_private(tmp):
    """ONE writer for both state documents: atomic, CRED_MODE, and loud when it cannot."""
    sandbox(tmp)
    SC.save_settings({"lang": "zh"})
    SC.save_nodes({"active": "a", "nodes": [{"tag": "a"}]})
    for path in (SC.SETTINGS_PATH, SC.NODES_PATH):
        mode = stat.S_IMODE(path.stat().st_mode)
        assert mode == SC.CRED_MODE, "%s is %03o" % (path.name, mode)
    assert SC.load_settings()["lang"] == "zh"
    assert SC.load_nodes()["active"] == "a"
    assert not [p for p in tmp.iterdir() if ".tmp." in p.name], "temporary left behind"

    # An unusable document is a refusal that names the file, never a silent default.
    SC.SETTINGS_PATH.write_text("{not json")
    try:
        SC.load_settings()
        raise AssertionError("a malformed settings.json was accepted")
    except SC.OverrideError as e:
        assert e.path == SC.SETTINGS_PATH
    assert SC._settings_or_empty() == {}      # the ONE degrade, and it stays silent

    # A node document's ELEMENTS have a contract too, and the reader is where it is
    # checked: generate_config() forms [n["tag"] for n in nodes] outside its guarded
    # region, so without this a hand-edited array ended the run in a traceback.
    for broken in ([1, 2], [{"server": "x"}], [{"tag": ""}], ["vless://..."]):
        SC.save_nodes({"active": None, "nodes": broken})
        try:
            SC.load_nodes()
            raise AssertionError("accepted %r" % (broken,))
        except SC.OverrideError as e:
            assert e.path == SC.NODES_PATH and "non-empty" in str(e), str(e)


def t_generate_config(tmp):
    """The whole composition path, and — where the host has sing-box — its verdict."""
    seed(tmp)
    assert SC.generate_config() is True
    doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))

    assert [o["tag"] for o in doc["outbounds"]] == ["proxy", "auto", "JP-1", "direct"]
    assert doc["outbounds"][0]["default"] == "auto"     # the judge picked the group
    assert SC.load_nodes()["active"] == "auto"          # and persisted the repair
    # AAAA is suppressed unconditionally in this build — no setting, no host probe.
    assert doc["dns"]["rules"][0] == {"action": "predefined", "rcode": "NOERROR",
                                      "query_type": [28, 64, 65]}
    assert doc["experimental"]["clash_api"]["external_controller"].startswith("127.0.0.1:")
    assert stat.S_IMODE(SC.CFG_PATH.stat().st_mode) == SC.CRED_MODE
    assert SC._drift_state() is False
    assert stat.S_IMODE(SC.STATE_PATH.stat().st_mode) == SC.CRED_MODE

    # Whatever is referenced is defined — the one invariant of the rule-set layer.
    defined = {d["tag"] for d in doc["route"].get("rule_set", [])}
    for where in ("dns", "route"):
        for rule in doc[where]["rules"]:
            assert set(rule.get("rule_set", [])) <= defined, rule

    if HAVE_SINGBOX:
        r = subprocess.run(["sing-box", "check", "-c", str(SC.CFG_PATH)],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        assert r.returncode == 0, r.stdout.decode("utf-8", "replace")
    else:
        SKIPPED.append("sing-box check (no sing-box on PATH)")

    # A hand-edit is drift, and the record says so without the document being read.
    SC.CFG_PATH.write_text('{"hand": "edited"}')
    assert SC._drift_state() is True


def t_degradation(tmp):
    """An unusable rule-set costs its own rules and nothing else."""
    if not HAVE_RULES:
        SKIPPED.append("t_degradation (no rule-sets under %s)" % REAL_RULES)
        return
    seed(tmp)
    (SC.RULES_DIR / "geoip-cn.srs").write_bytes(b"<html>error</html>")
    (SC.RULES_DIR / "geosite-cn.srs").unlink()
    report = dict((tag, status) for tag, _f, status in SC.ruleset_report())
    assert report["geoip-cn"] == "bad-magic" and report["geosite-cn"] == "absent"

    assert SC.generate_config() is True
    doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))
    defined = {d["tag"] for d in doc["route"]["rule_set"]}
    assert defined == {"geosite-google", "geosite-private"}, defined
    for where in ("dns", "route"):
        for rule in doc[where]["rules"]:
            assert set(rule.get("rule_set", [])) <= defined, rule
    if HAVE_SINGBOX:
        r = subprocess.run(["sing-box", "check", "-c", str(SC.CFG_PATH)],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        assert r.returncode == 0, r.stdout.decode("utf-8", "replace")

    # Every rule-set gone is the no-splitting document, not a broken one.
    for fname, _rel in SC.RULESET_FILES:
        (SC.RULES_DIR / fname).unlink(missing_ok=True)
    assert SC.generate_config() is True
    doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))
    assert "rule_set" not in doc["route"]       # absent, never an empty array
    assert doc["route"]["final"] == "proxy"


def t_checker_verdict_is_binding(tmp):
    """A document `sing-box check` rejects never becomes the file the service reads.

    The contract the whole candidate -> verdict -> install ordering exists for, and the
    one `sc add` leans on when it puts nodes.json back: a rejection must leave
    config.json byte-identical and the drift record untouched, so the two documents stay
    in step. The rejected value is a log level, chosen because it passes every check
    `sc` itself makes and fails only at the checker — which is exactly the case a test
    of `sc`'s own validation could not produce.
    """
    if not HAVE_SINGBOX:
        SKIPPED.append("t_checker_verdict_is_binding (no sing-box on PATH)")
        return
    seed(tmp)
    assert SC.generate_config() is True
    good = SC.CFG_PATH.read_bytes()
    record = SC.STATE_PATH.read_bytes()

    SC.OVERRIDE_PATH.write_text(json.dumps({"log": {"level": "not-a-level"}}))
    assert SC.generate_config() is False, "a rejected document was installed"
    assert SC.CFG_PATH.read_bytes() == good, "config.json changed on a rejection"
    assert SC.STATE_PATH.read_bytes() == record, "the drift record moved on a rejection"
    assert SC._drift_state() is False
    assert not [p for p in tmp.iterdir() if ".check." in p.name], "candidate left behind"

    SC.OVERRIDE_PATH.unlink()
    assert SC.generate_config() is True
    assert SC.CFG_PATH.read_bytes() == good      # and the same inputs give the same bytes


def t_override(tmp):
    """The user's document is applied last, and every way of writing it wrong is named."""
    seed(tmp)
    SC.generate_config()
    base = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))

    # A depth merge over an object touches one key and moves nothing.
    SC.OVERRIDE_PATH.write_text(json.dumps({"log": {"level": "debug"}}))
    assert SC.generate_config() is True
    doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))
    assert doc["log"] == {"level": "debug", "timestamp": True}
    assert list(doc.keys()) == list(base.keys())

    # A directive on an array, and a user-defined rule-set survives the degrade pass.
    if HAVE_RULES:
        # A REAL body at the user's path: `sing-box check` opens every rule-set it is
        # given, so a placeholder here would be testing the placeholder.
        mine = SC.RULES_DIR / "mine.srs"
        shutil.copyfile(str(SC.RULES_DIR / "geosite-private.srs"), str(mine))
        SC.OVERRIDE_PATH.write_text(json.dumps({"route": {
            "rule_set": {"$append": [{"tag": "mine", "type": "local",
                                      "format": "binary", "path": str(mine)}]},
            "rules": {"$append": [{"rule_set": ["mine"], "outbound": "direct"}]}}}))
        assert SC.generate_config() is True
        doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))
        assert doc["route"]["rules"][-1] == {"rule_set": ["mine"], "outbound": "direct"}
        assert "mine" in {d["tag"] for d in doc["route"]["rule_set"]}
    else:
        SKIPPED.append("t_override: user-defined rule-set (no rule-sets under %s)"
                       % REAL_RULES)

    # Every refusal: named, attributed to the user's file, and before anything is written.
    before = SC.CFG_PATH.read_bytes()
    for bad, fragment in (
            ({"dns": {"rules": [{"server": "x"}]}}, "must be changed with one of"),
            ({"dns": {"rules": {"$nope": []}}}, "unknown directive"),
            ({"log": {"$append": []}}, "already exists"),
            ({"dns": {"rules": {"$append": {}}}}, "must be an array"),
            ({"dns": {"rules": {"$before": {"match": {"server": "nowhere"},
                                            "values": []}}}}, "matched 0 elements"),
            ([1, 2, 3], "must be a JSON object")):
        SC.OVERRIDE_PATH.write_text(json.dumps(bad))
        try:
            SC.generate_config()
            raise AssertionError("accepted %r" % (bad,))
        except SC.OverrideError as e:
            assert fragment in str(e), (fragment, str(e))
            assert e.path == SC.OVERRIDE_PATH
        assert SC.CFG_PATH.read_bytes() == before, "config.json changed on a refusal"

    # Absent, empty and whitespace-only all mean "no override"; a dangling link does not.
    for text in ("", "   \n"):
        SC.OVERRIDE_PATH.write_text(text)
        assert SC._load_override() is None
    SC.OVERRIDE_PATH.unlink()
    assert SC._load_override() is None
    os.symlink(str(tmp / "nowhere.json"), str(SC.OVERRIDE_PATH))
    try:
        SC._load_override()
        raise AssertionError("a dangling symlink read as absent")
    except SC.OverrideError as e:
        assert "symbolic link" in str(e)


def t_selection_is_total(tmp):
    """The judge returns an outbound the same run defines, for every input."""
    cases = [(None, [], None), ("gone", [], None), (None, ["a"], "auto"),
             ("a", ["a", "b"], "a"), ("gone", ["a"], "auto"), ("auto", ["a"], "auto"),
             # A node already tagged `auto` suppresses the group, so the group is never
             # emitted and never selected: the fallback is a real node.
             ("auto", ["auto"], "auto"), (None, ["auto", "b"], "auto")]
    for active, tags, want in cases:
        got = SC._valid_selection(active, tags)
        assert got == want, (active, tags, got, want)
        assert got is None or got in tags or (got == SC.AUTO_TAG
                                              and SC._auto_group_emitted(tags))
    assert SC._unique_tag("auto", set()) == "auto #2"       # reserved tags are minted away
    assert SC._unique_tag("x", {"x"}) == "x #2"


def t_redaction_fails_closed(tmp):
    """`sc config` masks by name everywhere, and by REGION inside outbounds."""
    doc = {"outbounds": [{"type": "vless", "server": "h", "uuid": "U",
                          "tls": {"reality": {"public_key": "P"}},
                          "future_field": {"deep": "S"}}],
           "experimental": {"clash_api": {"secret": "K", "external_ui": "/ui"}}}
    out = SC._redact(doc, False)
    ob = out["outbounds"][0]
    assert ob["uuid"] == SC.MASK and ob["tls"]["reality"]["public_key"] == SC.MASK
    assert ob["future_field"] == SC.MASK, "an unknown key inside outbounds printed"
    assert ob["server"] == "h" and ob["type"] == "vless"     # keys and shape stay visible
    assert out["experimental"]["clash_api"]["secret"] == SC.MASK
    assert out["experimental"]["clash_api"]["external_ui"] == "/ui"
    assert len(SC.MASK) < 8         # short enough not to look like a secret to a scanner


def t_apply_failure_exits(tmp):
    """A command that cannot produce a document may not report success.

    The regression this guards: `sc rm` discarded the answer, printed its success line
    and exited 0 while config.json still carried the node it said it had removed.
    """
    seed(tmp)
    SC.generate_config()
    real = SC.generate_config
    SC.generate_config = lambda: False
    try:
        for command, args in ((SC.cmd_rm, type("A", (), {"spec": "JP-1"})()),
                              (SC.cmd_reload, None)):
            try:
                command(args)
                raise AssertionError("%s reported success" % command.__name__)
            except SystemExit as e:
                assert e.code == SC.t("Reload failed"), e.code
    finally:
        SC.generate_config = real


def t_update_interval_refuses_before_writing(tmp):
    """An OnCalendar systemd will not parse must reach no file, and no systemctl.

    Only the refusal path is exercised, and that is deliberate: it is the path that
    returns before the first subprocess, so this test can never touch a service, a unit
    or the host's systemd — and it is the whole of what changed. Applying a cadence for
    real needs root and is not something a test suite may do to the machine it runs on.
    """
    if not SC.SYSTEMD:
        SKIPPED.append("t_update_interval_refuses_before_writing (no systemctl)")
        return
    sandbox(tmp)
    for value in ("not-a-calendar!!",
                  # The injection shape: a newline used to carry directives of its own
                  # into the unit file, since only leading/trailing space was stripped.
                  "daily\n[Timer]\nUnit=attacker.service"):
        try:
            SC.cmd_update_interval(type("A", (), {"value": value})())
            raise AssertionError("accepted %r" % value)
        except SystemExit as e:
            assert "applying timer failed" in str(e.code), e.code
        assert not SC.TIMER_DROPIN_DIR.exists(), "a refused value reached %s" % SC.TIMER_DROPIN_DIR


def t_installer_credential_sweep(tmp):
    """install.sh's sweep, extracted and run against a temp directory.

    The function names its directory and its file list in variables and touches nothing
    else, which is what makes this possible without running the installer or being root.
    """
    body = subprocess.run(["sed", "-n", "/^sweep_credential_modes() {/,/^}/p",
                           str(HERE / "install.sh")],
                          stdout=subprocess.PIPE, check=True).stdout.decode()
    assert "for f in" in body, "sweep_credential_modes() could not be extracted"
    (tmp / "config.json").write_text("{}")
    os.chmod(str(tmp / "config.json"), 0o644)
    (tmp / "settings.json").write_text("{}")
    os.chmod(str(tmp / "settings.json"), 0o600)
    os.symlink("/etc/shadow", str(tmp / "nodes.json"))
    # CRED_FILES and CRED_MODE are taken FROM install.sh, never restated here: a list
    # the test declares for itself would pass whatever the installer actually sweeps.
    # Only CRED_DIR is overridden, because that is the whole point of running this here.
    decl = subprocess.run(["sed", "-n", "/^CRED_FILES=/p;/^CRED_MODE=/p",
                           str(HERE / "install.sh")],
                          stdout=subprocess.PIPE, check=True).stdout.decode()
    assert "CRED_FILES=" in decl and "CRED_MODE=" in decl, decl
    # Concatenated, not %-formatted: the stub below contains %s of its own.
    script = ("set -euo pipefail\n"
              "t() { printf '%s %s\\n' \"$1\" \"${*:2}\"; }\n"
              + decl + "CRED_DIR=" + str(tmp) + "\n"
              + body + "\nsweep_credential_modes\n")
    out = subprocess.run(["bash", "-c", script], stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT).stdout.decode()
    assert "perm_fixed" in out and "config.json" in out, out
    assert stat.S_IMODE((tmp / "config.json").stat().st_mode) == 0o600, out
    assert "perm_skip" in out, out                       # the symlink was not followed
    assert stat.S_IMODE(os.lstat(str(tmp / "nodes.json")).st_mode) & 0o777 != 0o600
    # One line per entry of install.sh's own list, and settings.json is one of them:
    # already at 0600, so it is reported and left alone rather than narrowed.
    assert "perm_ok" in out and "settings.json" in out, out
    rows = [l for l in out.splitlines()
            if l.startswith("perm_") and not l.startswith("perm_header")]
    assert len(rows) == 3, out          # one row per entry, none silently dropped


def t_i18n_parity(tmp):
    """Every user-facing string this file passes to t() has a zh translation.

    Static, and one-directional on purpose. It reads the literal first argument of every
    t(...) call and asserts the zh table has it — which is exactly the regression a
    bilingual tool has: a new sentence ships and half the UI turns English. It does NOT
    assert the reverse, because keys reached through a VARIABLE (`sc doctor`'s row
    labels, _age_text's unit keys) cannot be seen from here and would read as dead
    entries. That limit is the price of the check being fifteen lines instead of a
    runtime walk of every screen.
    """
    tree = ast.parse(SC_SRC.read_text(encoding="utf-8"))
    zh = {}
    for node in tree.body:
        if (isinstance(node, ast.Assign)
                and getattr(node.targets[0], "id", "") == "TRANSLATIONS"):
            zh = ast.literal_eval(node.value)["zh"]
    assert zh, "TRANSLATIONS['zh'] not found"
    missing = []
    for node in ast.walk(tree):
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                and node.func.id == "t" and node.args
                and isinstance(node.args[0], ast.Constant)
                and isinstance(node.args[0].value, str)
                and node.args[0].value not in zh):
            missing.append("line %d: %r" % (node.lineno, node.args[0].value[:60]))
    assert not missing, "untranslated string(s):\n  " + "\n  ".join(sorted(set(missing)))


def t_add_restores_on_rejection(tmp):
    """`sc add` keeps a node only if a usable document could be made from it.

    The one path in the tool that rolls user data back, and deliberately NOT a caller of
    _apply_or_exit() — it has to put nodes.json back before it says anything — so the
    convergence that now protects the other four commands does not cover it.
    """
    seed(tmp, links=())
    SC.restart_service = restart = lambda: True         # never touch this host's service
    real = SC.generate_config
    try:
        SC.cmd_add(type("A", (), {"url": VLESS})())
        assert [n["tag"] for n in SC.load_nodes()["nodes"]] == ["JP-1"]
        assert SC.load_nodes()["active"] == "auto"
        before = SC.NODES_PATH.read_bytes()

        SC.generate_config = lambda: False              # the checker refuses the next one
        try:
            SC.cmd_add(type("A", (), {"url": VLESS.replace("#JP-1", "#JP-2")})())
            raise AssertionError("a node that yields no usable config was kept")
        except SystemExit as e:
            assert e.code == 1, e.code
        assert SC.NODES_PATH.read_bytes() == before, "nodes.json was not restored"
    finally:
        SC.generate_config = real
        del restart


def t_update_rules(tmp):
    """The downloader: validate, install atomically, and restart only for real changes.

    Served from loopback, so this covers the mirror list, the dead-source skip, the
    byte validation and the change detection without a network or a service. config.json
    is deliberately absent, which is the fresh-install state in which the command does
    not regenerate or restart anything — so no sing-box is asked to load these bytes.
    """
    sandbox(tmp, rulesets=False)
    good = dict(("/" + rel, b"SRS" + bytes(200)) for _f, rel in SC.RULESET_FILES)
    args = type("A", (), {"mirror": None})()
    real_bases = SC.RULESET_BASES
    try:
        with local_source(good) as base:
            SC.RULESET_BASES = (base,)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_update_rules(args)               # no SystemExit == every file landed
            assert "Done" in out.getvalue(), out.getvalue()
            for fname, _rel in SC.RULESET_FILES:
                assert (SC.RULES_DIR / fname).read_bytes() == b"SRS" + bytes(200)
            assert SC.usable_tags(SC.ruleset_report()) == {
                f[:-4] for f, _r in SC.RULESET_FILES}
            assert not [p for p in SC.RULES_DIR.iterdir() if ".tmp." in p.name]

            # Same bytes again: nothing changed, so nothing is touched. This is the
            # regression that used to drop every live connection on the weekly timer.
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_update_rules(args)
            assert "No rule-set changed" in out.getvalue(), out.getvalue()

            # A dead source ahead of a live one: the FIRST file pays the failure and
            # says so, and the remaining three do not — the dead base is not contacted
            # again in this run, which is why their success lines carry no note. Exactly
            # one "fell back after" is the whole evidence for that.
            SC.RULESET_BASES = (dead_base(), base)
            (SC.RULES_DIR / "geoip-cn.srs").write_bytes(b"SRS" + bytes(300))
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_update_rules(args)
            text = out.getvalue()
            assert text.count("fell back after") == 1, text
            assert (SC.RULES_DIR / "geoip-cn.srs").read_bytes() == b"SRS" + bytes(200)
            assert "Rule-sets updated: geoip-cn" in text, text     # only that one changed

        # Every source dead: each file names every base, the skip included, the run ends
        # non-zero, and nothing on disk is touched.
        SC.RULESET_BASES = (dead_base(), dead_base())
        kept = (SC.RULES_DIR / "geosite-cn.srs").read_bytes()
        out, err = io.StringIO(), io.StringIO()
        try:
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
                SC.cmd_update_rules(args)
            raise AssertionError("a run in which every source failed exited 0")
        except SystemExit as e:
            assert e.code == 1, e.code
        assert "skipped (this source already failed" in out.getvalue(), out.getvalue()
        assert "No rule-set changed" in out.getvalue(), out.getvalue()
        assert "4 ruleset(s) failed" in err.getvalue(), err.getvalue()
        assert (SC.RULES_DIR / "geosite-cn.srs").read_bytes() == kept

        # Every body a source can return wrongly, judged before anything is installed.
        target = SC.RULES_DIR / "probe.tmp"
        with local_source({"/short": b"SRS", "/page": b"<html>404</html>" * 3,
                           "/cut": (999, b"SRS" + bytes(200))}) as base:
            for path, fragment in (("/short", "too small"), ("/page", "not a rule-set"),
                                   ("/cut", "truncated")):
                try:
                    SC._fetch_to_temp(base + path, target, "", False)
                    raise AssertionError("accepted %s" % path)
                except ValueError as e:
                    assert fragment in str(e), (path, str(e))
    finally:
        SC.RULESET_BASES = real_bases

    # THE apply decision, and the only place it can be observed: with a config.json on
    # disk. An unconditional restart here is the regression that dropped every live
    # connection — a remote admin's own SSH included — on every weekly timer run, for
    # four files whose bytes had not changed.
    SC.CFG_PATH.write_text("{}")            # only its EXISTENCE is read
    restarts, regens = [], []
    real_restart, real_regen, real_running = (SC.restart_service, SC.generate_config,
                                              SC.is_running)
    SC.restart_service = lambda: restarts.append(1) or True
    SC.generate_config = lambda: regens.append(1) or True
    SC.is_running = lambda: True
    try:
        with local_source(good) as base:
            SC.RULESET_BASES = (base,)
            with contextlib.redirect_stdout(io.StringIO()):
                SC.cmd_update_rules(args)               # identical bytes
            assert (restarts, regens) == ([], []), "unchanged files touched the service"

            # Bytes really differ: reload the data, do NOT regenerate the document —
            # the paths in it did not move.
            (SC.RULES_DIR / "geoip-cn.srs").write_bytes(b"SRS" + bytes(300))
            with contextlib.redirect_stdout(io.StringIO()):
                SC.cmd_update_rules(args)
            assert (len(restarts), regens) == (1, []), (restarts, regens)

            # A rule-set that was absent becomes usable: the document must be rebuilt,
            # because it now has a reference it did not have before.
            (SC.RULES_DIR / "geosite-cn.srs").unlink()
            with contextlib.redirect_stdout(io.StringIO()):
                SC.cmd_update_rules(args)
            assert (len(restarts), len(regens)) == (2, 1), (restarts, regens)
    finally:
        SC.restart_service, SC.generate_config, SC.is_running = (
            real_restart, real_regen, real_running)
        SC.CFG_PATH.unlink()

    # The apply set is a pure function and its two edge rules cannot be reached through
    # the command: a rule-set LOST mid-run is not a change (restarting for it would make
    # sing-box re-read a file it cannot parse), and a None digest means "never read" —
    # it differs from every digest AND from another None.
    was = [("a", "a.srs", "usable", "d1", 1, 1.0), ("b", "b.srs", "usable", "d2", 1, 1.0)]
    lost = [("a", "a.srs", "absent", None, None, None)] + was[1:]
    assert SC.changed_usable_tags(was, lost) == [], "a loss was counted as a change"
    grew = [("a", "a.srs", "usable", "d9", 1, 1.0)] + was[1:]
    assert SC.changed_usable_tags(was, grew) == ["a"]
    unread = [("a", "a.srs", "unreadable", None, None, None)]
    assert SC.changed_usable_tags(unread, was[:1]) == ["a"]

    # --mirror beats the environment, and either replaces the built-in list whole.
    os.environ["SB_RULES_BASE"] = "http://env.invalid"
    try:
        assert SC._ruleset_bases(["http://a  http://b"]) == ["http://a", "http://b"]
        assert SC._ruleset_bases(["   "]) == ["http://env.invalid"]
        del os.environ["SB_RULES_BASE"]
        assert SC._ruleset_bases(None) == list(SC.RULESET_BASES)
    finally:
        os.environ.pop("SB_RULES_BASE", None)


def t_doctor_smoke(tmp):
    """Every section prints, no probe raises, and the exit status is one of the three.

    doctor's promise is that it works on a broken machine, so a section that throws must
    still cost only its own rows — the driver renders the failure as an UNKNOWN row.
    Here the machine IS bare: an empty sandbox with no config and no service.
    """
    sandbox(tmp)
    real = SC._egress_ip
    SC._egress_ip = lambda: (_ for _ in ()).throw(OSError("no network in a test"))
    out = io.StringIO()
    try:
        with contextlib.redirect_stdout(out):
            SC.cmd_doctor(None)
        raise AssertionError("cmd_doctor returned instead of exiting")
    except SystemExit as e:
        assert e.code in (0, 1, 2), e.code
    finally:
        SC._egress_ip = real
    # The eight sections and their ORDER, spelled out here rather than read back from
    # DOCTOR_SECTIONS: a test that iterates the table it is checking asserts nothing —
    # delete a section and it dutifully expects one fewer. Both READMEs document these
    # checks in this causal order, so this list is the contract and the table is what has
    # to match it. (It was nine until IPv6 support was removed, and this line is what
    # made that removal state itself rather than pass silently.)
    expected = ("sing-box binary", "rule-sets", "configuration", "service",
                "TUN interface", "Clash API", "egress IP", "file permissions")
    assert tuple(name for name, _probe in SC.DOCTOR_SECTIONS) == expected
    text = out.getvalue()
    for label in expected:
        assert SC.t(label) in text, label
    assert "this check could not run" not in text, text      # no probe raised
    assert "no file at " in text                             # the bare host's diagnosis


def t_config_command(tmp):
    """`sc config`: a JSON document on stdout, everything sc says on stderr."""
    seed(tmp)
    SC.generate_config()
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        SC.cmd_config(None)
    doc = json.loads(out.getvalue())                # stdout alone must parse as JSON
    assert doc["outbounds"][2]["uuid"] == SC.MASK
    assert doc["outbounds"][2]["server"] == "node.example"
    assert SC.MASK not in out.getvalue().split('"server"')[1][:40]
    assert str(SC.CFG_PATH) in err.getvalue()
    assert "This is what sc last generated." in err.getvalue()

    SC.CFG_PATH.write_text(json.dumps(json.loads(SC.CFG_PATH.read_text())) + "\n")
    err = io.StringIO()
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
        SC.cmd_config(None)
    assert "has drifted" in err.getvalue(), err.getvalue()


# The request `sc ping` must make, spelled out rather than rebuilt from the constants it
# is checking: the probe endpoint, the budget, and a tag percent-encoded whole.
PING_PATH = ("/proxies/%s/delay?timeout=5000"
             "&url=https%%3A%%2F%%2Fwww.gstatic.com%%2Fgenerate_204")


def t_ping(tmp):
    """`sc ping` measures now, keeps the index `sc use` takes, and answers honestly.

    Driven against a loopback stand-in for the Clash API, so it asserts the REQUEST as
    well as the rendering — a tag carrying a space has to reach the API percent-encoded,
    or the node silently reports as dead.
    """
    seed(tmp, links=(VLESS, VLESS.replace("#JP-1", "#HK 2")))
    real_running, real_port = SC.is_running, SC.CLASH_PORT
    args = type("A", (), {"spec": None})()
    try:
        SC.is_running = lambda: False
        try:
            SC.cmd_ping(args)
            raise AssertionError("measured with nothing running")
        except SystemExit as e:
            assert "not running" in str(e.code), e.code

        SC.is_running = lambda: True
        seen = []
        answers = {PING_PATH % "JP-1": b'{"delay": 210}',
                   PING_PATH % "HK%202": b'{"delay": 87}'}
        with local_source(answers, seen) as base:
            SC.CLASH_PORT = int(base.rsplit(":", 1)[1])
            # The transport must be given MORE than the probe budget, or a node answering
            # just under PING_TIMEOUT_MS would be judged dead by the socket instead. A
            # server that answers instantly cannot show this, so the contract is asserted
            # on the argument rather than bought with a four-second sleep.
            budgets, real_api = [], SC.clash_api
            SC.clash_api = lambda *a, **kw: (budgets.append(kw.get("timeout")),
                                             real_api(*a, **kw))[1]
            out = io.StringIO()
            try:
                with contextlib.redirect_stdout(out):
                    SC.cmd_ping(args)               # no SystemExit == someone answered
            finally:
                SC.clash_api = real_api
            assert budgets and all(b is not None and b > SC.PING_TIMEOUT_MS / 1000.0
                                   for b in budgets), budgets
            text = out.getvalue()
            assert "210 ms" in text and "87 ms" in text, text
            assert "2/2" in text, text
            assert sorted(seen) == sorted(answers), seen

            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_ping(type("A", (), {"spec": "HK"})())
            assert "   2  HK 2" in out.getvalue(), out.getvalue()   # nodes.json's own index
            assert "1/1" in out.getvalue(), out.getvalue()

        with local_source({}) as base:              # nothing answers
            SC.CLASH_PORT = int(base.rsplit(":", 1)[1])
            out = io.StringIO()
            try:
                with contextlib.redirect_stdout(out):
                    SC.cmd_ping(args)
                raise AssertionError("a run in which nothing answered exited 0")
            except SystemExit as e:
                assert e.code == 1, e.code
            assert out.getvalue().count(SC.t("no answer")) == 2, out.getvalue()
            assert "0/2" in out.getvalue(), out.getvalue()
    finally:
        SC.is_running, SC.CLASH_PORT = real_running, real_port


def t_export_import(tmp):
    """A backup that carries credentials safely, and a merge that cannot lose a node."""
    seed(tmp, links=(VLESS,))
    backup = tmp / "backup.json"
    SC.cmd_export(type("A", (), {"path": str(backup)})())
    assert stat.S_IMODE(backup.stat().st_mode) == SC.CRED_MODE, "a backup at a wide mode"
    assert json.loads(backup.read_text()) == SC.load_nodes()

    real_restart, real_regen = SC.restart_service, SC.generate_config
    SC.restart_service = lambda: True
    try:
        # A fresh host takes the backup whole and ends up on the auto-select group.
        sandbox(tmp / "host2")
        SC.save_settings({"lang": "en"})
        SC.save_nodes({"active": None, "nodes": []})
        SC.cmd_import(type("A", (), {"path": str(backup)})())
        assert [n["tag"] for n in SC.load_nodes()["nodes"]] == ["JP-1"]
        assert SC.load_nodes()["active"] == "auto"

        # Importing it again is a no-op: the same node, not a second copy under #2.
        before = SC.NODES_PATH.read_bytes()
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            SC.cmd_import(type("A", (), {"path": str(backup)})())
        assert "Nothing to import" in out.getvalue(), out.getvalue()
        assert SC.NODES_PATH.read_bytes() == before

        # A DIFFERENT node wearing a tag already in use is renamed, never merged away.
        clash = tmp / "clash.json"
        clash.write_text(json.dumps({"active": None, "nodes": [
            SC.parse_share_url(VLESS.replace("@node.example", "@other.example"))]}))
        SC.cmd_import(type("A", (), {"path": str(clash)})())
        tags = [n["tag"] for n in SC.load_nodes()["nodes"]]
        assert tags == ["JP-1", "JP-1 #2"], tags

        # Validated before it is kept: a document yielding no usable config changes nothing.
        before = SC.NODES_PATH.read_bytes()
        SC.generate_config = lambda: False
        other = tmp / "third.json"
        other.write_text(json.dumps({"active": None, "nodes": [
            SC.parse_share_url(VLESS.replace("@node.example", "@third.example"))]}))
        try:
            SC.cmd_import(type("A", (), {"path": str(other)})())
            raise AssertionError("kept nodes from a document that produced no config")
        except SystemExit as e:
            assert e.code == 1, e.code
        assert SC.NODES_PATH.read_bytes() == before, "nodes.json was not restored"
    finally:
        SC.restart_service, SC.generate_config = real_restart, real_regen

    # A malformed document names ITSELF, never the store it was being merged into.
    bad = tmp / "bad.json"
    bad.write_text(json.dumps({"nodes": [{"server": "no tag here"}]}))
    try:
        SC.cmd_import(type("A", (), {"path": str(bad)})())
        raise AssertionError("imported a node with no tag")
    except SC.OverrideError as e:
        assert e.path == bad, e.path
        assert "non-empty" in str(e), str(e)

    # Nothing to back up is a refusal, not an empty file left on disk.
    sandbox(tmp / "host3")
    SC.save_nodes({"active": None, "nodes": []})
    empty = tmp / "empty.json"
    try:
        SC.cmd_export(type("A", (), {"path": str(empty)})())
        raise AssertionError("exported an empty node list")
    except SystemExit as e:
        assert "no nodes" in str(e.code), e.code
    assert not empty.exists()


def t_subscription(tmp):
    """A subscription owns its own nodes: it replaces them, and it touches nothing else.

    Every property asserted here is one an unattended weekly run can get wrong — dropping
    a node the user added by hand, emptying the list because the network failed, or
    accumulating a second copy of everything on each refresh.

    One server and one URL throughout: `bodies` is read on each request, so changing what
    the provider serves is a dict assignment rather than a second server on a second port
    (which would change the URL, and the URL is the identity being tested).
    """
    import base64
    seed(tmp, links=())
    hand = SC.parse_share_url(VLESS.replace("#JP-1", "#hand-made"))
    SC.save_nodes({"active": None, "nodes": [hand]})
    real_restart, real_regen = SC.restart_service, SC.generate_config
    SC.restart_service = lambda: True

    def body(*tags):                    # what real providers serve: base64 of the links
        links = "\n".join(VLESS.replace("#JP-1", "#" + tag) for tag in tags)
        return base64.b64encode(links.encode()).decode().encode()

    def args(action, url=None):
        return type("A", (), {"action": action, "url": url})()

    bodies = {"/sub": body("A", "B")}
    try:
        with local_source(bodies) as base:
            url = base + "/sub"

            SC.cmd_sub(args("add", url))
            assert [n["tag"] for n in SC.load_nodes()["nodes"]] == ["hand-made", "A", "B"]
            assert SC._subscriptions() == [url]
            assert all(n["source"] == url for n in SC.load_nodes()["nodes"][1:])
            assert "source" not in SC.load_nodes()["nodes"][0]
            # sc's own bookkeeping key never reaches the document sing-box loads.
            doc = json.loads(SC.CFG_PATH.read_text())
            assert all("source" not in o for o in doc["outbounds"]), doc["outbounds"]

            # The same body again: nothing changed, so nothing is touched.
            before = SC.NODES_PATH.read_bytes()
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_sub(args("update"))
            assert "No subscription changed" in out.getvalue(), out.getvalue()
            assert SC.NODES_PATH.read_bytes() == before

            # Adding it twice is a refused duplicate, not a second fetch.
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                SC.cmd_sub(args("add", url))
            assert "Already a subscription" in out.getvalue(), out.getvalue()
            assert SC.NODES_PATH.read_bytes() == before

            # The provider drops B and adds C. B goes; the hand-made node stays.
            bodies["/sub"] = body("A", "C")
            with contextlib.redirect_stdout(io.StringIO()):
                SC.cmd_sub(args("update"))
            tags = [n["tag"] for n in SC.load_nodes()["nodes"]]
            assert tags == ["hand-made", "A", "C"], tags

            # THE safety property: an unreachable provider keeps what it last gave us.
            del bodies["/sub"]
            before = SC.NODES_PATH.read_bytes()
            try:
                with contextlib.redirect_stdout(io.StringIO()), \
                        contextlib.redirect_stderr(io.StringIO()):
                    SC.cmd_sub(args("update"))
                raise AssertionError("a run in which every fetch failed exited 0")
            except SystemExit as e:
                assert e.code == 1, e.code
            assert SC.NODES_PATH.read_bytes() == before, "a failed fetch changed nodes.json"

            # rm takes its nodes with it, and nothing else.
            with contextlib.redirect_stdout(io.StringIO()):
                SC.cmd_sub(args("rm", url))
            assert [n["tag"] for n in SC.load_nodes()["nodes"]] == ["hand-made"]
            assert SC._subscriptions() == []

            # A body with no share link in it is refused, and nothing is recorded.
            bodies["/sub"] = b"nonsense\n"
            try:
                SC.cmd_sub(args("add", url))
                raise AssertionError("accepted a body with no share link")
            except SystemExit as e:
                assert "no share link" in str(e.code), e.code
            assert SC._subscriptions() == []

            # Refused by the checker: NEITHER document moves — and settings.json is the
            # one written last, which is what makes that true without a two-file rollback.
            bodies["/sub"] = body("Z")
            SC.generate_config = lambda: False
            before = SC.NODES_PATH.read_bytes()
            try:
                with contextlib.redirect_stdout(io.StringIO()):
                    SC.cmd_sub(args("add", url))
                raise AssertionError("kept a subscription whose config was refused")
            except SystemExit as e:
                assert e.code == 1, e.code
            assert SC.NODES_PATH.read_bytes() == before
            assert SC._subscriptions() == [], "settings.json was written on a refusal"
    finally:
        SC.restart_service, SC.generate_config = real_restart, real_regen

    # http(s) only, both base64 alphabets, and an unreadable line is counted not fatal.
    try:
        SC._fetch_text("file:///etc/shadow")
        raise AssertionError("read a file:// subscription")
    except ValueError as e:
        assert "http" in str(e)
    # Both base64 alphabets decode. Providers use either, and _b64dec relies on
    # urlsafe_b64decode passing `+` and `/` through untouched; swapped for the strict
    # standard-alphabet decoder it would stop accepting `-_`, and this is what says so.
    raw = bytes(range(250, 256))
    standard = base64.b64encode(raw).decode().rstrip("=")
    urlsafe = base64.urlsafe_b64encode(raw).decode().rstrip("=")
    assert standard != urlsafe, "this payload does not exercise the difference"
    assert SC._b64dec(standard) == SC._b64dec(urlsafe)
    nodes, bad = SC._parse_subscription(
        base64.b64encode((VLESS + "\n").encode()).decode())
    assert len(nodes) == 1 and bad == 0, (nodes, bad)
    nodes, bad = SC._parse_subscription("nonsense\n" + VLESS + "\n# a comment\n")
    assert len(nodes) == 1 and bad == 1, (nodes, bad)


def t_scheduled_run_covers_both_jobs(tmp):
    """The timer's unit runs the rule-set job AND the subscription job, in that order.

    Asserted against the shipped unit rather than described in prose: the `-` belongs on
    the FIRST line, because systemd stops a oneshot at the first failing ExecStart and
    `sc update-rules` exits non-zero for one unreachable mirror — without it, a mirror
    that stayed down would silently stop subscriptions from ever refreshing.
    """
    unit = (HERE / "systemd" / "sing-box-rules-update.service").read_text(encoding="utf-8")
    execs = [l.strip() for l in unit.splitlines() if l.startswith("ExecStart=")]
    assert execs == ["ExecStart=-/usr/local/bin/sc update-rules",
                     "ExecStart=/usr/local/bin/sc sub update"], execs
    assert "Type=oneshot" in unit


def _readme_shape(path):
    """The language-INDEPENDENT shape of a README: what the two translations must share.

    Heading text cannot be compared across languages, but structure can, and structure is
    where the drift actually happens: a section added to one file and not the other, a
    command documented once, a table row dropped, a roadmap box ticked on one side. Each
    fact below was chosen because it catches a drift that really occurred in this repo.

    Code fences are skipped while scanning for headings and rows: a `# comment` inside a
    bash block is not a heading, and this file's own examples contain both.
    """
    text = (HERE / path).read_text(encoding="utf-8")
    headings, rows, fences, boxes = [], 0, 0, {}
    fenced = False
    for line in text.split("\n"):
        if line.startswith("```"):
            fenced = not fenced
            fences += fenced
            continue
        if fenced:
            continue
        marks = re.match(r"^(#{1,6}) ", line)
        if marks:
            headings.append(len(marks.group(1)))
        if line.startswith("|"):
            rows += 1
        box = re.match(r"^\s*- \[([ x])\]", line)
        if box:
            boxes[box.group(1)] = boxes.get(box.group(1), 0) + 1
    return {"headings": headings, "table rows": rows, "code blocks": fences,
            "checkboxes": boxes,
            # `sc <word>` is language-neutral text: a command documented in one
            # translation and not the other shows up here and nowhere else.
            "sc commands": sorted(set(re.findall(r"\bsc ([a-z][a-z-]*)", text)))}


def t_readme_parity(tmp):
    """The two READMEs must stay the same document in two languages.

    Not a paragraph-by-paragraph diff — that would need rules more complicated than the
    problem. Five structural facts, each one a drift this repository has actually
    produced: a Features bullet and a roadmap checkbox that were updated in English and
    forgotten in Chinese, and a `sc doctor` table row removed from one table only.
    """
    en, zh = _readme_shape("README.md"), _readme_shape("README.zh-CN.md")
    for fact in sorted(en):
        if en[fact] == zh[fact]:
            continue
        if fact == "headings":
            for i, (a, b) in enumerate(zip(en[fact], zh[fact])):
                if a != b:
                    raise AssertionError(
                        "README structure diverges at heading %d: level %d in English, "
                        "%d in Chinese" % (i + 1, a, b))
            raise AssertionError("README heading count differs: %d English, %d Chinese"
                                 % (len(en[fact]), len(zh[fact])))
        if fact == "sc commands":
            raise AssertionError(
                "documented in one translation only — English: %s | Chinese: %s"
                % (sorted(set(en[fact]) - set(zh[fact])),
                   sorted(set(zh[fact]) - set(en[fact]))))
        raise AssertionError("%s differ: %r in English, %r in Chinese"
                             % (fact, en[fact], zh[fact]))


# ---------------------------------------------------------------- the runner

def main():
    tests = sorted((name, fn) for name, fn in globals().items()
                   if name.startswith("t_") and callable(fn))
    failed = []
    for name, fn in tests:
        buf = io.StringIO()
        tmp = Path(tempfile.mkdtemp(prefix="sc-selftest."))
        try:
            with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
                fn(tmp)
        except BaseException:                            # a failure is data, not an end
            traceback.print_exc(file=buf)
            failed.append((name, buf.getvalue()))
            print("FAIL  " + name)
        else:
            print("ok    " + name)
        finally:
            shutil.rmtree(str(tmp), ignore_errors=True)
    for name, output in failed:
        print("\n" + "=" * 70 + "\n" + name + "\n" + "=" * 70 + "\n" + output.rstrip())
    for note in SKIPPED:
        print("skip  " + note)
    print("\n%d/%d passed" % (len(tests) - len(failed), len(tests)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
