# singbox-cli

**English** | [简体中文](README.zh-CN.md)

> A friendly CLI shell for sing-box — proxied from boot, no GUI required, no user login required, all system traffic through a TUN proxy.

## ✨ Features

- **Proxy from boot**: systemd brings up the TUN interface before any user logs in. SSH, apt, every user process — all routed through the proxy.
- **Zero GUI dependency**: pure CLI. Runs on desktops, servers, headless boxes, containers.
- **One-shot share-link import**: supports `vless://` `vmess://` `trojan://` `ss://` `hysteria2://` `tuic://`
- **Hot node switch**: applied instantly via sing-box's Clash API, no service restart.
- **Live route mode switch**: `rule` / `global` / `direct` with one command.
- **Auto ruleset update**: systemd timer pulls `.srs` rulesets at a configurable cadence.
- **Bilingual**: English (default) and Simplified Chinese; pick at install time, switch any time with `sc lang en|zh`.

## 🛠 Requirements

- Linux with systemd **or** OpenRC — tested on Debian, Ubuntu, Fedora, RHEL/CentOS/Rocky/Alma, Arch/Manjaro, openSUSE, Alpine
- amd64 (x86_64) or arm64 (aarch64)
- Python 3.6+ (preinstalled on most distros)
- root (one-time sudoers setup, password-less afterwards)

## 🚀 Install

One line:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

The installer will:

1. Prompt you to choose CLI language — English (default) or Simplified Chinese
2. Download the sing-box binary from GitHub Releases and install it to `/usr/local/bin/sing-box`
3. Install the `sc` CLI to `/usr/local/bin/`
4. Create the service unit (systemd service + ruleset auto-update timer, **or** OpenRC init script on Alpine)
5. Configure password-less sudo (scoped to the `sc` command only)
6. Download `.srs` rulesets
7. Start sing-box and enable boot autostart

> The language defaults to whatever your `$LANG` env var suggests (Chinese locale → `zh`, otherwise `en`). Just hit Enter at the prompt to accept, or pick `1`/`2`.

### Upgrade

Re-run the same one-liner. `install.sh` is idempotent: it replaces the `sc` CLI, the service units and the ruleset timer, and finishes by regenerating `config.json` and restarting the service. `nodes.json` is **never touched**, so your nodes and your active selection are preserved. `settings.json` is rewritten but every existing key is carried over — only `lang` is set, to whatever you pick at the prompt.

**Re-running does not upgrade sing-box itself.** Step 2 skips its download whenever a `sing-box` is already on `PATH`, so an existing binary stays at whatever version it is. To move it to the current release, remove it first and re-run — which is also the only way an already-installed host gets the checksum verification, since that runs only on a binary this installer actually downloads:

```bash
sudo rm /usr/local/bin/sing-box
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

The service is down between those two commands and comes back at the end of the run. Your nodes, settings and rulesets are untouched by this.

### Other install methods

Inspect first, then run (recommended for the cautious):

```bash
curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh -o install.sh
less install.sh
sudo bash install.sh
```

git clone (for development):

```bash
git clone https://github.com/Alan-IFT/singbox-cli.git
cd singbox-cli
sudo ./install.sh
```

### Installing on a restricted network

Everything this tool does **after** it is installed works without reaching GitHub: `sc add` parses the share link, generates the config, asks `sing-box check` and restarts the service, all locally — no request leaves the machine. The problem is the bootstrap, because two things must come from GitHub first: the installer's own files and the sing-box binary.

**Mirrors are built in.** Every `github.com` / `raw.githubusercontent.com` URL the installer fetches is tried against the canonical host first and then against two public GitHub reverse proxies. The canonical host is first on purpose: a host that *can* reach GitHub never routes its bytes through a third party. A host that cannot pays one 10-second connect timeout per endpoint and then proceeds. The version lookup has three independent sources, so `api.github.com` — the one host no mirror carries — is no longer a single point of failure.

**The sing-box binary is checksum-verified before it is installed.** Its sha256 is compared against the digest GitHub publishes for that exact release asset, and the digest is fetched from `api.github.com` **only** — never through the mirror list. That is what makes it a check rather than a formality: the tarball may come from a mirror, the digest never does, so no single party supplies both. A mismatch deletes the file and ends the run; nothing is unpacked and nothing is installed.

If the digest cannot be fetched at all — the case on a host that can reach a mirror but not `api.github.com` — the installer says so plainly, prints the sha256 it actually downloaded, and continues. Refusing there would lock out exactly the hosts the mirror list exists for, over a check no previous version performed at all. To require a match on such a host, obtain the digest out of band and pass it in:

```bash
sudo SB_SHA256=d34d987e...c495 bash install.sh
```

That leaves fetching `install.sh` itself, which happens before any of this code runs. Use a mirror for that one URL:

```bash
sudo bash -c "$(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

**Your own mirror**, replacing the built-in list entirely (whitespace-separated; include an explicit `""` to keep the canonical host as a candidate):

```bash
sudo SB_GH_MIRROR="https://mirror.example.internal/" bash install.sh
```

**Fully offline / air-gapped.** The installer skips its only large download when a sing-box binary is already on `PATH`, so place one yourself and the GitHub dependency is limited to the five small artifact files (which `git clone`, a tarball copy or a USB stick can supply just as well):

```bash
sudo install -m 755 ./sing-box /usr/local/bin/sing-box   # from any trusted source
sudo ./install.sh                                        # step 2 reports "already installed"
```

`SB_VERSION=1.13.15` pins the version and skips the lookup entirely.

**If the rulesets fail to download**, the install still completes and the service still starts: `sc` degrades to "no splitting" — every rule referencing a missing `.srs` is dropped and all traffic takes the default outbound, i.e. the proxy. Add a node, confirm traffic works, then run `sc update-rules`; it now downloads *through* your own proxy and rule-based splitting comes back on the next regeneration. The ruleset mirror list is ordered by reachability for the same reason as above, and `sc update-rules --mirror URL` overrides it.

## 📖 Usage

### Add a node

```bash
sc add 'vless://uuid@host:443?security=reality&pbk=...&fp=chrome&flow=xtls-rprx-vision#LosAngeles-US'
```

> ⚠️ Share links contain `?` `&` `#` and other shell-special characters. **Wrap the link in single quotes.**

A node is kept only if a configuration carrying it was **accepted**. If `sing-box check` rejects the document the link produces — an unsupported cipher, a field this sing-box build does not know — `sc` quotes the checker, restores `nodes.json` byte for byte and exits non-zero, leaving `config.json` untouched. The link is not stored, so it cannot fail every later `sc reload` / `sc use` / unattended ruleset-timer regeneration until someone finds it and runs `sc rm`.

### Switch node

```bash
sc ls                  # list all nodes, with their delay
sc use 1               # by index
sc use US              # by name fragment
sc use auto            # the auto-select group (see below)
```

Switching is applied instantly via the Clash API — **no service restart**.

### Auto-select the fastest node

With at least one node added, `sc` also emits an **auto-select group** tagged `auto`: sing-box probes every node every 3 minutes against `https://www.gstatic.com/generate_204` and routes traffic to the fastest one that answers. `sc use auto` selects that group, so a node that slows down — or starts refusing connections — stops carrying traffic, and stops carrying DNS with it, without anyone having to type a command; the switch happens on the **next probe round**, which means up to about 3 minutes of failing requests before it lands, not an instant cut-over. One failure this does not cover: a node that still accepts connections and then never answers hangs the probe instead of failing it, and a probe that never finishes never revises the choice — in testing the group stayed on such a node for as long as the test ran. If traffic is dead and the group has not moved, switch by hand. `sc use <name>` still pins a single node exactly as before; a fresh install selects the group on the first `sc add`, and an existing install keeps the node it was already on until you run `sc use auto`.

`sc ls` shows the group on a row of its own, with no index number, and its address column names the node the group is on right now:

```text
   #  On  Type        Name                            Address                        Delay
      ●   urltest     auto                            → JP-2                        141 ms
   1      vless       US-1                            1.1.1.1:443                   210 ms
   2      vless       JP-2                            2.2.2.2:443                   141 ms
   3      vless       SG-3                            3.3.3.3:443                        -
```

The delay figure is **not a measurement `sc` takes**: it is a value the running sing-box already holds, produced by the group's own probing and read once over the Clash API. It therefore exists only while the group is in use — on a host pinned to a single node the group is idle, probing stops, and the column shows `-` everywhere (or keeps showing the last values it had). `-` means "no stored delay", never "0 ms" and never "unreachable"; with the service stopped `sc` issues no query at all and every cell is `-`.

> **If one of your own nodes is already tagged `auto`**, that host gets **no** auto-select group — two outbounds may not share a tag. `sc use auto` there pins *that node*, so the `Switched to: auto` it prints does **not** mean failover is on. Rename the node and the group appears by itself on the next `sc reload`.

### Switch route mode

```bash
sc mode rule           # rule-based routing (default)
sc mode global         # everything via proxy
sc mode direct         # everything direct
```

The mode lives in the **running** sing-box: its cache file carries the mode across restarts, and nothing `sc` writes to disk can carry it — a mode in `config.json` loses to the cached one anyway. So `sc mode` needs the service up. With sing-box stopped it changes nothing and says so, instead of recording a preference that would never take effect; start it with `sc on` and set the mode again.

### IPv6 name resolution

```bash
sc ipv6 auto           # answer AAAA empty unless this host has a global IPv6 address (default)
sc ipv6 on             # always resolve AAAA normally
sc ipv6 off            # always answer AAAA empty
sc ipv6 show           # print the setting and the decision it produces
```

On a host that cannot use IPv6, an AAAA lookup for a name this config sends to the proxied resolver — in `rule` mode every name outside the table below, in `global` everything but the `hosts` table, in `direct` none at all — still travels there, and while a node accepts the connection but never answers, that lookup produces nothing at all, measured at sing-box's own 10.0 s per-query deadline. Suppression removes that lookup entirely: the generated config answers AAAA (query type 28), and the SVCB / HTTPS types 64 and 65, with an **empty `NOERROR`** locally, asking no resolver at all. `auto` decides it by reading `/proc/net/if_inet6` once — "this host has a global IPv6 address" means an address inside `2000::/3` on an interface that is neither loopback nor `sb-tun`; link-local (`fe80::/10`) and unique-local (`fc00::/7`) addresses never count, and this project's own TUN device is excluded by name because it always carries one. `on` and `off` override that judgment by hand.

The setting is persisted in `/etc/sing-box/settings.json`; an absent key means `auto`, and a value that is none of the three is named on stderr and treated as `auto`. If the address list cannot be read at all, `sc` assumes the host **does** have IPv6 (so nothing becomes unreachable) and says so in one line. `sc ipv6 <value>` regenerates the config and restarts sing-box **only when the effective decision actually changes** — otherwise it says nothing changed and leaves the service alone. `sc ipv6 show` only reports what the setting is and what it decides: it never changes the `ipv6` setting, regenerates no config and touches the service in no way — but, like every command except `sc doctor`, it still runs the ordinary start-up path first, which on a fresh host creates `/etc/sing-box` and `/var/lib/sing-box` and seeds `nodes.json` / `settings.json`, and on **any** host that has not yet recorded a valid Clash API port — a fresh install, or one upgraded from a version that predates the port auto-probe — probes for a free port and writes it into `settings.json`.

The rule that carries this is evaluated **first**, ahead of both routing-mode rules, so it applies in `rule`, `global` and `direct` alike — the modes you switch to when something is already broken — and it references no ruleset, so a host whose `.srs` files are missing still gets it.

**Which names still resolve while every node is unusable** — measured against a node that accepts the connection and then never answers:

| Route mode | Answered without any node | Left unanswered |
|---|---|---|
| `rule` | the names in the built-in `hosts` table, the five domestic suffixes (`alidns.com`, `doh.pub`, `dot.pub`, `360.cn`, `onedns.net`), and every suppressed query type — plus, while the rulesets are usable, the names `geosite-cn` and `geosite-private` match | everything else, foreign names included |
| `global` | the `hosts` table and the suppressed query types only — you asked for everything to go through the proxy | everything else |
| `direct` | everything: in this mode no name is sent to the proxied resolver at all | — |

**With all four rulesets unusable** (the degraded config `sc` already warns about), the `rule` row above shrinks to the `hosts` table, the five domestic suffixes and the suppressed query types; every other name waits for a usable node or for the rulesets to come back. `global`'s row is already shorter than that, and `direct`'s does not depend on the rulesets at all.

**What this does not do.** There is no second resolver and no wait to configure. When the proxied resolver is reached but does not answer, sing-box abandons that query at its own fixed per-query deadline (10.0 s in 1.13.15 — no key this project emits can change it), returns nothing, and consults no one else; the error you finally see comes from your own client's timeout. A `NXDOMAIN` or `SERVFAIL` from the proxied resolver is relayed verbatim, never re-asked elsewhere, so no name is exposed to the domestic resolver as a consequence of a failure. A node whose address resolves only over IPv6 needs `sc ipv6 on`.

### Telemetry name rejection

```bash
sc telemetry block     # answer every listed name "no such domain" locally (the default)
sc telemetry allow     # resolve the listed names normally
sc telemetry show      # print the setting and every name on the list
```

`sc` ships a fixed list of 17 telemetry names. With the setting at `block` — the value of a host that has never set it — a query for a listed name, or for any subdomain of one, is answered by sing-box itself with `NXDOMAIN` and no records, in a few milliseconds, and **no query is sent to any DNS server**. A name is on the list only when **both** clauses hold: its sole function is carrying usage, diagnostic, crash or advertising-identifier data to a vendor, **and** blocking it disables no user-visible function of the product it belongs to. No update, activation, licensing, authentication, push-delivery, CDN-content, captcha or security-feature endpoint qualifies — which is why `analytics.google.com` (it also serves the Analytics console), `omtrdc.net` (Adobe Target delivers page content), `googletagmanager.com`, `settings-win.data.microsoft.com` and the vendors' push hosts are deliberately absent.

Matching is by label boundary: `crashlytics.com` covers that name and every subdomain of it at any depth, in any letter case, and does **not** cover `notcrashlytics.com`.

The setting is persisted in `/etc/sing-box/settings.json`; an absent key means `block`, so a fresh install and a host upgrading to this build behave identically, and a value that is neither `block` nor `allow` is named on stderr and treated as `block`. `sc telemetry <value>` regenerates the config and restarts sing-box **only when the effective setting actually changes** — otherwise it says nothing changed and names `sc reload`, which is what applies the setting to a `config.json` generated before it existed. `sc telemetry show` changes no setting, regenerates nothing and touches the service in no way — but, like every command except `sc doctor`, it still runs the ordinary start-up path first, which on a fresh host creates `/etc/sing-box` and `/var/lib/sing-box` and seeds `nodes.json` / `settings.json`.

The rule that carries the list is evaluated ahead of both routing-mode rules, so **changing the route mode does not lift the rejection**: `sc mode global` and `sc mode direct` change which resolver answers *other* names, never whether a listed name is rejected. It references no ruleset, so a host whose `.srs` files are missing still gets it, and it needs no usable node — a listed name is rejected on a host with no nodes at all.

**The list** — vendor and class for every shipped name; `sc telemetry show` prints the same names on the host itself:

| Name | Vendor | What it carries | Class |
|---|---|---|---|
| `telemetry.microsoft.com` | Microsoft | Windows diagnostics, crash and error reporting | OS diagnostics |
| `vortex.data.microsoft.com` | Microsoft | Windows diagnostic-data upload (DiagTrack) | OS diagnostics |
| `vortex-win.data.microsoft.com` | Microsoft | the Windows-specific sibling of the above | OS diagnostics |
| `metrics.ubuntu.com` | Canonical | the `ubuntu-report` installer / hardware survey | OS diagnostics |
| `daisy.ubuntu.com` | Canonical | whoopsie / Apport crash-report submission | OS diagnostics |
| `incoming.telemetry.mozilla.org` | Mozilla | Firefox telemetry ping submission | Browser telemetry |
| `google-analytics.com` | Google | Google Analytics hit collection | Analytics SDK |
| `app-measurement.com` | Google | Firebase Analytics measurement upload | Analytics SDK |
| `crashlytics.com` | Google | Firebase Crashlytics crash and session reports | Analytics SDK |
| `demdex.net` | Adobe | Experience Cloud ID / Audience Manager | Analytics SDK |
| `scorecardresearch.com` | Comscore | audience-measurement beacons | Analytics SDK |
| `hm.baidu.com` | Baidu | Baidu Tongji (百度统计) web analytics | Domestic analytics SDK |
| `cnzz.com` | Alibaba (Umeng+/CNZZ) | CNZZ web-analytics counters and log collection | Domestic analytics SDK |
| `mmstat.com` | Alibaba | group usage / behaviour beacon logging | Domestic analytics SDK |
| `ulogs.umeng.com` | Alibaba (Umeng) | U-App analytics SDK log upload | Domestic analytics SDK |
| `tracking.miui.com` | Xiaomi | MIUI system usage / analytics upload | Domestic analytics SDK |
| `data.mistat.xiaomi.com` | Xiaomi | MiStat statistics SDK data upload | Domestic analytics SDK |

**A rejection does not look like a broken network.** It arrives in milliseconds and carries an rcode — `status: NXDOMAIN`, `ANSWER: 0`, the `aa` flag set — where a network failure gives you nothing at all until your own client's timeout expires. `dig +nocookie crashlytics.com` is enough to tell the two apart, and `sc telemetry show` tells you whether the name you are chasing is on the list at all.

**If a listed name breaks an application**, there are two ways out and neither needs `bin/sc` edited: `sc telemetry allow` turns the whole list off, or the recipe below restores exactly one name. Both survive `sc reload`.

**Adding your own names, and excepting one of ours.** Both are edits to `/etc/sing-box/override.json` (the **Custom configuration** section below explains how that file works). Both anchor on `{"server": "hosts_dns"}`, the rule that answers from the built-in hosts table: that element is emitted in **both** settings states and in every ruleset state, so an override written today keeps working after `sc telemetry allow`, and `$after` places your rules ahead of ours.

Add names of your own:

```json
{
  "dns": {
    "rules": {
      "$after": {
        "match": { "server": "hosts_dns" },
        "values": [
          { "action": "predefined", "rcode": "NXDOMAIN",
            "domain_suffix": ["tracker.example.com", "beacon.example.net"] }
        ]
      }
    }
  }
}
```

Except one of ours — this one resolves `hm.baidu.com` normally while the other 16 stay rejected. Use `direct_dns` for a name that should be resolved domestically and `remote_dns` for one that should be resolved abroad:

```json
{
  "dns": {
    "rules": {
      "$after": {
        "match": { "server": "hosts_dns" },
        "values": [
          { "server": "direct_dns", "domain_suffix": ["hm.baidu.com"] }
        ]
      }
    }
  }
}
```

**There is only one `override.json`, and one array takes only one directive.** The two recipes above cannot be two separate files, and they cannot be two directives (`$after` and `$before`) in the same `dns.rules` object — that is refused with `$after cannot be combined with other keys in the same object`. If you want both, put both rules inside the **one** directive, the exception first so it is matched first:

```json
{
  "dns": {
    "rules": {
      "$after": {
        "match": { "server": "hosts_dns" },
        "values": [
          { "server": "direct_dns", "domain_suffix": ["hm.baidu.com"] },
          { "action": "predefined", "rcode": "NXDOMAIN",
            "domain_suffix": ["tracker.example.com"] }
        ]
      }
    }
  }
}
```

**What this does not do.** It matches **names**, and only names that reach this config's DNS rules. An application that ships its own DoH/DoT resolver, or that connects to a hard-coded IP address, is unaffected by any of this — nothing here blocks anything at the IP or the route layer, and nothing here inspects traffic. The list is fixed in `bin/sc` and never updates itself; `sc telemetry allow` and the recipes above are how you change what it does on your host.

### Service control

```bash
sc on                  # start + enable on boot
sc off                 # stop + disable on boot
sc status              # service status, TUN interface, rule-set status + age, current node, egress IP
sc doctor              # one-pass read-only health report (see below)
sc log -f              # follow logs in real time
```

### Diagnose the install

```bash
sc doctor
```

One pass, one screen, nine facts — printed in **causal order**, so every cause appears above the effects it can produce:

| # | Section | What it reports |
|---|---|---|
| 1 | sing-box binary | the resolved path of the binary and its version |
| 2 | Rule-sets | one row per `.srs`: usable / missing / not a rule-set file / too small / unreadable, the byte count from that same read, and how long ago the file was written — a usable rule-set older than 60 days is reported as a problem naming `sc update-rules` |
| 3 | Configuration | whether `config.json` exists, whether it is still what `sc` last generated, and what `sing-box check` says about it |
| 4 | IPv6 (AAAA) | this host's effective AAAA decision, and whether the `config.json` on disk carries that decision as the first `dns.rules` entry |
| 5 | Service | running now, and registered to start at boot — two separate facts |
| 6 | TUN interface | whether `sb-tun` exists, and its addresses |
| 7 | Clash API | the port recorded in `settings.json`, whether it answers, how many of your nodes carry a stored delay and which outbound auto-select is on right now, and one name lookup answered by the running sing-box — which may answer it from its own DNS cache — with the time that took |
| 8 | Egress IP | the observed public address (queried even when the service is down) |
| 9 | File permissions | any **credential** file directly inside `/etc/sing-box` that grants access to group or other (`settings.json` is excluded — it carries no credential), and whether the directory itself is group- or other-writable — each offending path named with its mode and the command that narrows it |

Every row is marked `[OK]`, `[PROBLEM]` or `[UNKNOWN]` (`[正常]` / `[异常]` / `[未知]` under `sc lang zh`), so `sc doctor | grep '^\[PROBLEM\]'` lists exactly what is wrong. `[UNKNOWN]` means the check could not run at all — a missing tool, a permission denial — never "the thing being checked is broken". One failing check never ends the run: all nine sections are always printed.

**`sc doctor` changes nothing.** It writes no config, downloads nothing, and never starts, stops, restarts, enables or repairs anything. Unlike every other subcommand it does not even create `/etc/sing-box` or persist a Clash API port on first run — on a broken or fresh machine the emptiness of those paths is often the diagnosis, and a diagnostic must not destroy the evidence it was run to collect. The one thing it asks of the outside world is section 7's name lookup: the command itself still touches no path, but the resolution is performed *by the running sing-box*, which may record it in its own DNS cache (`/var/lib/sing-box/cache.db`) exactly as it would any other query — and may equally answer a later query from that cache, which is why the row names the cache as a possible source rather than claiming the name was resolved upstream on this query. It is safe to run repeatedly, concurrently, and as the very first thing after a failure.

Exit status:

| Exit | Meaning |
|---|---|
| `0` | every section OK |
| `1` | at least one `[PROBLEM]` — any section: a missing binary, an unusable or stale rule-set, a `config.json` changed outside `sc`, a failed config check, an AAAA decision the document does not carry first, a stopped or non-autostarting service, a missing TUN device, an unanswered Clash API port, no node carrying a stored delay, a name lookup that produced no answer, a failed egress query, a credential file or a configuration directory open to group or other |
| `2` | no `[PROBLEM]`, but at least one `[UNKNOWN]` — a check could not run: no sing-box binary to check the config with, no record of what `sc` last generated, no init system detected, `ip` missing, no Clash API port recorded in `settings.json` (which also leaves the node-delay and DNS rows unprobed), a `nodes.json` that cannot be read, or a configuration directory that is absent or cannot be listed |

### Show the configuration

```bash
sc config
```

Prints `/etc/sing-box/config.json` — the document sing-box is actually running — with every node credential masked. Redaction is unconditional: no flag, setting or environment variable prints an unmasked value, because `sc` runs under a password-less `sudo` rule scoped to itself, so an opt-out would turn a root-only read of a `0600` credential file into a password-free one. The unredacted document stays reachable exactly one way: reading the file as root.

What is masked:

- **Inside `outbounds`, at every depth**: every key that is not in the **visible key set** — `type`, `tag`, `server`, `server_port`, `detour`, the transport / TLS / Reality / obfs fields and the protocol-tuning and auto-select-group settings. So `uuid`, `password`, `public_key` and `short_id` are masked, and so is any key `sc` never emits, including one introduced by an outbound you added through `override.json` or by a future sing-box version.
- **Everywhere in the document**: `password`, `uuid`, `secret`, `token`, `private_key`, `pre_shared_key`.

A masked value is always the same literal, `******`. Only the **value** is replaced — the key stays — so which fields are configured stays visible while their contents do not.

The document goes to **stdout** and everything `sc` says about it goes to **stderr**, so `sc config > current.json` yields a JSON document a parser accepts — whenever stdout's encoding can represent that document — and `sc config | grep -n server_name` works. On a stdout that cannot represent it (a non-UTF-8 locale, or `PYTHONIOENCODING` set to a narrower codec), a character `sc` cannot encode is written as a backslash escape rather than ending the run: the whole masked document still reaches stdout and the command still exits `0`. Which escape appears is decided by the character — `\xNN` for one in the Latin-1 range, `\uNNNN` for one elsewhere in the BMP (the CJK case), `\UNNNNNNNN` for one above the BMP — and of those three **only `\uNNNN` is a JSON escape**. A saved file whose escapes are all of that form is therefore still valid JSON; one carrying a `\xNN` or a `\UNNNNNNNN` is not. In every case, running the command under a UTF-8 stdout is what gets you the document unescaped. The stderr notes give the file's absolute path, state that credentials are masked, and — when a drift record exists — say whether the document on disk is what `sc` last generated or has been changed since.

**`sc config` writes nothing.** No file is created, modified or removed anywhere, not even `/etc/sing-box` itself on a host that does not have it; it downloads nothing, starts nothing, touches no service, and forms no opinion about whether the configuration is *valid* — that is `sc doctor`'s answer.

**The limit.** The mask covers the credentials `sc` itself writes. A secret you place in your own `/etc/sing-box/override.json` **outside** the `outbounds` array, under a key that is not one of the six names above — an inbound user's `auth_token`, say — is printed verbatim. Check your own override before pasting the output anywhere.

### Ruleset update

```bash
sc update-rules                       # update once now
sc update-rules --mirror <base-url>   # force a specific mirror (repeatable)
sc update-interval daily              # update every day
sc update-interval weekly             # update every week (default)
sc update-interval 'Mon *-*-* 04:00:00'   # every Monday at 04:00
sc update-interval show               # show current cadence + next run
```

`sc update-rules` tries several mirrors in order (jsDelivr → testingcf → ghfast → raw.githubusercontent) and validates every download before installing it, so a truncated body or an HTML error page is never written to `/etc/sing-box/rules/`. Progress is shown while downloading on a terminal; redirected output keeps one completion line per ruleset.

`--mirror` **replaces** the built-in mirror list (it does not fall back to it), is repeatable, and one value may hold several whitespace-separated URLs. The `SB_RULES_BASE="<url> [url...]"` environment variable does the same, but only when `sc` already runs as root (the systemd timer, a root shell) — from a normal shell `sc` re-execs itself through `sudo`, whose default `env_reset` drops the variable. Prefer `--mirror`.

**A ruleset that cannot be downloaded is no longer fatal.** The generated config drops that ruleset and every routing rule referencing it, warns which ones are unusable and why, and the service still starts — you lose routing granularity, not connectivity. Run `sc update-rules` (or `sc reload` once the files are in place) and the full rules come back automatically.

### Switch CLI language

```bash
sc lang en   # English
sc lang zh   # 简体中文
```

The setting is persisted in `/etc/sing-box/settings.json` and applies to all subsequent `sc` output (errors, status, help).

### Full command list

```bash
sc help
```

## 🏗 Architecture

```
boot
  └─ systemd starts sing-box (root)
       ├─ reads /etc/sing-box/config.json
       ├─ creates the sb-tun interface (172.19.0.1/30)
       ├─ connects to nodes directly (no user login required)
       └─ loads local .srs rulesets
              ↓
       all system traffic through the proxy (incl. SSH pre-login, GDM login screen)

User runs the sc CLI:
  └─ edits /etc/sing-box/nodes.json or settings.json
       └─ regenerates config.json
            └─ Clash API tells sing-box to apply changes (no restart)
```

## 📂 File locations

| Purpose | Path |
|---|---|
| sing-box binary | `/usr/local/bin/sing-box` |
| sc CLI | `/usr/local/bin/sc` |
| sing-box config (auto-generated) | `/etc/sing-box/config.json` (mode 600) |
| Node list (with credentials) | `/etc/sing-box/nodes.json` (mode 600) |
| Settings | `/etc/sing-box/settings.json` |
| Your own config overrides (optional, yours) | `/etc/sing-box/override.json` |
| Record of what `sc` last generated (internal) | `/etc/sing-box/.config.sha256` |
| Rulesets | `/etc/sing-box/rules/*.srs` |
| systemd service | `/etc/systemd/system/sing-box.service` (systemd only) |
| Auto-update timer | `/etc/systemd/system/sing-box-rules-update.timer` (systemd only) |
| Auto-update cadence override | `/etc/systemd/system/sing-box-rules-update.timer.d/override.conf` (systemd only) |
| OpenRC service | `/etc/init.d/sing-box` (OpenRC/Alpine only) |
| Periodic update scripts | `/etc/periodic/{daily,weekly,monthly}/singbox-update-rules` (OpenRC/Alpine only) |
| Password-less sudo | `/etc/sudoers.d/sc` |
| Uninstall script | `/usr/local/lib/singbox-cli/uninstall.sh` |
| Logs | `journalctl -u sing-box` or `sc log` (systemd); `sc log` reads `/var/log/sing-box/` on OpenRC |

## 🛠 Custom configuration (`override.json`)

`config.json` is **generated**: `sc reload`, `sc add` and `sc rm` rewrite it from scratch every time, and `sc use` and `sc update-rules` may do so as well, so anything you hand-edit there is discarded without a word. Put your changes in `/etc/sing-box/override.json` instead. `sc` never creates, writes or deletes that file, and applies it **last** — over everything `sc` composes — so it survives every regeneration and survives re-running `install.sh`.

An override that is absent, empty, or `{}` changes nothing. One that cannot be applied stops the command **before anything is written**: `config.json` is left exactly as it was, the running service is not touched, and the message names the file and the problem.

**Objects merge by depth.** A key you do not mention keeps its value and its position:

```json
{ "log": { "level": "debug" } }
```

→ only `log.level` changes; every other key of `log`, and its position, stays as it was.

**Arrays change only under an explicit directive**, because "add one DNS rule" and "replace every DNS rule" must never look the same:

| Directive | Effect |
|---|---|
| `$replace` | the array becomes exactly the value you give |
| `$prepend` | your elements go in front of the existing ones |
| `$append` | your elements go after the existing ones |
| `$before` | your elements go immediately before the element matched by `match` |
| `$after` | your elements go immediately after the element matched by `match` |

`$before` / `$after` take `{"match": {…}, "values": […]}`. `match` selects by subset equality — every key/value in it must equal the element's — and must match **exactly one** element; zero or several is an error, never a silent no-op. Anchors rather than numeric indices, because sing-box evaluates `dns.rules` and `route.rules` in order and an index is wrong the moment anything inserts earlier.

A key whose current value is an array therefore accepts **only** a directive object: an object, a scalar, `null` or a bare array written there is an error naming the five directives, never a silent replacement. To empty an array, use `$replace` with `[]`.

Example — insert an AAAA-suppressing DNS rule immediately after the `clash_mode: Direct` rule:

```json
{
  "dns": {
    "rules": {
      "$after": {
        "match": { "clash_mode": "Direct" },
        "values": [
          { "action": "predefined", "rcode": "NOERROR", "query_type": [28] }
        ]
      }
    }
  }
}
```

Values you insert are copied verbatim: nothing inside them is re-interpreted, so an inserted rule carrying its own `rule_set` or `domain_suffix` array is emitted exactly as written. A bare array where the generated config already has one is refused with a message naming the directives; a bare array at a key the generated config does not have is simply accepted and creates it.

> **`sc` depends on parts of the config it generates.** Removing `experimental.clash_api.external_controller`, or renaming the `proxy` outbound, yields a file `sing-box check` still accepts while `sc use` and `sc status` stop working. `sc` does not stop you — it is your file.

**If you already hand-edited `config.json`**, the next command that regenerates it prints one line on stderr: that the file was changed outside `sc`, that the change is about to be replaced, and where to put it so it lasts. The comparison is against `/etc/sing-box/.config.sha256`, a digest of what `sc` last wrote; a host that has never run this version has no record yet, so nothing is printed until after its first regeneration.

## 🗑 Uninstall

Pick any:

```bash
sc uninstall                                                                                          # easiest, on installed systems
sudo ./uninstall.sh                                                                                   # in the repo dir
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)" # one-line remote
```

This wipes the service unit, `/etc/sing-box/` (incl. nodes), `/var/lib/sing-box/`, `/var/log/sing-box/`, sudoers, `/usr/local/bin/sc`, `/usr/local/lib/singbox-cli/`. Then it asks whether to also remove the sing-box binary — answer `y` for **truly zero residue**.

## ⚠️ Security notes

- `nodes.json` contains node credentials/UUIDs, mode 600, root-only readable.
- `config.json` is generated from `nodes.json` and embeds the same credentials, so it is mode 600 too. Both are written to a fresh file that is already mode 600 before its first byte, then moved into place, so neither is ever readable by anyone but root — not even for the instant it is being written. One consequence: `sing-box check -c /etc/sing-box/config.json` now needs root, as it should.
- `sc` uses sudoers NOPASSWD, scoped to `/usr/local/bin/sc` only.
- `sc` is owned by root, regular users cannot modify it, so NOPASSWD cannot be bypassed.
- For multi-user machines, consider switching NOPASSWD back to password-required.

## 🤝 Contributing

PRs welcome. Top priorities:

- [ ] Subscription link auto-update
- [x] urltest support beyond selector (auto-pick the fastest node)
- [x] RHEL / Fedora / Arch family support
- [ ] `sc ping` for node latency testing
- [ ] Node import/export (JSON backup)

## 📄 License

MIT — see [LICENSE](LICENSE).
