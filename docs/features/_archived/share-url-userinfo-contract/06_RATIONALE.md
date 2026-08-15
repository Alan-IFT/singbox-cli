> Rationale portion for 06_TEST_REPORT.md. Non-binding.

# 06 — QA rationale · T-22 `share-url-userinfo-contract`

## How this stage ran

I did not reuse stage 4's corpus: I wrote a second harness from `01`'s AC table with different
credential constants (`a:b:c`, `q7:`, `x:y`, `péq`, `U9`, `pw7`), so a shared literal cannot make two
harnesses agree for one wrong reason, and read stage 4's afterwards. The two disagree about nothing —
both report 19 AC-1 fixtures green and exactly eleven red at HEAD, the same eleven by fixture class.

Trigger record (T6.1 / T6.2 / T6.3): `05_RATIONALE.md` opened under **T6.3** — CR-1's closing fixture
is written out there and §"Why the harness is not vacuously green" names three properties I re-tested
by mutation rather than by reading. `04_RATIONALE.md` was not needed (every number here is my own
run); `01`/`02_RATIONALE.md` were not opened — no AC's verification step was under-specified.

Live-host witness, before and after every run: `systemctl show -p MainPID -p ActiveEnterTimestamp
sing-box` → `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST` (unchanged);
`/etc/sing-box` mtime `2026-08-11 12:13:57` and `/var/lib/sing-box` mtime `2026-07-30 12:59:24`,
both unchanged. `is-active` was never called, no `systemctl` verb but `show` was run, no live
credential byte was read, and every fixture path resolves under `…/scratchpad/qa22/froot`.

## The harness, in full (RT-5 → T-28)

Four files, all **outside** the worktree, none committed (K-15 / BND-9), under
`…/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa22/`: `qa_fixtures.py` (corpus), `qa_runner.py`
(drives one checkout), `qa_compare.py` (evaluates the criteria over two result files), `qa_run.sh`
(clones HEAD, runs both, compares). Six more carry the adversarial rounds: `mutate.py`, `qa_delta.py`
+ `qa_model.py`, `qa_ac14.py`, `qa_total.py`, `qa_locale.py`, `qa_preexist.py`.

Driver contract, for a re-implementation: `qa_run.sh` `git clone`s the repo (never `git worktree`) to
`head-clone/`, then runs `qa_runner.py <checkout>/bin/sc <froot> <stub> <out.json>` twice — baseline
first, candidate second, **same fixture root**, separate processes — and hands both result files to
`qa_compare.py`. `qa_runner.py` rewrites `nodes.json` / `settings.json` and unlinks `.config.sha256`
**and** `config.json` before each `generate_config()` call (a document read back is never a stale
one), keeping each emitted document at `<out>.docs/<id>.json` for the `sing-box check` sweep. The
stub `sing-box` is `printf '#!/bin/sh\nexit 0\n'`.

### `qa_fixtures.py` — the complete per-class fixture-construction block (K-21 / BND-6)

```python
"""QA (stage 6) fixture corpus for T-22, written from 01's AC table -- NOT copied from
stage 4's corpus. Every userinfo is EXPLICIT per-class text (K-21 / BND-6):
raw ':' for F-a, literal '%3A' for F-b, literal '%2525' for F-c, explicit %XX for F-d,
raw '@' for F-e. No credential is ever passed through quote(); every expected value is the
constant the URL text was written to carry.
"""

import base64
import json

H = "h.example"


def b64(s):
    return base64.urlsafe_b64encode(s.encode()).decode().rstrip("=")


# --------------------------------------------------------------- AC-1 / AC-2 : 19 fixtures
# expect  : asserted on the OUTBOUND read back from the document written in that run,
#           AND on the raw bytes of that document (byte-level round trip, R-22).
# head_red: my own hand-derivation of AC-2's expected-mismatch set (BND-1), 11 of 19.
AC1 = [
    # ---- tuic x F-a..F-e : one fixture per class, all five predicted red at HEAD
    dict(id="qt_a", url="tuic://U9:a:b:c@%s:443#qt_a" % H,
         expect=dict(uuid="U9", password="a:b:c"), head_red=True),
    dict(id="qt_b", url="tuic://U9:x%%3Ay@%s:443#qt_b" % H,
         expect=dict(uuid="U9", password="x:y"), head_red=True),
    dict(id="qt_c", url="tuic://U9:100%%2525@%s:443#qt_c" % H,
         expect=dict(uuid="U9", password="100%25"), head_red=True),
    dict(id="qt_d", url="tuic://U9:p%%C3%%A9q@%s:443#qt_d" % H,
         expect=dict(uuid="U9", password="péq"), head_red=True),
    dict(id="qt_e", url="tuic://U9:a@b@%s:443#qt_e" % H,
         expect=dict(uuid="U9", password="a@b"), head_red=True),

    # ---- trojan : F-a is THREE fixtures, BC-4's '::', ':pw', 'pw:' (BND-5)
    dict(id="qj_a1", url="trojan://::@%s:443#qj_a1" % H,
         expect=dict(password="::"), head_red=True),
    dict(id="qj_a2", url="trojan://:q7@%s:443#qj_a2" % H,
         expect=dict(password=":q7"), head_red=True),
    dict(id="qj_a3", url="trojan://q7:@%s:443#qj_a3" % H,
         expect=dict(password="q7:"), head_red=True),
    dict(id="qj_b", url="trojan://x%%3Ay@%s:443#qj_b" % H,
         expect=dict(password="x:y"), head_red=False),
    dict(id="qj_c", url="trojan://100%%2525@%s:443#qj_c" % H,
         expect=dict(password="100%25"), head_red=False),
    dict(id="qj_d", url="trojan://p%%C3%%A9q@%s:443#qj_d" % H,
         expect=dict(password="péq"), head_red=False),
    dict(id="qj_e", url="trojan://a@b@%s:443#qj_e" % H,
         expect=dict(password="a@b"), head_red=False),

    # ---- hysteria2 : the same seven
    dict(id="qy_a1", url="hysteria2://::@%s:443#qy_a1" % H,
         expect=dict(password="::"), head_red=True),
    dict(id="qy_a2", url="hysteria2://:q7@%s:443#qy_a2" % H,
         expect=dict(password=":q7"), head_red=True),
    dict(id="qy_a3", url="hysteria2://q7:@%s:443#qy_a3" % H,
         expect=dict(password="q7:"), head_red=True),
    dict(id="qy_b", url="hysteria2://x%%3Ay@%s:443#qy_b" % H,
         expect=dict(password="x:y"), head_red=False),
    dict(id="qy_c", url="hysteria2://100%%2525@%s:443#qy_c" % H,
         expect=dict(password="100%25"), head_red=False),
    dict(id="qy_d", url="hysteria2://p%%C3%%A9q@%s:443#qy_d" % H,
         expect=dict(password="péq"), head_red=False),
    dict(id="qy_e", url="hysteria2://a@b@%s:443#qy_e" % H,
         expect=dict(password="a@b"), head_red=False),
]

# --------------------------------------------------------------- AC-3 : shadowsocks
# identical=True -> serialized OUTBOUND (RES-2: the document, not the parser's return) must
# be byte-identical to HEAD's.
AC3 = [
    dict(id="qs_j", url="ss://aes-128-gcm:pw7@%s:8388#qs_j" % H,                       # F-j
         expect=dict(method="aes-128-gcm", password="pw7"), identical=True),
    dict(id="qs_a", url="ss://aes-128-gcm:a:b@%s:8388#qs_a" % H,                       # F-a
         expect=dict(method="aes-128-gcm", password="a:b"), identical=True),
    dict(id="qs_e", url="ss://aes-128-gcm:pw@x@%s:8388#qs_e" % H,                      # F-e
         expect=dict(method="aes-128-gcm", password="pw@x"), identical=True),
    dict(id="qs_i", url="ss://%s#qs_i" % b64("aes-128-gcm:pw7@%s:8388" % H),           # F-i
         expect=dict(method="aes-128-gcm", password="pw7"), identical=True),
    dict(id="qs_h", url="ss://%s@%s:8388#qs_h" % (b64("aes-128-gcm:p%41q"), H),        # F-h
         expect=dict(method="aes-128-gcm", password="p%41q"), identical=False),        # BC-9
    # RES-1 / CR-1: the single fixture that observes BC-10's '%3A' half, BND-12's named
    # divergence case FOR parse_ss, and K-8 delta 2 (the plaintext method is now decoded).
    dict(id="qs_b", url="ss://a%%3Ab:pw@%s:8388#qs_b" % H,
         expect=dict(method="a:b", password="pw"), identical=False),
    # K-8 delta 1: colonless plaintext userinfo -- ValueError at HEAD, transcribed after.
    dict(id="qs_k", url="ss://aes-128-gcm@%s:8388#qs_k" % H,
         expect=dict(method="aes-128-gcm", password=""), identical=False),
]

# --------------------------------------------------------------- AC-4 : vless + vmess
# every vless fixture carries a uuid (K-9); no '%' anywhere in any userinfo except qv16.
_V = "vless://U9@%s:443" % H
AC4 = [
    dict(id="qv01", url=_V + "?type=tcp#qv01", identical=True),
    dict(id="qv02", url=_V + "?type=ws&path=/x&host=a.example#qv02", identical=True),
    dict(id="qv03", url=_V + "?type=grpc&serviceName=gs#qv03", identical=True),
    dict(id="qv04", url=_V + "?type=h2&host=a.example&path=/y#qv04", identical=True),
    dict(id="qv05", url=_V + "?type=http&host=a.example,b.example#qv05", identical=True),
    dict(id="qv06", url=_V + "?type=httpupgrade&path=/z&host=a.example#qv06", identical=True),
    dict(id="qv07", url=_V + "?type=tcp&security=tls&sni=a.example&alpn=h2,http/1.1&fp=chrome#qv07",
         identical=True),
    dict(id="qv08", url=_V + "?type=ws&path=/w&security=tls&allowInsecure=1#qv08", identical=True),
    dict(id="qv09", url=_V + "?type=grpc&serviceName=gs&security=tls&sni=a.example#qv09",
         identical=True),
    dict(id="qv10", url=_V + "?type=tcp&security=reality&pbk=PBK&sid=ab&flow=xtls-rprx-vision#qv10",
         identical=True),
    dict(id="qv11", url=_V + "?type=httpupgrade&path=/z&security=reality&pbk=PBK&fp=firefox#qv11",
         identical=True),
    dict(id="qv12", url=_V + "?type=h2&host=a.example&path=/y&security=tls&alpn=h2#qv12",
         identical=True),
    # BND-10: '%'-free vless userinfo carrying a RAW colon. Byte-identical to HEAD, and the
    # only instrument separating FR-7's first-field reading (uuid 'a') from FR-5's
    # whole-userinfo reading (which would emit 'a:b').
    dict(id="qv_bnd10", url="vless://a:b@%s:443#qv_bnd10" % H,
         expect=dict(uuid="a"), identical=True),
    # AC-16: FR-7's decode half. HEAD emits 'a%2Db'.
    dict(id="qv16", url="vless://a%%2Db@%s:443#qv16" % H,
         expect=dict(uuid="a-b"), identical=False),
]

_VM = dict(v="2", add=H, port="443", id="U9", aid="0", scy="auto")


def _vmess(ps, **kw):
    cfg = dict(_VM, ps=ps)
    cfg.update(kw)
    return "vmess://" + b64(json.dumps(cfg))


AC4 += [
    dict(id="qm01", expect=dict(uuid="U9"), url=_vmess("qm01", net="tcp"), identical=True),
    dict(id="qm02", expect=dict(uuid="U9"), url=_vmess("qm02", net="ws", path="/x", host="a.example", tls="tls"),
         identical=True),
    dict(id="qm03", expect=dict(uuid="U9"), url=_vmess("qm03", net="grpc", path="gs"), identical=True),
    dict(id="qm04", expect=dict(uuid="U9"), url=_vmess("qm04", net="h2", host="a.example", path="/y", tls="tls",
                               sni="a.example", alpn="h2", fp="chrome"), identical=True),
    dict(id="qm05", expect=dict(uuid="U9"), url=_vmess("qm05", net="httpupgrade", path="/z", host="a.example"),
         identical=True),
]

# --------------------------------------------------------------- AC-5..AC-8, BC-8, BC-11
_LONG = ("a:" * 1000) + "z"          # 2001 chars, BC-11, and F-a at scale

AC5_8 = [
    dict(id="qx5", url="tuic://a%%3Ab:pw@%s:443#qx5" % H,                              # AC-5
         expect=dict(uuid="a:b", password="pw")),
    dict(id="qx6j", url="trojan://100%%25@%s:443#qx6j" % H,                            # AC-6
         expect=dict(password="100%")),
    dict(id="qx6t", url="tuic://U9:100%%25@%s:443#qx6t" % H,
         expect=dict(uuid="U9", password="100%")),
    dict(id="qx7j", url="trojan://pw7@[2001:db8::1]:443#qx7j",                         # AC-7
         expect=dict(server="2001:db8::1", server_port=443, password="pw7")),
    dict(id="qx7y", url="hysteria2://pw7@[2001:db8::1]:443#qx7y",
         expect=dict(server="2001:db8::1", server_port=443, password="pw7")),
    dict(id="qx7t", url="tuic://U9:p:q@[2001:db8::1]:443#qx7t",
         expect=dict(server="2001:db8::1", server_port=443, uuid="U9", password="p:q")),
    dict(id="qx8j", url="trojan://%s:443#qx8j" % H, expect=dict(password="")),          # AC-8
    dict(id="qx8y", url="hysteria2://%s:443#qx8y" % H, expect=dict(password="")),
    dict(id="qx8t", url="tuic://%s:443#qx8t" % H, expect=dict(uuid="", password="")),
    # RES-3 / BC-8: %FF is not valid UTF-8 -> lossy U+FFFD, no exception, document written.
    dict(id="qbc8", url="trojan://p%%FFq@%s:443#qbc8" % H,
         expect=dict(password="p\ufffdq")),
    # RES-3 / BC-11: no length cap; 2001-character password, raw colons throughout.
    dict(id="qbc11j", url="trojan://%s@%s:443#qbc11j" % (_LONG, H),
         expect=dict(password=_LONG)),
    dict(id="qbc11t", url="tuic://U9:%s@%s:443#qbc11t" % (_LONG, H),
         expect=dict(uuid="U9", password=_LONG)),
]

ALL = AC1 + AC3 + AC4 + AC5_8
```

### `qa_runner.py` — the safety-critical core (K-16 … K-19), verbatim

```python
def load_sc(path):
    assert os.geteuid() != 0, "refuse to run as root"
    sc = types.ModuleType("sc")
    shim = types.ModuleType("os")
    shim.__dict__.update(os.__dict__)
    shim.geteuid = lambda: 0
    sys.modules["os"] = shim
    try:
        with open(path) as fh:
            exec(compile(fh.read(), path, "exec"), sc.__dict__)
    finally:
        sys.modules["os"] = os
    return sc


def repoint(sc, root, stub):
    root = Path(root).resolve()
    assert not str(root).startswith("/home/alan/Programs/singbox-cli"), \
        "fixture root must be outside the repository worktree"
    sc.CFG_DIR = root ; sc.CFG_PATH = root / "config.json"
    sc.NODES_PATH = root / "nodes.json" ; sc.SETTINGS_PATH = root / "settings.json"
    sc.RULES_DIR = root / "rules" ; sc.OVERRIDE_PATH = root / "override.json"
    sc.STATE_PATH = root / ".config.sha256" ; sc.IF_INET6_PATH = root / "if_inet6"
    for name in PATHS:                       # all EIGHT, asserted inside the root
        p = Path(getattr(sc, name)).resolve()
        assert p == root or str(p).startswith(str(root) + os.sep), \
            "%s escapes the fixture root: %s" % (name, p)
    sc.SYSTEMD = sc.OPENRC = False ; sc.SB_BIN = str(stub)
    sc.LANG = LANG ; sc.CLASH_PORT = PORT    # "en" / 29090
    root.mkdir(parents=True, exist_ok=True) ; (root / "rules").mkdir(exist_ok=True)
    (root / "if_inet6").write_text("")       # deterministic: no global IPv6


def run(sc, fx, keep_doc_dir):               # main() / _init_files() are NEVER called
    row["node"] = node = sc.parse_share_url(fx["url"])
    sc.NODES_PATH.write_text(json.dumps({"active": tag, "nodes": [node]}, ...))
    sc.SETTINGS_PATH.write_text(json.dumps(SETTINGS, indent=2))
    for p in (sc.STATE_PATH, sc.CFG_PATH):   # never read back a stale document
        p.unlink(missing_ok=True)
    row["generated"] = bool(sc.generate_config())
    row["doc"] = text = sc.CFG_PATH.read_text()          # the document, as bytes on disk
    row["outbound"] = <the outbound of `text` whose tag == node["tag"]>
    assert sc.LANG == LANG, "LANG moved (vacuity trap)"
    assert sc.CLASH_PORT == PORT, "CLASH_PORT moved (vacuity trap)"
```

### `qa_compare.py` — the assertion core (RES-2 + the R-22 byte-level round trip), verbatim

```python
def check(row, expect, require_generated=True, bytes_too=True):
    bad = []
    if require_generated and row.get("generated") is not True:
        bad.append("generated=%r error=%s" % (row.get("generated"), row.get("error")))
    ob = row.get("outbound")                      # RES-2: the DOCUMENT, not node
    if ob is None:
        bad.append("outbound absent from the emitted document (error=%s)" % row.get("error"))
        return bad
    for k, want in expect.items():
        got = ob.get(k)
        if got != want:
            bad.append("%s=%r want %r" % (k, got, want)); continue
        if isinstance(want, str):
            if len(got) != len(want):
                bad.append("%s length %d want %d" % (k, len(got), len(want)))
            if bytes_too:                         # R-22: the constant, in the file's bytes
                needle = '"%s": %s' % (k, json.dumps(want, ensure_ascii=False))
                if needle not in (row.get("doc") or ""):
                    bad.append("document bytes lack %s" % needle[:60])
    return bad
```

AC-2's control is code, not narration: `got_red` comes from running `check` over the **HEAD** result
file, `want_red` from each fixture's hand-authored `head_red` flag, and a match **inside** the set or
a mismatch **outside** it prints `HARNESS INDICTED (never bin/sc)` and fails the run.

## Full run 1 — the differential, 57 fixtures × 2 checkouts

`bash qa_run.sh`:

```
baseline clone HEAD: 51c0f47
worktree      HEAD: 51c0f47
ran 57 fixtures -> /tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa22/head.json (documents in /tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa22/head.docs)
ran 57 fixtures -> /tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa22/cand.json (documents in /tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/qa22/cand.docs)

== AC-1 : candidate, credential in the document == the constant the URL carries ==
  qt_a    PASS
  qt_b    PASS
  qt_c    PASS
  qt_d    PASS
  qt_e    PASS
  qj_a1   PASS
  qj_a2   PASS
  qj_a3   PASS
  qj_b    PASS
  qj_c    PASS
  qj_d    PASS
  qj_e    PASS
  qy_a1   PASS
  qy_a2   PASS
  qy_a3   PASS
  qy_b    PASS
  qy_c    PASS
  qy_d    PASS
  qy_e    PASS
== AC-2 : HEAD negative control, expected-mismatch set must be exactly BND-1's ==
  fixtures built      : 19
  red at HEAD         : 11 ['qj_a1', 'qj_a2', 'qj_a3', 'qt_a', 'qt_b', 'qt_c', 'qt_d', 'qt_e', 'qy_a1', 'qy_a2', 'qy_a3']
  predicted red (BND-1): 11 ['qj_a1', 'qj_a2', 'qj_a3', 'qt_a', 'qt_b', 'qt_c', 'qt_d', 'qt_e', 'qy_a1', 'qy_a2', 'qy_a3']
  PASS -- control agrees fixture-for-fixture
== AC-3 (shadowsocks) : asserted on the emitted document (RES-2) ==
  qs_j      PASS
  qs_a      PASS
  qs_e      PASS
  qs_i      PASS
  qs_h      PASS  (declared delta; head={"type": "shadowsocks", "tag": "qs_h", "server": "h.example", "server_port": 8388, "method": "aes-128-gcm", "password": "pAq"})
  qs_b      PASS  (declared delta; head={"type": "shadowsocks", "tag": "qs_b", "server": "h.example", "server_port": 8388, "method": "a%3Ab", "password": "pw"})
  qs_k      PASS  (declared delta; head=ValueError: not enough values to unpack (expected 2, got 1))
== AC-4 (vless + vmess) : asserted on the emitted document (RES-2) ==
  qv01…qv12  PASS  (6 transports x none, + tls x3, reality x2 -- all byte-identical to HEAD)
  qv_bnd10  PASS
  qv16      PASS  (declared delta; head={"type": "vless", "tag": "qv16", "server": "h.example", "server_port": 443, "uuid": "a%2Db", "packet_encoding": "xudp"})
  qm01…qm05  PASS  (4 vmess transports + tls; uuid asserted == "U9"; byte-identical to HEAD)
== AC-5/6/7/8 + BC-8 + BC-11 (targeted, emitted document) ==
  qx5       PASS
  qx6j      PASS
  qx6t      PASS
  qx7j      PASS
  qx7y      PASS
  qx7t      PASS
  qx8j      PASS
  qx8y      PASS
  qx8t      PASS
  qbc8      PASS  (head={"password": "p�q"})
  qbc11j    PASS  (head={"password": "a"})
  qbc11t    PASS  (head={"uuid": "U9", "password": ""})

RESULT: ALL GREEN (0 failing fixtures of 57)
```

## Full run 2 — mutation check: does this harness kill what the design forbids?

`python3 mutate.py .` writes four forbidden implementations **outside** the worktree (`bin/sc` is
never touched) and each is driven through the same runner and comparator:

```
=== m1_rebuild ===            (whole := first + ':' + rest -- the two-value shape I-1 forbids)
  qj_a3   FAIL  password='q7' want 'q7:'
  qy_a3   FAIL  password='q7' want 'q7:'
RESULT: FAILURES (2 failing fixtures of 57)
=== m2_decode_first ===       (unquote the authority, THEN split -- the order Q-2/K-2 forbid)
  qs_b      FAIL  method='a' want 'a:b'; password='b:pw' want 'pw'
  qx5       FAIL  uuid='a' want 'a:b'; password='b:pw' want 'pw'
RESULT: FAILURES (2 failing fixtures of 57)
=== m3_vless_whole ===        (FR-5's whole-userinfo reading applied to vless -- Q-3 forbids)
  qv_bnd10  FAIL  uuid='a:b' want 'a'; NOT byte-identical to HEAD
RESULT: FAILURES (1 failing fixtures of 57)
=== m4_trojan_username ===    (trojan back to p.username -- the defect itself)
  qj_a1   FAIL  password='' want '::'
  qj_a2   FAIL  password='' want ':q7'
  qj_a3   FAIL  password='q7' want 'q7:'
  qbc11j  FAIL  password='a' want 'a:a:a:…:z'   (2001 characters expected, 1 emitted)
RESULT: FAILURES (4 failing fixtures of 57)
```

Every mutant dies, each on exactly the fixture its condition predicts: m1 only on the `pw:` shape
(BND-5's third BC-4 shape, which a first+rest rebuild cannot emit), m3 only on `qv_bnd10` (BND-10's
instrument), m2 on the two `%3A`-before-the-boundary fixtures — one tuic, one **ss**, RES-1's fixture
doing the work CR-1 said no fixture did.

## Full run 3 — the fourth-delta hunt (BND-3 / RT-6)

`qa_delta.py` builds 566 URLs (4 urlparse schemes × 33 userinfo shapes × 4 host shapes, plus 39
`ss://` bodies across all three arms) and diffs HEAD against the candidate: 308 identical, 258
divergent. `qa_model.py` judges every non-`ss` divergence against an **independent re-implementation
of FR-2/3/4/5/7 written from `01`'s text**, and requires every non-credential key to match HEAD:

```
urlparse-scheme URLs checked against the model: 528 ; violations: 0
ss divergences: 10
```

The ten `ss://` divergences, classified by hand (there is no fourth):

| url | head | candidate | class |
|---|---|---|---|
| `ss://aes-128-gcm@h:8388` | `ValueError` | `method aes-128-gcm`, `password ""` | K-8 delta 1 |
| `ss://YWVzLTEyOC1nY20@h:8388` | `ValueError` | `method YWVzLTEyOC1nY20`, `password ""` | K-8 delta 1 |
| `ss://@h:8388` | `ValueError` | `method ""`, `password ""` | K-8 delta 1 (the empty case K-8 names) |
| `ss://a%3Ab:pw@h:8388` | `method a%3Ab` | `method a:b` | K-8 delta 2 |
| `ss://a%2Db:pw@h:8388` | `method a%2Db` | `method a-b` | K-8 delta 2 |
| `ss://p%FFq:pw@h:8388` | `method p%FFq` | `method p�q` | K-8 delta 2 (+ BC-8, lossy, no raise) |
| `ss://<b64 aes-128-gcm:p%41q>@h:8388` | `password pAq` | `password p%41q` | FR-6 / BC-9 (stated effect) |
| `ss://<b64 …:p%41q@h:8388>` (whole-body) | `password pAq` | `password p%41q` | FR-6 / BC-9 |
| `ss://<b64 …:100%2525>@h:8388` | `password 100%25` | `password 100%2525` | FR-6 / BC-9 |
| `ss://<b64 …:100%2525@h:8388>` | `password 100%25` | `password 100%2525` | FR-6 / BC-9 |

## Full run 4 — `verify_all`, the second independent execution (RES-4)

`bash /home/alan/Programs/singbox-cli/.harness/scripts/verify_all.sh`, run three times, identical
each time (before this report was written):

```
A.1 PASS  A.2 PASS  B.1 PASS  B.2 PASS  B.3 SKIP  E.1…E.5 PASS  E.6 PASS  F.1…F.6 PASS
=== Summary ===   PASS: 17   WARN: 0   FAIL: 0   SKIP: 1
```

## Full run 5 — `sing-box check` (AC-14) — NON-REGRESSION ONLY

The AC-1 corpus uses `U9` as a tuic uuid, which a real `sing-box` rejects for length before it ever
looks at a password (`invalid uuid: incorrect UUID length 2`) — at HEAD **and** on the candidate, 14
accepted / 5 rejected on both sides. So `qa_ac14.py` re-runs a small corpus with a legal UUID:

```
c_t_a   cand accepted     {"uuid": "11111111-…-555555555555", "password": "a:b:c"}
        head accepted     {"uuid": "11111111-…-555555555555", "password": ""}
c_j_a   cand accepted     {"password": "q7:"}        head accepted  {"password": "q7"}
c_y_a   cand accepted     {"password": "::"}         head accepted  {"password": ""}
c_s_b   cand REJECTED: unknown method: a:b           head REJECTED: unknown method: a%3Ab
c_s_k   cand REJECTED: missing password              head no document (ValueError: …)
```

HEAD's empty-tuic-password document is **accepted** by the real checker — which is the measured
answer to Q-10 and the reason this row can never be evidence for FR-1…FR-8.

The `c_s_k` line is K-8 delta 1's user-visible consequence, so I checked whether the failure class is
new. It is not: `ss://aes-128-gcm:@h.example:8388` parses identically at HEAD and on the candidate
(`method aes-128-gcm`, `password ""`) and its document is rejected by `sing-box check` with the same
`missing password` on both sides (`qa_preexist.py`). Delta 1 moves one input into a pre-existing
class; it does not create the class.

## Full run 6 — non-UTF-8 preferred encoding (QA-1)

`qa_locale.py` drives sc's **own** writers (`save_nodes` → `_write_private`, `generate_config` →
`_write_private`) for `trojan://p%C3%A9q@h.example:443`:

```
### candidate, default locale   preferred encoding: UTF-8 ; utf8_mode=0
parsed password == constant: True / generate_config -> True / document holds the UTF-8 bytes: True
### candidate, LC_ALL=C PYTHONUTF8=0 PYTHONCOERCECLOCALE=0   preferred encoding: ANSI_X3.4-1968
parsed password == constant: True
RAISED out of sc's own writers: UnicodeEncodeError: 'ascii' codec can't encode character '\xe9'
### HEAD, same environment
RAISED out of sc's own writers: UnicodeEncodeError: 'ascii' codec can't encode character '\xe9'
```

Identical at HEAD, so BC-7 is not regressed; the exposure is `_write_private` / `write_text` carrying
no `encoding=` — T-23's defect class, here shown to reach `nodes.json` and `config.json` and not only
the state file. It needs an explicitly non-UTF-8 locale: PEP 538/540 turn a bare `LC_ALL=C` into
UTF-8 mode, and that run passes.

## Full run 7 — `_userinfo` totality (I-1), never previously observed

`qa_total.py` runs 29,726 inputs — every string of length ≤3 over a 21-symbol alphabet
(`: @ % %3A %25 %FF %zz / ? # \n \t space 中 emoji NUL [ ] + a ""`), 20,000 random strings and two
strings of 100,000+ characters — checking the three algebraic invariants on each:

```
inputs=29726  raised=0  invariant violations=0
```

## Full run 8 — stability

Ten consecutive candidate runs of the whole corpus, each result file compared byte-for-byte with the
first: `ALL GREEN (0 failing fixtures of 57)` ×10, `node-json identical to run 0: yes` ×10.
`verify_all` ×3: `PASS 17 · WARN 0 · FAIL 0 · SKIP 1` ×3.

## Reasoned non-assertions (RES-3), and why they are reasoned rather than dropped

**BC-8** is now *observed*: `qbc8` emits `p�q`, raises nothing, and the document is written; the
ss half falls out of the delta sweep. Un-assertable is what BC-8 itself calls impossible — that the
*credential the URL carries* survives — since `%FF` encodes no UTF-8 character and JSON cannot hold
the byte. So the assertion is about the replacement character and the absent exception, BC-8's text.

**BC-11** is observed for 2001 characters (`qbc11j` / `qbc11t`): enough to show the change imposes no
cap, not a proof that none exists — the real bound is the caller's shell and `ARG_MAX`, which is no
property of `bin/sc`.

**Concurrency** is not asserted: `_userinfo` is pure, has no module state and does no I/O (run 7),
and `generate_config()`'s atomic-write behaviour is neither touched by this change nor in its scope.

**AC-13** is not substituted for. No artifact check appears anywhere in this report as evidence of a
live authentication (R-31 / R-41 / R-47 / R-52 / R-60 precedent, sixth time).
