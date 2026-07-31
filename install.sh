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
SB_BIN="/usr/local/bin/sing-box"
SB_REPO="SagerNet/sing-box"

# The log path the user is TOLD about — never reassigned, so every message names
# the real path (B-14, B-15). LOG_SINK is where output is actually redirected;
# it stays /dev/null until the probe below step 5 proves the log file openable.
INSTALL_LOG="/var/log/sing-box/install.log"
LOG_SINK="/dev/null"         # "$INSTALL_LOG" | /dev/null — written only by the probe

# Phase status — the single source of truth for the closing report
# (install_report) and for the process exit status. Pessimistic defaults: a
# phase counts as failed until the step that owns it records otherwise.
PHASE_RULESETS="failed"      # ok | failed           — step 6
PHASE_CONFIG="failed"        # ok | failed           — step 7, sc reload
PHASE_SERVICE="not-started"  # started | not-started — step 7, service launch

# ----------------- pre-flight: root -----------------
if [ "$EUID" -ne 0 ]; then
    echo "Run as root (sudo bash install.sh, or use the one-line install from the README)"
    echo "请以 root 身份运行（sudo bash install.sh 或参考 README 的一行安装命令）"
    exit 1
fi

# ----------------- detect package manager -----------------
PKG_MGR=$(type -P apt-get || type -P dnf || type -P yum || type -P pacman || type -P zypper || type -P apk || true)
if [ -z "$PKG_MGR" ]; then
    echo "ERROR: No supported package manager found."
    echo "Supported: apt (Debian/Ubuntu/Mint), dnf/yum (Fedora/RHEL/CentOS/Rocky/Alma),"
    echo "           pacman (Arch/Manjaro), zypper (openSUSE), apk (Alpine)"
    echo "错误：未检测到受支持的包管理器。"
    echo "支持：apt（Debian/Ubuntu/Mint）、dnf/yum（Fedora/RHEL/CentOS/Rocky/Alma）、"
    echo "      pacman（Arch/Manjaro）、zypper（openSUSE）、apk（Alpine）"
    exit 1
fi

# ----------------- detect cpu architecture -----------------
case "$(uname -m)" in
    amd64|x86_64)          ARCH="amd64" ;;
    aarch64|arm64|*armv8*) ARCH="arm64" ;;
    *)
        echo "ERROR: Only amd64 (x86_64) and arm64 (aarch64) are supported."
        echo "错误：仅支持 amd64 (x86_64) 和 arm64 (aarch64) 架构。"
        exit 1 ;;
esac

# ----------------- detect init system -----------------
IS_SYSTEMD=$(type -P systemctl || true)
IS_OPENRC=$(type -P rc-service || true)
if [ -z "$IS_SYSTEMD" ] && [ -z "$IS_OPENRC" ]; then
    echo "ERROR: Neither systemd (systemctl) nor OpenRC (rc-service) found — cannot install service."
    echo "错误：未找到 systemd（systemctl）或 OpenRC（rc-service）—— 无法安装服务。"
    exit 1
fi
INIT_SYS="systemd"
[ -z "$IS_SYSTEMD" ] && INIT_SYS="openrc"

# ----------------- python package name varies by distro -----------------
case "$PKG_MGR" in
    */pacman) PYTHON_PKG="python" ;;
    *)        PYTHON_PKG="python3" ;;
esac
# Alpine needs gcompat for glibc-linked binaries
EXTRA_DEPS=""
case "$PKG_MGR" in */apk) EXTRA_DEPS="gcompat" ;; esac
BASE_DEPS="curl $PYTHON_PKG ca-certificates $EXTRA_DEPS"

# ----------------- pkg_install helper -----------------
pkg_install() {
    # Always run to handle package-name vs binary-name mismatches (e.g. python3 vs python)
    case "$PKG_MGR" in
        */apt-get)
            apt-get update -qq
            # shellcheck disable=SC2086
            apt-get install -y -qq $* >/dev/null || return 1
            ;;
        */dnf|*/yum)
            # shellcheck disable=SC2086
            $PKG_MGR install -y -q $* >/dev/null || return 1
            ;;
        */pacman)
            # shellcheck disable=SC2086
            pacman -Sy --noconfirm --needed $* >/dev/null || return 1
            ;;
        */zypper)
            # shellcheck disable=SC2086
            zypper --non-interactive install --no-recommends $* >/dev/null || return 1
            ;;
        */apk)
            apk update >/dev/null
            # shellcheck disable=SC2086
            apk add --no-cache $* >/dev/null || return 1
            ;;
    esac
}

# ----------------- bootstrap curl -----------------
if ! command -v curl >/dev/null 2>&1; then
    # Use pkg_install but only for curl (safe before full dep install)
    pkg_install curl
fi

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
            step2_installing)    fmt="▶ [2/7] 从 GitHub Releases 下载 sing-box 二进制 ..." ;;
            step2_done)          fmt="  已安装：%s" ;;
            step3)               fmt="▶ [3/7] 安装 sc CLI ..." ;;
            step4)               fmt="▶ [4/7] 安装服务 ..." ;;
            step5)               fmt="▶ [5/7] 配置免密 sudo（仅针对 /usr/local/bin/sc）..." ;;
            step6)               fmt="▶ [6/7] 下载规则集 (.srs) ..." ;;
            step6_ok)            fmt="  下载完成" ;;
            step6_warn)          fmt="  ⚠️ 规则集下载失败，详细原因见 %s，稍后用 'sc update-rules' 重试" ;;
            step7)               fmt="▶ [7/7] 生成初始配置并启动服务 ..." ;;
            done_banner)         fmt="  ✅ 安装完成" ;;
            next_steps)          fmt="下一步：" ;;
            next_add)            fmt="  1. 添加节点：    sc add 'vless://...'" ;;
            next_status)         fmt="  2. 查看状态：    sc status" ;;
            next_help)           fmt="  3. 查看帮助：    sc help" ;;
            next_lang)           fmt="  4. 切换语言：    sc lang en|zh" ;;
            next_uninstall)      fmt="  5. 卸载：        sc uninstall" ;;
            note_initial)        fmt="（初始没有节点时，TUN 已建立但流量走 direct，加节点后自动切换）" ;;
            fail_banner)         fmt="  ❌ 安装未完成" ;;
            fail_config)         fmt="配置生成失败：sing-box 没有通过配置校验，服务未启动。" ;;
            fail_service)        fmt="配置已生成，但服务启动失败，当前没有运行。" ;;
            fail_rulesets)       fmt="规则集缺失（第 6 步下载失败），这通常就是配置校验失败的原因。" ;;
            fail_next)           fmt="请手动执行以下命令修复（系统不会自动恢复）：" ;;
            fail_rules)          fmt="  1. 重新下载规则集：sc update-rules" ;;
            fail_reload)         fmt="  2. 重新生成配置：  sc reload" ;;
            fail_status)         fmt="  3. 查看服务状态：  %s" ;;
            fail_log)            fmt="详细错误已记录在 %s" ;;
            fail_nolog)          fmt="%s 不可写，本次的详细错误没有保存；请直接运行上面的命令查看错误输出。" ;;
            step6_nolog)         fmt="  ⚠️ 规则集下载失败，%s 不可写，详细原因未能保存，稍后用 'sc update-rules' 重试" ;;
        esac
    else
        case "$key" in
            run_as_root)         fmt="Run as root (sudo bash install.sh, or use the one-line install from the README)" ;;
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
            step2_installing)    fmt="▶ [2/7] Downloading sing-box binary from GitHub Releases ..." ;;
            step2_done)          fmt="  Installed: %s" ;;
            step3)               fmt="▶ [3/7] Installing the sc CLI ..." ;;
            step4)               fmt="▶ [4/7] Installing service ..." ;;
            step5)               fmt="▶ [5/7] Configuring NOPASSWD sudo (scoped to /usr/local/bin/sc) ..." ;;
            step6)               fmt="▶ [6/7] Downloading rulesets (.srs) ..." ;;
            step6_ok)            fmt="  Done" ;;
            step6_warn)          fmt="  ⚠️ Ruleset download failed — see %s for the cause; retry later with 'sc update-rules'" ;;
            step7)               fmt="▶ [7/7] Generating initial config and starting the service ..." ;;
            done_banner)         fmt="  ✅ Install complete" ;;
            next_steps)          fmt="Next steps:" ;;
            next_add)            fmt="  1. Add a node:     sc add 'vless://...'" ;;
            next_status)         fmt="  2. Check status:   sc status" ;;
            next_help)           fmt="  3. Show help:      sc help" ;;
            next_lang)           fmt="  4. Switch lang:    sc lang en|zh" ;;
            next_uninstall)      fmt="  5. Uninstall:      sc uninstall" ;;
            note_initial)        fmt="(With no nodes yet, the TUN is up but traffic goes direct; adding a node switches it automatically.)" ;;
            fail_banner)         fmt="  ❌ Install incomplete" ;;
            fail_config)         fmt="Config generation failed: sing-box did not pass the config check, so the service was not started." ;;
            fail_service)        fmt="The config was generated, but the service failed to start and is not running." ;;
            fail_rulesets)       fmt="The rulesets are missing (the step 6 download failed) — that is usually why the config check fails." ;;
            fail_next)           fmt="Run these commands yourself to fix it (nothing repairs it automatically):" ;;
            fail_rules)          fmt="  1. Re-download rulesets: sc update-rules" ;;
            fail_reload)         fmt="  2. Regenerate config:    sc reload" ;;
            fail_status)         fmt="  3. Check service state:  %s" ;;
            fail_log)            fmt="The detailed error was written to %s" ;;
            fail_nolog)          fmt="%s is not writable, so the detailed error was not saved — run the commands above to see it." ;;
            step6_nolog)         fmt="  ⚠️ Ruleset download failed — %s is not writable, so the cause was not saved; retry later with 'sc update-rules'" ;;
        esac
    fi
    if [ "$#" -gt 0 ]; then
        # shellcheck disable=SC2059
        printf "$fmt\n" "$@"
    else
        printf "%s\n" "$fmt"
    fi
}

# Closing report. Reads the recorded phase status and nothing else, so the
# banner and the exit status can never disagree. Returns 0 for a successful
# install (config generated AND service running), 1 otherwise.
install_report() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    if [ "$PHASE_CONFIG" = "ok" ] && [ "$PHASE_SERVICE" = "started" ]; then
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
        return 0
    fi
    t fail_banner
    echo "═══════════════════════════════════════════════════════"
    echo ""
    if [ "$PHASE_CONFIG" = "ok" ]; then
        t fail_service
    else
        t fail_config
    fi
    if [ "$PHASE_RULESETS" = "failed" ]; then
        t fail_rulesets
    fi
    echo ""
    t fail_next
    t fail_rules
    t fail_reload
    if [ "$INIT_SYS" = "systemd" ]; then
        t fail_status "systemctl status sing-box"
    else
        t fail_status "rc-service sing-box status"
    fi
    echo ""
    # Always name the real log path; say which of the two things is true of it.
    if [ "$LOG_SINK" = "$INSTALL_LOG" ]; then
        t fail_log "$INSTALL_LOG"
    else
        t fail_nolog "$INSTALL_LOG"
    fi
    return 1
}

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

CLEANUP_DIRS=()
# "${arr[@]}" over an EMPTY array is an unbound-variable error under `set -u` on
# bash < 4.4 (CentOS/RHEL 7 ships 4.2). Inside the EXIT trap that would override
# the installer's derived exit status, so guard both the expansion and the rm.
cleanup() { for d in ${CLEANUP_DIRS[@]+"${CLEANUP_DIRS[@]}"}; do rm -rf "$d" || true; done; }
trap cleanup EXIT

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/bin/sc" ]; then
    ARTIFACT_DIR="$SCRIPT_DIR"
    SOURCE_DESC="local repo ($ARTIFACT_DIR)"
    [ "$LANG_CHOICE" = "zh" ] && SOURCE_DESC="本地仓库 ($ARTIFACT_DIR)"
else
    ARTIFACT_DIR="$(mktemp -d -t singbox-cli-install.XXXXXX)"
    CLEANUP_DIRS+=("$ARTIFACT_DIR")
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
# shellcheck disable=SC2086
pkg_install $BASE_DEPS || { echo "ERROR: Failed to install dependencies ($BASE_DEPS)"; exit 1; }

# ----------------- step 2: sing-box binary -----------------
if command -v sing-box >/dev/null 2>&1; then
    t step2_already "$(sing-box version | head -1)"
else
    t step2_installing
    SB_TMPDIR="$(mktemp -d)"
    CLEANUP_DIRS+=("$SB_TMPDIR")
    SB_VER=$(curl -fsSL "https://api.github.com/repos/${SB_REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"v\([^"]*\)".*/\1/')
    # Validate that we got a semver-like string (e.g. "1.10.0")
    if [ -z "$SB_VER" ] || ! echo "$SB_VER" | grep -qE '^[0-9]+\.[0-9]+'; then
        t download_failed "GitHub API (sing-box version)"
        t check_network
        exit 1
    fi
    SB_URL="https://github.com/${SB_REPO}/releases/download/v${SB_VER}/sing-box-${SB_VER}-linux-${ARCH}.tar.gz"
    if ! curl -fsSL "$SB_URL" -o "$SB_TMPDIR/sing-box.tar.gz"; then
        t download_failed "$SB_URL"
        t check_network
        exit 1
    fi
    mkdir -p "$SB_TMPDIR/extract"
    tar -xz --strip-components=1 -C "$SB_TMPDIR/extract" -f "$SB_TMPDIR/sing-box.tar.gz"
    install -m 755 "$SB_TMPDIR/extract/sing-box" "$SB_BIN"
    t step2_done "$(sing-box version | head -1)"
fi

# ----------------- step 3: dirs + sc CLI + uninstall.sh -----------------
t step3
mkdir -p /etc/sing-box/rules /var/lib/sing-box /var/log/sing-box "$LIB_DIR"
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

# Write distro-info so uninstall.sh and upgrades know the environment
cat > "$LIB_DIR/distro-info" <<EOF
PKG_MGR=$PKG_MGR
INIT_SYS=$INIT_SYS
EOF

# ----------------- step 4: service -----------------
t step4
if [ "$INIT_SYS" = "systemd" ]; then
    install -m 644 "$ARTIFACT_DIR/systemd/sing-box.service" /etc/systemd/system/
    install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.service" /etc/systemd/system/
    install -m 644 "$ARTIFACT_DIR/systemd/sing-box-rules-update.timer" /etc/systemd/system/
    systemctl daemon-reload
else
    # OpenRC (Alpine and compatible)
    cat > /etc/init.d/sing-box <<INITEOF
#!/sbin/openrc-run

name="sing-box"
description="sing-box Service"

command="$SB_BIN"
command_args="run -c /etc/sing-box/config.json"
command_background=true
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/sing-box/access.log"
error_log="/var/log/sing-box/error.log"

supervisor=supervise-daemon

depend() {
    need net
    after firewall
}
INITEOF
    chmod +x /etc/init.d/sing-box
fi

# ----------------- step 5: sudoers -----------------
t step5
cat > /etc/sudoers.d/sc <<EOF
$INSTALL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/sc
EOF
chmod 440 /etc/sudoers.d/sc
visudo -c -f /etc/sudoers.d/sc >/dev/null

# ----------------- install log -----------------
# Steps 6-7 append their diagnostics here, so a failed run keeps the real cause
# instead of sending it to /dev/null. Mode 0640: captured `sing-box check`
# output can quote fragments of the generated config. Only on success is the
# sink promoted to the real file — logging must never change what the installer
# does (a plain >> on an unwritable path makes the command itself fail), and
# INSTALL_LOG is never touched, so every message still names the real path.
if ( umask 027; printf '\n===== singbox-cli install (pid %s) =====\n' "$$" >>"$INSTALL_LOG" ) 2>/dev/null; then
    LOG_SINK="$INSTALL_LOG"
fi

# ----------------- step 6: rulesets -----------------
t step6
if /usr/local/bin/sc update-rules >>"$LOG_SINK" 2>&1; then
    PHASE_RULESETS="ok"
    t step6_ok
elif [ "$LOG_SINK" = "$INSTALL_LOG" ]; then
    t step6_warn "$INSTALL_LOG"
else
    t step6_nolog "$INSTALL_LOG"
fi

# ----------------- step 7: enable + start -----------------
t step7

# Register for boot autostart first: registration must not depend on config
# generation, and a failure here must never abort the install.
if [ "$INIT_SYS" = "systemd" ]; then
    systemctl enable sing-box >>"$LOG_SINK" 2>&1 || true
    systemctl enable sing-box-rules-update.timer >>"$LOG_SINK" 2>&1 || true
else
    rc-update add sing-box default >>"$LOG_SINK" 2>&1 || true
fi

# Generate the initial config; start the service only if that succeeded.
# Each phase records its own outcome; nothing else decides what the run was.
if /usr/local/bin/sc reload >>"$LOG_SINK" 2>&1; then
    PHASE_CONFIG="ok"
    if [ "$INIT_SYS" = "systemd" ]; then
        if systemctl start sing-box >>"$LOG_SINK" 2>&1; then
            PHASE_SERVICE="started"
        fi
        # The rules-update timer is auxiliary: its start does not decide the run.
        systemctl start sing-box-rules-update.timer >>"$LOG_SINK" 2>&1 || true
    else
        if rc-service sing-box start >>"$LOG_SINK" 2>&1; then
            PHASE_SERVICE="started"
        fi
    fi
fi

# The closing report and the exit status come from the same derivation, so the
# installer cannot print success for a run that did not install a working service.
install_report || exit 1
exit 0
