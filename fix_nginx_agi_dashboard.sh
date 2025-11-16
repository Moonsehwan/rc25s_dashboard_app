#!/bin/bash
echo "🧩 [RC25S] Configuring Nginx proxy for /agi/ dashboard..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

# 백업
cp "$NGINX_CONF" "${NGINX_CONF}.bak_$(date +%s)"

# 블록 존재 여부 확인 후 없으면 추가
if ! grep -q "location /agi/" "$NGINX_CONF"; then
cat <<'BLOCK' >> "$NGINX_CONF"

### RC25S AGI DASHBOARD ###
location /agi/ {
    proxy_pass         http://127.0.0.1:4545/;
    proxy_set_header   Host \$host;
    proxy_set_header   X-Real-IP \$remote_addr;
    proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto \$scheme;
}
BLOCK
echo "✅ /agi/ location block added to $NGINX_CONF"
else
echo "ℹ️ Nginx block already exists."
fi

# 문법 테스트 및 재시작
nginx -t && systemctl reload nginx && echo "🚀 Nginx reloaded successfully!"
