#!/bin/bash
echo "🧠 [RC25S] Nginx 전체 재구성 시작..."

# 1️⃣ nginx.conf 재생성
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak_$(date +%s)
cat <<'NG' | sudo tee /etc/nginx/nginx.conf > /dev/null
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    include /etc/nginx/sites-enabled/*;
}
NG

# 2️⃣ codex_console.conf 재작성
CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="/etc/nginx/sites-enabled/codex_console.conf.bak_full_$(date +%s)"
cp "$CONF" "$BACKUP"

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

    location / {
        root /var/www/html;
        index index.html;
    }
}
NGINX

# 3️⃣ 문법 검사 및 재시작
echo "🔍 nginx 설정 검사..."
if nginx -t; then
    echo "✅ 구문 문제 없음."
    systemctl restart nginx
else
    echo "❌ nginx.conf 또는 site 설정 오류. 복구 필요."
fi
