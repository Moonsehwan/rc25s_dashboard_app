#!/bin/bash
echo "🧠 [RC25S] Fixing static 404 + WS 502 errors..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

# 1️⃣ React 정적 경로 rewrite (alias → root + rewrite)
sed -i '/location \/agi\//,/}/d' "$NGINX_CONF"
cat <<'BLOCK' >> "$NGINX_CONF"
    # === RC25S AGI Dashboard (React frontend fix) ===
    location /agi/ {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
        index index.html;
        try_files $uri $uri/ /agi/index.html;
    }

    # 정적 리소스 리다이렉션
    location ~ ^/(favicon\.ico|manifest\.json|logo192\.png|logo512\.png|asset-manifest\.json)$ {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    }
BLOCK

# 2️⃣ FastAPI 서비스 재시작 (502 방지)
systemctl restart rc25s-dashboard.service
sleep 2

echo "🔍 Nginx 검사..."
if nginx -t; then
    systemctl reload nginx
    echo "✅ 정적 자원 및 WebSocket 브릿지 복구 완료!"
    echo "🌐 접속: https://api.mcpvibe.org/agi/"
else
    echo "❌ nginx 오류 — 수동 확인 필요"
fi
