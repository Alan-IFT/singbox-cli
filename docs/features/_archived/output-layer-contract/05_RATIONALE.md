> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1 — "No behaviour changed" — how it was verified, not accepted

I hold no shell. The claim was settled by reading every edited region and by one structural check the
developer did not make.

- `bin/sc:465-476` — the `_egress_ip()` docstring. It is the first statement after `def _egress_ip():`
  (`:464`), and the function body is unchanged at `:477-478`.
- `bin/sc:3098-3111` — the `cmd_config` docstring, first statement after `def cmd_config(args):`
  (`:3097`); `:3112` onward is untouched. The escape shapes are spelled `\\xNN` / `\\UNNNNNNNN` in
  source, so the string carries `\xNN` / `\UNNNNNNNN` and no invalid-escape warning exists to be
  promoted by `-W error`. An unescaped `\U` here would have been a hard `SyntaxError`, which is why
  the developer's "compiles clean" is a real check rather than a formality.
- `bin/sc:3151-3158` and `:3697-3704` — every line begins with `#`.

The check the developer did not make, and the one that actually closes the docstring half: **`__doc__`
is read nowhere in `bin/sc`** (repo-wide search, zero hits), and `HELP_EN` / `HELP_ZH` are independent
constants. A docstring in this file therefore has no route to any rendered line at all, which is a
stronger statement than "tokenize reports STRING". `t()`'s enumeration cannot have moved either: no
`t(` call appears in any of the four regions.

Rendered strings: I re-grepped the two load-bearing literals in the tree. Seven `失败` string sites
(`:136, :145, :147, :148, :158, :214, :234`), `OK (` at `:213` and `failed: {e}` at `:214`, all
untouched, and `restricted-network-regression.sh:284` still counts exactly those two with `grep -cF`.
No round-2 edit touches a rendered string, so the C-7 census does not need to be extended.

## 2 — CR-10 and CR-11: the two clauses the round's own new prose over- and under-states

**CR-10.** Today, through `sc config`, the escape path has exactly one reachable trigger:
`PYTHONIOENCODING`. Whenever it is unset, `Path.read_text()` and `sys.stdout` resolve the *same*
codec, and a character that decoded can always encode — that identity holds for every locale, not
just UTF-8, which is precisely why the developer's own `LC_ALL=C` measurement of the escape path is a
counterfactual carrying the `read_text()` repair. So the published parenthetical's first cause,
"a non-UTF-8 locale", describes a case where today the run ends at `bin/sc:3113` with exit 1 and
`cannot read …` — the opposite of the clause it qualifies ("instead of ending the run"). The
conclusion the reader takes away ("run under a UTF-8 stdout") is right in both cases, which is why
this is MINOR and why leaving it is a legitimate disposition: the sentence is written for the world
the filed pool row creates. What must not happen is the row landing without anyone re-reading these
two sentences, and that is RES-6's whole content.

**CR-11.** `errors="backslashreplace"` displaces `surrogateescape` for *everything*, and under the
POSIX locale CPython surrogate-escapes all three OS byte interfaces — filesystem names, `os.environ`
and `sys.argv`. `_ruleset_bases()` reads `SB_RULES_BASE` (`bin/sc:1129`) or `--mirror` from argv, and
those values are printed verbatim inside the cause list built at `:3346` and emitted at `:3370`. That
is a second route, structurally identical to the `{path}` one and about as likely. I checked the
other candidates before filing: `RULES_DIR.iterdir()` (`:1148`) never prints a name, `cmd_sysproxy`
prints `val` and not the env-derived `user` (`:3303`, `:3320`), and `_doctor_run`'s `errors="replace"`
(`:2536`) produces `U+FFFD`, which HEAD would have *aborted* on under an ASCII stdout — an FR-7
improvement, not a give-up. So the honest form of the row is the class plus the `{path}` instance, and
the fix is one clause, not a rewrite.

## 3 — The round-2 safety event: ruling

**The re-taken evidence is sound.** Two things had to be true, and only one of them is closed by the
harness's own witness.

1. *The void run wrote nothing.* This cannot be closed by C-1's before/after witness — that witness
   is taken by the **re-take**, and a mutation made before it would be inside both snapshots. I
   closed it independently, by reading the build that actually ran: `/usr/local/bin/sc` defines
   `main()` at `:2432`, calls `parser.parse_args()` at `:2453`, and reaches `_init_files()` only at
   `:2466`, inside the post-parse arm. An `invalid choice` error is raised *by* `parse_args`, so
   execution ended at `:2453` — before the first writer on the start-up path, and with no
   module-level writer above it. Exit 2 is argparse's own status and corroborates the account. The
   run was root (that is what the re-exec bought) and still could not have written.
2. *The re-take is independent of it.* It used `docs/dev-map.md:121-158` verbatim, on a fresh
   `mkdtemp()` root, with the eight-constant assertion and the two-path witness in place, and five
   cases reproduced byte-for-byte. Reproduction on a different loader is the strongest available
   evidence that the loader was not what produced the numbers.

Declaring the run void rather than salvaging it was the right call, and re-taking *all five* cases
rather than the one that failed is the part I would have insisted on had it not been done.

**The non-filing was right.** The technical fact already has exactly one home (`docs/dev-map.md:121-158`),
and `.harness/rules/70-doc-size.md`'s adversarial check plus the 30-line insight-index cap both argue
against a second copy of a rule that is already binding — an insight index that restates the dev-map
is how both stop being read. The event is recorded where it belongs: `04_RATIONALE.md` §1, in the
developer's own words, plus this ruling. What the episode does show is that the row's *rule* was
enough and its *failure signature* was not — a fresh context that skips the row does not get a loud
"you imported the installed build", it gets an argparse usage error about its own argv, which reads
like a bug in the harness. Naming that signature is one clause, and it is RES-7 rather than a finding
because nothing under review is defective for lacking it.

## 4 — DD-1 / DD-2 / DD-3, restated at their current lines

DD-1 upheld, and more strongly than filed: CPython constructs the real `sys.stdout` with an explicit
`newline="\n"` on every platform, so omitting the argument at `bin/sc:3707` would have replaced a
pinned `\n` with a platform-dependent one — a genuine (if Linux-invisible) AC-14 regression
introduced by the re-wrap itself. There was no justifiable omission for C-10 to accept.

DD-2 upheld. `print(x)` is `write(str(x))`, so `_plain(str(x))` differs from HEAD by exactly `_plain`'s
neutralisation and nothing else; a bare `_plain(x)` would be a **new** failure mode (`TypeError` where
HEAD printed a value), and narrowing the type earlier needs a branch and a message Q-18 forbids.
`_plain` (`bin/sc:2482`) removes only CR and complete CSI sequences and strips trailing whitespace, so
it is a no-op over any `repr`. `:2456` correctly carries no `str()`, which is what makes it
character-identical to `_doctor_egress:2886` and makes C-3's re-pointing of AC-12 a real comparison.

DD-3 upheld, and its record is now honest — see CR-4. The five blocks are 20 lines and the diff's
`#`-share is +33/−9; the ledger-named block and the `os._exit` block account for the remainder.

## 5 — Method, and what this review could not do

Read-only throughout: no `bin/sc` execution, no import, no harness, no `git diff`. Every claim about
the shipped code is read out of the working tree at the cited line; every claim that needs execution
is marked "record" in the coverage table, and where the record is the only evidence the finding — if
any — is about the record. The one file I read outside the repository is `/usr/local/bin/sc`, read
never executed, and only to settle §3's first question. No credential byte appears anywhere in this
review (`verify_all` A.1).

`.harness/rules/70-doc-size.md` still declares no `## Stage-doc boundary rule` (R-37 / Q-16, confirmed
again here), so this contract applies its schema as written: the safety-event ruling and the round
record are carried as a `## Residuals travelling` row and in the message to the PM respectively, and
no section was invented.
