> Rationale portion for 04_DEVELOPMENT.md. Non-binding.

# 04 — Development rationale · T-22 `share-url-userinfo-contract`

## Where the harness lives, and how to re-run it

Outside the repository worktree, never committed (K-15 / BND-9):

```
/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad/
├── sweep.sh          ← AC-10 / V-6 static sweep (banner-anchored, quote-agnostic)
└── t22/
    ├── fixtures.py   ← the 50-fixture corpus; the per-class construction block is below
    ├── runner.py     ← import neutralisation + 8-constant repointing + one run per fixture
    ├── compare.py    ← AC-1…AC-8 / AC-16 evaluation over the two result files
    ├── run.sh        ← driver: git clone baseline, run both checkouts, compare
    ├── static.sh     ← AC-9 / AC-11 static checks
    ├── baseline-clone/  ← git clone of the repo at 51c0f47 (never a git worktree, K-19)
    ├── fixture-root/    ← THE one fixture root, used by both checkouts (K-19 / PQ-7)
    └── stub-sing-box    ← `#!/bin/sh` / `exit 0`, assigned to sc.SB_BIN
```

`bash .../t22/run.sh` re-runs everything (clone is reused if present). It refuses to run as root.
RT-5 asks QA to paste the full listing into `06_TEST_REPORT.md`; the block most likely to be got
wrong on a re-implementation is reproduced verbatim below.

## The per-class fixture-construction block (K-21 / BND-6), verbatim

No `quote()` call exists anywhere in the harness. Every userinfo is explicit text, and every expected
value is the constant the URL text was written to carry — never a value re-derived by encoding it.

```python
H = "h.example"
# tuic x F-a..F-e -- one fixture per class, all five expected red at HEAD
dict(id="t_a", url="tuic://u1:p:q@%s:443#t_a" % H,            expect=dict(uuid="u1", password="p:q"))
dict(id="t_b", url="tuic://u1:a%%3Ab@%s:443#t_b" % H,         expect=dict(uuid="u1", password="a:b"))
dict(id="t_c", url="tuic://u1:100%%2525@%s:443#t_c" % H,      expect=dict(uuid="u1", password="100%25"))
dict(id="t_d", url="tuic://u1:p%%E4%%B8%%AD@%s:443#t_d" % H,  expect=dict(uuid="u1", password="p中"))
dict(id="t_e", url="tuic://u1:a@b@%s:443#t_e" % H,            expect=dict(uuid="u1", password="a@b"))
# trojan / hysteria2: F-a is THREE fixtures -- BC-4's '::', ':pw', 'pw:' (BND-5)
dict(id="j_a1", url="trojan://::@%s:443#j_a1" % H,            expect=dict(password="::"))
dict(id="j_a2", url="trojan://:pw@%s:443#j_a2" % H,           expect=dict(password=":pw"))
dict(id="j_a3", url="trojan://pw:@%s:443#j_a3" % H,           expect=dict(password="pw:"))
dict(id="j_b",  url="trojan://a%%3Ab@%s:443#j_b" % H,         expect=dict(password="a:b"))
dict(id="j_c",  url="trojan://100%%2525@%s:443#j_c" % H,      expect=dict(password="100%25"))
dict(id="j_d",  url="trojan://p%%E4%%B8%%AD@%s:443#j_d" % H,  expect=dict(password="p中"))
dict(id="j_e",  url="trojan://a@b@%s:443#j_e" % H,            expect=dict(password="a@b"))
#   ... y_a1..y_e are the same seven with the hysteria2:// scheme
# BND-10: '%'-free vless userinfo with a RAW colon -- byte-identical to HEAD, uuid 'a' not 'a:b'
dict(id="v11", url="vless://a:b@%s:443#v11" % H, expect=dict(uuid="a"), identical=True)
# AC-16: FR-7's decode half -- HEAD emits 'a%2Db'
dict(id="v16", url="vless://a%%2Db@%s:443#v16" % H, expect=dict(uuid="a-b"), identical=False)
```

(`%%` is the `%`-formatting escape; the URL text carries a single literal `%`.)

The trap this block exists to avoid, stated once: `urllib.parse.quote()` defaults to `safe='/'`, so it
encodes a raw `:` as `%3A`. Passing a known password through it turns every `F-a` fixture into an
`F-b` one — AC-1 then goes green against a *truncating* parser and AC-2's expected mismatch vanishes
for trojan and hysteria2, so both criteria agree with each other while observing nothing (RS-11).

## Why AC-2 is trustworthy here, and what would have indicted the harness

The control was run first, and its red set was compared to BND-1's enumeration **before** any AC-1
number was read. Two symptoms would have indicted the harness rather than `bin/sc`: a **match inside**
the expected set (a fixture whose HEAD reading happens to be right — the signature of a `quote()`-built
URL, or of an expected value re-derived from the parser's own output), and a **mismatch outside** it
(a fixture observing something other than this change — a moved fixture root, a stale `.config.sha256`,
a `LANG`/`CLASH_PORT` reassignment). Neither appeared: the red set is `t_a t_b t_c t_d t_e j_a1 j_a2
j_a3 y_a1 y_a2 y_a3`, exactly 11, exactly BND-1's members.

The eight green-at-HEAD fixtures are green *by construction*, and the reason is worth stating so no
later stage reads them as a broken control: their userinfo carries no **raw** colon, so CPython's
`netloc.rpartition('@')[0].partition(':')[0]` returns the whole userinfo and HEAD's single `unquote`
already produces the right answer. HEAD is wrong about *where a userinfo ends*, and those eight
fixtures do not ask it that question.

## BND-12: the order, and why the two orders diverge

The plaintext `ss://` arm splits the **raw** userinfo and decodes afterwards. Inside `_userinfo`:

```python
raw = authority.rpartition("@")[0]      # last '@'  -- reproduces body.rsplit("@", 1)[0] value-for-value
first, _, rest = raw.partition(":")     # first RAW colon -- before any decoding
dec = urllib.parse.unquote
return dec(raw), dec(first), dec(rest)  # each projection decoded exactly once
```

`ss://a%3Ab:pw@h:8388` is the case where the two orders disagree: split-then-decode gives
`method = "a:b"`, `password = "pw"`; decode-then-split gives `method = "a"`, `password = "b:pw"`. The
second reading makes the URL's meaning depend on how its author chose to encode it, which is the
defect FR-2 exists to remove — hence the gate's ruling that `01` FR-6's "first colon of the *decoded*
userinfo" governs the two base64 arms only. The base64 arms keep their own split and get **no**
`unquote`: their material was never URI text (BC-9, K-7), and `s_h` observes it — HEAD stored `pAq`
where the link carried `p%41q`.

## BND-7: getting the docstring's one sentence right

The shipped sentence is *"No other site states any of these rules for a userinfo field taken from URI
text."* Two weaker scopings were rejected on arrival, each falsified by the file it ships in:

- *"no other site restates any of them"* — falsified by `bin/sc:729` / `:738`, the two base64 colon
  splits FR-6 and K-7 deliberately keep.
- *"…for text taken from URI text"* — falsified by the tag decodes at `:575` and `:724`, which are URI
  text; they are a **tag**, not a userinfo field, which is why the word `field` carries the scope.

A shipped file must not carry a claim its own code contradicts; the sweep in the contract portion is
what shows the sentence is true as scoped.

## Measurement narrative

1. `verify_all` baseline captured before the first edit: PASS 17 / WARN 0 / FAIL 0 / SKIP 1.
2. Edits applied in the design's order — CL-1, CL-5 (tuic, the structurally dead branch), CL-3+CL-4
   (identical projection, one edit in two places), CL-2, then CL-6+CL-7 together (CL-6 alone would
   double-decode the plaintext arm; CL-7 alone would stop decoding it entirely). `py_compile` after
   the function landed, `git diff --numstat` after the last one: `21 11`.
3. Harness built, baseline cloned at `51c0f47`, **baseline run first**, candidate second, same fixture
   root, `nodes.json` / `settings.json` rewritten and `.config.sha256` deleted per fixture.
4. `compare.py` evaluated AC-1…AC-8 and AC-16 over the two result files: 0 failing rows, 11 red at
   HEAD, 19 AC-1 fixtures.
5. Static sweeps (`sweep.sh`, `static.sh`) for AC-9 / AC-10 / AC-11.
6. `CHANGELOG.md` and `docs/dev-map.md` written last, so both describe what shipped.
7. `verify_all` re-run: identical to baseline.

Two facts about the run environment that a re-run should keep: the stub `SB_BIN` makes
`generate_config()`'s `sing-box check` a no-op returning 0 (so AC-14 is *not* observed here, which is
correct — it is non-regression only), and `if_inet6` is written empty so `ipv6_decision()` is
deterministic across both checkouts. Every run asserted `sc.LANG == "en"` and `sc.CLASH_PORT == 29090`
afterwards; neither ever moved, because `main()` is never called.
