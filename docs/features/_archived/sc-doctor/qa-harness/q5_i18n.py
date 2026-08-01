"""AC-18 / AC-19 / AC-20 — bilingual coverage, no namespaced keys, no grep-literal collision.

AC-18 hypothesis: "some new key has no zh entry (t() degrades silently to English) or a zh
value whose placeholder set differs from its key's, which raises KeyError at run time".
AC-20 hypothesis: "a zh string doctor emits contains the load-bearing 失败： literal".
The 失败： literal is RENDERED at run time from t('failed: {e}') and searched for in the zh
output — never grepped from the repository (insight-index.md:19: that form is self-violating).
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_fix as F  # noqa: E402
import qa_load  # noqa: E402
from qa_load import T  # noqa: E402

t = T("q5 AC-18/19/20")

head = qa_load.load(text=qa_load.head_source(), name="sc_head")
tree = qa_load.load(name="sc_tree")
old = set(head.TRANSLATIONS["zh"])
new = set(tree.TRANSLATIONS["zh"])
added = sorted(new - old)
print("zh keys: HEAD=%d  tree=%d  added=%d" % (len(old), len(new), len(added)))
t.eq(len(new - old), len(added), "key set diff is well-formed")
t.eq(sorted(old - new), [], "AC-18: no pre-existing zh key was removed or overridden away")
t.eq(len(tree.TRANSLATIONS), 1, "R-4: TRANSLATIONS still has exactly one language table")

# duplicate-key detection: a repeated literal key in the source silently overrides
src = qa_load.SRC.read_text()
zh_block = src[src.index('TRANSLATIONS = {'):src.index('def t(s, **kwargs):')]
lits = re.findall(r'^\s{8}("(?:[^"\\]|\\.)*"):', zh_block, re.M)
dupes = sorted(k for k in set(lits) if lits.count(k) > 1)
t.eq(dupes, [], "R-7: no duplicate key literal in TRANSLATIONS['zh']")

PH = re.compile(r"\{(\w+)\}")
for k in added:
    v = tree.TRANSLATIONS["zh"][k]
    t.eq(sorted(PH.findall(v)), sorted(PH.findall(k)),
         "AC-18: placeholder set matches for %r" % k)
    t.ok(not re.match(r"^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$", k),
         "AC-19: %r is prose, not an identifier-style namespaced key" % k)
    t.ok(all(w.replace("-", "").replace(":", "").isalnum() or not w.isascii()
             for w in k.split()) or " " in k,
         "AC-19: %r reads as English prose/word (no dotted/underscored token)" % k)
    t.ok("失败" not in v, "AC-20(static): the zh value of %r contains no 失败" % k)

# the load-bearing literal, RENDERED at run time
tree.LANG = "zh"
rendered = tree.t("failed: {e}", e="X")
lit = rendered.split("X")[0]
t.ok(lit and "失败" in lit, "AC-20: rendered the grep literal at run time: %r" % lit)

# ---- executed: run doctor under lang zh in five different states ----
GOODCFG = '{"log": {"level": "warn"}, "outbounds": [{"type":"direct","tag":"direct"}], ' \
          '"route": {"final": "direct"}}'
roots = []
scen = [
    ("zh-empty-rules", dict(rulesets="empty", config=GOODCFG)),
    ("zh-no-config", dict(rulesets="good", config=None)),
    ("zh-bad-config", dict(rulesets="good", config="{ nope")),
    ("zh-odd-rulesets", dict(rulesets={"geosite-cn.srs": b"", "geoip-cn.srs": b"<html>"},
                             config=GOODCFG)),
    ("zh-healthy", dict(rulesets="good", config=GOODCFG)),
]
english_keys = added
for name, kw in scen:
    r = F.mkroot(name)
    roots.append(r)
    F.sandbox(r, settings={"lang": "zh"}, **kw)
    rc, out, err = F.run_child({"mode": "doctor", "root": str(r), "lang": "zh",
                                "egress": {"value": "203.0.113.7"}})
    tx = out.decode()
    t.ok(b"Traceback" not in err, "AC-18 %s: no KeyError/traceback under lang zh" % name)
    t.ok(b"KeyError" not in err, "AC-18 %s: no KeyError" % name)
    t.ok(lit not in tx, "AC-20 %s: no output line contains the rendered %r literal" % (name, lit))
    # A leak is an English KEY appearing where its zh rendering should be. Interpolated
    # DATA (a path, a tool's own version string, a filename) is not a key (02_ §10 note),
    # and a key whose zh value IS the key (product names like "Clash API") cannot leak.
    zh = tree.TRANSLATIONS["zh"]
    translated = [k for k in english_keys if zh[k] != k]
    leaked = []
    for line in tx.splitlines():
        if not line.startswith("["):
            continue
        mark, rest = line[1:].split("] ", 1)
        label, _, value = rest.partition(": ")
        for k in translated:
            if k == label:
                leaked.append(("label", line, k))
            stem = k.split("{")[0].strip()
            if stem and len(stem) >= 6 and stem in value and "{" in k:
                leaked.append(("value", line, k))
            elif "{" not in k and k == value:
                leaked.append(("value", line, k))
        if mark not in ("正常", "异常", "未知"):
            leaked.append(("mark", line, mark))
    t.eq(leaked, [], "AC-18 %s: no line is an untranslated English key" % name)
    for m, l in F.labels_of(tx):
        t.ok(m in ("正常", "异常", "未知"),
             "BC-18 %s: class marker %r rendered in Chinese" % (name, m))

# --- NON-VACUITY: break one zh entry and prove the leak detector goes red -------------
bad_src = src.replace('        "rule-sets": "规则集",\n', "")
t.ok(bad_src != src, "non-vacuity: removed the zh entry for 'rule-sets'")
mut = F.HERE / "mutant_i18n.py"
mut.write_text(bad_src)
r = roots[0]
rc, out, _ = F.run_child({"mode": "doctor", "root": str(r), "lang": "zh",
                          "egress": {"value": "1.2.3.4"}}, env={"QA_MUTANT": str(mut)})
t.ok("rule-sets" in out.decode(),
     "non-vacuity: with the zh entry deleted the English key DOES leak — the detector can fail")

# and a placeholder mismatch really does raise KeyError at run time
bad2 = src.replace('"{reason}, {size} bytes": "{reason}，{size} 字节"',
                   '"{reason}, {size} bytes": "{reason}，{bytes} 字节"')
t.ok(bad2 != src, "non-vacuity: introduced a placeholder mismatch")
mut2 = F.HERE / "mutant_ph.py"
mut2.write_text(bad2)
rc, out, err = F.run_child({"mode": "doctor", "root": str(roots[4]), "lang": "zh",
                            "egress": {"value": "1.2.3.4"}}, env={"QA_MUTANT": str(mut2)})
t.ok(b"KeyError" in err or b"Traceback" in err or "无法执行" in out.decode(),
     "non-vacuity: a mismatched placeholder is detectable (stderr=%r)" % err[-160:])
mut.unlink()
mut2.unlink()

print("\nNEW zh KEYS (%d):" % len(added))
for k in added:
    print("  %-62s -> %s" % (k, tree.TRANSLATIONS["zh"][k]))

F.cleanup(*roots)
sys.exit(1 if t.done() else 0)
