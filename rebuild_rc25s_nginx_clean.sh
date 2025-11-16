#!/bin/bash
echo "🧠 [RC25S] Performing full Nginx config rebuild (clean mode)..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="$CONF.bak_fullclean_$(date +%s)"
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

# 1️⃣ 백업 및 초기화
cp "$CONF" "$BACKUP"
echo "📦 백업 완료 → $BACKUP"
echo "🧹 기존 설정 초기화 중..."
> "$CONF"

# 2️⃣ 완전한 서버 블록 작성
cat > "$CONF" <<BLOCK
server {
    listen 80;
    server_name api.mcpvibe.org;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # === FastAPI Backend Proxies ===
    location /health {
        proxy_pass http://127.0.0.1:4545/health;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # === AGI Dashboard (React Frontend) ===
    location /agi/ {
        alias $FRONT_DIR/;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Favicon and Static
    location = /favicon.ico {
        root $FRONT_DIR;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
    }
}
BLOCK

# 3️⃣ 설정 검사 및 리로드
echo "🔍 Nginx 문법 검사..."
if sudo nginx -t; then
  echo "✅ 문법 확인 완료 — Nginx 재시작 중..."
  sudo systemctl restart nginx
  echo "🌐 테스트 https://api.mcpvibe.org/agi/"
  curl -s https://api.mcpvibe.org/agi/ | head -n 15
else
  echo "❌ Nginx 설정 오류 — 복원 필요: $BACKUP"
fi
