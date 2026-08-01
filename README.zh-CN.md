# singbox-cli

[English](README.md) | **简体中文**

> 给 sing-box 装一个易用的命令行外壳——开机即起、不依赖图形界面、不依赖用户登录、整机流量走 TUN 代理。

## ✨ 特性

- **开机即代理**：通过 systemd 在登录前就把 TUN 接口拉起来，含 SSH、apt、所有用户进程一律走代理
- **零 GUI 依赖**：纯 CLI，无图形界面、无桌面环境要求，桌面/服务器/无头机均可用
- **分享链接一键添加**：支持 `vless://` `vmess://` `trojan://` `ss://` `hysteria2://` `tuic://`
- **节点切换不重启**：通过 sing-box 的 Clash API 即时生效
- **路由模式即时切换**：`rule` / `global` / `direct` 一条命令搞定
- **规则集自动更新**：systemd timer 定期拉 `.srs`，频率可配
- **中英双语**：默认英文，安装时可选中文；任何时候 `sc lang en|zh` 切换

## 🛠 系统要求

- 带有 systemd **或** OpenRC 的 Linux 发行版——测试过 Debian、Ubuntu、Fedora、RHEL/CentOS/Rocky/Alma、Arch/Manjaro、openSUSE、Alpine
- amd64 (x86_64) 或 arm64 (aarch64)
- Python 3.6+（系统自带）
- root 权限（一次性配 sudoers，之后免密）

## 🚀 安装

一行命令搞定：

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
```

安装脚本会自动：

1. 提示选择 CLI 语言——英文（默认）或简体中文
2. 从 GitHub Releases 下载 sing-box 二进制并安装到 `/usr/local/bin/sing-box`
3. 安装 `sc` CLI 到 `/usr/local/bin/`
4. 创建服务（systemd 发行版：服务 unit + 规则集自动更新 timer；Alpine/OpenRC：init.d 脚本）
5. 配置免密 sudo（仅针对 `sc` 命令）
6. 下载 `.srs` 规则集
7. 启动 sing-box 并设置开机自启

> 语言默认根据 `$LANG` 推断（中文 locale → `zh`，否则 `en`）。提示出现时直接回车即采用默认，或输入 `1`/`2` 显式选择。

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
sc doctor              # 一次跑完的只读体检报告（见下）
sc log -f              # 实时日志
```

### 诊断安装

```bash
sc doctor
```

一条命令、一屏输出、七项事实 —— 按**因果顺序**打印，任何一项的原因都排在它能导致的结果之上：

| # | 检查项 | 报告内容 |
|---|---|---|
| 1 | sing-box 可执行文件 | 解析到的可执行文件路径及其版本 |
| 2 | 规则集 | 每个 `.srs` 一行：可用 / 缺失 / 不是规则集文件 / 文件过小 / 无法读取，以及同一次读取得到的字节数 |
| 3 | 配置文件 | `config.json` 是否存在，以及 `sing-box check` 的结论 |
| 4 | 服务 | 当前是否运行、是否已设置开机自启 —— 两件独立的事实 |
| 5 | TUN 接口 | `sb-tun` 是否存在及其地址 |
| 6 | Clash API | `settings.json` 中记录的端口，以及该端口是否响应 |
| 7 | 出口 IP | 观察到的公网出口地址（服务已停止时同样查询） |

每一行都标注 `[正常]` / `[异常]` / `[未知]`（`sc lang en` 下为 `[OK]` / `[PROBLEM]` / `[UNKNOWN]`），所以 `sc doctor | grep '^\[异常\]'` 就能列出所有出问题的项。`[未知]` 表示这项检查根本没能执行 —— 工具缺失、权限不足 —— 而不是「被检查的东西坏了」。任何一项检查出问题都不会中断整个报告：七项永远都会打印。

**`sc doctor` 不会改动任何东西。** 它不生成配置、不下载、不启动、不停止、不重启、不启用、不修复。与其他子命令不同，它连启动阶段那步也不做：不会创建 `/etc/sing-box`，也不会在首次运行时探测并保存 Clash API 端口 —— 机器已经坏掉或全新时，这些路径的「空」本身就是诊断结论，诊断工具不能把自己要收集的证据先毁掉。它可以反复运行、并发运行，出问题后第一个跑的就该是它。

退出码：

| 退出码 | 含义 |
|---|---|
| `0` | 七项全部正常 |
| `1` | 至少一项 `[异常]` —— 任意一项：可执行文件缺失、规则集不可用、配置检查未通过、服务未运行或未设置开机自启、TUN 设备不存在、Clash API 端口无响应、出口 IP 查询未成功 |
| `2` | 没有 `[异常]`，但至少一项 `[未知]` —— 该项检查无法执行：没有 sing-box 可执行文件来检查配置、未检测到 init 系统、缺少 `ip` 命令、或 `settings.json` 中没有记录 Clash API 端口 |

### 规则集更新

```bash
sc update-rules                       # 立即更新一次
sc update-rules --mirror <基地址>     # 指定镜像（可重复）
sc update-interval daily              # 每天自动更新
sc update-interval weekly             # 每周（默认）
sc update-interval 'Mon *-*-* 04:00:00'   # 每周一凌晨 4 点
sc update-interval show               # 查看当前频率和下次执行时间
```

`sc update-rules` 会按顺序尝试多个镜像（jsDelivr → testingcf → ghfast → raw.githubusercontent），并在安装前校验每次下载的内容，因此传输不完整的响应或 HTML 错误页永远不会被写入 `/etc/sing-box/rules/`。在终端下会显示下载进度；输出被重定向时仍然是每个规则集一行结果。

`--mirror` 会**替换**内置镜像列表（失败后不会再回退到内置列表），可以重复出现，单个值也可以写多个以空格分隔的 URL。环境变量 `SB_RULES_BASE="<url> [url...]"` 效果相同，但仅在 `sc` 已经以 root 身份运行时有效（systemd 定时器、root shell）—— 在普通 shell 下 `sc` 会通过 `sudo` 重新执行自己，默认的 `env_reset` 会清除该变量。推荐使用 `--mirror`。

**规则集下载失败不再导致服务起不来。** 生成配置时会自动剔除该规则集以及所有引用它的分流规则，并提示哪些规则集不可用、原因是什么，服务照常启动 —— 损失的只是分流粒度，不是连通性。补齐后执行 `sc update-rules`（或 `sc reload`），完整的分流规则会自动恢复。

### 切换 CLI 语言

```bash
sc lang en   # English
sc lang zh   # 简体中文
```

设置持久化到 `/etc/sing-box/settings.json`，对后续所有 `sc` 输出（错误、状态、帮助）生效。

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
| sing-box 二进制 | `/usr/local/bin/sing-box` |
| sc CLI | `/usr/local/bin/sc` |
| sing-box 配置（自动生成） | `/etc/sing-box/config.json` |
| 节点列表（含密码） | `/etc/sing-box/nodes.json`（mode 600） |
| 设置 | `/etc/sing-box/settings.json` |
| 规则集 | `/etc/sing-box/rules/*.srs` |
| systemd 服务 | `/etc/systemd/system/sing-box.service`（仅 systemd） |
| 自动更新 timer | `/etc/systemd/system/sing-box-rules-update.timer`（仅 systemd） |
| 自动更新频率覆盖 | `/etc/systemd/system/sing-box-rules-update.timer.d/override.conf`（仅 systemd） |
| OpenRC 服务 | `/etc/init.d/sing-box`（仅 Alpine/OpenRC） |
| 定期更新脚本 | `/etc/periodic/{daily,weekly,monthly}/singbox-update-rules`（仅 Alpine/OpenRC） |
| 免密 sudo | `/etc/sudoers.d/sc` |
| 卸载脚本 | `/usr/local/lib/singbox-cli/uninstall.sh` |
| 日志 | `journalctl -u sing-box` 或 `sc log`（systemd）；OpenRC 下 `sc log` 读取 `/var/log/sing-box/` |

## 🗑 卸载

任意一种方式都行：

```bash
sc uninstall                                    # 已安装环境最简单
sudo ./uninstall.sh                             # 在仓库目录里
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)"   # 一行远程
```

会清掉服务 unit（systemd）或 init.d 脚本（OpenRC）、`/etc/sing-box/`（含节点）、`/var/lib/sing-box/`、`/var/log/sing-box/`、sudoers、`/usr/local/bin/sc`、`/usr/local/lib/singbox-cli/`。最后会问你要不要顺便把 sing-box 二进制也删掉——选 `y` 即真正零残留。

## ⚠️ 安全考虑

- `nodes.json` 包含节点密码/UUID，权限 600，仅 root 可读
- `sc` CLI 通过 sudoers NOPASSWD 实现免密，规则范围只限 `/usr/local/bin/sc` 这一个二进制
- `sc` 自身是 root 拥有，普通用户无法修改，所以 NOPASSWD 不会被绕过
- 若机器多用户共享，请评估是否需要把 NOPASSWD 改为有密码

## 🤝 贡献

欢迎 PR。优先方向：

- [ ] 支持订阅链接自动更新
- [ ] 支持 selector 之外的 urltest（自动选最快节点）
- [x] 支持 RHEL / Fedora / Arch 系发行版
- [ ] 添加节点延迟测试命令 `sc ping`
- [ ] 节点导入/导出（JSON 备份）

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE)
