#!/usr/bin/env bash
# singbox-cli installer
#
# One-liner / 一键安装：
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
#
# Local install / 本地仓库安装：
#   sudo ./install.sh
set -euo pipefail

REPO="Alan-IFT/singbox-cli"
REF="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"
LIB_DIR="/usr/local/lib/singbox-cli"

# ----------------- i18n -----------------
# Initial guess from $LANG; user confirms or overrides at the prompt below.
LANG_CHOICE="en"
case "${LANG:-}" in zh*|ZH*) LANG_CHOICE="zh" ;; esac

t() {
    local key="$1"
    shift || true
    local fmt
    if [ "$LANG_CHOICE" = "zh" ]; then
        case "$key" in
            run_as_root)         fmt="请以 root 身份运行（sudo bash install.sh 或参考 README 的一行安装命令）" ;;
            apt_only)            fmt="本安装器仅支持 Debian / Ubuntu 系发行版" ;;
            no_user)             fmt="⚠️  检测不到普通用户身份。建议先 sudo 切到普通用户再运行。" ;;
            install_root_prompt) fmt="   当前将为 root 安装（继续? [y/N]）" ;;
            downloading)         fmt="● 从 %s 下载安装文件 ..." ;;
            download_failed)     fmt="✗ 下载失败：%s" ;;
            check_network)       fmt="  请检查网络后重试" ;;
            banner)              fmt="  singbox-cli 安装" ;;
            target_user)         fmt="  目标用户：%s" ;;
            install_source)      fmt="  安装来源：%s" ;;
            language_chosen)     fmt="  语言：%s" ;;
            step1)               fmt="▶ [1/7] 安装系统依赖 ..." ;;
            step2_already)       fmt="▶ [2/7] sing-box 已安装：%s" ;;
            step2_installing)    fmt="▶ [2/7] 添加 sing-box 官方 APT 源并安装 ..." ;;
            step2_done)          fmt="  已安装：%s" ;;
            step3)               fmt="▶ [3/7] 安装 sc CLI ..." ;;
            step4)               fmt="▶ [4/7] 安装 systemd 服务 ..." ;;
            step5)               fmt="▶ [5/7] 配置免密 sudo（仅针对 /usr/local/bin/sc）..." ;;
            step6)               fmt="▶ [6/7] 下载规则集 (.srs) ..." ;;
            step6_ok)            fmt="  下载完成" ;;
            step6_warn)          fmt="  ⚠️ 下载失败（可能是网络问题），稍后用 'sc update-rules' 重试" ;;
            step7)               fmt="▶ [7/7] 生成初始配置并启动服务 ..." ;;
            done_banner)         fmt="  ✅ 安装完成" ;;
            next_steps)          fmt="下一步：" ;;
            next_add)            fmt="  1. 添加节点：    sc add 'vless://...'" ;;
            next_status)         fmt="  2. 查看状态：    sc status" ;;
            next_help)           fmt="  3. 查看帮助：    sc help" ;;
            next_lang)           fmt="  4. 切换语言：    sc lang en|zh" ;;
            next_uninstall)      fmt="  5. 卸载：        sc uninstall" ;;
            note_initial)        fmt="（初始没有节点时，TUN 已建立但流量走 direct，加节点后自动切换）" ;;
        esac
    else
        case "$key" in
            run_as_root)         fmt="Run as root (sudo bash install.sh, or use the one-line install from the README)" ;;
            apt_only)            fmt="This installer only supports Debian / Ubuntu" ;;
            no_user)             fmt="⚠️  Cannot detect a regular user. Consider re-running with sudo from a normal account." ;;
            install_root_prompt) fmt="   Will install for root. Continue? [y/N]" ;;
            downloading)         fmt="● Downloading install files from %s ..." ;;
            download_failed)     fmt="✗ Download failed: %s" ;;
            check_network)       fmt="  Please check your network and retry" ;;
            banner)              fmt="  singbox-cli installer" ;;
            target_user)         fmt="  Target user:    %s" ;;
            install_source)      fmt="  Source:         %s" ;;
            language_chosen)     fmt="  Language:       %s" ;;
            step1)               fmt="▶ [1/7] Installing system dependencies ..." ;;
            step2_already)       fmt="▶ [2/7] sing-box already installed: %s" ;;
            step2_installing)    fmt="▶ [2/7] Adding the official sing-box APT source and installing ..." ;;
            step2_done)          fmt="  Installed: %s" ;;
            step3)               fmt="▶ [3/7] Installing the sc CLI ..." ;;
            step4)               fmt="▶ [4/7] Installing systemd units ..." ;;
            step5)               fmt="▶ [5/7] Configuring NOPASSWD sudo (scoped to /usr/local/bin/sc) ..." ;;
            step6)               fmt="▶ [6/7] Downloading rulesets (.srs) ..." ;;
            step6_ok)            fmt="  Done" ;;
            step6_warn)          fmt="  ⚠️ Download failed (likely a network issue) — retry later with 'sc update-rules'" ;;
            step7)               fmt="▶ [7/7] Generating initial config and starting the service ..." ;;
            done_banner)         fmt="  ✅ Install complete" ;;
            next_steps)          fmt="Next steps:" ;;
            next_add)            fmt="  1. Add a node:     sc add 'vless://...'" ;;
            next_status)         fmt="  2. Check status:   sc status" ;;
            next_help)           fmt="  3. Show help:      sc help" ;;
            next_lang)           fmt="  4. Switch lang:    sc lang en|zh" ;;
            next_uninstall)      fmt="  5. Uninstall:      sc uninstall" ;;
            note_initial)        fmt="(With no nodes yet, the TUN is up but traffic goes direct; adding a node switches it automatically.)" ;;
        esac
    fi
    if [ "$#" -gt 0 ]; then
        # shellcheck disable=SC2059
        printf "$fmt\n" "$@"
    else
        printf "%s\n" "$fmt"
    fi
}

# ----------------- pre-flight -----------------
if [ "$EUID" -ne 0 ]; then
    t run_as_root
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    t apt_only
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq curl >/dev/null
fi

# ----------------- language choice -----------------
default_choice="1"
[ "$LANG_CHOICE" = "zh" ] && default_choice="2"
echo ""
echo "Language / 语言"
echo "  1) English"
echo "  2) 简体中文"
echo -n "Choice / 选择 [1-2] (default: $default_choice): "
lang_input=""
read -r lang_input || lang_input=""
case "$lang_input" in
    1|en|EN|english|English) LANG_CHOICE="en" ;;
    2|zh|ZH|chinese|Chinese|中文) LANG_CHOICE="zh" ;;
    "") [ "$default_choice" = "2" ] && LANG_CHOICE="zh" || LANG_CHOICE="en" ;;
    *) [ "$default_choice" = "2" ] && LANG_CHOICE="zh" || LANG_CHOICE="en" ;;
esac

INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$INSTALL_USER" ] || [ "$INSTALL_USER" = "root" ]; then
    t no_user
    t install_root_prompt
    ans=""
    read -r ans || ans=""
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
    INSTALL_USER="root"
fi

# 确定安装文件来源：本地 clone 或远程下载
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/sc" ]; then
    ARTIFACT_DIR="$SCRIPT_DIR"
    SOURCE_DESC="local repo ($ARTIFACT_DIR)"
    [ "$LANG_CHOICE" = "zh" ] && SOURCE_DESC="本地仓库 ($ARTIFACT_DIR)"
else
    ARTIFACT_DIR="$(mktemp -d -t singbox-cli-install.XXXXXX)"
    trap 'rm -rf "$ARTIFACT_DIR"' EXIT
    SOURCE_DESC="$REPO@$REF"
    t downloading "$SOURCE_DESC"
    mkdir -p "$ARTIFACT_DIR/bin" "$ARTIFACT_DIR/systemd"
    for rel in \
        bin/sc \
        uninstall.sh \
        systemd/sing-box.service \
        systemd/sing-box-rules-update.service \
        systemd/sing-box-rules-update.timer
    do
        if ! curl -fsSL "$RAW_BASE/$rel" -o "$ARTIFACT_DIR/$rel"; then
            t download_failed "$RAW_BASE/$rel"
            t check_network
            exit 1
        fi
    done
fi

echo "═══════════════════════════════════════════════════════"
t banner
echo "═══════════════════════════════════════════════════════"
t target_user "$INSTALL_USER"
t install_source "$SOURCE_DESC"
t language_chosen "$LANG_CHOICE"
echo ""

# ----------------- step 1: deps -----------------
t step1
apt-get update -qq
apt-get install -y -qq curl python3 ca-certificates >/dev/null

# ----------------- step 2: sing-box -----------------
if command -v sing-box >/dev/null 2>&1; then
    t step2_already "$(sing-box version | head -1)"
else
    t step2_installing
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
    chmod a+r /etc/apt/keyrings/sagernet.asc
    cat > /etc/apt/sources.list.d/sagernet.sources <<'EOF'
Types: deb
URIs: https://deb.sagernet.org/
Suites: *
Components: *
Enabled: yes
Signed-By: /etc/apt/keyrings/sagernet.asc
EOF
    apt-get update -qq
    apt-get install -y -qq sing-box
    t step2_done "$(sing-box version | head -1)"
fi

# ----------------- step 3: dirs + sc CLI + uninstall.sh -----------------
t step3
mkdir -p /etc/sing-box/rules /var/lib/sing-box "$LIB_DIR"
install -m 755 "$ARTIFACT_DIR/bin/sc" /usr/local/bin/sc
install -m 755 "$ARTIFACT_DIR/uninstall.sh" "$LIB_DIR/uninstall.sh"

# Persist chosen language to settings.json before the first `sc reload`,
# so the CLI picks it up immediately. Preserves any pre-existing settings.
python3 - "$LANG_CHOICE" <<'PY'
import json, os, sys
from pathlib import Path
lang = sys.argv[1]
p = Path("/etc/sing-box/settings.json")
p.parent.mkdir(parents=True, exist_ok=True)
data = {"default_tun": True, "mode": "rule", "lang": "en"}
if p.exists():
    try:
        data.update(json.loads(p.read_text()))
    except json.JSONDecodeError:
        pass
data["lang"] = lang
p.write_text(json.dumps(data, indent=2))
PY

# ----------------- step 4: systemd units -----------------
t step4
install -m 644 "$ARTIFACT_DIR/systemd/sing-box.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.timer" /etc/systemd/system/
systemctl daemon-reload

# ----------------- step 5: sudoers -----------------
t step5
cat > /etc/sudoers.d/sc <<EOF
$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/sc
EOF
chmod 440 /etc/sudoers.d/sc
visudo -c -f /etc/sudoers.d/sc >/dev/null

# ----------------- step 6: rulesets -----------------
t step6
if /usr/local/bin/sc update-rules >/dev/null 2>&1; then
    t step6_ok
else
    t step6_warn
fi

# ----------------- step 7: enable + start -----------------
t step7
/usr/local/bin/sc reload >/dev/null
systemctl enable --now sing-box >/dev/null 2>&1
systemctl enable --now sing-box-rules-update.timer >/dev/null 2>&1

echo ""
echo "═══════════════════════════════════════════════════════"
t done_banner
echo "═══════════════════════════════════════════════════════"
echo ""
t next_steps
t next_add
t next_status
t next_help
t next_lang
t next_uninstall
echo ""
t note_initial
