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
sc ls                  # 看所有节点，带延迟
sc use 1               # 按序号切
sc use 美国            # 按名字片段切
sc use auto            # 切到自动选择组（见下）
```

切换通过 Clash API 即时生效，**不重启服务**。

### 自动选择最快节点

只要至少有一个节点，`sc` 就会额外生成一个标签为 `auto` 的**自动选择组**：由 sing-box 每 3 分钟用 `https://www.gstatic.com/generate_204` 探测所有节点，把流量切到响应最快的那个。`sc use auto` 就是选中这个组，于是某个节点变慢、或者开始拒绝连接时，流量 —— 以及跟着它走的 DNS —— 会自动离开它，不需要任何人敲命令；但切走发生在**下一轮探测**，也就是说在它切走之前，最多还有约 3 分钟的请求是坏的，并不是瞬间切换。有一种故障它覆盖不了 —— 某个节点还能连上、之后却一直不回应，这会把探测挂住，而不是让探测判定它不可用，而一次永远结束不了的探测也就永远不会更新选择：实测中组会一直留在这种节点上，测多久都不动。如果流量已经断了、组却没有换走，请自己手动切。`sc use <名称>` 依旧是钉死单个节点，行为和以前完全一样；全新安装在第一次 `sc add` 时会选中这个组，已有安装则保持原来那个节点不动，直到你自己执行 `sc use auto`。

`sc ls` 会为这个组单独打一行，这一行没有序号，地址列写的是它此刻实际在用的节点：

```text
  序号  激活  协议          名称          地址              延迟
      ●   urltest     auto          → JP-2           141 ms
   1      vless       US-1          1.1.1.1:443      210 ms
   2      vless       JP-2          2.2.2.2:443      141 ms
   3      vless       SG-3          3.3.3.3:443           -
```

延迟这一列**不是 `sc` 去测出来的**：它是正在运行的 sing-box 手里已经有的值，由这个组自己的探测产生，`sc` 只是通过 Clash API 读了一次。因此它只在这个组被使用期间才存在 —— 如果这台机器钉死在某个节点上，组就是空闲的，探测会停下来，这一列会全是 `-`（或者一直显示最后一次探测到的旧值）。`-` 表示「没有存下来的延迟」，既不是「0 毫秒」也不是「连不上」；服务没运行时 `sc` 根本不会发起查询，每一格都是 `-`。

> **如果你自己的某个节点本来就叫 `auto`**，这台机器上**不会**生成自动选择组 —— 两个出站不允许同名。此时 `sc use auto` 钉死的是*那个节点*，它打印的 `Switched to: auto` **并不代表**故障自动切换已经开启。把该节点改名，下次 `sc reload` 时这个组就会自己出现。

### 切路由模式

```bash
sc mode rule           # 按规则分流（默认）
sc mode global         # 全部走代理
sc mode direct         # 全部直连
```

### IPv6 域名解析

```bash
sc ipv6 auto           # 本机没有全局 IPv6 地址时，AAAA 查询直接返回空结果（默认）
sc ipv6 on             # 始终正常解析 AAAA
sc ipv6 off            # 始终对 AAAA 返回空结果
sc ipv6 show           # 显示当前设置以及它得出的结论
```

在用不了 IPv6 的机器上，凡是被这份配置送往代理侧解析器的域名 —— `rule` 模式下是下表之外的全部域名，`global` 模式下是 `hosts` 表以外的全部，`direct` 模式下一个都没有 —— 它的 AAAA 查询仍然会走到那里；而当节点「TCP 能连上、之后一直不回应」时，这次查询什么都拿不回来，实测正好卡在 sing-box 自己的每次查询 10.0 秒上限。开启抑制后这次查询根本不会发出：生成的配置在本地就用**空的 `NOERROR`** 回答 AAAA（查询类型 28）以及 SVCB / HTTPS 这两个类型（64、65），不询问任何解析器。`auto` 的判断依据是读一次 `/proc/net/if_inet6` —— 「本机有全局 IPv6 地址」指的是某个既不是回环、也不是 `sb-tun` 的网卡上存在 `2000::/3` 范围内的地址；链路本地（`fe80::/10`）和唯一本地（`fc00::/7`）地址一律不算，而本项目自己的 TUN 设备按名字排除，因为它上面必然有一个链路本地地址。`on` 与 `off` 用于手动覆盖这个判断。

设置持久化在 `/etc/sing-box/settings.json`；没有这个键就等于 `auto`，值不是这三个之一时会在 stderr 点名说明并按 `auto` 处理。如果地址列表根本读不到，`sc` 会**按有 IPv6 处理**（这样不会让任何东西变得不可达），并用一行说明这件事。`sc ipv6 <值>` **只有在实际结论真的发生变化时**才重新生成配置并重启 sing-box —— 否则只打印一行「设置无变化」，完全不碰服务。`sc ipv6 show` 只是报告当前设置以及它得出的结论：它不会改动 `ipv6` 这个设置、不重新生成配置、也完全不碰服务 —— 但和除 `sc doctor` 以外的所有子命令一样，它仍然会先走一遍常规启动流程：全新机器上这一步会创建 `/etc/sing-box` 与 `/var/lib/sing-box`、写入初始的 `nodes.json` / `settings.json`；而**任何**还没记录下有效 Clash API 端口的机器上 —— 全新安装，或者从早于端口自动探测的版本升级上来的机器 —— 这一步都会探测一个空闲端口并写进 `settings.json`。

承载它的那条规则排在 DNS 规则的**第一条**，在两条路由模式规则之前，因此 `rule`、`global`、`direct` 三种模式下同样生效 —— 而这正是出问题时人们会切过去的模式；它也不引用任何规则集，所以 `.srs` 文件缺失的机器照样有这个能力。

**所有节点都不可用时，哪些域名仍然能解析** —— 实测所用的节点是「TCP 能连上、之后一直不回应」这一种：

| 路由模式 | 不依赖任何节点即可解析 | 得不到回答 |
|---|---|---|
| `rule` | 内置 `hosts` 表里的那些域名、五个国内域名后缀（`alidns.com`、`doh.pub`、`dot.pub`、`360.cn`、`onedns.net`）、以及所有被抑制的查询类型 —— 规则集可用时，还包括 `geosite-cn` 与 `geosite-private` 命中的域名 | 其余全部，包括所有境外域名 |
| `global` | 只有 `hosts` 表和被抑制的查询类型 —— 这个模式下是你自己要求所有流量都走代理 | 其余全部 |
| `direct` | 全部：这个模式下没有任何域名会被送到代理侧的解析器 | —— |

**四个规则集全部不可用时**（也就是 `sc` 已经会告警的降级配置），上表中 `rule` 这一行会缩小到 `hosts` 表、五个国内域名后缀和被抑制的查询类型；其余域名要等到某个节点恢复可用、或者规则集补齐之后才能解析。`global` 那一行本来就比这更短，`direct` 那一行则根本不依赖规则集。

**它做不到的事。** 这里没有第二个解析器，也没有任何可配置的等待时间。代理侧的解析器连得上却不回答时，sing-box 会在它自己固定的每次查询上限（1.13.15 上是 10.0 秒 —— 本项目生成的配置里没有任何键能改动它）放弃这次查询，什么都不返回，也不会去问别人；你最终看到的报错来自你自己客户端的超时。代理侧解析器返回的 `NXDOMAIN` 或 `SERVFAIL` 会被原样转达，不会拿去别处重问一遍，因此不会因为一次失败就把某个域名暴露给国内解析器。地址只能通过 IPv6 解析出来的节点需要 `sc ipv6 on`。

### 遥测域名拦截

```bash
sc telemetry block     # 名单内的域名一律在本地返回「域名不存在」（默认）
sc telemetry allow     # 名单内的域名正常解析
sc telemetry show      # 显示当前设置以及名单中的每个域名
```

`sc` 内置了一份固定的遥测域名清单，共 17 条。设置为 `block` 时 —— 这也是从未设置过的机器的取值 —— 查询名单内的域名、或它的任意子域名，都由 sing-box 自己以 `NXDOMAIN`、零条记录、几毫秒的速度回答，**不会向任何 DNS 服务器发出查询**。一个域名进入名单必须**同时**满足两条：它的唯一用途是把使用情况、诊断、崩溃或广告标识数据送给厂商，**并且**拦截它不会让所属产品的任何用户可见功能失效。任何更新、激活、授权、认证、推送下发、CDN 内容、验证码或安全特性的端点都不符合 —— 这也是 `analytics.google.com`（它同时提供 Analytics 控制台）、`omtrdc.net`（Adobe Target 会下发页面内容）、`googletagmanager.com`、`settings-win.data.microsoft.com` 以及各厂商的推送域名被刻意排除在外的原因。

匹配以标签边界为准：`crashlytics.com` 覆盖它本身以及任意层级的子域名，不区分大小写，但**不会**覆盖 `notcrashlytics.com`。

设置持久化在 `/etc/sing-box/settings.json`；没有这个键就等于 `block`，因此全新安装与升级上来的机器行为完全一致；值不是 `block` 也不是 `allow` 时，会在 stderr 点名说明并按 `block` 处理。`sc telemetry <值>` **只有在实际生效的设置真的发生变化时**才重新生成配置并重启 sing-box —— 否则只说明设置无变化，并提示 `sc reload`，那才是把这项设置应用到「生成于该设置之前」的 `config.json` 的办法。`sc telemetry show` 不改动任何设置、不重新生成配置、也完全不碰服务 —— 但和除 `sc doctor` 以外的所有子命令一样，它仍然会先走一遍常规启动流程：全新机器上这一步会创建 `/etc/sing-box` 与 `/var/lib/sing-box`，并写入初始的 `nodes.json` / `settings.json`。

承载这份清单的规则排在两条路由模式规则之前，因此**切换路由模式并不会解除拦截**：`sc mode global` 和 `sc mode direct` 改变的是*其他*域名由哪个解析器回答，而不是名单内的域名是否被拦截。它不引用任何规则集，所以 `.srs` 文件缺失的机器照样有这个能力；它也不需要任何可用节点 —— 一台一个节点都没有的机器同样会拦截名单内的域名。

**清单** —— 每一条都标注厂商与类别；`sc telemetry show` 在机器上打印的就是同一份名单：

| 域名 | 厂商 | 承载什么 | 类别 |
|---|---|---|---|
| `telemetry.microsoft.com` | 微软 | Windows 诊断、崩溃与错误报告 | 桌面系统诊断 |
| `vortex.data.microsoft.com` | 微软 | Windows 诊断数据上传（DiagTrack） | 桌面系统诊断 |
| `vortex-win.data.microsoft.com` | 微软 | 上一条的 Windows 专用同类端点 | 桌面系统诊断 |
| `metrics.ubuntu.com` | Canonical | `ubuntu-report` 的安装 / 硬件调查 | 桌面系统诊断 |
| `daisy.ubuntu.com` | Canonical | whoopsie / Apport 崩溃报告上报 | 桌面系统诊断 |
| `incoming.telemetry.mozilla.org` | Mozilla | Firefox 遥测 ping 上报 | 浏览器遥测 |
| `google-analytics.com` | 谷歌 | Google Analytics 打点采集 | 分析 SDK |
| `app-measurement.com` | 谷歌 | Firebase Analytics 度量数据上传 | 分析 SDK |
| `crashlytics.com` | 谷歌 | Firebase Crashlytics 崩溃与会话上报 | 分析 SDK |
| `demdex.net` | Adobe | Experience Cloud ID / Audience Manager | 分析 SDK |
| `scorecardresearch.com` | Comscore | 受众度量打点 | 分析 SDK |
| `hm.baidu.com` | 百度 | 百度统计（Baidu Tongji）网站分析 | 国内分析 SDK |
| `cnzz.com` | 阿里巴巴（友盟+/CNZZ） | CNZZ 网站分析计数与日志采集 | 国内分析 SDK |
| `mmstat.com` | 阿里巴巴 | 集团使用 / 行为打点日志 | 国内分析 SDK |
| `ulogs.umeng.com` | 阿里巴巴（友盟） | U-App 分析 SDK 日志上传 | 国内分析 SDK |
| `tracking.miui.com` | 小米 | MIUI 系统使用 / 分析数据上传 | 国内分析 SDK |
| `data.mistat.xiaomi.com` | 小米 | MiStat 统计 SDK 数据上传 | 国内分析 SDK |

**被拦截和网络故障看起来完全不同。** 拦截在几毫秒内返回，并且带着一个 rcode —— `status: NXDOMAIN`、`ANSWER: 0`、置上 `aa` 标志 —— 而网络故障是在你自己客户端超时之前什么都拿不到。用 `dig +nocookie crashlytics.com` 就足以分辨这两者，而 `sc telemetry show` 能告诉你正在排查的那个域名到底在不在名单里。

**如果名单内的域名弄坏了某个应用**，有两条退路，都不需要改 `bin/sc`：`sc telemetry allow` 关闭整份名单，或者用下面的写法只放行其中一个域名。两者都能在 `sc reload` 之后继续生效。

**添加你自己的域名，以及放行我们名单里的某一个。** 两者都是对 `/etc/sing-box/override.json` 的修改（这个文件怎么用见下方的**自定义配置**一节）。两者都锚定在 `{"server": "hosts_dns"}` 这条规则上 —— 也就是用内置 hosts 表回答的那一条：无论设置是 `block` 还是 `allow`、无论规则集是否可用，这个元素都一定会被生成，所以今天写下的 override 在 `sc telemetry allow` 之后依然有效；而 `$after` 会把你的规则放在我们的规则之前。

添加你自己的域名：

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

放行我们名单里的某一个 —— 下面这份让 `hm.baidu.com` 正常解析，其余 16 条依然被拦截。应当走国内解析的域名用 `direct_dns`，应当走境外解析的用 `remote_dns`：

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

**`override.json` 只有一个，而一个数组只接受一条指令。** 上面两份写法不能拆成两个文件，也不能在同一个 `dns.rules` 对象里写成两条指令（`$after` 加 `$before`）—— 那会被拒绝，并提示 `$after cannot be combined with other keys in the same object`。两样都要的话，把两条规则放进**同一条**指令里，放行的那条写在前面，这样它会先被匹配到：

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

**它做不到的事。** 它匹配的是**域名**，而且只匹配那些会走到这份配置 DNS 规则里的域名。自带 DoH/DoT 解析器的应用，或者直接连硬编码 IP 地址的应用，完全不受影响 —— 这里不在 IP 层或路由层拦截任何东西，也不检查流量内容。清单固定写在 `bin/sc` 里，不会自行更新；`sc telemetry allow` 和上面的写法就是你在自己机器上改变它行为的方式。

### 控制服务

```bash
sc on                  # 启动 + 开机自启
sc off                 # 停止 + 取消开机自启
sc status              # 查看服务状态、TUN 接口、规则集状态与更新时间、当前节点、出口 IP
sc doctor              # 一次跑完的只读体检报告（见下）
sc log -f              # 实时日志
```

### 诊断安装

```bash
sc doctor
```

一条命令、一屏输出、九项事实 —— 按**因果顺序**打印，任何一项的原因都排在它能导致的结果之上：

| # | 检查项 | 报告内容 |
|---|---|---|
| 1 | sing-box 可执行文件 | 解析到的可执行文件路径及其版本 |
| 2 | 规则集 | 每个 `.srs` 一行：可用 / 缺失 / 不是规则集文件 / 文件过小 / 无法读取，同一次读取得到的字节数，以及文件写入至今有多久 —— 可用但超过 60 天的规则集会被报为异常，并给出 `sc update-rules` |
| 3 | 配置文件 | `config.json` 是否存在、是否仍是 `sc` 最近一次生成的那份，以及 `sing-box check` 的结论 |
| 4 | IPv6（AAAA） | 本机实际生效的 AAAA 决策，以及磁盘上的 `config.json` 是否与该决策一致 |
| 5 | 服务 | 当前是否运行、是否已设置开机自启 —— 两件独立的事实 |
| 6 | TUN 接口 | `sb-tun` 是否存在及其地址 |
| 7 | Clash API | `settings.json` 中记录的端口、该端口是否响应、有多少个节点带有已记录的延迟以及自动选择当前走哪个出站，还有一次由正在运行的 sing-box 完成的域名解析及其耗时 |
| 8 | 出口 IP | 观察到的公网出口地址（服务已停止时同样查询） |
| 9 | 文件权限 | `/etc/sing-box` 下任何对同组或其他用户开放的**凭据**文件（`settings.json` 除外 —— 它不含凭据），以及目录本身是否可被同组或其他用户写入 —— 每个有问题的路径都会连同权限位和收紧它的命令一起点名 |

每一行都标注 `[正常]` / `[异常]` / `[未知]`（`sc lang en` 下为 `[OK]` / `[PROBLEM]` / `[UNKNOWN]`），所以 `sc doctor | grep '^\[异常\]'` 就能列出所有出问题的项。`[未知]` 表示这项检查根本没能执行 —— 工具缺失、权限不足 —— 而不是「被检查的东西坏了」。任何一项检查出问题都不会中断整个报告：九项永远都会打印。

**`sc doctor` 不会改动任何东西。** 它不生成配置、不下载、不启动、不停止、不重启、不启用、不修复。与其他子命令不同，它连启动阶段那步也不做：不会创建 `/etc/sing-box`，也不会在首次运行时探测并保存 Clash API 端口 —— 机器已经坏掉或全新时，这些路径的「空」本身就是诊断结论，诊断工具不能把自己要收集的证据先毁掉。它唯一向外界发起的动作是第 7 项里的那次域名解析：命令本身仍然不碰任何路径，但**这次解析是由正在运行的 sing-box 完成的**，它可能会像对待任何一次查询那样把结果记进自己的 DNS 缓存（`/var/lib/sing-box/cache.db`）。它可以反复运行、并发运行，出问题后第一个跑的就该是它。

退出码：

| 退出码 | 含义 |
|---|---|
| `0` | 九项全部正常 |
| `1` | 至少一项 `[异常]` —— 任意一项：可执行文件缺失、规则集不可用或已过期、`config.json` 被 `sc` 以外的方式改过、配置检查未通过、`config.json` 与 AAAA 决策不一致、服务未运行或未设置开机自启、TUN 设备不存在、Clash API 端口无响应、没有任何节点带有已记录的延迟、域名解析没有拿到结果、出口 IP 查询未成功、凭据文件或配置目录对同组/其他用户开放 |
| `2` | 没有 `[异常]`，但至少一项 `[未知]` —— 该项检查无法执行：没有 sing-box 可执行文件来检查配置、没有 `sc` 最近一次生成内容的记录、未检测到 init 系统、缺少 `ip` 命令、`settings.json` 中没有记录 Clash API 端口（此时节点延迟与 DNS 两项也不会发起探测）、`nodes.json` 读不出来、或配置目录不存在 / 无法列出 |

### 查看配置

```bash
sc config
```

打印 `/etc/sing-box/config.json` —— sing-box 实际在跑的那份文档 —— 其中所有节点凭据都已隐去。隐去是无条件的：没有任何参数、设置或环境变量能打印出未隐去的值，因为 `sc` 运行在一条只对它自己生效的免密 `sudo` 规则之下，一旦提供「不隐去」的开关，本来只有 root 才读得到的 `0600` 凭据文件就变成了任何人免密即可读取。想看未隐去的原文，只有一个途径：以 root 身份直接读那个文件。

哪些内容会被隐去：

- **`outbounds` 之内，任意深度**：所有不在**可见键集合**里的键 —— 可见的是 `type`、`tag`、`server`、`server_port`、`detour`，以及传输层 / TLS / Reality / obfs 各字段和协议调优、自动选择组的设置。因此 `uuid`、`password`、`public_key`、`short_id` 都会被隐去；`sc` 自己从不写出的键也一样，包括你通过 `override.json` 添加的出站带来的键、以及将来 sing-box 新增的字段。
- **整份文档任意位置**：`password`、`uuid`、`secret`、`token`、`private_key`、`pre_shared_key`。

被隐去的值永远是同一个固定写法 `******`。被替换的只有**值**，键名照常保留 —— 所以「配了哪些字段」始终看得见，「字段内容是什么」始终看不见。

配置文档写到**标准输出**，`sc` 自己说的每一句话写到**标准错误**，因此 `sc config > current.json` 得到的是一份 JSON 解析器认可的文档，`sc config | grep -n server_name` 也照常可用。标准错误上的说明会给出该文件的绝对路径、声明凭据已隐去，并在存在漂移记录时说明磁盘上这份文档是不是 `sc` 最近一次生成的内容。

**`sc config` 不写任何东西。** 任何地方都不会被创建、修改或删除文件，机器上没有 `/etc/sing-box` 时它也不会去建；不下载、不启动任何进程、不碰服务，也不对配置**是否有效**下任何结论 —— 那是 `sc doctor` 的结论。

**它的边界。** 隐去覆盖的是 `sc` 自己写进去的凭据。如果你把某个密钥写在自己的 `/etc/sing-box/override.json` 里、位置在 `outbounds` **之外**、键名又不属于上面那六个（比如某个入站用户的 `auth_token`），它会被原样打印出来。把输出贴到任何地方之前，先看一眼自己的 override。

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
| sing-box 配置（自动生成） | `/etc/sing-box/config.json`（mode 600） |
| 节点列表（含密码） | `/etc/sing-box/nodes.json`（mode 600） |
| 设置 | `/etc/sing-box/settings.json` |
| 你自己的配置覆盖（可选，归你管） | `/etc/sing-box/override.json` |
| `sc` 上次生成内容的记录（内部用） | `/etc/sing-box/.config.sha256` |
| 规则集 | `/etc/sing-box/rules/*.srs` |
| systemd 服务 | `/etc/systemd/system/sing-box.service`（仅 systemd） |
| 自动更新 timer | `/etc/systemd/system/sing-box-rules-update.timer`（仅 systemd） |
| 自动更新频率覆盖 | `/etc/systemd/system/sing-box-rules-update.timer.d/override.conf`（仅 systemd） |
| OpenRC 服务 | `/etc/init.d/sing-box`（仅 Alpine/OpenRC） |
| 定期更新脚本 | `/etc/periodic/{daily,weekly,monthly}/singbox-update-rules`（仅 Alpine/OpenRC） |
| 免密 sudo | `/etc/sudoers.d/sc` |
| 卸载脚本 | `/usr/local/lib/singbox-cli/uninstall.sh` |
| 日志 | `journalctl -u sing-box` 或 `sc log`（systemd）；OpenRC 下 `sc log` 读取 `/var/log/sing-box/` |

## 🛠 自定义配置（`override.json`）

`config.json` 是**生成物**：`sc reload`、`sc add`、`sc rm` 每次都会把它整份重写，`sc use` 和 `sc update-rules` 也可能重写，所以你在那里手改的内容会被悄无声息地丢掉。请改成写 `/etc/sing-box/override.json`。`sc` 从不创建、不写入、也不删除这个文件，并且把它放在**最后**应用 —— 覆盖在 `sc` 组合出的一切之上 —— 因此它能挺过每一次重新生成，也能挺过重新执行 `install.sh`。

不存在、内容为空、或者就是 `{}` 的覆盖文件，等于什么都没改。无法应用的覆盖文件会让命令**在写入任何东西之前就停下**：`config.json` 保持原样，运行中的服务不受影响，报错会指名这个文件和具体问题。

**对象按层级合并。** 你没提到的键保留原值和原位置：

```json
{ "log": { "level": "debug" } }
```

→ 只有 `log.level` 变了；`log` 的其他键及其位置都原封不动。

**数组只在显式指令下才会变**，因为「加一条 DNS 规则」和「换掉全部 DNS 规则」绝不能长得一样：

| 指令 | 效果 |
|---|---|
| `$replace` | 数组变成你给的这份，仅此而已 |
| `$prepend` | 你的元素放到已有元素前面 |
| `$append` | 你的元素放到已有元素后面 |
| `$before` | 你的元素紧挨着 `match` 命中的那个元素之前 |
| `$after` | 你的元素紧挨着 `match` 命中的那个元素之后 |

`$before` / `$after` 的值是 `{"match": {…}, "values": […]}`。`match` 按子集相等匹配 —— 其中每个键值都要与元素的相等 —— 且必须**恰好命中一个**元素；命中 0 个或多个都是错误，绝不会静默地什么都不做。用锚点而不是数字下标，是因为 sing-box 按顺序求值 `dns.rules` 和 `route.rules`，而只要有人往前面插一条，下标就错了。

因此，当前值是数组的那个键**只接受指令对象**：在那里写对象、标量、`null` 或裸数组都会报错并列出这五个指令，绝不会静默替换。要清空一个数组，请用 `$replace` 配 `[]`。

示例 —— 在 `clash_mode: Direct` 那条规则后面紧接着插入一条抑制 AAAA 的 DNS 规则：

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

你插入的值是原样拷贝：里面的内容不会被再次解释，所以一条自带 `rule_set` 或 `domain_suffix` 数组的规则会照原样输出。在生成配置已有数组的位置直接写一个裸数组会被拒绝，报错里会列出可用指令；而在生成配置里本来没有的键上写裸数组则直接接受并创建它。

> **`sc` 依赖它自己生成的一部分配置。** 删掉 `experimental.clash_api.external_controller`，或者把 `proxy` 出站改名，得到的文件 `sing-box check` 照样接受，但 `sc use` 和 `sc status` 会失灵。`sc` 不会拦你 —— 这是你的文件。

**如果你已经手改过 `config.json`**，下一条重新生成它的命令会在 stderr 打一行：该文件被 `sc` 以外的方式改过、这次改动即将被覆盖、以及应该把它写到哪里才能长久保留。比对的依据是 `/etc/sing-box/.config.sha256`，也就是 `sc` 上次写入内容的摘要；从没跑过这个版本的机器还没有这份记录，所以在它第一次重新生成之前不会打印任何东西。

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
- `config.json` 由 `nodes.json` 生成，内嵌同样的凭据，因此同样是权限 600。两者都是先写进一个「落第一个字节之前就已经是 600」的新文件，再原子地移动到正式路径，所以它们在任何一个瞬间都不会被 root 以外的人读到 —— 包括正在被写入的那一瞬间。附带的影响：`sing-box check -c /etc/sing-box/config.json` 现在需要 root 才能执行，这是应有的行为
- `sc` CLI 通过 sudoers NOPASSWD 实现免密，规则范围只限 `/usr/local/bin/sc` 这一个二进制
- `sc` 自身是 root 拥有，普通用户无法修改，所以 NOPASSWD 不会被绕过
- 若机器多用户共享，请评估是否需要把 NOPASSWD 改为有密码

## 🤝 贡献

欢迎 PR。优先方向：

- [ ] 支持订阅链接自动更新
- [x] 支持 selector 之外的 urltest（自动选最快节点）
- [x] 支持 RHEL / Fedora / Arch 系发行版
- [ ] 添加节点延迟测试命令 `sc ping`
- [ ] 节点导入/导出（JSON 备份）

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE)
