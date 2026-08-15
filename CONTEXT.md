# singbox-cli — glossary

`sc` manages a local sing-box proxy: nodes, routing mode, generated configuration and the
`.srs` rule-sets that drive traffic splitting. This glossary fixes the words the code, the
task documents and the bilingual UI all use for those things, so two tasks cannot mean two
different things by the same word. Terms specific to THIS project only.

## Language

**rule-set**:
One `.srs` file under `/etc/sing-box/rules/` holding a compiled list of domains or CIDRs that
routing rules reference by tag. The project manages a fixed, ordered set of them.
_Avoid_: ruleset (in prose), geo file, rule list, geosite/geoip (those name individual files)

**usable rule-set**:
A rule-set that exists, is a regular file, carries the `SRS` magic and meets the minimum size —
the single condition config generation, the downloader and the display all consult. A rule-set
that is merely *present* is not necessarily usable.
_Avoid_: valid, present, downloaded, available

**gained**:
A rule-set that became usable during one run of a command, having not been usable when the run
started. Gaining changes what the generated `config.json` contains, so it triggers regeneration.
_Avoid_: restored, recovered, fixed

**content-changed**:
A rule-set whose installed bytes differ at the end of a run from the bytes installed at its
start. This changes only the data sing-box loaded — the generated `config.json` is unaffected —
so it triggers re-application of rule-set data, not regeneration. Every gained rule-set is
content-changed; the converse is false.
_Avoid_: updated, refreshed, downloaded, new

**hot-apply**:
Making a change effective in the running sing-box process without terminating it, through its
loopback Clash API. The project prefers hot-apply to a restart wherever the change's nature
allows it; node and routing-mode switches are hot-applied today.
_Avoid_: live reload, soft restart, apply instantly

**service-affecting action**:
Any operation that restarts, reloads, starts or stops the `sing-box` service, or instructs the
running process to re-read its configuration or rule-set data. Named as one concept because
whether a command performs one is a user-visible promise — a restart drops every live
connection.
_Avoid_: touching the service, bouncing, refreshing

**non-TTY output contract**:
The rule that when a stream is not attached to a terminal, output written to it carries no carriage
return and no intermediate progress state — exactly one complete line per item. It is a correctness
rule, not a style rule: `sc update-rules` output is captured into `/var/log/sing-box/install.log`
and installer output is routinely piped to a log or run from automation.
_Avoid_: quiet mode, non-interactive mode, plain output

**quiet notice**:
The single complete line printed *before* a transfer starts that names what is being fetched (a
repository-relative path, or a version plus architecture). It is printed in both modes: on a terminal
it labels the progress display, and off one it is the whole of the output for that transfer.
_Avoid_: progress line, status line, banner

**stated outcome**:
A sentence the installer itself prints, in the user's chosen language, saying what happened and what
to do next, paired with an exit status derived from the same facts. T-01 made this the installer's
standing promise: a run that ends without one is a defect regardless of why it ended. A raw error
line from a called tool (curl, mktemp, tar) is not a stated outcome — it is not localized, it does
not name the installer's step, and it says nothing about what to do next.
_Avoid_: error message, failure message, banner (the banner is one rendering of a stated outcome)

**assignment abort**:
Termination of a `set -e` shell script at a bare `VAR=$(…)` command substitution whose command or
pipeline exited non-zero, before any line below the assignment runs. The distinguishing symptom is
that the script's own validation and error handling for that value become unreachable code.
_Avoid_: silent failure, crash, set -e bug

**degraded config**:
A generated `config.json` from which unusable rule-sets and every routing rule referencing them
have been dropped, so sing-box starts with less routing granularity instead of failing to start.
_Avoid_: fallback config, broken config, partial config

**credential document**:
A file this tool creates that holds node credentials — today `/etc/sing-box/config.json` and
`/etc/sing-box/nodes.json`, plus any temporary object holding their bytes. Every credential
document is installed by `_write_private()` and is mode `0600` at every instant it holds content,
never only at the end of a write. `settings.json` and `rules/*.srs` are not credential documents.
T-13's `01_REQUIREMENT_ANALYSIS.md` calls this a "credential-bearing file"; use *credential
document* from here on.
_Avoid_: secret file, private file, sensitive config, protected file

**base template**:
The data form of the configuration document `sc` starts from, holding every part that does not
depend on run-time state. It ships inside `bin/sc` because `install.sh` fetches an enumerated
artifact list and the CLI must stay a single self-contained file.
_Avoid_: default config, skeleton, config template string

**overlay**:
One ordered transformation applied to the accumulated configuration document — objects merge by
depth, arrays only under an explicit directive. The user override is the last overlay and goes
through the same merge implementation as any shipped one; there is never a second merge.
_Avoid_: patch, layer, mixin, fragment (a fragment is a *file* that may hold an overlay)

**directive**:
An explicit array-merge instruction inside an overlay — `$prepend`, `$append`, `$replace`, or the
positional form that inserts relative to a matched anchor element. Required because DNS and route
rule order carries meaning, so a default array merge would be silently wrong. Directives are read
only at merge positions, never inside a value being inserted wholesale.
_Avoid_: operator, strategy, merge mode

**emitted position**:
The index at which an `sc`-authored overlay places its own rule in an array the base template
defines — for the AAAA rule, the head of `dns.rules`. It is a promise, not an implementation
detail: that position is what makes the rule apply in `rule`, `global` and `direct` alike, and
both READMEs publish it. It has one home (the overlay's own directive payload) and two readers
(the generator and `sc doctor`), so a probe asks the document about it by reading that payload
rather than by spelling an index of its own.
_Avoid_: index, offset, slot, ordering

**user override**:
The user-owned document `sc` reads and never writes, creates, or deletes, applied last. It is what
makes a hand-made customization survive `sc reload` / `use` / `add`. Distinct from the systemd
timer's `override.conf` drop-in, which is unrelated.
_Avoid_: user config, custom config, local config, patch file

**drift**:
The state where `/etc/sing-box/config.json` on disk differs from the document `sc` last generated,
i.e. someone hand-edited a generated artifact. `sc` states drift before replacing the file and names
the user override as the durable place for the change; it does not block and does not back up.
_Avoid_: dirty config, manual change, out-of-sync

**drift record**:
The sha256 digest of `config.json` as `sc` last installed it, kept at `/etc/sing-box/.config.sha256`
and rewritten only after a successful install. It is a digest, never a copy — a second copy of the
generated document would be a second credential document on disk. Absent means *unknown*, not drift.
_Avoid_: config hash file, checksum, snapshot, backup

**telemetry reject list**:
The fixed, curated set of names `sc` answers locally with "no such domain" (`NXDOMAIN`, no records,
no upstream query), emitted as one DNS rule and switched by the one `telemetry` setting. It is data
plus a toggle, not a downloaded feed: no rule-set, no update path, no expiry. Membership is by a
stated criterion — the name's sole function is carrying usage/diagnostic/crash/advertising-identifier
data, **and** blocking it disables no user-visible function — so update, activation, authentication,
push-delivery, CDN-content and security endpoints are excluded whatever data they also carry.
_Avoid_: blocklist, adblock, filter list, blacklist

**reject rule**:
The single emitted `dns.rules` element carrying the telemetry reject list, positioned after the
predefined-hosts rule and **before both `clash_mode` rules** — so rejection is independent of routing
mode, which is load-bearing rather than incidental: after the `clash_mode` rules the name is
measurably leaked to an upstream resolver in `global` and `direct` alike. Users anchor their own
override rules against it with `$after {"server": "hosts_dns"}`, never against the rule's own
`{"rcode": "NXDOMAIN"}`, which exists only while the list is on.
_Avoid_: block rule, deny rule, blackhole rule

**visible key set**:
The fixed set of key names whose values `sc config` renders verbatim **inside the `outbounds` array**;
every other key there has its whole value replaced by the mask, at every depth. It is derived, not
curated — every key name `sc` emits inside an outbound, minus the credential-bearing ones, plus
`detour`, sing-box's outbound-chaining key, which `sc` itself never emits — so a key nobody
enumerated is masked rather than printed.
_Avoid_: whitelist, allowed fields, safe keys, field filter

**mask**:
The one fixed literal `sc config` writes in place of a value it must not print. It replaces the value
and never the key, is identical everywhere, and carries nothing derived from what it replaced — no
length, no prefix, no digest — so which fields exist stays observable while their contents do not.
_Avoid_: redaction placeholder, censor, stars, `<hidden>`

**blackout**:
The deliberate, *derived* unreachability of every shipped rule-set source plus `github.com`,
`raw.githubusercontent.com` and `api.github.com`, injected through name resolution and lifted by
restoring one file byte-for-byte. It is a property the regression harness creates on purpose inside a
disposable VM, never an accident of the network and never a substitution of the source list.
_Avoid_: offline mode, air-gap, network failure, mock

**userinfo reading**:
The single judgment about a share URL's authority: the userinfo is the text before its **last** `@`,
its field boundary is the **first unescaped colon** in that text, the split happens on the **raw**
URI text, and each extracted field is percent-decoded **exactly once** afterwards. One construct in
`bin/sc` states it and every parser takes a *projection* of it — the whole userinfo, its first field,
or its remainder — so a scheme's grammar is a choice of projection, never a second parse. Material
recovered from base64 was never URI text and is deliberately outside it.
_Avoid_: `urlparse().username`, credential parsing, userinfo helper, split the password

**document envelope**:
The single region of config generation that spans the user override's bytes to the emitted
document's bytes, inside which *any* exception becomes one unusable-document sentence naming a
path and a fault class. It is a region, not a list of catch sites: what makes it honest is that
nothing inside it can reach the user as a traceback, and what makes it truthful is that the
write and the checker sit outside it, keeping their own renderings.
_Avoid_: error handler, try block, catch-all, guard

**state document**:
A JSON document `sc` both authors and reads back as its own persistent state — `settings.json` and
`nodes.json`, and those two only. One reader decodes every state document as UTF-8 independently of
the process locale, applies exactly one top-level shape check, and answers *usable* / *absent* /
*unusable*; every writer emits UTF-8 with non-ASCII literal. The user's `override.json` is **not**
one (it is untrusted input, with its own size cap and policies), and neither is `config.json` (a
document `sc` emits *for sing-box*, whose readers deliberately keep their own decoding).
_Avoid_: config file, settings file, data file, state file (the file is not the category)

## Project intent

**singbox-cli is a headless v2rayN.** Stated by the owner 2026-08-01: 「初衷是实现一个类似于非桌面版
的 V2rayN；所以完全可以抄 V2rayN 的一些逻辑」. Treat 2dust/v2rayN as the roadmap reference for *what*
the tool should do — failover groups, per-node latency, selectable rule-source profiles, subscription
handling — while remembering its *implementation* of rule-set downloading is thinner than this
project's (no retry, no fallback, no checksum; see `docs/batches/default/BATCH_PLAN.md` notes).
Copying a v2rayN behaviour is endorsed; copying its download code would be a regression.
