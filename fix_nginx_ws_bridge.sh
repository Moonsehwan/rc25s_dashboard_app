#!/bin/bash
echo "🔧 [RC25S] Nginx WebSocket 프록시 구성 중..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP_PATH="${NGINX_CONF}.bak_ws_$(date +%s)"
cp "$NGINX_CONF" "$BACKUP_PATH"

# 중복 방지
grep -q "location /ws" "$NGINX_CONF" && echo "⚠️ 이미 /ws 블록 존재함 — 건너뜀." && exit 0

# /ws 블록 삽입 (server {} 내부에)
sudo sed -i '/server_name api.mcpvibe.org;/a \
    \n    ### RC25S AGI WebSocket ###\n    location /ws {\n        proxy_pass http://127.0.0.1:4545/ws;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n    }\n' "$NGINX_CONF"

sudo nginx -t && sudo systemctl restart nginx && echo "✅ WebSocket 프록시 활성화 완료!"
