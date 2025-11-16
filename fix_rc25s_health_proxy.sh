#!/bin/bash
echo "🧠 [RC25S] Fixing Nginx proxy for /health and /ws routes..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

# 백업
cp "$NGINX_CONF" "$NGINX_CONF.bak_$(date +%s)"

# 기존 설정 제거 및 추가
sed -i '/location \/health/,/}/d' "$NGINX_CONF"
sed -i '/location \/ws/,/}/d' "$NGINX_CONF"

cat <<BLOCK >> "$NGINX_CONF"

    # === RC25S Dashboard Backend Proxy ===
    location /health {
        proxy_pass http://127.0.0.1:4545/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }
BLOCK

sudo nginx -t && sudo systemctl reload nginx
echo "✅ /health 및 /ws 프록시 경로 복구 완료!"
