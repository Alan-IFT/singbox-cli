# 常见问题

## Q: 为什么不直接用 v2rayN？

v2rayN 是优秀的 GUI 客户端，但有两个限制无法满足某些场景：

1. **必须用户登录 GUI 才能跑**——SSH、apt 这些登录前的流量没法走代理
2. **TUN 模式需要 sudo 密码**——开机自启会卡在密码提示

singbox-cli 直接用 systemd 跑 sing-box，绕过 GUI 限制。

## Q: 加节点后 `sc status` 显示出口 IP 还是本机 IP？

可能性：

1. **节点本身有问题**：用 `sc log -f` 看日志，如果有 `connection failed` 就是节点连不通
2. **路由规则把目标 IP 当国内**：`api.ipify.org` 偶尔被 geosite-cn 误判，换个测试域名（如 `ifconfig.me`）
3. **mode 不是 rule 或 global**：`sc mode rule`

## Q: 装完之后 SSH 连不上了，怎么办？

按 `Ctrl+Alt+F3` 切到 tty3，本地登录后跑 `sc off`，然后排查：

- 通常是 `strict_route` 把入站 SSH 流量也劫持了。检查路由表 `ip route show table all`
- 或者节点 IP 解析回了 SSH 同一个网段，导致路由冲突

排查方法：把节点 IP 直接加到路由白名单：

```bash
sudo ip route add <节点IP>/32 dev <你的物理网卡>
```

## Q: 想换 sing-box 配置（DNS、规则等）怎么办？

`sc reload` 会从 `bin/sc` 里的 `generate_config()` 函数重新生成 `config.json`，所以你**不能**直接改 `config.json`（会被覆盖）。

正确做法：

- 改路由规则、DNS 等模板：直接编辑 `bin/sc` 里的 `generate_config()` 函数，然后 `sc reload`
- 改节点参数：编辑 `/etc/sing-box/nodes.json`，然后 `sc reload`

## Q: 想用自己的 .srs 规则集？

把文件放到 `/etc/sing-box/rules/` 下，文件名照 `geoip-cn.srs` 这样的现有规则命名（覆盖掉默认下载的）。然后 `sc reload` 让 sing-box 加载。

如果想加全新的规则集 tag，需要改 `bin/sc` 里的 `generate_config()` 把它注册到 `route.rule_set` 里。

## Q: 流量统计、节点测速？

目前没做，因为 sing-box 的 Clash API 已经暴露了相关接口，可以直接装一个 Web Dashboard：

```bash
# 推荐 metacubexd，纯静态页面
sudo mkdir -p /etc/sing-box/dashboard
cd /etc/sing-box/dashboard
sudo curl -fsSL -o gh-pages.zip \
  https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
sudo unzip gh-pages.zip
```

然后修改 `generate_config()` 里 `clash_api` 段，添加 `external_ui` 字段：

```python
"clash_api": {
    "external_controller": f"127.0.0.1:{CLASH_PORT}",
    "external_ui": "/etc/sing-box/dashboard/metacubexd-gh-pages",
}
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

`/etc/sing-box/nodes.json` 复制过去就行。如果想云端同步：

- 简单方案：放进 git private repo，写 systemd timer 定期 pull
- 或者用 Syncthing 同步 `/etc/sing-box/`

## Q: 我想贡献代码，从哪里开始？

`README.md` 有 TODO 列表。或者直接开 issue 描述你的需求。
