#!/usr/bin/env bash
# singbox-cli installer
#
# 一键安装（推荐）：
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Alan-IFT/singbox-cli/main/install.sh)"
#
# 本地仓库安装：
#   sudo ./install.sh
#
# 可用环境变量：
#   SINGBOX_CLI_REPO  默认 Alan-IFT/singbox-cli，用于安装 fork
#   SINGBOX_CLI_REF   默认 main，用于锁定到某个 tag/commit
#   FORCE_ROOT=1      非交互式下若检测不到普通用户，跳过确认直接装为 root
set -euo pipefail

REPO="${SINGBOX_CLI_REPO:-Alan-IFT/singbox-cli}"
REF="${SINGBOX_CLI_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"

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
    if [ "${FORCE_ROOT:-0}" = "1" ]; then
        INSTALL_USER="root"
    elif [ -t 0 ]; then
        echo "⚠️  检测不到普通用户身份。建议先 sudo 切到普通用户再运行。"
        echo "   当前将为 root 安装（继续? [y/N]）"
        read -r ans
        [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
        INSTALL_USER="root"
    else
        echo "⚠️  检测不到普通用户身份且非交互式运行。"
        echo "   若确认要为 root 安装，请加 FORCE_ROOT=1 重试："
        echo "   FORCE_ROOT=1 sudo bash -c \"\$(curl -fsSL $RAW_BASE/install.sh)\""
        exit 1
    fi
fi

# 确定安装文件来源：本地 clone 或远程下载
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/proxy" ]; then
    ARTIFACT_DIR="$SCRIPT_DIR"
    SOURCE_DESC="本地仓库 ($ARTIFACT_DIR)"
else
    ARTIFACT_DIR="$(mktemp -d -t singbox-cli-install.XXXXXX)"
    trap 'rm -rf "$ARTIFACT_DIR"' EXIT
    SOURCE_DESC="$REPO@$REF"
    echo "● 从 $SOURCE_DESC 下载安装文件 ..."
    mkdir -p "$ARTIFACT_DIR/bin" "$ARTIFACT_DIR/systemd"
    for rel in \
        bin/proxy \
        systemd/sing-box.service \
        systemd/sing-box-rules-update.service \
        systemd/sing-box-rules-update.timer
    do
        if ! curl -fsSL "$RAW_BASE/$rel" -o "$ARTIFACT_DIR/$rel"; then
            echo "✗ 下载失败：$RAW_BASE/$rel"
            echo "  请检查网络或确认 REPO/REF 设置是否正确"
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

# ----------------- step 3: dirs + proxy CLI -----------------
echo "▶ [3/7] 安装 proxy CLI ..."
mkdir -p /etc/sing-box/rules /var/lib/sing-box
install -m 755 "$ARTIFACT_DIR/bin/proxy" /usr/local/bin/proxy

# ----------------- step 4: systemd units -----------------
echo "▶ [4/7] 安装 systemd 服务 ..."
install -m 644 "$ARTIFACT_DIR/systemd/sing-box.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.service" /etc/systemd/system/
install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.timer" /etc/systemd/system/
systemctl daemon-reload

# ----------------- step 5: sudoers -----------------
echo "▶ [5/7] 配置免密 sudo（仅针对 /usr/local/bin/proxy）..."
cat > /etc/sudoers.d/proxy <<EOF
$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/proxy
EOF
chmod 440 /etc/sudoers.d/proxy
visudo -c -f /etc/sudoers.d/proxy >/dev/null

# ----------------- step 6: rulesets -----------------
echo "▶ [6/7] 下载规则集 (.srs) ..."
if /usr/local/bin/proxy update-rules >/dev/null 2>&1; then
    echo "  下载完成"
else
    echo "  ⚠️ 下载失败（可能是网络问题），稍后用 'proxy update-rules' 重试"
fi

# ----------------- step 7: enable + start -----------------
echo "▶ [7/7] 生成初始配置并启动服务 ..."
/usr/local/bin/proxy reload >/dev/null
systemctl enable --now sing-box >/dev/null 2>&1
systemctl enable --now sing-box-rules-update.timer >/dev/null 2>&1

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ 安装完成"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "下一步："
echo "  1. 添加节点：    proxy add 'vless://...'"
echo "  2. 查看状态：    proxy status"
echo "  3. 查看帮助：    proxy help"
echo ""
echo "（初始没有节点时，TUN 已建立但流量走 direct，加节点后自动切换）"
