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
- **Chinese-friendly UI**: all CLI output and help text is in Simplified Chinese (English/i18n contributions welcome).

## 🛠 Requirements

- Debian / Ubuntu (other systemd + apt distros may work but are untested)
- Python 3.6+ (preinstalled on most distros)
- root (one-time sudoers setup, password-less afterwards)

## 🚀 Install

One line:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

The installer will:

1. Add the official sing-box APT source and install the sing-box core
2. Install the `sc` CLI to `/usr/local/bin/`
3. Create the systemd service + ruleset auto-update timer
4. Configure password-less sudo (scoped to the `sc` command only)
5. Download `.srs` rulesets
6. Start sing-box and enable boot autostart

### Upgrade

Re-run the same one-liner. `install.sh` is idempotent: it overwrites the `sc` binary and systemd units but **leaves `nodes.json` / `settings.json` untouched**, so your nodes are preserved.

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

## 📖 Usage

### Add a node

```bash
sc add 'vless://uuid@host:443?security=reality&pbk=...&fp=chrome&flow=xtls-rprx-vision#LosAngeles-US'
```

> ⚠️ Share links contain `?` `&` `#` and other shell-special characters. **Wrap the link in single quotes.**

### Switch node

```bash
sc ls                  # list all nodes
sc use 1               # by index
sc use US              # by name fragment
```

Switching is applied instantly via the Clash API — **no service restart**.

### Switch route mode

```bash
sc mode rule           # rule-based routing (default)
sc mode global         # everything via proxy
sc mode direct         # everything direct
```

### Service control

```bash
sc on                  # start + enable on boot
sc off                 # stop + disable on boot
sc status              # service status, TUN interface, current node, egress IP
sc log -f              # follow logs in real time
```

### Ruleset update

```bash
sc update-rules                       # update once now
sc update-interval daily              # update every day
sc update-interval weekly             # update every week (default)
sc update-interval 'Mon *-*-* 04:00:00'   # every Monday at 04:00
sc update-interval show               # show current cadence + next run
```

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
| sing-box binary | `/usr/bin/sing-box` (apt-installed) |
| sc CLI | `/usr/local/bin/sc` |
| sing-box config (auto-generated) | `/etc/sing-box/config.json` |
| Node list (with credentials) | `/etc/sing-box/nodes.json` (mode 600) |
| Settings | `/etc/sing-box/settings.json` |
| Rulesets | `/etc/sing-box/rules/*.srs` |
| systemd service | `/etc/systemd/system/sing-box.service` |
| Auto-update timer | `/etc/systemd/system/sing-box-rules-update.timer` |
| Auto-update cadence override | `/etc/systemd/system/sing-box-rules-update.timer.d/override.conf` |
| Password-less sudo | `/etc/sudoers.d/sc` |
| Uninstall script | `/usr/local/lib/singbox-cli/uninstall.sh` |
| Logs | `journalctl -u sing-box` or `sc log` |

## 🗑 Uninstall

Pick any:

```bash
sc uninstall                                                                                          # easiest, on installed systems
sudo ./uninstall.sh                                                                                   # in the repo dir
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)" # one-line remote
```

This wipes systemd units, `/etc/sing-box/` (incl. nodes), `/var/lib/sing-box/`, sudoers, `/usr/local/bin/sc`, `/usr/local/lib/singbox-cli/`. Then it asks whether to also remove the sing-box binary and APT source — answer `y` for **truly zero residue**.

## ⚠️ Security notes

- `nodes.json` contains node credentials/UUIDs, mode 600, root-only readable.
- `sc` uses sudoers NOPASSWD, scoped to `/usr/local/bin/sc` only.
- `sc` is owned by root, regular users cannot modify it, so NOPASSWD cannot be bypassed.
- For multi-user machines, consider switching NOPASSWD back to password-required.

## 🤝 Contributing

PRs welcome. Top priorities:

- [ ] Subscription link auto-update
- [ ] urltest support beyond selector (auto-pick the fastest node)
- [ ] RHEL / Fedora / Arch family support
- [ ] `sc ping` for node latency testing
- [ ] Node import/export (JSON backup)

## 📄 License

MIT — see [LICENSE](LICENSE).

---

> CLI output and `sc help` are in Simplified Chinese. The full project documentation in Chinese: [README.zh-CN.md](README.zh-CN.md).
