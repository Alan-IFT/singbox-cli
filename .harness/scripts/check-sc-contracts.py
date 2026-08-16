#!/usr/bin/env python3
"""Committed contract assertions for bin/sc. Wired as verify_all B.4 (T-28).

usage: check-sc-contracts.py [--source PATH] [--list] [NAME ...]

WHAT THIS DOES TO THE HOST: nothing. It loads bin/sc as a module in THIS process --
never as a program, never /usr/local/bin/sc, never sudo -- repoints every path
constant into a mkdtemp root removed at exit, and calls named functions of the loaded
module. It never calls main() or _init_files(), opens no socket, resolves no name and
spawns no child process, and it refuses to run as root twice (main(), then load()).

NEUTRALISATION -- A PREDICATE IS NOT A CAPABILITY. bin/sc:125-126 sudo-re-execs the
INSTALLED sc at import time when os.geteuid() != 0. docs/dev-map.md's recipe defeats
that PREDICATE with an os shim whose geteuid returns 0, but the shim copies the real
os.__dict__, so shim.execvp IS os.execvp: a guard refactored to os.getuid(),
os.getresuid() or os.geteuid() > 0 would re-exec the installed build under sudo from
inside verify_all on the owner's live machine (R-78 -- that has happened here). So
load() also removes the CAPABILITY, in TWO halves that are not the same kind of thing:
  (a) On the shim, every PUBLIC process-start name in dir(os) ON POSIX raises LoadRefused --
  exec* / spawn* / fork* / system, and popen (which runs /bin/sh -c) and posix_spawn*
  (3.8+), which begin with none of the first three. Half (a) IS a name enumeration and
  stays one, so its completeness claim is scoped TWICE and both scopes are load-bearing.
  To POSIX, because os.startfile exists only on Windows -- where verify_all.ps1's B.4 is an
  unconditional SKIP and this file is not run at all. And to the PUBLIC spellings, because
  every prefix in the tuple is public while os._execvpe and os._spawnvef begin with "_" and
  match none of them: those two are in dir(os) TODAY, they are open, and they are family
  (ii) below -- where the enumeration and the measurement are. Since bin/sc binds this shim
  as its own `os` at import, half (a) outlives the load and covers the whole run.
  (b) For the duration of exec() ONLY, subprocess.Popen is replaced on the REAL module
  object and restored in the SAME finally as the shim. Half (b) is NOT an enumeration and
  must not be described as one: Popen is the single choke point every documented entry
  point of that module (run / call / check_call / check_output / getoutput /
  getstatusoutput) funnels through, and it sits ABOVE CPython's _USE_POSIX_SPAWN choice,
  so it holds on the posix_spawn and the fork_exec dispatch alike.
  Half (b) closes a MEASURED hole, not a theoretical one: before this task, a subject
  calling subprocess.call / Popen().wait() / subprocess.run or ctypes.CDLL(None).system
  from its own import started a process and left its marker on CPython 3.12.3, while the
  os.posix_spawn control was refused.
  COVERED: any process the loaded module starts or replaces itself with through a PUBLIC
  PROCESS-START NAME ON its own `os` (os.execvp, os.system, os.posix_spawn ...), whatever
  uid source its guard reads, and any it starts through subprocess's public API while it is
  being exec'd -- the run aborts loudly instead. An attribute of that same `os` which is
  itself a MODULE is family (iv) below, not this: os.path.os is the real os and is open.
  STILL OPEN -- four route families, named here because they are not closed:
  (i)   a call reaching the C level through neither `os` nor subprocess.Popen. The CHEAPEST
        member is `import posix; posix.system(...)`: posix is the C module os wraps, this
        file replaces sys.modules["os"] and never sys.modules["posix"], and it needs no
        attribute chain at all. Also ctypes (CDLL(None).system / fork / execv) and a direct
        _posixsubprocess.fork_exec. Re-measured rather than assumed: the posix and the
        ctypes variants each still leave their marker with both halves in force.
  (ii)  a process-start name in `os` that no prefix in load()'s tuple matches -- NOT ONLY A
        FUTURE ONE. Enumerated, not assumed: of the 402 names dir(os) has on CPython 3.12.3
        the tuple matches 22, and exactly two of the rest start a process -- os._execvpe and
        os._spawnvef, private helpers whose "_" no public prefix reaches. Both measured on
        this delivery, scratch subject, /usr/bin/touch on a scratch marker: os._execvpe
        REPLACED the loading interpreter (marker left, exit 0, no summary, no refusal), and
        os._spawnvef FORKED (strace: execve 1, clone 1) before the child's exec was refused.
        Adding the two names would deny those two spellings and buy nothing: the mechanism
        is the binding, not the name -- shim.__dict__.update(os.__dict__) (:213) copies the
        FUNCTION OBJECTS, and a copied function's __globals__ IS the real os module dict, so
        _execvpe calls the real execv and _spawnvef the real fork whatever the shim's
        attributes say. Measured: with both halves in force os.path.os._execvpe(...) -- the
        same helper through family (iv) -- replaced the interpreter too, marker left, exit
        0. A longer list is not a stronger guarantee, which is why this task added no name
        to that tuple; the next private helper CPython adds arrives here, not in the tuple.
  (iii) any module added to the pre-import line at :152-153 -- by construction it binds the
        REAL os, so a future addition there owes the same pricing half (b) was given.
        Today subprocess is the only one of them that can start a process.
  (iv)  the real `os` module itself, ONE ATTRIBUTE HOP away and through neither half.
        shim.__dict__.update(os.__dict__) (:213) copies the real posixpath, whose own `os`
        attribute IS the real os -- so os.path.os.execvp(...) reaches it from the shim, and
        subprocess.os / shutil.os / tempfile.os reach it from every module already
        imported. Measured before AND after half (b): os.path.os.system(...) and
        subprocess.os.system(...) from a scratch subject's import each left their marker
        both times, exit 1, the load never refused.
  THE ASSERTION PHASE IS COVERED BY NEITHER HALF, and this is where that is said. load()'s
  finally restores both displacements before the first assertion runs. What SB_BIN's
  repointing neutralises there is not a call SITE but an ARGUMENT: the only calls it reaches
  are the three that pass [SB_BIN, ...]. bin/sc:2175, the one generate_config() reaches, gets
  a path that does not exist and raises FileNotFoundError instead of executing, which that
  caller already handles as "could not be run"; :2634 and :2731 sit behind
  shutil.which(SB_BIN), which returns None for an absent path, so they never run at all.
  Nothing else in bin/sc is neutralised. Their runner _doctor_run (def at bin/sc:2599, its one
  subprocess.run at :2614) is GENERAL and its other callers pass real host tools (:2827
  systemctl, :2831 rc-update, :2853 ip); fixture()'s SYSTEMD = OPENRC = False empties the
  `if SYSTEMD:` / `elif OPENRC:` pairs and short-circuits
  _doctor_service at :2816, so of those three only _doctor_tun's :2853 survives; it leaves that
  call, cmd_status's `ip -br addr show` (:2504) and cmd_sysproxy's `sudo -u <user> gsettings`
  (:3406) unguarded, and it ROUTES INTO cmd_log's else-arm holding `tail` (:3607 with -f, which
  never returns, and :3609). So what holds this phase is WHICH FUNCTIONS THE TESTS LIST NAMES --
  today not one of them drives a process call other than the SB_BIN one, measured: a full B.4 run
  under strace -f makes 1 execve (this interpreter) and 0 clone/fork. That is a property of the
  list, re-checked by review when a name is added, and enforced by nothing in this file. No
  assertion may drive cmd_status, cmd_sysproxy, cmd_log or a doctor probe.
  WHAT THIS IS, SAID PLAINLY: a guard against an ACCIDENTAL process start from the
  subject's own import -- the R-78 incident, which has happened here -- and NOT a sandbox
  against a subject that seeks to escape. The four families above are open by design and
  measured open. A reader may not take that list for a verified guarantee.

THE PATH INVARIANT (BC-2): fixture() repoints the nine names of PATHS, then asserts that
every module attribute that IS a pathlib.Path resolves inside the run root -- exactly
that, no more: a Path inside a container escapes the scan, so PERIODIC_DIRS (bin/sc:79-83,
a dict of Paths) and SB_BIN (a str) are handled by hand; a bare Path constant is caught.

WHAT THESE ASSERTIONS DO NOT REACH. Three limits, stated here so that no one has to infer
them from what happens to be absent:
  LANGUAGE. Every sentence assertion pins the ENGLISH KEY spelling of the sentence it
  names, and nothing else. A translation-only wording regression -- a zh value edited to
  say something different -- is outside their reach, and re-running the SAME assertions
  under another language cannot change that: the expected value and the observed value are
  both produced by the same t() lookup, so a changed wording moves both sides together and
  no re-run discriminates it. There is no second-language pass here and none is wanted; a
  translation-PRESENCE check is refused too, because a key with no translation renders its
  English text by design. What guards a translated wording is review, not this file.
  THE OUTPUT LAYER. T-25's contract -- what a user actually sees on a terminal, in which
  encoding, with which stream -- is outside the reach of ANY assertion in this suite,
  because every one of them runs bin/sc's functions IN THIS PROCESS. Scope, stated exactly:
  no committed artifact runs THIS REPOSITORY'S bin/sc as a program, and this suite starts no
  child process at all. Both halves are narrower than they read, so both are said in full:
  verify_all.sh itself runs git, bash and python3 -- that is the harness around the suite,
  not the suite -- and restricted-network-regression.sh:285 runs the INSTALLED
  /usr/local/bin/sc as root, on the destructive operator-token arm that verify_all cannot
  reach (B.5 wires --self-check only; that arm is :142-148 of the same file). What verifies
  T-25's contract is review at change time plus an out-of-process measurement taken by the
  task that changes the output layer. NOT verify_all B.5, which is T-07's restricted-network
  self-check and asserts nothing whatever about rendering.
  THE ONE WRITER, PARTLY. config_json_is_installed_by_the_one_writer enforces T-13's
  invariant BOUNDED TO generate_config() and by source, because the property has no
  behavioural reach at all (measured: 0 differences over 13 cases). Two residuals follow
  from that bound: a SECOND installer added alongside a surviving _write_private(CFG_PATH,
  ...) call is not caught, and moving the install into a helper reddens the clause while
  the invariant still holds -- at which point the clause is re-aimed at the new owner,
  never deleted. Its own docstring carries a third.

No credential byte from any host or node appears here, and no literal following a
password / secret / token / api_key key exceeds 7 characters (BC-8, BC-9). Fixture
hosts are .invalid names. Standard library only; Python 3.6 syntax floor.
"""
import ast
import json
import os
import shutil
import string
import sys
import tempfile
import types
from pathlib import Path

# Every stdlib module bin/sc imports that this file does not itself need, imported BEFORE
# the shim exists so no module first imported during exec() binds the shim as its os
# (K-5); it closes what the finally cannot. A new import in bin/sc belongs here too.
import argparse, base64, copy, hashlib, http.client, io, socket  # noqa: E401,F401
import stat, subprocess, time, urllib.parse, urllib.request      # noqa: E401,F401

# The real Popen, bound HERE at import and never inside load(): half (b) restores THIS name
# and then asserts against it, so no reordering of load()'s statements can leave the restore
# putting the DENIAL back while the assertion compares it with itself -- which is what a
# capture written below the displacement did, silently, for the whole rest of the process.
# What that does not stop is a deliberate rebinding of this name inside load(); that is not
# a reorder, and no assertion here is aimed at it.
REAL_POPEN = subprocess.Popen

# Resolved from this file's own location, never from the cwd: verify_all's checks are
# cwd-sensitive (insight 13) and this one must not be.
REPO = Path(__file__).resolve().parent.parent.parent
DEFAULT_SOURCE = REPO / "bin" / "sc"
WITNESSED = ("/etc/sing-box", "/var/lib/sing-box")
# ONE table drives both the repoint and the invariant: delete a row and that constant
# stays under /etc, where fixture()'s scan names it and the run stops.
PATHS = (("CFG_DIR", ""), ("CFG_PATH", "config.json"), ("NODES_PATH", "nodes.json"),
         ("SETTINGS_PATH", "settings.json"), ("RULES_DIR", "rules"),
         ("OVERRIDE_PATH", "override.json"), ("STATE_PATH", ".config.sha256"),
         ("IF_INET6_PATH", "if_inet6"), ("LIB_DIR", "lib"))
ROOT = None     # the run root: mkdtemp'd by main(), removed in its finally


class LoadRefused(Exception):
    """bin/sc could not be loaded, or tried to replace this process while loading."""


def _no_new_process(*args, **kwargs):
    raise LoadRefused("a process start or replacement during load (first argument: %r) -- "
                      "perhaps an elevate guard reading a uid the geteuid shim misses, "
                      "perhaps another process API this load denies" % (args[:1],))


def _eq(got, want, what):
    if got != want:
        raise AssertionError("%s: got %r, want %r" % (what, got, want))


def _mode(path):
    return os.lstat(str(path)).st_mode & 0o777


def _refused(sc, call, path, sentence, what):
    """The OverrideError `call` must raise, checked by sentence and .path, returned."""
    try:
        call()
    except sc.OverrideError as e:
        if sentence is not None:
            _eq(str(e), sentence, what + ": the sentence")
        _eq(e.path, path, what + ": OverrideError.path")
        return e
    raise AssertionError(what + ": no OverrideError was raised")


def load(src):
    """bin/sc as a module, through docs/dev-map.md's recipe plus the exec denial."""
    if os.geteuid() == 0:
        raise LoadRefused("refusing to load bin/sc as root")
    shim = types.ModuleType("os")
    shim.__dict__.update(os.__dict__)
    shim.geteuid = lambda: 0                # the elevate branch is not taken ...
    for name in dir(os):                    # ... and cannot be taken any other way
        if name.startswith(("exec", "spawn", "fork", "popen", "posix_spawn", "system")):
            setattr(shim, name, _no_new_process)
    mod = types.ModuleType("sc")
    # Popen is the choke point every documented entry point of that module funnels through,
    # and REAL_POPEN was captured at import, above -- there is no capture here to get out of
    # order. Nothing that can raise may stand between these two lines and the try:.
    subprocess.Popen = _no_new_process
    sys.modules["os"] = shim
    try:
        # encoding= is required: CPython reads a script as UTF-8 (PEP 263) while a bare
        # open() uses the locale codec and dies on bin/sc's first non-ASCII byte under
        # LC_ALL=C PYTHONUTF8=0 (R-77).
        with open(str(src), encoding="utf-8") as fh:
            text = fh.read()
        exec(compile(text, str(src), "exec"), mod.__dict__)
    finally:
        sys.modules["os"] = os              # restore IMMEDIATELY, in a finally -- the SAME
        subprocess.Popen = REAL_POPEN       # finally for BOTH displacements, never a second
    if sys.modules["os"] is not os or mod.os is not shim or subprocess.Popen is not REAL_POPEN:
        raise LoadRefused("a displacement made by the load did not survive its finally")
    return mod


def fixture(sc, name):
    """A fresh sub-directory of the run root with every path constant repointed into
    it, then BC-2's invariant asserted over the loaded module."""
    d = ROOT / name
    (d / "rules").mkdir(parents=True)
    for attr, leaf in PATHS:
        setattr(sc, attr, (d / leaf) if leaf else d)
    (d / "if_inet6").write_text("", encoding="utf-8")    # host-independent IPv6 decision
    sc.SYSTEMD = sc.OPENRC = False
    sc.CLASH_PORT = 29090
    sc.LANG = "en"
    sc.SB_BIN = str(d / "no-sing-box")                   # a path that does not exist
    root = str(ROOT)    # the root itself is inside; a sibling sharing its prefix is NOT
    outside = sorted(k for k, v in vars(sc).items() if isinstance(v, Path)
                     and str(v.resolve()) != root
                     and not str(v.resolve()).startswith(root + os.sep))
    if outside:
        raise AssertionError("Path constant(s) outside the run root: " + ", ".join(outside))
    return d


def _facts(path):
    try:
        st = os.lstat(path)     # lstat, never stat: a link is its own subject
    except OSError as e:
        return ("ERR", e.errno)  # total: an absent or unreadable path is a stable value
    return (st.st_ino, st.st_mode, st.st_size, st.st_mtime)


def witness():
    """The host state this run must not change (BC-5). Read-only and total.

    ASYMMETRY, deliberate: /etc/sing-box is witnessed WITH every entry directly inside
    it, /var/lib/sing-box as the DIRECTORY only. A running sing-box owns
    /var/lib/sing-box/cache.db -- bin/sc:1354 emits it as experimental.cache_file.path
    -- and rewrites it when it likes, so witnessing those entries would redden B.4 for
    something this suite did not do. The directory's own facts still catch a create or
    a delete under it.
    """
    seen = {}
    for path in WITNESSED:
        seen[path] = _facts(path)
    try:
        names = sorted(os.listdir(WITNESSED[0]))
    except OSError as e:
        seen[WITNESSED[0] + "/*"] = ("ERR", e.errno)
        names = []
    for n in names:
        seen[WITNESSED[0] + "/" + n] = _facts(WITNESSED[0] + "/" + n)
    return seen


def userinfo_ends_at_last_at(sc):
    """FR-7 the userinfo is everything before the authority's LAST '@'."""
    _eq(sc._userinfo("a@b@h"), ("a@b", "a@b", ""), "userinfo of a@b@h")
    _eq(sc._userinfo("h"), ("", "", ""), "userinfo of an authority with no '@'")
    return "a@b@h -> whole 'a@b'; h -> all three projections empty"


def userinfo_splits_at_first_raw_colon(sc):
    """FR-7 the field boundary is the FIRST raw colon, and whole is a third value."""
    _eq(sc._userinfo("u:p:q@h"), ("u:p:q", "u", "p:q"), "userinfo of u:p:q@h")
    trailing, bare = sc._userinfo("pw:@h"), sc._userinfo("pw@h")
    _eq(trailing[1:], bare[1:], "(first, rest) of 'pw:' and of 'pw'")
    if trailing[0] == bare[0]:
        raise AssertionError("whole is derivable from (first, rest): both %r" % (bare[0],))
    return "u:p:q -> ('u', 'p:q'); 'pw:' and 'pw' share (first, rest), differ in whole"


def userinfo_decodes_exactly_once(sc):
    """FR-7 each projection is percent-decoded exactly once, after the split."""
    _eq(sc._userinfo("a%3Ab@h"), ("a:b", "a:b", ""), "an encoded colon is not a delimiter")
    _eq(sc._userinfo("a%2540b@h"), ("a%40b", "a%40b", ""), "a double-encoded '@'")
    return "%3A stays inside `first`; %2540 -> %40, never '@'"


def write_private_exact_0600_under_hostile_umask(sc):
    """FR-8 the written file is mode exactly 0600 whatever the umask cleared."""
    d = fixture(sc, "write-private-umask")
    old = os.umask(0o277)
    try:
        sc._write_private(d / "c.json", "{}\n")
        fd, control = tempfile.mkstemp(dir=str(d))      # the control: no fchmod
        os.close(fd)
    finally:
        os.umask(old)
    _eq(_mode(d / "c.json"), 0o600, "target mode at umask 0277")
    _eq(_mode(control), 0o400, "bare mkstemp control mode")
    return "target 0600 while a bare mkstemp beside it reads 0400"


def write_private_replaces_wider_and_symlinked_target(sc):
    """FR-8 a wider target and a symlinked one both end as regular 0600 files."""
    d = fixture(sc, "write-private-replace")
    wide, victim, link = d / "wide.json", d / "victim.json", d / "link.json"
    wide.write_text("old", encoding="utf-8")
    victim.write_text("victim", encoding="utf-8")
    os.chmod(str(wide), 0o666)
    os.chmod(str(victim), 0o644)
    os.symlink(str(victim), str(link))          # destination inside the root (K-6)
    sc._write_private(wide, "new")
    sc._write_private(link, "through")
    _eq((_mode(wide), wide.read_text(encoding="utf-8")), (0o600, "new"), "over a 0666 target")
    _eq((os.path.islink(str(link)), _mode(link), link.read_text(encoding="utf-8")),
        (False, 0o600, "through"), "over a symlinked target")
    _eq((_mode(victim), victim.read_text(encoding="utf-8")), (0o644, "victim"),
        "the link's former destination")
    return "0666 target -> 0600; symlink replaced by a regular 0600 file, destination intact"


def write_private_writes_utf8_bytes(sc):
    """FR-8 the bytes on disk are the text's UTF-8, whatever the process locale."""
    p = fixture(sc, "write-private-utf8") / "utf8.json"
    text = "节点 ✓\n"                           # non-ASCII, no credential material
    sc._write_private(p, text)
    _eq(p.read_bytes(), text.encode("utf-8"), "the bytes on disk")
    return "%d text characters -> %d UTF-8 bytes on disk" % (len(text), len(p.read_bytes()))


def read_state_refuses_utf16_by_name(sc):
    """FR-9 a UTF-16 state document is refused by name, not silently accepted."""
    p = fixture(sc, "read-state-utf16") / "nodes.json"
    raw = json.dumps({"nodes": []}).encode("utf-16")
    p.write_bytes(raw)
    _eq(json.loads(raw), {"nodes": []}, "json.loads over the same bytes (insight 16)")
    _refused(sc, lambda: sc._read_state(p, member="nodes"), p,
             sc.t("not valid UTF-8 text"), "a UTF-16 document")
    return "json.loads accepts the bytes; the explicit decode refuses them by name"


def read_state_shape_and_default_split(sc):
    """FR-9 one shape sentence per document; absent-is-empty vs absent-is-failure."""
    d = fixture(sc, "read-state-shape")
    top, member, gone = d / "top.json", d / "member.json", d / "gone.json"
    top.write_text("[]", encoding="utf-8")
    member.write_text('{"nodes": {}}', encoding="utf-8")
    _refused(sc, lambda: sc._read_state(top), top,
             sc.t("the top level must be a JSON object"), "a top-level array")
    _refused(sc, lambda: sc._read_state(member, member="nodes"), member,
             sc.t("the \"{member}\" member must be a JSON array", member="nodes"),
             "a member that is not an array")
    _eq(sc._read_state(gone, default={}), {}, "an absent document with a default")
    _refused(sc, lambda: sc._read_state(gone), gone, None, "an absent document")
    return "two shape sentences; absent with a default returns it, absent without raises"


def merge_array_key_demands_a_directive(sc):
    """FR-10 every non-directive value at an existing array key earns the vocabulary."""
    want = sc.t("at {at}: an existing array must be changed with one of {directives}",
                at="dns.rules", directives=sc._directive_list())
    for value in ({"server": "x"}, "scalar", None, [{"server": "x"}]):
        _refused(sc, lambda: sc._merge(sc._compose([]), {"dns": {"rules": value}}),
                 None, want, "%r over dns.rules" % (value,))
    return "object / scalar / null / bare array at dns.rules all earn: " + want


def unusable_fault_clause_is_a_class_name(sc):
    """FR-10 the unusable-document sentence's fault clause is a bare class name."""
    fixture(sc, "fault-clause")
    sc.save_nodes({"active": "n1", "nodes": [
        {"tag": "n1", "type": "trojan", "server": "a.invalid", "server_port": 443,
         "password": "pw"}]})
    sentinel = "sentinel-rule"
    sc.OVERRIDE_PATH.write_text(json.dumps({"route": {"rules": {"$append": [sentinel]}}}),
                                encoding="utf-8")
    e = _refused(sc, sc.generate_config, sc.OVERRIDE_PATH,
                 sc.t("no configuration could be produced from it ({fault})",
                      fault="AttributeError"), "a string appended to route.rules")
    if sentinel in str(e):
        raise AssertionError("the sentence quotes the offending document")
    _eq(sc.CFG_PATH.exists(), False, "whether a configuration reached disk")
    return "fault clause is exactly 'AttributeError'; no override text, no file written"


def redact_masks_secret_keys_at_every_depth(sc):
    """FR-11 every SECRET_KEYS name is masked at every depth, its key preserved."""
    leaf = dict((k, "s") for k in sorted(sc.SECRET_KEYS))
    masked = dict((k, sc.MASK) for k in sorted(sc.SECRET_KEYS))
    doc, want = dict(leaf), dict(masked)
    doc["log"], want["log"] = dict(leaf, deeper=dict(leaf)), dict(masked, deeper=dict(masked))
    doc["outbounds"] = [dict(leaf, type="trojan", tls=dict(leaf))]
    want["outbounds"] = [dict(masked, type="trojan", tls=dict(masked))]
    _eq(sc._redact(doc, False), want, "the redacted document")
    return "%d SECRET_KEYS names at depths 1-3, inside and outside outbounds" % len(leaf)


def redact_masks_unlisted_keys_inside_outbounds(sc):
    """FR-11 an unlisted key anywhere inside outbounds is masked; the mask carries nothing."""
    doc = {"unlisted": "abc", "outbounds": [
        {"type": "trojan", "unlisted": "abc", "tls": {"enabled": True, "nested": {"a": 1}}}]}
    want = {"unlisted": "abc", "outbounds": [
        {"type": "trojan", "unlisted": sc.MASK, "tls": {"enabled": True, "nested": sc.MASK}}]}
    _eq(sc._redact(doc, False), want, "the redacted document")
    short = {"outbounds": [{"type": "trojan", "password": "a"}]}
    longer = {"outbounds": [{"type": "trojan", "password": "bbbbbb"}]}
    _eq(json.dumps(sc._redact(short, False)), json.dumps(sc._redact(longer, False)),
        "two documents differing only in a secret's value and length")
    return "unlisted masked at depth 1 and under a visible container; masks byte-identical"


def dns_overlay_prepend_is_head_of_dns_rules(sc):
    """FR-12 the $prepend payload is non-empty and lands at the head of dns.rules."""
    fixture(sc, "dns-overlay")
    for suppress in (True, False):
        payload = sc._dns_overlay(suppress)["dns"]["rules"]["$prepend"]
        if not payload:
            raise AssertionError("the $prepend payload is empty for suppress=%r" % suppress)
        _eq(payload[0], sc._aaaa_rule(suppress), "the payload's first element")
        # Composed against the SECOND live dns.rules writer, not a bare base (insight 26).
        doc = sc._compose([sc._dns_overlay(suppress), sc._telemetry_overlay()])
        _eq(doc["dns"]["rules"][0], sc._aaaa_rule(suppress), "the head of composed dns.rules")
    if sc._aaaa_rule(True) == sc._aaaa_rule(False):
        raise AssertionError("both decisions give the same rule, so neither is tested")
    return "non-empty payload at index 0 of composed dns.rules, for both decisions"


def zh_placeholders_are_a_subset_of_their_key(sc):
    """FR-13 every translated string's placeholders are a subset of its own key's."""
    offenders, n, parse = [], 0, string.Formatter().parse
    for lang in sorted(sc.TRANSLATIONS):
        for key, value in sorted(sc.TRANSLATIONS[lang].items()):
            n += 1
            try:
                want = set(f for _, f, _, _ in parse(key) if f is not None)
                got = set(f for _, f, _, _ in parse(value) if f is not None)
            except ValueError as e:
                offenders.append("%s[%r]: unparsable (%s)" % (lang, key, e))
                continue
            # "" is an auto-numbered {} field and a digit-only name a positional one;
            # t() passes keywords only, so either raises at msg.format(**kwargs).
            bad = sorted(f for f in got if f == "" or f.isdigit() or f not in want)
            if bad:
                offenders.append("%s[%r]: %s" % (lang, key, ", ".join(bad)))
    if offenders:
        raise AssertionError("%d offending entry(ies):\n%s"
                             % (len(offenders), "\n".join(offenders)))
    return "%d entries in %d table(s), 0 offenders" % (n, len(sc.TRANSLATIONS))


def _literal_str(node):
    """The str a literal ast node spells, else None. literal_eval, never ast.Str: that
    class is deprecated and reading it warns, while Constant is only what 3.8+ parses."""
    try:
        value = ast.literal_eval(node)
    except Exception:       # a name, an f-string, a call -- anything not a literal
        return None
    return value if isinstance(value, str) else None


def _argument(node, index, name):
    """The ast node of an argument given positionally at `index` or by keyword `name`."""
    if index is not None and len(node.args) > index:
        return node.args[index]
    for kw in node.keywords:
        if kw.arg == name:
            return kw.value
    return None


def _io_callee(node):
    """(what to call it, index of its `mode` argument) for a call in I-4's population.

    None for everything else. The mode index differs per callee and is the whole reason
    this is a table rather than a name test: Path.open(mode) puts it first, while the
    builtin open(file, mode) and os.fdopen(fd, mode) put it second.
    """
    func = node.func
    if isinstance(func, ast.Attribute):
        if func.attr in ("read_text", "write_text"):
            return (func.attr, None)            # no mode argument exists: always text
        if func.attr == "open":
            return ("Path.open", 0)
        if func.attr == "fdopen":
            return ("os.fdopen", 1)
    elif isinstance(func, ast.Name) and func.id == "open":
        return ("open", 1)
    return None


def _json_loads_over_read_bytes(node):
    """json.loads(<...>.read_bytes()) -- bytes handed straight to the parser (insight 16)."""
    func = node.func
    if not (isinstance(func, ast.Attribute) and func.attr in ("load", "loads")
            and isinstance(func.value, ast.Name) and func.value.id == "json" and node.args):
        return False
    arg = node.args[0]
    return (isinstance(arg, ast.Call) and isinstance(arg.func, ast.Attribute)
            and arg.func.attr == "read_bytes")


def every_file_read_and_write_names_utf8(sc):
    """FR-1 every text read and write in bin/sc names UTF-8, so no locale decides a codec.

    THE POPULATION IS FILE TEXT I/O AND NOTHING ELSE (K-6): Path.read_text /
    Path.write_text (no mode argument exists, so both are always text), Path.open,
    os.fdopen and the builtin open(). A call of the open family is admitted as binary
    ONLY by a literal "b" in its own mode argument -- it is then counted as inspected,
    never as unseen -- and a mode that is not a literal cannot be proved binary and
    FAILS. subprocess.run(..., text=True) decodes a pipe, not a file, and is outside
    this bound (RES-1); bytes.decode() / str.encode() default to UTF-8 by definition.
    Also asserts no json.loads() takes a read_bytes() result directly: its UTF-16/UTF-32
    auto-detect would silently accept a document that is not UTF-8 at all.

    Reads the source of the LOADED module, so --source drives a mutated clone. Pure: no
    fixture, no subprocess, no I/O beyond reading that one file.
    """
    src = sc.generate_config.__code__.co_filename
    with open(src, encoding="utf-8") as fh:
        tree = ast.parse(fh.read(), src)
    text_sites, binary_sites, offenders = 0, 0, []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        if _json_loads_over_read_bytes(node):
            offenders.append("line %d: json.loads() over read_bytes()" % node.lineno)
            continue
        callee = _io_callee(node)
        if callee is None:
            continue
        name, mode_index = callee
        where = "line %d: %s()" % (node.lineno, name)
        if mode_index is not None:
            mode = _argument(node, mode_index, "mode")
            if mode is not None:
                spelled = _literal_str(mode)
                if spelled is None:
                    offenders.append(where + ": its mode is not a literal, so binary "
                                             "cannot be proved")
                    continue
                if "b" in spelled:
                    binary_sites += 1
                    continue
        encoding = _argument(node, None, "encoding")
        if encoding is None or _literal_str(encoding) != "utf-8":
            offenders.append(where + ': no literal encoding="utf-8"')
            continue
        text_sites += 1
    if offenders:
        raise AssertionError("%d site(s) leaving a codec to the process locale:\n%s"
                             % (len(offenders), "\n".join(offenders)))
    if not text_sites or not binary_sites:
        raise AssertionError("scanned %d text and %d binary site(s): a zero means the scan "
                             "matched nothing and asserts nothing"
                             % (text_sites, binary_sites))
    return ("%d text site(s) name utf-8; %d binary site(s) admitted by a literal mode"
            % (text_sites, binary_sites))


def config_json_is_installed_by_the_one_writer(sc):
    """FR-7 generate_config() installs config.json through the one writer (T-13).

    STRUCTURAL BY NECESSITY, not by preference: T-30 stage 6 built the declined shape --
    `os.replace(candidate, CFG_PATH)` in place of the second `_write_private()` call -- and
    measured 0 observable differences across 13 cases with this suite fully green
    (.harness/rejected-decisions.md, candidate-installed-by-os-replace-instead-of-the-one-
    writer). No byte-, mode- or timing-comparing assertion can pin which callee owns the
    write, so a source clause is the only enforcement there is. Reads the source of the
    LOADED module, so --source drives a mutated clone; its only I/O is that one file.

    WHAT IT PINS: at least one call of the bare name `_write_private` inside the single
    `generate_config` FunctionDef whose FIRST POSITIONAL argument is the bare name
    `CFG_PATH`. No statement order, no argument count, no surrounding block.

    THREE RESIDUALS, none of them a defect of bin/sc (RES-4, C-7):
      * A SECOND installer added ALONGSIDE a surviving _write_private(CFG_PATH, ...) call
        is not caught. The clause is positive-only on purpose: the negative half would be a
        list of rename/replace/write spellings, i.e. a name list standing in for a
        capability -- the defect this whole task exists to stop.
      * Moving the install into a helper generate_config() calls REDDENS this clause while
        the invariant still holds. Re-aim it at the new owner; never delete it.
      * The destination argument is pinned as the bare name CFG_PATH in first-positional
        position, so `_write_private(path=CFG_PATH, ...)` or `dest = CFG_PATH;
        _write_private(dest, ...)` redden it too. That argument is not decoration: without
        it the clause passes the measured mutant, which keeps bin/sc's OTHER
        _write_private(Path(name), text) call. Same remedy -- re-aim, never delete.
    """
    src = sc.generate_config.__code__.co_filename
    with open(src, encoding="utf-8") as fh:
        defs = [n for n in ast.walk(ast.parse(fh.read(), src))
                if isinstance(n, ast.FunctionDef) and n.name == "generate_config"]
    _eq(len(defs), 1, "generate_config() definitions in " + src)
    installs = [n.lineno for n in ast.walk(defs[0]) if isinstance(n, ast.Call)
                and isinstance(n.func, ast.Name) and n.func.id == "_write_private"
                and n.args and getattr(n.args[0], "id", None) == "CFG_PATH"]
    if not installs:
        raise AssertionError("no _write_private(CFG_PATH, ...) call inside generate_config():"
                             " something else installs config.json in " + src)
    return ("generate_config() installs config.json through _write_private(CFG_PATH, ...) at "
            "line(s) " + ", ".join(str(n) for n in installs))


def unusable_settings_refuses_regeneration(sc):
    """FR-6 a present but unusable settings.json refuses every regenerating run.

    "[]" is the document because its sentence is a fixed key with no interpolated parser
    text (BC-3). The node store is VALID and written first: that is what proves the
    refusal precedes load_nodes() rather than merely preceding a write.
    """
    fixture(sc, "unusable-settings")
    sc.save_nodes({"active": "n1", "nodes": [
        {"tag": "n1", "type": "trojan", "server": "a.invalid", "server_port": 443,
         "password": "pw"}]})
    sc.SETTINGS_PATH.write_text("[]", encoding="utf-8")
    before = sc.SETTINGS_PATH.read_bytes()
    _refused(sc, sc.generate_config, sc.SETTINGS_PATH,
             sc.t("the top level must be a JSON object"), "an unusable settings.json")
    _eq(sc.CFG_PATH.exists(), False, "whether a configuration reached disk")
    _eq(sc.STATE_PATH.exists(), False, "whether a drift record reached disk")
    _eq(sc.SETTINGS_PATH.read_bytes(), before, "the settings document's bytes")
    return "refused by name with a valid node store present; no config, no drift record"


def _write_failure(sc, document, what):
    """save_settings() must exit with the rendered sentence; its cause clause, returned."""
    template = sc.t("Could not write {path}: {err}", path=sc.SETTINGS_PATH, err="\x00")
    head, _, tail = template.partition("\x00")
    try:
        sc.save_settings(document)
    except SystemExit as e:
        message = str(e.code)
    except BaseException as e:      # anything else escaping IS the defect this pins
        raise AssertionError("%s: %s left save_settings(): %s" % (what, type(e).__name__, e))
    else:
        raise AssertionError(what + ": save_settings() returned instead of exiting")
    if not (message.startswith(head) and message.endswith(tail)):
        raise AssertionError("%s: %r is not the rendered sentence" % (what, message))
    if str(sc.SETTINGS_PATH) not in message:
        raise AssertionError("%s: the sentence does not name the file" % (what,))
    cause = message[len(head):len(message) - len(tail)] if tail else message[len(head):]
    if not cause.strip():
        raise AssertionError("%s: the cause clause is empty" % (what,))
    return cause


def settings_write_failure_is_a_sentence(sc):
    """FR-4 a failed settings.json write is one sentence and a non-zero exit, never a
    traceback -- including for a failure whose exception carries no .strerror, on which a
    bare e.strerror would raise AttributeError inside the handler itself.

    Asserts nothing about what is on disk afterwards: a part-way write_text legitimately
    leaves a truncated document (BC-5), which this task states rather than repairs.
    """
    d = fixture(sc, "settings-write-failure")
    sc.SETTINGS_PATH = d / "no-such-directory" / "settings.json"
    os_cause = _write_failure(sc, {"lang": "en"}, "a parent directory that does not exist")
    sc.SETTINGS_PATH = d / "settings.json"
    # A lone surrogate: json.loads accepts the "\udXXX" escape a hand edit can supply, and
    # json.dumps(ensure_ascii=False) hands it back to a UTF-8 encode that cannot take it.
    lone = _write_failure(sc, {"lang": "\ud800"}, "a value UTF-8 cannot encode")
    return "OSError -> %r; a value UTF-8 cannot encode -> %r" % (os_cause, lone)


class _Verdict(object):
    """What subprocess.run() hands back. PQ-1: .stdout is BYTES, never str -- _doctor_run
    decodes it itself, and a str would raise there instead of here.

    .stderr is a str and no build in this tree reads it: it exists so that a build reading
    the pre-T-30 shape (capture_output=True, text=True, r.stderr) reaches its BEHAVIOUR
    instead of dying on the stub's shape. Without it the HEAD control fails with an
    AttributeError, which would pass this assertion off as discriminating while it merely
    detected a spelling. Delete it and the control stops being one.
    """

    def __init__(self, returncode, stdout):
        self.returncode, self.stdout = returncode, stdout
        self.stderr = stdout.decode("utf-8", "replace")


class _CheckerStub(object):
    """`subprocess`, as generate_config() resolves it: PIPE / STDOUT plus a run() that
    records what it was handed and then produces one of the three checker verdicts.

    No child process is started (the module docstring's claim stays true), and the
    recording happens at the ONE instant the candidate holds the whole document -- so the
    candidate's mode and config.json's bytes are observed by a run, not by inspection.
    """

    PIPE = -1
    STDOUT = -2

    def __init__(self, sc, code):
        self.sc, self.code, self.calls = sc, code, []

    def run(self, cmd, **kwargs):
        self.calls.append((list(cmd), _mode(cmd[3]), _bytes(self.sc.CFG_PATH)))
        if self.code is None:                   # the binary cannot be run at all
            raise OSError(8, "Exec format error", cmd[0])
        # Quotes the path it was handed, as sing-box's own decode-class rejection does
        # (measured, 1.13.15), so the run's substitution of that name really executes.
        return _Verdict(self.code, b"FATAL decode config at "
                        + cmd[3].encode("utf-8") + b": stub verdict\n")


def _bytes(path):
    """A path's bytes, or None when it has none. Total, so an absent file is a value."""
    try:
        return path.read_bytes()
    except OSError:
        return None


def config_reaches_disk_only_when_the_checker_did_not_reject(sc):
    """FR-1 the checker's verdict is taken on a candidate BEFORE config.json is replaced.

    FOUR arms in one function. The first three drive one stub bound to sc.subprocess and
    restored in a finally -- rejected (exit 1), accepted (exit 0), and could-not-be-run
    (run() raises OSError) -- each in its own fixture whose config.json and drift record
    carry SENTINEL bytes distinct from anything a run emits, so "left unchanged" and
    "replaced" are two observations rather than one. A build that writes nothing at all
    passes the first arm and fails the other two; a build that writes unconditionally does
    the converse.

    What makes each of those three a control rather than a description (PQ-2): exactly ONE
    check per call, at an argv[3] that is NOT str(CFG_PATH) -- on HEAD that index holds
    config.json itself -- whose DIRECTORY is CFG_DIR, at mode 0600, with config.json still
    carrying its pre-run bytes at the instant the verdict is formed. The directory clause
    is spelled os.path.dirname(cmd[3]) == str(sc.CFG_DIR) and NEVER as a containment
    `str(sc.CFG_PATH) in cmd[3]`, which is satisfied by the very build this arm
    discriminates: HEAD hands the checker str(CFG_PATH) itself, and a string contains
    itself. str(CFG_PATH) is also a literal PREFIX of the candidate's own name, so the
    containment can distinguish neither of the two builds it would be written for. What
    the dirname clause catches (measured) is a build that mkstemps into TMPDIR --
    violating I-1's dir=, BC-1/BC-2 and os.replace's EXDEV constraint -- which passed
    every clause of this assertion before the clause existed, the listdir one included:
    a candidate outside CFG_DIR never appears in a listing of CFG_DIR. The third arm is this task's R-70 half: no exception leaves generate_config()
    when the binary will not exec, the document is installed anyway, the record is written
    and the call reports success.

    THE FOURTH ARM binds no stub at all and is a different kind of control. Read these
    three facts before touching it:
      * It PASSES on a HEAD clone, and that is correct. It is a REGRESSION control for
        this design's own guarded region, never a HEAD discriminator -- HEAD's first tail
        statement is _write_private(CFG_PATH, text) inside HEAD's own try, whose mkstemp
        raises the same FileNotFoundError and renders the same "Could not write {path}"
        key. The REJECTED arm is this assertion's HEAD discriminator; this one is not.
      * It is the ONLY control anywhere in this suite for the guarded-region invariant:
        no filesystem call in generate_config()'s tail may unwind without a rendered
        run-level outcome line (BC-11). Nothing else observes it.
      * It reddens for BOTH ways that invariant gets re-broken. Delete the
        `if name is not None:` guard in the finally and os.unlink(None) raises TypeError
        straight past the inner `except OSError` (UnboundLocalError if the sentinel is
        deleted with it) -- either way an exception leaves generate_config(). Move the
        mkstemp call back above the `try:` and its OSError leaves generate_config()
        uncaught, because main()'s envelope takes OverrideError only, cmd_reload() has no
        try, and cmd_update_rules()' recovery arm re-raises anything whose .path is not
        SETTINGS_PATH.
    Delete it and the control stops being one.
    """
    installed, recorded = b"SENTINEL-CONFIG\n", b"SENTINEL-DIGEST\n"
    seen_modes = []
    for label, code, want in (("rejected", 1, False), ("accepted", 0, True),
                              ("cannot-run", None, True)):
        d = fixture(sc, "checker-verdict-" + label)
        sc.save_nodes({"active": "n1", "nodes": [
            {"tag": "n1", "type": "trojan", "server": "a.invalid", "server_port": 443,
             "password": "pw"}]})
        sc.CFG_PATH.write_bytes(installed)
        sc.STATE_PATH.write_bytes(recorded)
        before = sorted(os.listdir(str(d)))
        stub, real = _CheckerStub(sc, code), sc.subprocess
        sc.subprocess = stub
        try:
            got = sc.generate_config()
        finally:
            sc.subprocess = real            # never leave the stub bound (K-11)
        _eq(got, want, label + ": generate_config()'s return")
        _eq(len(stub.calls), 1, label + ": number of `sing-box check` invocations")
        cmd, mode, during = stub.calls[0]
        _eq(cmd[1:3], ["check", "-c"], label + ": the checker's argv")
        if cmd[3] == str(sc.CFG_PATH):
            raise AssertionError(label + ": the checker was pointed at config.json itself")
        _eq(os.path.dirname(cmd[3]), str(sc.CFG_DIR),
            label + ": the directory the candidate was created in")
        _eq(mode, 0o600, label + ": the candidate's mode while it held the document")
        _eq(during, installed, label + ": config.json's bytes while the verdict was formed")
        _eq(sorted(os.listdir(str(d))), before, label + ": the entries under CFG_DIR")
        after, record = _bytes(sc.CFG_PATH), _bytes(sc.STATE_PATH)
        if want is False:
            _eq((after, record), (installed, recorded),
                label + ": config.json and the drift record after the run")
        else:
            if after == installed:
                raise AssertionError(label + ": config.json still holds the pre-run bytes")
            json.loads(after.decode("utf-8"))       # what was installed IS a document
            _eq(record, hashlib.sha256(after).hexdigest().encode("ascii") + b"\n",
                label + ": the drift record after the run")
        seen_modes.append("%s -> %r" % (label, got))
    # Arm 4 -- BC-11 at the candidate's own creation. No stub: config.json's PARENT does
    # not exist, so mkstemp raises FileNotFoundError, and it does so identically for root
    # and non-root (a permission-based fixture would simply pass as root). Nothing earlier
    # in generate_config() names CFG_PATH.parent -- the drift quartet degrades to None
    # through _config_digest()'s own `except OSError` -- so mkstemp is the first statement
    # that touches the absent directory and _write_private is never reached.
    d = fixture(sc, "checker-verdict-candidate-uncreatable")
    sc.save_nodes({"active": "n1", "nodes": [
        {"tag": "n1", "type": "trojan", "server": "a.invalid", "server_port": 443,
         "password": "pw"}]})
    sc.CFG_PATH = d / "no-such-directory" / "config.json"
    _eq(sc.generate_config(), False, "candidate-uncreatable: generate_config()'s return "
        "(an exception leaving the call fails this arm, which is the point of it)")
    seen_modes.append("candidate-uncreatable -> False, no raise")
    return ("one check per call in CFG_DIR at a non-config.json path, mode 0600, "
            "config.json intact at verdict time; " + ", ".join(seen_modes))


# Data, not discovery: this order is the run order and --list's, which is what makes two
# runs byte-identical; len(TESTS) is "defined" and MUST equal baseline.json's test_count.
TESTS = (
    userinfo_ends_at_last_at, userinfo_splits_at_first_raw_colon,
    userinfo_decodes_exactly_once, write_private_exact_0600_under_hostile_umask,
    write_private_replaces_wider_and_symlinked_target, write_private_writes_utf8_bytes,
    read_state_refuses_utf16_by_name, read_state_shape_and_default_split,
    merge_array_key_demands_a_directive, unusable_fault_clause_is_a_class_name,
    redact_masks_secret_keys_at_every_depth, redact_masks_unlisted_keys_inside_outbounds,
    dns_overlay_prepend_is_head_of_dns_rules, zh_placeholders_are_a_subset_of_their_key,
    every_file_read_and_write_names_utf8, config_json_is_installed_by_the_one_writer,
    unusable_settings_refuses_regeneration, settings_write_failure_is_a_sentence,
    config_reaches_disk_only_when_the_checker_did_not_reject,
)


def _execute(src, selected, before):
    stage, passed, loaded = "load", 0, True
    try:
        sc = load(src)
        stage = "fixture"
        fixture(sc, "preflight")    # BC-2 runs even when every selected assertion is pure
    except Exception as e:
        sys.stdout.write("%s failed  %s: %s\n" % (stage, type(e).__name__, e))
        sys.stdout.write("os restored  %s\n" % (sys.modules["os"] is os))
        # No early return: BC-5's after-witness below covers THIS path too, and this is
        # exactly the path on which something unexpected may already have run.
        selected, loaded = (), False
    for fn in selected:
        try:
            evidence = fn(sc)
        except Exception as e:
            sys.stdout.write("FAIL  %s  %s: %s\n" % (fn.__name__, type(e).__name__, e))
        else:
            sys.stdout.write("PASS  %s  %s\n" % (fn.__name__, evidence))
            passed += 1
    after = witness()
    changed = sorted(k for k in set(before) | set(after) if before.get(k) != after.get(k))
    for k in changed:
        sys.stdout.write("WITNESS  %s  before=%r after=%r\n" % (k, before.get(k), after.get(k)))
    sys.stdout.write("summary: %d defined, %d run, %d passed\n"
                     % (len(TESTS), len(selected), passed))
    if not loaded:
        return 2
    return 0 if selected and passed == len(selected) and not changed else 1


def main(argv):
    global ROOT
    if os.geteuid() == 0:
        sys.stdout.write("refusing to run as root: this suite loads bin/sc into this "
                         "process, which must never be able to reach a real install\n")
        return 2
    src, names, argv = str(DEFAULT_SOURCE), [], list(argv)
    while argv:
        arg = argv.pop(0)
        if arg == "--source" and argv:
            src = argv.pop(0)
        elif arg == "--list":
            for fn in TESTS:
                sys.stdout.write("%s  %s\n" % (fn.__name__, fn.__doc__.splitlines()[0]))
            return 0
        elif arg.startswith("-"):
            sys.stdout.write("usage: check-sc-contracts.py [--source PATH] [--list] "
                             "[NAME ...]\n")
            return 2
        else:
            names.append(arg)
    unknown = [n for n in names if n not in [fn.__name__ for fn in TESTS]]
    if unknown:
        sys.stdout.write("unknown assertion(s): %s\n" % ", ".join(unknown))
        return 2
    selected = [fn for fn in TESTS if not names or fn.__name__ in names]
    before = witness()
    ROOT = Path(tempfile.mkdtemp(prefix="sc-contract-")).resolve()
    rc = 2
    try:
        rc = _execute(src, selected, before)
    finally:
        try:
            shutil.rmtree(str(ROOT))
        except OSError as e:      # never silent: name the path that survived
            sys.stderr.write("run root NOT removed: %s (%s)\n" % (ROOT, e))
            rc = 2
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
