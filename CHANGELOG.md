# Changelog

## [0.1.0] - 2026-05-08

首次发布。

### 功能

- `sc` CLI 命令行工具，包含 `ls / now / use / add / rm / on / off / status / mode / default-tun / sysproxy / update-rules / update-interval / log / reload / uninstall / help`
- 支持的分享链接协议：vless, vmess, trojan, ss, hysteria2, tuic
  - 包括 VLESS Reality + Vision、WebSocket、gRPC、HTTP/2、HTTPUpgrade 等传输层
- systemd 集成，开机自启，TUN 在用户登录前就已建立
- Clash API 即时切节点 / 切路由模式（无需重启服务）
- 规则集自动更新（默认每周，可通过 `sc update-interval` 配置）
- 完全中文化的命令输出和帮助文档
- 一行 curl 一键安装：`sudo bash -c "$(curl -fsSL .../install.sh)"`，无需 git clone
- 一键卸载（`sc uninstall` / `./uninstall.sh` / 一行 curl 三种方式），可选连同 sing-box 与 APT 源一并清掉，零残留

### 系统要求

- Debian / Ubuntu
- Python 3.6+
- systemd
