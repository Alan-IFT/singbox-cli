# 06 — Rationale — restricted-network-regression-test (T-07)

> Rationale portion for 06_TEST_REPORT.md. Non-binding.

Full tool runs whose ≤5-line excerpts the contract cites, the measurement narrative, and the
reproducer sources. Everything the QA schema admits no section for lands here (R-37, sixth
occurrence: `.harness/rules/70-doc-size.md` still has no `## Stage-doc boundary rule`).
Session scratchpad root, `$S` below:
`/tmp/claude-1000/-home-alan-Programs-singbox-cli/a17674e2-5185-45cb-8e32-1055c19e0e23/scratchpad`

## 0 — Method, and what I deliberately did not read

Stage 4's transcripts (`04_RATIONALE.md` §8 §9 §10) were left unread until every run below had
been taken, so that no fixture, no marker string and no expected value in this stage descends from
the developer's own tests. Every fixture was built from the AC/BC table and from `bin/sc` /
`install.sh` at HEAD. Where a stage-4 or stage-5 claim is reproduced (D-3, GC-3, GC-4, CR-15,
F-6), it is reproduced from scratch and the agreement is reported as agreement, not as evidence
borrowed. Triggers T6.1 / T6.2 / T6.3 did not need to fire against a missing document —
`01_RATIONALE.md`, `02_RATIONALE.md`, `04_RATIONALE.md` and `05_RATIONALE.md` all exist. T6.2 was
reached for once (D-3's negative control) and answered by re-deriving the measurement instead.

## 1 — AC-1, V-1 (RES-2 half)

```
$ git ls-files -s .harness/scripts/restricted-network-regression.sh
100755 aa8477f3f09237d6b6cdac5b50274497b6bfe0a4 0	.harness/scripts/restricted-network-regression.sh
ls-files rc=0
$ git check-ignore -v .harness/scripts/restricted-network-regression.sh
check-ignore rc=1              # no output, no matching pattern
$ stat -c '%a %n' .harness/scripts/restricted-network-regression.sh
755 .harness/scripts/restricted-network-regression.sh
```

`.gitignore` was read whole (24 lines): the only pattern that could have caught the artifact is
`test/` at `:19`, and the artifact is under `.harness/scripts/`.

## 2 — AC-2, V-2

```
$ bash -n .harness/scripts/restricted-network-regression.sh
bash -n rc=0
$ wc -l .harness/scripts/restricted-network-regression.sh
330
$ bash .harness/scripts/verify_all.sh
[A.1] No hardcoded secrets ... PASS      [F.1] AI-GUIDE.md <=200 lines ... PASS
[A.2] No .env files committed ... PASS   [F.2] Rule fragments <=200 lines each ... PASS
[B.1] Syntax (bin/sc, install.sh, uninstall.sh) ... PASS
[B.2] install.sh bilingual key parity ... PASS
[B.3] Lint ... SKIP
[E.1]…[E.6] ... PASS (E.6 = Adversarial tests section in completed task reports)
[F.3] Agent definitions <=300 lines each ... PASS
[F.4] insight-index.md <=30 lines ... PASS
[F.5] docs/tasks.md <=300 lines ... PASS
[F.6] Active task docs <=500 lines each ... PASS
=== Summary ===  PASS: 17  WARN: 0  FAIL: 0  SKIP: 1     EXIT=0
```

Measured three times: before the `test/head-baseline` clone existed, with it present, and at
delivery after both stage-6 documents were written. Identical each time.

## 3 — AC-3 / AC-4 / GC-6, V-3 and V-4

Every run below was taken with `cwd` and `TMPDIR` pointed at freshly created empty directories, as
uid 1000. Full transcript:

```
########## RUN 1: no argv                                   exit=2
--stdout--                                                  (empty)
--stderr--
usage: restricted-network-regression.sh --i-will-destroy-this-vm
       restricted-network-regression.sh --self-check [--source FILE]

--i-will-destroy-this-vm  run the scenario. Root, on a DISPOSABLE single-use
                          systemd VM only. It edits /etc/hosts and installs.
--self-check              derive the blackout and check coverage. No root, no
                          network, writes nothing. --source defaults to bin/sc.
condition lines on stdout: 0
########## RUN 2: bad argv (--bogus)                        exit=2   (same usage)
########## RUN 3: token present, configured host            exit=3
REFUSED: a configured installation is present: /etc/sing-box/nodes.json
This is not a disposable VM. Nothing was read, written or started.
E1 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E2 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E3 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E4 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E5 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
E6 UNMET obs=refused;node_store=/etc/sing-box/nodes.json pair=none
--stderr--                                                  (empty)
########## RUN 4: token + extra argv                        exit=2, stdout 0 lines
########## write check
cwd contents: []   TMPDIR contents: []
hosts sha: 2f3a6061eaf9572bb13609518317d19417cfe64c5c2223b034d0b581acdcdf70
```

Non-vacuity of the write check — the same predicate against a deliberate writer:

```
$ TMPDIR=$S/nvtmp bash -c 'echo x > ./decoy; echo y > "$TMPDIR/decoy2"'
after a deliberate writer: cwd=[decoy] TMPDIR=[decoy2]
```

Gate-2-precedes-everything, established on the code rather than assumed: the three call sites that
can touch a host are `:196` (`getent`), `:206` (`bash "$REPO/install.sh"`) and `:283`
(`/usr/local/bin/sc update-rules`), all past gate 4; `command -v curl` at `:165` is already past
gate 2. `grep -n sleep` returns only `:260` and `:286`, likewise past gate 4 — which is why the
`[HOST]` forms finish in 3-10 ms and the artifact's 15 s of own waiting is unreachable here.

## 4 — AC-4 hardening: near-miss argv (mine, not in any upstream plan)

The one thing that would have been catastrophic on this host is an argv that is *not* the token
but still reaches the scenario. `case "${1:-}" in "$TOKEN")` expands `TOKEN` as a **pattern**, so
this had to be measured, not reasoned about.

```
  argv=[--i-will-destroy-this-vm ] exit=2 stdout_lines=0     (trailing space)
  argv=[ --i-will-destroy-this-vm] exit=2 stdout_lines=0     (leading space)
  argv=[--I-WILL-DESTROY-THIS-VM] exit=2 stdout_lines=0
  argv=[--i-will-destroy-this-v]  exit=2 stdout_lines=0
  argv=[--i-will-destroy-this-vmx] exit=2 stdout_lines=0
  argv=[--i-will-destroy-this-*]  exit=2 stdout_lines=0      (glob)
  argv=[*]                        exit=2 stdout_lines=0
  argv=[--i-will-destroy-this-vm --self-check] exit=2
=== positive control (exact token) ===
  argv=[--i-will-destroy-this-vm] exit=3 stdout_lines=8
      first_out=[REFUSED: a configured installation is present: /etc/sing-box/nodes.json]
```

Ten near-misses, one hit, and the hit stops at gate 2. `/etc/hosts` digest unchanged after all
eleven.

## 5 — AC-5 covered arm, and GC-5 / RES-3 character-for-character

Full covered-arm transcript:

```
$ bash …/restricted-network-regression.sh --self-check                     exit=0
derived bases (4):
https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo
https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo
blackout hosts (6):
api.github.com
cdn.jsdelivr.net
ghfast.top
github.com
raw.githubusercontent.com
testingcf.jsdelivr.net
SELF-CHECK OK: 4 shipped base(s), all covered
```

RES-3 asks for a character-for-character comparison against `bin/sc:113-118`. Doing that by eye
would be exactly the "looks correct from the diff" this stage is forbidden. The expected list was
therefore produced by an **independent parser** — `ast.literal_eval` over lines 113-118, which
shares no code with the artifact's `sed`+`grep -oE` — and the two were compared with `cmp`:

```
$ python3 $S/extract_bases.py > $S/sc.bases          # ast.literal_eval of bin/sc:113-118
$ sed -n '2,5p' $S/r5.out       > $S/printed.bases   # the transcript's four URLs
$ cat -A $S/sc.bases            # no trailing whitespace, LF only
https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo$
https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo$
https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo$
https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo$
$ cmp $S/sc.bases $S/printed.bases && echo "cmp rc=0 : BYTE-IDENTICAL, 4 of 4"
cmp rc=0 : BYTE-IDENTICAL, 4 of 4
$ sha256sum $S/sc.bases $S/printed.bases
f1f66d7d857ee9a16fdba4a85cbe443122d2dff252712d4711460f7d2392215e  sc.bases
f1f66d7d857ee9a16fdba4a85cbe443122d2dff252712d4711460f7d2392215e  printed.bases
```

`extract_bases.py`, in full:

```python
import ast
src = open('/home/alan/Programs/singbox-cli/bin/sc', encoding='utf-8').read().splitlines()
blk = "\n".join(src[112:118])          # lines 113..118, 1-based
assert blk.splitlines()[0] == "RULESET_BASES = (", blk.splitlines()[0]
for u in ast.literal_eval(blk.split('=', 1)[1].strip()):
    print(u)
```

The assertion on the block header is what makes the extraction non-vacuous: if `RULESET_BASES`
ever moves, the script raises rather than silently comparing the wrong lines. Two negative
controls proved the `cmp` discriminates:

```
NC-1 one-byte mutation (testingcf -> testingcg):
  sc.bases.mut printed.bases differ: byte 79, line 2          rc=1
NC-2 one line dropped:
  cmp: EOF on sc.bases.short after byte 217, line 3           rc=1
```

Why this mattered: **F-6 is real and unrepaired**, and I reproduced it before doing the
comparison. `--source` with a three-base list yields `SELF-CHECK OK: 3 shipped base(s), all
covered`, exit 0. So exit 0 carries no information about whether the derivation matched the
shipped list; only the printed list does, and only if someone compares it. GC-5's design is
correct and its discharge depends entirely on this section.

## 6 — AC-5 uncovered arm, and the whole coverage-predicate boundary sweep

Seventeen scratch source files, all built from the BC table. Verdicts:

| fixture | content | result | exit |
|---|---|---|---|
| `f1_iplit` | one `https://127.0.0.1/geo` | `SELF-CHECK FAIL: uncoverable base(s): https://127.0.0.1/geo` | 1 |
| `f2_empty` | `RULESET_BASES = (` + `)` | `SELF-CHECK FAIL: no base parsed from …` (BC-13) | 1 |
| `f3_nolist` | no block, a URL elsewhere | `SELF-CHECK FAIL: no base parsed from …` (BC-13) | 1 |
| `f5_three` | three bases | `SELF-CHECK OK: 3 shipped base(s), all covered` — **F-6** | 0 |
| `f6_userinfo` | `https://u@raw.githubusercontent.com/…` | `OK`, blackout host `u@raw.githubusercontent.com` | 0 |
| `f6b_userinfo` | `https://u@cdn.example/geo` | `OK`, blackout host `u@cdn.example` — **D6-1** | 0 |
| `f7_squote` | single-quoted entry | base `https://single.example/geo',` — **D6-3** | 0 |
| `f8_noclose` | indented closing paren | picks up `https://sneaky.example/geo` — **D6-2** | 0 |
| `f9a/f9b/f9c` | `localhost` / `:8443` / empty host | each named as uncoverable | 1 |
| `f10_glob` | `https://a*.example/geo` | `OK`, host `a*.example` (CR-10 confirmed) | 0 |
| `f11_unreadable` | mode 000 | `sed: can't read …: Permission denied` then `no base parsed` | 1 |
| `f12_crlf` | CRLF endings | `https://crlf.example/geo` — clean, no `^M` (`cat -A` verified) | 0 |
| `f13_ipv6` | `https://[2001:db8::1]/geo` | uncoverable (caught by `*:*`) | 1 |
| `f14_dup` | same base twice | `2 shipped base(s)`, hosts deduplicated to 4 | 0 |
| `f15_unicode` | U+00E9 in the host | `OK`, host `uniM-CM-).example` (`cat -A`) | 0 |
| `<a directory>` | — | `SELF-CHECK FAIL: no such source file: …/src` | 1 |
| `--source` with no value | — | usage | 2 |

`cwd` and `TMPDIR` were empty after all seventeen.

D6-1's measurement, which is what turns "looks odd" into a defect:

```
$ python3 -c "from urllib.parse import urlsplit; s=urlsplit('https://u@cdn.example/geo'); …"
url          = https://u@cdn.example/geo
netloc       = u@cdn.example    <- what host_of() returns
hostname     = cdn.example      <- what urllib/curl resolves
equal?       = False
```

`uncoverable()` direct table (from `qa_units.sh` U1) — the predicate's real shape:

```
  ''  -> UNCOVERABLE     'localhost' -> UNCOVERABLE   '127.0.0.1' -> UNCOVERABLE
  '10.0.0.1' -> UNCOVERABLE   'a.example:8443' -> UNCOVERABLE  '[2001:db8::1]' -> UNCOVERABLE
  'cdn.jsdelivr.net' -> coverable   'ghfast.top' -> coverable
  'u@cdn.example' -> coverable   '1.2.3.example' -> coverable   '1cdn.example.com' -> coverable
```

The last two are correct (they are real names `/etc/hosts` can map, and the glob does not
false-positive on digit-leading hostnames); the third-from-last is D6-1.

## 7 — AC-16 / AC-17, V-8 and V-9, under GC-11

GC-11 says the baseline must be a `git clone`, never a `git worktree`, because a worktree's `.git`
is a **file** and `verify_all` A.1/A.2 then turn SKIP while the summary still reads a plausible
14/4. Both halves were checked, in this order — clone first, `find`-reachability second, counts
only third:

```
$ git clone --quiet --no-hardlinks . test/head-baseline
$ stat -c '%F %n' test/head-baseline/.git
directory /home/alan/Programs/singbox-cli/test/head-baseline/.git      <- not a file
$ git -C test/head-baseline rev-parse HEAD ; git rev-parse HEAD
6f7d9c3d3231656b13f9e75531a0489bd45790eb
6f7d9c3d3231656b13f9e75531a0489bd45790eb
$ git check-ignore -v test/head-baseline
.gitignore:19:test/	test/head-baseline
$ for root in .harness/agents .harness/rules docs/features; do
      echo "root=$root -> $(find "$root" -path '*head-baseline*' | wc -l) hits"; done
root=.harness/agents -> 0 hits
root=.harness/rules -> 0 hits
root=docs/features -> 0 hits
```

Those are the only three `find` roots in `verify_all.sh` (`:102`, `:155`, `:177`, `:200`, `:209`,
`:235` — three distinct roots), and `grep -nE 'grep -r|grep -R|globstar|\*\*'` finds no other
recursive scan. `git status --short` does not list the clone. Only then were the counts read, and
they were `PASS 17 / WARN 0 / FAIL 0 / SKIP 1`, identical to the pre-clone measurement.

Byte identity:

```
install.sh                     90b3167a9610 IDENTICAL
bin/sc                         08732ea127c0 IDENTICAL
uninstall.sh                   9bf90dde3cd9 IDENTICAL
systemd/sing-box-rules-update.service cddebb89a7a4 IDENTICAL
systemd/sing-box-rules-update.timer   b933b8009853 IDENTICAL
systemd/sing-box.service       e5649b1d5d86 IDENTICAL
.harness/scripts/baseline.json 9821fce69c5d IDENTICAL
$ cmp .harness/scripts/baseline.json test/head-baseline/.harness/scripts/baseline.json
cmp rc=0
```

Negative control, on a **copy** (the frozen file itself was never touched):

```
$ cp install.sh $S/install.sh.mut ; printf '\n' >> $S/install.sh.mut
$ cmp test/head-baseline/install.sh $S/install.sh.mut
cmp: EOF on test/head-baseline/install.sh after byte 29217, line 615        rc=1
```

`baseline.json` at delivery is unchanged, `"test_count": 0` — see the contract's
`## verify_all result` for why it stays there.

## 8 — AC-14 and AC-15

The two dev-map rows were checked element by element with `grep -cF` against the diff's added
lines only (so an element present elsewhere in `dev-map.md` cannot satisfy the row), plus a
negative control:

```
  I-11   CURL_OPTS_QUIET / CURL_OPTS_PROGRESS / # download flag policy / not additive /
         [ -t 2 ] / 0x0D / never inline flags                                   all present
  I-12   restricted-network-regression.sh / .harness/scripts/ / E1…E6 / RULESET_BASES /
         never imports / /dev/net/tun / single-use / --self-check / exit 3 /
         verify_all / .ps1                                                      all present
  CTRL   THIS-STRING-IS-NOT-IN-THE-ROWS                                 *** ABSENT ***
```

18/18 elements present, control absent. `git diff --stat docs/dev-map.md` = `2 ++`, 0 removals, so
C-2's "no other line changes" holds.

AC-15, by line address:

```
 2:# ===== 受限网络回归测试 · 操作指南（一次性 VM）=====
 8:#   1. 一台**一次性**、带 systemd 的 Linux 虚拟机，用完即弃；绝不要在工作机上跑。
 9:#   2. root 身份运行。          3. `sing-box` 二进制已装好（本脚本不会去装它）。
10:#   4. 有 /dev/net/tun 设备。   5. 环境变量 SB_RULES_BASE 未设置…
12:#   6. 机器上**没有**已配置的 singbox-cli：/etc/sing-box/nodes.json 不存在…
14:#   7. 本仓库已 clone 到这台虚拟机上，并从该 clone 里运行本脚本。
16-19: VM prep (apt-get, mknod /dev/net/tun, git clone)
22:#   sudo bash /root/singbox-cli/.harness/scripts/restricted-network-regression.sh --i-will-destroy-this-vm
26-28: 虚拟机是**一次性**的：脚本跑完不清理、不卸载… 不要在同一台机器上跑第二次
```

All seven preconditions, the prep block, the verbatim token and the single-use sentence are
present, in Chinese, per `.harness/rules/00-core.md`. The CJK audit that produced D6-4:

```
$ awk 'NR>=29' <artifact> | grep -nP '[\x{4E00}-\x{9FFF}\x{3000}-\x{303F}\x{FF00}-\x{FFEF}]'
line 31 : # of this file can collide with `bin/sc`'s load-bearing `失败：` grep.
```

Exactly one hit, and it is the sentence claiming there are none. `bin/sc:213` shows the grep
literal is the Chinese rendering of `"failed: {e}"`, i.e. a **runtime output** string; a comment
in a file nothing greps cannot collide with it. Documentation defect, not a functional one.

## 9 — Marker-existence audit: the "assertion that can never fire" class

An assertion whose marker string does not exist in the source that emits it is the mirror image of
a vacuous green — it can never pass, and on a VM it would be read as a product failure. Every
fixed string the artifact greps was checked against the file that produces it:

```
  [[6/7]]                         in install.sh   present (2)
  [✅ Install complete]          in install.sh   present (1)
  [❌]                           in install.sh   present (8)
  [Ruleset download failed]       in install.sh   present (2)   (step6_warn AND step6_nolog)
  [is not writable]               in install.sh   present (2)
  [/var/log/sing-box/install.log] in install.sh   present (1)   (INSTALL_LOG at :21)
  [failed: ]                      in bin/sc       present (7)
  [ruleset(s) failed to update]   in bin/sc       present (2)
  [degraded to no-splitting mode] in bin/sc       present (2)
  [OK (]                          in bin/sc       present (2)
  [THIS-MARKER-DOES-NOT-EXIST]    in install.sh   *** ABSENT ***     (control)
```

Two routing questions this raised, both answered on the code:

- The degradation warning is written by `_warn_degraded` to **stderr** (`bin/sc:1032-1046`), and
  `install.sh:590` runs `sc reload >>"$LOG_SINK" 2>&1`, so it does reach `install.log`. E3's
  `degr` grep can fire — T-02's BC-32 is reachable, not merely asserted.
- `Ruleset download failed` appears in *both* `step6_warn` (`install.sh:216`) and `step6_nolog`
  (`:236`), so E1 still gets a non-zero `pair=` under BC-10. That is correct behaviour, not a
  collision.

## 10 — The unit reproducers (`qa_units.sh`), and what they independently confirm

The script sources **lines 1-134 only** of the artifact, so `main()` never runs: no gate, no
`mktemp`, no `/etc/hosts`, no `install.sh`, no `bin/sc` import. Result: `pass=24 fail=0`.

What it confirms independently of stage 4:

- **D-3 (the suffix trap)** re-derived from `bin/sc` itself: `premise: base4 IS a byte-suffix of
  base3`; on my own synthetic 3-of-4 log, `substring form (the trap) counts = 4` but
  `shipped entry-boundary form counts = 3`, and replaying E3's conjunction gives
  `E3 with shipped matcher on a 3-of-4 log = FAIL` / `E3 with substring matcher on the same log =
  PASS`. Positive control: `entry-boundary form on a true 4-of-4 log = 4`. The shipped matcher is
  non-vacuous; the obvious one is not.
- **GC-3 (E6's `dns_refs` must be non-zero)**: `E6(cfg_degraded) -> FAIL`,
  `E6(cfg_recovered) -> PASS`, `E6(cfg_broken) -> FAIL`. F-2's unfalsifiable form would have made
  the first of those PASS.
- **E4's conjunction**: `E4(cfg_degraded) -> PASS`, `E4(cfg_recovered) -> FAIL`,
  `E4(cfg_broken) -> FAIL` — so E4 does discriminate the degraded document from the recovered one,
  which is the strongest thing available for CR-7's gap short of a VM.
- **`finish()`**: `six PASS -> exit 0`, `one BLOCKED -> exit 1`, `one FAIL -> exit 1`,
  `forced refusal -> exit 3`, `refusal prints condition lines = 6`.
- **CR-15 reproduced**: after composing real E1/E2/E5 verdicts, `unmet_all` overwrites them —
  `E1 UNMET obs=fatal:cannot_restore_/etc/hosts pair=none`. Stage 5's finding stands; I reached it
  from the code, not from their write-up.
- **`derive()` over the shipped list**: rc 0, 4 bases, 6 hosts, `BAD` empty.

Source, in full:

```bash
#!/usr/bin/env bash
S="$(dirname "$0")"; . "$S/helpers.sh"      # sed -n '1,134p' <artifact> > helpers.sh
pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then pass=$((pass+1)); printf 'ok   %-46s = %s\n' "$1" "$3"
       else fail=$((fail+1)); printf 'FAIL %-46s exp=%s got=%s\n' "$1" "$2" "$3"; fi; }
# U1 uncoverable() over '', localhost, 127.0.0.1, 10.0.0.1, a.example:8443, [2001:db8::1],
#    cdn.jsdelivr.net, ghfast.top, raw.githubusercontent.com, u@cdn.example, 1.2.3.example,
#    1cdn.example.com   -- printed as a table
# U2 host_of() on base 3 (expect ghfast.top) and on a userinfo authority
# U3 val() on defs=0;… , on defs=4;route_refs=2;dns_refs=3 , on the ?-triple
# U4 cfg_facts() over four synthetic documents, then E4's and E6's PASS conjunctions replayed
#    against each of them with the other clauses pinned true
# U5 D-3: B1..B4 taken from bin/sc; a synthetic log naming only B1,B2,B3 on four `failed: ` lines;
#    substring matcher vs `-e "failed: $b -> " -e "; $b -> "` matcher; E3's conjunction replayed
#    with both; then a true 4-of-4 log as the positive control
# U6 finish()/unmet_all()/set_c() driven with a synthetic E array in a subshell
# U7 derive() against /home/alan/Programs/singbox-cli/bin/sc
printf '=== qa_units: pass=%d fail=%d ===\n' "$pass" "$fail"; [ "$fail" -eq 0 ]
```

The elided bodies are mechanical; each `ck` line in the transcript names its expected value, so
the assertions are recoverable from the run output alone. The load-bearing one, U5:

```bash
B3='https://ghfast.top/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo'
B4='https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo'
case "$B3" in *"$B4") echo "premise: base4 IS a byte-suffix of base3" ;; esac
for f in geoip-cn geosite-cn geosite-google geosite-private; do   # a log naming only B1,B2,B3
  printf 'WARN  %s failed: %s -> t; %s -> t; %s -> t\n' "$f" "$B1" "$B2" "$B3" >>"$LOG"; done
nfail=$(grep -cF 'failed: ' "$LOG")
for b in "$B1" "$B2" "$B3" "$B4"; do
  [ "$(grep -F 'failed: ' "$LOG" | grep -cF -e "$b")" = "$nfail" ] && sub=$((sub+1))
  [ "$(grep -F 'failed: ' "$LOG" | grep -cF -e "failed: $b -> " -e "; $b -> ")" = "$nfail" ] && bnd=$((bnd+1))
done      # -> sub=4  bnd=3
```

## 11 — Stability, timing and the delivery measurement

Ten repeats of the whole `[HOST]` set, each with a fresh `TMPDIR`:

```
run  1 : 2|3|0|1|1|0|cebe74b8|1629c103|69343bf0|=== qa_units: pass=24 fail=0 ===|2f3a6061…|cwd=[] tmp=[]
        witness: MainPID=2566751 ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST
… runs 2-10 byte-identical …
10/10 runs produced an identical signature: yes
```

The signature is `rc(usage)|rc(refusal)|rc(self-check)|rc(iplit)|rc(empty)|rc(units)` followed by
md5 prefixes of the three outputs, the unit-suite tail line, the `/etc/hosts` digest and the
leftover-file listing. No flakes.

Wall clock: `--self-check` 0.010s, `--i-will-destroy-this-vm` (refusal) 0.003s.

## 12 — AC-18 witness pair, and what was left on disk

| point | MainPID | ActiveEnterTimestamp | /etc/hosts sha256 |
|---|---|---|---|
| task start (given) | 2566751 | Tue 2026-08-11 12:13:57 CST | 2f3a6061…dcdf70 |
| stage-6 start | 2566751 | Tue 2026-08-11 12:13:57 CST | 2f3a6061…dcdf70 |
| each of 10 stability runs | 2566751 | Tue 2026-08-11 12:13:57 CST | 2f3a6061…dcdf70 |
| stage-6 delivery | 2566751 | Tue 2026-08-11 12:13:57 CST | 2f3a6061…dcdf70 |

`systemctl is-active` was never invoked against this host's `sing-box`. `/etc/nsswitch.conf`
(`cf4b8650…`) and `/etc/resolv.conf` (`ebdf5602…`) were digested at stage-6 start and are
unchanged. `install.sh`, `uninstall.sh` and `/usr/local/bin/sc` were never executed; `bin/sc` was
never imported (it was only `open()`ed as text by `extract_bases.py` and read by `grep`/`sed`).

Left on disk: **nothing inside the repository**. `test/head-baseline` was deleted after the counts
were read. Files written by this stage: `06_TEST_REPORT.md`, `06_RATIONALE.md`, and one appended
row (id 2) in `.harness/operator-obligations.md`. Everything else lives under `$S` in the session
scratchpad and disappears with the session — which is precisely the T-02 / T-08 failure mode
(Q-6, Q-7), so §5, §6, §9 and §10 above carry enough of each reproducer to rebuild it.

## 13 — Judgment calls recorded under the owner's standing grant

1. **`baseline.json` not updated.** The QA role says the baseline only goes up and the test count
   should rise. AC-17 makes `baseline.json` byte-unchanged a binding criterion and Q-9 resolves
   `test_count` to stay `0` until a suite exists that a script actually runs. The contract wins;
   the baseline is held, never lowered, and R-9 owns the change.
2. **Reproducers not committed.** `02_SOLUTION_DESIGN.md`'s change ledger admits no new file, the
   frozen set names `.gitignore`, and `test/` is ignored — so there is no legal home for them in
   this task. Transcribed here instead, and the durable version is R-9's.
3. **Three `[VM]` conditions given unit-level evidence but still reported BLOCKED** (AC-8, AC-9,
   AC-11). The unit runs test the artifact's *predicates* over synthetic inputs; they say nothing
   about what a real install produces. Labelling them "partly discharged at unit level, condition
   still BLOCKED" keeps AC-19's prohibition intact — the criterion's status is BLOCKED and no PASS
   is claimed from an inspection.
4. **D6-1 filed as MINOR, not MAJOR.** It cannot be reached by the four bases at HEAD, and on a VM
   the I-9 resolver proof would fail closed to `UNMET` rather than produce a false PASS. It is
   filed because I-7 designates `uncoverable()` the single home of FR-3 coverage and BC-2, and a
   coverage predicate that says "covered" about a name it cannot sink is a latent vacuous green of
   exactly the class this task exists to prevent.
5. **The operator obligation carries the recipe.** The QA schema has no section shaped like a
   procedure, and `.harness/operator-obligations.md` is this harness's declared home for a step a
   human must perform on an unreachable host. Row 2 was appended with the next unused id; row 1
   was not renumbered or altered.
