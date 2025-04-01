#!/bin/bash

# 每天凌晨 2 点执行
# 0 2 * * * /etc/openvpn/update_routes.sh

URL="https://raw.githubusercontent.com/wlrsx/pinode/refs/heads/main/routes_config/routes.list"
CCD_FILE="/etc/openvpn/ccd/pinode"
SCRIPT_DIR="$(dirname "$0")"
OLD_FILE="$SCRIPT_DIR/routes.list.old"
LOG_FILE="/var/log/update_routes.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

ROUTES=$(curl -s "$URL")
if [ $? -ne 0 ]; then
    log "无法获取 $URL 的内容"
    exit 1
fi

if [ -f "$OLD_FILE" ] && [ "$(cat "$OLD_FILE")" = "$ROUTES" ]; then
    log "路由配置无变化，退出"
    exit 0
fi

sed -i '/^push "route /d' "$CCD_FILE"

echo "$ROUTES" | while read -r target mask gateway; do
    [ -z "$target" ] && continue
    if [[ "$target" =~ [a-zA-Z] ]]; then
        # ip=$(dig +short "$target" A | grep -v '\.$' | head -n 1)
        ip=$(ping -c 1 -W 1 "$target" | grep -oP '(?<=\().*?(?=\))' | head -n 1)
        if [ -z "$ip" ]; then
            log "无法解析 $target，跳过"
            continue
        fi
        target="$ip"
    fi
    echo "push \"route $target $mask $gateway\"" >> "$CCD_FILE"
done

echo "$ROUTES" > "$OLD_FILE"

systemctl restart openvpn@server
if [ $? -eq 0 ]; then
    log "路由配置已更新并重启服务成功"
else
    log "重启 OpenVPN 服务失败"
    exit 1
fi
