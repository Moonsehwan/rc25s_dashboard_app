#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 클린 리빌드 시작..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="/etc/nginx/sites-enabled/codex_console.conf.bak_clean_$(date +%s)"

# 백업
cp "$CONF" "$BACKUP"
echo "📦 백업 완료: $BACKUP"

# 완전 재작성
cat > "$CONF" <<'NGINX'
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === RC25S React Dashboard ===
    location /agi/ {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # === Backend API ===
    location /health {
        proxy_pass http://127.0.0.1:4545/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }

    # === Default fallback ===
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGINX

echo "🔍 nginx 설정 검사..."
if nginx -t; then
    echo "✅ 설정 정상! Nginx reload..."
    systemctl reload nginx
else
    echo "❌ 설정 오류. 이전 백업으로 복원 필요."
fi
