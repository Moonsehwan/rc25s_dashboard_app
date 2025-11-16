#!/bin/bash
echo "🧠 [RC25S] Full AGI Dashboard Fix — Nginx + React paths..."

FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
CONF="/etc/nginx/sites-enabled/codex_console.conf"
PKG="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/package.json"

# 1️⃣ Nginx 파일 유효성 검사 및 백업
if [ ! -f "$CONF" ]; then
  echo "❌ Nginx site config not found at $CONF"
  exit 1
fi
cp "$CONF" "$CONF.bak_fix_$(date +%s)"
echo "📦 Nginx config backed up."

# 2️⃣ Nginx 서버 블록 정리
awk '
/server\s*{/ {in_server=1}
in_server {print}
' "$CONF" > /tmp/clean_server_block.conf

cat > "$CONF" <<BLOCK
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # Proxy to FastAPI backend
    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /health {
        proxy_pass http://127.0.0.1:4545/health;
    }

    # === RC25S AGI Dashboard Frontend ===
    location /agi/ {
        alias $FRONT_DIR/;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location = /favicon.ico {
        root $FRONT_DIR;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
    }
}
BLOCK

# 3️⃣ React homepage 수정
if ! grep -q '"homepage": "/agi"' "$PKG"; then
  echo "🧩 Updating React homepage..."
  tmp=$(mktemp)
  jq '.homepage="/agi"' "$PKG" > "$tmp" && mv "$tmp" "$PKG"
fi

# 4️⃣ React 재빌드
echo "⚙️ Rebuilding React frontend..."
cd /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend
npm run build >/dev/null 2>&1 && echo "✅ React build complete."

# 5️⃣ Nginx 검증 및 리로드
sudo nginx -t && sudo systemctl reload nginx && echo "✅ Nginx reloaded successfully!" || echo "❌ Nginx reload failed."

# 6️⃣ 테스트
echo "🌐 Testing AGI Dashboard..."
curl -s https://api.mcpvibe.org/agi/ | head -n 20
