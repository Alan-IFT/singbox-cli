> Rationale portion for 05_CODE_REVIEW.md. Non-binding.

## 1 — Why `$after {"server": "hosts_dns"}` is not merely adequate but forced

I did not take DD-1/DD-2 on the developer's measurement. The claim decomposes into four independent
propositions, each checkable in the file.

**(a) Uniqueness.** `_anchor_index` (`bin/sc:1241-1261`) matches by subset equality over the
elements of the array named by the merge path. The composed `dns.rules` is: the `$prepend`ed
suppression rule (`:1599-1601`, no `server` key), then `CONFIG_BASE["dns"]["rules"]` (`:1153-1166`),
whose only element carrying `"server": "hosts_dns"` is `{"server": "hosts_dns", "ip_accept_any":
true}` at `:1154` — every other element carries `remote_dns` or `direct_dns` — plus the reject rule
(`:1727`, no `server` key). `dns.servers` also holds a `hosts_dns` **tag** and `remote_dns` carries
`"domain_resolver": "hosts_dns"`, but neither is in the array the anchor is resolved against. So the
anchor matches exactly one element in {`block`,`allow`} × {rule-sets usable, none usable} and at
HEAD. `_filter_rules` (`:921-926`) keeps any rule without a `rule_set` key unconditionally, so no
rule-set state can delete it, and no setting emits or removes it. This is strictly stronger than
FR-9's first clause, which only demands uniqueness in the states where the reject rule exists.

**(b) Position.** After `_compose`, the array is `[suppress, hosts, reject, Global, Direct, …]`.
The user's document is merged afterwards, at its own site (`:1913-1918`). `$after` on index 1 inserts
at index 2 (`_apply_directive:1279-1281`), so the user's rules land **after** the hosts rule — BC-11
holds, `sc`'s own DoH bootstrap keeps answering, and extending the list cannot break it — and
**before** the shipped reject rule, which shifts to 3. `_filter_rules` runs after the merge but
touches only `rule_set`-bearing rules, of which the published recipes have none.

**(c) The shared-anchor claim.** `_directive_of` (`:1225-1233`) raises when one merge-value object
carries a `$` key beside any other key, or two `$` keys. One array therefore takes one directive,
one directive carries one `match`, and only one `override.json` exists (`OVERRIDE_PATH`, `:30`).
C-4 obliges both READMEs to show a combined form for a user who wants both recipes; that form is
one directive; therefore both recipes must be publishable on one anchor. Sound.

**(d) Why no other anchor works.** `{"rcode": "NXDOMAIN"}` exists only under `block` — F-2, and the
developer reproduced the exact `OverrideError` under `allow` and at HEAD. `{"clash_mode": "Global"}`
is present in every state, but `$before` it resolves to index 3, i.e. *after* the shipped reject
rule, so it cannot except anything — the gate said this and the index arithmetic confirms it.
`{"action": "predefined"}` matches two elements under `block` (the suppression rule and the reject
rule) and, were it unique, `$after` the index-0 suppression rule would land at index 1, ahead of the
hosts rule, breaking BC-11. That exhausts the candidates: the slot between the hosts rule and the
first thing that chooses a resolver is the only admissible one, and `$after {"server":"hosts_dns"}`
is its only spelling. DD-1/DD-2 are not a preference; they are the unique solution to C-4.

The one thing I would have liked stated in shipped text is CR-7: a rule at index 2 precedes both
`clash_mode` rules, so an excepted name follows the resolver the user names in `global` and `direct`
too. The design's original anchor had the same property, and `README.md:202` does tell the user to
pick `direct_dns` or `remote_dns` deliberately, so this is a sentence for a future edit, not a defect.

## 2 — Ruling on DD-4 against rule 85, including the smaller alternative

Rule 85's `## Less is more` puts the burden of proof on the larger design, and `_telemetry_meaning()`
is one function the design did not name — so I tested three shapes against the file rather than
against the argument.

*Shape A — spell the conditional at both print sites.* Four lines duplicated in the `show` arm and
the `set` arm, and, decisively, **two definitions of one judgment**: "what does `block` mean for a
listed name". That is rule 85 test 2 verbatim, and it is the same reason D-1(b) refused to inline
`_telemetry_setting()`. Rejected by the rule, not by taste.

*Shape B — one private helper taking the setting as an argument.* What shipped. Six lines, pure,
private, no state, no file read, no second reader of `settings["telemetry"]` (I verified: the key is
read only at `:1685`/`:1687` and written only at `:2675`), and no third consumer of
`TELEMETRY_NAMES` (read only at `:1728` and `:2670`). AC-6's deletion test is unaffected in either
direction. It also matches the project's existing seam: `ipv6_decision()` returns its own already
translated sentence, so "the judgment owns its sentence" is this codebase's established shape — the
helper reproduces it without creating the `telemetry_decision()` sibling I-3 explicitly forbids,
because it derives nothing and decides nothing.

*Shape C — restructure `cmd_telemetry()` so the two lines print once.* This is the genuinely smaller
one: zero new definitions, ~6 fewer lines. I wrote it out. It costs two separate `if val == "show"`
tests with the `save_settings()` block between them, i.e. the `show` and `set` flows interleaved
instead of sequential, and it drifts from I-7's stated call flow and from `cmd_ipv6()`'s shape more
than shape B does. Rule 85 says to count a design's size as "its diff **plus** what every future
reader and every future task must now hold in their head": one named, pure, five-line mapping is
less to hold than a two-phase branch in a command that also persists state and restarts a service.

So B wins, and DD-4 stands. The developer's own defence ("takes the setting as an argument, reads
nothing") is correct but incomplete — it establishes the helper is harmless, not that it is smaller.
The reason it is smaller is that the alternative that would remove it does not remove the concept,
only its name.

## 3 — DD-5, and the one place the honesty stops short

The split is right, and the reasoning generalises: a `[D]`/`[A]` class is a property of an
*observation*, and AC-B6b holds two observations whose control classes are opposite by construction
— at HEAD the excepted name resolves because there is nothing to except, at the candidate because
the exception works, so the control can only ever *agree*, which NFR-8 defines as inconclusive
regardless of the rig. No sequence of measurements could have made AC-B6b-as-written pass. Reporting
that, and then splitting, is the correct handling of a criterion defect discovered at stage 4, and it
is precisely the class the gate itself caught as F-4 for V-29. The split does not weaken the
criterion: the `[D]` half now carries a control that genuinely reproduces a defect (HEAD rejects none
of the other names), which the bundled form never did.

Two qualifications, both in the contract portion. CR-3: the Summary's "30 pass, 0 fail, **0
inconclusive**" is true only of the post-split set, and the reader who stops there learns the
opposite of what AC-B7 exists to make visible — the fix is one clause, not a re-run. CR-4: the `[D]`
half was evidenced on 5 of the other 16 names (`04_RATIONALE.md:213-219`), while AC-B6b says
*every*. Five is a reasonable sample and the mechanism is a single suffix list, so I do not doubt the
result; I object to a sample presented as a census, which is the same distinction C-10 drew for BC-1.

## 4 — What I could not verify, and why I say so rather than imply otherwise

This stage had no shell. Three consequences, each carried as a residual rather than smuggled into a
✅. AC-7's freeze is asserted from reading each frozen symbol and confirming no new code path mutates
or shadows it — that is not the `ast` extraction plus byte comparison K-15 makes binding, and a
textual reading is exactly the unsound check K-15 was written against, so RES-1 hands it to stage 6.
The 30 behavioural observations, the four-resolver C-3 check and the latency distribution are
accepted from `04_RATIONALE.md` (RES-2). And `verify_all`'s 17/0/0/1 is the PM's independent re-run,
not mine.

What I *did* verify mechanically, by reading the tree rather than the report: the anchor arithmetic
above; the three-key rule and the absence of `answer`, of a second matcher, of a leading dot and of
any `reject` action in `dns.rules` (the file's only `"reject"` is `route.rules`' pre-existing QUIC
rule at `:1185`); that all six new translation keys exist in `zh` with identical placeholder sets and
that **every new `t()` call site — including the two implicit string concatenations at `:2633-2634`
and `:2681-2682` — resolves character-for-character to a key that exists**, the two reused keys
included (`:183`, `:138`); that both READMEs are 433 lines with every heading on the same line
number and the three JSON blocks byte-identical across languages; that the name count 17 is
consistent across the tuple, both tables, both prose paragraphs, the "other 16" line and the
changelog; that no shipped surface claims blocking beyond name resolution, client-side negative
caching, or a traceback-free `sc telemetry`; and that the guard tuple at `:1681-1683` is
`_ipv6_setting()`'s at `:1475` character for character, which is what makes the `UnicodeDecodeError`
hole provably pre-existing and provably not widened.

## 5 — Two things I deliberately did not re-litigate

The rule's position (Q-6/C-11), the `NXDOMAIN` mechanism (Q-4) and the `block` default (Q-7) are
settled upstream, and nothing in the code contradicts them: the overlay's anchor puts the rule ahead
of both mode rules, the emitted rule is `predefined`/`NXDOMAIN` with no `answer`, and absence of the
key resolves to `block` at `:1685-1686`. C-11 remains the owner's to confirm and the implementation
is reversible at one anchor string, one README paragraph per language and one dev-map row — the gate
was right that reverting it later is expensive, and nothing here has made it cheaper or dearer.

I also did not charge the developer for the two stage-2 units in CR-5. K-13 puts `CONTEXT.md` outside
the permitted diff and the stage documents are not stage 4's to edit; the correct handling is exactly
what C-7 does for Q-5 — a PM amendment at delivery. I raise it because RS-3 is the one residual on
this task whose text escapes the feature folder and lands in a document every future task reads, and
nobody downstream is currently watching it.
