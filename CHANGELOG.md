# Changelog

## [Unreleased]

### 修复

- **Clash API 端口自动探测**：以前 `external_controller` 写死为 `127.0.0.1:9090`，与 xray / clash / cockpit 等同样默认占用 9090 的服务安装在同一台机器时会 `bind: address already in use`，导致 sing-box 启动即崩溃、TUN 建不起来。现在改为在高位区间（`29090` 起）自动探测一个空闲端口，写入 `settings.json` 的 `clash_api_port` 后固定复用（不会在重启时漂移）；`settings.json` 中已存在的值会被原样沿用，可手动指定。`sc status` 会显示当前 Clash API 端口。
- **安装器如实报告安装结果**：以前 `install.sh` 第 7 步先执行 `sc reload` 再 `systemctl enable --now`，一旦规则集下载失败导致配置校验不通过，脚本会在 `set -e` 下直接中断，开机自启和自动更新定时器都没来得及注册；第 6、7 步的错误又全部丢进 `/dev/null`，结尾还无条件打印「✅ 安装完成」。现在：先无条件注册开机自启（`systemctl enable` / `rc-update add`，失败也不中断），再按配置生成是否成功决定要不要 `start` 服务；第 6、7 步的输出统一追加到 `/var/log/sing-box/install.log`（权限 0640，写不进去时如实说明而不是假装已记录）；结尾横幅与退出码都由记录的阶段状态推导——成功照旧，失败则打印失败原因、修复命令（`sc update-rules` / `sc reload` / `systemctl status sing-box`）和日志路径，并以非 0 退出。

## [0.1.0] - 2026-05-08

首次发布。

### 功能

- `sc` CLI 命令行工具，包含 `ls / now / use / add / rm / on / off / status / mode / default-tun / sysproxy / update-rules / update-interval / log / reload / lang / uninstall / help`
- 支持的分享链接协议：vless, vmess, trojan, ss, hysteria2, tuic
  - 包括 VLESS Reality + Vision、WebSocket、gRPC、HTTP/2、HTTPUpgrade 等传输层
- systemd 集成，开机自启，TUN 在用户登录前就已建立
- Clash API 即时切节点 / 切路由模式（无需重启服务）
- 规则集自动更新（默认每周，可通过 `sc update-interval` 配置）
- **中英双语 UI**：默认英文，安装时由用户选择，`sc lang en|zh` 随时切换；install.sh / uninstall.sh / sc 全部覆盖
- 一行 curl 一键安装：`sudo bash -c "$(curl -fsSL .../install.sh)"`，无需 git clone
- 一键卸载（`sc uninstall` / `./uninstall.sh` / 一行 curl 三种方式），可选连同 sing-box 与 APT 源一并清掉，零残留

### 系统要求

- Debian / Ubuntu
- Python 3.6+
- systemd
