#!/usr/bin/env bash
# ===== 受限网络回归测试 · 操作指南（一次性 VM）=====
# 在一台**一次性**虚拟机里把全部规则集来源变成不可达，跑一次 install.sh，检查装完
# 之后系统是否仍处于"降级但可用"的状态；再解除封锁、跑一次 `sc update-rules` 检查
# 能否恢复。共 6 个条件 E1…E6，每个一行。
#
# 前置条件（不满足报 UNMET，不是 FAIL）：
#   1. 一台**一次性**、带 systemd 的 Linux 虚拟机，用完即弃；绝不要在工作机上跑。
#   2. root 身份运行。          3. `sing-box` 二进制已装好（本脚本不会去装它）。
#   4. 有 /dev/net/tun 设备。   5. 环境变量 SB_RULES_BASE 未设置（设了会顶掉 sc 的
#      来源列表，封锁就失去意义）。
#   6. 机器上**没有**已配置的 singbox-cli：/etc/sing-box/nodes.json 不存在（存在即
#      拒绝执行、退出码 3），config.json 不存在，/etc/sing-box/rules/ 里没有 .srs。
#   7. 本仓库已 clone 到这台虚拟机上，并从该 clone 里运行本脚本。
#
# 在一次性虚拟机上准备环境（示例，Debian/Ubuntu）：
#   apt-get install -y curl python3 git    # 再自行装好 sing-box 二进制
#   ls /dev/net/tun || { mkdir -p /dev/net && mknod /dev/net/tun c 10 200; }
#   git clone <repo-url> /root/singbox-cli
#
# 调用方式（令牌必须原样给出）：
#   sudo bash /root/singbox-cli/.harness/scripts/restricted-network-regression.sh --i-will-destroy-this-vm
# 只做推导与拒绝逻辑、不写任何文件的自检（可以在开发机上跑）：
#   bash .harness/scripts/restricted-network-regression.sh --self-check
#
# 虚拟机是**一次性**的：脚本跑完不清理、不卸载、不把机器恢复原状 —— 它改过
# /etc/hosts、装过服务、写过 /etc/sing-box。跑完请直接销毁这台虚拟机，不要在同一台
# 机器上跑第二次（第二次会因为前置条件 6 报 UNMET）。
# ==============================================================================
# Below this line everything, runtime output included, is English — so no string
# of this file can collide with `bin/sc`'s load-bearing `失败：` grep.
#
# SAFETY: outside its mktemp work dir the only host file this writes is
# /etc/hosts, and only once all four gates in main() have passed; it never runs
# uninstall.sh, removes a unit, or touches firewall / resolv.conf.
# Deliberately NOT `set -e`: here a non-zero status IS the datum (`is-enabled` on
# an absent unit, a failed `sc update-rules`), so `-e` would abort at the very
# observation this exists to take. The four must-succeed commands are `|| die`d.

set -uo pipefail

TOKEN='--i-will-destroy-this-vm'
NODES=/etc/sing-box/nodes.json
CFG=/etc/sing-box/config.json
RULES_DIR=/etc/sing-box/rules
LOG=/var/log/sing-box/install.log
MARK=singbox-cli-restricted-network-regression
# Repo root from THIS file's own path — never `git rev-parse` (git is not a
# dependency of this scenario, and the VM may have the checkout without it).
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd) || exit 2
REPO=$(cd "$SELF_DIR/../.." && pwd) || exit 2
WORK=""
BASES=""; HOSTS=""; BAD=""
declare -a E=()

usage() {
    cat >&2 <<EOF
usage: restricted-network-regression.sh $TOKEN
       restricted-network-regression.sh --self-check [--source FILE]

$TOKEN  run the scenario. Root, on a DISPOSABLE single-use
                          systemd VM only. It edits /etc/hosts and installs.
--self-check              derive the blackout and check coverage. No root, no
                          network, writes nothing. --source defaults to bin/sc.
EOF
    exit 2
}
die() { printf 'FATAL: %s\n' "$1" >&2; unmet_all "fatal:${1// /_}"; finish 1; }
set_c() { E[$1]="E$1 $2 obs=$3 pair=$4"; }
unmet_all() { local i; for i in 1 2 3 4 5 6; do E[$i]="E$i UNMET obs=$1 pair=none"; done; }
# Exactly six lines, always, on every path past the usage gate; exit 0 only when
# all six are PASS, unless a status is forced (the FR-11 refusal exits 3).
finish() {
    local i rc=0
    for i in 1 2 3 4 5 6; do
        printf '%s\n' "${E[$i]}"
        case "${E[$i]}" in "E$i PASS "*) ;; *) rc=1 ;; esac
    done
    exit "${1:-$rc}"
}
sysread() { local o; o=$("$@" 2>/dev/null); o="${o%%$'\n'*}"; printf '%s' "${o:-unknown}"; }
sb_pid() { local o; o=$(systemctl show -p MainPID sing-box 2>/dev/null) || o=; printf '%s' "${o#MainPID=}"; }
val() { local s="${1#*$2=}"; printf '%s' "${s%%;*}"; }

# --- derivation (FR-3) -------------------------------------------------------
# Textual only: this file never imports, sources, executes or python3-loads the
# candidate bin/sc — its import-time auto-elevate re-execs the INSTALLED sc.
derive_bases() { sed -n '/^RULESET_BASES = (/,/^)/p' "$1" | grep -oE 'https?://[^"]+'; }
host_of() { local h="${1#*://}"; printf '%s' "${h%%/*}"; }
# /etc/hosts maps names, not addresses: an address literal, a port-bearing
# authority, localhost or an empty host is UNCOVERABLE — named, never skipped.
uncoverable() { case "$1" in ""|localhost|*:*|[0-9]*.[0-9]*.[0-9]*.[0-9]*) return 0 ;; esac; return 1; }
# Sets BASES / HOSTS / BAD. Returns 1 on BC-13 (nothing parsed) or BC-2 (a
# shipped source the blackout cannot cover). The command substitution's status is
# deliberately NOT consulted (the emptiness of BASES is the datum instead).
derive() {
    local b h list="github.com raw.githubusercontent.com api.github.com"
    BASES=$(derive_bases "$1")
    BAD=""
    [ -n "$BASES" ] || { BAD="no base parsed from $1"; return 1; }
    for b in $BASES; do
        h=$(host_of "$b")
        if uncoverable "$h"; then BAD="$BAD $b"; else list="$list $h"; fi
    done
    HOSTS=$(printf '%s\n' $list | sort -u)
    if [ -n "$BAD" ]; then BAD="uncoverable base(s):$BAD"; return 1; fi
}
# The covered arm prints the derived list AND its count, so a reader can compare
# it against bin/sc's RULESET_BASES block instead of trusting exit 0.
self_check() {
    local n
    if ! derive "$1"; then
        [ -n "$BASES" ] && printf 'derived bases:\n%s\n' "$BASES"
        printf 'SELF-CHECK FAIL: %s\n' "$BAD"
        return 1
    fi
    n=$(printf '%s\n' "$BASES" | wc -l)
    printf 'derived bases (%s):\n%s\n' "$n" "$BASES"
    printf 'blackout hosts (%s):\n%s\n' "$(printf '%s\n' "$HOSTS" | wc -l)" "$HOSTS"
    printf 'SELF-CHECK OK: %s shipped base(s), all covered\n' "$n"
}
# Counts only — never a key, a value, a tag or a byte of the document (K-8).
cfg_facts() {
    python3 - "$1" 2>/dev/null <<'PY' || printf 'defs=?;route_refs=?;dns_refs=?'
import json, sys
def refs(a): return sum(1 for x in (a or []) if isinstance(x, dict) and "rule_set" in x)
try:
    d = json.load(open(sys.argv[1])); r = d.get("route") or {}
    print("defs=%d;route_refs=%d;dns_refs=%d" % (len(r.get("rule_set") or []),
          refs(r.get("rules")), refs((d.get("dns") or {}).get("rules"))))
except Exception:
    print("defs=?;route_refs=?;dns_refs=?")
PY
}

main() {
    local src
    case "${1:-}" in
        "$TOKEN") [ $# -eq 1 ] || usage ;;
        --self-check)
            shift; src="$REPO/bin/sc"
            if [ "${1:-}" = "--source" ]; then src="${2:-}"; [ -n "$src" ] || usage; shift 2; fi
            [ $# -eq 0 ] || usage
            [ -f "$src" ] || { printf 'SELF-CHECK FAIL: no such source file: %s\n' "$src"; exit 1; }
            if self_check "$src"; then exit 0; fi
            exit 1 ;;
        *) usage ;;
    esac

    # --- gates. NOTHING is created on disk until all four have passed. --------
    if [ -e "$NODES" ] || [ -L "$NODES" ]; then      # -L: dangling counts as configured
        printf 'REFUSED: a configured installation is present: %s\n' "$NODES"
        printf 'This is not a disposable VM. Nothing was read, written or started.\n'
        unmet_all "refused;node_store=$NODES"
        finish 3
    fi
    local uid="${EUID:-$(id -u)}"
    if [ "$uid" -ne 0 ]; then
        printf 'UNMET: must run as root; euid=%s\n' "$uid"
        unmet_all "euid=$uid"; finish
    fi
    local why=""
    command -v systemctl >/dev/null 2>&1 || why="no systemctl"
    command -v sing-box >/dev/null 2>&1 || why="${why:-no sing-box binary}"
    command -v curl >/dev/null 2>&1 || why="${why:-no curl}"
    command -v python3 >/dev/null 2>&1 || why="${why:-no python3}"
    [ -c /dev/net/tun ] || why="${why:-no /dev/net/tun}"
    [ -z "${SB_RULES_BASE:-}" ] || why="${why:-SB_RULES_BASE is set}"
    [ -f "$REPO/install.sh" ] || why="${why:-no install.sh under $REPO}"
    [ -e "$CFG" ] && why="${why:-config.json already present}"
    ls "$RULES_DIR"/*.srs >/dev/null 2>&1 && why="${why:-rule-set dir already populated}"
    if [ -n "$why" ]; then
        printf 'UNMET: precondition: %s\n' "$why"
        unmet_all "precondition:${why// /_}"; finish
    fi
    if ! derive "$REPO/bin/sc"; then
        printf 'UNMET: blackout coverage: %s\n' "$BAD"
        unmet_all "coverage_gap:${BAD// /_}"; finish
    fi
    # Pre-install readings: the counter-observations E2 and E5 are paired against.
    local pre_svc pre_tmr pre_act
    pre_svc=$(sysread systemctl is-enabled sing-box)
    pre_tmr=$(sysread systemctl is-enabled sing-box-rules-update.timer)
    pre_act=$(sysread systemctl is-active sing-box)

    # --- blackout ------------------------------------------------------------
    WORK=$(mktemp -d) || die "mktemp -d failed"
    trap 'if [ -n "$WORK" ] && [ -f "$WORK/hosts.orig" ]; then cp "$WORK/hosts.orig" /etc/hosts || true; fi' EXIT
    printf 'work dir (kept): %s\n' "$WORK"
    cp /etc/hosts "$WORK/hosts.orig" || die "cannot back up /etc/hosts"
    { printf '# BEGIN %s\n' "$MARK"
      printf '%s\n' "$HOSTS" | sed 's/^/0.0.0.0 /'
      printf '# END %s\n' "$MARK"; } >>/etc/hosts || die "cannot append to /etc/hosts"
    local h bad=""    # injection proof (BC-3): every answer, every first field 0.0.0.0
    for h in $HOSTS; do
        getent hosts "$h" >"$WORK/getent" 2>/dev/null
        [ -s "$WORK/getent" ] && ! grep -qv '^0\.0\.0\.0[[:space:]]' "$WORK/getent" || bad="$bad $h"
    done
    if [ -n "$bad" ]; then
        printf 'UNMET: blackout did not reach the resolver for:%s\n' "$bad"
        unmet_all "injection_unproven:${bad// /_}"; finish
    fi

    # --- blackout arm --------------------------------------------------------
    local cap="$WORK/install.capture" irc=0
    printf '1\ny\n' | bash "$REPO/install.sh" >"$cap" 2>&1 || irc=$?
    # Every capture/log match below is a FIXED-STRING match: `[6/7]` as a regex is
    # a bracket expression matching any line containing 6, / or 7.
    if ! grep -qF '[6/7]' "$cap"; then
        printf 'UNMET: installer did not reach the rule-set step; irc=%s\n' "$irc"
        unmet_all "no_step6;irc=$irc"; finish
    fi
    local okb fb s6w st
    okb=$(grep -cF '✅ Install complete' "$cap"); fb=$(grep -cF '❌' "$cap")
    s6w=$(grep -cF 'Ruleset download failed' "$cap")
    # E1's pair is the step-6 rule-set-failure warning from the SAME capture: it is
    # what separates a degraded success from a healthy one. The failure-banner
    # count rides along as a companion but FR-10 does not rest on it.
    if [ "$s6w" -eq 0 ]; then
        set_c 1 BLOCKED "irc=$irc;ok_banner=$okb;fail_banner=$fb" "unproven;step6_warn=0"
    else
        st=FAIL
        [ "$irc" -eq 0 ] && [ "$okb" -ge 1 ] && [ "$fb" -eq 0 ] && st=PASS
        set_c 1 "$st" "irc=$irc;ok_banner=$okb;fail_banner=$fb" "step6_warn=$s6w;fail_banner=$fb"
    fi
    local en_svc en_tmr act_tmr
    en_svc=$(sysread systemctl is-enabled sing-box)
    en_tmr=$(sysread systemctl is-enabled sing-box-rules-update.timer)
    act_tmr=$(sysread systemctl is-active sing-box-rules-update.timer)
    # E2 is independent of the rule-set outcome: install.sh enables both units
    # before config generation, each with `|| true`.
    st=FAIL
    [ "$en_svc" = enabled ] && [ "$en_tmr" = enabled ] && [ "$act_tmr" = active ] && st=PASS
    set_c 2 "$st" "svc=$en_svc;timer=$en_tmr;timer_active=$act_tmr" \
        "pre_svc=$pre_svc;pre_timer=$pre_tmr"
    local lmode nfail nbase agg degr named nolog b
    lmode=$(stat -c %a "$LOG" 2>/dev/null); lmode="${lmode:-absent}"
    nfail=$(grep -cF 'failed: ' "$LOG" 2>/dev/null); nfail="${nfail:-0}"
    agg=$(grep -cF 'ruleset(s) failed to update' "$LOG" 2>/dev/null); agg="${agg:-0}"
    degr=$(grep -cF 'degraded to no-splitting mode' "$LOG" 2>/dev/null); degr="${degr:-0}"
    named=$(grep -cF "$LOG" "$cap")
    nolog=$(grep -cF 'is not writable' "$cap")
    # A base counts only if EVERY per-rule-set cause line names it AS ITS OWN
    # entry. `sc` joins entries with "; " and each is `<base> -> <cause>`, so the
    # entry boundary must be matched: base 4 is a SUFFIX of base 3, and a bare
    # substring test would count base 4 on a line that only ever named base 3.
    nbase=0
    for b in $BASES; do
        [ "$(grep -F 'failed: ' "$LOG" 2>/dev/null |
             grep -cF -e "failed: $b -> " -e "; $b -> ")" = "$nfail" ] && nbase=$((nbase + 1))
    done
    local cmode ccheck bcf
    cmode=$(stat -c %a "$CFG" 2>/dev/null); cmode="${cmode:-absent}"
    bcf=$(cfg_facts "$CFG")
    sing-box check -c "$CFG" >"$WORK/check.out" 2>&1; ccheck=$?
    # E5: the state at the END of the settle window (never the first positive
    # read) — or two reads whose MainPID agrees. K-7: at most 10 x 1 s.
    local st5="" p5="" prev5="" agree=0 o5 i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 1
        st5=$(sysread systemctl is-active sing-box); p5=$(sb_pid)
        if [ "$st5" = active ] && [ -n "$p5" ] && [ "$p5" != 0 ] && [ "$p5" = "$prev5" ]; then
            agree=1; break
        fi
        prev5="$p5"
    done
    st=FAIL; [ "$st5" = active ] && st=PASS
    o5="state=$st5;mainpid=$p5;settled_at=${i}s"
    # `active` alone cannot separate a settled service from one crash-looping
    # under Restart=on-failure, so a window that expired with no two AGREEING
    # MainPID reads is BLOCKED, never PASS. (`$p5 = $prev5` is NOT that test:
    # the loop's tail assignment makes it true on the exhausted exit as well.)
    if [ "$st" = PASS ] && [ "$agree" -eq 0 ]; then
        set_c 5 BLOCKED "$o5" "unproven;no_mainpid_agreement"
    else set_c 5 "$st" "$o5" "pre_state=$pre_act"; fi

    # --- recovery arm: the blackout is LIFTED by a byte restore, not an edit --
    cp "$WORK/hosts.orig" /etc/hosts || die "cannot restore /etc/hosts"
    local rcap="$WORK/update-rules.capture" urc=0 nok=-1 nrf=-1 rcf="defs=?;route_refs=?;dns_refs=?"
    local pid_b="" pid_a="" rblock=""
    if [ -x /usr/local/bin/sc ]; then
        pid_b=$(sb_pid)
        /usr/local/bin/sc update-rules >"$rcap" 2>&1 || urc=$?
        nok=$(grep -cF 'OK (' "$rcap"); nrf=$(grep -cF 'failed: ' "$rcap")
        for i in 1 2 3 4 5; do
            sleep 1; pid_a=$(sb_pid)
            [ -n "$pid_a" ] && [ "$pid_a" != 0 ] && [ "$pid_a" != "$pid_b" ] && break
        done
        rcf=$(cfg_facts "$CFG")
    fi
    # BC-9. Not run, or ran and reached NO source: the recovery readings are then
    # the blackout's own, so every claim resting on them is unproven, not PASS.
    [ "$nok" -lt 0 ] && rblock="unproven;recovery_arm_not_run"
    [ "$nok" -eq 0 ] && rblock="unproven;no_reachable_source"

    # --- E3 / E4 / E6: cross-arm pairs, so they are composed last -------------
    local o3="log_mode=$lmode;failed_lines=$nfail;bases_named=$nbase;aggregate=$agg"
    o3="$o3;degradation=$degr;log_path_on_screen=$named;nolog_form=$nolog"
    if [ -n "$rblock" ]; then set_c 3 BLOCKED "$o3" "$rblock"
    elif [ "$nolog" -ge 1 ]; then set_c 3 FAIL "$o3" "rec_failed=$nrf;rec_ok=$nok"
    else
        st=FAIL
        [ "$lmode" = 640 ] && [ "$nfail" -eq 4 ] && [ "$nbase" -eq 4 ] && [ "$agg" -ge 1 ] &&
            [ "$degr" -ge 1 ] && [ "$named" -ge 1 ] && st=PASS
        set_c 3 "$st" "$o3" "rec_failed=$nrf;rec_ok=$nok"
    fi
    local o4="mode=$cmode;$bcf;sing_box_check=$ccheck"
    if [ -n "$rblock" ]; then set_c 4 BLOCKED "$o4" "$rblock"
    else
        st=FAIL
        [ "$cmode" = 600 ] && [ "$(val "$bcf" defs)" = 0 ] && [ "$(val "$bcf" route_refs)" = 0 ] &&
            [ "$(val "$bcf" dns_refs)" = 0 ] && [ "$ccheck" -eq 0 ] && st=PASS
        set_c 4 "$st" "$o4" "rec_defs=$(val "$rcf" defs);rec_dns_refs=$(val "$rcf" dns_refs)"
    fi
    local o6="urc=$urc;ok_lines=$nok;$rcf;mainpid=$pid_b->$pid_a" rd rr rdn
    rd=$(val "$rcf" defs); rr=$(val "$rcf" route_refs); rdn=$(val "$rcf" dns_refs)
    if [ -n "$rblock" ] || [ "$nrf" -eq 4 ]; then
        set_c 6 BLOCKED "$o6" "${rblock:-unproven;no_reachable_source}"
    else
        st=FAIL
        # dns_refs must be NON-ZERO: `>= 0` is true of the degraded document too,
        # which would make FR-9's DNS clause unfalsifiable.
        [ "$urc" -eq 0 ] && [ "$nok" -eq 4 ] && [ "$rd" = 4 ] && [ "$rr" != 0 ] &&
            [ "$rdn" != 0 ] && [ -n "$pid_a" ] && [ "$pid_a" != "$pid_b" ] && st=PASS
        set_c 6 "$st" "$o6" "bo_defs=$(val "$bcf" defs);bo_dns_refs=$(val "$bcf" dns_refs)"
    fi
    finish
}

main "$@"
