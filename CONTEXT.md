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

**degraded config**:
A generated `config.json` from which unusable rule-sets and every routing rule referencing them
have been dropped, so sing-box starts with less routing granularity instead of failing to start.
_Avoid_: fallback config, broken config, partial config
