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
asserted otherwise would be asserting the fake.
"""
import ast
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import traceback
from pathlib import Path

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
    # An empty file is a host with no IPv6 address at all, so the emitted document is
    # the same on every machine this suite runs on.
    SC.IF_INET6_PATH = tmp / "if_inet6"
    SC.IF_INET6_PATH.write_text("")
    SC.TIMER_DROPIN_DIR = tmp / "timer.d"
    if rulesets and HAVE_RULES:
        shutil.copytree(str(REAL_RULES), str(SC.RULES_DIR))
    else:
        SC.RULES_DIR.mkdir()
    return tmp


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

def t_syntax(tmp):
    """Every shipped file parses. The floor, and until this file existed, the ceiling."""
    subprocess.run([sys.executable, "-m", "py_compile", str(SC_SRC)], check=True)
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


def t_generate_config(tmp):
    """The whole composition path, and — where the host has sing-box — its verdict."""
    seed(tmp)
    assert SC.generate_config() is True
    doc = json.loads(SC.CFG_PATH.read_text(encoding="utf-8"))

    assert [o["tag"] for o in doc["outbounds"]] == ["proxy", "auto", "JP-1", "direct"]
    assert doc["outbounds"][0]["default"] == "auto"     # the judge picked the group
    assert SC.load_nodes()["active"] == "auto"          # and persisted the repair
    assert doc["dns"]["rules"][0]["query_type"] == [28, 64, 65]   # no IPv6 on this host
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
