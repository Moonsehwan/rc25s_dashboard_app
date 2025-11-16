#!/bin/bash
CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="/etc/nginx/sites-enabled/codex_console.conf.bak.$(date +%Y%m%d%H%M%S)"
BUILD_PATH="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

echo "🧩 [RC25S] Nginx Auto-Fix Triggered..."
echo "📦 Backing up current config → $BACKUP"
cp "$CONF" "$BACKUP"

# 완전 정상 버전으로 교체
cat <<NGINX > "$CONF"
server {
    listen 80;
    server_name api.mcpvibe.org;

    # HTTPS 리디렉션
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # 🔹 React 정적 경로
    root $BUILD_PATH;
    index index.html;

    # 🔹 React 앱 (메인 페이지)
    location /agi/ {
        root $BUILD_PATH;
        try_files \$uri \$uri/ /index.html;
    }

    # 🔹 FastAPI 백엔드 헬스체크
    location /health {
        proxy_pass http://127.0.0.1:4545/health;
        proxy_connect_timeout 5s;
        proxy_read_timeout 10s;
    }

    # 🔹 FastAPI 백엔드 (LLM)
    location /llm {
        proxy_pass http://127.0.0.1:4545/llm;
        proxy_connect_timeout 60s;
        proxy_send_timeout 180s;
        proxy_read_timeout 180s;
        send_timeout 180s;
    }

    # 🔹 WebSocket 연결
    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX

echo "🔍 Testing nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
  echo "✅ Nginx configuration valid. Reloading..."
  systemctl reload nginx
  echo "🚀 Nginx successfully reloaded."
else
  echo "❌ Configuration test failed. Restoring backup..."
  cp "$BACKUP" "$CONF"
  nginx -t
fi
