# singbox-cli

> 给 sing-box 装一个易用的命令行外壳——开机即起、不依赖图形界面、不依赖用户登录、整机流量走 TUN 代理。

[English summary at the bottom](#english-summary)

## ✨ 特性

- **开机即代理**：通过 systemd 在登录前就把 TUN 接口拉起来，含 SSH、apt、所有用户进程一律走代理
- **零 GUI 依赖**：纯 CLI，无图形界面、无桌面环境要求，桌面/服务器/无头机均可用
- **分享链接一键添加**：支持 `vless://` `vmess://` `trojan://` `ss://` `hysteria2://` `tuic://`
- **节点切换不重启**：通过 sing-box 的 Clash API 即时生效
- **路由模式即时切换**：`rule` / `global` / `direct` 一条命令搞定
- **规则集自动更新**：systemd timer 定期拉 `.srs`，频率可配
- **中文友好**：所有命令输出和帮助都是中文

## 🛠 系统要求

- Debian / Ubuntu（其他 systemd + apt 系发行版理论可用，未测试）
- Python 3.6+（系统自带）
- root 权限（一次性配 sudoers，之后免密）

## 🚀 安装

一行命令搞定：

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

安装脚本会自动：

1. 添加 sing-box 官方 APT 源并安装 sing-box 内核
2. 安装 `sc` CLI 到 `/usr/local/bin/`
3. 创建 systemd 服务 + 规则集自动更新 timer
4. 配置免密 sudo（仅针对 `sc` 命令）
5. 下载 `.srs` 规则集
6. 启动 sing-box 并设置开机自启

### 升级

再跑一次同样的命令即可。`install.sh` 是幂等的，会覆盖 `sc` 二进制和 systemd unit，**不会动 `nodes.json` / `settings.json`**，节点配置不会丢。

### 其他安装方式

先审阅脚本再执行（推荐谨慎用户）：

```bash
curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh -o install.sh
less install.sh
sudo bash install.sh
```

git clone（适合二次开发）：

```bash
git clone https://github.com/Alan-IFT/singbox-cli.git
cd singbox-cli
sudo ./install.sh
```

## 📖 使用

### 添加节点

```bash
sc add 'vless://uuid@host:443?security=reality&pbk=...&fp=chrome&flow=xtls-rprx-vision#美国洛杉矶'
```

> ⚠️ 分享链接含 `?` `&` `#` 等 shell 特殊字符，**必须用单引号**包起来。

### 切节点

```bash
sc ls                  # 看所有节点
sc use 1               # 按序号切
sc use 美国            # 按名字片段切
```

切换通过 Clash API 即时生效，**不重启服务**。

### 切路由模式

```bash
sc mode rule           # 按规则分流（默认）
sc mode global         # 全部走代理
sc mode direct         # 全部直连
```

### 控制服务

```bash
sc on                  # 启动 + 开机自启
sc off                 # 停止 + 取消开机自启
sc status              # 查看服务状态、TUN 接口、当前节点、出口 IP
sc log -f              # 实时日志
```

### 规则集更新

```bash
sc update-rules                       # 立即更新一次
sc update-interval daily              # 每天自动更新
sc update-interval weekly             # 每周（默认）
sc update-interval 'Mon *-*-* 04:00:00'   # 每周一凌晨 4 点
sc update-interval show               # 查看当前频率和下次执行时间
```

### 完整命令列表

```bash
sc help
```

## 🏗 架构

```
开机
  └─ systemd 启动 sing-box（root 权限）
       ├─ 读 /etc/sing-box/config.json
       ├─ 创建 sb-tun 接口（172.19.0.1/30）
       ├─ 直接连节点（无需用户登录）
       └─ 加载本地 .srs 规则集
              ↓
       全机流量走代理（含 SSH 登录前、GDM 登录界面）

用户使用 sc CLI：
  └─ 修改 /etc/sing-box/nodes.json 或 settings.json
       └─ 重新生成 config.json
            └─ Clash API 通知 sing-box 即时切换（不重启）
```

## 📂 文件位置

| 用途 | 路径 |
|---|---|
| sing-box 二进制 | `/usr/bin/sing-box`（apt 安装） |
| sc CLI | `/usr/local/bin/sc` |
| sing-box 配置（自动生成） | `/etc/sing-box/config.json` |
| 节点列表（含密码） | `/etc/sing-box/nodes.json`（mode 600） |
| 设置 | `/etc/sing-box/settings.json` |
| 规则集 | `/etc/sing-box/rules/*.srs` |
| systemd 服务 | `/etc/systemd/system/sing-box.service` |
| 自动更新 timer | `/etc/systemd/system/sing-box-rules-update.timer` |
| 自动更新频率覆盖 | `/etc/systemd/system/sing-box-rules-update.timer.d/override.conf` |
| 免密 sudo | `/etc/sudoers.d/sc` |
| 卸载脚本 | `/usr/local/lib/singbox-cli/uninstall.sh` |
| 日志 | `journalctl -u sing-box` 或 `sc log` |

## 🗑 卸载

任意一种方式都行：

```bash
sc uninstall                                    # 已安装环境最简单
sudo ./uninstall.sh                             # 在仓库目录里
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)"   # 一行远程
```

会清掉 systemd 服务、`/etc/sing-box/`（含节点）、`/var/lib/sing-box/`、sudoers、`/usr/local/bin/sc`、`/usr/local/lib/singbox-cli/`。最后会问你要不要顺便把 sing-box 二进制和 APT 源也删掉——选 `y` 即真正零残留。

## ⚠️ 安全考虑

- `nodes.json` 包含节点密码/UUID，权限 600，仅 root 可读
- `sc` CLI 通过 sudoers NOPASSWD 实现免密，规则范围只限 `/usr/local/bin/sc` 这一个二进制
- `sc` 自身是 root 拥有，普通用户无法修改，所以 NOPASSWD 不会被绕过
- 若机器多用户共享，请评估是否需要把 NOPASSWD 改为有密码

## 🤝 贡献

欢迎 PR。优先方向：

- [ ] 支持订阅链接自动更新
- [ ] 支持 selector 之外的 urltest（自动选最快节点）
- [ ] 支持 RHEL / Fedora / Arch 系发行版
- [ ] 添加节点延迟测试命令 `sc ping`
- [ ] 节点导入/导出（JSON 备份）

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE)

---

## English Summary

`singbox-cli` is a CLI wrapper around [sing-box](https://github.com/SagerNet/sing-box) that turns it into a proper system-level proxy:

- **Boot-time TUN**: traffic is proxied before any user logs in (works for SSH, apt, headless servers)
- **No GUI required**: pure command-line, runs on desktops, servers, headless machines
- **Share-link import**: just paste your `vless://` (or vmess/trojan/ss/hy2/tuic) URL
- **Instant node switching** via Clash API (no service restart)
- **Configurable ruleset auto-update** via systemd timer

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"

sc add 'vless://...'
sc status
sc help
sc uninstall    # 一键卸载
```

Note: UI strings and help text are currently in Simplified Chinese. English/i18n contributions welcome.
