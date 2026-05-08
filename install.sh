#!/usr/bin/env bash
# singbox-cli installer
#
# 一键安装：
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
#
# 本地仓库安装：
#   sudo ./install.sh
set -euo pipefail

REPO="Alan-IFT/singbox-cli"
REF="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"
LIB_DIR="/usr/local/lib/singbox-cli"

# ----------------- pre-flight -----------------
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 身份运行（sudo bash install.sh 或参考 README 一键命令）"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "本安装器仅支持 Debian / Ubuntu 系发行版"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq curl >/dev/null
fi

INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
if [ -z "$INSTALL_USER" ] || [ "$INSTALL_USER" = "root" ]; then
    echo "⚠️  检测不到普通用户身份。建议先 sudo 切到普通用户再运行。"
    echo "   当前将为 root 安装（继续? [y/N]）"
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
    INSTALL_USER="root"
fi

# 确定安装文件来源：本地 clone 或远程下载
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/sc" ]; then
    ARTIFACT_DIR="$SCRIPT_DIR"
    SOURCE_DESC="本地仓库 ($ARTIFACT_DIR)"
else
    ARTIFACT_DIR="$(mktemp -d -t singbox-cli-install.XXXXXX)"
    trap 'rm -rf "$ARTIFACT_DIR"' EXIT
    SOURCE_DESC="$REPO@$REF"
    echo "● 从 $SOURCE_DESC 下载安装文件 ..."
    mkdir -p "$ARTIFACT_DIR/bin" "$ARTIFACT_DIR/systemd"
    for rel in \
        bin/sc \
        uninstall.sh \
        systemd/sing-box.service \
        systemd/sing-box-rules-update.service \
        systemd/sing-box-rules-update.timer
    do
        if ! curl -fsSL "$RAW_BASE/$rel" -o "$ARTIFACT_DIR/$rel"; then
            echo "✗ 下载失败：$RAW_BASE/$rel"
            echo "  请检查网络后重试"
            exit 1
        fi
    done
fi

echo "═══════════════════════════════════════════════════════"
echo "  singbox-cli 安装"
echo "  目标用户：$INSTALL_USER"
echo "  安装来源：$SOURCE_DESC"
echo "═══════════════════════════════════════════════════════"
echo ""

# ----------------- step 1: deps -----------------
echo "▶ [1/7] 安装系统依赖 ..."
apt-get update -qq
apt-get install -y -qq curl python3 ca-certificates >/dev/null

# ----------------- step 2: sing-box -----------------
if command -v sing-box >/dev/null 2>&1; then
    echo "▶ [2/7] sing-box 已安装：$(sing-box version | head -1)"
else
    echo "▶ [2/7] 添加 sing-box 官方 APT 源并安装 ..."
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
    echo "  已安装：$(sing-box version | head -1)"
fi

# ----------------- step 3: dirs + sc CLI + uninstall.sh -----------------
echo "▶ [3/7] 安装 sc CLI ..."
mkdir -p /etc/sing-box/rules /var/lib/sing-box "$LIB_DIR"
install -m 755 "$ARTIFACT_DIR/bin/sc" /usr/local/bin/sc
install -m 755 "$ARTIFACT_DIR/uninstall.sh" "$LIB_DIR/uninstall.sh"

# ----------------- step 4: systemd units -----------------
echo "▶ [4/7] 安装 systemd 服务 ..."
install -m 644 "$ARTIFACT_DIR/systemd/sing-box.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.timer" /etc/systemd/system/
systemctl daemon-reload

# ----------------- step 5: sudoers -----------------
echo "▶ [5/7] 配置免密 sudo（仅针对 /usr/local/bin/sc）..."
cat > /etc/sudoers.d/sc <<EOF
$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/sc
EOF
chmod 440 /etc/sudoers.d/sc
visudo -c -f /etc/sudoers.d/sc >/dev/null

# ----------------- step 6: rulesets -----------------
echo "▶ [6/7] 下载规则集 (.srs) ..."
if /usr/local/bin/sc update-rules >/dev/null 2>&1; then
    echo "  下载完成"
else
    echo "  ⚠️ 下载失败（可能是网络问题），稍后用 'sc update-rules' 重试"
fi

# ----------------- step 7: enable + start -----------------
echo "▶ [7/7] 生成初始配置并启动服务 ..."
/usr/local/bin/sc reload >/dev/null
systemctl enable --now sing-box >/dev/null 2>&1
systemctl enable --now sing-box-rules-update.timer >/dev/null 2>&1

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ 安装完成"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "下一步："
echo "  1. 添加节点：    sc add 'vless://...'"
echo "  2. 查看状态：    sc status"
echo "  3. 查看帮助：    sc help"
echo "  4. 卸载：        sc uninstall"
echo ""
echo "（初始没有节点时，TUN 已建立但流量走 direct，加节点后自动切换）"
