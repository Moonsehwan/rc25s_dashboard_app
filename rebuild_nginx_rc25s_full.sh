#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 리빌드 및 AGI Dashboard 정식 설정 시작..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
BACK_PORT=4545

# 🔒 백업
cp "$NGINX_CONF" "${NGINX_CONF}.bak_final_$(date +%s)"
echo "📦 기존 설정 백업 완료."

# ⚙️ 완전 재작성
cat <<NGX > "$NGINX_CONF"
server {
    listen 80;
    server_name api.mcpvibe.org;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === AGI Dashboard (React frontend) ===
    location /agi/ {
        alias $FRONT_DIR/;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # === WebSocket bridge ===
    location /ws {
        proxy_pass http://127.0.0.1:$BACK_PORT/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
    }

    # === Health check ===
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host \$host;
    }

    # === Default static fallback ===
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGX

echo "🔍 nginx 문법 검사 중..."
if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx 완전 리빌드 완료! 접속: https://api.mcpvibe.org/agi/"
else
    echo "❌ 오류 발생 — 백업 파일 유지됨: ${NGINX_CONF}.bak_final_$(date +%s)"
fi
