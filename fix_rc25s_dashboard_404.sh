#!/bin/bash
echo "🧠 [RC25S] Fixing 404 for AGI Dashboard (React path + alias mode)..."

FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

# 1️⃣ 빌드 확인
if [ ! -f "$FRONT_DIR/index.html" ]; then
  echo "⚠️ React build not found. Rebuilding..."
  cd /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend
  npm run build
else
  echo "✅ React build exists at $FRONT_DIR"
fi

# 2️⃣ Nginx 수정 — alias로 변경
sed -i '/location \/agi\//,/}/d' "$NGINX_CONF"

cat <<BLOCK >> "$NGINX_CONF"
    # === RC25S AGI DASHBOARD (alias mode) ===
    location /agi/ {
        alias $FRONT_DIR/;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
BLOCK

# 3️⃣ nginx 테스트 & reload
echo "🔍 Testing nginx..."
nginx -t && systemctl reload nginx && echo "✅ Dashboard should now be live at: https://api.mcpvibe.org/agi/" || echo "❌ Failed. Check logs."
