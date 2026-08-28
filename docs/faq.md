# 常见问题

## Q: 为什么不直接用 v2rayN？

v2rayN 是优秀的 GUI 客户端，但有两个限制无法满足某些场景：

1. **必须用户登录 GUI 才能跑**——SSH、apt 这些登录前的流量没法走代理
2. **TUN 模式需要 sudo 密码**——开机自启会卡在密码提示

singbox-cli 直接用 systemd 跑 sing-box，绕过 GUI 限制。

## Q: 加节点后 `sc status` 显示出口 IP 还是本机 IP？

先跑 `sc doctor`：它按因果顺序把二进制、规则集、配置、服务、TUN、策略路由、Clash API、DNS、出口 IP 一次报完，`[异常]` 出现在哪一行，原因通常就在那一行或它上面一行。它全程只读，坏机器上可以随便重复跑。

最容易被漏掉的一种是**策略路由丢了**：服务还在跑、`sb-tun` 还在，但把流量送进 TUN 路由表的那组 `ip rule` 没了，于是本机流量全部走物理网卡直连——`sc doctor` 的「策略路由」一项就是查这个。手工确认用 `ip rule show`（看有没有 `[unresolved]`）和 `ip route get 1.1.1.1`（看是不是经 `sb-tun`），恢复用 `sc reload`。

删规则的通常是 `systemd-networkd`（它默认会清理别的程序建的策略路由规则），所以安装器会放一份配置从源头挡住它；`sc doctor` 的「规则保护」那一行会告诉你这层保护在不在。如果保护已就位却仍然反复丢规则，那就是还有**别的**东西在删，该去查那个，而不是加自动重启。兜底手段见 README 的 `sc watchdog` 一节——默认关闭，只修这一件事，不判断节点质量。

它还没说清楚的三种情况：

1. **节点本身连不通**：`sc log -f` 看日志，有 `connection failed` 就是它
2. **测试域名被当成国内**：`api.ipify.org` 偶尔被 geosite-cn 误判，换 `ifconfig.me` 再试
3. **路由模式不是 rule 或 global**：`sc mode rule`

## Q: 装完之后 SSH 连不上了，怎么办？

按 `Ctrl+Alt+F3` 切到 tty3，本地登录后跑 `sc off`，然后排查：

- 通常是 `strict_route` 把入站 SSH 流量也劫持了。检查路由表 `ip route show table all`
- 或者节点 IP 解析回了 SSH 同一个网段，导致路由冲突

排查方法：把节点 IP 直接加到路由白名单：

```bash
sudo ip route add <节点IP>/32 dev <你的物理网卡>
```

## Q: 想换 sing-box 配置（DNS、规则等）怎么办？

写 `/etc/sing-box/override.json`。

**不要**改 `config.json`——它是生成物，`sc reload` / `add` / `rm` 每次都整份重写；也**不要**改 `bin/sc`，升级会覆盖掉。`sc` 从不创建、不写、不删 override.json，并且把它放在最后应用，所以它能挺过每一次重新生成，也能挺过重装。

合并规则、指令语法（`$prepend` / `$append` / `$replace` / `$before` / `$after`）和成套示例，见 README 的「自定义配置（override.json）」一节——那里是这件事的唯一说明，本文不再复述一份。

改节点参数仍然是编辑 `/etc/sing-box/nodes.json` 然后 `sc reload`。拿不准改动生效了没有：`sc doctor` 的「配置改动」一行会告诉你磁盘上这份是不是 `sc` 最后生成的那份。

## Q: 想用自己的 .srs 规则集？

**替换现有的**：把文件放到 `/etc/sing-box/rules/`，用现有文件名（如 `geoip-cn.srs`）覆盖，然后 `sc reload`。注意下次 `sc update-rules` 会把它换回官方版本。

**新增一个 tag**：不用改 `bin/sc`，在 override.json 里追加定义和引用即可——`sc` 是从生成出来的文档里读「哪些 rule-set 有定义」的，所以你自己定义的 tag 不会被当成悬空引用删掉：

```json
{
  "route": {
    "rule_set": { "$append": [
      {"tag": "my-set", "type": "local", "format": "binary", "path": "/etc/sing-box/rules/my-set.srs"}
    ] },
    "rules": { "$append": [
      {"rule_set": ["my-set"], "outbound": "direct"}
    ] }
  }
}
```

## Q: 流量统计、节点测速？

测速用 `sc ping`：它让正在运行的 sing-box 现测一次（`sc ls` 的「延迟」列是自动选择组探测留下的历史值，不是实时测量；`sc ping` 测完之后那一列显示的就是这次的结果）。`sc doctor` 会告诉你有多少个节点拿到了延迟值、自动选择组当前走哪个。

流量统计没做。

要图形界面，装一个 Web Dashboard 挂到 Clash API 上：

```bash
# 推荐 metacubexd，纯静态页面
sudo mkdir -p /etc/sing-box/dashboard
cd /etc/sing-box/dashboard
sudo curl -fsSL -o gh-pages.zip \
  https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
sudo unzip gh-pages.zip
```

然后在 `/etc/sing-box/override.json` 里加上 `external_ui`。对象是按层级合并的，所以只写这一个键，`external_controller` 和它的位置都不动：

```json
{ "experimental": { "clash_api": { "external_ui": "/etc/sing-box/dashboard/metacubexd-gh-pages" } } }
```

Clash API 端口是自动探测的高位端口（避免和 xray/clash/cockpit 等默认占用的 9090 冲突），具体值用 `sc status` 查看（或看 `/etc/sing-box/settings.json` 里的 `clash_api_port`）。`sc reload` 之后浏览器打开 `http://127.0.0.1:<端口>/ui/`，就能看到流量、延迟、节点切换等图形界面。

## Q: TUN 模式下 BT/PT 下载会出问题吗？

TUN 默认会代理所有 UDP，BT 大量 UDP 包会占满代理流量。建议：

- BT 应用绑定到非默认接口（如 `eth0`），绕过 TUN
- 或者通过 routing 规则把 BT 端口（一般 6881-6889）排除到 direct
- 或者临时 `sc off`，下完再 `sc on`

## Q: 升级 sing-box 后规则失效？

`sc update-rules` 重新拉一次。sing-box 1.10+ 之后 .srs 格式偶有调整，对应 ruleset 仓库会同步更新。

## Q: 多机共享一份配置？

`sc export /root/nodes.json` 导出，挪到另一台机器上 `sc import /root/nodes.json` 合并进去。

不建议直接 `cp /etc/sing-box/nodes.json`：那份文件里有全部密码和 UUID，手工复制出来的副本经常是 0644，而 `sc export` 是原子写入、权限 600、root 所有；`sc import` 还会在保留之前先校验一遍配置，生成不出可用配置就一字节不差地还原。它是合并而不是覆盖，所以目标机器上已有的节点不会丢，重复导入也是空操作。

如果想云端同步：

- 简单方案：放进 git private repo，写 systemd timer 定期 pull
- 或者用 Syncthing 同步 `/etc/sing-box/`

## Q: 我想贡献代码，从哪里开始？

README 的「贡献」一节有一份优先方向清单。或者直接开 issue 描述你的需求，并贴上 `sc doctor` 的输出——它第一行就是这个构建的版本号，没有它就说不清是哪一版产生的问题。
