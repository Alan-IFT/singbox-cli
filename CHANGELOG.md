# Changelog

## [Unreleased]

### 新增

- **规则集多镜像回退 + 下载校验 + 进度显示**：`sc update-rules` 不再只认 GitHub 一个地址，而是按顺序尝试 jsDelivr / testingcf / ghfast / raw.githubusercontent 四个镜像，任何一个失败（连不上、非 2xx、内容不合法）就换下一个；同一次运行中已失败的源会被跳过，所以四个镜像的总耗时与过去单个地址一致，超时时间没有任何改动。前面的镜像失败、后面的镜像成功时，失败原因会追加在该规则集那一行结果之后（`；已回退，前序镜像未成功：<镜像> -> <原因>`），镜像配错或某个源挂掉不会因为有备用源就被悄悄掩盖，`/var/log/sing-box/install.log` 里一眼可见；四个镜像都正常时这一段不会出现，输出与过去完全一致。下载改为分块读取：内容必须带 `SRS` magic、达到最小体积，且在响应声明了 `Content-Length` 时收到的字节数必须与之相等，校验通过后才原子替换到正式路径 —— HTML 错误页和传输不完整的响应永远不会落盘。终端下显示实时进度（字节数 / 百分比），输出被重定向到文件或日志时保持每个规则集一行结果、不含任何 `\r`。临时文件名带上进程号，定时任务与手工执行并发时不会互相破坏；上一次被杀死的运行残留的临时文件会在下次下载该规则集时清掉。新增 `--mirror <基地址>`（可重复）与 `SB_RULES_BASE` 环境变量用于指定镜像，两者都是替换内置列表而非追加。

### 修复

- **规则集缺失不再导致服务起不来**：以前 `config.json` 里那四条 `rule_set` 定义是无条件写入的，只要 `.srs` 没下载下来，sing-box 就会在路由初始化阶段 FATAL（`parse rule-set[0]: open .../geoip-cn.srs: no such file`），配置校验失败，服务永远起不来，后续每次 `sc add` 都重复同样的报错 —— 一个可选的分流优化变成了硬性启动依赖。现在生成配置时会逐个判断规则集是否可用（存在、是普通文件、带 `SRS` magic、达到最小体积），只写入可用的定义，并把 `dns.rules` 和 `route.rules` 中引用了不可用规则集的规则一并剔除（引用了多个规则集的规则只保留可用的那些），因此配置里不会再出现指向未定义标签的引用。降级是逐个文件的，不是全有全无：四个里坏一个就只掉那一个。降级不算错误，`sc add / rm / use / mode / default-tun / reload` 照常成功返回。每次生成降级配置都会在 stderr 用双语提示「几个 / 共几个不可用、分别是哪些、原因是什么、用哪两条命令恢复」，并区分「全部不可用 = 已降级为无分流模式」和「部分不可用 = 已跳过引用它们的分流规则」两种措辞。`sc update-rules` 补齐规则集后会自动重新生成配置并（在服务正在运行时）重启，无需再手动执行 `sc reload`。

- **Clash API 端口自动探测**：以前 `external_controller` 写死为 `127.0.0.1:9090`，与 xray / clash / cockpit 等同样默认占用 9090 的服务安装在同一台机器时会 `bind: address already in use`，导致 sing-box 启动即崩溃、TUN 建不起来。现在改为在高位区间（`29090` 起）自动探测一个空闲端口，写入 `settings.json` 的 `clash_api_port` 后固定复用（不会在重启时漂移）；`settings.json` 中已存在的值会被原样沿用，可手动指定。`sc status` 会显示当前 Clash API 端口。
- **安装器如实报告安装结果**：以前 `install.sh` 第 7 步先执行 `sc reload` 再 `systemctl enable --now`，一旦规则集下载失败导致配置校验不通过，脚本会在 `set -e` 下直接中断，开机自启和自动更新定时器都没来得及注册；第 6、7 步的错误又全部丢进 `/dev/null`，结尾还无条件打印「✅ 安装完成」。现在：先无条件注册开机自启（`systemctl enable` / `rc-update add`，失败也不中断），再按配置生成是否成功决定要不要 `start` 服务；第 6、7 步的输出统一追加到 `/var/log/sing-box/install.log`（权限 0640，写不进去时如实说明而不是假装已记录）；结尾横幅与退出码都由记录的阶段状态推导——成功照旧，失败则打印失败原因、修复命令（`sc update-rules` / `sc reload` / `systemctl status sing-box`）和日志路径，并以非 0 退出。
- **规则集自动更新的 systemd 定时任务从来没跑起来过**：`sing-box-rules-update.service` 的 `ExecStart` 一直指向 `/usr/local/bin/proxy`——这个项目从未安装过叫 `proxy` 的可执行文件（安装器装的是 `/usr/local/bin/sc`），所以每周定时器一触发就以 `203/EXEC` 失败，README 里承诺的「规则集自动更新」在任何一台 systemd 机器上、任何一个版本里都没有真正执行过，`systemctl --failed` 里还会一直挂着这个单元。现在该单元执行 `/usr/local/bin/sc update-rules`。**升级方式**：重新跑一遍安装命令（`sudo bash -c "$(curl -fsSL .../install.sh)"`，或从仓库目录执行 `sudo ./install.sh`）即可——安装器会覆盖单元文件并自己执行 `systemctl daemon-reload`，无需手工改单元、无需重启定时器。**升级后会发生什么**：在定时器一直正常触发的机器上不会立刻补跑一次（触发时间戳始终在正常推进，与被触发的服务失败与否无关），第一次真正的自动更新在下一个每周触发点 + 最多 1 小时随机延迟；若定时器此前被停用过、时间戳已经过期，`Persistent=true` 会在安装结束后立刻补跑一次；想立刻跑一次可执行 `sudo systemctl start sing-box-rules-update.service`，注意这条命令只有在规则集内容确实发生变化时才会重启 sing-box（那几秒连接会中断）；内容没变时不会碰服务；残留的 `failed` 状态可用 `sudo systemctl reset-failed sing-box-rules-update.service` 立即清掉，不清也会在下一次成功运行后自动消失。
- **规则集更新不再无谓重启**：以前 `sc update-rules` 只要跑完就重启 sing-box —— 每周定时任务把四个文件重新下载一遍、内容一个字节都没变，也照样重启，把所有连接（包括远程管理自己的 SSH）断掉几秒。现在每次运行会在下载前后各观察一次磁盘上的规则集，只有当某个规则集的内容真的发生变化（按完整内容比对，不看修改时间、不看文件大小、不看「请求成功了」）时才会重启，并在输出里点名是哪几个规则集变了；内容没变就完全不碰服务。规则集从不可用变为可用时，仍然会重新生成配置并（在服务正在运行时）重启，行为与之前一致。每次运行的最后一行都会如实说明这次到底动没动服务。

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
