#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 초기화 및 정식 AGI Dashboard 복구 중..."

NGINX_DIR="/etc/nginx/sites-enabled"
NGINX_CONF="$NGINX_DIR/codex_console.conf"
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
BACK_PORT=4545

echo "🧹 모든 백업파일(.bak*) 삭제 중..."
find "$NGINX_DIR" -type f -name "*.bak*" -delete

echo "✅ 잔여 백업 정리 완료."

cat <<'NGX' > "$NGINX_CONF"
server {
    listen 80;
    server_name api.mcpvibe.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === RC25S AGI Dashboard (React frontend) ===
    location /agi/ {
        alias /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build/;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # === WebSocket Bridge ===
    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }

    # === Health Check ===
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
    }

    # === Static fallback ===
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGX

echo "🔎 nginx 문법 검사 중..."
if nginx -t; then
    echo "✅ 구문 OK. nginx reload..."
    systemctl reload nginx
    echo "🌐 대시보드: https://api.mcpvibe.org/agi/"
else
    echo "❌ 오류 발생. 수동 확인 필요."
fi
