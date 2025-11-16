#!/bin/bash
echo "🧠 [RC25S] Nginx 설정 완전 초기화 및 AGI 대시보드 복원 시작..."

NGINX_DIR="/etc/nginx/sites-enabled"
NGINX_CONF="$NGINX_DIR/codex_console.conf"
BACK_PORT=4545
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

# 🔥 백업 파일 및 중복 설정 제거
find "$NGINX_DIR" -type f -name "*.bak_*" -delete
echo "🧹 모든 백업 파일(.bak_*) 삭제 완료."

# ✅ 클린 설정 재작성
cat <<NGX > "$NGINX_CONF"
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === RC25S AGI DASHBOARD ===
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

    # === MCP Health ===
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host \$host;
    }

    # === Static Fallback ===
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGX

# ✅ 테스트 및 재시작
echo "🔎 nginx 설정 검사 중..."
nginx -t && systemctl reload nginx && echo "✅ Nginx 복구 완료! 접속: https://api.mcpvibe.org/agi/" || echo "❌ nginx 테스트 실패. 로그를 확인하세요."
