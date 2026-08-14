> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1. Undeclared-growth arithmetic for the rework round

I hold no shell. Round 1's chain closed at **+288 net** against a declared `+320/−32`, measured
anchor-by-anchor against the design's own pre-edit citations. For round 2 the same method is
applied one level up: every **round-1 shipped** line number (recorded in round 1's own document)
is re-located in the current file, and each anchor's shift must equal the sum of the additions
above it and nothing else.

| anchor | round 1 | round 2 | Δ | what must be above it |
|---|---|---|---|---|
| `RULESET_STALE_DAYS = 60` | `:102` | `:102` | 0 | — |
| `EGRESS_HOST = "api.ipify.org"` | `:454` | `:454` | 0 | the replaced key pair is **2 lines for 2 lines** — `TRANSLATIONS` is line-neutral |
| `urlopen("https://" + EGRESS_HOST, timeout=8)` | `:465` | `:466` | +1 | CR-7 docstring **+1** |
| `def _aaaa_rule(suppress)` | `:1668` | `:1670` | +2 | + CR-4 docstring **+1** |
| `def _dns_overlay()` | `:1682` | `:1684` | +2 | zero net in between ✔ |
| `_aaaa_rule(ipv6_decision()[1])` | `:1699` | `:1701` | +2 | ✔ |
| `# doctor` block header | `:2380` | `:2382` | +2 | ✔ (900 lines of zero net) |
| `DOCTOR_EXIT` | `:2396` | `:2398` | +2 | ✔ |
| `def _doctor_rulesets()` | `:2487` | `:2489` | +2 | ✔ |
| `def _doctor_config()` | `:2531` | `:2533` | +2 | ✔ |
| `def _doctor_ipv6()` | `:2598` | `:2600` | +2 | ✔ |
| `def _doctor_clash()` | `:2710` | `:2712` | +2 | ✔ |
| the `current=` keyword argument | `:2769` | `:2772` | +3 | + CR-5's wrapped argument **+1** |
| `def _doctor_permissions()` | `:2808` | `:2811` | +3 | ✔ |
| `CFG_DIR.stat().st_mode` | `:2828` | `:2831` | +3 | ✔ |
| `entry.lstat().st_mode` | `:2850` | `:2853` | +3 | ✔ |
| the `settings.json` exclusion | `:2861` | `:2864` | +3 | ✔ |
| the clean-host `return` | `:2877` | `:2883` | +6 | + the CR-1 call-site comment **+3** |
| `DOCTOR_SECTIONS` | `:2890` | `:2896` | +6 | ✔ |
| `if args.cmd in ("doctor", "config")` | `:3640` | `:3646` | +6 | ✔ (700 lines of zero net) |

**Closure.** 1 + 1 + 1 + 3 = **+6**, so 288 + 6 = **+294 net**, which is exactly the declared
`+331/−37`. Every anchor's shift is the running sum and never one more, so no line entered the
diff anywhere outside the four named edits.

**Add/delete cross-check, independent of the shifts.** Round 1 declared `+320/−32`; round 2
declares `+331/−37`, i.e. **+11 added, +5 deleted**. The four edits decompose as: key pair 2/2,
clean-host comment 3/0, and three rewrites (`ipv6_decision` docstring, `_egress_ip` docstring,
the `_plain()` wrap) whose added lines must total 6 against 3 deleted. 2+3+6 = 11 ✔ and
2+0+3 = 5 ✔. A single further net-zero edit anywhere in the file would have read `+332/−38`.
This is the property that catches a rework round quietly re-touching a frozen function.

**Inventory re-enumerated rather than assumed.** Module-level constants across the whole file:
the only ones this task adds are still `RULESET_STALE_DAYS` (`:102`) and `EGRESS_HOST` (`:454`).
Module-level functions: the only one this task adds is still `_aaaa_rule()` (`:1670`);
`_age_seconds()` is still unwritten; the doctor block still holds exactly nine probes plus
`_doctor_run()` and `_doctor_print()`. No cap and no flag exists anywhere.

**One honest limit (RES-11).** The `--numstat` figures are the developer's declaration. What I
verified first-hand is the shipped line geometry, which is the stronger of the two for this
purpose: it constrains *where* the +6 is, not merely how much there is. AC-S7 re-reads the
numstat at delivery.

## 2. Is CR-1 closed at the code, or only in the document?

Three questions, all answered at the file.

**(a) Is the sentence exactly as wide as the check, in both languages?** The check is two
predicates: the directory is offending on `dir_mode & 0o022` (`:2841`), and an entry is offending
on `stat.S_ISREG(mode) and entry.name != "settings.json" and mode & 0o077` (`:2864`). The shipped
sentence is `"no credential file grants access to group or other, and the directory is not group-
or other-writable"` (`:335`) / 「没有凭据文件对同组或其他用户开放，目录本身也不可被同组或其他用户写入」
(`:336`). Both halves carry no placeholder, so parity is trivially exact; the zh half asserts the
same two clauses in the same order and contains no `失败`. The four prose surfaces move with it:
`README.md:268` ("any **credential** file directly inside `/etc/sing-box` … (`settings.json` is
excluded — it carries no credential)"), the zh mirror at the same line, and both exit-status
tables at `:279` ("a credential file or a configuration directory open to group or other" /
「凭据文件或配置目录对同组/其他用户开放」).

**(b) Was the *check* narrowed instead?** No — and this was the repair that would have been
wrong. Both predicates are byte-identical to round 1 at the same tokens, and their shift is
exactly the +3 the arithmetic in §1 predicts from edits *above* them. Nothing was added to the
exclusion list, no filename pattern appeared, and the `wide` / `links` counters and their
precedence (`wide` outranks `links`, `:2869-2876`) are unchanged. The clean-host `return` is
still reachable only when `wide == 0 and links == 0`, so the narrowed string is printed only in
the state it describes.

**(c) Is the record now true?** `04_DEVELOPMENT.md`'s D-5 states the drift, its cause
(`save_settings()` uses `write_text()`, so `settings.json` is 0644 on a default install), the
rule it obeys ("narrowing the sentence, never the check"), and the control (V-9.5, a
default-install fixture whose capture must **not** contain `no file grants access`). That is the
shape a drift row is supposed to have.

## 3. The R-22 re-interrogation of the one row that changed

The question this task exists to ask: *is there a host where something is wrong and this row
still reads `[OK]`?*

- **A credential file at a wide mode.** `config.json` at 0644, `nodes.json` at 0640, a hand-made
  `config.json.bak-2026-08-01` at 0644 — each is a regular file, is not named `settings.json`,
  and trips `mode & 0o077`, so `wide` increments and the row is PROBLEM with the path, the
  `%03o` mode and `chmod 600 <path>` on the detail line. The narrowing cannot reach this branch:
  it edited a string on the `else`.
- **The directory itself.** 0777 or 0775 trips `dir_mode & 0o022` → PROBLEM. Unchanged.
- **Is the OK sentence now so narrow it stops meaning anything?** No. It still makes two
  load-bearing assertions — every credential document directly inside the directory is 0600 or
  narrower (which is precisely R-10's instance class, hand-made backups included, with no filename
  pattern anywhere), and the directory does not grant write to group or other (R-11's
  rename-between-`fchmod`-and-replace window). The only file it stops speaking for is the single
  document the project deliberately writes 0644 and that carries no credential.
- **The residual in the other direction (CR-11).** The check is now slightly *wider* than the
  sentence: a stray non-credential file — `notes.txt` at 0644 — is still reported PROBLEM while
  the clean sentence promises only about credential files. An under-promise can produce no false
  `[OK]`, which is the direction this task wants; closing it would mean spelling the exclusion
  inside the row on a healthy host, and BC-20 ("exactly one OK permission row, naming no path")
  plus NFR-3 forbid that. Recorded, not actioned.
- **Unchanged and still open:** a group-writable `rules/` sub-directory is never judged (RES-6),
  because BC-19 forbids descending.

## 4. Was `CHANGELOG.md:7` the same finding or a widened diff?

**The same finding.** Three tests, all passed. *Same defect*: the clause carried the identical
universal ("对同组或其他用户开放的文件") about the identical row whose check excludes
`settings.json` by name. *Same repair*: one word plus the exclusion named out loud, no new claim
introduced. *No diff growth at all*: the entry is a single markdown line added under
`## [Unreleased]`, so its numstat is `+1/−0` whether or not the text was amended — the diff is
byte-for-byte the same size as it would have been had the clause been left false. Round 1's
scope sentence named "one translation-key pair plus two README clauses" as the size of the fix,
not as a fence around which surfaces may state the truth; leaving one of four user-facing
surfaces asserting the refuted universal would have re-filed the same MAJOR at stage 7. The two
README exit-status clauses at `:279` fall under the same judgement.

## 5. The other four closures, checked at the code rather than in the record

- **CR-4.** `bin/sc:1636-1639` now reads "Three callers — _dns_overlay(), cmd_ipv6() and
  `sc doctor`'s AAAA row"; `docs/dev-map.md:57` reads the same with `_doctor_ipv6()` and "once
  per run" spelled out. The claim that the **body** is byte-unchanged (out-of-scope 9) is
  supported two ways: the body still spans 18 lines and starts exactly where §1's chain predicts,
  and §1's add/delete cross-check leaves no budget for a net-zero line swap inside it. Without a
  shell that is the strongest available check, and it is a real one.
- **CR-5.** `:2772` renders `current=_plain(current or t("(none)"))`. Two things had to be true
  and are: `stored_delays()` yields `current` as `None` or a **non-empty `str`** (`:2181`
  `isinstance(now, str) and now`), so `_plain()` can never be handed a non-string and the wrap
  introduces no new failure mode; and `t("(none)")` is a **pre-existing** key (`:150`, with its
  zh entry 「（无）」) already used at `:2262`, `:2368` and `:2709`, so the fallback path's text is
  byte-identical to what round 1 shipped — the fix changed the escaping, not the row. With this,
  `_plain()`'s docstring invariant (`:2406-2408`, unamended) is true again of the whole doctor
  block: `{e}` values, filesystem-sourced paths, the checker's output (plained wholesale in
  `_doctor_run()`, `:2456`) and now the API-sourced tag. Amending the docstring instead — the
  alternative round 1 offered — would have been the weaker repair, and the developer took the
  stronger one.
- **CR-6.** GC-10's disposition now states what shipped, in the code's own terms: clause (c) says
  the tag **is** `_plain()`ed, clause (d) says the mode strings are **not** and are met by
  construction because `"%03o" % (st_mode & 0o777)` formats an `int` this code owns and cannot
  carry CR or ESC, and it says out loud that a `_plain()` wrapper there would be a provable no-op
  a future reader has to re-derive. That is the right call and the right record: the defect was
  never the missing call, it was a discharge asserting a call that did not exist.
- **CR-7.** `:460-462` sources the literal to `EGRESS_HOST` and names its other consumer, and
  keeps the still-true half ("the 8 s socket timeout lives here and nowhere else" — `:466` is the
  only `timeout=8` in the file).

## 6. Nothing outside the round's scope moved

Re-checked directly, not inherited: `DOCTOR_SECTIONS` has **nine** entries in the declared order
with the two new ones at positions 4 and 9 (`:2896-2906`); `DOCTOR_EXIT` is `{OK: 0, UNKNOWN: 2,
PROBLEM: 1}` (`:2398`) and `DOCTOR_MARK` and the `"[" + mark + "] " + label + ": "` grammar in
`_doctor_print()` (`:2909-2919`) are untouched; the three socket timeouts are `timeout=8`
(`:466`), `timeout=30` (`:1121`) and `timeout=3` (`:2122`); the read-only dispatch arm is still
the positive enumeration `if args.cmd in ("doctor", "config"):` (`:3646`); exactly two mode reads
exist (`:2831`, `:2853`) and the file's only other `os.stat` is `_load_override()`'s pre-existing
one (`:1447`); there is still **one** Clash exception envelope and no `try` around either
`clash_api()` call in `_doctor_clash()`; `stored_delays()`, `_drift_state()`, `_age_text()` and
`ruleset_state()` are unmodified; and `TRANSLATIONS` is line-neutral across the rework, which is
what holds the key count at 28 added / 3 deleted without a shell.

## 7. Why CR-10 is MINOR and not a rollback

Twelve line citations in `04_DEVELOPMENT.md` were not re-based after the rework, including one
written **this** round ("the CR-1 comment at `:2874-2878`", shipped `:2878-2882`). Every one of
them is substantively correct — the right function, the right predicate, the right clause — and
each is off by the +2/+3/+6 that §1's own chain predicts, which is itself evidence that the
record was written against the pre-rework file rather than re-measured. That is materially
weaker than round 1's CR-6, where the record asserted a `_plain()` call that did not exist:
nothing here is false about behaviour, only about coordinates, and any reader who lands three
lines early finds the thing they were sent to. Rolling back a second time over stale line
numbers would spend the escalation budget on a `sed`-sized fix while the two genuinely open
items (CR-2, CR-3) are ones this stage already ruled need a design decision and travel as pool
rows. It is filed as RES-10 so stage 6 re-derives its fixture anchors from the file.

## 8. Trigger record

- **T5.2** — adjudicating `04_DEVELOPMENT.md`'s recorded drift, now five rows: D-1 (re-read,
  unchanged from round 1's adjudication) and the new **D-5** (the CR-1 narrowing). Reached for
  `02_RATIONALE.md`; present; consulted — its "the credential directory / the one document in it
  that carries no credential" vocabulary is where D-5's word *credential* comes from, so the
  narrowing uses the design's own term rather than inventing one.
- **T5.1 / T5.3** — did not fire this round: no design-fidelity finding turns on *why* the design
  chose a shape, and no new reuse-correctness or risk finding was raised.
- **T5.4** — did not fire: every identifier I acted on (`R-22`, `Q-4`, `GC-10`, `BC-19`, `BC-20`,
  `D-5`, `V-9.5`) is defined in a contract portion.
- No stage's **contract** portion was missing, so no `BLOCKED ON UPSTREAM` applies.
