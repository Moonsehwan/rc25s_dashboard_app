#!/bin/bash
set -e

LOG="/srv/repo/vibecoding/logs/rc25s_autoheal.log"
CONF="/etc/nginx/sites-enabled/codex_console.conf"
FRONTEND="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend"
BACKEND_SERVICE="rc25s-dashboard.service"

echo "🧩 [RC25S] Full Dashboard Auto-Heal Started: $(date)" | tee -a "$LOG"

# 1️⃣ React 빌드
cd "$FRONTEND"
echo "📦 Installing npm dependencies..." | tee -a "$LOG"
npm install --silent

echo "⚙️  Building production React..." | tee -a "$LOG"
npm run build --silent

# 2️⃣ Nginx 설정 검증 및 자동 복원
echo "🧱 Backing up current Nginx config..." | tee -a "$LOG"
cp "$CONF" "${CONF}.bak.$(date +%Y%m%d%H%M%S)" || true

cat > "$CONF" <<'NGINXCONF'
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

    root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    index index.html;

    location ~* ^/agi/(.*\.(?:js|css|json|ico|png|jpg|jpeg|svg|woff2?))$ {
        alias /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build/$1;
        access_log off;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }

    location /agi/ {
        try_files \$uri \$uri/ /index.html;
    }

    location /health {
        proxy_pass http://127.0.0.1:4545/health;
    }

    location /llm {
        proxy_pass http://127.0.0.1:4545/llm;
        proxy_connect_timeout 60s;
        proxy_read_timeout 180s;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINXCONF

echo "🔍 Testing nginx configuration..." | tee -a "$LOG"
if nginx -t; then
    echo "✅ Nginx configuration OK. Reloading..." | tee -a "$LOG"
    systemctl reload nginx
else
    echo "❌ Nginx config test failed. Restoring backup..." | tee -a "$LOG"
    mv "${CONF}.bak."* "$CONF"
    exit 1
fi

# 3️⃣ FastAPI 재시작
echo "🚀 Restarting FastAPI Dashboard Service..." | tee -a "$LOG"
systemctl restart "$BACKEND_SERVICE"

sleep 2
echo "🩺 Testing backend health..." | tee -a "$LOG"
curl -s http://127.0.0.1:4545/health | tee -a "$LOG"

# 4️⃣ 외부 확인
echo "🌐 Testing public endpoints..." | tee -a "$LOG"
curl -Is https://api.mcpvibe.org/agi/static/js/main.ffd914ce.js | grep "Content-Type" | tee -a "$LOG"
curl -Is https://api.mcpvibe.org/agi/manifest.json | grep "Content-Type" | tee -a "$LOG"

echo "✅ RC25S Full Dashboard Auto-Heal Completed Successfully ✅" | tee -a "$LOG"
