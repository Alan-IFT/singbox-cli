#!/usr/bin/env bash
# singbox-cli uninstaller
# Usage: sudo ./uninstall.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "请以 root 身份运行（sudo ./uninstall.sh）"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  singbox-cli 卸载"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "将会删除："
echo "  - systemd 服务 sing-box, sing-box-rules-update.{service,timer}"
echo "  - /usr/local/bin/proxy"
echo "  - /etc/sing-box/  (含节点和配置)"
echo "  - /var/lib/sing-box/"
echo "  - /etc/sudoers.d/proxy"
echo ""
echo "保留："
echo "  - sing-box 二进制本身"
echo "  - sing-box APT 源"
echo ""
read -rp "确认卸载？[y/N] " ans
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "已取消"; exit 0; }

systemctl disable --now sing-box 2>/dev/null || true
systemctl disable --now sing-box-rules-update.timer 2>/dev/null || true

rm -f /etc/systemd/system/sing-box.service
rm -f /etc/systemd/system/sing-box-rules-update.service
rm -f /etc/systemd/system/sing-box-rules-update.timer
rm -rf /etc/systemd/system/sing-box-rules-update.timer.d/
systemctl daemon-reload

rm -f /usr/local/bin/proxy
rm -f /etc/sudoers.d/proxy
rm -rf /etc/sing-box/
rm -rf /var/lib/sing-box/

echo ""
echo "✅ 已卸载 singbox-cli"
echo ""
echo "如需进一步彻底移除 sing-box 本身："
echo "  sudo apt-get purge -y sing-box"
echo "  sudo rm /etc/apt/sources.list.d/sagernet.sources"
echo "  sudo rm /etc/apt/keyrings/sagernet.asc"
