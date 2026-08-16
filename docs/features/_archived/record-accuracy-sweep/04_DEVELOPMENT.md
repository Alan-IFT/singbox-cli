# 04 — Development · T-32 `record-accuracy-sweep`

> Contract portion. Rationale: 04_RATIONALE.md (absent = none written).

## Summary

1. Seven shipped sentences were corrected in five files and R-74's board row was amended in place;
   R-77, R-78 and R-84 were re-verified as ALREADY CLOSED and edited nowhere.
2. Zero executable lines changed: `bin/sc` parsed at HEAD and at delivery with every `str` constant
   normalised gives **identical** ASTs (15550 nodes, 113 top-level defs in the same order), and
   exactly **three** string constants differ — one English sentence at its two sites plus its `zh` twin.
3. Both filed repairs that were false of the code (R-83's "four directives", R-85's
   「没有哪台机器的退出码会变小」) were refuted from the code and not shipped; no mechanism was added,
   and the decline is recorded once in `.harness/rejected-decisions.md`.

## Files changed

| path | what changed · **the check that establishes it** | ledger id |
|---|---|---|
| `/home/alan/Programs/singbox-cli/bin/sc` | R-63: four comment lines above `parse_ss`'s last-`@` split (`:792-795`) stating that the split's product is a base64 candidate with one consumer, and that a second consumer treating it as a userinfo field falsifies `_userinfo()`'s claim. **Check (AC-1):** every occurrence of the name `userinfo` in the delivered file is `:695`-`:700` (`_userinfo`'s own def and docstring), `:710`, `:770`, `:823`, `:848` (four `_userinfo(p.netloc)` calls), `:792`/`:795` (the comment this task added), `:796` (the binding) and `:798` (`_b64dec(userinfo)`) — so the binding has exactly **one** use and that use is the base64 decode. The `except` arm at `:801` consumes `body`, not this name; `:807`'s `decoded.rsplit("@", 1)` is a different split with a different product | E-1 |
| `/home/alan/Programs/singbox-cli/bin/sc` | R-83: the AAAA PROBLEM sentence — `TRANSLATIONS` key `:312`, its `zh` value `:313`, and the identical literal at the `_doctor_ipv6()` call site `:2804-2807` (one `t()` call, its keywords on `:2808`). **Check (AC-5/AC-6/G-6):** the directive derivation in `## Condition disposition` below; the composition order `:2107-2117` (the user's document is merged **last**, on every run); and `:2798-2803`, where `rules is None` (no `dns` key, or `dns` not a dict) reaches the same PROBLEM return | E-2 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | R-79: the `backslashreplace` cost clause now states the price as **prospective** at both named sites. **Check (AC-3):** `git log -S 'backslashreplace' -- bin/sc` → `6d16caf` (T-25); `git show 6d16caf^:bin/sc` read in source order at both sites — see `## Condition disposition`, G-16 | E-3 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | R-82: the `# Clash API` file-map row states **both** clauses of `stored_delays()`'s `port` contract. **Check (AC-4):** the delivered guard is `if port is None and not is_running():` (`bin/sc:2307`), so it fires only when no port is named; the utilities row and the docstring (`:2299-2301`) now say the same two things | E-4 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | R-94(a): the `# Paths` row states **nine** repointable `Path` constants by name, asserts the function-body-only property of the **eight** that have it, names `CFG_DIR` as the exception, and explains `bin/sc`'s frozen "as the eighth". **Check (AC-13):** AST enumeration of the delivered file — see `## Condition disposition`, G-8 | E-5 |
| `/home/alan/Programs/singbox-cli/docs/dev-map.md` | R-94(d): the `check-sc-contracts.py` utilities row states **no** assertion count and points at `baseline.json`'s `test_count` and B.4's own `N defined` line. **Check (AC-14):** see G-11's B.4 derivation | E-6 |
| `/home/alan/Programs/singbox-cli/CHANGELOG.md` | R-85: the T-26 entry's exit-code lead states the derived transition set as an **equality** (`0 → 1`, `2 → 1`, `1 → 2`, nothing else) instead of a direction. **Check (AC-9/AC-10/AC-11):** the transition table in `## Condition disposition` | E-7 |
| `/home/alan/Programs/singbox-cli/.harness/rules/80-delivery-policy.md` | R-91: the durability paragraph carries **zero** line ranges into `upgrade-project.sh` and five named tokens instead. **Check (AC-12):** `grep -cF` against the delivered script — `refresh_set` 5, `known` 7, `VERIFY-SPLICE` 1, `VERIFY-HALT` 2, `"$proj_file.bak-$stamp"` 1; and `grep -oE ':[0-9]+-[0-9]+'` over the delivered paragraph returns **nothing** | E-8 |
| `/home/alan/Programs/singbox-cli/.harness/rules/50-singbox-cli.md` | R-94(b): the Test bullet states no assertion count (one physical line changed; the line below it keeps the `baseline.json` floor pointer byte-identical). R-94(c): the manual-verification preamble now names only B.3. **Check (AC-15):** the delivered run's step list — B.3 is the only SKIP | E-9 |
| `/home/alan/Programs/singbox-cli/docs/tasks.md` | *process path*: rotation per M-1 (five pointer lines), R-74 amended in place, R-94(e)'s `test_count` **18 → 19 since T-31**, and T-32's row carrying the disposition of all eleven. **Check:** `wc -l` = 293, F.5 PASS | E-10 |
| `/home/alan/Programs/singbox-cli/docs/tasks-archive.md` | *process path*: receives the rotated T-22 block and the R-78/R-79/R-82/R-83/R-84/R-85/R-91/R-94 rows, verbatim; nothing closed by moving | E-11 |
| `/home/alan/Programs/singbox-cli/.harness/rejected-decisions.md` | *process path*: one appended entry `## a-mechanism-that-keeps-shipped-prose-true` — Decision / Why (with T-27 and T-31 as precedents) / What is NOT claimed / Origin, i.e. **four** bullets where I-10 says three (reported as D-6). Its enumeration partitions **one** population and names it: eleven **rows** = nine semantic claims + R-94 (the copied count, whose **three** clauses are two deleted and one corrected to 19 in `docs/tasks.md`, still standing) + R-74 itself | E-12 |
| `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_DEVELOPMENT.md` | *process path*: this document | E-13 |
| `/home/alan/Programs/singbox-cli/docs/features/record-accuracy-sweep/04_RATIONALE.md` | *process path*: the transcripts, the two ceiling arguments and the measurement narratives | E-14 |

`docs/batches/closeout/BATCH_LOG.md` and `BATCH_PLAN.md` appear in `git diff` and were **already
modified before this stage began** (PM-owned; verified against the task-start `git status`). No file
outside this ledger was edited by stage 4.

### Changed lines per file, against the ledger and NFR-2 (G-10)

| file | ledger ceiling | measured (lines whose content differs, K-1) | verdict |
|---|---|---|---|
| `bin/sc` | E-1 ≤3 + E-2 ≤6 = 9 | **11** (E-1 4, E-2 7) | **over by 2 — reported, not crammed** |
| `docs/dev-map.md` | E-3…E-6, 1 each = 4 | **4** | within |
| `CHANGELOG.md` | E-7 ≤1 | **1** | within (PQ-8: entries are one physical line) |
| `.harness/rules/80-delivery-policy.md` | E-8 ≤4 | **8** | **over by 4 — reported, not crammed** |
| `.harness/rules/50-singbox-cli.md` | E-9 ≤2 | **2** | within |
| **total outside the process paths** | **NFR-2: 30** | **26** | **within, 4 lines of headroom** |

## verify_all result

```
baseline (measured on this tree at task start, not inherited): PASS 20  WARN 0  FAIL 0  SKIP 1  exit 0
after   (measured on the delivered tree):                      PASS 20  WARN 0  FAIL 0  SKIP 1  exit 0
delta:                                                         0 new FAIL, 0 new WARN, 0 step added/removed/renamed
B.3: SKIP before and after — the run's only SKIP, which is what rule 50's corrected preamble now names
B.4: PASS before and after; F.2 / F.5 / E.5 PASS (AC-19)
F.5: docs/tasks.md 299 -> 293 lines, cap 300
python3 -m py_compile bin/sc: exit 0 (AC-2)
bin/sc sha256 after: 0afdc3b69307defc5e49f81cb148c5124b8b469ebb6dc77fe4dc23bf2f11b669 (NFR-3: it changes; no delivered document claims otherwise)
live host before: MainPID=1776263 NRestarts=0 ActiveEnterTimestamp=Mon 2026-08-17 00:44:47 CST
live host after:  MainPID=1776263 NRestarts=0 ActiveEnterTimestamp=Mon 2026-08-17 00:44:47 CST   (identical across the run; `systemctl show` only, `is-active` never invoked, AC-21)
the witnessed instance is NOT the one this task's earlier runs recorded (MainPID 2566751, ActiveEnterTimestamp Tue 2026-08-11 12:13:57 CST) — it was replaced by something OUTSIDE this task, and this delivery states that rather than an explanation it does not have. What is measured: /etc/sing-box mtime 2026-08-11 12:13:57 and /var/lib/sing-box mtime 2026-07-30 12:59:24, both unchanged, so nothing was written under either; `uptime -s` = 2026-07-30, so the host did not reboot; NRestarts is still 0; ps says the live process started Mon 2026-08-17 00:44:46; and no stage of this task executes an `sc` or issues any unit-changing command — only reads, prose edits and verify_all
AC-21's own claim, unchanged and still true: this task disturbed nothing on the host — every run's before/after witness pair is identical
```

The full step-by-step output of the delivered run is in `04_RATIONALE.md` §1.

## Design drift

| id | design item | what was done instead | why |
|---|---|---|---|
| D-1 | E-1's budget `≤3` lines | 4 comment lines above `parse_ss`'s split | I-1 requires **two** clauses (one-consumer/base64-candidate, and what a second consumer falsifies); the three-line form put the clause boundary mid-phrase at 96 columns. G-10 governs: reported, never crammed. NFR-2's total is 26/30 |
| D-2 | E-8's budget `≤4` lines | 8 lines in rule 80's durability paragraph | The paragraph traded 4 short coordinates for I-8's **six** named mechanisms plus the sentence saying why they are tokens; the paragraph reflows, so the replacement is 8 physical lines. F-8 already recorded that this ceiling was asserted rather than measured against the paragraph's layout. G-10 governs |
| D-3 | I-1's "the decode helper on the **next** line" | the comment says "the decode below" | PQ-2 records the off-by-one: `try:` sits between the binding (`:796`) and `_b64dec(userinfo)` (`:798`). Naming the line would have shipped a false clause inside the sentence that exists to stop false clauses |
| D-4 | V-8's population ("the two changed probes") and its one-directional observable | the derivation covers **all three** probes `CHANGELOG.md:29` names, compared in both directions | Bound by G-3 and G-2; F-3/F-13 record that AC-9 governs and V-8 does not. `02` was not re-emitted |
| D-5 | K-3's "grep that the new English string occurs exactly twice" | an `ast.parse` identity check (never an import) | F-4/G-5: the call-site literal is implicitly concatenated over three physical lines, so a whole-sentence grep returns **1**. The method is stated under G-5 below |
| D-6 | I-10's "the file's existing **three-bullet** shape" (Decision / Why / Origin) | **four** bullets — the added one is **What is NOT claimed** | G-12 makes it binding that the entry state what the decline does *not* claim (B.4's sentence assertions pin the English key spelling, B.2 pins `install.sh`'s key parity; the **truth** of a sentence about code has no owner). That clause fits none of the three named bullets, and folding it into *Why* would bury a boundary the gate made binding inside the argument it bounds. Reported per G-10; the bullet stays |

No other deviation. No behavioural change, no statement added/removed/reordered, no new file outside
the ledger, no check/script/template/`verify_all` step added.

## Condition disposition

| gate condition | disposition | evidence |
|---|---|---|
| G-2 | DISCHARGED | The delivered lead states the transition set as an **equality** — 「能产生的退出码变化**恰好是下面三种，没有第四种**」 — and this document states the equality too: the delivered set **equals** the derived set `{0 → 1, 2 → 1, 1 → 2}`; every derived transition appears in the lead and the lead states no transition the table does not derive. Table below |
| G-3 | DISCHARGED | The derivation covers **all three** rows `CHANGELOG.md:29` names. The DNS-lookup probe is included as an unchanged-class probe with the reason stated. Table below |
| G-4 | DISCHARGED | The AC-10 host is delivered with a concrete witness whose displacement is **override-caused**, so `config.json` is byte-for-byte what `sc` generated and the drift row is never PROBLEM. Witness below |
| G-5 | DISCHARGED | Method written below |
| G-6 | DISCHARGED | The delivered sentence says config.json "does not carry that decision **at the head of** its `dns.rules`", which is a non-existence claim and therefore true of the branch where there is no `dns.rules` array at all: `bin/sc:2798` binds `rules = dns.get("rules") if isinstance(dns, dict) else None`, `:2800`'s `isinstance(rules, list)` is then false, and `:2802` returns the same PROBLEM row. The clause presupposes no first entry, unlike the sentence it replaces ("as the first dns.rules entry") |
| G-7 | NOT STAGE 4 — noted | Gate ruling for stage 6: the delivered sentence names **no** directive (K-6 honoured; the derivation lives here instead) |
| G-8 | DISCHARGED | Both numbers with their properties, in one sentence. Enumeration below |
| G-8 (2nd owner) | STAGE 6 | The delivered `# Paths` row is the artifact to read |
| G-9 | DISCHARGED | Read in **both** directions by `ast.parse`, not by B.4: EN placeholders `['{decision}', '{override}']`, `zh` placeholders `['{decision}', '{override}']`, sets **equal**. B.4's PASS is recorded as evidence of the **subset** direction only (`check-sc-contracts.py:455-475` computes `got ⊆ want`, so a `zh` entry that dropped `{override}` would have passed the run) |
| G-10 | DISCHARGED | Two ceilings were exceeded and are **reported** as D-1 and D-2 with per-file counts above; nothing was crammed; NFR-2's 30 holds at 26 |
| G-11 | DISCHARGED | Own post-change run recorded above and in full in `04_RATIONALE.md` §1, compared step-by-step against the measured task-start baseline. No step's status was inherited: B.3's SKIP, B.5's PASS and F.4's PASS were each re-read from this run |
| G-12 | DISCHARGED | The amended R-74 row states that what has no owner is the **truth** of a sentence about code, and names what *is* owned — B.4's sentence assertions pin the English key spelling of every sentence they name, B.2 pins `install.sh`'s key parity. It states no guarantee about future sentences |
| G-13 | DISCHARGED | All eleven dispositions are in T-32's row on `docs/tasks.md` itself, and each of the five pointer lines names the rows it moved, where they went and their disposition. Nothing is reachable only from the archive |
| G-14 | PM / STAGE 7 | `.harness/insight-index.md:10`'s four ranges into `upgrade-project.sh` — **not repaired here**; travels as a filed-row candidate. Re-verified untouched by this task |
| G-15 | PM / STAGE 7 | RS-1's AC-13 wording imprecision travels as a filed-row candidate; G-8's reading is what this task delivered |
| G-16 | DISCHARGED — **no site BLOCKED** | Both sites stay named in the delivered clause and both were settled by `git show` plus reading the retrieved text. Trace below |

### G-5 — the key/call-site identity method (survives the implicit concatenation)

`ast.parse` on `bin/sc` (**parsing only — the module is never imported or executed**, so NFR-4 is
untouched) folds implicit concatenation into a single `Constant`, which is exactly what a
whole-sentence grep cannot do. The method, and its result on the delivered file:

| step | result |
|---|---|
| every `str` `Constant` in the module containing `at the head of its dns.rules` | **2** — `:312` (len 274) and `:2804` (len 274) |
| distinct values among them | **1** — so the `TRANSLATIONS` key and the call-site literal are byte-identical, which is what K-3 wanted and what the grep cannot show |
| the `TRANSLATIONS` entry's key, and the `t(...)` first argument inside `_doctor_ipv6` | both found; `key == call-site literal` → **True** |
| control: `grep -c` for the whole English sentence | **1**, not 2 — F-4 reproduced on the delivered file, which is why this method replaces K-3's |

The same parse establishes BC-5/K-4 at this site: neither string carries `失败：` or `failed: `.

### AC-8 / PQ-1 — the directive derivation (the filed "four" is **three**)

Five directives (`bin/sc:1277`). "Reaches element 0" = can change `dns.rules[0]`.

| directive | what `_apply_directive` does | reaches element 0? |
|---|---|---|
| `$prepend` | `return copy.deepcopy(payload) + current` (`:1457`) | **yes** — the payload's first element becomes index 0 |
| `$replace` | `return copy.deepcopy(payload)` (`:1454-1455`) | **yes** — the whole array, index 0 included, is the payload |
| `$before` | insert at `i = _anchor_index(...)` (`:1447`), `current[:i] + values + current[i:]` (`:1450`) | **yes, only when the anchor resolves to element 0** — then `i == 0` and the insert lands at index 0 |
| `$after` | same insert after `i += 1` (`:1449`) | **no** — `_anchor_index` returns a matched index `hits[0] ≥ 0` (`:1430`), so the insert lands at `≥ 1` |
| `$append` | `return current + copy.deepcopy(payload)` (`:1458`) | **no** — index 0 is untouched while `current` is non-empty, and it always is: `generate_config` refuses a non-list `dns.rules` (`:2127-2130`) and `sc`'s own overlays populate it (`_dns_overlay`'s single-element `$prepend`, `:1786`) |

**Verdict on the filed characterisation: refuted.** Three, not four. The filed second clause — "the
advice is ineffective only for `$replace`" — is refuted too: `generate_config` composes `sc`'s own
overlays and then merges the user's document **last, on every run** (`:2107` then `:2117`), so
regeneration reproduces **every** override-caused displacement, not one of them. The delivered
sentence therefore offers `sc reload` only for a stale or hand-edited document and, for the override
cause, says regeneration reproduces it and names the override as what to change. Per K-6 the shipped
sentence names **no** directive — this table is where the enumeration lives (G-7).

### AC-9 / AC-10 / G-2 / G-3 — the exit-code transition derivation

Mapping (delivered, `bin/sc:2550-2554`): classes are ordered `OK(0) < UNKNOWN(1) < PROBLEM(2)`;
`DOCTOR_EXIT = {OK: 0, UNKNOWN: 2, PROBLEM: 1}`. `cmd_doctor` takes `worst = max(worst, cls)` over
every row (`:3110`) and exits `DOCTOR_EXIT[worst]` (`:3111`). **The mapping is a label set, not a
magnitude** — which is why "direction" is not a property this exit code has, and why both the shipped
「只有一个方向」 and the filed 「没有哪台机器的退出码会变小」 are false.

Population = **every** row `CHANGELOG.md:29` names as changed (G-3), from `git show d849234{,^}:bin/sc`:

| probe T-26 changed | classes before | classes after | did a class move? |
|---|---|---|---|
| IPv6 (AAAA) | `_aaaa_rule(suppress) in rules` → OK on **membership anywhere**; else PROBLEM; UNKNOWN on unreadable/undecidable | `rules[:len(prepend)] == prepend` → OK only at the **head** | **yes** — a document whose AAAA rule is present but **not first** moves **OK → PROBLEM**. Nothing else moved: an absent rule was PROBLEM both ways, and `rules is None` reaches PROBLEM both ways |
| node delays | `if not is_running(): return {}, None` → on an init-less host no request was issued, so the row was PROBLEM (`0/N`) | `if port is None and not is_running():` → a named port bypasses the guard, so the answer is read | **yes** — an init-less host whose Clash API answers with ≥1 stored delay moves **PROBLEM → OK** |
| DNS 解析 (DNS lookup) | PROBLEM / OK / PROBLEM over the three branches | PROBLEM / OK / PROBLEM — the probe is byte-for-byte unchanged; only the three sentences changed | **no** — so it contributes no transition. This is the row `02`'s V-8 omitted |

Derived transitions (a host's exit is `DOCTOR_EXIT[max(classes)]`):

| # | change | before → after | reachable? |
|---|---|---|---|
| 1 | AAAA OK→PROBLEM on a host whose every other row is OK | `0 → 1` | yes — the case T-26 set out to correct |
| 2 | AAAA OK→PROBLEM on a host with ≥1 UNKNOWN row and no PROBLEM row | `2 → 1` | **yes — AC-10's host; witness below.** The exit code moves **downward** |
| 3 | AAAA OK→PROBLEM on a host that already carries a PROBLEM row | `1 → 1` | reachable, **not a transition** |
| 4 | node delays PROBLEM→OK on an init-less host with no other PROBLEM row | `1 → 2` | yes — service and boot autostart are UNKNOWN there (`_doctor_service` returns two UNKNOWN rows when neither init system is present), so the new worst is UNKNOWN |
| 5 | node delays PROBLEM→OK where an init system reports not-running | `1 → 1` | reachable, **not a transition** — `_doctor_service` makes the service row PROBLEM on that host, so PROBLEM still wins |
| 6 | node delays PROBLEM→OK ending at worst = OK | — | **unreachable**: the change requires `is_running()` false, and every host where that is true carries either two UNKNOWN service rows (no init system) or a PROBLEM service row |
| 7 | both changes on one host | `1 → 1` | reachable, **not a transition** |

**Derived set = `{0 → 1, 2 → 1, 1 → 2}`, and the delivered lead's set is equal to it** — three
transitions, each stated with its host class, plus the explicit "no fourth", plus the unchanged case,
plus the statement that the DNS row moved no class.

**AC-10 / G-4 — the witness, named:** a host that upgraded from a build older than the drift record,
so `/etc/sing-box/.config.sha256` is absent, **and** whose `override.json` puts a rule of its own at
the head of `dns.rules`. Its `config.json` is byte-for-byte what `sc` generated from that override,
so the AAAA rule sits at index 1 — member, not head.
* Rows **before** T-26: `config drift` **UNKNOWN** (`_drift_state()` returns `None` for "no record",
  `bin/sc:2010-2036`, and the row renders it UNKNOWN at `:2710-2713`), AAAA **OK** (membership), every
  other row OK. `worst = UNKNOWN` → **exit 2**.
* Rows **after**: AAAA **PROBLEM** (head test), everything else unchanged. `worst = PROBLEM` → **exit 1**.
* **Pair: 2 → 1, reachable.**
* G-4's hazard is avoided by construction: the displacement is **override-caused**, so nothing was
  hand-edited and the drift row cannot be PROBLEM (`bin/sc:2706-2715` reaches PROBLEM only for
  `_drift_state()` **True**). The drift row existed before T-26 — `git show d849234^:bin/sc` carries
  the `no record of what sc last generated` key and its call site (2 occurrences) — so the "before"
  half of the pair is a property of the pre-T-26 build, not of today's.
* A second, record-present variant works identically (drift **OK**, the UNKNOWN supplied by another
  row such as an absent `sing-box` binary), and is not the delivered witness.

### G-8 / AC-13 — the `Path` constant enumeration (AST over the delivered `bin/sc`)

Nine `Path`-valued constants in `# Paths`: `CFG_DIR` `:23`, `CFG_PATH` `:24`, `NODES_PATH` `:25`,
`SETTINGS_PATH` `:26`, `RULES_DIR` `:27`, `OVERRIDE_PATH` `:32`, `STATE_PATH` `:38`, `LIB_DIR` `:43`,
`IF_INET6_PATH` `:64`. (`PERIODIC_DIRS` `:79` is a dict of `Path`s, not a `Path` constant — the same
exclusion the loader recipe already records.) Walking the module and collecting every `Name` load
**outside** any `FunctionDef` / `Lambda` / `ClassDef` yields exactly six hits, all of one constant:

```
module-level loads: CFG_DIR at :24, :25, :26, :27, :32, :38   (6, deriving its six siblings)
the other eight constants: 0 module-level loads each
```

So **nine** is the repointable set, the function-body-only property holds of **eight**, and `CFG_DIR`
is the exception — which is what the delivered sentence says, and why repointing `CFG_DIR` alone
moves nothing. The count-only repair G-8 forbids (eight → nine, property left universal) was not made.

### G-16 / AC-3 — both FR-4 sites, settled by retrieval and reading. **Neither is BLOCKED**

`git log -S 'backslashreplace' -- bin/sc` → **`6d16caf`** (T-25); the pre-`backslashreplace` build is
`git show 6d16caf^:bin/sc`, read as text. **No `sc` — historical, current or installed — was executed
as a program at any point in this stage** (`bin/sc:124-126` re-execs a hard-coded
`/usr/local/bin/sc` under `sudo` at import, so the act has no containment).

| site named by the clause | what the retrieved text shows, in source order | outcome |
|---|---|---|
| the `SB_RULES_BASE` / `--mirror` base `_ruleset_bases()` returns, printed by `cmd_update_rules`'s cause list | in the retrieved build `cmd_update_rules` prints `prefix = f"  ↓ {fname} ... "` with `print(prefix, end="", flush=True)` **before** the base loop begins — and the cause list is printed inside that same per-file iteration, at `print(t("failed: {e}", …))` and on the success line. `↓` (U+2193) is `sc`-authored and unencodable under an ASCII stdout, so the run ends there, before any base string reaches a printed line | **SETTLED — the loss was never available** |
| the `{path}` rows `_doctor_permissions()` builds from `CFG_DIR.iterdir()` | a `{path}` detail row exists only on the `wide` or `links` branch, and each of those branches emits its summary row **first** — `"{n} path(s) grant access to group or other — run the command shown for each"` / `"{n} path(s) could not be judged — see below"`, both carrying an em dash. On the clean-host branch the probe returns one row naming **no** path at all. The detail strings themselves carry an em dash beside `{path}`, so even reached in isolation the encode raises before the line is written | **SETTLED — the loss was never available** |

Under `LC_ALL=C PYTHONUTF8=0` the stream's handler is `surrogateescape`, so a `\udcXX` from an
undecodable byte *is* encodable there while an `sc`-authored `↓` or `—` is not — which is exactly why
the earlier write is what ends the run. That premise is the one the existing dev-map clause already
asserts and T-25 measured; this stage established the **source order** by reading, and marks the
premise as inherited rather than re-measured (NFR-5).

### BC-4 / AC-20 — the both-languages check, and the README search that found nothing

* The English key and its `zh` entry changed in the same edit, with the placeholder set unchanged and
  equal in both directions (G-9). No other user-facing sentence changed.
* No line carrying `失败：` or `failed: ` was changed: across all ten files in `git diff`, the count of
  added-or-removed lines carrying either literal is **0** (`bin/sc` itself carries seven such lines,
  none of them in this diff). R-75's diagnostic grep is unchanged, so BC-5 needs no statement.
* README search, recorded because it establishes an absence: `grep -n -e 'does not carry this
  decision' -e 'first dns.rules entry' -e 'dns.rules 第一条' README.md README.zh-CN.md` → **0 hits**
  (exit 1). Widening to the subject terms (`grep -in -e AAAA -e 'dns.rules'`) returns only the
  `sc ipv6` usage block (`:116-118`, `:122`), the doctor row-4 cell (`:263`), the exit-code table
  (`:279-280`) and the override recipe (`:398`, `:402`). Row 4's cell describes **what the row
  checks** — "whether the `config.json` on disk carries that decision as the first `dns.rules` entry"
  — which this task does not change; neither README carries the PROBLEM sentence or its advice, so
  there is nothing to mirror.

### FR-2 / AC-16 / K-15 — the three ALREADY CLOSED rows, edited nowhere

`git diff -- docs/dev-map.md` produces four hunks, at lines **33, 42, 81 and 87**. The fenced loader
recipe block and its four trailing clauses, and `docs/dev-map.md:76`'s frozen past-tense
`18 defined … T-30` measurement, are outside every hunk. Discharging task established by `git log -S`
over each clause's own text, not inferred — all three land in **`2ea5e16`** (T-28,
`test(sc): ship the committed bin/sc contract suite`):

| row | the clause that discharges it | true of the delivered `bin/sc`? |
|---|---|---|
| R-77 | the recipe reads its source with an explicit codec: `open("bin/sc", encoding="utf-8").read()` inside the fenced block | yes — the block is unchanged and is what B.4 runs |
| R-78 | the clause naming the failure signature: a context skipping the recipe gets an argparse usage error about its own argv at **exit 2** from the re-exec'd `/usr/local/bin/sc` | yes — `bin/sc:124-126` re-execs the hard-coded installed path with `sys.argv[1:]` |
| R-84 | the clause naming the read-only command pair | yes — `main()`'s arm is `if args.cmd in ("doctor", "config"):` at `bin/sc:3843` |

R-109 lives inside that same frozen block and is untouched, so this sweep neither collides with it
nor duplicates it (out-of-scope 3, stated explicitly as FR-2 requires).

## Open issues for review

1. **Schema-gap row, reported rather than designed around** (rule 70's `## Stage-doc boundary rule`).
   `02`'s I-11 and gate conditions G-2…G-5, G-8 and G-16 require **tables** in `04_DEVELOPMENT.md`
   that fit no declared section shape of this stage doc. Destination given: they are placed **inside**
   `## Condition disposition`, under the condition rows that cite them, because that is the section
   whose declared subject they are evidence for. No new section and no third document was created.
2. Two ledger ceilings were exceeded (D-1, D-2). They are reported per G-10; NFR-2's binding 30 holds
   at 26. If stage 5 prefers the ceilings to the prose, the four-line comment and the eight-line
   paragraph are the two places to cut, and both cuts cost a clause the interface asked for.
3. `docs/tasks.md`'s T-32 row is written in the delivered "completed row" shape the ledger (E-10)
   specifies, dated 2026-08-17. Its outcome text is stage 4's; the **PM owns its final wording at
   delivery**, and the Active-tasks table was left to the PM as well.
4. AC-14's third leg — B.4's own `N defined` line — is established by **reading**, not by a second
   run, so that no `bin/sc` import happens outside `verify_all` B.4 (NFR-4 / BC-9). The chain:
   `len(TESTS)` is 19 by enumeration (`check-sc-contracts.py:846-864`); B.4 invokes the suite with no
   NAME argument (`verify_all.sh:103`), so `selected = list(TESTS)` (`:916`) and `run = 19`;
   `_execute` returns non-zero unless `passed == len(selected)` (`:888`) and B.4 FAILs on non-zero
   (`verify_all.sh:105`); B.4 PASSed, so the line it captured reads `summary: 19 defined, 19 run, 19
   passed`. `baseline.json:4` is `test_count: 19`. All three agree. **What the deletion covers, stated
   exactly:** K-8 scopes it to `docs/dev-map.md`'s utilities row and `.harness/rules/50-singbox-cli.md`'s
   Test bullet, and the count is gone from both. `docs/tasks.md` **retains** one — authorised by E-10 /
   R-94(e) and stating it correctly, `:230-231` (`test_count` is **19** since T-31) and T-32's own board
   row at `:16`. So the true statement is *the count is deleted from the two documents K-8 names, and
   the one copy that remains outside `baseline.json` — in `docs/tasks.md` — says 19, which is right*.
   It is **not** I-6's and V-12's absolute "no delivered document outside `baseline.json` states a
   count": that phrasing is false of a **compliant** tree, so AC-14 must be read against the tree
   (19 / 19 / 19, plus a correct `docs/tasks.md` copy) and not against V-12's wording. Recorded rather
   than repaired because it is upstream — `02`'s I-6 invariant and E-10's authorised `tasks.md` count
   clause are in tension, and `02` owns that tension.
5. `.harness/scripts/guard-rm.sh` refused a `python3 - <<EOF` heredoc with *could not parse nested
   pwsh command safely* — **R-86's sixteenth instance**. The bypass was **not** set; the work was done
   by writing the script to a scratch file and running it. Recorded, not fixed (out-of-scope 2).
6. `.harness/scripts/doc-query.js` does not exist on this host, so the insight-index query the
   developer contract mandates could not be run as written; `.harness/insight-index.md` was read
   directly instead (30 lines, at its cap). Same class as R-88 — an absent plugin artifact, handled
   fail-open and recorded.
7. **The live host's `sing-box` instance changed between this task's own runs, and no stage of this
   task can have caused it.** The witness recorded above is `MainPID` 1776263 / `ActiveEnterTimestamp`
   Mon 2026-08-17 00:44:47; the earlier runs recorded 2566751 / Tue 2026-08-11 12:13:57. `/etc/sing-box`
   and `/var/lib/sing-box` mtimes are unchanged, the host did not reboot (`uptime -s` = 2026-07-30) and
   `NRestarts` is still 0, so a unit was restarted with no config write, by something outside this
   pipeline. Consequence for **stage 6**: AC-21's host evidence must be **re-taken**, never inherited
   from this document — an inherited host witness is the same defect class this task exists to stop.
8. Travelling to the PM, unrepaired and re-verified untouched: **G-14** (`.harness/insight-index.md:10`
   carries four line ranges into `upgrade-project.sh` — R-91's own hazard class, in the file every
   task start reads) and **G-15** (RS-1's AC-13 wording). Also unrepaired by contract: R-98, R-106,
   R-86, R-89/R-90/R-92, R-107, R-109, R-110.

## Dev-map updates

1. No project structure changed — no file, module or folder was added, moved or removed — so
   `docs/dev-map.md`'s folder layout and section lists needed no update on that account.
2. `docs/dev-map.md` was edited four times as *content* repairs, not structure: the `# Paths` row
   (nine constants, the eight-with-the-property, `CFG_DIR` as the exception), the `# Clash API`
   file-map row (both `port` clauses), the `backslashreplace` cost clause (the price is prospective at
   both named sites) and the `check-sc-contracts.py` utilities row (no assertion count; the floor is
   its one home).

## Insight to surface

- `_doctor_permissions()` cannot emit a `{path}` row without first emitting a summary row that carries an em dash, and `cmd_update_rules` prints its `↓` prefix before contacting any base — so on a pre-T-25 build under `LC_ALL=C` **both** of the two sites the `backslashreplace` cost clause names were unreachable, which makes the whole class of "what this argument costs" claims worth testing for reachability before they are written down · evidence: `git show 6d16caf^:bin/sc`, `cmd_update_rules`'s `print(prefix, end="", flush=True)` and `_doctor_permissions()`'s `wide`/`links` summary rows
- `sc doctor`'s `DOCTOR_EXIT = {OK: 0, UNKNOWN: 2, PROBLEM: 1}` is a **label set, not a scale**, so no claim of the form "the exit code only moves one way" or "no host's exit code gets smaller" can be true of it — T-26's own changelog shipped one such claim and the row filed against it proposed another, and the host that refutes both (≥1 UNKNOWN row, no PROBLEM row, an override-displaced `dns.rules` head, moving **2 → 1**) is an ordinary upgraded machine · evidence: `bin/sc:2550-2554` with `worst = max(...)` at `:3110-3111`
- A whole-sentence `grep` cannot establish that a `TRANSLATIONS` key and its call-site literal are the same string, because the call site is implicitly concatenated across physical lines and returns **1** hit, not 2 — `ast.parse` folds the concatenation and answers the real question (2 constants, 1 distinct value) without importing the module, which is the only method available under a no-import rule · evidence: `bin/sc:312` and `:2804-2807`, `check-sc-contracts.py:455-475` for the subset-only zh assertion

## Verdict

READY FOR REVIEW
