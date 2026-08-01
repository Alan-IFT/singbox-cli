"""Stage 6b — DEF-1 re-verification: `_plain()` whole-CSI stripping (bin/sc:1236).

Independent of 04_ §13's own checks. Three questions, each stated so it can fail:

  Q1 (AC-17 invariant, the criterion the fix could most plausibly have broken):
      for EVERY input, the result contains no 0x1B and no 0x0D.  Fuzzed.
  Q2 (byte-identity, verified not restated): for every ESC-FREE input the result equals
      the PRE-FIX implementation, quoted verbatim from 02_ §3.6:
          text.replace("\\r","").replace("\\x1b","").rstrip()
      This oracle is the design document's, not the developer's code.
  Q3 (no legitimate text eaten): logrus' "[0000]" elapsed field and "rule-set[0]" survive
      a real coloured line, and every non-CSI ESC form loses only its ESC (HEAD behaviour).

Plus a NON-VACUITY control: the pre-fix implementation is run against the same coloured
line and must FAIL Q3, proving these assertions can go red.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q11 DEF-1 _plain() whole-CSI")
mod = qa_load.load()
plain = mod._plain


def prefix_oracle(text):
    """The implementation DEF-1 was filed against — 02_SOLUTION_DESIGN.md §3.6, verbatim."""
    return text.replace("\r", "").replace("\x1b", "").rstrip()


# ---- the fix is confined to _plain(), and `re` is still not imported ------------------
src = qa_load.SRC.read_text()
t.ok("\nimport re\n" not in src and "\nimport re " not in src,
     "DEF-1: `re` is still not imported by bin/sc")
t.eq(src.count("def _plain("), 1, "DEF-1: exactly one _plain() definition")

# ---- Q3a: the real coloured line sing-box 1.13.15 emits into a PIPE ------------------
REAL = ("\x1b[31mFATAL\x1b[0m[0000] initialize router: parse rule-set[0]: "
        "open /tmp/x/rules/geoip-cn.srs: no such file or directory")
got = plain(REAL)
want = ("FATAL[0000] initialize router: parse rule-set[0]: "
        "open /tmp/x/rules/geoip-cn.srs: no such file or directory")
t.eq(got, want, "DEF-1: the real coloured checker line renders clean")
t.ok("[0000]" in got, "DEF-1: logrus' [0000] elapsed field survives")
t.ok("rule-set[0]" in got, "DEF-1: 'rule-set[0]' survives")
# non-vacuity: the pre-fix implementation must FAIL this very assertion
t.ok(prefix_oracle(REAL) != want,
     "NON-VACUITY: the pre-fix implementation still fails this (got %r)"
     % prefix_oracle(REAL)[:24])

# ---- Q3b: a hand table of forms, each with the answer written down first --------------
CASES = [
    # (input, expected, why)
    ("\x1b[0m", "", "SGR reset removed whole"),
    ("\x1b[31;1;4mX", "X", "multi-parameter SGR"),
    ("\x1b[?25lX", "X", "private-parameter CSI (0x3F in the param range)"),
    ("\x1b[2J\x1b[HX", "X", "two adjacent CSIs"),
    ("\x1b[1 qX", "X", "CSI with an intermediate byte (0x20) before the final"),
    ("[0000] hello", "[0000] hello", "no ESC at all: untouched"),
    ("rule-set[0]", "rule-set[0]", "no ESC at all: untouched"),
    ("a\x1bb", "ab", "bare ESC, not CSI: only the ESC goes (HEAD behaviour)"),
    ("a\x1b", "a", "trailing bare ESC"),
    ("a\x1b[", "a[", "truncated CSI: incomplete, so only the ESC goes"),
    ("a\x1b[31", "a[31", "CSI with params but no final: incomplete"),
    ("a\x1b]0;title\x07b", "a]0;title\x07b", "OSC deliberately unhandled: only the ESC goes"),
    ("a\x1b(Bb", "a(Bb", "charset selection deliberately unhandled"),
    ("x\ry\nz", "xy\nz", "CR removed mid-string, LF kept (I-1: _plain does not touch LF)"),
    ("x\ry\r\n", "xy", "CRLF: CR removed, then rstrip eats the trailing LF"),
    ("  padded  ", "  padded", "rstrip only, never lstrip; never abridges"),
    ("", "", "empty string"),
    ("\x1b[31m\x1b[0m", "", "colour on, colour off, nothing left"),
]
for src_s, exp, why in CASES:
    t.eq(plain(src_s), exp, "DEF-1 case: %s" % why)

# ---- Q3c: the one form that COULD eat text, stated openly -----------------------------
# ESC immediately followed by "[0000]" IS a complete CSI by the grammar (params 0..0,
# final "]" = 0x5D), so it is consumed whole. That is spec-correct, and it cannot arise
# from logrus, whose "[0000]" always follows a completed "\x1b[0m". Asserted so the
# behaviour is on the record rather than a surprise.
t.eq(plain("\x1b[0000] tail"), " tail",
     "DEF-1: ESC+'[0000]' is a valid CSI and IS consumed (documented, not reachable "
     "from logrus, whose [0000] follows a completed \\x1b[0m)")
t.eq(plain("\x1b[0m[0000] tail"), "[0000] tail",
     "DEF-1: the logrus shape actually emitted keeps its elapsed field")

# ---- Q1 + Q2: fuzz -------------------------------------------------------------------
rnd = random.Random(20260801)
ALPHA = ("abcXYZ019 \t[];:?m@~" + "\x1b" * 3 + "\r\n" + "\x00\x7f" + "中文—")
esc_free_checked = 0
for _ in range(40000):
    n = rnd.randrange(0, 40)
    s = "".join(rnd.choice(ALPHA) for _ in range(n))
    r = plain(s)
    if "\x1b" in r or "\r" in r:
        t.ok(False, "AC-17 fuzz: 0x1B/0x0D survived for %r -> %r" % (s, r))
        break
    if "\x1b" not in s:
        esc_free_checked += 1
        if r != prefix_oracle(s):
            t.ok(False, "byte-identity fuzz: %r -> %r, pre-fix gave %r"
                        % (s, r, prefix_oracle(s)))
            break
else:
    t.ok(True, "AC-17 fuzz: 40000 random inputs, 0 x 0x1B and 0 x 0x0D in every result")
    t.ok(True, "byte-identity fuzz: %d ESC-free inputs all equal the pre-fix implementation"
               % esc_free_checked)

# ESC-free fuzz over a wider alphabet, since the alphabet above is ESC-heavy
ALPHA2 = "abcXYZ019 \t[]();:?m@~\r\n\x00\x7f中文—\\/'\"%%{}"
for _ in range(20000):
    n = rnd.randrange(0, 60)
    s = "".join(rnd.choice(ALPHA2) for _ in range(n))
    if plain(s) != prefix_oracle(s):
        t.ok(False, "byte-identity(2): %r -> %r vs %r" % (s, plain(s), prefix_oracle(s)))
        break
else:
    t.ok(True, "byte-identity: 20000 further ESC-free inputs are byte-for-byte unchanged")

# ---- no input can make _plain() raise -------------------------------------------------
for s in ("\x1b" * 50, "\x1b[" * 50, "\x1b[" + "0" * 5000 + "m", "\x1b[\x1b[\x1b[m"):
    try:
        r = plain(s)
        t.ok("\x1b" not in r, "robustness: %r... yields no ESC" % s[:12])
    except Exception as e:  # noqa: BLE001
        t.ok(False, "robustness: _plain(%r...) raised %r" % (s[:12], e))

sys.exit(1 if t.done() else 0)
