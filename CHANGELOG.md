# Changelog

## [0.1.0] - 2026-05-08

首次发布。

### 功能

- `proxy` CLI 命令行工具，包含 `ls / now / use / add / rm / on / off / status / mode / default-tun / sysproxy / update-rules / update-interval / log / reload / help`
- 支持的分享链接协议：vless, vmess, trojan, ss, hysteria2, tuic
  - 包括 VLESS Reality + Vision、WebSocket、gRPC、HTTP/2、HTTPUpgrade 等传输层
- systemd 集成，开机自启，TUN 在用户登录前就已建立
- Clash API 即时切节点 / 切路由模式（无需重启服务）
- 规则集自动更新（默认每周，可通过 `proxy update-interval` 配置）
- 完全中文化的命令输出和帮助文档
- 一键安装脚本（自动添加 sing-box 官方 APT 源）
- 一键卸载脚本

### 系统要求

- Debian / Ubuntu
- Python 3.6+
- systemd
