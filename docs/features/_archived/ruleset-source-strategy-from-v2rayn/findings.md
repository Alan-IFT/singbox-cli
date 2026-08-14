# Findings: rule-set source strategy, measured against v2rayN — T-21

> Explore mode. This document decides; it ships no code. Every URL, repo path, host and byte count
> below was fetched or measured first-hand on 2026-08-14 from this host, through the live tunnel.

## Answer

**Do nothing to the source list. Decline all three proposals.** Two of the three rest on premises
that are false, and the third is a routing-behaviour switch wearing a mirror's clothes.

| # | Question | Verdict | One-line reason |
|---|---|---|---|
| Q1 | Add GitHub **Releases** assets as a base | **DECLINE — premise refuted twice** | No `.srs` exists as a Release asset anywhere (4 publishers checked); and Releases are served from the **same Fastly IP** as `raw.githubusercontent.com`, so it is not a second CDN |
| Q2 | Mirror the rules into a repo **we control** | **DEFER — trigger: a content complaint, never an availability one** | v2rayN's own mirror is a fork served from a **single** un-mirrored raw URL — strictly worse availability than our four bases; a mirror buys curation, and we have no curation complaint on record |
| Q3 | User-selectable **source sets** | **DECLINE as a `sc` feature — the capability already exists with zero code** | sing-box 1.13.15 accepts `rule_set` `type: remote`, so T-14's `override.json` already expresses any source set; and the candidate sets' `geosite-cn` differ **17-fold in size**, so a one-word selector would silently change routing |
| Q4 | Rule downloads via **proxy** or **direct** | **DECLINE the switch — we already implement v2rayN's actual policy, with zero code** | Measured: every base is routed `rule=final` -> `proxy` today; and `install.sh:567` fetches **before** the service starts at `:593`, so a fresh install fetches direct. "Proxy if up, else direct" — exactly what v2rayN's `GetWebProxy` computes in code |

Net recommended change to `bin/sc`: **none**. Three ledger rows and one insight fall out of this;
they are listed under "Rows filed".

## Method and safety

- All network probes ran as ordinary `curl` / `python3` invocations writing only into the session
  scratchpad. `bin/sc` was **never imported or executed** (insight 2026-08-01: `_init_files()`
  hard-codes `/var/lib/sing-box`, so a repointed harness still writes the real path).
- Nothing under `/etc/sing-box/` or `/var/lib/sing-box` was written; no service action was taken.
  The live service was witnessed with `systemctl show -p MainPID -p ActiveEnterTimestamp`:
  `MainPID=2566751`, `ActiveEnterTimestamp=Tue 2026-08-11 12:13:57 CST`, unchanged throughout.
- `/etc/sing-box/config.json` is unreadable to this agent (0600, root; `sudo` needs a password on
  this host), so the emitted-document facts below are read from `bin/sc`'s `CONFIG_BASE`
  (`bin/sc:1264-1284`) and corroborated live through the Clash API, not from the file.
- Timings are **total wall clock per attempt** as reported by `curl -w %{time_total}` (insight
  2026-08-14: a `timeout=N` argument bounds a socket operation, not a call, so a claimed timeout is
  not admissible evidence — only an observed elapsed time is).

## Premise audit

The brief required every premise to be checked first-hand. Seven were; three failed, one is half true.

| Premise (source: `BATCH_PLAN.md` Notes "v2rayN研究 2026-08-01" / the goal sentence) | Verdict |
|---|---|
| v2rayN pulls `.dat` from `/releases/latest/download/{0}.dat` | **TRUE** — `Global.cs:8` |
| Release assets are "served by a different CDN than `raw.githubusercontent.com`" | **FALSE** — same Fastly edge, same anycast IP (E5) |
| A Releases path exists for the rule-sets *this project* consumes | **FALSE** — no publisher ships `.srs` as a Release asset (E1, E3) |
| v2rayN's `.srs` come from `2dust/sing-box-rules`, "a repo they control" | **TRUE but weaker than described** — it is a *fork* of `lyc8503/sing-box-rules`, fetched from a **single** raw URL with no mirror list (E6, E13) |
| v2rayN's downloader has "no retry, no fallback, no checksum" | **TRUE on fallback and checksum; imprecise on retry** — `DownloaderHelper.cs:159` sets `MaxTryAgainOnFailure = 2` (E12) |
| v2rayN "downloads THROUGH the local proxy" | **TRUE but conditional, and that condition is the whole answer** — `GetWebProxy` returns `null` (direct) when the local socks port is not listening (E11) |
| Selectable source sets "compose with T-14's override layer" | **HALF FALSE** — T-14 composes the *emitted config document*; the base list is a download-time constant reachable only by `--mirror` / `SB_RULES_BASE`. The part that is true is better than described: sing-box's own `type: remote` rule-set makes the override layer sufficient **without** any `sc` feature (E15) |

## Q1 — GitHub Releases assets as a base

**Verdict: DECLINE. The premise is refuted twice over, so there is no proposal left to cost.**

**E1 — there is no `.srs` release asset upstream.** `MetaCubeX/meta-rules-dat` has exactly one
release, tag `latest`, published `2026-08-13T23:12:35Z`, with **28 assets**: `geoip.dat`,
`geosite.dat`, `geoip.db`, `geosite.db`, `geoip.metadb`, `country.mmdb`, `GeoLite2-ASN.mmdb`,
`BundleMRS.7z`, and a `.sha256sum` beside each. **Zero `.srs`.** There is no `BundleSRS`. The four
files this project installs (`geoip/cn.srs`, `geosite/cn.srs`, `geosite/google.srs`,
`geosite/private.srs`, `bin/sc:106-111`) exist only on the **`sing` branch**, whose head commit is
`2026-08-13T23:13:03Z` ("Released on 2026-08-14 07:09") — i.e. the branch and the release are
published by the same job, minutes apart, and the branch carries the format we need.

**E3 — this is universal, not a MetaCubeX quirk.** Same check against every other publisher in play:
`SagerNet/sing-geosite` (11 releases) ships `geosite.db` + `geosite-cn.db` + sha256sums;
`SagerNet/sing-geoip` (4 releases) ships `geoip.db` + `geoip-cn.db`; `2dust/sing-box-rules`
(30 releases, newest `20260814015319`) ships `geoip.db`, `geoip-cn.db`, `geosite.db`. **No publisher
ships per-list `.srs` as a release asset.** `.srs` is a per-list artifact — 3 790 files on the 2dust
geosite branch, 518 on its geoip branch — which is a git-branch shape, not a release-asset shape.

**E4 — the `.db` assets that *are* published cannot be used.** Tested against the installed binary
with a bogus-key negative control and a positive control:

```
$ sing-box check -c t_geosite.json     # route.geosite + route.geoip + a geosite rule
FATAL initialize router: parse rule[0]: geosite database is deprecated in sing-box 1.8.0
      and removed in sing-box 1.12.0
$ sing-box check -c t_ctrl.json        # control: route.bogus_key_control
FATAL decode config: route.bogus_key_control: json: unknown field "bogus_key_control"
$ sing-box check -c t_ok.json          # positive control
exit=0
```

The control matters: `route.geosite` is *decoded* (it is a known field) and then rejected at router
init, whereas an invented key dies at decode. So the rejection is a deliberate removal, on
`sing-box version 1.13.15` — the binary installed on this host.

**E5 — and the "different CDN" claim is false anyway.** Following a real release download:

```
final_url = https://release-assets.githubusercontent.com/github-production-release-asset/...
            ?sp=r&se=2026-08-14T15:18:24Z&sig=...&jwt=...        (signed, ~1 h expiry)
remote_ip = 185.199.108.133      http=200   size=206529   time_total=2.607
headers   : via: 1.1 varnish, 1.1 varnish - x-served-by: cache-iad-..., cache-hhr-...
            server: Windows-Azure-Blob/1.0 (origin)
```

`185.199.108.133` is one of the four addresses `raw.githubusercontent.com` resolves to on this host
(`185.199.108/109/110/111.133`). Release assets and raw content share the **same Fastly anycast
edge**; only the origin behind it differs. A network that blackholes `raw.githubusercontent.com` by
address blackholes release assets with it. What the Releases path adds instead is a `github.com`
302 hop and a signed, time-limited URL: 2.6 s for 206 KB against **1.39-1.54 s for 447 KB** from
base 4 (E7).

**Failure-domain arithmetic (E8), which is the real answer to "does a fifth base help".** During the
timing runs, `cdn.jsdelivr.net` and `testingcf.jsdelivr.net` both landed on `104.17.207.5` /
`104.17.208.5` — the same Cloudflare edge pair. Today's four bases therefore span **three**
independent failure domains: Cloudflare (bases 1+2), `ghfast.top` `107.175.190.200` (base 3), Fastly
`185.199.10x.133` (base 4). A Releases base would be a fifth URL inside a domain base 4 already
covers — **zero** added independence.

**Ongoing cost had we adopted:** a signed-URL redirect path to keep working, `latest`-tag semantics
to track, and a fifth entry in a list whose failures `_ruleset_bases` must keep explaining. Bought:
nothing measurable.

## Q2 — a mirror repository this project controls

**Verdict: DEFER, with an explicit trigger.** Reopen only on a **content** complaint about
MetaCubeX's rules (wrong, stale, or withdrawn), never on an availability complaint — availability is
already covered and a mirror would make it worse before it made it better.

**E6 — v2rayN's mirror is not the availability win it looks like.** `Global.cs:9` reads

```csharp
public const string SingboxRulesetUrl =
    @"https://raw.githubusercontent.com/2dust/sing-box-rules/rule-set-{0}/{1}.srs";
```

One base. `raw.githubusercontent.com`. No CDN in front, no mirror list, no fallback — the very host
our base list keeps in **last** place. And `2dust/sing-box-rules` is a **fork of
`lyc8503/sing-box-rules`** (GitHub API `parent`/`source`), so "a repo they control" means content
control, not delivery control. On the axis Q2 is usually argued (reachability from a restricted
network) their design is strictly weaker than ours.

**E7 — we have no availability problem to solve.** 4 bases x 2 files x 3 rounds = **24 fetches,
24/24 HTTP 200**, every body carrying the `SRS` magic, and `geosite/cn.srs` **447 412 bytes,
byte-count identical from all four bases**. Wall clock for the 447 KB file: base 1 1.42-1.64 s,
base 2 1.36-1.84 s, base 3 1.83-2.33 s, base 4 1.39-1.54 s. For the 696-byte file, 0.66-1.38 s
(latency-dominated). The slowest base beats the Releases hop in E5.

**Ongoing cost, stated plainly because this is the verdict most likely to be overturned later.** A
mirror is not a change, it is a **standing obligation**: a scheduled job that re-publishes four
files forever, plus the CI credentials, plus somebody noticing when it stops. 2dust's fork commits
**daily** (`rule-set-geosite` head `2026-08-14T01:53:16Z`, "Update rule-set") — that is the cadence
this costs. And it interacts badly with what this batch just shipped: T-19 reports rule-set **age**
and T-20 makes it a `sc doctor` conclusion, so after a mirror those numbers would measure *our
mirror's lag*, not the upstream's freshness, and a stalled job would present as healthy files that
are quietly months old. Availability is bought more cheaply by a base list (already shipped) and
freshness is bought most cheaply by not standing between the user and the publisher.

**Also on the cost side:** jsDelivr fronts **any** GitHub repo, verified —
`https://cdn.jsdelivr.net/gh/2dust/sing-box-rules@rule-set-geosite/geosite-cn.srs` returns 200 /
527 715 bytes. Whatever CDN benefit a repo of ours would enjoy is already available for any repo we
might point at, without owning one.

## Q3 — user-selectable source sets

**Verdict: DECLINE as a `sc` feature.** The capability a user actually wants already exists, in
sing-box, reachable through T-14's override, at a cost of zero lines in `bin/sc`.

**E15 — the zero-code path, verified against the installed binary with a bogus-key control:**

```json
{"route": {"rule_set": [{"tag": "geosite-cn-alt", "type": "remote", "format": "binary",
   "url": "https://raw.githubusercontent.com/2dust/sing-box-rules/rule-set-geosite/geosite-cn.srs",
   "download_detour": "direct", "update_interval": "7d"}]}}
```

`sing-box check` exits **0** on this; the same object with an added `bogus_rs_key` dies at decode
(`route.rule_set[0].bogus_rs_key: json: unknown field`), so the acceptance is real and not the
decoder shrugging. A user who wants the Loyalsoldier-derived set, the russia set, the Iran set, or
any private one writes it into `/etc/sing-box/override.json` — T-14's layer, applied last — and gets
per-rule-set source **and** per-rule-set egress (`download_detour`) as sing-box's own feature.
Rule 85's tie-break is not close: data in a file the user already owns beats a new selector, a new
settings key, and a new compatibility matrix in `sc`.

**E13 — what the matrix would have cost, measured.** The three sets v2rayN offers disagree on
layout, on ref structure, and on naming, all at once (`Global.cs:184-185`):

| Set | URL shape for the four files we install |
|---|---|
| 2dust | `raw.../2dust/sing-box-rules/`**`rule-set-geoip`**`/geoip-cn.srs` and `.../`**`rule-set-geosite`**`/geosite-cn.srs` — two **branches** |
| russia (runetfreedom) | `raw.../russia-v2ray-rules-dat/release/`**`sing-box`**`/rule-set-{geoip,geosite}/...` — one branch, extra path segment |
| Iran (chocolate4u) | `raw.../Iran-sing-box-rules/`**`rule-set`**`/geosite-cn.srs` — one **flat** directory; v2rayN's format string discards its `{0}` argument for this one |

All four names resolve in all three sets (12/12 HTTP 200), so a naive selector would *appear* to
work. But `bin/sc` joins `base + "/" + relpath` with the ref embedded in the base for jsDelivr
(`.../gh/OWNER/REPO@REF/...`), and 2dust splits geoip and geosite across two refs — so mirroring
even *one* alternate set through jsDelivr requires the base to become **per-file**, not per-run.
That is a change to `RULESET_BASES`/`RULESET_FILES`' shape, i.e. to the seam T-02 deliberately made
singular.

**E14 — and the selector would be mislabelled.** `geosite-cn.srs` across the four sources:

| Source | bytes |
|---|---|
| MetaCubeX (current) | 447 412 |
| 2dust (Loyalsoldier-derived) | 527 715 |
| russia (runetfreedom) | **25 413** |
| Iran (chocolate4u) | 40 472 |

The russia set's `geosite-cn` is **5.7 %** the size of ours. In this project's default config
`geosite-cn -> direct` (`bin/sc:1280`) and `geosite-cn -> direct_dns` (`:1253`), so "choose a source
set" would silently move most Chinese traffic from direct to proxy. That is a **routing decision**
presented as a mirror preference. An override file that names the URL is the honest surface for it,
because the user is choosing rules, not choosing a download server.

**One consequence to record rather than fix:** rule-sets adopted via `type: remote` live in
sing-box's `cache_file`, outside `sc`'s `.srs` model — so T-02's validity judgment, T-19's age
reporting and T-20's doctor row do not see them. That is the honest trade of the zero-code path and
belongs in the README sentence filed as **R-55**, not in new machinery.

## Q4 — proxy or direct (the point the pool said to settle by measurement)

**Verdict: DECLINE any switch. Measurement shows we already implement the policy v2rayN implements
in code, and we implement it with no code at all.**

**E9 — what happens today, observed rather than reasoned.** Polling the Clash API's `/connections`
(`127.0.0.1:29090`, read-only) while fetching `geosite/cn.srs` from each base in turn:

```
host=cdn.jsdelivr.net        dstIP=104.17.207.5     chains=[<node>, proxy]  rule=final
host=testingcf.jsdelivr.net  dstIP=104.17.208.5     chains=[<node>, proxy]  rule=final
host=ghfast.top              dstIP=107.175.190.200  chains=[<node>, proxy]  rule=final
host=raw.githubusercontent   dstIP=185.199.110.133  chains=[<node>, proxy]  rule=final
```

`rule=final` is sing-box's own record of *why*: no route rule matches these hosts, so
`route.final = "proxy"` applies (`bin/sc:1283`). Rule-set downloads on a running host **already go
through the proxy**, exactly as v2rayN does — not by a downloader decision but because the TUN
captures locally-originated traffic (`ip rule` 9003 -> table 2022 -> `default via 172.19.0.2 dev
sb-tun`) and `sc` is not the one process exempted (`{"outbound": "direct", "process_name":
["sing-box"]}`, `bin/sc:1268`).

**E10 — and the other arm is already right too.** `install.sh:567` runs
`/usr/local/bin/sc update-rules` at step 6; `systemctl start sing-box` is line **593**, step 7. On a
fresh install there is no tunnel yet, so that fetch is necessarily **direct**. The same holds for
any recovery run on a host whose service is down — which is the state `sc update-rules` exists to
repair.

**E11 — that is precisely v2rayN's policy, written out longhand.** `DownloadService.cs:244-256`:

```csharp
private async Task<WebProxy?> GetWebProxy(bool blProxy) {
    if (!blProxy) return null;
    var port = AppManager.Instance.GetLocalPort(EInboundProtocol.socks);
    if (await SocketCheck(Global.Loopback, port) == false) return null;   // falls back to direct
    return new WebProxy($"socks5://{Global.Loopback}:{port}");
}
```

and the geo/srs call site passes `blProxy: true` (`UpdateService.cs:551`). So v2rayN is
"**proxy if the local proxy is actually listening, else direct**" — a socket probe plus a branch. We
get the identical policy from the routing table for free. Adding a `--direct` flag or a bypass rule
would not add a capability; it would add a way to pin the wrong arm, and pinning `direct` re-creates
the exact failure that started this batch (a host that cannot reach `raw.githubusercontent.com`).

**What I could not measure here, named per the R-31/R-41/R-47 discipline.** I did **not** measure the
direct arm's latency and success on this network. All locally-originated traffic is policy-routed
into `sb-tun` (`ip rule` 9000-9010, verified), so forcing a direct fetch requires either switching
`clash_mode` or adding a route rule — both mutations of the live tunnel, which the brief classifies
as a defect rather than data. **The measurement, named:** on a host where the tunnel can be stopped,
fetch all four bases with the service down and again with it up, and compare success rate and wall
clock. It is not load-bearing for this verdict — the verdict is "change nothing", and the
change-nothing arm is the one that was measured — but it is the evidence anyone proposing a
`direct` default would owe.

## Implications for our project

- **v2rayN is behind us on this axis, and the roadmap framing survives the check.** Verified at
  master: `DownloadGeoFile` ends `File.Copy(tmpFileName, targetPath, true)` (`UpdateService.cs:531`)
  — overwrite regardless of content, no magic check, no size check, no checksum, one URL. We
  validate (`SRS` magic + 16-byte floor + Content-Length equality), fall back across four bases,
  replace atomically and mark dead bases per run. One correction to the record:
  `DownloaderHelper.cs:159` does set `MaxTryAgainOnFailure = 2`, so "no retry" was imprecise — it is
  transport-level retry against the *same* URL, which is not fallback.
- **One thing v2rayN does that we structurally cannot copy, and should not want to.** Its `.srs` set
  is *derived from the user's own routing and DNS rules* (`UpdateSrsFileAll` walks `RoutingItems`
  and the sing-box DNS document, then appends `["google","cn","geolocation-cn","category-ads-all"]`).
  Ours is a fixed four, and the config that consumes them is composed by `sc`. Deriving the download
  set from the emitted document is the only genuinely interesting idea in their update path — and it
  is worth **nothing** here until a user can add rule-sets, which is Q3's `type: remote` answer.
- **The base list's real weak point is not its length.** Bases 1 and 2 share a failure domain (E8).
  If anyone ever wants to strengthen the list it is a one-word data change to base 2, not a fifth
  base — filed as **R-53**, not proposed here, because 24/24 gives no evidence it is needed.
- **`--mirror` still accepts any scheme, `file://` included** (T-02 follow-up 3,
  `docs/tasks-archive.md`). Untouched today because `--mirror` is a root-only flag; it would become a
  real surface the moment a *user-facing* source selector existed. Another line in Q3's decline column.

## Rows filed (not built)

- **R-53** — bases 1 and 2 resolve to the same Cloudflare edge; the four-base list spans three
  failure domains, not four. Observation, unassigned; a one-entry data change if ever wanted.
- **R-54** — **R-16 re-homed.** T-21 was one of R-16's four candidate owners (the merge has no
  type-mismatch vocabulary: a bare object silently replaces an array). An `explore` task ships no
  code and therefore **cannot** claim it. R-16 stays open with T-15/T-16/T-17 having passed and T-21
  now formally declined as owner: the next task that needs the vocabulary owns it.
- **R-55** — two sentences the README owes users, both established here: rule-set downloads follow
  the host's routing (tunnelled when the service is up, direct at install time), and an alternate
  rule source is expressible today as a `type: remote` entry in `override.json` — with the caveat
  that such rule-sets sit outside `sc`'s validity, age and doctor reporting. Owner: next task
  touching the README rule-set section.

No `BATCH_PLAN.md` task row is filed. The findings recommend no code, and manufacturing a row to
justify the research would be the failure mode the brief named.

## Recommended next step

**Abandon Q1 outright** (its premise is refuted, and it cannot be revived without a publisher
changing what it ships). **Hold Q2 against its trigger.** **Answer Q3 with documentation, not a
feature** (R-55). **Change nothing about download egress.** The rule-set source strategy this
project already has is the one it should keep.
