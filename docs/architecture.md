# 架构详解

## 设计目标

1. **登录前可用**：含 SSH、apt、headless 服务器场景
2. **零 GUI 依赖**：纯 CLI，可用于 Docker 容器、minimal 镜像
3. **路由规则与 sing-box 一致**：复用官方 .srs 规则集格式
4. **配置可读可编辑**：所有配置文件是 JSON，紧急情况可手动修复

## 数据流

```
┌─────────────────┐
│   用户/进程     │ (浏览器、curl、apt、SSH 等)
└────────┬────────┘
         ↓ TCP/UDP 包
┌─────────────────────────────────┐
│   Linux 内核                    │
│   strict_route 把所有非本地     │
│   流量送进 sb-tun 接口          │
└────────┬────────────────────────┘
         ↓
┌─────────────────────────────────┐
│   sb-tun (172.19.0.1/30)        │
└────────┬────────────────────────┘
         ↓ 用户态 TUN
┌─────────────────────────────────┐
│   sing-box（systemd, root）     │
│                                 │
│   1. sniff（识别协议/SNI）      │
│   2. DNS hijack（拦截 :53）     │
│   3. 路由规则匹配               │
│      - process: sing-box → direct (防回环) │
│      - clash_mode 匹配          │
│      - rule_set 匹配 (.srs)     │
│      - final → "proxy" selector │
│   4. selector 选当前激活节点    │
│   5. 节点出站协议（vless/...）  │
└────────┬────────────────────────┘
         ↓
┌─────────────────────────────────┐
│   物理网卡（绕过 sb-tun）       │
│   auto_detect_interface=true    │
│   保证不回环                    │
└────────┬────────────────────────┘
         ↓
       Internet
```

## 关键文件之间的关系

```
nodes.json + settings.json
         │
         │  sc reload / sc add / sc use ...
         ↓
   generate_config()
         │
         ↓
   config.json  ──>  sing-box check
         │              │
         │              └─ 失败则不重启，错误打到 stderr
         ↓
   systemctl restart sing-box
         │
         ↓
   sing-box 加载新配置
         │
         ├─ TUN 接口建立 / 调整
         ├─ Clash API 启动 (127.0.0.1:<自动探测的高位端口>)
         └─ 路由表插入规则
```

## 切节点为什么不需要重启

selector 出站类型支持运行时切换默认节点。`sc use <name>` 实际做的是：

1. 修改 `nodes.json` 的 `active` 字段（持久化）
2. 通过 Clash API `PUT /proxies/proxy {"name": "<tag>"}` 通知 sing-box
3. sing-box 内部把 selector 的当前选择切换到新节点
4. 老节点的现有连接立即中断（`interrupt_exist_connections: true`）
5. 后续新连接走新节点

整个过程毫秒级完成，无需重启服务。

## 加节点为什么需要重启

加新节点意味着 outbound 列表里多一个条目，selector 可选项也要扩展。这两个都是启动时确定的结构，sing-box 目前没有暴露「热加入 outbound」的 API。所以 `sc add` 会：

1. 把节点写入 `nodes.json`
2. 重新生成 `config.json`
3. 重启 sing-box（中断 ~1 秒）

切路由模式同样通过 Clash API 动态生效，不重启。

## 防回环机制

最容易踩的坑是 sing-box 自己的出站连接（连节点用的）也被 TUN 抢走，导致死循环。三层防护：

1. **`auto_detect_interface: true`**：sing-box 知道哪个是物理网卡，主动绑定
2. **`outbound: direct, process_name: ["sing-box"]`**：路由规则显式让 sing-box 自己的连接走 direct
3. **strict_route 的隐式排除**：sing-box 主动给自己的目标 IP 加路由排除

## 规则集 .srs 格式

`.srs` 是 sing-box 自创的二进制规则集格式，比 v2ray 的 `.dat` 体积小、加载快、按需编译。来源是 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的 `sing` 分支。

`sc update-rules` 会从 GitHub raw 下载这些文件到 `/etc/sing-box/rules/`：

- `geoip-cn.srs` — 中国大陆 IP 段
- `geosite-cn.srs` — 中国大陆域名（含主流站点）
- `geosite-google.srs` — Google 系域名（强制走代理）
- `geosite-private.srs` — 私网域名（localhost、.local 等，强制 direct）

## 安全考量

| 资产 | 保护手段 |
|---|---|
| `nodes.json`（含密码/UUID） | mode 600，仅 root 可读 |
| `config.json`（由 nodes.json 生成，内嵌同样的凭据） | mode 600，仅 root 可读；先建一个空文件并把权限设成 600，再写内容、原子替换，所以写入过程中也不会宽于 600 |
| `sc` CLI 自身 | mode 755 root:root，普通用户改不动 |
| sudoers NOPASSWD | 范围限定为 `/usr/local/bin/sc`，不是 ALL |
| sing-box 进程 | systemd 启动，root 权限运行（TUN 需要 CAP_NET_ADMIN） |

如果是多用户环境，建议把 NOPASSWD 改回有密码模式：

```bash
sudo rm /etc/sudoers.d/sc
```

之后每次跑 `sc ...` 会要密码。
