#!/bin/bash
echo "🧠 [RC25S] Rebuilding Nginx config for AGI Dashboard (clean server block)..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="$CONF.bak_fullclean_$(date +%s)"

# 1️⃣ 백업
cp "$CONF" "$BACKUP"
echo "📦 기존 설정 백업 완료 → $BACKUP"

# 2️⃣ 완전한 server 블록 재작성
cat > "$CONF" <<'BLOCK'
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === AGI Dashboard (React Frontend) ===
    location /agi/ {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
        index index.html;
        try_files $uri $uri/ /agi/index.html;
    }

    # === Static resources fix ===
    location ~ ^/(favicon\.ico|manifest\.json|logo192\.png|logo512\.png|asset-manifest\.json)$ {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    }

    # === WebSocket backend ===
    location /ws {
        proxy_pass http://127.0.0.1:4545;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # === MCP & API routes ===
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    location / {
        root /var/www/html;
        index index.html;
    }
}
BLOCK

# 3️⃣ nginx 테스트 & reload
echo "🔍 nginx 구문 검사 중..."
if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx 리빌드 성공! AGI Dashboard가 활성화되었습니다."
    echo "🌐 접속: https://api.mcpvibe.org/agi/"
else
    echo "❌ 오류 발생. 백업 복원 명령: cp $BACKUP $CONF"
fi
