> Rationale portion for 03_GATE_REVIEW.md. Non-binding.

## The security ruling — verified, and it holds

Q-2's evidence was checked in the two files it names, not read from stage 1.

- `install.sh:546-552` writes `/etc/sudoers.d/sc` containing `$INSTALL_USER ALL=(ALL) NOPASSWD:
  /usr/local/bin/sc`, `chmod 440`s it and validates it with `visudo -c`.
- `bin/sc:117-118` re-execs `os.execvp("sudo", ["sudo", "/usr/local/bin/sc"] + sys.argv[1:])` at
  **import** time whenever `os.geteuid() != 0`.
- `_write_private()` installs `config.json` at `CRED_MODE = 0o600` (`bin/sc:41`, `:418-458`) and
  `install.sh:315` lists it in `CRED_FILES` for the credential-mode sweep.

So the composition is exactly as stated: for the install user, an unredacted `sc config` converts a
password-gated read of a 0600 credential document into a password-free one, and an opt-out flag has
the identical property because the flag is reachable through the same NOPASSWD rule. The ruling
stands, and the reverse risk is small: the unredacted document remains readable by `sudo cat`, which
is the password-gated route the sudoers rule does not cover — a legitimate need is therefore unmet by
nothing at all. No escape hatch is warranted.

Nothing secret survives the mask, checked against real shapes rather than the requirement's summary.
`git grep` over `bin/sc` for `private_key`, `pre_shared_key`, `"secret"` and `token` returns **zero**
hits, so FR-4's claim that those can only enter through `override.json` is true; the credential names
`sc` actually writes into an outbound are `uuid` (`:578`, `:601`, `:715`), `password` (`:637`, `:673`,
`:685`, `:697` inside `obfs`, `:716`), `public_key` (`:563`) and `short_id` (`:566`) — the four FR-3
masks by exclusion, plus the `obfs.password` which is masked twice over (SECRET_KEYS first, then the
region rule). `experimental.clash_api` in `CONFIG_BASE` (`:1229`) carries only `external_controller`,
so the root-level `secret` case is an override-only case and SECRET_KEYS covers it at `strict=False`.

I-4's `strict` propagation was traced by hand against three shapes:

- the T-15 `urltest` group (`:1788-1796`) — `outbounds` is in the visible set, so its **list of tag
  strings** descends with `strict=True` and each element, being neither list nor dict, returns
  verbatim: the group stays fully legible;
- `transport.headers` (`:525`, `:609`) — `headers` and `Host` are both visible, every other key in
  that object is masked, which is BC-9 exactly;
- `experimental.clash_api.secret` at the root — `strict` is `False` there, and SECRET_KEYS is tested
  **before** the region rule, so the floor still fires.

`strict` turns true on descent into any key literally named `outbounds` and never turns back, which
is what makes BC-8 fail closed.

## The 34 names — re-derived from the code, not accepted

I enumerated every key literal assigned inside the four cited ranges independently of
`02_RATIONALE.md`'s table:

`_attach_transport` (`:519-543`) → `transport`, `type`, `path`, `headers`, `Host`, `host`,
`service_name`. `_attach_tls` (`:546-567`) → `tls`, `enabled`, `server_name`, `alpn`, `utls`,
`fingerprint`, `insecure`, `reality`, `public_key`, `short_id`. The six parsers (`:570-729`) → `type`,
`tag`, `server`, `server_port`, `uuid`, `flow`, `packet_encoding`, `alter_id`, `security`, `password`,
`method`, `obfs`, `congestion_control`, `udp_relay_mode`. `_runtime_overlay` (`:1788-1811`) →
`outbounds`, `url`, `interval`, `tolerance`, `idle_timeout`, `default`, `interrupt_exist_connections`
(plus `type`/`tag` again).

That is **37** distinct names. Minus `uuid`/`password`/`public_key`/`short_id` = 33; plus `detour` =
34, and the 34 I derived are name-for-name the 34 in I-2 and in FR-3. So: the set is **complete** (no
key `sc` emits is missing — the direction that would silently hide a field), and it is **minimal**
except for the single deliberate addition. `git grep` confirms there is no fifth emission site: every
`"tag":` / `"type":` literal in the file outside these ranges is a DNS server, an inbound or a
`route.rule_set` entry, none of which sits inside `outbounds`.

`detour` is the one curated member, and the audit's only substantive correction is that the *glossary*
does not admit it (F-4). It earns its line: sing-box's outbound-chaining key can only reach the
document through `override.json`, and without it a user's chain would print `"detour": "******"` —
masking a routing relationship, not a secret, which is the opposite of the command's purpose.

**Is 34 names of data the smallest correct expression?** The burden was tested rather than accepted.
Stage 1's FR-3 — not stage 2 — fixes the allow-list *shape*, so the architect's freedom was only in
the membership, and membership is a derivation with one documented exception. The genuinely smaller
formulations were re-examined here:

- The 5-name allow-list is smaller and strictly safer, and it does defeat FR-1's stated purpose: on a
  real reality/vless node it masks `tls`, `transport` and `flow` wholesale, i.e. SNI, ALPN, uTLS
  fingerprint, ws path, `Host`, gRPC service name — precisely the fields `sc ls` does not show and the
  only fields inside `outbounds` worth reading. The rejection is sound.
- A credential deny-list inside `outbounds` (8 names instead of 34) would be smaller *and* readable,
  but it fails open on the one case Q-5 exists for and AC-B3 observes. Overruling it would be
  overruling FR-3, which is a stage-1 decision this gate has no cause to reopen.
- No structurally different formulation reaches the same fail-closed property with less to maintain:
  a value-shape heuristic is not provable, and a textual mask cannot guarantee the output parses.

So the data literal is where the size properly lands, and K-10 puts the maintenance obligation in the
constant's own comment with V-11 as a seconds-long mechanical re-check. This is data, not machinery.

## The `_drift_state()` split — load-bearing for this task

`bin/sc:1871-1897` was read in full rather than trusted. `_warn_drift()` returns early on an
unreadable record, on an empty record, on `_config_digest() is None` **and on `current == recorded`** —
the *matches* state is discarded at `:1892` and is not observable from any caller. FR-6 needs exactly
that state, so the claim is true of the code and not merely asserted, and there is no way to reach the
third state without touching the function.

The alternative — re-reading the record inside `cmd_config()` and leaving `_warn_drift()` alone — is
genuinely smaller in names and roughly zero in diff, and it is the one this gate would take if the
judgement were trivial. It is not: BC-12/BC-13 fold four distinct *unknown* cases into that read, and
rule 85's second test (duplicated judgment) is met squarely. The future edit it prevents is nameable
and already filed — a drift row in `sc doctor` (T-20) becomes one `_drift_state()` call rather than a
third reader. K-14 plus V-12's four-state before/after comparison bound the regression risk on
`generate_config()`'s apply path, which is the only place the warning is user-visible. Not a refactor
riding along; kept.

## The dispatch change — smallest safe form

`bin/sc:3177` is `if args.cmd == "doctor":` with the comment at `:3168-3176` explaining that this is a
**positive** opt-out naming one command so that every future command inherits the initialising arm.
`in ("doctor", "config")` preserves that property exactly: the `else` arm still calls `_init_files()`,
`_load_lang()` and `_resolve_clash_port()`, and an unlisted future subcommand still lands there. A
`READ_ONLY_COMMANDS` constant is the same line count and is what `docs/dev-map.md:153-155` forbids.
`cmd_config()` needs `LANG` (assigned in both arms) and does not need `CLASH_PORT`. No smaller or
safer change exists; the tuple is a data change.

## Per-finding reasoning

**F-1.** T-15's lesson is the pattern, not the incident: an AC set that pins the artifact and never the
behaviour passes a gate it should fail. AC-B1 pins "parses, and equals the file except where masked" —
which an all-masked document satisfies exactly, and AC-B2 ("no fixture credential appears") satisfies
it *better* the more is masked. The two therefore agree with each other on a useless build. V-1 already
carries the real observation ("the mask appears only at `uuid`/`password`/`public_key`/`short_id`
positions"), and that expectation is provably correct for the stated fixture, because a document `sc`
generated contains no key outside the visible set. The cheapest honest fix is to bind the criterion to
its step rather than to reopen stage 1 for a wording round, hence GC-1 rather than a rollback.

**F-2.** `_init_files()` at `bin/sc:470-481` creates `CFG_DIR` and `RULES_DIR` from repointable
constants but `Path("/var/lib/sing-box")` as a literal, with `parents=True, exist_ok=True` — so on a
host where sing-box is installed the call leaves **no trace** in `/var/lib` and V-4's listing diff there
is empty whether or not the command initialised. The temp-root half of V-4 would still catch it (via
`rules/`, `nodes.json`, `settings.json`), so the step is not worthless — but its stated primary
evidence is the vacuous half, and the configuration in which it runs is the one `docs/dev-map.md`
tells every harness never to enter. Raisers over the two functions give a stronger negative, are
smaller than the listing machinery, and remove any path to the live filesystem; V-10 already
establishes the idiom in this same plan.

**F-3.** `docs/dev-map.md` names the drift trio twice, at `:38` and at `:65`. The second is the row a
future task reads when it asks "who decides whether the document drifted?" — exactly T-20's question —
so leaving it saying *trio* re-creates the second-opinion risk C-2 exists to remove.

**F-4 / F-5.** On the remit question: `CONTEXT.md` states its own purpose in its first six lines — it
fixes the words the code, the task documents and the bilingual UI all use, so two tasks cannot mean two
things by one word. That purpose is served only if the entry exists *before* the code is written, which
is why this project's precedent has stage 1 or stage 2 apply it and the gate audit it
(`install-version-query-abort` PM-2 accepted the analyst's edit and A-5 upheld it; the architect of
`config-write-permission-hardening` added *credential document* "per standing project contract"). The
one case where a stage declined (`proxy-urltest-group`) declined because that task's requirement carried
a permitted-diff NFR; T-06's NFRs impose no such list. So C-10 is within remit and the audit reduces to
the wording — which is where the actual defect is: the definition claims pure derivation and one of its
34 members is not derived. K-15 makes the developer quote this entry in code comments and both READMEs,
so an inaccurate glossary propagates into four files.

**F-6.** Reading FR-9 strictly, "the documentation" could mean all four documents; K-12 binds only the
two READMEs. Putting an `override.json` caveat into `HELP_EN`/`HELP_ZH` would inflate two hand-aligned
blocks for a case the READMEs already own, and the help block's own convention is one line of
description plus terse sub-lines. Resolved toward the READMEs under the standing authority — the
smaller surface, and the one the FR-9 sentence's own subject ("the documentation states the mask's
limit") is satisfied by.

**F-7.** FR-7 and NFR-1 are real promises with a real failure mode (a command that exists to inspect a
broken host must not open a socket on it), and the AC table binds only the filesystem half. This is the
same class as F-1 — the promise is wider than what any criterion observes — but the design already
carries the observation, so it costs one reporting condition rather than a criterion.

**F-8.** `Path.read_text()` with no argument decodes with `locale.getpreferredencoding(False)`, and the
matching stdout write encodes the same way; `ensure_ascii=False` (I-13) guarantees non-ASCII bytes on
that write whenever a tag is Chinese, which on this project is the common case. PEP 538's C-locale
coercion lands in 3.7, so the stated 3.6 floor (`README.md:21`) is precisely the version where a
`C`-locale host breaks — and it breaks in both directions (a false BC-2/BC-3 on the read, a
`UnicodeEncodeError` traceback on the write). It is a pre-existing repo-wide class: `load_nodes()`,
`load_settings()` and `_load_lang()` all read the same way and `cmd_ls` prints the same tags, so `sc ls`
fails first on such a host. Buying an encoding argument here fixes half of one instance of a repo-wide
class and would not even make `sc config` work on that host — the write would still fail. Disclosure is
the proportionate answer; a family fix belongs with R-25/R-29's row.

**F-9.** `install.sh` writes no `config.json` anywhere; the atomicity BC-11 and RS-3 rely on is
`os.replace` in `_write_private()` (`bin/sc:458`), whose docstring already states rename-not-truncate
and mode-travels-with-inode. The mechanism is correct — only the attribution is wrong, and a reviewer
sent to `install.sh` to verify it would find nothing.

## Verified good — positive statements, not absences

- **A.1 arithmetic.** `verify_all.sh:33` matches `(api[_-]?key|secret|password|token)[[:space:]]*[:=]
  [[:space:]]*["'][^"']{8,}["']` over non-`.md` tracked files. `MASK = "******"` is six characters, so
  `"password": "******"` yields a six-character quoted literal and cannot match; `SECRET_KEYS`'
  membership literals are followed by `,`, never by `:` or `=`. NFR-3 is satisfiable as designed and
  K-11 keeps it that way.
- **i18n exposure.** `check-i18n-parity.sh` parses `install.sh`'s bash `t()` only (`:32`, `:48`), and
  `install.sh` gains nothing in this task, so the `set -u` failure mode insight 11 describes is not
  reachable here. `bin/sc`'s `t()` falls back to the English key (`:411-413`, and `TRANSLATIONS` has no
  `en` table), so a missing key degrades to English rather than killing the run — and all five reused
  keys were found in the `zh` table with matching placeholders anyway.
- **K-4's premise.** `README.md:21` states the Python 3.6+ floor, and `sys.stderr` became
  unconditionally line-buffered only in 3.9 (bpo-13601); before that a redirected stderr is
  block-buffered and the shutdown flush order (stdout first) puts the commentary *after* the document.
  The explicit `sys.stderr.flush()` is therefore required for AC-B6 and is the smallest thing that
  makes ordering follow write order. Insight-index lines 28-29 are the project's twin cases, not the
  proof of the 3.9 fact itself.
- **K-6.** `os._exit(1)` skips interpreter shutdown entirely, so the buffered stdout is never flushed
  and no "Exception ignored" text can be emitted; stderr was already flushed by K-4 and nothing writes
  to it afterwards, so nothing is lost. The Python docs' `dup2(devnull)` recipe is one line larger for
  identical observable behaviour here, and the design records the `atexit` precondition in the comment.
- **Fixture feasibility.** `generate_config()` writes `config.json` **before** running `sing-box check`
  (`bin/sc:1975-1977`), so V-1's "generated by this same `sc`" fixture is producible in a temp root with
  a stub `SB_BIN` and no real `.srs` bytes — insight 23's checker trap does not bite this plan. The
  document `sc` writes is `json.dumps(config, indent=2, ensure_ascii=False)`, byte-for-byte the same
  serialisation I-13 prints, so AC-B1's comparison is exact up to the mask and one trailing newline.
- **AC-B9's honesty.** Only AC-B9 needs root: it names the installed `/usr/local/bin/sc` and the live
  0600 document. AC-B1…AC-B8 run entirely inside the repointed root as the invoking user, AC-S1 reads
  four documents, and AC-S2 runs `verify_all`, whose A/B/E/F steps need neither root nor network. The
  R-31/R-41 discipline (report BLOCKED, file a row, substitute nothing) applies unchanged.
- **BC coverage.** Every one of BC-1…BC-16 lands on a named carrier, and the error taxonomy is right
  where this repo has historically got it wrong: `UnicodeDecodeError` is a `ValueError` and not an
  `OSError` (insight 18), and K-5 catches `(OSError, ValueError)` in one arm rather than repeating
  `_load_lang()`'s hole.

## Evidence read for this review

`bin/sc:20-74` (paths, `CRED_MODE`, reserved tags), `:100-149` (elevation, i18n head), `:268-341`
(reused keys, `LANG`, `_load_lang`), `:411-501` (`t`, `_write_private`, `_init_files`, nodes/settings
IO), `:504-746` (both attachers and all six parsers), `:1103-1231` (`CONFIG_BASE`), `:1740-1820`
(`_telemetry_overlay`, `_runtime_overlay`), `:1824-1898` (drift trio), `:1900-1980`
(`generate_config`'s write path), `:2300-2340` (`_plain`), `:3007-3141` (both help blocks), `:3140-3215`
(`main()`); `install.sh:315`, `:492`, `:530-570`; `.harness/scripts/verify_all.sh:1-150`;
`.harness/scripts/check-i18n-parity.sh` in full; `.harness/insight-index.md` in full;
`.harness/rules/85-design-discipline.md` in full; `.harness/rules/70-doc-size.md` in full (it defines no
`## Stage-doc boundary rule`, so Q-12/R-37 is confirmed and this document applies the contract schema as
written); `AI-GUIDE.md`; `CONTEXT.md:1-153`; `docs/dev-map.md:26-155`; `docs/tasks.md:1-30, 189-284`;
`README.md:21, 258-297`; `README.zh-CN.md:258-297`; `CHANGELOG.md:1-20`;
`docs/features/sc-config-show/01_REQUIREMENT_ANALYSIS.md` and `02_SOLUTION_DESIGN.md` in full;
`02_RATIONALE.md` in full (triggered by I-2's provenance claim).
