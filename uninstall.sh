#!/usr/bin/env bash
# singbox-cli uninstaller
#
# 一键卸载（任意目录）：
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)"
#
# 已安装环境：
#   sc uninstall
# 或本地仓库：
#   sudo ./uninstall.sh
set -euo pipefail

LIB_DIR="/usr/local/lib/singbox-cli"

if [ "$EUID" -ne 0 ]; then
    echo "请以 root 身份运行（sudo bash uninstall.sh 或 sc uninstall）"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  singbox-cli 卸载"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "将删除："
echo "  - systemd 服务 sing-box, sing-box-rules-update.{service,timer}"
echo "  - /usr/local/bin/sc"
echo "  - /etc/sing-box/         （含节点配置）"
echo "  - /var/lib/sing-box/"
echo "  - /etc/sudoers.d/sc"
echo "  - $LIB_DIR/"
echo ""
ans=""
read -rp "确认卸载？[y/N] " ans || ans=""
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "已取消"; exit 0; }

systemctl disable --now sing-box 2>/dev/null || true
systemctl disable --now sing-box-rules-update.timer 2>/dev/null || true

rm -f /etc/systemd/system/sing-box.service
rm -f /etc/systemd/system/sing-box-rules-update.service
rm -f /etc/systemd/system/sing-box-rules-update.timer
rm -rf /etc/systemd/system/sing-box-rules-update.timer.d/
systemctl daemon-reload

# 同时清掉旧版本可能留下的文件名（proxy → sc 改名前的残留）
rm -f /usr/local/bin/sc /usr/local/bin/proxy
rm -f /etc/sudoers.d/sc /etc/sudoers.d/proxy
rm -rf /etc/sing-box/
rm -rf /var/lib/sing-box/
rm -rf "$LIB_DIR"

echo ""
purge=""
read -rp "是否同时移除 sing-box 二进制和 APT 源？这会让本机失去 sing-box 内核 [y/N] " purge || purge=""
if [ "$purge" = "y" ] || [ "$purge" = "Y" ]; then
    apt-get purge -y sing-box >/dev/null 2>&1 || true
    rm -f /etc/apt/sources.list.d/sagernet.sources
    rm -f /etc/apt/keyrings/sagernet.asc
    apt-get update -qq >/dev/null 2>&1 || true
    echo "  已移除 sing-box 与 APT 源"
fi

echo ""
echo "✅ 已卸载 singbox-cli"
