#!/usr/bin/env bash
# singbox-cli uninstaller
#
# One-line / 一键卸载（任意目录）：
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/uninstall.sh)"
#
# Already installed / 已安装环境：
#   sc uninstall
# Or local repo / 或本地仓库：
#   sudo ./uninstall.sh
set -euo pipefail

LIB_DIR="/usr/local/lib/singbox-cli"
SETTINGS_PATH="/etc/sing-box/settings.json"

# Read distro-info written by installer (defaults to systemd for backward compat)
INIT_SYS="systemd"
if [ -f "$LIB_DIR/distro-info" ]; then
    # shellcheck disable=SC1090
    . "$LIB_DIR/distro-info"
fi

# Pick language: settings.json's lang first, else $LANG env, else en.
LANG_CHOICE="en"
if [ -f "$SETTINGS_PATH" ]; then
    LANG_CHOICE=$(python3 -c "import json,sys
try:
    print(json.load(open('$SETTINGS_PATH')).get('lang','en'))
except Exception:
    print('en')" 2>/dev/null || echo en)
elif case "${LANG:-}" in zh*|ZH*) true ;; *) false ;; esac; then
    LANG_CHOICE="zh"
fi

t() {
    local key="$1"
    shift || true
    local fmt
    if [ "$LANG_CHOICE" = "zh" ]; then
        case "$key" in
            run_as_root)    fmt="请以 root 身份运行（sudo bash uninstall.sh 或 sc uninstall）" ;;
            banner)         fmt="  singbox-cli 卸载" ;;
            will_remove)    fmt="将删除：" ;;
            list_systemd)   fmt="  - systemd 服务 sing-box, sing-box-rules-update.{service,timer}" ;;
            list_openrc)    fmt="  - OpenRC 服务 sing-box (/etc/init.d/sing-box)" ;;
            list_bin)       fmt="  - /usr/local/bin/sc" ;;
            list_etc)       fmt="  - /etc/sing-box/         （含节点配置）" ;;
            list_var)       fmt="  - /var/lib/sing-box/" ;;
            list_log)       fmt="  - /var/log/sing-box/" ;;
            list_sudoers)   fmt="  - /etc/sudoers.d/sc" ;;
            list_lib)       fmt="  - %s/" ;;
            confirm)        fmt="确认卸载？[y/N] " ;;
            cancelled)      fmt="已取消" ;;
            purge_q)        fmt="是否同时移除 sing-box 二进制（/usr/local/bin/sing-box）？这会让本机失去 sing-box 内核 [y/N] " ;;
            purge_done)     fmt="  已移除 sing-box" ;;
            done_banner)    fmt="✅ 已卸载 singbox-cli" ;;
        esac
    else
        case "$key" in
            run_as_root)    fmt="Run as root (sudo bash uninstall.sh, or sc uninstall)" ;;
            banner)         fmt="  singbox-cli uninstall" ;;
            will_remove)    fmt="The following will be removed:" ;;
            list_systemd)   fmt="  - systemd units sing-box, sing-box-rules-update.{service,timer}" ;;
            list_openrc)    fmt="  - OpenRC service sing-box (/etc/init.d/sing-box)" ;;
            list_bin)       fmt="  - /usr/local/bin/sc" ;;
            list_etc)       fmt="  - /etc/sing-box/         (incl. node configs)" ;;
            list_var)       fmt="  - /var/lib/sing-box/" ;;
            list_log)       fmt="  - /var/log/sing-box/" ;;
            list_sudoers)   fmt="  - /etc/sudoers.d/sc" ;;
            list_lib)       fmt="  - %s/" ;;
            confirm)        fmt="Confirm uninstall? [y/N] " ;;
            cancelled)      fmt="Cancelled" ;;
            purge_q)        fmt="Also remove the sing-box binary (/usr/local/bin/sing-box)? This leaves the machine without the sing-box core. [y/N] " ;;
            purge_done)     fmt="  Removed sing-box" ;;
            done_banner)    fmt="✅ singbox-cli uninstalled" ;;
        esac
    fi
    if [ "$#" -gt 0 ]; then
        # shellcheck disable=SC2059
        printf "$fmt\n" "$@"
    else
        printf "%s\n" "$fmt"
    fi
}

if [ "$EUID" -ne 0 ]; then
    t run_as_root
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
t banner
echo "═══════════════════════════════════════════════════════"
echo ""
t will_remove
if [ "$INIT_SYS" = "openrc" ]; then
    t list_openrc
else
    t list_systemd
fi
t list_bin
t list_etc
t list_var
t list_log
t list_sudoers
t list_lib "$LIB_DIR"
echo ""
ans=""
printf "%s" "$(t confirm)"
read -r ans || ans=""
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { t cancelled; exit 0; }

if [ "$INIT_SYS" = "openrc" ]; then
    rc-service sing-box stop 2>/dev/null || true
    rc-update del sing-box default 2>/dev/null || true
    rm -f /etc/init.d/sing-box
    # Also remove periodic cron jobs if any were set up
    rm -f /etc/periodic/daily/singbox-update-rules
    rm -f /etc/periodic/weekly/singbox-update-rules
    rm -f /etc/periodic/monthly/singbox-update-rules
else
    systemctl disable --now sing-box 2>/dev/null || true
    systemctl disable --now sing-box-rules-update.timer 2>/dev/null || true

    rm -f /etc/systemd/system/sing-box.service
    rm -f /etc/systemd/system/sing-box-rules-update.service
    rm -f /etc/systemd/system/sing-box-rules-update.timer
    rm -rf /etc/systemd/system/sing-box-rules-update.timer.d/
    systemctl daemon-reload 2>/dev/null || true
fi

# Also remove legacy `proxy` filenames left from pre-rename installs.
rm -f /usr/local/bin/sc /usr/local/bin/proxy
rm -f /etc/sudoers.d/sc /etc/sudoers.d/proxy
rm -rf /etc/sing-box/
rm -rf /var/lib/sing-box/
rm -rf /var/log/sing-box/
rm -rf "$LIB_DIR"

echo ""
purge=""
printf "%s" "$(t purge_q)"
read -r purge || purge=""
if [ "$purge" = "y" ] || [ "$purge" = "Y" ]; then
    rm -f /usr/local/bin/sing-box
    # Also clean up any leftover APT source from older installs
    rm -f /etc/apt/sources.list.d/sagernet.sources
    rm -f /etc/apt/keyrings/sagernet.asc
    t purge_done
fi

echo ""
t done_banner
