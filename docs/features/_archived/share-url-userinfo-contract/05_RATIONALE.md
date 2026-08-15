> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## Capability note — how this review was conducted

This stage holds **no shell**. Every sweep below was run with the ripgrep-backed content-search
tool over the named absolute path; no `git`, `awk`, `grep` or `bash` process was started, and
nothing touched `/etc/sing-box`, `/var/lib/sing-box`, the running service or `/usr/local/bin/sc`.
No real credential byte from the live host appears anywhere in this document (K-20).

Three things the developer verified with a shell were re-established without one:

1. **HEAD's code** — read directly from the developer's baseline clone,
   `…/scratchpad/t22/baseline-clone/bin/sc`. Its `.git/packed-refs` carries
   `51c0f4765a4a7daca9c4ccd66ec887c8ba52304b refs/remotes/origin/main`, and the worktree's
   `.git/refs/heads/main` holds the same SHA — so the clone is a pristine checkout of exactly the
   commit this change sits on. K-19 satisfied, and the differential's baseline is the right one.
2. **The diff** — computed line-for-line between that clone's `bin/sc` and the shipped one.
3. **NFR-3's file set** — established from mtime ordering rather than `git status` (below).

## AC-10 static sweep (V-6 / BND-4 / BND-11), command and output

Run over the whole of `/home/alan/Programs/singbox-cli/bin/sc` — deliberately **wider** than the
`# Share-URL parsers` section, so a userinfo reading that escaped the section would also be caught.
Group (ii) is run quote-agnostically exactly as BND-11 prescribes, so a single-quoted
`split(':', 1)` cannot evade it.

```
pattern 1: \.username|\.password
  -> No matches found        (0 hits in the entire file)

pattern 2: netloc|rpartition|rsplit\("@"|rsplit\('@'|unquote
  575:    return urllib.parse.unquote(frag) if frag else f"{host}:{port}"
  635:    raw = authority.rpartition("@")[0]
  637:    dec = urllib.parse.unquote
  644:    _, uuid, _ = _userinfo(p.netloc)
  704:    password, _, _ = _userinfo(p.netloc)
  724:        name = urllib.parse.unquote(frag)
  726:        userinfo, hostpart = body.rsplit("@", 1)
  737:        method_pwd, hostpart = decoded.rsplit("@", 1)
  753:    password, _, _ = _userinfo(p.netloc)
  778:    _, uuid, password = _userinfo(p.netloc)

pattern 3: (partition|split|rsplit)\(\s*['"]:
  636:    first, _, rest = raw.partition(":")
  729:            method, password = decoded.split(":", 1)
  734:        host, port = hostpart.rsplit(":", 1)
  738:        method, password = method_pwd.split(":", 1)
  739:        host, port = hostpart.rsplit(":", 1)
  -> 5 hits

pattern 4 (my addition, not required by V-6): (partition|split|index|find)\(\s*['"]@
  635, 726, 737, and 2710 (parts[0].split("@")[0] == TUN_IFACE -- an interface name, not a URI)
```

**Reading.** Group (i): zero `.username` / `.password` anywhere in the file, so K-3 and PQ-1 hold
beyond the section. Exactly **one** application of the last-`@` rule (`:635`), inside `_userinfo`,
whose parameter is `authority` — so GF-11's complaint about the original expectation's spelling is
answered as BND-11 corrected it: **four** `p.netloc` argument passes at the call sites (`:644`,
`:704`, `:753`, `:778`) plus one rule application inside the function. `unquote` appears only inside
`_userinfo` (`:637`) and at the two tag decodes (`:575`, `:724`). `parse_ss`'s `body.rsplit("@", 1)`
(`:726`) is present and unchanged (K-6), as is the base64 arm's `decoded.rsplit("@", 1)` (`:737`).

Group (ii): **exactly five**, and they are the five BND-4 enumerated in advance — `:636` inside
`_userinfo`, `:729` the SIP002 base64-userinfo arm (`:715` at HEAD, surviving because CL-6 replaced
only the `except` arm), `:738` the legacy whole-body arm (`:724` at HEAD), `:734` and `:739` the two
host/port splits (`:720`, `:725` at HEAD). **No sixth hit anywhere in the file.** Pattern 4 was added
on my own initiative to catch an `@`-boundary reading spelled with something other than `rpartition`
or `rsplit`; it found none.

## The diff, measured independently (+21 / −11, and the five-versus-seven question)

Derived by comparing `baseline-clone/bin/sc` with the shipped `bin/sc`, site by site:

| site | added | removed |
|---|---|---|
| CL-1 `_userinfo` inserted (def + 5 docstring + 4 body + 2 separating blanks) | 12 | 0 |
| CL-2 vless (`_userinfo` call; `"uuid": p.username` → `"uuid": uuid`) | 2 | 1 |
| CL-3 trojan | 2 | 1 |
| CL-4 hysteria2 | 2 | 1 |
| CL-5 tuic (HEAD `:763-768`, six lines, → one line) | 1 | 6 |
| CL-6 + CL-7 parse_ss (`except` arm; `"password": unquote(password)` → `password`) | 2 | 2 |
| **total** | **21** | **11** |

Inside K-12's ≤22 / ≤11. The docstring is 5 physical lines (`:630-634`), i.e. the element list was
trimmed rather than the cap negotiated — exactly what PQ-10 instructed.

**Why five hunks and not seven, and why that is not evidence of a missing edit.** `git diff` merges
two change sites into one hunk when fewer than `2 × context` unchanged lines separate them, and the
default context is 3 — so the merge window is 6 unchanged lines. Measured on HEAD's numbering:

- CL-1's insertion point (after `:628`) and CL-2's inserted call (after `:631`) are **3** lines
  apart → merged; CL-2's own two changes (`:631` and `:637`) are 5 lines apart → merged. One hunk.
- CL-7 (`:732`) and CL-4's inserted call (after `:738`) are separated by exactly **6** unchanged
  lines (`:733-738`) → merged. One hunk.
- CL-6 (`:717`) and CL-7 (`:732`) are separated by 14 unchanged lines → **not** merged.

That gives, deterministically: {CL-1+CL-2}, {CL-3}, {CL-6}, {CL-7+CL-4}, {CL-5} = **five**. The gate
predicted seven because it counted change *sites*, and its own BND-13 text anticipated the mismatch
("a `git diff` showing seven hunks satisfies it because `parse_ss` carries two") while naming the cap
as the binding number. A hunk count is a property of the renderer's context setting, not of the
change; all seven sites are present and each is the one CL-n specifies. **BND-13 discharged.**

## Three behaviour deltas, re-derived from HEAD rather than accepted (RT-6 / BND-3)

`baseline-clone/bin/sc:763-768` is HEAD's tuic block:

```
    userinfo = p.username or ""
    if ":" in userinfo:
        uuid, password = userinfo.split(":", 1)
        password = urllib.parse.unquote(password)
    else:
        uuid, password = userinfo, ""
```

CPython's `.username` is `netloc.rpartition('@')[0].partition(':')[0]`, so it can never contain a
colon: the `if` is structurally dead, `password` is unconditionally `""`, and `uuid` is never
decoded. That single reading is the origin of both AC-12 (a) and AC-12 (d)'s tuic half, and it
confirms the changelog's causal sentence about `username` is accurate.

Per-parser, HEAD versus shipped, over the whole input space:

- **vless** — HEAD `p.username`; shipped `dec(first)`. Differs in (i) percent-decoding (FR-7, stated,
  positively observed by `v16`) and (ii) `None` → `""` when the authority carries no `@` (**K-9,
  delta 3**). With an `@` present but an empty userinfo both give `""`. Nothing else.
- **trojan / hysteria2** — HEAD `unquote(p.username or "")`; shipped `dec(raw)`. These differ **only**
  when the userinfo carries a raw colon (FR-5, stated). With no `@`, HEAD's `None or ""` and
  `rpartition`'s `""` agree. This is precisely why AC-2's expected-mismatch set contains the three
  `F-a` fixtures of each and none of `F-b`…`F-e`.
- **tuic** — HEAD (`""`, undecoded first field); shipped (`dec(first)`, `dec(rest)`). Both differences
  are FR-4's stated effects. No-userinfo agrees (`""`, `""`), which is AC-8.
- **shadowsocks** — base64 arms: password no longer percent-decoded (FR-6 / BC-9 / Q-4, stated; `s_h`).
  Plaintext arm: **delta 1** (colonless — including empty — userinfo no longer raises `ValueError`
  out of `userinfo.split(":", 1)`) and **delta 2** (`method` now decoded). Boundary and password
  decoding are unchanged: HEAD split the raw userinfo at its first colon and decoded the password
  once, and so does `_userinfo`.
- **vmess** — untouched.

**No fourth delta.** The gate, the architect and I each derived this independently and agree; the
edges I probed specifically for a fourth were the empty-userinfo-with-`@` case (agrees), the
no-userinfo case for all four `urlparse` schemes (agrees), the bracketed-IPv6 case (brackets live
right of the last `@`, so `whole` never sees them), and the `ss://` body whose `@` sits in a
`?plugin=` tail (`rpartition` and `rsplit` are the same function here, so unchanged from HEAD).

## Why the harness is not vacuously green (R-22, BND-1, BND-6)

I did not read the developer's transcript as evidence. Three properties decide it, and each is
visible in the harness source:

1. **Expected values are constants, never the parser's output.** `fixtures.py` carries
   `expect=dict(password="p:q")`-style literals; `compare.py:22-34` compares `obj.get(k)` against
   `want` from that dict. `grep`-equivalent for `quote(` over `fixtures.py` and `runner.py`: zero.
   No known credential is round-tripped through an encoder, so K-21's failure mode cannot occur.
2. **Raw colons are raw.** `t_a` is `tuic://u1:p:q@h.example:443`, `j_a1/2/3` are `::@`, `:pw@`,
   `pw:@`, `s_a` is `aes-256-gcm:p:q@`, `v11` is `a:b@`. None is `%3A`. `j_a3`/`y_a3` (`pw:`) are the
   shapes a `first + ":" + rest` rebuild cannot emit, so BND-5's third BC-4 shape does the work I-1's
   third projection exists for.
3. **The control is code, not narration.** `compare.py:48-67` builds `got_mismatch` from the HEAD run
   against the same constants, compares it to the hand-authored `head_mismatch` set, and prints
   `HARNESS INDICTED (never bin/sc)` on a match **inside** the set or a mismatch **outside** it —
   V-2's void condition implemented rather than described.

I then re-derived all nineteen `head_mismatch` values by hand against HEAD's `:637`, `:696`, `:744`,
`:763-768`. Spot-checks that matter: `j_a1` (`trojan://::@h:443`) → HEAD userinfo `::`,
`.partition(':')[0]` = `""`, so HEAD emits `""` against an expected `"::"` → red, correctly flagged.
`j_a3` (`pw:@`) → HEAD `"pw"` against `"pw:"` → red. `j_b` (`a%3Ab@`) → no raw colon, so HEAD's
`unquote` already gives `a:b` → green **by construction**, correctly flagged `head_mismatch=False`.
`j_e` (`a@b@h:443`) → HEAD's own `rpartition` gives `a@b`, no colon → green. Total red = 5 tuic +
3 trojan + 3 hysteria2 = **11**, exactly BND-1's set. The developer's number is reproducible.

One further vacuity route I checked and found closed: `s_j` / `s_a` / `s_e` only exercise the
plaintext arm if `_b64dec` raises on their userinfo. Were the try arm to win, `method` would not be
`aes-256-gcm` and `check_expect`'s constant would fail — so arm selection is asserted, not assumed.
`s_k` independently proves the `except` arm is reachable, since HEAD raises there.

Neutralisation: `runner.py:26-38` installs the `os` shim, `exec(compile(...))`s into a fresh module
object and restores `sys.modules["os"]` in a `finally`; `:41-62` repoints all eight path constants
and **asserts each resolves inside the fixture root** before anything runs; `:93-94` asserts
`sc.LANG` and `sc.CLASH_PORT` after every single run (K-17's vacuity trap); `main()` and
`_init_files()` are never called; `run.sh:10` refuses to run as root and `:16` uses `git clone`,
never `git worktree`.

## CR-1 — what exactly is unobserved, and why it is MINOR rather than MAJOR

The ss corpus is `s_j` (`aes-256-gcm:pw`), `s_a` (`aes-256-gcm:p:q`), `s_e` (`aes-256-gcm:pw@a`),
`s_i` (legacy base64 whole body), `s_h` (base64 userinfo containing `p%41q`) and `s_k` (colonless).
Only `s_h` contains a `%`, and its `%41` is inside base64-recovered material. So **no fixture puts a
`%` into an ss plaintext userinfo at all**, and three declared things go unobserved:

- BC-10's `%3A` half. Its colon half is covered by `s_a`.
- BND-12's own named divergence case. The condition text singles out `ss://a%3Ab:pw@h:443` as "the
  case where the two orders diverge", and the developer's disposition answers it with `x5` — which
  is a **tuic** URL. The order is correct in the shipped code, and it is correct for `parse_ss` for
  the strong reason that both consume one construct at `bin/sc:635-638`; but no ss fixture observes it.
- K-8 delta 2. The developer's own BND-3 row says it plainly: "no `%`-carrying `method` fixture
  diverges". A pre-declared delta that no fixture can see is a delta taken on trust.

I rated this MINOR rather than MAJOR under the standing decision authority, on three grounds. First,
the shipped behaviour is not in doubt: `parse_ss`'s plaintext arm has no boundary logic of its own
left to be wrong (my group-(ii) sweep shows the only colon split reachable from it is `:636`), so
this is a gap in *evidence*, not in *behaviour*. Second, AC-3 enumerates its ss fixture set
explicitly — `F-h`, `F-i`, `F-j` plus one `F-a` and one `F-e` — and the developer supplied exactly
that set plus `s_k`; the letter of the criterion is met, and the gap is in the criterion. Third, QA
runs next, owns V-3, and closes all three with one fixture line. Blocking the merge to re-run an
uncommitted harness that T-28 will re-implement from the `06_TEST_REPORT.md` listing would spend a
round for no change to the artifact. RES-1 carries it with the fixture written out so QA cannot
mis-transcribe it: `ss://a%3Ab:pw@h.example:8388#s_b` → `method` `a:b`, `password` `pw`.

## CR-3 — the changelog clause, weighed

K-14 (a) is satisfied on every count I could test against HEAD, including the two non-claims, which
the bullet does not merely omit but states positively as correct-today — a stronger discharge than
the condition asks for, and the right call, since a user scanning for their own case needs to be
told they are *not* affected. My only reservation is the parenthetical «服务端因此一直认证不过».

The empty-password predicate is verified. Its consequence for a live TUIC handshake is not, and
AC-13 — the row that would verify it — is BLOCKED by construction, which is exactly why K-20 forbids
substituting an artifact check for it. The inference is very likely true, and nothing about the
repair advice changes if it is false. But K-14's stated concern is a sentence in "the one document
its audience cannot check", and this is one clause further than what was measured. Softening it to
what is known (the stored password is empty, so the node cannot authenticate with the credential its
link carried) costs nothing. Non-blocking; the developer may take it at the same time as any other
change or decline it with a line in `PM_LOG.md`.

## BND-7, and the one site the gate did not enumerate

The shipped sentence is `bin/sc:634`: *"No other site states any of these rules for a userinfo field
taken from URI text."* GF-7 enumerated the two sites it had to survive — `:729`/`:738` (base64,
never URI text) and `:575`/`:724` (URI text, but a tag). A third site exists that neither the gate
nor the developer named: `:726`, `body.rsplit("@", 1)`, which does apply the last-`@` rule to URI
text.

It does not falsify the sentence, and the reason is a happy consequence of CL-6 rather than a design
intention: before this change, `:717` consumed that `userinfo` variable to produce the plaintext
arm's `method` and `password` — i.e. it *did* yield userinfo fields from URI text. After CL-6 the
`except` arm reads `body` and calls `_userinfo`, so `:726`'s output now feeds **only** `_b64dec` at
`:729`. Its product is a base64 candidate, never a field. The sentence is true of the shipped file,
and it is true because of an edit whose purpose was something else. I record it because a future
change that gives `:726`'s variable a second consumer would silently falsify a shipped claim, and
nothing in the file says so. That is CR-4's whole content.

## NFR-3 without `git status`

`git status` was unavailable. The substitute is modification-time ordering across the tracked tree,
which is decisive here because the stage documents themselves are timestamps. Ordered oldest to
newest, the tail of the repository reads:

```
… docs/tasks.md · docs/batches/default/{BATCH_PLAN,BATCH_LOG,BATCH_REPORT}.md ·
docs/batches/followups/{BATCH_PLAN,BATCH_LOG}.md ·
01_REQUIREMENT_ANALYSIS.md · 01_RATIONALE.md · 02_RATIONALE.md · 02_SOLUTION_DESIGN.md ·
03_GATE_REVIEW.md · 03_RATIONALE.md ·
bin/sc · CHANGELOG.md · docs/dev-map.md ·
04_DEVELOPMENT.md · 04_RATIONALE.md · PM_LOG.md
```

Everything between `03_RATIONALE.md` and `04_DEVELOPMENT.md` is what stage 4 wrote: exactly
`bin/sc`, `CHANGELOG.md`, `docs/dev-map.md`. `docs/batches/**` sits *before* stage 1 and is
therefore untouched, as are `README.md`, `README.zh-CN.md`, `install.sh`, `uninstall.sh`,
`systemd/**`, `.harness/**` and `docs/tasks.md`. The permitted product diff (`bin/sc` +
`CHANGELOG.md`) plus CL-9's declared stage-4 navigation duty is precisely the set observed.

Two pre-existing observations, neither this task's doing and neither a finding: `test/t20/.head-clone`
is a HEAD clone from T-20 living **inside** the worktree, kept invisible only by `.gitignore`'s
`test/` line — worth knowing, because K-15's "outside the worktree" requirement was met this time by
`…/scratchpad/t22/` and the T-20 artifact shows the other habit exists. And `docs/tasks.md` carries a
modification that predates stage 1, i.e. PM bookkeeping from before this task's code work.

## What I checked and found nothing to report

Recorded so a later reader knows these were looked at rather than skipped: BC-6's double-decode
arithmetic (`unquote("100%2525")` = `100%25`, `unquote("100%25")` = `100%`, one pass each); BC-3's
bracketed IPv6 in all three credential-bearing schemes plus the no-userinfo IPv6 case, where
`rpartition` returns `""` and the bracket colons can never reach `partition(":")`; BC-1/BC-2 for all
four `urlparse` schemes; the `%FF` path (`unquote`'s `errors='replace'` default, no exception, no new
error path — BC-8, unobserved but structurally sound); the 3.6 floor (`str.partition`,
`str.rpartition`, no new import — K-11, NFR-1); `SECRET_KEYS` / `VISIBLE_IN_OUTBOUND` / `MASK` /
`_redact` untouched, so R-46 stays filed under Q-5's condition; the emitted key set unchanged, vless's
`uuid` moving `null` → `""` without adding a key; `README.md` searched for any sentence about
credential fidelity that this change would falsify (there is none — the only relevant line enumerates
supported schemes, which is unaffected), so NFR-3's README clause does not fire; and `失败：`, which
occurs once in `CHANGELOG.md` at line 39, inside a 0.1.0-era entry, and zero times in the new bullet.
