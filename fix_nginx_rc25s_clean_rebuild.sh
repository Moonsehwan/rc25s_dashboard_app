#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 클린 복구 + AGI Dashboard 통합 재작성 시작..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACK_PORT=4545
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

# 🔒 백업
cp "$NGINX_CONF" "${NGINX_CONF}.bak_full_$(date +%s)"
echo "📦 백업 완료: ${NGINX_CONF}.bak_full_$(date +%s)"

# ⚙️ 새로운 Nginx 설정 완전 재작성
cat <<NGX > "$NGINX_CONF"
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === AGI React Dashboard ===
    location /agi/ {
        root $FRONT_DIR;
        try_files \$uri /index.html;
    }

    # === WebSocket Bridge ===
    location /ws {
        proxy_pass http://127.0.0.1:$BACK_PORT/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }

    # === MCP & API Health ===
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host \$host;
    }

    # === Static fallback ===
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGX

# ✅ 문법 검사 및 적용
echo "🔍 nginx 설정 검사 중..."
nginx -t && systemctl reload nginx && echo "✅ Nginx 클린 복구 완료! 접속: https://api.mcpvibe.org/agi/" || echo "❌ 오류 발생. 백업 파일 유지됨."
